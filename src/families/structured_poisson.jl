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
        cg_maxiter::Union{Nothing, Integer} = nothing,
        U_init = nothing, Z_init = nothing,
        U_store = nothing, Z_store = nothing)
    _structured_poisson_check_dims(Y, Λ, β, precision, sigma2)
    p, n = size(Y)
    K = size(Λ, 2)
    T = promote_type(eltype(Y), eltype(Λ), eltype(β), typeof(float(sigma2)))
    L = Matrix{T}(Λ)
    b = Vector{T}(β)
    Q = _schur_precision_storage(precision, T)
    invsigma2 = inv(T(sigma2))
    U = zeros(T, p)
    if U_init !== nothing
        length(U_init) == p || throw(DimensionMismatch(
            "U_init must have length $p; got $(length(U_init))"))
        @inbounds for t in 1:p
            U[t] = U_init[t]
        end
    end
    Z = zeros(T, K, n)
    if Z_init !== nothing
        size(Z_init) == (K, n) || throw(DimensionMismatch(
            "Z_init must be $(K)×$(n); got $(size(Z_init))"))
        @inbounds for i in 1:n, k in 1:K
            Z[k, i] = Z_init[k, i]
        end
    end
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
            mul!(tmpK, op.Ainvs[i], gz)
            mul!(tmpP, L, tmpK)
            for t in 1:p
                rhsU[t] -= W[t, i] * tmpP[t]
            end
        end

        if mode_solve == :dense
            Csu = cholesky(_schur_u_dense(op))
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
            mul!(ΔZ, op.Ainvs[i], gz)
            for k in 1:K
                Z[k, i] += ΔZ[k]
                maxstep = max(maxstep, abs(ΔZ[k]))
            end
        end
        U .+= ΔU
        maxstep < tol && break
    end
    if U_store !== nothing
        length(U_store) == p || throw(DimensionMismatch(
            "U_store must have length $p; got $(length(U_store))"))
        copyto!(U_store, U)
    end
    if Z_store !== nothing
        size(Z_store) == (K, n) || throw(DimensionMismatch(
            "Z_store must be $(K)×$(n); got $(size(Z_store))"))
        copyto!(Z_store, Z)
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
        U_init = nothing, Z_init = nothing,
        U_store = nothing, Z_store = nothing,
        return_diagnostics::Bool = false)
    mode = _structured_poisson_mode(
        Y, Λ, β, precision; sigma2 = sigma2, maxiter = maxiter, tol = tol,
        mode_solve = mode_solve, cg_tol = cg_tol, cg_maxiter = cg_maxiter,
        U_init = U_init, Z_init = Z_init, U_store = U_store, Z_store = Z_store)
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

function _structured_poisson_pack_mode(U::AbstractVector, Z::AbstractMatrix)
    return vcat(U, vec(Z))
end

function _structured_poisson_unpack_mode(x::AbstractVector, p::Integer,
        K::Integer, n::Integer)
    m = p + K * n
    length(x) == m || throw(ArgumentError(
        "structured Poisson mode vector has length $(length(x)); expected $m"))
    U = @view x[1:p]
    Z = reshape(@view(x[(p + 1):m]), K, n)
    return U, Z
end

function _structured_poisson_qF(Y::AbstractMatrix, precision::AbstractMatrix,
        x::AbstractVector, θ::AbstractVector, p::Integer, K::Integer;
        sigma2::Real, logdet_method::Symbol = :dense,
        dense_cutoff::Integer = 256, probes = nothing,
        rng::AbstractRNG = Random.default_rng(), nprobes::Integer = 16,
        lanczos_steps::Integer = 40, reorth::Bool = false)
    n = size(Y, 2)
    U, Z = _structured_poisson_unpack_mode(x, p, K, n)
    β, Λ = _structured_poisson_unpackθ(θ, p, K)
    _structured_poisson_check_dims(Y, Λ, β, precision, sigma2)

    T = promote_type(eltype(x), eltype(θ), typeof(float(sigma2)))
    L = _matrix_storage(Λ, T)
    b = Vector{T}(β)
    Q = _schur_precision_storage(precision, eltype(precision))
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

    Qu = Vector{T}(undef, p)
    mul!(Qu, Q, U)
    invsigma2 = inv(T(sigma2))
    quad_u = invsigma2 * dot(U, Qu)
    quad_z = sum(abs2, Z)
    logdet_Qscaled = T(_structured_poisson_logdet_precision(precision)) -
                     p * log(T(sigma2))
    value = ℓ - T(0.5) * (quad_z + quad_u + logdet_A + logdet_Su) +
            T(0.5) * logdet_Qscaled

    F = Vector{T}(undef, p + K * n)
    @inbounds for t in 1:p
        F[t] = -invsigma2 * Qu[t]
        for i in 1:n
            F[t] += S[t, i]
        end
    end
    offset = p
    @inbounds for i in 1:n
        for k in 1:K
            g = -Z[k, i]
            for t in 1:p
                g += L[t, k] * S[t, i]
            end
            F[offset + (i - 1) * K + k] = g
        end
    end
    return vcat(value, F)
