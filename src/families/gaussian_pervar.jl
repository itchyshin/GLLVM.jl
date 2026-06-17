# Per-species (heteroscedastic) Gaussian GLLVM marginal log-likelihood + fit.
#
# gllvmTMB's Gaussian default places a *per-species* residual SD φ_j on each
# trait, so V[y_{·j}] = φ_j². GLLVM.jl's shared-σ Gaussian path (src/likelihood.jl,
# src/fit.jl, src/profile.jl) uses a single σ_eps and is left UNTOUCHED. This file
# adds a parallel per-species variant.
#
# The only change relative to the scalar marginal is the per-trait diagonal of the
# marginal site covariance:
#
#   shared-σ:    M = Λ Λ' + σ_eps² · I_p          (constant diagonal)
#   per-species: M = Λ Λ' + diag(φ²_1, …, φ²_p)   (per-trait diagonal)
#
# Each site y_s ~ N(μ (+ X_s β), M). `low_rank_chol(Λ, d)` already accepts a
# length-p positive diagonal `d` and provides Woodbury logdet / solves for
# M = Λ Λ' + diag(d); per-species variance is just `d = φ²vec`. No new linear
# algebra is introduced — the quadratic form, logdet, and β/X handling mirror
# `gaussian_marginal_loglik` (src/likelihood.jl) exactly.
#
# The shared-σ fit profiles the single σ_eps analytically (src/profile.jl). That
# closed-form profile does NOT generalise to a per-species vector, so the
# per-species fit optimises the variances numerically — expected and fine.

using LinearAlgebra

"""
    gaussian_pervar_marginal_loglik(y, Λ, φ²vec; X=nothing, β=nothing) -> Real

Gaussian GLLVM marginal log-likelihood with **per-species** (heteroscedastic)
residual variances. `y` is `p × n_sites`, `Λ` is `p × K` unit-tier loadings, and
`φ²vec` is the length-`p` vector of per-species residual **variances** `V_j = φ_j²`
(NOT SDs).

Each site `y_s ~ N(X_s β, M)` with `M = Λ Λ' + diag(φ²vec)`. The marginal is
computed via the Woodbury / matrix-determinant-lemma factorisation
[`low_rank_chol`](@ref), exactly as the shared-σ marginal does, but with the
constant diagonal `σ_eps²·I` replaced by the supplied per-species diagonal.

Fixed effects: pass both `X::Array{<:Real,3}` of shape `(p, n_sites, q)` and
`β::Vector` of length `q`, or neither. When `β`/`X` are omitted the residual is
`y` itself (no centering) — identical to `gaussian_marginal_loglik`'s convention.

Passing a constant variance vector `fill(σ², p)` reproduces the scalar marginal
`gaussian_marginal_loglik(y, Λ, sqrt(σ²); …)` to machine precision.
"""
function gaussian_pervar_marginal_loglik(y::AbstractMatrix, Λ::AbstractMatrix,
                                         φ²vec::AbstractVector;
                                         X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                                         β::Union{Nothing, AbstractVector} = nothing)
    p, n = size(y)
    K    = size(Λ, 2)
    length(φ²vec) == p ||
        throw(ArgumentError("φ²vec length ($(length(φ²vec))) must equal p ($p)"))
    T = promote_type(eltype(y), eltype(Λ), eltype(φ²vec))

    # Residual ε = y - X β if fixed effects supplied (mirrors likelihood.jl).
    if X === nothing && β === nothing
        resid = y
        Tres = T
    else
        (X === nothing || β === nothing) &&
            throw(ArgumentError("Provide both X and β or neither"))
        q = size(X, 3)
        size(X, 1) == p ||
            throw(ArgumentError("X first dim ($(size(X,1))) must equal p ($p)"))
        size(X, 2) == n ||
            throw(ArgumentError("X second dim ($(size(X,2))) must equal n_sites ($n)"))
        length(β) == q ||
            throw(ArgumentError("β length ($(length(β))) must equal size(X, 3) ($q)"))
        Tres = promote_type(T, eltype(X), eltype(β))
        resid = Matrix{Tres}(undef, p, n)
        @inbounds for s in 1:n, t in 1:p
            μ_ts = zero(Tres)
            for k in 1:q
                μ_ts += X[t, s, k] * β[k]
            end
            resid[t, s] = y[t, s] - μ_ts
        end
    end

    # Per-species diagonal: d[t] = φ²_t. This is the ONLY substantive difference
    # from the shared-σ marginal (which uses d[t] = σ_eps² for all t).
    Td = promote_type(T, eltype(φ²vec))
    d  = Vector{Td}(undef, p)
    @inbounds for t in 1:p
        d[t] = convert(Td, φ²vec[t])
    end

    # Woodbury factorisation of M = Λ Λ' + diag(d) (src/lowrank_cholesky.jl).
    F = low_rank_chol(Λ, d)
    logdet_M = logdet(F)

    # Quadratic form Σ_s r_s' M⁻¹ r_s via the Woodbury solves.
    Minv_r = F \ resid                 # p × n
    quad   = sum(resid .* Minv_r)

    Tout = promote_type(Tres, Td)
    return -convert(Tout, 0.5) * (n * p * log(convert(Tout, 2π)) + n * logdet_M + quad)
