# Parametric bootstrap confidence intervals for the *fitted parameters* of the
# NON-GAUSSIAN one-part fits (PoissonFit, NBFit, BinomialFit, BetaFit, NB1Fit,
# BetaBinomialFit, TruncPoissonFit, TruncNBFit, ZIPFit, ZINBFit).
#
# This is the parameter-level twin of two siblings:
#   * src/confint_bootstrap.jl              — the Gaussian parametric bootstrap
#     (simulate from the fit, refit, percentile CIs; the resampling loop and the
#     "guard non-converged refits" safeguard are copied in spirit here).
#   * src/confint_derived_bootstrap_families.jl — the SAME simulate→refit→percentile
#     bootstrap for non-Gaussian *derived* scalars (correlation/communality).
#
# Where the derived-bootstrap sibling collects one scalar `derived_fn(fit_b)` per
# replicate, here we collect the WHOLE packed parameter vector and form a
# per-parameter percentile CI, returning the same `(term, estimate, lower, upper,
# se, …)` shape as the Wald `confint(::<FitType>)` (src/confint_families.jl) so the
# two CI methods are drop-in comparable.
#
#     for b = 1..nboot:
#         Y_b   = simulate(fit, n; seed = seed + b)      # family-dispatched DGP
#         fit_b = <refit Y_b with the same fitter/spec>  # fit_poisson_gllvm / …
#         θ_b   = <native-scale parameter vector of fit_b>
#     CI[j] = percentile(θ_b[:, j], [α, 1-α])            # per parameter j
#
# Scale convention (matches src/confint_families.jl `kinds`):
#   :linear → reported as-is                         (β, Λ entries)
#   :log_sd → positive parameter (r / φ / α)         (percentile on the raw scale)
#   :logit  → probability π ∈ (0,1)                  (percentile on the raw scale)
# Because the percentile is monotone, taking it on the raw scale is identical to
# taking it on the working (log / logit) scale and back-transforming, so we keep
# every replicate, estimate, and bound on ONE native scale (the same scale
# `confint(::<FitType>)` reports) and read percentiles there directly.
#
# This file is ADDITIVE. It does NOT touch confint_bootstrap.jl,
# confint_derived_bootstrap_families.jl, confint_families.jl, simulate.jl, or any
# src/families/*.jl fitter. It REUSES `simulate(fit, n)` (simulate.jl), the term-name
# / selector helpers `_confint_beta_lambda_terms` / `_confint_lambda_term_names`
# (confint_families.jl, confint.jl), `_confint_select_indices` (confint.jl), and
# `_derived_percentile` (confint_derived.jl). All internal helpers are prefixed
# `_bootci_` so they do not collide with the derived-bootstrap sibling's `_boot_*`.

# ---------------------------------------------------------------------------
# Union of the one-part non-Gaussian fit types that share the simulate→refit→
# percentile parameter bootstrap (everything with a family-dispatched
# `simulate(fit, n)` overload AND a packed `confint(::<FitType>)` layout).
# ---------------------------------------------------------------------------
const _BootCIFamilyFit = Union{PoissonFit, NBFit, BinomialFit, BetaFit, NB1Fit,
                               BetaBinomialFit, TruncPoissonFit, TruncNBFit,
                               ZIPFit, ZINBFit}

# ---------------------------------------------------------------------------
# Native-scale packed parameter vector + matching term names / kinds, for the
# point estimate AND for each refit. The (terms, kinds, θ) triple is laid out
# EXACTLY as src/confint_families.jl packs θ̂ for each family — except the
# dispersion/zero-inflation entries are stored on their NATIVE scale (r, φ, π),
# not log/logit, because the bootstrap reads percentiles directly on that scale.
#
#   β[1..p]                         (:linear)
#   pack_lambda(Λ)  in pack order   (:linear)
#   <family extras, native scale>   (:log_sd for r/φ/α, :logit for π)
#
# Returns (terms::Vector{String}, kinds::Vector{Symbol}, θ::Vector{Float64}).
# ---------------------------------------------------------------------------
function _bootci_terms_kinds_theta(fit::_BootCIFamilyFit)
    p, K = size(fit.Λ)
    terms, kinds = _confint_beta_lambda_terms(p, K)
    θ = vcat(Float64.(fit.β), Float64.(pack_lambda(fit.Λ)))
    _bootci_append_extras!(terms, kinds, θ, fit)
    return terms, kinds, θ
