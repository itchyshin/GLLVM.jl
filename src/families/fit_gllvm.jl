# Unified GLLVM fit entry point — dispatches on the response family.

"""
    fit_gllvm(Y; family = Normal(), K, num_lv = nothing,
              row_eff = :none, disp_group = nothing, pervar = false, kwargs...)

Fit a GLLVM, dispatching on the response `family` — a Distributions.jl
distribution used as a marker (the GLM.jl convention):

- `Normal()`   → [`fit_gaussian_gllvm`](@ref) — closed-form Gaussian marginal
- `Binomial()` → [`fit_binomial_gllvm`](@ref) — Laplace marginal (binary / binomial)
- `Poisson()`  → [`fit_poisson_gllvm`](@ref) — Laplace marginal (counts)
- `TruncatedPoisson()` → [`fit_truncated_poisson_gllvm`](@ref) — zero-truncated Poisson
- `CensoredPoisson()` → [`fit_censored_poisson_gllvm`](@ref) — right-censored Poisson (Julia-forward)
- `Lognormal()` → [`fit_lognormal_gllvm`](@ref) — one-part lognormal (twin fid 3)
- `TruncatedNegBin2()` → [`fit_truncated_nbinom2_gllvm`](@ref) — zero-truncated NB2 (shared `r`)
- `NegativeBinomial()` → [`fit_nb_gllvm_grouped`](@ref) with per-species `r`
  (twin-aligned default; shared-`r` via [`fit_nb_gllvm`](@ref))
- `Beta()`     → [`fit_beta_gllvm_grouped`](@ref) with per-species `φ`
  (twin-aligned default; shared-`φ` via [`fit_beta_gllvm`](@ref))
- `NB1()`      → [`fit_nb1_gllvm_grouped`](@ref) with per-species linear-variance `φ`
  (twin-aligned default; shared-`φ` via [`fit_nb1_gllvm`](@ref)). The marker's `φ`
  field is a tag payload — it is never read here; `φ` is always estimated.
- `BetaBinom()` → [`fit_beta_binomial_gllvm_grouped`](@ref) with per-species Beta
  precision `φ` (twin-aligned default; shared-`φ` via
  [`fit_beta_binomial_gllvm`](@ref)). The marker's `φ` field is a tag payload, as for
  `NB1`. The p×n trial counts `N` are **required** on this route: at `N = 1` the
  beta-binomial collapses to `Bernoulli(μ)` and `φ` is unidentifiable, so the named
  fitter's all-ones default is not inherited here and a missing `N` errors.
- `Ordinal()`  → [`fit_ordinal_gllvm_pertrait`](@ref) — Laplace marginal (ordered categories)
- `Gamma()`    → [`fit_gamma_gllvm`](@ref) — Laplace marginal (positive continuous; shared shape)
- `Exponential()` → [`fit_exponential_gllvm`](@ref) — Laplace marginal
- `GeneralizedPoisson1(α)` → [`fit_gp1_gllvm`](@ref) — Laplace marginal (GP-1 counts, signed dispersion)
- `ZIB(N)` → [`fit_zib_gllvm`](@ref) — zero-inflated binomial (Julia-forward). Unlike the
  other markers, `ZIB` carries the shared trials count, so `N` travels on the family
  instance rather than as a keyword argument.

`K` is the latent dimension; the gllvm-style alias `num_lv` is accepted as a synonym
for `K` (gllvm uses `num.lv`). Family-specific keyword arguments (`link`, `N`,
`Σ_phy`, …) pass through to the underlying fitter.

# Structural / dispersion variants (gllvm-style keyword routing)

These keyword arguments route to the corresponding specialised fitter while keeping
the plain-call behaviour when they are at their defaults (regression safe):

- `row_eff::Symbol = :none` — community / random row effect (gllvm's `row.eff`):
  - `:none`   → no row effect (the standard dispatch above).
  - `:fixed`  → [`fit_roweffect_gllvm`](@ref) — per-site fixed intercept `ρ_s`.
  - `:random` → [`fit_row_random_gllvm`](@ref) — per-site random intercept `ρ_s ~ N(0, σ_row²)`.

- `disp_group` — grouped / species-specific dispersion (gllvm's `disp.group`).
  For `NegativeBinomial`, `Beta`, `NB1`, and `BetaBinom` only, `disp_group = nothing`
  is coerced to `:species` (per-trait φ / `r`, matching gllvmTMB). Pass a length-`p`
  integer vector of group ids for custom grouping, or `:species` explicitly. Routes to:
  - `NegativeBinomial` → [`fit_nb_gllvm_grouped`](@ref) (per-group `r`)
  - `Beta`             → [`fit_beta_gllvm_grouped`](@ref) (per-group `φ`)
  - `Gamma`            → [`fit_gamma_gllvm_grouped`](@ref) (per-species shape `α`; opt-in only)
  - `NB1`              → [`fit_nb1_gllvm_grouped`](@ref) (per-species linear-variance `φ`)
  - `BetaBinom`        → [`fit_beta_binomial_gllvm_grouped`](@ref) (per-group Beta
    precision `φ`; the p×n `N` keyword is required)
  - `GLLVM.TweedieED`  → [`fit_tweedie_gllvm_grouped`](@ref) (per-species `φ`, shared power)
  Families without a grouped fitter throw a clear `ArgumentError`. Shared
  dispersion for NB/Beta/NB1/BetaBinom remains available via the named fitters
  [`fit_nb_gllvm`](@ref) / [`fit_beta_gllvm`](@ref) / [`fit_nb1_gllvm`](@ref) /
  [`fit_beta_binomial_gllvm`](@ref).

- `pervar::Bool = false` — heteroscedastic (per-species variance) Gaussian. Only valid
  for `family = Normal()`; `true` routes to [`fit_gaussian_pervar_gllvm`](@ref).

## Precedence and unsupported combinations

The variants route to single specialised fitters; no single underlying fitter combines
two of them. Therefore at most one of `row_eff != :none`, effective
`disp_group !== nothing` (including the NB/Beta default coerce), and
`pervar == true` may be active. Any other combination throws an `ArgumentError`
("combination not yet supported") rather than silently ignoring a request.

```julia
fit_gllvm(Y; family = Normal(),   K = 2)                          # Gaussian
fit_gllvm(Y; family = Binomial(), K = 2, link = LogitLink())      # binary
fit_gllvm(Y; family = Poisson(),  K = 2, row_eff = :random)       # random row effect
fit_gllvm(Y; family = NegativeBinomial(1.0, 0.5), K = 2)          # per-species r (default)
fit_gllvm(Y; family = Beta(), K = 2)                              # per-species φ (default)
fit_gllvm(Y; family = NB1(),  K = 2)                              # per-species linear-variance φ
fit_gllvm(Y; family = BetaBinom(), K = 2, N = trials)             # per-species φ; N is p×n, required
fit_gllvm(Y; family = Normal(), K = 2, pervar = true)             # per-species variance
```
"""
function fit_gllvm(Y::AbstractMatrix; family = Normal(), K = nothing,
                   num_lv = nothing, row_eff::Symbol = :none,
                   disp_group = nothing, pervar::Bool = false, kwargs...)
    # gllvm's `num.lv` alias for K. If both given they must agree.
    if num_lv !== nothing
        if K !== nothing && K != num_lv
            throw(ArgumentError("fit_gllvm: K=$K and num_lv=$num_lv disagree; pass only one"))
        end
        K = num_lv
    end

    # API B (Curie): NB/Beta/NB1/BetaBinom public default matches gllvmTMB per-trait
    # φ — the estimand already shipped on the R bridge and on `@formula` with X, so
    # the unified entry point must not default to a shared scalar instead. Shared-φ
    # engines remain `fit_nb_gllvm` / `fit_beta_gllvm` / `fit_nb1_gllvm` /
    # `fit_beta_binomial_gllvm`. The NB1 and BetaBinom markers' `φ` fields are never
    # read: φ is always estimated. Gamma unchanged.
    if disp_group === nothing &&
       (family isa NegativeBinomial || family isa Beta || family isa NB1 ||
        family isa BetaBinom)
        disp_group = :species
    end

    # Count how many structural/dispersion variants are active. At most one is
    # supported, since each routes to a distinct single-purpose fitter.
    nvariants = (row_eff !== :none) + (disp_group !== nothing) + pervar
    if nvariants > 1
        throw(ArgumentError(
            "fit_gllvm: combination of row_eff=:$(row_eff), " *
            "disp_group=$(disp_group === nothing ? "nothing" : "set"), pervar=$pervar " *
            "is not yet supported — at most one of row_eff / disp_group / pervar may be active"))
    end

    # --- pervar: heteroscedastic Gaussian. -----------------------------------
    if pervar
        family isa Normal || throw(ArgumentError(
            "fit_gllvm: pervar=true is only supported for family=Normal() " *
            "(got $(nameof(typeof(family))))"))
        K === nothing && throw(ArgumentError("fit_gllvm: K (or num_lv) is required"))
        return fit_gaussian_pervar_gllvm(Y; K = K, kwargs...)
    end

    # --- row_eff: community (fixed) or random row effect. --------------------
    if row_eff !== :none
        K === nothing && throw(ArgumentError("fit_gllvm: K (or num_lv) is required"))
        if row_eff === :fixed
            return fit_roweffect_gllvm(Y; family = family, K = K, kwargs...)
        elseif row_eff === :random
            return fit_row_random_gllvm(Y; family = family, K = K, kwargs...)
        else
            throw(ArgumentError(
                "fit_gllvm: row_eff must be :none, :fixed, or :random (got :$(row_eff))"))
        end
    end

    # --- disp_group: grouped / species-specific dispersion. ------------------
    if disp_group !== nothing
        K === nothing && throw(ArgumentError("fit_gllvm: K (or num_lv) is required"))
        p = size(Y, 1)
        group = if disp_group === :species
            collect(1:p)
        elseif disp_group isa AbstractVector{<:Integer}
            collect(disp_group)
        else
            throw(ArgumentError(
                "fit_gllvm: disp_group must be :species or a length-p Int vector " *
                "(got $(typeof(disp_group)))"))
        end
        return _fit_gllvm_grouped(family, Y; K = K, group = group, kwargs...)
    end

    # --- default: family dispatch (unchanged behaviour). ---------------------
    K === nothing ? _fit_gllvm(family, Y; kwargs...) :
                    _fit_gllvm(family, Y; K = K, kwargs...)
