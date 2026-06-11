# Parametric-bootstrap confidence intervals for *derived quantities* of the
# NON-GAUSSIAN one-part fits (PoissonFit, NBFit, BetaFit, GammaFit, BinomialFit,
# OrdinalFit) and the cross-family MixedFamilyFit.
#
# The Gaussian path (bootstrap_ci_derived(::GllvmFit, …) in confint_derived.jl)
# replays the Gaussian-only `_derived_simulate!`. Here we do the SAME percentile
# bootstrap but swap that simulator for the family-dispatched `simulate(fit, n)`
# (src/simulate.jl) and refit with the matching fitter:
#
#     for b = 1..n_boot:
#         Y_b   = simulate(fit, n; seed = seed + b)      # family-dispatched DGP
#         fit_b = <refit Y_b with the same fitter/spec>  # fit_poisson_gllvm / …
#         v_b   = derived_fn(fit_b)                       # scalar derived quantity
#     CI = percentile(v_b, [α, 1-α])
#
# The non-Gaussian latent-scale derived quantities (correlation / communality;
# confint_derived.jl, families/mixed.jl) need the data matrix `Y` (the fits do
# not store it), so each replicate evaluates `derived_fn(fit_b, Y_b)` — the
# bootstrap data matrix that produced `fit_b`. Convenience wrappers
# (`correlation_boot_ci`, `communality_boot_ci`) build the right `derived_fn`.
#
# This file is ADDITIVE: it does NOT touch confint_bootstrap.jl, confint_derived.jl,
# simulate.jl, or any src/families/*.jl fitter. The ::GllvmFit methods are
# unchanged. It REUSES `simulate(fit, n)` (simulate.jl), the latent-scale
# extractors `correlation`/`communality` (confint_derived.jl, families/mixed.jl),
# and `_derived_percentile` (confint_derived.jl).

# ---------------------------------------------------------------------------
# Union of the family fit types that share the simulate→refit→derived bootstrap
# (everything with a family-dispatched `simulate(fit, n)` overload). MixedFamilyFit
# is handled by its own method because its refit needs the per-trait families.
# ---------------------------------------------------------------------------
const _BootstrapFamilyFit =
    Union{PoissonFit, NBFit, BetaFit, GammaFit, BinomialFit, OrdinalFit}

# ---------------------------------------------------------------------------
# Coerce a freshly simulated (always-Float64) replicate matrix to the response
# type the fit's fitter AND latent-scale extractor expect. The integer-response
# families (Poisson, NB, Binomial, Ordinal) need an `Int` matrix — both their
# fitter (`AbstractMatrix{<:Integer}`) and their `predict`/`correlation` (which
# also dispatch on `<:Integer`) require it. Beta/Gamma and the mixed fit take
# Float64. Applied ONCE in the core loop so refit and derived use one matrix.
_boot_coerce_response(::Union{PoissonFit, NBFit, BinomialFit, OrdinalFit},
                      Y_b::AbstractMatrix) = round.(Int, Y_b)
_boot_coerce_response(::Union{BetaFit, GammaFit, MixedFamilyFit},
                      Y_b::AbstractMatrix) = Y_b

# Per-fit refit: re-fit an (already coerced) replicate Y_b with the SAME fitter
# and spec (link, dispersion family, K) as the original fit. Each returns a fit
# of the same concrete type. Binomial threads through the trial counts N.
# ---------------------------------------------------------------------------
function _boot_refit(fit::PoissonFit, Y_b::AbstractMatrix)
    return fit_poisson_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
end
function _boot_refit(fit::NBFit, Y_b::AbstractMatrix)
    return fit_nb_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
end
function _boot_refit(fit::BetaFit, Y_b::AbstractMatrix)
    return fit_beta_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
end
function _boot_refit(fit::GammaFit, Y_b::AbstractMatrix)
    return fit_gamma_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
end
function _boot_refit(fit::BinomialFit, Y_b::AbstractMatrix,
                     N::Union{Nothing, AbstractMatrix})
    return fit_binomial_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link, N = N)
