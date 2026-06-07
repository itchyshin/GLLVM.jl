# Conway–Maxwell–Poisson (CMP / COM-Poisson) family for the GLLVM Laplace path.
#
# A two-parameter count distribution that handles BOTH under- and over-dispersion
# — a capability gllvmTMB does NOT offer. In the *rate* parameterisation,
#
#     P(y) = λ^y / ((y!)^ν · Z(λ,ν)),   y = 0,1,2,…,
#     Z(λ,ν) = Σ_{j=0}^∞ λ^j / (j!)^ν     (the normalising constant),
#
# where ν > 0 is the dispersion exponent:
#     ν = 1 ⇒ Poisson(λ)                  (Z = e^λ; THE correctness anchor),
#     ν > 1 ⇒ underdispersion,
#     ν < 1 ⇒ overdispersion.
# NOTE: λ is the CMP *rate*, NOT the mean (E[y] ≠ λ except at ν=1). This is the
# standard rate form; `predict(..., type=:rate)` therefore returns λ, not E[y].
#
# Link: log link on the rate, λ = exp(η), η = β_t + (Λz_s)_t.
#
# A single latent η drives λ; the family marker carries only the scalar dispersion
# ν. This file runs its OWN per-site Laplace (mirroring ordered_beta.jl /
# beta_binomial.jl): the per-trait score s_t = ∂log p/∂η and weight
# W_t = −∂²log p/∂η² are obtained by ForwardDiff on the scalar map η → log p
# (no hand-derived CMP derivatives), with W_t clamped to ≥ 1e-8 for SPD.
#
# Z(λ,ν) has no closed form for general ν, so its log is computed by summing the
# series to convergence (terms decay fast once j > λ^{1/ν}); the sum is written
# generically so it is ForwardDiff-Dual-safe (η is a Dual during differentiation):
# log(j!) = loggamma(j+1) (SpecialFunctions), and the accumulators take the type
# of η. Truncate when the added term is < 1e-12 of the running sum (hard cap
# 10_000, mirroring the NB1 Fisher-sum idiom in families/negbin1.jl).

"""
    COMPoisson(ν)

Conway–Maxwell–Poisson family marker (rate parameterisation). `ν > 0` is the
dispersion exponent: `ν = 1` ⇒ Poisson, `ν > 1` ⇒ underdispersion, `ν < 1` ⇒
overdispersion. Named to avoid colliding with any `Distributions` type; used only
as a tag for the dedicated CMP Laplace path.
"""
struct COMPoisson <: Distribution{Univariate, Discrete}
    ν::Float64
end

const _CMP_LOGZ_TOL = 1e-12
const _CMP_LOGZ_CAP = 10_000

"""
    compoisson_logz(logλ, ν) -> (type of logλ)

Log normalising constant `log Z(λ,ν)` with `λ = exp(logλ)`, computed by summing
`Z = Σ_j exp(j·logλ − ν·loggamma(j+1))` to convergence. Written generically so it
is ForwardDiff-Dual-safe (accumulators take the type of `logλ`). The series is
truncated once an added term is `< 1e-12` of the running sum (hard cap 10_000
terms). At `ν = 1` this returns `λ` exactly (`Z = e^λ`), the Poisson anchor.
"""
function compoisson_logz(logλ, ν)
    T = promote_type(typeof(logλ), typeof(ν))
    # j = 0 term is exp(0) = 1; the series terms decay fast once j > λ^{1/ν}.
    Z = one(T)
    j = 0
    @inbounds while j < _CMP_LOGZ_CAP
        j += 1
        logterm = j * logλ - ν * loggamma(T(j + 1))
        term = exp(logterm)
        Z += term
        term < _CMP_LOGZ_TOL * Z && break
    end
    return log(Z)
end

"""
    compoisson_logpdf(y, η, ν) -> Float64

Scalar CMP log-pmf `log P(y | λ=exp(η), ν)` for one trait, in the rate form
`log p = y·log λ − ν·loggamma(y+1) − log Z(λ,ν)`, with `log λ = η` clamped via
`_clamp_eta` (so `λ ≤ exp(30)`). Dual-safe (`compoisson_logz` accumulates in the
type of `η`). At `ν = 1` this equals the Poisson(λ) log-pmf.
"""
function compoisson_logpdf(y, η, ν)
    logλ = _clamp_eta(η)
    logZ = compoisson_logz(logλ, ν)
    return y * logλ - ν * loggamma(oftype(logλ, y) + 1) - logZ