end

# Per-family dispersion / zero-inflation extras appended after the β/Λ block.
# Mirrors the `push!(terms, …)` tail of each `confint(::<FitType>)` method, with
# the NATIVE-scale value pushed onto θ (Wald stores log/logit; we store r/φ/π).
_bootci_append_extras!(::Vector{String}, ::Vector{Symbol}, ::Vector{Float64},
                       ::Union{PoissonFit, BinomialFit, TruncPoissonFit}) = nothing

function _bootci_append_extras!(terms, kinds, θ, fit::Union{NBFit, TruncNBFit})
    push!(terms, "r"); push!(kinds, :log_sd); push!(θ, Float64(fit.r))
    return nothing
end
function _bootci_append_extras!(terms, kinds, θ, fit::Union{BetaFit, NB1Fit, BetaBinomialFit})
    push!(terms, "phi"); push!(kinds, :log_sd); push!(θ, Float64(fit.φ))
    return nothing
end
function _bootci_append_extras!(terms, kinds, θ, fit::ZIPFit)
    push!(terms, "pi"); push!(kinds, :logit); push!(θ, Float64(fit.π))
    return nothing
end
function _bootci_append_extras!(terms, kinds, θ, fit::ZINBFit)
    push!(terms, "r");  push!(kinds, :log_sd); push!(θ, Float64(fit.r))
    push!(terms, "pi"); push!(kinds, :logit);  push!(θ, Float64(fit.π))
    return nothing
end

# ---------------------------------------------------------------------------
# Coerce a freshly simulated (always-Float64) replicate to the response type the
# refit expects: the count / Bernoulli-trial families need an Int matrix; Beta a
# Float64 matrix. Mirrors `_boot_coerce_response` in the derived-bootstrap sibling,
# extended to every one-part family handled here.
# ---------------------------------------------------------------------------
_bootci_coerce_response(::Union{PoissonFit, NBFit, BinomialFit, NB1Fit,
                                BetaBinomialFit, TruncPoissonFit, TruncNBFit,
                                ZIPFit, ZINBFit},
                        Y_b::AbstractMatrix) = round.(Int, Y_b)
_bootci_coerce_response(::BetaFit, Y_b::AbstractMatrix) = Y_b

# ---------------------------------------------------------------------------
# Per-fit refit: re-fit an (already coerced) replicate Y_b with the SAME fitter
# and spec (link, dispersion family, K) as the original fit. Extends the
# derived-bootstrap sibling's `_boot_refit` set to NB1 / Beta-Binomial / the
# truncated & zero-inflated families. Binomial / Beta-Binomial thread N.
# ---------------------------------------------------------------------------
_bootci_refit(fit::PoissonFit, Y_b, ::Any) =
    fit_poisson_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
_bootci_refit(fit::NBFit, Y_b, ::Any) =
    fit_nb_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
_bootci_refit(fit::BetaFit, Y_b, ::Any) =
    fit_beta_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
_bootci_refit(fit::NB1Fit, Y_b, ::Any) =
    fit_nb1_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
_bootci_refit(fit::TruncPoissonFit, Y_b, ::Any) =
    fit_truncpoisson_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
_bootci_refit(fit::TruncNBFit, Y_b, ::Any) =
    fit_truncnb_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
_bootci_refit(fit::ZIPFit, Y_b, ::Any) =
    fit_zip_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
_bootci_refit(fit::ZINBFit, Y_b, ::Any) =
    fit_zinb_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
_bootci_refit(fit::BinomialFit, Y_b, N) =
    fit_binomial_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link, N = N)