end
function _boot_refit(fit::OrdinalFit, Y_b::AbstractMatrix)
    return fit_ordinal_gllvm(Y_b; K = size(fit.Λ, 2), link = fit.link)
end

# ---------------------------------------------------------------------------
# Generic bootstrap-percentile core. `simulate_b(b)` draws the b-th replicate
# (always-Float64, seeded deterministically); `coerce_b(Y)` casts it to the fit's
# response type (so refit AND derived use ONE matrix); `refit_b(Y_b)` refits;
# `derived_b(fit_b, Y_b)` evaluates the scalar derived quantity on the replicate.
# Returns the same NamedTuple shape as bootstrap_ci_derived(::GllvmFit).
# ---------------------------------------------------------------------------
function _bootstrap_ci_derived_core(est::Real, n_boot::Integer, level::Real,
                                    simulate_b, coerce_b, refit_b, derived_b;
                                    verbose::Bool = false)
    replicates = fill(NaN, n_boot)
    converged = falses(n_boot)
    for b in 1:n_boot
        try
            Y_b = coerce_b(simulate_b(b))
            fit_b = refit_b(Y_b)
            converged[b] = _boot_converged(fit_b)
            v = Float64(derived_b(fit_b, Y_b))
            if isfinite(v)
                replicates[b] = v
            end
        catch e
            verbose && @info "bootstrap_ci_derived rep $b failed: $e"
        end
    end

    α = (1 - level) / 2
    valid = filter(isfinite, replicates)
    n_valid = length(valid)
    lower, upper = if n_valid ≥ 10
        (_derived_percentile(valid, α), _derived_percentile(valid, 1 - α))
    else
        (NaN, NaN)
    end
    return (estimate    = Float64(est),
            lower       = lower,
            upper       = upper,
            n_converged = count(converged),
            n_valid     = n_valid,
            replicates  = replicates)
end

# Convergence flag accessor (the family fits expose `.converged`).
_boot_converged(fit) = fit.converged

# ---------------------------------------------------------------------------
# Public API: parametric bootstrap CI for a derived quantity of a NON-GAUSSIAN
# one-part fit.
# ---------------------------------------------------------------------------

"""
    bootstrap_ci_derived(fit, derived_fn; Y, n_boot=500, level=0.95, seed=0,
                         N=nothing, verbose=false) -> NamedTuple

Parametric bootstrap percentile CI for a scalar *derived quantity* of a fitted
non-Gaussian one-part GLLVM (`PoissonFit`, `NBFit`, `BetaFit`, `GammaFit`,
`BinomialFit`, `OrdinalFit`). For `b = 1..n_boot` a fresh data matrix is drawn
with the family-dispatched `simulate(fit, n; seed = seed + b)`, refit with the
matching fitter (same `K`/`link`/dispersion family), and `derived_fn` is
evaluated on the replicate; the percentile CI is taken over the converged
replicates.

`derived_fn` is called as `derived_fn(fit_b, Y_b)` — the second argument is the
bootstrap data matrix, which the latent-scale extractors
([`correlation`](@ref), [`communality`](@ref)) need (the fits do not store the
data). For a single scalar, e.g. `ρ[1,2]`, write
`(f, Y) -> correlation(f, Y)[1, 2]`. The convenience wrappers
[`correlation_boot_ci`](@ref) and [`communality_boot_ci`](@ref) build this for
you.

`Y` is the response matrix the fit was computed on — required, because the fit
does not record the number of sites `n = size(Y, 2)` (the replicate size) and
the point estimate is computed from it. `N` (Binomial only) gives the trial
counts to reuse for both simulation and refit.

Returns a NamedTuple with fields:
  - `estimate::Float64`           — derived quantity at the original MLE
  - `lower::Float64`              — percentile `100·(1-level)/2`
  - `upper::Float64`              — percentile `100·(1+level)/2`
  - `n_converged::Int`            — bootstrap fits that converged
  - `n_valid::Int`                — replicates with a finite derived value
  - `replicates::Vector{Float64}` — the `n_boot` samples (`NaN` for failures)

`n_boot` defaults to 500 (publication-grade); lower (e.g. 100) for quick checks.
Cost is `n_boot ×` per-fit time.
"""
function bootstrap_ci_derived(fit::_BootstrapFamilyFit, derived_fn::Function;
                              Y::Union{Nothing, AbstractMatrix} = nothing,
                              n_boot::Integer = 500,
                              level::Real = 0.95,
                              seed::Integer = 0,
                              N::Union{Nothing, AbstractMatrix} = nothing,
                              verbose::Bool = false)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    n_boot ≥ 1 || throw(ArgumentError("n_boot must be ≥ 1; got $n_boot"))
    Y === nothing && throw(ArgumentError(
        "bootstrap_ci_derived requires the data matrix `Y` (the same matrix " *
        "passed to the fitter); it sets the replicate size n = size(Y, 2)."))
    n = size(Y, 2)

    est = Float64(derived_fn(fit, Y))

    # NA-aware derived bootstrap (#93): re-impose the original missingness pattern on
    # every replicate so each refit reflects the same information loss (FIML parametric
    # bootstrap). Dense Y ⇒ any_miss false ⇒ identical to the complete-data bootstrap.
    miss = ismissing.(Y); any_miss = any(miss)
    # Binomial's simulate/refit thread the trial counts N; the others take no N.
    simulate_b = fit isa BinomialFit ? (b -> simulate(fit, n; N = N, seed = seed + b)) :
                                       (b -> simulate(fit, n; seed = seed + b))
    refit_b = fit isa BinomialFit ? (Y_b -> _boot_refit(fit, Y_b, N)) :
                                    (Y_b -> _boot_refit(fit, Y_b))
    coerce_b = Y_b -> (Yc = _boot_coerce_response(fit, Y_b);
                       any_miss ? ifelse.(miss, missing, Yc) : Yc)

    return _bootstrap_ci_derived_core(est, n_boot, level,
                                      simulate_b, coerce_b, refit_b, derived_fn;
                                      verbose = verbose)
