# Zero-truncated Poisson (positive Poisson) family pieces for the generic Laplace
# core (src/families/laplace.jl). y_t ∈ {1,2,…} (NO zeros): y ~ Poisson(μ)
# conditioned on y ≥ 1, μ = exp(η) (log link). There is NO dispersion — the rate
# μ is the single per-observation parameter.
#
# Conditional law (Johnson, Kemp & Kotz 2005, Univariate Discrete Distributions,
# §4.10; Cohen 1960):
#   P(y = k | y ≥ 1) = e^{-μ} μ^k / (k! (1 − e^{-μ}))   for k = 1, 2, …
#   ⇒ logpdf = logpdf(Poisson(μ), k) − log(1 − e^{-μ}).
# Mean and variance of the truncated law:
#   μ_tr = E[y | y ≥ 1] = μ / (1 − e^{-μ}),
#   Var[y | y ≥ 1]      = μ_tr (1 + μ − μ_tr).
#
# Score / weight wrt η (log link, dμ/dη = μ), θ = η:
#   ℓ = y log μ − μ − log(y!) − log(1 − e^{-μ}).
#   s = ∂ℓ/∂η = (∂ℓ/∂μ)·μ
#     = (y/μ − 1 − e^{-μ}/(1 − e^{-μ}))·μ
#     = y − μ − μ e^{-μ}/(1 − e^{-μ})
#     = y − μ/(1 − e^{-μ}) = y − μ_tr.
#   W = E[s²] = Var[y | y ≥ 1] = μ_tr (1 + μ − μ_tr)  ≥ 0  (truncated Fisher info).
# These reduce to the plain Poisson (y − μ, μ) as μ → ∞ (e^{-μ} → 0 ⇒ μ_tr → μ).
#
# `_glm_logpdf` is written via `logpdf(Poisson(μ), Int(y))` minus the truncation
# normaliser `log1p(-exp(-μ))` (numerically stable form of log(1 − e^{-μ})). This
# keeps the implicit-gradient path in laplace.jl AD-clean: the per-observation
# (η)-derivatives are taken by ForwardDiff through this closed form (the generic
# `_scalar_laplace_site_implicit_value_grad` path, exactly as NB1 uses it).

"""
    ZeroTruncatedPoisson()

Zero-truncated (positive) Poisson family marker: counts `y ∈ {1, 2, …}` drawn
from `Poisson(μ)` conditioned on `y ≥ 1`, with log link (`μ = exp η`). No
dispersion parameter. Used as the family argument to the generic Laplace core
(the truncated-Poisson twin of the `Poisson()` marker).
"""
struct ZeroTruncatedPoisson end

default_link(::ZeroTruncatedPoisson) = LogLink()

_clamp_mu(::ZeroTruncatedPoisson, μ) = max(μ, 1e-12)

# Truncated mean μ_tr = μ/(1 − e^{-μ}); stable via -expm1(-μ) = 1 − e^{-μ}.
@inline _ztp_mutr(μ) = μ / (-expm1(-μ))

_glm_score(::ZeroTruncatedPoisson, μ, n, me, y) = y - _ztp_mutr(μ)   # log link ⇒ y − μ_tr
function _glm_weight(::ZeroTruncatedPoisson, μ, n, me)
    μtr = _ztp_mutr(μ)
    return μtr * (one(μ) + μ - μtr)                                   # Var[y|y≥1] ≥ 0
end
_glm_logpdf(::ZeroTruncatedPoisson, μ, n, y) =
    logpdf(Poisson(μ), Int(y)) - log1p(-exp(-μ))

"""
    truncpoisson_marginal_loglik_laplace(Y, Λ, β, link=LogLink(); kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a zero-truncated
Poisson GLLVM — a thin wrapper over the family-generic `marginal_loglik_laplace`
with `ZeroTruncatedPoisson()`. `Y` is the p×n integer count matrix (all entries
`≥ 1`); `Λ` p×K; `β` length-p. The truncated Poisson has no trial counts, so a
unit `N` is supplied internally.
"""
truncpoisson_marginal_loglik_laplace(Y::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, link::Link = LogLink(); kwargs...) =
    marginal_loglik_laplace(ZeroTruncatedPoisson(), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    TruncPoissonFit

Result of [`fit_truncpoisson_gllvm`](@ref): intercepts `β` (length p), loadings
`Λ` (p×K), the `link`, the maximised Laplace `loglik`, the optimiser `converged`
flag, and `iterations`. The zero-truncated Poisson carries no dispersion.
"""
struct TruncPoissonFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::TruncPoissonFit)
    p, K = size(f.Λ)
    print(io, "TruncPoissonFit(p=", p, ", K=", K, ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_truncpoisson_gllvm(Y; K, link=LogLink(), …) -> TruncPoissonFit

Fit a zero-truncated Poisson GLLVM by L-BFGS over `[β; vec(Λ)]` on the Laplace
marginal log-likelihood ([`truncpoisson_marginal_loglik_laplace`](@ref)). `Y` is
a p×n integer count matrix (responses × sites) with every entry `≥ 1`; `K` the
latent dimension. Optimises intercepts `β` and loadings `Λ` (no dispersion). The
L-BFGS gradient uses the generic implicit dense-Laplace gradient
(`marginal_loglik_laplace_implicit_value_grad`): the per-site latent mode is
found once by Fisher scoring, then the gradient is taken with the
implicit-function rule, with per-observation `η`-derivatives supplied by
ForwardDiff through the closed-form `_glm_logpdf`. Warm start = empirical
log-mean intercepts + an SVD (PPCA-style) loadings init.
"""
function fit_truncpoisson_gllvm(Y::AbstractMatrix{<:Union{Missing, Integer}}; K::Integer,
        link::Link = LogLink(),
        β_init = nothing, Λ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    all(x -> ismissing(x) || x ≥ 1, Y) || throw(ArgumentError(
        "fit_truncpoisson_gllvm: zero-truncated Poisson requires all observed Y ≥ 1"))
    rr = rr_theta_len(p, K)

    # warm start: empirical log-scale intercepts + SVD (PPCA-like) loadings
    # NA-aware warm start: per-trait observed-cell log-mean intercepts; missing cells
    # mean-filled for the SVD init ONLY (FIML estimator, issue #27). Byte-equivalent on dense Y.
    Zemp = Matrix{Float64}(undef, p, n)
    β0r = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        acc = 0.0; cnt = 0
        for i in 1:n
            if !ismissing(Y[t, i])
                v = linkfun(link, max(Y[t, i] + 0.5, 1e-4)); Zemp[t, i] = v; acc += v; cnt += 1
            end
        end
        m = cnt == 0 ? linkfun(link, 0.5) : acc / cnt
        β0r[t] = m
        for i in 1:n
            ismissing(Y[t, i]) && (Zemp[t, i] = m)
        end
    end
    β0 = β_init === nothing ? β0r : collect(float.(β_init))
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

    θ0 = vcat(β0, pack_lambda(Λ0))
    family_fromθ = _ -> ZeroTruncatedPoisson()
    N = ones(Int, size(Y))
    value_grad(θ) = marginal_loglik_laplace_implicit_value_grad(
        family_fromθ, Y, N, θ, p, K, link; maxiter = newton_maxiter, tol = newton_tol)
    negll_fg!(F, G, θ) = _penalized_negloglik_fg!(F, G, value_grad, θ)
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(Optim.only_fg!(negll_fg!), θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations))
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    return TruncPoissonFit(β̂, Λ̂, link, -Optim.minimum(res),
                           Optim.converged(res), Optim.iterations(res))
end