end

# Per-trait score s_t = ∂log p/∂η and weight W_t = −∂²log p/∂η², via ForwardDiff
# on the scalar map η → log p. W clamped to ≥ 1e-8 to keep Λ'WΛ + I SPD.
function _cmp_score_weight(y, η, ν)
    f = ηv -> compoisson_logpdf(y, ηv, ν)
    g = ηv -> ForwardDiff.derivative(f, ηv)
    s = g(η)
    W = -ForwardDiff.derivative(g, η)
    return s, max(W, 1e-8)
end

# Inner Laplace mode-finder for one site (Newton on the negative second
# derivative). Mirrors `_beta_binomial_mode` / `_ordered_beta_mode`.
function _compoisson_mode(y::AbstractVector, Λ::AbstractMatrix, β::AbstractVector,
        ν::Real; maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    z = zeros(K)
    for _ in 1:maxiter
        η = β .+ Λ * z
        s = Vector{Float64}(undef, p)
        W = Vector{Float64}(undef, p)
        @inbounds for t in 1:p
            st, Wt = _cmp_score_weight(y[t], η[t], ν)
            s[t] = st
            W[t] = Wt
        end
        A = Symmetric(Λ' * (W .* Λ) + I)
        Δ = _safe_solve(A, Λ' * s .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break
        z = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

# Per-site Laplace log-marginal:
#   log p(y_s) ≈ ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I).
function _compoisson_loglik_site(y::AbstractVector, Λ::AbstractMatrix,
        β::AbstractVector, ν::Real; maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    z = _compoisson_mode(y, Λ, β, ν; maxiter = maxiter, tol = tol)
    η = β .+ Λ * z
    ℓ = 0.0
    W = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        ℓ += compoisson_logpdf(y[t], η[t], ν)
        _, Wt = _cmp_score_weight(y[t], η[t], ν)
        W[t] = Wt
    end
    A = Symmetric(Λ' * (W .* Λ) + I)
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

"""
    compoisson_marginal_loglik_laplace(Y, Λ, β, ν; link=LogLink(), maxiter=100, tol=1e-9) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Conway–Maxwell–Poisson
GLLVM with dispersion `ν` (rate parameterisation, log link `λ = exp(η)`). `Y` is the
p×n integer count matrix; `Λ` p×K loadings; `β` length-p intercepts. Runs its own
per-site Laplace (single latent η). At `Λ = 0` this reduces exactly to the sum of
the independent CMP `logp`; at `ν = 1` it equals the Poisson marginal (the anchor).

The `link` keyword is accepted for interface symmetry with the other count
families but is fixed to the log link on the rate (`λ = exp(η)`); a non-log link is
not meaningful in the rate form.
"""
function compoisson_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, ν::Real; link::Link = LogLink(),
        maxiter::Integer = 100, tol::Real = 1e-9)
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        acc += _compoisson_loglik_site(view(Y, :, i), Λ, β, ν;
                                       maxiter = maxiter, tol = tol)
    end
    return acc
end

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    COMPoissonFit

Result of [`fit_compoisson_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the `link` (always the log link on the rate), the dispersion exponent `ν`
(`ν=1` Poisson, `ν>1` under-, `ν<1` overdispersion), the maximised Laplace
`loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct COMPoissonFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    link::Link
    ν::Float64
    loglik::Float64
    converged::Bool
    iterations::Int
end

# ---------------------------------------------------------------------------
# Post-fit ordination: getLV / predict. A single latent η drives λ (the family
# marker carries ν), so the per-site mode is this file's own `_compoisson_mode`,
# and :rate returns the CMP rate λ = exp(η) (NOT the mean).
# ---------------------------------------------------------------------------

_loadings(fit::COMPoissonFit) = fit.Λ
_loglik(fit::COMPoissonFit)   = fit.loglik

# Free params: β (p) + reduced loadings Λ + dispersion ν.
function _nparams(fit::COMPoissonFit)
    p, K = size(fit.Λ)
    return p + (p * K - div(K * (K - 1), 2)) + 1       # β + Λ + ν
end

"""
    getLV(fit::COMPoissonFit, Y; rotate=true) -> n×K matrix

Conditional latent-variable scores for a CMP fit: the per-site Laplace mode `ẑₛ`
(`_compoisson_mode`) at the fitted `(Λ, β)` and dispersion `ν`. `Y` is the `p×n`
integer count matrix; `rotate=true` applies the canonical [`rotation`](@ref).
"""
function getLV(fit::COMPoissonFit, Y::AbstractMatrix{<:Real}; rotate::Bool = true)
    p, n = size(Y)
    K = size(fit.Λ, 2)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _compoisson_mode(view(Y, :, s), fit.Λ, fit.β, fit.ν)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::COMPoissonFit, Y; type=:rate) -> p×n matrix

In-sample fitted values at the Laplace mode `ẑ` (see [`getLV`](@ref)): `type=:link`
returns the linear predictor `η = β + Λ ẑ`; `type=:rate` returns the CMP **rate**
`λ = exp(η)` (η clamped). NOTE: in the rate parameterisation `λ` is NOT the mean
`E[y]` (they coincide only at `ν=1`); there is no closed-form mean, so `predict`
returns the rate, not the expectation.
"""
function predict(fit::COMPoissonFit, Y::AbstractMatrix{<:Real}; type::Symbol = :rate)
    type in (:link, :rate) ||
        throw(ArgumentError("type must be :link or :rate; got :$type"))
    Z = getLV(fit, Y; rotate = false)                 # n×K
    η = fit.β .+ fit.Λ * Z'                            # p×n
    type === :link && return η
    return exp.(_clamp_eta.(η))
end

function Base.show(io::IO, f::COMPoissonFit)
    p, K = size(f.Λ)
    print(io, "COMPoissonFit(p=", p, ", K=", K, ", link=", nameof(typeof(f.link)),
          ", ν=", round(f.ν; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_compoisson_gllvm(Y; K, link=LogLink(), ν_init=1.0, …) -> COMPoissonFit

Fit a Conway–Maxwell–Poisson GLLVM by L-BFGS over `[β; vec(Λ); log ν]` on the
Laplace marginal ([`compoisson_marginal_loglik_laplace`](@ref)), jointly estimating
the dispersion exponent `ν > 0` (optimised on the log scale). `Y` is a p×n integer
count matrix; `K` the latent dimension. Finite-difference gradient (the Laplace
inner mode-finder is not forward-AD-friendly). Warm start = empirical log-rate
intercepts (`log` of per-species `(mean + 0.5)`) + an SVD (PPCA-style) loadings
init + `ν₀ = ν_init` (default 1, i.e. Poisson).

The log link on the rate is fixed; `link` is accepted for interface symmetry.
"""
function fit_compoisson_gllvm(Y::AbstractMatrix{<:Real}; K::Integer,
        link::Link = LogLink(), ν_init::Real = 1.0,
        β_init = nothing, Λ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    # warm start: empirical log-rate intercepts (log of per-species (mean+0.5)) +
    # SVD (PPCA-like) loadings.
    Zemp = [log(max(float(Y[t, i]) + 0.5, 1e-4)) for t in 1:p, i in 1:n]
    β0 = β_init === nothing ? vec(sum(Zemp; dims = 2)) ./ n : collect(float.(β_init))
    Λ0 = if Λ_init === nothing
        Zc = Zemp .- β0
        F = svd(Zc)
        kk = min(K, length(F.S))
        L = zeros(p, K)
        @inbounds for j in 1:kk
            L[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
        end
        L
    else
        collect(float.(Λ_init))
    end
    logν0 = log(float(ν_init))

    θ0 = vcat(β0, pack_lambda(Λ0), logν0)
    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        ν = exp(θ[p + rr + 1])
        v = try
            -compoisson_marginal_loglik_laplace(Y, Λ, β, ν; link = link,
                                                maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(negll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :finite)
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    ν̂ = exp(θ̂[p + rr + 1])
    return COMPoissonFit(β̂, Λ̂, link, ν̂, -Optim.minimum(res),
                         Optim.converged(res), Optim.iterations(res))
end