end

function _structured_poisson_joint_solve(qx::AbstractVector, op::_SchurUOperator;
        mode_solve::Symbol = :dense, cg_tol::Real = 1e-8,
        cg_maxiter::Union{Nothing, Integer} = nothing,
        Csu = nothing, rhs_scale = 1)
    p, K = size(op.Lambda)
    n = size(op.Wsites, 2)
    m = p + K * n
    length(qx) == m || throw(DimensionMismatch(
        "qx must have length $m; got $(length(qx))"))

    T = promote_type(eltype(qx), eltype(op), typeof(float(rhs_scale)))
    rhsU = Vector{T}(undef, p)
    tmpK = Vector{T}(undef, K)
    solK = Vector{T}(undef, K)
    tmpP = Vector{T}(undef, p)
    @inbounds for t in 1:p
        rhsU[t] = rhs_scale * qx[t]
    end
    @inbounds for i in 1:n
        offset = p + (i - 1) * K
        for k in 1:K
            tmpK[k] = rhs_scale * qx[offset + k]
        end
        mul!(solK, op.Ainvs[i], tmpK)
        mul!(tmpP, op.Lambda, solK)
        for t in 1:p
            rhsU[t] -= op.Wsites[t, i] * tmpP[t]
        end
    end

    solU = zeros(T, p)
    if mode_solve == :dense
        C = Csu === nothing ? cholesky(_schur_u_dense(op)) : Csu
        copyto!(solU, rhsU)
        ldiv!(C, solU)
    elseif mode_solve == :cg
        cg = _schur_u_cg!(solU, op, rhsU; tol = cg_tol,
            maxiter = cg_maxiter === nothing ? max(100, 2 * p) : cg_maxiter)
        cg.converged || throw(ArgumentError(
            "structured Poisson joint CG failed to converge; residual $(cg.residual)"))
    else
        throw(ArgumentError("mode_solve must be :dense or :cg; got $mode_solve"))
    end

    sol = Vector{T}(undef, m)
    copyto!(view(sol, 1:p), solU)
    @inbounds for i in 1:n
        offset = p + (i - 1) * K
        for k in 1:K
            tmpK[k] = rhs_scale * qx[offset + k]
        end
        for t in 1:p
            Wa = op.Wsites[t, i] * solU[t]
            for k in 1:K
                tmpK[k] -= op.Lambda[t, k] * Wa
            end
        end
        mul!(solK, op.Ainvs[i], tmpK)
        for k in 1:K
            sol[offset + k] = solK[k]
        end
    end
    return sol
end

function _structured_poisson_adjoint_solve(qx::AbstractVector, Y::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, precision::AbstractMatrix,
        U::AbstractVector, Z::AbstractMatrix; sigma2::Real,
        mode_solve::Symbol = :dense, cg_tol::Real = 1e-8,
        cg_maxiter::Union{Nothing, Integer} = nothing)
    _structured_poisson_check_dims(Y, Λ, β, precision, sigma2)
    p, n = size(Y)
    K = size(Λ, 2)
    m = p + K * n
    length(qx) == m || throw(DimensionMismatch(
        "qx must have length $m; got $(length(qx))"))

    T = promote_type(eltype(qx), eltype(Λ), eltype(β), eltype(U), eltype(Z),
        typeof(float(sigma2)))
    L = _matrix_storage(Λ, T)
    b = Vector{T}(β)
    Uv = Vector{T}(U)
    Zv = Matrix{T}(Z)
    Q = _schur_precision_storage(precision, eltype(precision))
    S = Matrix{T}(undef, p, n)
    W = Matrix{T}(undef, p, n)
    _structured_poisson_lsw!(S, W, Y, L, b, Uv, Zv)
    op = _SchurUOperator(Q, L, W; sigma2 = sigma2)
    return _structured_poisson_joint_solve(
        qx, op; mode_solve = mode_solve, cg_tol = cg_tol,
        cg_maxiter = cg_maxiter, rhs_scale = -one(T))