_bootci_refit(fit::BetaBinomialFit, Y_b, N) =
    fit_betabinomial_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link, N = N)

# Native-scale packed parameter vector of a refit (must match the ORIGINAL fit's
# (terms, kinds) layout 1:1 — same family type ⇒ same length by construction).
_bootci_refit_theta(fit_b::_BootCIFamilyFit) = _bootci_terms_kinds_theta(fit_b)[3]

# Binomial / Beta-Binomial thread the trial counts N through both simulate and
# refit; every other one-part family ignores N.
_bootci_needs_N(::Union{BinomialFit, BetaBinomialFit}) = true
_bootci_needs_N(::Any) = false

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

"""
    bootstrap_ci_families(fit, Y; nboot=200, level=0.95, seed=0, N=nothing,
                          parm=nothing, verbose=false) -> NamedTuple

Parametric bootstrap percentile confidence intervals for the fitted parameters of
a NON-GAUSSIAN one-part GLLVM (`PoissonFit`, `NBFit`, `BinomialFit`, `BetaFit`,
`NB1Fit`, `BetaBinomialFit`, `TruncPoissonFit`, `TruncNBFit`, `ZIPFit`, `ZINBFit`).

This is the bootstrap counterpart of the Wald `confint(::<FitType>)` in
`src/confint_families.jl`, and the parameter-level twin of
[`bootstrap_ci_derived`](@ref) (which bootstraps *derived* scalars). For
`b = 1..nboot` a fresh `p × n` data matrix is drawn with the family-dispatched
`simulate(fit, n; seed = seed + b)` (`n = size(Y, 2)`), refit with the matching
fitter (same `K` / `link` / dispersion family), and the refit's packed parameter
vector is recorded; a per-parameter percentile CI is taken over the converged
replicates.

`Y` is the response matrix the fit was computed on — required, because the fit
does not record `n = size(Y, 2)` (the replicate size). `N` (Binomial /
Beta-Binomial only) gives the trial counts reused for both simulation and refit.

Returns a NamedTuple with fields (the Wald five, plus bootstrap diagnostics):

  - `term::Vector{String}`         — parameter names (β, Λ in `pack_lambda` order,
                                     then the family extras `r` / `phi` / `pi`)
  - `estimate::Vector{Float64}`    — the original MLE on each parameter's NATIVE
                                     scale (`fit.β`, `vec(fit.Λ)`, `fit.r`, …)
  - `lower::Vector{Float64}`       — percentile `100·(1-level)/2`
  - `upper::Vector{Float64}`       — percentile `100·(1+level)/2`
  - `se::Vector{Float64}`          — bootstrap SE (std-dev of the replicates)
  - `n_converged::Int`             — bootstrap fits that converged
  - `n_valid::Int`                 — replicates with a finite parameter vector
  - `replicates::Matrix{Float64}`  — `nboot × n_par` matrix of bootstrap θ̂_b
                                     (`NaN` rows only for refits that errored or
                                     returned a non-finite / wrong-length vector)

Scale convention (matches `confint(::<FitType>)`): β and Λ entries are `:linear`;
the dispersion `r` (NB2 / trunc-NB / ZINB), the precision `phi` (Beta / NB1 /
Beta-Binomial), and the shape are positive `:log_sd` quantities; the
zero-inflation probability `pi` (ZIP / ZINB) is a `:logit` quantity in `(0,1)`.
Because the percentile is monotone, it is taken directly on each parameter's
native scale, so every returned bound is on the same scale as `estimate` and
positive / `(0,1)`-bounded parameters keep their domain.

`parm` selects a subset of returned terms (default `nothing` = all), using the
same selector semantics as `confint` (a `String`, `Symbol`, or `Vector{String}`;
see [`confint`](@ref)).

`nboot` defaults to 200 (modest); publication-grade is 500–2000. Cost is
`nboot ×` per-fit time. A refit that errors out or yields a non-finite /
wrong-length parameter vector is recorded as a `NaN` row and excluded from the
percentile; a non-converged-but-finite refit IS included (convergence is recorded
only as the `n_converged` diagnostic, not used to filter — matching the sibling
bootstrap files). A parameter with fewer than 10 valid replicates returns `NaN`
bounds (mirroring `bootstrap_ci(::GllvmFit)` and `bootstrap_ci_derived`).

# Example

```julia
Y   = round.(Int, simulate(Poisson(), log.([4.0, 6.0, 3.0]), 0.5 .* randn(3, 1), 200; seed = 1))
fit = fit_poisson_gllvm(Y; K = 1)
ci  = bootstrap_ci_families(fit, Y; nboot = 200, seed = 42)
ci.term      # parameter names
ci.lower     # 2.5% percentile bounds
ci.upper     # 97.5% percentile bounds
```
"""
function bootstrap_ci_families(fit::_BootCIFamilyFit,
                               Y::AbstractMatrix;
                               nboot::Integer = 200,
                               level::Real = 0.95,
                               seed::Integer = 0,
                               N::Union{Nothing, AbstractMatrix} = nothing,
                               parm::Union{Nothing, AbstractString, Symbol, AbstractVector} = nothing,
                               verbose::Bool = false)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    nboot ≥ 1 || throw(ArgumentError("nboot must be ≥ 1; got $nboot"))
    n = size(Y, 2)

    # NA-aware bootstrap (issue #27): if the data carry missing cells, re-impose the
    # SAME missingness pattern on every parametric replicate so each refit reflects the
    # same information loss (FIML parametric bootstrap). On a dense Y `miss` is all-false
    # ⇒ this is byte-identical to the complete-data bootstrap.
    miss = ismissing.(Y)
    any_miss = any(miss)

    terms, kinds, θ̂ = _bootci_terms_kinds_theta(fit)
    n_par = length(θ̂)

    # Binomial / Beta-Binomial thread N through simulate; the others take no N.
    needs_N = _bootci_needs_N(fit)
    simulate_b = needs_N ? (b -> simulate(fit, n; N = N, seed = seed + b)) :
                           (b -> simulate(fit, n; seed = seed + b))

    replicates = fill(NaN, nboot, n_par)
    converged = falses(nboot)

    for b in 1:nboot
        try
            Y_b = _bootci_coerce_response(fit, simulate_b(b))
            any_miss && (Y_b = ifelse.(miss, missing, Y_b))
            fit_b = _bootci_refit(fit, Y_b, N)
            θ_b = _bootci_refit_theta(fit_b)
            if length(θ_b) == n_par && all(isfinite, θ_b)
                replicates[b, :] = θ_b
                converged[b] = fit_b.converged
            else
                verbose && @info "bootstrap_ci_families rep $b: bad θ_b (length $(length(θ_b)) vs $n_par, finite $(all(isfinite, θ_b)))"
            end
        catch e
            verbose && @info "bootstrap_ci_families rep $b failed: $e"
            # replicates[b, :] stays NaN
        end
    end

    n_converged = count(converged)

    # ----- Per-parameter percentile CIs + bootstrap SE over the finite replicates.
    α = (1 - level) / 2
    lower = fill(NaN, n_par)
    upper = fill(NaN, n_par)
    se    = fill(NaN, n_par)
    n_valid = nboot
    for j in 1:n_par
        col = filter(isfinite, view(replicates, :, j))
        n_valid = min(n_valid, length(col))
        if length(col) ≥ 10
            lower[j] = _derived_percentile(col, α)
            upper[j] = _derived_percentile(col, 1 - α)
        end
        if length(col) ≥ 2
            se[j] = std(col)
        end
    end

    # ----- Optionally subset by `parm` (same selector semantics as confint).
    sel = _confint_select_indices(parm, terms)
    isempty(sel) && throw(ArgumentError("parm selector matched no parameters"))

    return (term        = terms[sel],
            estimate    = θ̂[sel],
            lower       = lower[sel],
            upper       = upper[sel],
            se          = se[sel],
            n_converged = n_converged,
            n_valid     = n_valid,
            replicates  = replicates[:, sel])
end
