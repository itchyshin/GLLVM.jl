# Wald confidence intervals via the observed information matrix for two of the
# recently-added non-Gaussian GLLVM fitters: zero-inflated Binomial (ZIBinom) and
# Generalized Poisson (GP-1). This file is *additive* — like src/confint_families.jl
# it does not touch the family fit drivers in src/families/*.jl. Each
# `confint(::<FitType>)` method below
#   1. reassembles the packed parameter vector θ̂ in the SAME parameterisation the
#      fitter optimised it,
#   2. builds a PURE-VALUE NLL closure nll(θ) = -<family>_marginal_loglik_laplace(…)
#      reassembled from θ via the existing value functions (so ForwardDiff sees a
#      clean function), and
#   3. calls the shared `_nongaussian_wald_ci` routine (defined in
#      src/confint_families.jl) with the per-parameter back-transform kinds.
#
# Back-transform convention (matches src/confint_families.jl):
#   :linear → estimate as-is, CI = θ̂ ± z·SE
#   :logit  → estimate = logistic(θ̂), CI = logistic(θ̂ ± z·SE)  (probability in (0,1))
#
# NOTE on CMPoisson (CMPoissonFit): a confint method is intentionally NOT provided
# here. Its marginal `compoisson_marginal_loglik_laplace` evaluates a *truncated
# infinite sum* (the COM-Poisson normaliser Z and its moments) at every cell on every
# objective evaluation, so a ForwardDiff Hessian over θ would be both very slow and
# numerically fragile (the truncation cap is primal-only, and second derivatives of
# the streaming log-sum-exp through Duals-of-Duals are delicate). Wald inference for
# CMPoisson is deferred as a follow-up — a hand-coded or finite-difference observed
# information would be the appropriate route.

# ---------------------------------------------------------------------------
# Zero-inflated Binomial (β, Λ, logit π; needs trial counts N).
# ---------------------------------------------------------------------------

"""
    confint(fit::ZIBinomFit; Y, N=nothing, level=0.95, parm=nothing) -> NamedTuple

Wald CIs (observed information) for a fitted zero-inflated Binomial (ZIBinom) GLLVM.
`Y` is the p×n success-count matrix; `N` the matching trial counts (default all-ones,
i.e. zero-inflated Bernoulli) — pass the same `N` used in `fit_zibinom_gllvm`. β and Λ
are linear; the zero-inflation probability `π` is parameterised internally on the logit
scale, so `"pi"` is reported on the (0,1) scale via `logistic(logit π ± z·SE)`.
"""
function confint(fit::ZIBinomFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 N::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::ZIBinomFit) requires the data matrix `Y` (the same matrix passed to fit_zibinom_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    Nm = N === nothing ? fill(1, p, size(Y, 2)) : N
    size(Nm) == size(Y) || throw(DimensionMismatch("N must match size(Y) = $(size(Y))"))
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.π / (1 - fit.π)))
    link = fit.link
    nll = θ -> -zibinom_marginal_loglik_laplace(
        Y, Nm, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        _prob_from_logit(θ[p + rr + 1]); link = link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    push!(terms, "pi"); push!(kinds, :logit)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Generalized Poisson (β, Λ, dispersion α on the IDENTITY scale).
# ---------------------------------------------------------------------------

"""
    confint(fit::GenPoissonFit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald CIs (observed information) for a fitted Generalized Poisson (GP-1,
`Var = μ(1+αμ)²`) GLLVM. `Y` is the p×n count matrix. β and Λ are linear; the
dispersion `α` is estimated on an UNCONSTRAINED IDENTITY scale (it may be negative for
under-dispersion), so its term `"alpha"` is reported on the native (linear) scale via
`α̂ ± z·SE` — NOT exponentiated.
"""
function confint(fit::GenPoissonFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::GenPoissonFit) requires the data matrix `Y` (the same matrix passed to fit_genpoisson_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ), fit.α)
    link = fit.link
    nll = θ -> -genpoisson_marginal_loglik_laplace(
        Y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], θ[p + rr + 1]; link = link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    push!(terms, "alpha"); push!(kinds, :linear)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end