end

_fit_gllvm(::Normal,   Y::AbstractMatrix; kwargs...) = fit_gaussian_gllvm(Y; kwargs...)
_fit_gllvm(::Binomial, Y::AbstractMatrix; kwargs...) = fit_binomial_gllvm(Y; kwargs...)
_fit_gllvm(::Poisson,  Y::AbstractMatrix; kwargs...) = fit_poisson_gllvm(Y; kwargs...)
_fit_gllvm(::TruncatedPoisson, Y::AbstractMatrix; kwargs...) =
    fit_truncated_poisson_gllvm(Y; kwargs...)
_fit_gllvm(::CensoredPoisson, Y::AbstractMatrix; kwargs...) =
    fit_censored_poisson_gllvm(Y; kwargs...)
_fit_gllvm(::Lognormal, Y::AbstractMatrix; kwargs...) =
    fit_lognormal_gllvm(Y; kwargs...)
_fit_gllvm(::TruncatedNegBin2, Y::AbstractMatrix; kwargs...) =
    fit_truncated_nbinom2_gllvm(Y; kwargs...)
_fit_gllvm(::NegativeBinomial, Y::AbstractMatrix; kwargs...) = fit_nb_gllvm(Y; kwargs...)
_fit_gllvm(::Beta,     Y::AbstractMatrix; kwargs...) = fit_beta_gllvm(Y; kwargs...)
_fit_gllvm(::Ordinal,  Y::AbstractMatrix; kwargs...) = fit_ordinal_gllvm_pertrait(Y; kwargs...)
_fit_gllvm(::Gamma,    Y::AbstractMatrix; kwargs...) = fit_gamma_gllvm(Y; kwargs...)
_fit_gllvm(::Exponential, Y::AbstractMatrix; kwargs...) = fit_exponential_gllvm(Y; kwargs...)
_fit_gllvm(::GeneralizedPoisson1, Y::AbstractMatrix; kwargs...) = fit_gp1_gllvm(Y; kwargs...)
_fit_gllvm(::ZIPoisson, Y::AbstractMatrix; kwargs...) = fit_zip_gllvm(Y; kwargs...)
_fit_gllvm(::ZINegBin, Y::AbstractMatrix; kwargs...) = fit_zinb_gllvm(Y; kwargs...)
# `ZIB` is not a zero-arg marker: the shared scalar trials count travels on the
# family instance (`ZIB(N)`), so it is forwarded here rather than taken as a kwarg.
_fit_gllvm(family::ZIB, Y::AbstractMatrix; kwargs...) =
    fit_zib_gllvm(Y; N = family.N, kwargs...)

