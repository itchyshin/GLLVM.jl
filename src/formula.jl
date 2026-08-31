# @formula front-end — a pre-processor mapping gllvmTMB-style syntax and StatsModels
# formulas onto the matrix-level engine. Slices 1–2 of the formula-front-end design spec
# (docs/superpowers/specs/2026-05-31-formula-frontend-random-slopes-design.md).
#
#     gllvm(@formula(y ~ 1 + temp + depth), Y, site_data; family = Poisson(), K = 2)
#     gllvm(@formula(y ~ 1 + temp + habitat), Y, site_data; contrasts = Dict(:habitat => DummyCoding()))
#
# Mapping (verified against the engine contract):
#  - The intercept `1` is the engine's BUILT-IN per-species intercept (the Gaussian
#    path profiles out the per-trait row mean — src/likelihood.jl:39; fit_gllvm_cov
#    carries explicit per-species β). So the `1` term is dropped here, not put into X.
#  - Site-level covariates (continuous, categorical contrasts via StatsModels, function
#    terms, interactions) become columns of the engine's (p, n, q) design X, broadcast
#    across species (X[t,s,k] = covariate[s,k]) ⇒ a coefficient SHARED across species.
#  - Dispatch: Normal() → fit_gaussian_gllvm(Y; X); other families → fit_gllvm_cov /
#    specialised grouped-cov fitters.
#
# StatsModels integration supports continuous covariates, categorical contrasts
# (DummyCoding, EffectsCoding, HelmertCoding, etc.), function transformations (e.g. `log(x)`),
# and interaction terms across site-level variables.
#
# StatsModels is imported SELECTIVELY so it does not bring StatsAPI's
# `predict`/`residuals`/`fit` into the module and clash with GLLVM's own post-fit generics.

import StatsModels
using StatsModels: @formula, FormulaTerm, Term, ConstantTerm, FunctionTerm, InteractionTerm, schema, apply_schema, modelmatrix, coefnames
import Tables

struct _FormulaKUnset end
const _FORMULA_K_UNSET = _FormulaKUnset()

function _extract_formula_symbols(term)
    syms = Symbol[]
    if term isa Term
        push!(syms, term.sym)
    elseif term isa FunctionTerm
        for arg in term.args
            append!(syms, _extract_formula_symbols(arg))
        end
    elseif term isa InteractionTerm
        for t in term.terms
            append!(syms, _extract_formula_symbols(t))
        end
    elseif term isa Tuple
        for t in term
            append!(syms, _extract_formula_symbols(t))
        end
    end
    return syms
end

# Extract site-level model matrix mm (n × q) and coefficient names from formula RHS.
function _build_site_modelmatrix(rhs, data; contrasts::AbstractDict = Dict{Symbol, Any}())
    cols = Tables.columntable(data)
    ts = rhs isa Tuple ? rhs : (rhs,)
    non_const = [t for t in ts if !(t isa ConstantTerm)]
    if isempty(non_const)
        n = length(Tables.rows(cols))
        return zeros(Float64, n, 0), String[]
    end

    # Validate that required symbols exist in data
    for t in non_const
        syms = _extract_formula_symbols(t)
        for s in syms
            haskey(cols, s) || throw(ArgumentError(
                "covariate `$s` in the formula is not a column of `data`"))
        end
    end

    rhs_term = length(non_const) == 1 ? non_const[1] : Tuple(non_const)
    f_cov = FormulaTerm(ConstantTerm(0), rhs_term)
    sch = StatsModels.schema(f_cov, cols, contrasts)
    applied = StatsModels.apply_schema(f_cov, sch)
    mm = StatsModels.modelmatrix(applied.rhs, cols)
    cnames = StatsModels.coefnames(applied.rhs)
    cnames_vec = cnames isa AbstractVector ? string.(cnames) : [string(cnames)]
    return Matrix{Float64}(mm), cnames_vec
end

