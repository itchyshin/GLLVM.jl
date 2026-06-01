# Internal structured Poisson Laplace prototype.
#
# This is the small/medium-p objective surface for the planned non-Gaussian
# structured-dependence path. It is deliberately not exported: fitters should
# only depend on it after the dense-mode and SLQ determinant checks are stable.

function _structured_poisson_check_dims(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, precision::AbstractMatrix, sigma2::Real)
    p, _ = size(Y)
    size(Λ, 1) == p || throw(DimensionMismatch(
        "Λ must have one row per response; got $(size(Λ, 1)) rows for p=$p"))
    length(β) == p || throw(DimensionMismatch(
        "β must have length $p; got $(length(β))"))
    size(precision) == (p, p) || throw(DimensionMismatch(
        "precision must be $(p)×$(p); got $(size(precision))"))
    sigma2 > 0 || throw(ArgumentError("sigma2 must be positive; got $sigma2"))
    return nothing
end

function _structured_poisson_lsw(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, U::AbstractVector, Z::AbstractMatrix)
    p, n = size(Y)
    T = promote_type(eltype(Λ), eltype(β), eltype(U), eltype(Z))
    S = Matrix{T}(undef, p, n)
    W = Matrix{T}(undef, p, n)
    ℓ = _structured_poisson_lsw!(S, W, Y, Λ, β, U, Z)
    return ℓ, S, W
end

function _structured_poisson_lsw!(S::AbstractMatrix, W::AbstractMatrix,
        Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        U::AbstractVector, Z::AbstractMatrix)
    p, n = size(Y)
    size(S) == (p, n) || throw(DimensionMismatch("S must be $(p)×$(n); got $(size(S))"))
    size(W) == (p, n) || throw(DimensionMismatch("W must be $(p)×$(n); got $(size(W))"))
    T = promote_type(eltype(S), eltype(W), eltype(Λ), eltype(β), eltype(U), eltype(Z))
    ℓ = zero(T)
    @inbounds for i in 1:n
        for t in 1:p
            η = β[t] + U[t]
            for k in axes(Λ, 2)
                η += Λ[t, k] * Z[k, i]
            end
            η = _clamp_eta(η)
            μ = _clamp_mu(Poisson(), exp(η))
            S[t, i] = Y[t, i] - μ
            W[t, i] = μ
            ℓ += _glm_logpdf(Poisson(), μ, one(Int), Y[t, i])
        end
    end
    return ℓ
end

function _structured_poisson_logdet_precision(precision::AbstractMatrix)
    return logdet(cholesky(Symmetric(precision)))
end

function _structured_poisson_logdet_precision(precision::Symmetric)
    return logdet(cholesky(precision))
end