# No `_fit_gllvm(::NB1, …)` / `_fit_gllvm(::BetaBinom, …)` arms: the per-trait
# coerce above always sets `disp_group`, so both reach `_fit_gllvm_grouped`
# instead. A bare arm here would be unreachable and would advertise the shared-φ
# estimand, which is available only through the named `fit_nb1_gllvm` /
# `fit_beta_binomial_gllvm`.

# Clear error for families not yet implemented (hurdle, remaining zero-inflated, …).
_fit_gllvm(family, Y::AbstractMatrix; kwargs...) = throw(ArgumentError(
    "fit_gllvm: family $(nameof(typeof(family))) is not implemented yet " *
    "(available: Normal, Binomial, Poisson, TruncatedPoisson, CensoredPoisson, TruncatedNegBin2, Lognormal, NegativeBinomial, NB1, Beta, BetaBinom, Ordinal, Gamma, Exponential, GeneralizedPoisson1, ZIPoisson, ZINegBin, ZIB)"))

# --- grouped-dispersion routing keyed on the family marker. ------------------
_fit_gllvm_grouped(::NegativeBinomial, Y::AbstractMatrix; kwargs...) =
    fit_nb_gllvm_grouped(Y; kwargs...)
_fit_gllvm_grouped(::Beta,  Y::AbstractMatrix; kwargs...) = fit_beta_gllvm_grouped(Y; kwargs...)
_fit_gllvm_grouped(::Gamma, Y::AbstractMatrix; kwargs...) = fit_gamma_gllvm_grouped(Y; kwargs...)
_fit_gllvm_grouped(::NB1,   Y::AbstractMatrix; kwargs...) = fit_nb1_gllvm_grouped(Y; kwargs...)
_fit_gllvm_grouped(::TweedieED, Y::AbstractMatrix; kwargs...) =
    fit_tweedie_gllvm_grouped(Y; kwargs...)