# The per-variance Gaussian fitter treats X as the complete mean design. Use
# StatsModels' intercept/rank rules before expanding a site intercept to one
# coefficient per trait. Keep the legacy shared-variance route separate.
function _pervar_formula_design(rhs, cols, p, n; contrasts, names::Bool=false)
    intercept = !StatsModels.omitsintercept(rhs)
    site_names = String[]
    terms = rhs isa Tuple ? rhs : (rhs,)
    if all(t -> t isa ConstantTerm, terms)
        site = zeros(n, 0)
    else
        f = FormulaTerm(ConstantTerm(0), rhs)
        sch = StatsModels.schema(f, cols, contrasts)
        applied = StatsModels.apply_schema(f, sch, StatsModels.StatisticalModel)
        mm = Matrix{Float64}(StatsModels.modelmatrix(applied.rhs, cols))
        model_names = StatsModels.coefnames(applied.rhs)
        model_names = model_names isa AbstractVector ? string.(model_names) : [string(model_names)]
        intercept = StatsModels.hasintercept(applied.rhs)
        site_idx = findall(!=("(Intercept)"), model_names)
        site = mm[:, site_idx]
        site_names = model_names[site_idx]
    end
    size(site, 1) == n || throw(DimensionMismatch("formula design must have one row per site"))
    q0 = intercept ? p : 0
    X = zeros(p, n, q0 + size(site, 2))
    if intercept
        for t in 1:p
            X[t, :, t] .= 1
        end
    end
    for k in axes(site, 2), s in 1:n, t in 1:p
        X[t, s, q0 + k] = site[s, k]
    end
    if names
        coefficient_names = String[]
        append!(coefficient_names, ("trait_$(trait)" for trait in 1:p if intercept))
        append!(coefficient_names, site_names)
        return X, coefficient_names
    end
    return X
end

