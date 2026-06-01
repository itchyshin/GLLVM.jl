# Matrix-free Schur-complement operator for the planned non-Gaussian structured
# dependence Laplace path. This is an internal substrate: it is not wired into
# fitters yet.

struct _SchurUOperator{T,TP<:AbstractMatrix{T}}
    precision::TP
    Lambda::Matrix{T}
    Wsites::Matrix{T}
    Wsum::Vector{T}
    Achols::Vector{Cholesky{T, Matrix{T}}}
    invsigma2::T
end

_schur_precision_parent(precision::AbstractMatrix, ::Type{T}) where {T} =
    Matrix{T}(precision)

function _schur_precision_parent(
        precision::SparseArrays.SparseMatrixCSC{<:Any, Ti}, ::Type{T}) where {T, Ti}
    return SparseArrays.SparseMatrixCSC{T, Ti}(precision)
end

_schur_precision_storage(precision::AbstractMatrix, ::Type{T}) where {T} =
    Symmetric(_schur_precision_parent(precision, T))

function _schur_precision_storage(precision::Symmetric, ::Type{T}) where {T}
    return Symmetric(_schur_precision_parent(parent(precision), T), Symbol(precision.uplo))
end

function _SchurUOperator(precision::AbstractMatrix, Lambda::AbstractMatrix,
        Wsites::AbstractMatrix; sigma2::Real)
    p, K = size(Lambda)
    size(Wsites, 1) == p || throw(DimensionMismatch(
        "Wsites must have one row per response; got $(size(Wsites, 1)) rows for p=$p"))
    size(precision) == (p, p) || throw(DimensionMismatch(
        "precision must be $(p)×$(p); got $(size(precision))"))
    sigma2 > 0 || throw(ArgumentError("sigma2 must be positive; got $sigma2"))

    T = promote_type(eltype(precision), eltype(Lambda), eltype(Wsites), typeof(float(sigma2)))
    L = Matrix{T}(Lambda)
    W = Matrix{T}(Wsites)
    Q = _schur_precision_storage(precision, T)
    Wsum = vec(sum(W; dims = 2))
    Achols = Vector{Cholesky{T, Matrix{T}}}(undef, size(W, 2))
    @inbounds for s in axes(W, 2)
        A = Matrix{T}(I, K, K)
        for t in 1:p
            for k in 1:K
                WLtk = W[t, s] * L[t, k]
                for l in 1:K
                    A[k, l] += WLtk * L[t, l]
                end
            end
        end
        Achols[s] = cholesky(Symmetric(A))
    end
    return _SchurUOperator(Q, L, W, Wsum, Achols, inv(T(sigma2)))
end

Base.size(op::_SchurUOperator) = (size(op.Lambda, 1), size(op.Lambda, 1))
Base.size(op::_SchurUOperator, d::Integer) = size(op)[d]
Base.eltype(::_SchurUOperator{T}) where {T} = T

function LinearAlgebra.mul!(y::AbstractVector, op::_SchurUOperator, x::AbstractVector)
    K = size(op.Lambda, 2)
    tmp = zeros(eltype(op), K)
    sol = zeros(eltype(op), K)
    return _schur_u_mul!(y, op, x, tmp, sol)
end

function _schur_u_mul!(y::AbstractVector, op::_SchurUOperator, x::AbstractVector,
        tmp::AbstractVector, sol::AbstractVector)
    p, K = size(op.Lambda)
    length(x) == p || throw(DimensionMismatch("x must have length $p; got $(length(x))"))
    length(y) == p || throw(DimensionMismatch("y must have length $p; got $(length(y))"))
    length(tmp) == K || throw(DimensionMismatch("tmp must have length $K; got $(length(tmp))"))
    length(sol) == K || throw(DimensionMismatch("sol must have length $K; got $(length(sol))"))
    T = eltype(op)

    mul!(y, op.precision, x)
    @inbounds for t in 1:p
        y[t] = op.invsigma2 * y[t] + op.Wsum[t] * x[t]
    end

    @inbounds for s in axes(op.Wsites, 2)
        fill!(tmp, zero(T))
        for t in 1:p
            Wtx = op.Wsites[t, s] * x[t]
            for k in 1:K
                tmp[k] += op.Lambda[t, k] * Wtx
            end
        end
        copyto!(sol, tmp)
        ldiv!(op.Achols[s], sol)
        for t in 1:p
            correction = zero(T)
            for k in 1:K
                correction += op.Lambda[t, k] * sol[k]
            end
            y[t] -= op.Wsites[t, s] * correction
        end
    end
    return y
end