end

function _structured_poisson_implicit_value_grad_ad(θ::AbstractVector,
        Y::AbstractMatrix, precision::AbstractMatrix, p::Integer, K::Integer;
        sigma2::Real, logdet_method::Symbol = :dense,
        dense_cutoff::Integer = 256, probes = nothing,
        rng::AbstractRNG = Random.default_rng(), nprobes::Integer = 16,
        lanczos_steps::Integer = 40, reorth::Bool = false,
        mode_solve::Symbol = :dense, cg_tol::Real = 1e-8,
        cg_maxiter::Union{Nothing, Integer} = nothing,
        maxiter::Integer = 50, tol::Real = 1e-8,
        U_init = nothing, Z_init = nothing,
        U_store = nothing, Z_store = nothing)
    β, Λ = _structured_poisson_unpackθ(θ, p, K)
    mode = _structured_poisson_mode(
        Y, Λ, β, precision; sigma2 = sigma2, maxiter = maxiter, tol = tol,
        mode_solve = mode_solve, cg_tol = cg_tol, cg_maxiter = cg_maxiter,
        U_init = U_init, Z_init = Z_init, U_store = U_store, Z_store = Z_store)
    x0 = _structured_poisson_pack_mode(mode.U, mode.Z)
    m = length(x0)
    qF_from_all = allx -> _structured_poisson_qF(
        Y, precision, allx[1:m], allx[(m + 1):end], p, K;
        sigma2 = sigma2, logdet_method = logdet_method,
        dense_cutoff = dense_cutoff, probes = probes, rng = rng,
        nprobes = nprobes, lanczos_steps = lanczos_steps, reorth = reorth)
    F_from_θ = θlocal -> view(_structured_poisson_qF(
        Y, precision, x0, θlocal, p, K; sigma2 = sigma2,
        logdet_method = logdet_method, dense_cutoff = dense_cutoff,
        probes = probes, rng = rng, nprobes = nprobes,
        lanczos_steps = lanczos_steps, reorth = reorth), 2:(m + 1))
    all0 = vcat(x0, θ)
    qgrad = ForwardDiff.gradient(allx -> qF_from_all(allx)[1], all0)
    qx = qgrad[1:m]
    qθ = qgrad[(m + 1):end]
    Fθ = ForwardDiff.jacobian(F_from_θ, θ)
    adj = _structured_poisson_adjoint_solve(
        qx, Y, Λ, β, precision, mode.U, mode.Z; sigma2 = sigma2,
        mode_solve = mode_solve, cg_tol = cg_tol, cg_maxiter = cg_maxiter)
    grad = qθ - Fθ' * adj
    return qF_from_all(all0)[1], grad
end