"""
    gllvm(formula, Y, data; family = Normal(), K, sources = nothing,
          contrasts = Dict(), kwargs...)

Fit a GLLVM from an R-`gllvmTMB`-style `@formula` over a wide species×site response
matrix `Y` (`p × n`) and a `Tables`-compatible `data` of **site-level** covariates
(one row per site = per column of `Y`).

```julia
using GLLVM, Distributions, StatsModels
gllvm(@formula(y ~ 1 + temp + depth), Y, site_data; family = Normal(),  K = 2)
gllvm(@formula(y ~ 1 + temp + habitat), Y, site_data; family = Poisson(), K = 2,
      contrasts = Dict(:habitat => DummyCoding()))
```

The response symbol on the formula LHS (`y`) names the matrix `Y` and is otherwise
ignored. The intercept (`1`) is the engine's built-in per-species intercept; each
covariate column on the RHS (continuous, categorical via `contrasts`, interactions)
becomes a coefficient **shared across species** (the engine's `(p,n,q)` design).
Dispatches to [`fit_gaussian_gllvm`](@ref) for `Normal()`, to [`fit_nb_gllvm_grouped_cov`](@ref) /
[`fit_beta_gllvm_grouped_cov`](@ref) / [`fit_gamma_gllvm_grouped_cov`](@ref) /
[`fit_nb1_gllvm_grouped_cov`](@ref) / `fit_beta_binomial_gllvm_grouped_cov` for
NB2/NB1/Beta/Gamma/beta-binomial (per-trait φ/α + shared site-X; twin API B; the
beta-binomial route also threads a binomial-style `N` trial-count kwarg), to
[`fit_ordinal_gllvm_pertrait_cov`](@ref) for `Ordinal()` (per-trait cutpoints +
shared site-X), to [`fit_zip_gllvm_cov`](@ref) for `ZIPoisson()` (separate
`γz`/`γc`, `Λz=0`; Julia-forward), to [`fit_zinb_gllvm_cov`](@ref) for
`ZINegBin()` (separate `γz`/`γc`, `Λz=0`, shared scalar `r`; Julia-forward),
and to [`fit_gllvm_cov`](@ref) for the other non-Gaussian families (shared
dispersion + X). Returns that fitter's result.
For `Normal()`, `pervar=true` instead selects
[`fit_gaussian_pervar_gllvm`](@ref). This route constructs the complete mean:
`y ~ 1 + x` (or `y ~ x`) has trait-specific intercepts and a shared slope;
`y ~ 0 + x` or `y ~ -1 + x` removes those intercepts. `y ~ 0` is zero mean.
`fixed_residual_sd=c` passes an explicit fixed residual scale to this route;
it does not choose R's data-dependent scale automatically. Categorical contrasts
follow StatsModels' rank rules. Do not also supply `X` with a formula.
The default shared-variance route keeps its existing behavior.
With no covariates it reduces to the intercept-only fit. Supplied table columns
must still have one entry per site; an empty table is allowed for an
intercept-only formula because `Y` supplies the site count.
With explicit `sources`, only `Normal()` is admitted and `K`, `pervar=true`, and
an explicit `X` are rejected. The formula then supplies the complete source-model
mean design: trait-specific intercept columns (when present) and shared
site-level coefficients, using StatsModels' contrast, interaction, and rank
rules. This does not parse formula source terms, trees, pedigrees, meshes, or
random slopes.
`ZIB` through `@formula` is **no-X only** for now (bridge still OWED; ZIB+X formula
is fenced).
"""
function gllvm(formula::FormulaTerm, Y::AbstractMatrix, data;
               family = Normal(), K::Union{Integer, _FormulaKUnset} = _FORMULA_K_UNSET,
               sources = nothing,
               pervar::Bool = false,
               contrasts::AbstractDict = Dict{Symbol, Any}(), kwargs...)
    p, n = size(Y)
    cols = Tables.columntable(data)
    for (name, column) in pairs(cols)
        length(column) == n || throw(DimensionMismatch(
            "`data` column `$name` has $(length(column)) rows but Y has $n sites (columns)"))
    end
    if sources !== nothing
        family isa Normal || throw(ArgumentError("formula source models require family=Normal()"))
        K === _FORMULA_K_UNSET || throw(ArgumentError("do not supply K with explicit sources; each source owns its rank"))
        pervar && throw(ArgumentError("pervar=true is incompatible with explicit sources"))
        haskey(kwargs, :X) && throw(ArgumentError("do not supply X with a source formula; the formula defines the complete mean"))
        haskey(kwargs, :coefficient_names) && throw(ArgumentError("do not supply coefficient_names with a source formula; the formula supplies them"))
        X, coefficient_names = _pervar_formula_design(
            formula.rhs, cols, p, n; contrasts=contrasts, names=true)
        return fit_gaussian_sources(Y; sources=sources, X=X,
            coefficient_names=coefficient_names, kwargs...)
    end
    K === _FORMULA_K_UNSET && throw(UndefKeywordError(:K))
    if pervar
        family isa Normal || throw(ArgumentError("pervar=true requires family=Normal()"))
        haskey(kwargs, :X) && throw(ArgumentError("do not supply X with a pervar formula; the formula defines the complete mean"))
        X = _pervar_formula_design(formula.rhs, cols, p, n; contrasts=contrasts)
        return fit_gllvm(Y; family=family, K=K, pervar=true, X=X, kwargs...)
    end
    mm, cnames = _build_site_modelmatrix(formula.rhs, cols; contrasts = contrasts)
    q = size(mm, 2)

    if q == 0
        return family isa Normal ? fit_gaussian_gllvm(Y; K = K, kwargs...) :
               family isa ZIPoisson ? fit_zip_gllvm(Y; K = K, kwargs...) :
               family isa ZINegBin ? fit_zinb_gllvm(Y; K = K, kwargs...) :
               family isa ZIB ? fit_gllvm(Y; family = family, K = K, kwargs...) :
                                fit_gllvm(Y; family = family, K = K, kwargs...)
    end

    size(mm, 1) == n || throw(DimensionMismatch(
        "`data` has $(size(mm, 1)) rows but Y has $n sites (columns)"))

    X = Array{Float64, 3}(undef, p, n, q)
    @inbounds for k in 1:q, s in 1:n, t in 1:p
        X[t, s, k] = mm[s, k]
    end

    if family isa Normal
        return fit_gaussian_gllvm(Y; X = X, K = K, kwargs...)
    elseif family isa NegativeBinomial
        return fit_nb_gllvm_grouped_cov(Y; X = X, K = K, kwargs...)
    elseif family isa Beta
        return fit_beta_gllvm_grouped_cov(Y; X = X, K = K, kwargs...)
    elseif family isa Gamma
        return fit_gamma_gllvm_grouped_cov(Y; X = X, K = K, kwargs...)
    elseif family isa NB1
        return fit_nb1_gllvm_grouped_cov(Y; X = X, K = K, kwargs...)
    elseif family isa BetaBinom
        return fit_beta_binomial_gllvm_grouped_cov(Y; X = X, K = K, kwargs...)
    elseif family isa Ordinal
        return fit_ordinal_gllvm_pertrait_cov(Y; X = X, K = K, kwargs...)
    elseif family isa ZIPoisson
        return fit_zip_gllvm_cov(Y; X = X, K = K, kwargs...)
    elseif family isa ZINegBin
        return fit_zinb_gllvm_cov(Y; X = X, K = K, kwargs...)
    elseif family isa ZIB
        throw(ArgumentError(
            "ZIB through @formula is no-X only for now (pass `@formula(y ~ 1)`); " *
            "ZIB+X formula / bridge admission is still OWED"))
    else
        return fit_gllvm_cov(Y; family = family, X = X, K = K, kwargs...)
    end