function _schur_u_dense(op::_SchurUOperator)
    p = size(op, 1)
    T = eltype(op)
    S = Matrix{T}(undef, p, p)
    e = zeros(T, p)
    y = zeros(T, p)
    tmp = zeros(T, size(op.Lambda, 2))
    sol = similar(tmp)
    @inbounds for j in 1:p
        fill!(e, zero(T))
        e[j] = one(T)
        _schur_u_mul!(y, op, e, tmp, sol)
        S[:, j] .= y
    end
    return Symmetric((S + S') ./ 2)
end

function _rademacher_probes(rng::AbstractRNG, p::Integer, nprobes::Integer)
    p > 0 || throw(ArgumentError("p must be positive; got $p"))
    nprobes > 0 || throw(ArgumentError("nprobes must be positive; got $nprobes"))
    probes = Matrix{Float64}(undef, p, nprobes)
    @inbounds for j in 1:nprobes, i in 1:p
        probes[i, j] = rand(rng, Bool) ? 1.0 : -1.0
    end
    return probes
end

function _slq_logdet(op::_SchurUOperator, probes::AbstractMatrix;
        lanczos_steps::Integer = 40, reorth::Bool = false)
    p = size(op, 1)
    size(probes, 1) == p || throw(DimensionMismatch(
        "probes must have $p rows; got $(size(probes, 1))"))
    nprobes = size(probes, 2)
    nprobes > 0 || throw(ArgumentError("at least one probe is required"))
    mmax = min(Int(lanczos_steps), p)
    mmax > 0 || throw(ArgumentError("lanczos_steps must be positive; got $lanczos_steps"))

    T = promote_type(eltype(op), eltype(probes))
    q = zeros(T, p)
    qprev = zeros(T, p)
    w = zeros(T, p)
    tmp = zeros(T, size(op.Lambda, 2))
    sol = similar(tmp)
    Qbasis = Matrix{T}(undef, p, mmax)
    alphas = Vector{T}(undef, mmax)
    betas = Vector{T}(undef, max(mmax - 1, 0))
    total = zero(T)

    @inbounds for j in 1:nprobes
        copyto!(q, view(probes, :, j))
        probe_norm2 = dot(q, q)
        probe_norm2 > 0 || throw(ArgumentError("probe $j has zero norm"))
        q ./= sqrt(probe_norm2)
        fill!(qprev, zero(T))
        beta_prev = zero(T)
        m = 0
        for k in 1:mmax
            _schur_u_mul!(w, op, q, tmp, sol)
            if k > 1
                @. w -= beta_prev * qprev
            end
            alpha = dot(q, w)
            @. w -= alpha * q
            if reorth
                for h in 1:(k - 1)
                    coeff = dot(view(Qbasis, :, h), w)
                    for i in 1:p
                        w[i] -= coeff * Qbasis[i, h]
                    end
                end
            end
            alphas[k] = alpha
            Qbasis[:, k] .= q
            m = k
            if k == mmax
                break
            end
            beta = norm(w)
            beta <= sqrt(eps(T)) && break
            betas[k] = beta
            copyto!(qprev, q)
            @. q = w / beta
            beta_prev = beta
        end
        Ttri = SymTridiagonal(view(alphas, 1:m), view(betas, 1:max(m - 1, 0)))
        F = eigen(Ttri)
        vals = F.values
        minimum(vals) > 0 || throw(ArgumentError(
            "Lanczos tridiagonal is not positive definite; minimum eigenvalue $(minimum(vals))"))
        probe_est = zero(T)
        for h in eachindex(vals)
            probe_est += abs2(F.vectors[1, h]) * log(vals[h])
        end
        total += probe_norm2 * probe_est
    end
    return total / nprobes
end

function _schur_u_logdet(op::_SchurUOperator; method::Symbol = :auto,
        dense_cutoff::Integer = 256, probes::Union{Nothing, AbstractMatrix} = nothing,
        rng::AbstractRNG = Random.default_rng(), nprobes::Integer = 16,
        lanczos_steps::Integer = 40, reorth::Bool = false)
    p = size(op, 1)
    dense_cutoff >= 0 || throw(ArgumentError("dense_cutoff must be non-negative; got $dense_cutoff"))

    if method == :dense || (method == :auto && p <= dense_cutoff)
        return logdet(cholesky(_schur_u_dense(op)))
    elseif method == :slq || method == :auto
        active_probes = probes === nothing ? _rademacher_probes(rng, p, nprobes) : probes
        return _slq_logdet(op, active_probes; lanczos_steps = lanczos_steps, reorth = reorth)
    else
        throw(ArgumentError("method must be :auto, :dense, or :slq; got $method"))
    end
end

function _schur_u_cg!(x::AbstractVector, op::_SchurUOperator, b::AbstractVector;
        tol::Real = 1e-8, maxiter::Integer = max(100, 2 * length(b)))
    p = size(op, 1)
    length(x) == p || throw(DimensionMismatch("x must have length $p; got $(length(x))"))
    length(b) == p || throw(DimensionMismatch("b must have length $p; got $(length(b))"))
    maxiter > 0 || throw(ArgumentError("maxiter must be positive; got $maxiter"))
    tol > 0 || throw(ArgumentError("tol must be positive; got $tol"))

    T = promote_type(eltype(op), eltype(x), eltype(b))
    r = Vector{T}(undef, p)
    d = Vector{T}(undef, p)
    q = Vector{T}(undef, p)
    tmp = zeros(T, size(op.Lambda, 2))
    sol = similar(tmp)

    _schur_u_mul!(q, op, x, tmp, sol)
    @inbounds for i in 1:p
        r[i] = b[i] - q[i]
        d[i] = r[i]
    end
    rsold = dot(r, r)
    threshold = (T(tol) * max(norm(b), one(T)))^2
    if rsold <= threshold
        return (converged = true, iterations = 0, residual = sqrt(rsold))
    end

    iterations = 0
    for iter in 1:maxiter
        iterations = iter
        _schur_u_mul!(q, op, d, tmp, sol)
        denom = dot(d, q)
        denom > zero(T) || break
        α = rsold / denom
        @inbounds for i in 1:p
            x[i] += α * d[i]
            r[i] -= α * q[i]
        end
        rsnew = dot(r, r)
        if rsnew <= threshold
            return (converged = true, iterations = iterations, residual = sqrt(rsnew))
        end
        β = rsnew / rsold
        @inbounds for i in 1:p
            d[i] = r[i] + β * d[i]
        end
        rsold = rsnew
    end
    return (converged = false, iterations = iterations, residual = sqrt(rsold))
end