end

"""
    bootstrap_ci_derived(fit::MixedFamilyFit, derived_fn; Y, n_boot=500,
                         level=0.95, seed=0, N=nothing, verbose=false)
        -> NamedTuple

Parametric bootstrap percentile CI for a scalar *derived quantity* (typically a
cross-family correlation) of a fitted mixed-family GLLVM. Replicates are drawn
with `simulate(fit, n; seed = seed + b)` (the per-trait families/links/dispersions
and shared `Λ`) and refit with `fit_mixed_gllvm` at the same `families`/`links`/`K`.
`derived_fn(fit_b, Y_b)` is evaluated per replicate. See the one-part method for
the field documentation; `N` supplies Binomial trial counts where the mix
includes a Binomial trait.
"""
function bootstrap_ci_derived(fit::MixedFamilyFit, derived_fn::Function;
                              Y::Union{Nothing, AbstractMatrix} = nothing,
                              n_boot::Integer = 500,
                              level::Real = 0.95,
                              seed::Integer = 0,
                              N::Union{Nothing, AbstractMatrix} = nothing,
                              verbose::Bool = false)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    n_boot ≥ 1 || throw(ArgumentError("n_boot must be ≥ 1; got $n_boot"))
    Y === nothing && throw(ArgumentError(
        "bootstrap_ci_derived requires the data matrix `Y` (the same matrix " *
        "passed to fit_mixed_gllvm); it sets the replicate size n = size(Y, 2)."))
    n = size(Y, 2)
    K = size(fit.Λ, 2)

    est = Float64(derived_fn(fit, Y))

    # NA-aware derived bootstrap (#93): re-impose the original missingness pattern on
    # every replicate (FIML parametric bootstrap). Dense Y ⇒ no-op.
    miss = ismissing.(Y); any_miss = any(miss)
    simulate_b = b -> simulate(fit, n; N = N, seed = seed + b)
    coerce_b = Y_b -> (Yc = _boot_coerce_response(fit, Y_b);
                       any_miss ? ifelse.(miss, missing, Yc) : Yc)
    refit_b = Y_b -> fit_mixed_gllvm(Y_b; families = fit.families,
                                     links = fit.links, K = K, N = N)

    return _bootstrap_ci_derived_core(est, n_boot, level,
                                      simulate_b, coerce_b, refit_b, derived_fn;
                                      verbose = verbose)