function _structured_poisson_block_implicit_value_grad(θ::AbstractVector,
        Y::AbstractMatrix, precision::AbstractMatrix, p::Integer, K::Integer;
        sigma2::Real, dense_cutoff::Integer = 256, probes = nothing,
        rng::AbstractRNG = Random.default_rng(), nprobes::Integer = 16,
        lanczos_steps::Integer = 40, reorth::Bool = false,
        mode_solve::Symbol = :dense, cg_tol::Real = 1e-8,
        cg_maxiter::Union{Nothing, Integer} = nothing,
        maxiter::Integer = 50, tol::Real = 1e-8,
        U_init = nothing, Z_init = nothing,
        U_store = nothing, Z_store = nothing)
    β, Λ = _structured_poisson_unpackθ(θ, p, K)
    mode = _structured_poisson_mode(
        Y, Λ, β, precision; sigma2 = sigma2, maxiter = maxiter, tol = tol,
        mode_solve = mode_solve, cg_tol = cg_tol, cg_maxiter = cg_maxiter,
        U_init = U_init, Z_init = Z_init, U_store = U_store, Z_store = Z_store)
    U = mode.U
    Z = mode.Z
    n = size(Y, 2)
    T = promote_type(eltype(θ), eltype(Y), typeof(float(sigma2)))
    Q = _schur_precision_storage(precision, T)
    L = _matrix_storage(Λ, T)
    b = Vector{T}(β)
    S = Matrix{T}(undef, p, n)
    W = Matrix{T}(undef, p, n)
    ℓ = _structured_poisson_lsw!(S, W, Y, L, b, U, Z)
    op = _SchurUOperator(Q, L, W; sigma2 = sigma2)
    Csu = cholesky(_schur_u_dense(op))
    G = Csu \ Matrix{T}(I, p, p)

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
    value = ℓ - T(0.5) * (quad_z + quad_u + logdet_A + logdet(Csu)) +
            T(0.5) * logdet_Qscaled

    q_u = zeros(T, p)
    q_Z = zeros(T, K, n)
    gradβ = zeros(T, p)
    gradΛ = zeros(T, p, K)
    Usite = Matrix{T}(undef, p, K)
    GU = Matrix{T}(undef, p, K)
    C = Matrix{T}(undef, K, K)
    v = Vector{T}(undef, K)
    tmp = Vector{T}(undef, K)
    rz = Vector{T}(undef, K)

    @inbounds for i in 1:n
        for t in 1:p
            for k in 1:K
                Usite[t, k] = W[t, i] * L[t, k]
            end
        end
        mul!(GU, G, Usite)
        mul!(C, transpose(Usite), GU)
        M = op.Ainvs[i]
        for t in 1:p
            for k in 1:K
                acc = zero(T)
                for l in 1:K
                    acc += M[k, l] * L[t, l]
                end
                v[k] = acc
            end
            for k in 1:K
                acc = GU[t, k]
                for l in 1:K
                    acc -= C[k, l] * v[l]
                end
                tmp[k] = acc
            end
            for k in 1:K
                acc = v[k]
                for l in 1:K
                    acc -= M[k, l] * tmp[l]
                end
                rz[k] = acc
            end
            h = G[t, t]
            for k in 1:K
                h -= GU[t, k] * v[k]
                h += L[t, k] * rz[k]
            end
            Wh = W[t, i] * h
            a = S[t, i] - T(0.5) * Wh
            q_u[t] -= T(0.5) * Wh
            gradβ[t] += a
            for k in 1:K
                q_Z[k, i] -= T(0.5) * Wh * L[t, k]
                gradΛ[t, k] += a * Z[k, i] - W[t, i] * rz[k]
            end
        end
    end

    qx = Vector{T}(undef, p + K * n)
    copyto!(view(qx, 1:p), q_u)
    @inbounds for i in 1:n
        offset = p + (i - 1) * K
        for k in 1:K
            qx[offset + k] = q_Z[k, i]
        end
    end
    α = _structured_poisson_joint_solve(
        qx, op; mode_solve = :dense, Csu = Csu)
    αu = @view α[1:p]
    αZ = reshape(@view(α[(p + 1):end]), K, n)
    @inbounds for i in 1:n
        for t in 1:p
            δ = αu[t]
            for k in 1:K
                δ += L[t, k] * αZ[k, i]
            end
            gradβ[t] -= W[t, i] * δ
            for k in 1:K
                gradΛ[t, k] += S[t, i] * αZ[k, i] - W[t, i] * Z[k, i] * δ
            end
        end
    end

    grad = zeros(T, length(θ))
    copyto!(view(grad, 1:p), gradβ)
    @inbounds for k in 1:K
        grad[p + k] = gradΛ[k, k]
        for t in (k + 1):p
            grad[p + _lower_index(p, K, t, k)] = gradΛ[t, k]
        end
    end
    return value, grad
end