end

"""
    gllvm(formula, long_data; family = Normal(), K, species = :species, site = :site,
          contrasts = Dict(), kwargs...)

Long-format (melted) front door: one row per `(species, site)` observation. Pivots
`long_data` to the wide `(Y, site_data)` representation and calls the wide
[`gllvm`](@ref) — so the two data shapes share one engine path.

```julia
# long_data has columns y, species, site, temp, habitat
gllvm(@formula(y ~ 1 + temp + habitat), long_data; family = Poisson(), K = 2,
      species = :species, site = :site, contrasts = Dict(:habitat => DummyCoding()))
```

The formula LHS names the response column; `species`/`site` name the grouping
keys (default `:species`/`:site`). `Y` is built in sorted species×site order, so
`gllvm(f, long)` and `gllvm(f, Y, site_data)` give **identical** fits (a tested
round-trip identity). Requires a **complete** species×site grid (no missing
cells) and site covariates that are **constant within site** (both validated with
a clear error), matching the wide-mode contract.
For explicit Gaussian `sources`, source projection rows must correspond to this
same sorted site order; the long route passes that order through to the wide
source fitter unchanged.
"""
function gllvm(formula::FormulaTerm, long_data; family = Normal(),
               K::Union{Integer, _FormulaKUnset} = _FORMULA_K_UNSET,
               species::Symbol = :species, site::Symbol = :site,
               contrasts::AbstractDict = Dict{Symbol, Any}(), kwargs...)
    cols = Tables.columntable(long_data)
    formula.lhs isa Term || throw(ArgumentError(
        "long-format gllvm needs a single response column on the formula LHS; got $(formula.lhs)"))
    rsym = formula.lhs.sym
    for key in (rsym, species, site)
        haskey(cols, key) || throw(ArgumentError("column `$key` not found in long data"))
    end
    spcol = getproperty(cols, species)
    stcol = getproperty(cols, site)
    ycol  = getproperty(cols, rsym)
    nrow = length(ycol)
    (length(spcol) == nrow && length(stcol) == nrow) ||
        throw(DimensionMismatch("response, species, and site columns must have equal length"))

    splevels = sort(unique(spcol)); stlevels = sort(unique(stcol))
    p = length(splevels); n = length(stlevels)
    spidx = Dict(v => i for (i, v) in enumerate(splevels))
    stidx = Dict(v => j for (j, v) in enumerate(stlevels))

    Y = Matrix{eltype(ycol)}(undef, p, n)
    filled = falses(p, n)
    @inbounds for r in 1:nrow
        i = spidx[spcol[r]]; j = stidx[stcol[r]]
        filled[i, j] && throw(ArgumentError(
            "duplicate (species, site) = ($(spcol[r]), $(stcol[r])) in long data"))
        Y[i, j] = ycol[r]; filled[i, j] = true
    end
    all(filled) || throw(ArgumentError(
        "long data is not a complete species×site grid (v1 requires every cell present; " *
        "missing-response handling is a separate capability)"))

    # Repeated terms in interactions share one site-level column. `unique`
    # preserves first occurrence, which keeps the formula's covariate order.
    syms = unique(_extract_formula_symbols(formula.rhs))
    site_data = if isempty(syms)
        NamedTuple()
    else
        vecs = map(syms) do cv
            haskey(cols, cv) || throw(ArgumentError("covariate `$cv` not found in long data"))
            col = getproperty(cols, cv)
            vals = Vector{eltype(col)}(undef, n)
            seen = falses(n)
            for r in 1:nrow
                j = stidx[stcol[r]]
                if seen[j]
                    isequal(vals[j], col[r]) || throw(ArgumentError(
                        "covariate `$cv` is not constant within site `$(stcol[r])` " *
                        "(a site-level covariate must repeat identically down the species axis)"))
                else
                    vals[j] = col[r]; seen[j] = true
                end
            end
            vals
        end
        NamedTuple{Tuple(syms)}(Tuple(vecs))
    end

    if K === _FORMULA_K_UNSET
        return gllvm(formula, Y, site_data; family=family, contrasts=contrasts, kwargs...)
    end
    return gllvm(formula, Y, site_data; family=family, K=K,
        contrasts=contrasts, kwargs...)
end
