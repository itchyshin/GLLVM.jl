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

struct _SchurUOperatorWorkspace{T}
    Wsum::Vector{T}
    Achols::Vector{Cholesky{T, Matrix{T}}}
    Amats::Vector{Matrix{T}}
end

_matrix_storage(A::Matrix{T}, ::Type{T}) where {T} = A
_matrix_storage(A::AbstractMatrix, ::Type{T}) where {T} = Matrix{T}(A)

_schur_precision_parent(precision::Matrix{T}, ::Type{T}) where {T} = precision
_schur_precision_parent(precision::AbstractMatrix, ::Type{T}) where {T} =
    Matrix{T}(precision)

function _schur_precision_parent(
        precision::SparseArrays.SparseMatrixCSC{T, Ti}, ::Type{T}) where {T, Ti}
    return precision
end

function _schur_precision_parent(
        precision::SparseArrays.SparseMatrixCSC{<:Any, Ti}, ::Type{T}) where {T, Ti}
    return SparseArrays.SparseMatrixCSC{T, Ti}(precision)
end

_schur_precision_storage(precision::AbstractMatrix, ::Type{T}) where {T} =
    Symmetric(_schur_precision_parent(precision, T))

function _schur_precision_storage(precision::Symmetric, ::Type{T}) where {T}
    return Symmetric(_schur_precision_parent(parent(precision), T), Symbol(precision.uplo))
end

function _SchurUOperatorWorkspace(::Type{T}, p::Integer, K::Integer, nsites::Integer) where {T}
    p > 0 || throw(ArgumentError("p must be positive; got $p"))
    K > 0 || throw(ArgumentError("K must be positive; got $K"))
    nsites > 0 || throw(ArgumentError("nsites must be positive; got $nsites"))
    Wsum = zeros(T, p)
    Amats = [Matrix{T}(I, K, K) for _ in 1:nsites]
    Achols = Vector{Cholesky{T, Matrix{T}}}(undef, nsites)
    @inbounds for s in 1:nsites
        Achols[s] = cholesky!(Symmetric(Amats[s]))
    end
    return _SchurUOperatorWorkspace(Wsum, Achols, Amats)
end

function _check_schur_workspace(ws::_SchurUOperatorWorkspace, p::Integer,
        K::Integer, nsites::Integer)
    length(ws.Wsum) == p || throw(DimensionMismatch(
        "workspace Wsum must have length $p; got $(length(ws.Wsum))"))
    length(ws.Achols) == nsites || throw(DimensionMismatch(
        "workspace Achols must have length $nsites; got $(length(ws.Achols))"))
    length(ws.Amats) == nsites || throw(DimensionMismatch(
        "workspace Amats must have length $nsites; got $(length(ws.Amats))"))
    @inbounds for s in 1:nsites
        size(ws.Amats[s]) == (K, K) || throw(DimensionMismatch(
            "workspace Amats[$s] must be $(K)×$(K); got $(size(ws.Amats[s]))"))
    end
    return nothing
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
    L = _matrix_storage(Lambda, T)
    W = _matrix_storage(Wsites, T)
    Q = _schur_precision_storage(precision, T)
    ws = _SchurUOperatorWorkspace(T, p, K, size(W, 2))
    return _SchurUOperator(Q, L, W, ws; sigma2 = sigma2)
end

function _SchurUOperator(precision::AbstractMatrix, Lambda::AbstractMatrix,
        Wsites::AbstractMatrix, ws::_SchurUOperatorWorkspace; sigma2::Real)
    p, K = size(Lambda)
    size(Wsites, 1) == p || throw(DimensionMismatch(
        "Wsites must have one row per response; got $(size(Wsites, 1)) rows for p=$p"))
    size(precision) == (p, p) || throw(DimensionMismatch(
        "precision must be $(p)×$(p); got $(size(precision))"))
    sigma2 > 0 || throw(ArgumentError("sigma2 must be positive; got $sigma2"))
    nsites = size(Wsites, 2)

    T = promote_type(eltype(precision), eltype(Lambda), eltype(Wsites), typeof(float(sigma2)))
    ws isa _SchurUOperatorWorkspace{T} || throw(ArgumentError(
        "workspace element type must be $T; got $(eltype(ws.Wsum))"))
    _check_schur_workspace(ws, p, K, nsites)
    L = _matrix_storage(Lambda, T)
    W = _matrix_storage(Wsites, T)
    Q = _schur_precision_storage(precision, T)

    fill!(ws.Wsum, zero(T))
    @inbounds for s in axes(W, 2), t in 1:p
        ws.Wsum[t] += W[t, s]
    end
    @inbounds for s in axes(W, 2)
        A = ws.Amats[s]
        fill!(A, zero(T))
        for k in 1:K
            A[k, k] = one(T)
        end
        for t in 1:p
            for k in 1:K
                WLtk = W[t, s] * L[t, k]
                for l in 1:K
                    A[k, l] += WLtk * L[t, l]
                end
            end
        end
        ws.Achols[s] = cholesky!(Symmetric(A))
    end
    return _SchurUOperator(Q, L, W, ws.Wsum, ws.Achols, inv(T(sigma2)))
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
    return _schur_u_dense!(S, op, e, y, tmp, sol)