function _structured_poisson_trace_implicit_value_grad(θ::AbstractVector,
        Y::AbstractMatrix, precision::AbstractMatrix, p::Integer, K::Integer;
        sigma2::Real, dense_cutoff::Integer = 256, probes = nothing,
        rng::AbstractRNG = Random.default_rng(), nprobes::Integer = 16,
        lanczos_steps::Integer = 40, reorth::Bool = false,
        mode_solve::Symbol = :dense, trace_solve::Symbol = :solve,
        cg_tol::Real = 1e-8,
        cg_maxiter::Union{Nothing, Integer} = nothing,
        maxiter::Integer = 50, tol::Real = 1e-8,
        U_init = nothing, Z_init = nothing,
        U_store = nothing, Z_store = nothing)
    trace_solve in (:solve, :lanczos) || throw(ArgumentError(
        "trace_solve must be :solve or :lanczos; got $trace_solve"))
    β, Λ = _structured_poisson_unpackθ(θ, p, K)
    mode = _structured_poisson_mode(
        Y, Λ, β, precision; sigma2 = sigma2, maxiter = maxiter, tol = tol,
        mode_solve = mode_solve, cg_tol = cg_tol, cg_maxiter = cg_maxiter,
        U_init = U_init, Z_init = Z_init, U_store = U_store, Z_store = Z_store)
    U = mode.U
    Z = mode.Z
    n = size(Y, 2)
    active_probes = probes === nothing ? _rademacher_probes(rng, p, nprobes) : probes
    size(active_probes, 1) == p || throw(DimensionMismatch(
        "probes must have $p rows; got $(size(active_probes, 1))"))
    nprobe = size(active_probes, 2)
    nprobe > 0 || throw(ArgumentError("at least one probe is required"))

    T = promote_type(eltype(θ), eltype(Y), eltype(active_probes), typeof(float(sigma2)))
    Q = _schur_precision_storage(precision, T)
    L = _matrix_storage(Λ, T)
    b = Vector{T}(β)
    R = _matrix_storage(active_probes, T)
    S = Matrix{T}(undef, p, n)
    W = Matrix{T}(undef, p, n)
    ℓ = _structured_poisson_lsw!(S, W, Y, L, b, U, Z)
    op = _SchurUOperator(Q, L, W; sigma2 = sigma2)
    logdet_Su, X = if trace_solve == :lanczos
        _slq_logdet_invprobes(op, R; lanczos_steps = lanczos_steps, reorth = reorth)
    else
        logdet_value = _schur_u_logdet(op; method = :slq,
            dense_cutoff = dense_cutoff, probes = R, rng = rng,
            nprobes = nprobe, lanczos_steps = lanczos_steps, reorth = reorth)
        Xsolve = Matrix{T}(undef, p, nprobe)
        if mode_solve == :dense
            Csu = cholesky(_schur_u_dense(op))
            copyto!(Xsolve, R)
            ldiv!(Csu, Xsolve)
        elseif mode_solve == :cg
            r = zeros(T, p)
            d = zeros(T, p)
            q = zeros(T, p)
            tmp_cg = zeros(T, K)
            sol_cg = similar(tmp_cg)
            @inbounds for j in 1:nprobe
                fill!(view(Xsolve, :, j), zero(T))
                cg = _schur_u_cg!(view(Xsolve, :, j), op, view(R, :, j),
                    r, d, q, tmp_cg, sol_cg; tol = cg_tol,
                    maxiter = cg_maxiter === nothing ? max(100, 2 * p) : cg_maxiter)
                cg.converged || throw(ArgumentError(
                    "structured Poisson trace-gradient CG failed to converge; residual $(cg.residual)"))
            end
        else
            throw(ArgumentError("mode_solve must be :dense or :cg; got $mode_solve"))
        end
        logdet_value, Xsolve
    end

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

    q_u = zeros(T, p)
    q_Z = zeros(T, K, n)
    gradβ = zeros(T, p)
    gradΛ = zeros(T, p, K)
    Usite = Matrix{T}(undef, p, K)
    UR = Matrix{T}(undef, K, nprobe)
    UX = Matrix{T}(undef, K, nprobe)
    C = Matrix{T}(undef, K, K)
    v = Vector{T}(undef, K)
    geUt = Vector{T}(undef, K)
    Cv = Vector{T}(undef, K)
    tmp = Vector{T}(undef, K)
    rz = Vector{T}(undef, K)
    invnprobe = inv(T(nprobe))

    @inbounds for i in 1:n
        for t in 1:p
            for k in 1:K
                Usite[t, k] = W[t, i] * L[t, k]
            end
        end
        mul!(UR, transpose(Usite), R)
        mul!(UX, transpose(Usite), X)
        mul!(C, UX, transpose(UR))
        C .*= invnprobe
        M = op.Ainvs[i]
        for t in 1:p
            Gtt = zero(T)
            for j in 1:nprobe
                Gtt += X[t, j] * R[t, j]
            end
            Gtt *= invnprobe
            for k in 1:K
                accv = zero(T)
                accg = zero(T)
                for l in 1:K
                    accv += M[k, l] * L[t, l]
                end
                for j in 1:nprobe
                    accg += UX[k, j] * R[t, j]
                end
                v[k] = accv
                geUt[k] = accg * invnprobe
            end
            mul!(Cv, C, v)
            for k in 1:K
                tmp[k] = geUt[k] - Cv[k]
            end
            for k in 1:K
                acc = v[k]
                for l in 1:K
                    acc -= M[k, l] * tmp[l]
                end
                rz[k] = acc
            end
            λMv = zero(T)
            geUv = zero(T)
            vCv = zero(T)
            for k in 1:K
                λMv += L[t, k] * v[k]
                geUv += geUt[k] * v[k]
                vCv += v[k] * Cv[k]
            end
            h = Gtt + λMv - T(2) * geUv + vCv
            Wh = W[t, i] * h
            a = S[t, i] - T(0.5) * Wh
            q_u[t] -= T(0.5) * Wh
            gradβ[t] += a
            for k in 1:K
                q_Z[k, i] -= T(0.5) * Wh * L[t, k]
                gradΛ[t, k] += a * Z[k, i] - W[t, i] * rz[k]
            end
        end
    end

    qx = Vector{T}(undef, p + K * n)
    copyto!(view(qx, 1:p), q_u)
    @inbounds for i in 1:n
        offset = p + (i - 1) * K
        for k in 1:K
            qx[offset + k] = q_Z[k, i]
        end
    end
    α = _structured_poisson_joint_solve(
        qx, op; mode_solve = mode_solve, cg_tol = cg_tol,
        cg_maxiter = cg_maxiter)
    αu = @view α[1:p]
    αZ = reshape(@view(α[(p + 1):end]), K, n)
    @inbounds for i in 1:n
        for t in 1:p
            δ = αu[t]
            for k in 1:K
                δ += L[t, k] * αZ[k, i]
            end
            gradβ[t] -= W[t, i] * δ
            for k in 1:K
                gradΛ[t, k] += S[t, i] * αZ[k, i] - W[t, i] * Z[k, i] * δ
            end
        end
    end

    grad = zeros(T, length(θ))
    copyto!(view(grad, 1:p), gradβ)
    @inbounds for k in 1:K
        grad[p + k] = gradΛ[k, k]
        for t in (k + 1):p
            grad[p + _lower_index(p, K, t, k)] = gradΛ[t, k]
        end
    end
    return value, grad
