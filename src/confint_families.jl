# Wald confidence intervals via the observed information matrix for the
# one-part non-Gaussian GLLVM fitters (Poisson, Binomial, Negative Binomial,
# Beta, Gamma, Ordinal).
#
# This file is *additive*: it does not touch the family fit drivers in
# src/families/*.jl. Each `confint(::<FitType>)` method below
#   1. reassembles the packed parameter vector θ̂ exactly as the fitter optimised
#      it (β, pack_lambda(Λ), and — where present — the log-dispersion / cutpoint
#      increments),
#   2. builds a PURE-VALUE NLL closure nll(θ) = -<family>_marginal_loglik_laplace(…)
#      reassembled from θ via the existing value functions (so ForwardDiff sees a
#      clean function), and
#   3. calls the shared `_nongaussian_wald_ci` routine — the non-Gaussian twin of
#      the core in src/confint.jl.
#
# Back-transform convention (matches src/confint.jl):
#   :linear  → estimate as-is, CI = θ̂ ± z·SE          (β, Λ entries, first ordinal
#              cutpoint ψ₁)
#   :log_sd  → estimate = exp(θ̂), CI = exp(θ̂ ± z·SE)  (log dispersion r / precision
#              φ / shape α / scale σ; ordinal cutpoint *increments* ψ_{c≥2} stored as logs)
#   :logit   → estimate = logistic(θ̂), CI = logistic(θ̂ ± z·SE)  (zero-inflation
#              probability π of ZIP / ZINB; monotone ⇒ bounds stay ordered in (0,1))
#
# Non-PD Hessian handling mirrors src/confint.jl: a failed Hessian or
# non-positive variance ⇒ NaN bounds with `pd_hessian = false`.