end

function _symmetrize_schur_dense!(S::AbstractMatrix)
    p = size(S, 1)
    size(S, 2) == p || throw(DimensionMismatch("S must be square; got $(size(S))"))
    half = one(eltype(S)) / 2
    @inbounds for j in 1:p
        for i in (j + 1):p
            v = (S[i, j] + S[j, i]) * half
            S[i, j] = v
            S[j, i] = v
        end
    end
    return Symmetric(S)
end

function _schur_u_dense!(S::AbstractMatrix, op::_SchurUOperator,
        e::AbstractVector, y::AbstractVector, tmp::AbstractVector, sol::AbstractVector)
    p, K = size(op.Lambda)
    size(S) == (p, p) || throw(DimensionMismatch("S must be $(p)×$(p); got $(size(S))"))
    length(e) == p || throw(DimensionMismatch("e must have length $p; got $(length(e))"))
    length(y) == p || throw(DimensionMismatch("y must have length $p; got $(length(y))"))
    length(tmp) == K || throw(DimensionMismatch("tmp must have length $K; got $(length(tmp))"))
    length(sol) == K || throw(DimensionMismatch("sol must have length $K; got $(length(sol))"))
    T = eltype(op)
    fill!(e, zero(T))
    @inbounds for j in 1:p
        e[j] = one(T)
        _schur_u_mul!(y, op, e, tmp, sol)
        e[j] = zero(T)
        for i in 1:p
            S[i, j] = y[i]
        end
    end
    return _symmetrize_schur_dense!(S)
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

function _orthogonal_probes(rng::AbstractRNG, p::Integer, nprobes::Integer)
    p > 0 || throw(ArgumentError("p must be positive; got $p"))
    nprobes > 0 || throw(ArgumentError("nprobes must be positive; got $nprobes"))
    nprobes <= p || throw(ArgumentError(
        "orthogonal probes require nprobes <= p; got nprobes=$nprobes, p=$p"))
    probes = randn(rng, p, nprobes)
    target_norm2 = float(p)
    @inbounds for j in 1:nprobes
        for h in 1:(j - 1)
            coeff = dot(view(probes, :, h), view(probes, :, j)) / target_norm2
            for i in 1:p
                probes[i, j] -= coeff * probes[i, h]
            end
        end
        normj = norm(view(probes, :, j))
        normj > sqrt(eps(Float64)) || throw(ArgumentError(
            "failed to generate linearly independent orthogonal probe $j"))
        scale = sqrt(float(p)) / normj
        for i in 1:p
            probes[i, j] *= scale
        end
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
    T = promote_type(eltype(op), eltype(x), eltype(b))
    r = Vector{T}(undef, p)
    d = Vector{T}(undef, p)
    q = Vector{T}(undef, p)
    tmp = zeros(T, size(op.Lambda, 2))
    sol = similar(tmp)
    return _schur_u_cg!(x, op, b, r, d, q, tmp, sol; tol = tol, maxiter = maxiter)
end

function _schur_u_cg!(x::AbstractVector, op::_SchurUOperator, b::AbstractVector,
        r::AbstractVector, d::AbstractVector, q::AbstractVector,
        tmp::AbstractVector, sol::AbstractVector;
        tol::Real = 1e-8, maxiter::Integer = max(100, 2 * length(b)))
    p = size(op, 1)
    K = size(op.Lambda, 2)
    length(x) == p || throw(DimensionMismatch("x must have length $p; got $(length(x))"))
    length(b) == p || throw(DimensionMismatch("b must have length $p; got $(length(b))"))
    length(r) == p || throw(DimensionMismatch("r must have length $p; got $(length(r))"))
    length(d) == p || throw(DimensionMismatch("d must have length $p; got $(length(d))"))
    length(q) == p || throw(DimensionMismatch("q must have length $p; got $(length(q))"))
    length(tmp) == K || throw(DimensionMismatch("tmp must have length $K; got $(length(tmp))"))
    length(sol) == K || throw(DimensionMismatch("sol must have length $K; got $(length(sol))"))
    maxiter > 0 || throw(ArgumentError("maxiter must be positive; got $maxiter"))
    tol > 0 || throw(ArgumentError("tol must be positive; got $tol"))

    T = promote_type(eltype(op), eltype(x), eltype(b), eltype(r), eltype(d),
        eltype(q), eltype(tmp), eltype(sol))

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