end

function _structured_poisson_implicit_value_grad(θ::AbstractVector,
        Y::AbstractMatrix, precision::AbstractMatrix, p::Integer, K::Integer;
        sigma2::Real, logdet_method::Symbol = :dense,
        dense_cutoff::Integer = 256, probes = nothing,
        rng::AbstractRNG = Random.default_rng(), nprobes::Integer = 16,
        lanczos_steps::Integer = 40, reorth::Bool = false,
        mode_solve::Symbol = :dense, trace_solve::Symbol = :solve,
        cg_tol::Real = 1e-8,
        cg_maxiter::Union{Nothing, Integer} = nothing,
        maxiter::Integer = 50, tol::Real = 1e-8,
        U_init = nothing, Z_init = nothing,
        U_store = nothing, Z_store = nothing)
    if logdet_method == :dense
        return _structured_poisson_block_implicit_value_grad(
            θ, Y, precision, p, K; sigma2 = sigma2, dense_cutoff = dense_cutoff,
            probes = probes, rng = rng, nprobes = nprobes,
            lanczos_steps = lanczos_steps, reorth = reorth,
            mode_solve = mode_solve, cg_tol = cg_tol, cg_maxiter = cg_maxiter,
            maxiter = maxiter, tol = tol, U_init = U_init, Z_init = Z_init,
            U_store = U_store, Z_store = Z_store)
    elseif logdet_method == :slq || (logdet_method == :auto && p > dense_cutoff)
        return _structured_poisson_trace_implicit_value_grad(
            θ, Y, precision, p, K; sigma2 = sigma2, dense_cutoff = dense_cutoff,
            probes = probes, rng = rng, nprobes = nprobes,
            lanczos_steps = lanczos_steps, reorth = reorth,
            mode_solve = mode_solve, trace_solve = trace_solve,
            cg_tol = cg_tol, cg_maxiter = cg_maxiter,
            maxiter = maxiter, tol = tol, U_init = U_init, Z_init = Z_init,
            U_store = U_store, Z_store = Z_store)
    end
    return _structured_poisson_implicit_value_grad_ad(
        θ, Y, precision, p, K; sigma2 = sigma2, logdet_method = logdet_method,
        dense_cutoff = dense_cutoff, probes = probes, rng = rng,
        nprobes = nprobes, lanczos_steps = lanczos_steps, reorth = reorth,
        mode_solve = mode_solve, cg_tol = cg_tol, cg_maxiter = cg_maxiter,
        maxiter = maxiter, tol = tol, U_init = U_init, Z_init = Z_init,
        U_store = U_store, Z_store = Z_store)
end

