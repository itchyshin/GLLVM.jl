# Unified GLLVM fit entry point — dispatches on the response family.

"""
    fit_gllvm(Y; family = Normal(), K, num_lv = nothing,
              row_eff = :none, disp_group = nothing, pervar = false, kwargs...)

Fit a GLLVM, dispatching on the response `family` — a Distributions.jl
distribution used as a marker (the GLM.jl convention):

- `Normal()`   → [`fit_gaussian_gllvm`](@ref) — closed-form Gaussian marginal
- `Binomial()` → [`fit_binomial_gllvm`](@ref) — Laplace marginal (binary / binomial)
- `Poisson()`  → [`fit_poisson_gllvm`](@ref) — Laplace marginal (counts)
- `NegativeBinomial()` → [`fit_nb_gllvm`](@ref) — Laplace marginal (overdispersed counts)
- `Beta()`     → [`fit_beta_gllvm`](@ref) — Laplace marginal (proportions in (0,1))
- `Ordinal()`  → [`fit_ordinal_gllvm`](@ref) — Laplace marginal (ordered categories)
- `Gamma()`    → [`fit_gamma_gllvm`](@ref) — Laplace marginal (positive continuous)
- `Exponential()` → [`fit_exponential_gllvm`](@ref) — Laplace marginal
- `GeneralizedPoisson1(α)` → [`fit_gp1_gllvm`](@ref) — Laplace marginal (GP-1 counts, signed dispersion)

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

- `disp_group = nothing` — grouped / species-specific dispersion (gllvm's `disp.group`).
  Pass a length-`p` integer vector of group ids, or the symbol `:species` for the
  per-species map `1:p`. Routes to the family's grouped fitter:
  - `NegativeBinomial` → [`fit_nb_gllvm_grouped`](@ref) (per-species `r`)
  - `Beta`             → [`fit_beta_gllvm_grouped`](@ref) (per-species `φ`)
  - `Gamma`            → [`fit_gamma_gllvm_grouped`](@ref) (per-species shape `α`)
  - `GLLVM.NB1`        → [`fit_nb1_gllvm_grouped`](@ref) (per-species linear-variance `φ`)
  - `GLLVM.TweedieED`  → [`fit_tweedie_gllvm_grouped`](@ref) (per-species `φ`, shared power)
  Families without a grouped fitter throw a clear `ArgumentError`.

- `pervar::Bool = false` — heteroscedastic (per-species variance) Gaussian. Only valid
  for `family = Normal()`; `true` routes to [`fit_gaussian_pervar_gllvm`](@ref).

## Precedence and unsupported combinations

The variants route to single specialised fitters; no single underlying fitter combines
two of them. Therefore at most one of `row_eff != :none`, `disp_group !== nothing`, and
`pervar == true` may be active. Any other combination throws an `ArgumentError`
("combination not yet supported") rather than silently ignoring a request.

```julia
fit_gllvm(Y; family = Normal(),   K = 2)                          # Gaussian
fit_gllvm(Y; family = Binomial(), K = 2, link = LogitLink())      # binary
fit_gllvm(Y; family = Poisson(),  K = 2, row_eff = :random)       # random row effect
fit_gllvm(Y; family = NegativeBinomial(1.0, 0.5), K = 2,
          disp_group = :species)                                  # per-species dispersion
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
_fit_gllvm(::NegativeBinomial, Y::AbstractMatrix; kwargs...) = fit_nb_gllvm(Y; kwargs...)
_fit_gllvm(::Beta,     Y::AbstractMatrix; kwargs...) = fit_beta_gllvm(Y; kwargs...)
_fit_gllvm(::Ordinal,  Y::AbstractMatrix; kwargs...) = fit_ordinal_gllvm(Y; kwargs...)
_fit_gllvm(::Gamma,    Y::AbstractMatrix; kwargs...) = fit_gamma_gllvm(Y; kwargs...)
_fit_gllvm(::Exponential, Y::AbstractMatrix; kwargs...) = fit_exponential_gllvm(Y; kwargs...)
_fit_gllvm(::GeneralizedPoisson1, Y::AbstractMatrix; kwargs...) = fit_gp1_gllvm(Y; kwargs...)

# Clear error for families not yet implemented (hurdle, zero-inflated, …).
_fit_gllvm(family, Y::AbstractMatrix; kwargs...) = throw(ArgumentError(
    "fit_gllvm: family $(nameof(typeof(family))) is not implemented yet " *
    "(available: Normal, Binomial, Poisson, NegativeBinomial, Beta, Ordinal, Gamma, Exponential, GeneralizedPoisson1)"))

# --- grouped-dispersion routing keyed on the family marker. ------------------
_fit_gllvm_grouped(::NegativeBinomial, Y::AbstractMatrix; kwargs...) =
    fit_nb_gllvm_grouped(Y; kwargs...)
_fit_gllvm_grouped(::Beta,  Y::AbstractMatrix; kwargs...) = fit_beta_gllvm_grouped(Y; kwargs...)
_fit_gllvm_grouped(::Gamma, Y::AbstractMatrix; kwargs...) = fit_gamma_gllvm_grouped(Y; kwargs...)
_fit_gllvm_grouped(::NB1,   Y::AbstractMatrix; kwargs...) = fit_nb1_gllvm_grouped(Y; kwargs...)
_fit_gllvm_grouped(::TweedieED, Y::AbstractMatrix; kwargs...) =
    fit_tweedie_gllvm_grouped(Y; kwargs...)

# Families without a grouped-dispersion fitter.
_fit_gllvm_grouped(family, Y::AbstractMatrix; kwargs...) = throw(ArgumentError(
    "fit_gllvm: disp_group (grouped dispersion) is not supported for family " *
    "$(nameof(typeof(family))) — available: NegativeBinomial, Beta, Gamma, NB1, Tweedie (TweedieED)"))