# Shared Wald-CI core for the one-part non-Gaussian fitters. `θ̂` is the packed
# MLE, `nll` the pure-value negative log-likelihood, `terms`/`kinds` the
# per-parameter names and back-transform tags (one of :linear, :log_sd, :logit). `parm`
# uses the same selector semantics as src/confint.jl via
# `_confint_select_indices`.
function _nongaussian_wald_ci(θ̂::AbstractVector, nll,
                              terms::Vector{String}, kinds::Vector{Symbol};
                              level::Real = 0.95,
                              parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    n_par = length(θ̂)
    length(terms) == n_par || error(
        "Internal: term-name vector length ($(length(terms))) does not match θ̂ length ($n_par). " *
        "This is a packing layout bug.")
    length(kinds) == n_par || error(
        "Internal: kinds vector length ($(length(kinds))) does not match θ̂ length ($n_par).")

    H = nothing
    pd = true
    try
        H = ForwardDiff.hessian(nll, θ̂)
    catch
        H = nothing
        pd = false
    end

    se_all = fill(NaN, n_par)
    if H !== nothing && all(isfinite, H)
        Σ = nothing
        try
            Hsym = (H .+ H') ./ 2
            Σ = inv(Hsym)
        catch
            Σ = nothing
            pd = false
        end

        if Σ !== nothing
            diagΣ = diag(Σ)
            for i in 1:n_par
                v = diagΣ[i]
                if isfinite(v) && v > 0
                    se_all[i] = sqrt(v)
                else
                    pd = false
                end
            end
        end
    else
        pd = false
    end

    sel = _confint_select_indices(parm, terms)
    isempty(sel) && throw(ArgumentError("parm selector matched no parameters"))

    z = quantile(Normal(), 0.5 + level / 2)

    term_out     = String[]
    estimate_out = Float64[]
    lower_out    = Float64[]
    upper_out    = Float64[]
    se_out       = Float64[]

    for i in sel
        push!(term_out, terms[i])
        push!(se_out, se_all[i])

        θi = θ̂[i]
        sei = se_all[i]
        kind = kinds[i]

        if kind === :log_sd
            push!(estimate_out, exp(θi))
            if isfinite(sei)
                push!(lower_out, exp(θi - z * sei))
                push!(upper_out, exp(θi + z * sei))
            else
                push!(lower_out, NaN)
                push!(upper_out, NaN)
            end
        elseif kind === :logit
            # probability on the logit scale: estimate = logistic(θ̂),
            # CI = logistic(θ̂ ± z·SE) (monotone ⇒ bounds stay ordered in (0,1)).
            push!(estimate_out, _prob_from_logit(θi))
            if isfinite(sei)
                push!(lower_out, _prob_from_logit(θi - z * sei))
                push!(upper_out, _prob_from_logit(θi + z * sei))
            else
                push!(lower_out, NaN)
                push!(upper_out, NaN)
            end
        else
            push!(estimate_out, θi)
            if isfinite(sei)
                push!(lower_out, θi - z * sei)
                push!(upper_out, θi + z * sei)
            else
                push!(lower_out, NaN)
                push!(upper_out, NaN)
            end
        end
    end

    return (term = term_out,
            estimate = estimate_out,
            lower = lower_out,
            upper = upper_out,
            se = se_out,
            pd_hessian = pd)
end

# β + Λ term names/kinds shared by the intercept-bearing families (everything
# except Ordinal). β[1..p] then the pack_lambda-ordered Λ entries, all :linear.
function _confint_beta_lambda_terms(p::Integer, K::Integer)
    terms = String[]
    kinds = Symbol[]
    for j in 1:p
        push!(terms, "beta[$j]")
        push!(kinds, :linear)
    end
    for nm in _confint_lambda_term_names("Lambda", p, K)
        push!(terms, nm)
        push!(kinds, :linear)
    end
    return terms, kinds
end

# ---------------------------------------------------------------------------
# Poisson (β, Λ only).
# ---------------------------------------------------------------------------

"""
    confint(fit::PoissonFit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald confidence intervals (observed-information / Hessian) for a fitted Poisson
GLLVM. Returns the same NamedTuple shape as `confint(::GllvmFit)`:
`(term, estimate, lower, upper, se, pd_hessian)`. `Y` is the p×n count matrix the
fit was computed on. β and Λ entries are reported on their native (linear) scale.
A non-positive-definite Hessian yields NaN bounds with `pd_hessian = false`.
"""
function confint(fit::PoissonFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::PoissonFit) requires the data matrix `Y` (the same matrix passed to fit_poisson_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ))
    link = fit.link
    nll = θ -> -poisson_marginal_loglik_laplace(
        Y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Binomial (β, Λ only; logit/probit/cloglog links).
# ---------------------------------------------------------------------------

"""
    confint(fit::BinomialFit; Y, N=nothing, level=0.95, parm=nothing) -> NamedTuple

Wald confidence intervals (observed-information / Hessian) for a fitted Binomial
GLLVM. `Y` is the p×n response matrix; `N` the matching trial counts (default
all-ones, i.e. Bernoulli) — pass the same `N` used in `fit_binomial_gllvm`.
Returns `(term, estimate, lower, upper, se, pd_hessian)`. β and Λ entries are on
the native (linear) scale.
"""
function confint(fit::BinomialFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 N::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::BinomialFit) requires the data matrix `Y` (the same matrix passed to fit_binomial_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    Nm = N === nothing ? fill(1, p, size(Y, 2)) : N
    size(Nm) == size(Y) || throw(DimensionMismatch("N must match size(Y) = $(size(Y))"))
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ))
    link = fit.link
    nll = θ -> -binomial_marginal_loglik_laplace(
        Y, Nm, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Negative Binomial (β, Λ, log dispersion r).
# ---------------------------------------------------------------------------

"""
    confint(fit::NBFit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald confidence intervals (observed-information / Hessian) for a fitted
negative-binomial (NB2) GLLVM. `Y` is the p×n count matrix. Returns
`(term, estimate, lower, upper, se, pd_hessian)`. β and Λ entries are linear; the
dispersion `r` is parameterised internally on the log scale, so its term `"r"` is
reported on the raw (positive) scale via `exp(log r ± z·SE_log)`.
"""
function confint(fit::NBFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::NBFit) requires the data matrix `Y` (the same matrix passed to fit_nb_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.r))
    link = fit.link
    nll = θ -> -nb_marginal_loglik_laplace(
        Y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        _positive_from_log(θ[p + rr + 1]); link = link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    push!(terms, "r")
    push!(kinds, :log_sd)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Beta (β, Λ, log precision φ).
# ---------------------------------------------------------------------------

"""
    confint(fit::BetaFit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald confidence intervals (observed-information / Hessian) for a fitted Beta
GLLVM. `Y` is the p×n matrix of proportions in (0,1). Returns
`(term, estimate, lower, upper, se, pd_hessian)`. β and Λ entries are linear; the
precision `φ` is parameterised internally on the log scale, so its term `"phi"`
is reported on the raw (positive) scale via `exp(log φ ± z·SE_log)`.
"""
function confint(fit::BetaFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::BetaFit) requires the data matrix `Y` (the same matrix passed to fit_beta_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.φ))
    link = fit.link
    nll = θ -> -beta_marginal_loglik_laplace(
        Y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        _positive_from_log(θ[p + rr + 1]); link = link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    push!(terms, "phi")
    push!(kinds, :log_sd)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Gamma (β, Λ, log shape α).  Inner-mode convergence is guarded (see below).
# ---------------------------------------------------------------------------

"""
    confint(fit::GammaFit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald confidence intervals (observed-information / Hessian) for a fitted Gamma
GLLVM. `Y` is the p×n matrix of positive reals. Returns
`(term, estimate, lower, upper, se, pd_hessian)`. β and Λ entries are linear; the
shape `α` is parameterised internally on the log scale, so its term `"alpha"` is
reported on the raw (positive) scale via `exp(log α ± z·SE_log)`.

!!! note
    The Gamma fitter's inner Laplace mode convergence is less robust than the
    other one-part families (it currently relies on direct ForwardDiff through
    the dense Laplace objective for some configurations). If the observed
    information matrix is not positive definite at the MLE — which can happen
    when the inner mode is fragile — this returns NaN bounds with
    `pd_hessian = false` rather than an unreliable interval.
"""
function confint(fit::GammaFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::GammaFit) requires the data matrix `Y` (the same matrix passed to fit_gamma_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.α))
    link = fit.link
    nll = θ -> -gamma_marginal_loglik_laplace(
        Y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        _positive_from_log(θ[p + rr + 1]); link = link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    push!(terms, "alpha")
    push!(kinds, :log_sd)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Ordinal (Λ, cutpoint increments ψ; NO species intercept).
# ---------------------------------------------------------------------------

"""
    confint(fit::OrdinalFit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald confidence intervals (observed-information / Hessian) for a fitted
proportional-odds cumulative-logit ordinal GLLVM. `Y` is the p×n matrix of
ordinal responses coded `1:C`. Returns `(term, estimate, lower, upper, se,
pd_hessian)`.

The packed parameters are `[vec(Λ); ψ]`, where the `C−1` ordered cutpoints are
the unconstrained increments `τ₁ = ψ₁, τ_c = τ_{c-1} + exp(ψ_c)`. Λ entries and
the first cutpoint `psi[1]` (= τ₁) are reported on the native (linear) scale; the
remaining increments `psi[c]` for `c ≥ 2` are parameterised on the log scale
(they equal `log(τ_c − τ_{c-1})`), so they are reported on the raw (positive)
increment scale via `exp(ψ_c ± z·SE_log)`.
"""
function confint(fit::OrdinalFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::OrdinalFit) requires the data matrix `Y` (the same matrix passed to fit_ordinal_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    C = fit.C
    # Recover the unconstrained increments ψ from the ordered cutpoints τ:
    #   ψ₁ = τ₁, ψ_c = log(τ_c − τ_{c-1})  for c ≥ 2.
    τ = fit.τ
    ψ = similar(τ)
    ψ[1] = τ[1]
    @inbounds for c in 2:length(τ)
        ψ[c] = log(τ[c] - τ[c - 1])
    end
    θ̂ = vcat(pack_lambda(fit.Λ), ψ)
    nll = θ -> -ordinal_marginal_loglik_laplace(
        Y, unpack_lambda(θ[1:rr], p, K), _unpack_cutpoints(θ[(rr + 1):(rr + C - 1)]),
        fit.link)

    terms = String[]
    kinds = Symbol[]
    for nm in _confint_lambda_term_names("Lambda", p, K)
        push!(terms, nm)
        push!(kinds, :linear)
    end
    for c in 1:(C - 1)
        push!(terms, "psi[$c]")
        # ψ₁ = τ₁ is unconstrained (linear); ψ_{c≥2} = log Δτ_c (positive ⇒ exp).
        push!(kinds, c == 1 ? :linear : :log_sd)
    end
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# NB1 (β, Λ, log dispersion φ; linear-variance NB).
# ---------------------------------------------------------------------------

"""
    confint(fit::NB1Fit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald CIs (observed information) for a fitted NB1 (linear-variance NB) GLLVM. `Y` is
the p×n count matrix. β and Λ are linear; the dispersion `φ` is parameterised
internally on the log scale, so `"phi"` is reported on the raw (positive) scale via
`exp(log φ ± z·SE)`.
"""
function confint(fit::NB1Fit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::NB1Fit) requires the data matrix `Y` (the same matrix passed to fit_nb1_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.φ))
    link = fit.link
    nll = θ -> -nb1_marginal_loglik_laplace(
        Y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        _positive_from_log(θ[p + rr + 1]); link = link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    push!(terms, "phi"); push!(kinds, :log_sd)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Beta-Binomial (β, Λ, log precision φ; needs trial counts N).
# ---------------------------------------------------------------------------

"""
    confint(fit::BetaBinomialFit; Y, N=nothing, level=0.95, parm=nothing) -> NamedTuple

Wald CIs (observed information) for a fitted Beta-Binomial GLLVM. `Y` is the p×n
success-count matrix; `N` the trial counts (default all-ones) — pass the same `N`
used in `fit_betabinomial_gllvm`. β and Λ are linear; the precision `φ` is
parameterised internally on the log scale, reported via `exp(log φ ± z·SE)`.
"""
function confint(fit::BetaBinomialFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 N::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::BetaBinomialFit) requires the data matrix `Y` (the same matrix passed to fit_betabinomial_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    Nm = N === nothing ? fill(1, p, size(Y, 2)) : N
    size(Nm) == size(Y) || throw(DimensionMismatch("N must match size(Y) = $(size(Y))"))
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.φ))
    link = fit.link
    nll = θ -> -betabinomial_marginal_loglik_laplace(
        Y, Nm, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        _positive_from_log(θ[p + rr + 1]); link = link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    push!(terms, "phi"); push!(kinds, :log_sd)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Student-t (β, Λ, log scale σ; ν held fixed at the fitted value).
# ---------------------------------------------------------------------------

"""
    confint(fit::StudentTFit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald CIs (observed information) for a fitted Student-t GLLVM. `Y` is the p×n response
matrix. β and Λ are linear; the scale `σ` is parameterised internally on the log
scale, reported via `exp(log σ ± z·SE)`. The degrees of freedom `ν` are held fixed at
the fitted value (the fitter does not estimate ν), so the interval conditions on `ν`.
"""
function confint(fit::StudentTFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::StudentTFit) requires the data matrix `Y` (the same matrix passed to fit_studentt_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.σ))
    link = fit.link
    ν = fit.ν
    nll = θ -> -studentt_marginal_loglik_laplace(
        Y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        _positive_from_log(θ[p + rr + 1]); ν = ν, link = link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    push!(terms, "sigma"); push!(kinds, :log_sd)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Zero-truncated Poisson (β, Λ only).
# ---------------------------------------------------------------------------

"""
    confint(fit::TruncPoissonFit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald CIs (observed information) for a fitted zero-truncated Poisson GLLVM. `Y` is the
p×n matrix of positive counts. β and Λ are reported on the native (linear) scale.
"""
function confint(fit::TruncPoissonFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::TruncPoissonFit) requires the data matrix `Y` (the same matrix passed to fit_truncpoisson_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ))
    link = fit.link
    nll = θ -> -truncpoisson_marginal_loglik_laplace(
        Y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Zero-truncated NB2 (β, Λ, log dispersion r).
# ---------------------------------------------------------------------------

"""
    confint(fit::TruncNBFit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald CIs (observed information) for a fitted zero-truncated NB2 GLLVM. `Y` is the p×n
matrix of positive counts. β and Λ are linear; the dispersion `r` is parameterised
internally on the log scale, reported via `exp(log r ± z·SE)`.
"""
function confint(fit::TruncNBFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::TruncNBFit) requires the data matrix `Y` (the same matrix passed to fit_truncnb_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.r))
    link = fit.link
    nll = θ -> -truncnb_marginal_loglik_laplace(
        Y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        _positive_from_log(θ[p + rr + 1]); link = link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    push!(terms, "r"); push!(kinds, :log_sd)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Zero-inflated Poisson (β, Λ, logit π).
# ---------------------------------------------------------------------------

"""
    confint(fit::ZIPFit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald CIs (observed information) for a fitted zero-inflated Poisson GLLVM. `Y` is the
p×n count matrix. β and Λ are linear; the zero-inflation probability `π` is
parameterised internally on the logit scale, so `"pi"` is reported on the (0,1) scale
via `logistic(logit π ± z·SE)`.
"""
function confint(fit::ZIPFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::ZIPFit) requires the data matrix `Y` (the same matrix passed to fit_zip_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.π / (1 - fit.π)))
    link = fit.link
    nll = θ -> -zip_marginal_loglik_laplace(
        Y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        _prob_from_logit(θ[p + rr + 1]); link = link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    push!(terms, "pi"); push!(kinds, :logit)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end

# ---------------------------------------------------------------------------
# Zero-inflated NB2 (β, Λ, log dispersion r, logit π).
# ---------------------------------------------------------------------------

"""
    confint(fit::ZINBFit; Y, level=0.95, parm=nothing) -> NamedTuple

Wald CIs (observed information) for a fitted zero-inflated NB2 GLLVM. `Y` is the p×n
count matrix. β and Λ are linear; the dispersion `r` is parameterised internally on
the log scale (reported via `exp`), and the zero-inflation probability `π` on the
logit scale (reported on (0,1) via `logistic`).
"""
function confint(fit::ZINBFit;
                 Y::Union{Nothing, AbstractMatrix} = nothing,
                 level::Real = 0.95,
                 parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing)
    Y === nothing && throw(ArgumentError(
        "confint(::ZINBFit) requires the data matrix `Y` (the same matrix passed to fit_zinb_gllvm)"))
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.r), log(fit.π / (1 - fit.π)))
    link = fit.link
    nll = θ -> -zinb_marginal_loglik_laplace(
        Y, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        _positive_from_log(θ[p + rr + 1]), _prob_from_logit(θ[p + rr + 2]); link = link)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    push!(terms, "r"); push!(kinds, :log_sd)
    push!(terms, "pi"); push!(kinds, :logit)
    return _nongaussian_wald_ci(θ̂, nll, terms, kinds; level = level, parm = parm)
end