function _structured_poisson_mode(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, precision::AbstractMatrix; sigma2::Real,
        maxiter::Integer = 50, tol::Real = 1e-8,
        mode_solve::Symbol = :dense, cg_tol::Real = 1e-8,
        cg_maxiter::Union{Nothing, Integer} = nothing)
    _structured_poisson_check_dims(Y, Λ, β, precision, sigma2)
    p, n = size(Y)
    K = size(Λ, 2)
    T = promote_type(eltype(Y), eltype(Λ), eltype(β), typeof(float(sigma2)))
    L = Matrix{T}(Λ)
    b = Vector{T}(β)
    Q = _schur_precision_storage(precision, T)
    invsigma2 = inv(T(sigma2))
    U = zeros(T, p)
    Z = zeros(T, K, n)
    Qu = zeros(T, p)
    gU = zeros(T, p)
    gz = zeros(T, K)
    rhsU = zeros(T, p)
    tmpK = zeros(T, K)
    tmpP = zeros(T, p)
    ΔU = zeros(T, p)
    ΔZ = zeros(T, K)
    S = Matrix{T}(undef, p, n)
    W = Matrix{T}(undef, p, n)
    cg_r = zeros(T, p)
    cg_d = zeros(T, p)
    cg_q = zeros(T, p)
    cg_tmp = zeros(T, K)
    cg_sol = similar(cg_tmp)
    schur_ws = _SchurUOperatorWorkspace(T, p, K, n)
    maxstep = T(Inf)
    gradnorm = T(Inf)
    iterations = 0
    cg_iterations = 0
    cg_residual = zero(T)
    cg_converged = true

    for iter in 1:maxiter
        iterations = iter
        _structured_poisson_lsw!(S, W, Y, L, b, U, Z)
        mul!(Qu, Q, U)
        @inbounds for t in 1:p
            gU[t] = -invsigma2 * Qu[t]
            for i in 1:n
                gU[t] += S[t, i]
            end
        end

        op = _SchurUOperator(Q, L, W, schur_ws; sigma2 = sigma2)
        copyto!(rhsU, gU)
        gradnorm = maximum(abs, gU)

        @inbounds for i in 1:n
            fill!(gz, zero(T))
            for t in 1:p
                for k in 1:K
                    gz[k] += L[t, k] * S[t, i]
                end
            end
            for k in 1:K
                gz[k] -= Z[k, i]
            end
            gradnorm = max(gradnorm, maximum(abs, gz))
            copyto!(tmpK, gz)
            ldiv!(op.Achols[i], tmpK)
            mul!(tmpP, L, tmpK)
            for t in 1:p
                rhsU[t] -= W[t, i] * tmpP[t]
            end
        end

        if mode_solve == :dense
            Sdense = Matrix(_schur_u_dense(op))
            Csu = cholesky(Symmetric(Sdense))
            copyto!(ΔU, rhsU)
            ldiv!(Csu, ΔU)
        elseif mode_solve == :cg
            fill!(ΔU, zero(T))
            cg = _schur_u_cg!(ΔU, op, rhsU, cg_r, cg_d, cg_q, cg_tmp, cg_sol; tol = cg_tol,
                maxiter = cg_maxiter === nothing ? max(100, 2 * p) : cg_maxiter)
            cg_iterations += cg.iterations
            cg_residual = cg.residual
            cg_converged &= cg.converged
        else
            throw(ArgumentError("mode_solve must be :dense or :cg; got $mode_solve"))
        end
        maxstep = maximum(abs, ΔU)

        @inbounds for i in 1:n
            fill!(gz, zero(T))
            for t in 1:p
                WΔu = W[t, i] * ΔU[t]
                for k in 1:K
                    gz[k] += L[t, k] * (S[t, i] - WΔu)
                end
            end
            for k in 1:K
                gz[k] -= Z[k, i]
            end
            copyto!(ΔZ, gz)
            ldiv!(op.Achols[i], ΔZ)
            for k in 1:K
                Z[k, i] += ΔZ[k]
                maxstep = max(maxstep, abs(ΔZ[k]))
            end
        end
        U .+= ΔU
        maxstep < tol && break
    end
    return (U = U, Z = Z, iterations = iterations,
            maxstep = maxstep, gradnorm = gradnorm,
            cg_iterations = cg_iterations, cg_residual = cg_residual,
            cg_converged = cg_converged)
end

function _structured_poisson_marginal_loglik_laplace(Y::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, precision::AbstractMatrix;
        sigma2::Real, logdet_method::Symbol = :dense,
        dense_cutoff::Integer = 256, probes = nothing,
        rng::AbstractRNG = Random.default_rng(), nprobes::Integer = 16,
        lanczos_steps::Integer = 40, reorth::Bool = false,
        maxiter::Integer = 50, tol::Real = 1e-8,
        mode_solve::Symbol = :dense, cg_tol::Real = 1e-8,
        cg_maxiter::Union{Nothing, Integer} = nothing,
        return_diagnostics::Bool = false)
    mode = _structured_poisson_mode(
        Y, Λ, β, precision; sigma2 = sigma2, maxiter = maxiter, tol = tol,
        mode_solve = mode_solve, cg_tol = cg_tol, cg_maxiter = cg_maxiter)
    U = mode.U
    Z = mode.Z
    p, n = size(Y)
    T = promote_type(eltype(Y), eltype(Λ), eltype(β), typeof(float(sigma2)))
    Q = _schur_precision_storage(precision, T)
    L = _matrix_storage(Λ, T)
    b = Vector{T}(β)
    S = Matrix{T}(undef, p, n)
    W = Matrix{T}(undef, p, n)
    ℓ = _structured_poisson_lsw!(S, W, Y, L, b, U, Z)
    op = _SchurUOperator(Q, L, W; sigma2 = sigma2)
    logdet_Su = _schur_u_logdet(op; method = logdet_method,
        dense_cutoff = dense_cutoff, probes = probes, rng = rng,
        nprobes = nprobes, lanczos_steps = lanczos_steps, reorth = reorth)
    logdet_A = zero(T)
    @inbounds for i in 1:n
        logdet_A += logdet(op.Achols[i])
    end
    Qu = similar(U)
    mul!(Qu, Q, U)
    invsigma2 = inv(T(sigma2))
    quad_u = invsigma2 * dot(U, Qu)
    quad_z = sum(abs2, Z)
    logdet_Qscaled = _structured_poisson_logdet_precision(Q) - p * log(T(sigma2))
    value = ℓ - T(0.5) * (quad_z + quad_u + logdet_A + logdet_Su) +
            T(0.5) * logdet_Qscaled
    if return_diagnostics
        return (value = value, mode = mode, logdet_Su = logdet_Su,
                logdet_A = logdet_A, logdet_Qscaled = logdet_Qscaled)
    end
    return value
end