end

"""
    GaussianPerVarFit

Result of [`fit_gaussian_pervar_gllvm`](@ref): the heteroscedastic Gaussian GLLVM
fit with a per-species residual variance.

Fields:
- `β::Vector`    — per-species intercept (length `p`; the profiled column means).
- `Λ::Matrix`    — fitted unit-tier loadings (`p × K`).
- `φ²::Vector`   — per-species residual variances `V_j = φ_j²` (length `p`).
- `loglik`       — converged marginal log-likelihood.
- `converged`    — Optim convergence flag.
- `iterations`   — Optim iteration count.
"""
struct GaussianPerVarFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    φ²::Vector{Float64}
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, fit::GaussianPerVarFit)
    p, K = size(fit.Λ)
    print(io, "GaussianPerVarFit(p=$p, K=$K, loglik=",
          round(fit.loglik; digits = 4),
          ", converged=", fit.converged,
          ", iterations=", fit.iterations, ")")
end

_loadings(fit::GaussianPerVarFit) = fit.Λ
_loglik(fit::GaussianPerVarFit)   = fit.loglik

# Free params: β (p) + reduced loadings Λ + one residual variance per species (p).
function _nparams(fit::GaussianPerVarFit)
    p, K = size(fit.Λ)
    return p + rr_theta_len(p, K) + p   # β + Λ + p per-species variances φ²
end