end

# ---------------------------------------------------------------------------
# Convenience wrappers for the two headline derived quantities. They build the
# `(fit_b, Y_b) -> scalar` closure that threads the bootstrap data matrix into
# the latent-scale extractor, including the Binomial `N` keyword.
# ---------------------------------------------------------------------------

# Internal: a derived closure (fit, Y) -> correlation(fit, Y)[i, j] that forwards
# the Binomial trial counts when the fit is Binomial or mixed-with-N.
function _boot_correlation_fn(::Any, i::Integer, j::Integer,
                              N::Union{Nothing, AbstractMatrix})
    return (f, Y) -> correlation(f, Y)[i, j]
end
function _boot_correlation_fn(::BinomialFit, i::Integer, j::Integer,
                              N::Union{Nothing, AbstractMatrix})
    return (f, Y) -> correlation(f, Y; N = N)[i, j]
end
function _boot_correlation_fn(::MixedFamilyFit, i::Integer, j::Integer,
                              N::Union{Nothing, AbstractMatrix})
    return (f, Y) -> correlation(f, Y; N = N)[i, j]
end

function _boot_communality_fn(::Any, t::Integer,
                              N::Union{Nothing, AbstractMatrix})
    return (f, Y) -> communality(f, Y)[t]
end
function _boot_communality_fn(::BinomialFit, t::Integer,
                              N::Union{Nothing, AbstractMatrix})
    return (f, Y) -> communality(f, Y; N = N)[t]
end
function _boot_communality_fn(::MixedFamilyFit, t::Integer,
                              N::Union{Nothing, AbstractMatrix})
    return (f, Y) -> communality(f, Y; N = N)[t]
end

"""
    correlation_boot_ci(fit, i, j; Y, n_boot=500, level=0.95, seed=0,
                        N=nothing, verbose=false) -> NamedTuple

Parametric bootstrap percentile CI for the latent-scale cross-trait correlation
`ρ[i, j]` of a fitted non-Gaussian one-part or mixed GLLVM. Thin wrapper over
[`bootstrap_ci_derived`](@ref) with `derived_fn = (f, Y) -> correlation(f, Y)[i, j]`
(forwarding the Binomial `N`). See that method for the returned fields.
"""
function correlation_boot_ci(fit::Union{_BootstrapFamilyFit, MixedFamilyFit},
                             i::Integer, j::Integer;
                             Y::Union{Nothing, AbstractMatrix} = nothing,
                             n_boot::Integer = 500, level::Real = 0.95,
                             seed::Integer = 0,
                             N::Union{Nothing, AbstractMatrix} = nothing,
                             verbose::Bool = false)
    f = _boot_correlation_fn(fit, i, j, N)
    return bootstrap_ci_derived(fit, f; Y = Y, n_boot = n_boot, level = level,
                                seed = seed, N = N, verbose = verbose)
end

"""
    communality_boot_ci(fit, t; Y, n_boot=500, level=0.95, seed=0,
                        N=nothing, verbose=false) -> NamedTuple

Parametric bootstrap percentile CI for the latent-scale per-trait communality
`c²[t]` of a fitted non-Gaussian one-part or mixed GLLVM. Thin wrapper over
[`bootstrap_ci_derived`](@ref) with `derived_fn = (f, Y) -> communality(f, Y)[t]`
(forwarding the Binomial `N`). See that method for the returned fields.
"""
function communality_boot_ci(fit::Union{_BootstrapFamilyFit, MixedFamilyFit},
                             t::Integer;
                             Y::Union{Nothing, AbstractMatrix} = nothing,
                             n_boot::Integer = 500, level::Real = 0.95,
                             seed::Integer = 0,
                             N::Union{Nothing, AbstractMatrix} = nothing,
                             verbose::Bool = false)
    f = _boot_communality_fn(fit, t, N)
    return bootstrap_ci_derived(fit, f; Y = Y, n_boot = n_boot, level = level,
                                seed = seed, N = N, verbose = verbose)
end