# Beta-binomial: the trial counts are required here, unlike in the named fitter.
# `fit_beta_binomial_gllvm_grouped` defaults `N === nothing` to all-ones, but at
# N = 1 the beta-binomial collapses to `Bernoulli(μ)` and φ is unidentifiable —
# the log-density is flat in φ to roundoff. Inheriting that default at a public
# entry point would hand back a per-trait φ vector the likelihood cannot inform,
# with no warning, so a missing `N` is an error naming the keyword. A scalar `N`
# is likewise rejected rather than broadcast: shaping data is the family file's
# job, not the dispatcher's.
function _fit_gllvm_grouped(::BetaBinom, Y::AbstractMatrix; N = nothing, kwargs...)
    p, n = size(Y)
    N === nothing && throw(ArgumentError(
        "fit_gllvm: family BetaBinom requires the trial counts `N` as a $(p)×$(n) " *
        "matrix (φ is unidentifiable at N = 1, so there is no safe default) — " *
        "call fit_gllvm(Y; family = BetaBinom(), K = …, N = N)"))
    N isa AbstractMatrix || throw(ArgumentError(
        "fit_gllvm: family BetaBinom needs `N` as a $(p)×$(n) matrix, got " *
        "$(typeof(N)); a scalar is not broadcast here — pass fill(N, $p, $n)"))
    return fit_beta_binomial_gllvm_grouped(Y; N = N, kwargs...)
end

# Families without a grouped-dispersion fitter.
_fit_gllvm_grouped(family, Y::AbstractMatrix; kwargs...) = throw(ArgumentError(
    "fit_gllvm: disp_group (grouped dispersion) is not supported for family " *
    "$(nameof(typeof(family))) — available: NegativeBinomial, Beta, Gamma, NB1, BetaBinom, Tweedie (TweedieED)"))