"""
    fit_gaussian_pervar_gllvm(Y; K, X=nothing, g_tol=1e-5, iterations=1000)
        -> GaussianPerVarFit

Fit a heteroscedastic (per-species variance) Gaussian GLLVM by L-BFGS.

`Y` is `p × n_sites`. Optimises `θ = [vec(packed Λ); log φ²_1 … log φ²_p]` with
the per-species intercept `β` (length `p`) profiled out analytically as the column
means each evaluation — for an intercept-only Gaussian the sample column mean is the
exact ML / GLS estimate regardless of the covariance, so this is profiling, not an
approximation.

Warm start: PPCA closed form (Tipping & Bishop 1999) for `Λ` and per-species
residual variances initialised from the per-species sample variances of `Y`.

The shared-σ `fit_gaussian_gllvm` is untouched; this is a parallel variant.
"""
function fit_gaussian_pervar_gllvm(Y::AbstractMatrix;
                                   K::Integer,
                                   X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                                   method::Symbol = :em,
                                   g_tol::Real = 1e-5,
                                   em_tol::Real = 1e-8,
                                   iterations::Integer = 1000)
    p, n = size(Y)
    @assert K ≥ 1
    @assert n ≥ 2 "Need n_sites ≥ 2 for per-species variances"

    Yf = Matrix{Float64}(Y)

    # Per-species intercept profiled as column means. Centre Y once for the
    # warm-start; the objective recomputes the profile internally.
    μ0 = vec(sum(Yf, dims = 2)) ./ n           # length p
    Yc = Yf .- reshape(μ0, p, 1)               # centred

    # ----- Warm starts.
    # Λ via PPCA on the centred data (requires K < p); otherwise fall back to
    # the default lower-triangular init.
    Λ0 = if K < p
        Λp, _ = ppca_init(Yc, K)
        Λp
    else
        unpack_lambda(init_theta_rr(p, K), p, K)
    end
    θ_Λ0 = pack_lambda(Λ0)
    rrlen = rr_theta_len(p, K)

    # Per-species variance init: per-species sample variance of the centred data,
    # floored away from zero. Use a fraction so it does not absorb the loadings.
    col_var = vec(sum(abs2, Yc, dims = 2)) ./ max(n - 1, 1)   # length p
    φ²_0 = max.(0.5 .* col_var, 1e-3)
    logφ²_0 = log.(φ²_0)

    params0 = vcat(θ_Λ0, logφ²_0)

    # Fast path: closed-form EM for factor analysis (Rubin & Thayer 1982, `em_fa`)
    # on the IDENTICAL Λ Λ' + diag(φ²) model. No inner AD — reaches the same ML
    # optimum 1–2 orders of magnitude faster than the L-BFGS + ForwardDiff path.
    # Requires the FA regime K < p and no fixed effects; otherwise fall through to
    # L-BFGS. The per-species intercept is the profiled column means (β = μ0), so
    # EM runs on the centred residual `Yc`.
    if method === :em && K < p && X === nothing
        Λ_em, φ²_em, ll_em, nit_em, conv_em =
            em_fa(Yc, K; λ_init = Λ0, ψ_init = φ²_0, tol = em_tol,
                  max_iter = max(Int(iterations), 2000))
        return GaussianPerVarFit(
            collect(Float64, μ0),
            Matrix{Float64}(Λ_em),
            collect(Float64, φ²_em),
            Float64(ll_em),
            conv_em,
            nit_em,
        )
    end

    # Objective: profile the per-species intercept as the residual column means,
    # then evaluate the per-species marginal NLL on the centred residual.
    function nll(params)
        θ_Λ   = @view params[1:rrlen]
        logφ² = @view params[(rrlen + 1):(rrlen + p)]
        Λ     = unpack_lambda(θ_Λ, p, K)
        φ²    = exp.(logφ²)
        # Profile intercept: subtract per-species column means (exact ML for the
        # intercept-only Gaussian, any covariance). Column means are constants in
        # the parameters, so this stays AD-clean.
        resid = Yf .- reshape(μ0, p, 1)
        return -gaussian_pervar_marginal_loglik(resid, Λ, φ²)
    end

    opts = Optim.Options(g_tol = g_tol, iterations = Int(iterations),
                         show_trace = false)
    res = Optim.optimize(nll, params0, Optim.LBFGS(), opts; autodiff = :forward)

    params_hat = Optim.minimizer(res)
    θ_Λ_hat   = params_hat[1:rrlen]
    logφ²_hat = params_hat[(rrlen + 1):(rrlen + p)]
    Λ_hat     = unpack_lambda(θ_Λ_hat, p, K)
    φ²_hat    = exp.(logφ²_hat)

    # Recover the profiled per-species intercept (column means).
    β_hat = vec(sum(Yf, dims = 2)) ./ n

    ll = -Optim.minimum(res)

    return GaussianPerVarFit(
        collect(Float64, β_hat),
        Matrix{Float64}(Λ_hat),
        collect(Float64, φ²_hat),
        Float64(ll),
        Optim.converged(res),
        Optim.iterations(res),
    )
end