function _structured_poisson_initial_theta(Y::AbstractMatrix, K::Integer;
        β_init = nothing, Λ_init = nothing)
    p, n = size(Y)
    0 < K <= p || throw(ArgumentError("K must satisfy 0 < K <= p; got K=$K for p=$p"))
    Zemp = Matrix{Float64}(undef, p, n)
    @inbounds for i in 1:n, t in 1:p
        Zemp[t, i] = log(max(float(Y[t, i]) + 0.5, 1e-4))
    end
    β0 = β_init === nothing ? vec(sum(Zemp; dims = 2)) ./ n : collect(float.(β_init))
    length(β0) == p || throw(DimensionMismatch(
        "β_init must have length $p; got $(length(β0))"))
    Λ0 = if Λ_init === nothing
        Zc = Zemp .- β0
        F = svd(Zc)
        kk = min(Int(K), length(F.S))
        L = zeros(Float64, p, K)
        @inbounds for j in 1:kk
            L[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
        end
        L
    else
        L = collect(float.(Λ_init))
        size(L) == (p, K) || throw(DimensionMismatch(
            "Λ_init must be $(p)×$(K); got $(size(L))"))
        L
    end
    return vcat(β0, pack_lambda(Λ0))
end

function _structured_poisson_unpackθ(θ::AbstractVector, p::Integer, K::Integer)
    rr = rr_theta_len(p, K)
    length(θ) == p + rr || throw(ArgumentError(
        "structured Poisson θ has length $(length(θ)); expected $(p + rr) for p=$p, K=$K"))
    β = θ[1:p]
    Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    return β, Λ
end

function _fit_structured_poisson_objective(θ::AbstractVector, Y::AbstractMatrix,
        precision::AbstractMatrix, p::Integer, K::Integer; sigma2::Real,
        logdet_method::Symbol, dense_cutoff::Integer, probes,
        nprobes::Integer, lanczos_steps::Integer, reorth::Bool,
        mode_solve::Symbol, cg_tol::Real,
        cg_maxiter::Union{Nothing, Integer}, maxiter::Integer, tol::Real,
        U_init, Z_init, U_store, Z_store)
    try
        β, Λ = _structured_poisson_unpackθ(θ, p, K)
        value = _structured_poisson_marginal_loglik_laplace(
            Y, Λ, β, precision; sigma2 = sigma2, logdet_method = logdet_method,
            dense_cutoff = dense_cutoff, probes = probes, nprobes = nprobes,
            lanczos_steps = lanczos_steps, reorth = reorth,
            mode_solve = mode_solve, cg_tol = cg_tol, cg_maxiter = cg_maxiter,
            maxiter = maxiter, tol = tol,
            U_init = U_init, Z_init = Z_init, U_store = U_store,
            Z_store = Z_store)
        isfinite(value) && return -value
    catch
    end
    penalty = zero(eltype(θ))
    @inbounds for x in θ
        isfinite(x) && (penalty += abs2(x))
    end
    return oftype(first(θ), 1e12) + penalty
end

"""
    _fit_structured_poisson_laplace(Y, precision; K, sigma2, kwargs...)

Internal fixed-covariance structured Poisson fitter for benchmarking the joint
Laplace prototype. It estimates only `β` and the lower-triangular loadings `Λ`
for a supplied structured precision and variance scale; public formula/API
wiring waits until the exact CG and determinant paths have fitted-model tests.
By default, neighbouring objective probes reuse the previous fitted latent mode
as a warm start through `mode_cache=true`, and L-BFGS uses the private
implicit-gradient scaffold (`gradient=:implicit`) instead of Optim finite
differences. With the default `trace_solve=:auto`, SLQ fits reuse the SLQ
Lanczos bases for the inverse-probe approximation in the trace-gradient path;
set `trace_solve=:solve` to keep the older explicit solve path.
"""
function _fit_structured_poisson_laplace(Y::AbstractMatrix{<:Integer},
        precision::AbstractMatrix; K::Integer, sigma2::Real,
        β_init = nothing, Λ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 80,
        logdet_method::Symbol = :dense, dense_cutoff::Integer = 256,
        probes = nothing, rng::AbstractRNG = Random.default_rng(),
        nprobes::Integer = 16, lanczos_steps::Integer = 40,
        reorth::Bool = false, mode_solve::Symbol = :cg,
        trace_solve::Symbol = :auto, cg_tol::Real = 1e-8,
        cg_maxiter::Union{Nothing, Integer} = nothing,
        maxiter::Integer = 50, tol::Real = 1e-8,
        mode_cache::Bool = true, gradient::Symbol = :implicit)
    p, _ = size(Y)
    0 < K <= p || throw(ArgumentError("K must satisfy 0 < K <= p; got K=$K for p=$p"))
    _structured_poisson_check_dims(Y, zeros(Float64, p, K), zeros(Float64, p),
        precision, sigma2)
    mode_solve in (:dense, :cg) || throw(ArgumentError(
        "mode_solve must be :dense or :cg; got $mode_solve"))
    logdet_method in (:auto, :dense, :slq) || throw(ArgumentError(
        "logdet_method must be :auto, :dense, or :slq; got $logdet_method"))
    trace_solve in (:auto, :solve, :lanczos) || throw(ArgumentError(
        "trace_solve must be :auto, :solve, or :lanczos; got $trace_solve"))
    gradient in (:finite, :implicit) || throw(ArgumentError(
        "gradient must be :finite or :implicit; got $gradient"))

    active_trace_solve = trace_solve == :auto ?
        ((logdet_method == :slq || (logdet_method == :auto && p > dense_cutoff)) ?
         :lanczos : :solve) :
        trace_solve
    θ0 = _structured_poisson_initial_theta(Y, K; β_init = β_init, Λ_init = Λ_init)
    active_probes = if probes === nothing &&
            (logdet_method == :slq || (logdet_method == :auto && p > dense_cutoff))
        _rademacher_probes(rng, p, nprobes)
    else
        probes
    end
    Ucache = mode_cache ? zeros(Float64, p) : nothing
    Zcache = mode_cache ? zeros(Float64, K, size(Y, 2)) : nothing
    initial_loglik = -_fit_structured_poisson_objective(
        θ0, Y, precision, p, K; sigma2 = sigma2, logdet_method = logdet_method,
        dense_cutoff = dense_cutoff, probes = active_probes, nprobes = nprobes,
        lanczos_steps = lanczos_steps, reorth = reorth, mode_solve = mode_solve,
        cg_tol = cg_tol, cg_maxiter = cg_maxiter, maxiter = maxiter, tol = tol,
        U_init = Ucache, Z_init = Zcache, U_store = Ucache, Z_store = Zcache)

    negll(θ) = _fit_structured_poisson_objective(
        θ, Y, precision, p, K; sigma2 = sigma2, logdet_method = logdet_method,
        dense_cutoff = dense_cutoff, probes = active_probes, nprobes = nprobes,
        lanczos_steps = lanczos_steps, reorth = reorth, mode_solve = mode_solve,
        cg_tol = cg_tol, cg_maxiter = cg_maxiter, maxiter = maxiter, tol = tol,
        U_init = Ucache, Z_init = Zcache, U_store = Ucache, Z_store = Zcache)
    value_grad(θ) = _structured_poisson_implicit_value_grad(
        θ, Y, precision, p, K; sigma2 = sigma2, logdet_method = logdet_method,
        dense_cutoff = dense_cutoff, probes = active_probes, rng = rng,
        nprobes = nprobes, lanczos_steps = lanczos_steps, reorth = reorth,
        mode_solve = mode_solve, trace_solve = active_trace_solve,
        cg_tol = cg_tol, cg_maxiter = cg_maxiter,
        maxiter = maxiter, tol = tol,
        U_init = Ucache, Z_init = Zcache, U_store = Ucache, Z_store = Zcache)
    negll_fg!(F, G, θ) = _penalized_negloglik_fg!(F, G, value_grad, θ)
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    opts = Optim.Options(g_tol = g_tol, iterations = iterations)
    res = if gradient == :finite
        Optim.optimize(negll, θ0, ls, opts; autodiff = :finite)
    else
        Optim.optimize(Optim.only_fg!(negll_fg!), θ0, ls, opts)
    end
    θ̂ = Optim.minimizer(res)
    β̂, Λ̂ = _structured_poisson_unpackθ(θ̂, p, K)
    return (β = collect(β̂), Λ = Matrix(Λ̂), loglik = -Optim.minimum(res),
            initial_loglik = initial_loglik, converged = Optim.converged(res),
            iterations = Optim.iterations(res), objective_calls = Optim.f_calls(res),
            gradient_calls = Optim.g_calls(res), mode_solve = mode_solve,
            logdet_method = logdet_method, sigma2 = float(sigma2),
            mode_cache = mode_cache, gradient = gradient,
            trace_solve = active_trace_solve)
end
