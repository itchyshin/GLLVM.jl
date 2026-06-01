# @formula front-end (v1) — a thin pre-processor mapping gllvmTMB-style syntax onto
# the matrix-level engine. Slices 1–2 of the formula-front-end design spec
# (docs/superpowers/specs/2026-05-31-formula-frontend-random-slopes-design.md).
#
#     gllvm(@formula(y ~ 1 + temp + depth), Y, site_data; family = Poisson(), K = 2)
#
# Mapping (verified against the engine contract):
#  - The intercept `1` is the engine's BUILT-IN per-species intercept (the Gaussian
#    path profiles out the per-trait row mean — src/likelihood.jl:39; fit_gllvm_cov
#    carries explicit per-species β). So the `1` term is dropped here, not put into X.
#  - Each continuous main-effect covariate (a site-level column of `data`, length n)
#    becomes a column of the engine's (p, n, q) design X, broadcast across species
#    (X[t,s,k] = covariate[s]) ⇒ a coefficient SHARED across species. This is the
#    direct (p,n,q)/shared-γ contract of the engine; species-specific responses
#    (fourth-corner `temp & traits(...)`) are a later slice.
#  - Dispatch: Normal() → fit_gaussian_gllvm(Y; X); other families → fit_gllvm_cov.
#
# v1 scope (errors clearly otherwise): an intercept + continuous main-effect
# covariates resolved against a Tables-compatible `data` of site-level covariates
# (one row per column of Y). Categorical terms, interactions, function terms, and
# random-effect terms `(… | g)` are NOT yet wired — they are deferred slices.
#
# StatsModels is imported SELECTIVELY (only the `@formula` macro + term types) so it
# does not bring StatsAPI's `predict`/`residuals`/`fit` into the module and clash
# with GLLVM's own post-fit generics.

using StatsModels: @formula, FormulaTerm, Term, ConstantTerm
import Tables

# Continuous main-effect covariate symbols from a formula RHS (intercept dropped).
function _formula_covariates(rhs)
    ts = rhs isa Tuple ? rhs : (rhs,)
    syms = Symbol[]
    for t in ts
        if t isa ConstantTerm
            continue                                  # intercept = engine's built-in
        elseif t isa Term
            push!(syms, t.sym)
        else
            throw(ArgumentError(
                "gllvm(@formula …) v1 supports an intercept + continuous main-effect " *
                "covariates only; got unsupported term `$(t)`. Categorical terms, " *
                "interactions (fourth-corner `a & b`), function terms (`log(x)`), and " *
                "random-effect terms `(… | g)` are not yet wired — see the formula " *
                "front-end design spec."))
        end
    end
    return syms
end

"""
    gllvm(formula, Y, data; family = Normal(), K, kwargs...)

Fit a GLLVM from an R-`gllvmTMB`-style `@formula` over a wide species×site response
matrix `Y` (`p × n`) and a `Tables`-compatible `data` of **site-level** covariates
(one row per site = per column of `Y`).

```julia
using GLLVM, Distributions
gllvm(@formula(y ~ 1 + temp + depth), Y, site_data; family = Normal(),  K = 2)
gllvm(@formula(y ~ 1 + temp),         Y, site_data; family = Poisson(), K = 2)
```

The response symbol on the formula LHS (`y`) names the matrix `Y` and is otherwise
ignored. The intercept (`1`) is the engine's built-in per-species intercept; each
continuous covariate on the RHS becomes a coefficient **shared across species**
(the engine's `(p,n,q)` design). Dispatches to [`fit_gaussian_gllvm`](@ref) for
`Normal()` and to [`fit_gllvm_cov`](@ref) for the non-Gaussian families, returning
that fitter's result (`GllvmFit`, or `GllvmCovFit` whose `γ[k]` matches the k-th
RHS covariate). With no covariates it reduces to the intercept-only fit.

**v1 scope:** intercept + continuous main-effect covariates. Categorical terms,
interactions (`a & b` / fourth-corner), function terms, and random effects
`(… | g)` are deferred (they error with a clear message). See the formula
front-end design spec for the full grammar and the random-slope roadmap.
"""
function gllvm(formula::FormulaTerm, Y::AbstractMatrix, data;
               family = Normal(), K::Integer, kwargs...)
    p, n = size(Y)
    syms = _formula_covariates(formula.rhs)
    q = length(syms)
    # `columntable` accepts any Tables-compatible source (NamedTuple of vectors,
    # DataFrame, …) and errors clearly on a non-table.
    cols = Tables.columntable(data)

    if q == 0
        return family isa Normal ? fit_gaussian_gllvm(Y; K = K, kwargs...) :
                                   fit_gllvm(Y; family = family, K = K, kwargs...)
    end

    for s in syms
        haskey(cols, s) || throw(ArgumentError(
            "covariate `$s` in the formula is not a column of `data`"))
        col = getproperty(cols, s)
        length(col) == n || throw(DimensionMismatch(
            "`data` column `$s` has $(length(col)) rows but Y has $n sites (columns)"))
        eltype(col) <: Real || throw(ArgumentError(
            "covariate `$s` is non-numeric ($(eltype(col))); categorical covariates " *
            "are not yet supported in the @formula front-end (v1 = continuous only)"))
    end

    X = Array{Float64, 3}(undef, p, n, q)
    @inbounds for k in 1:q
        col = getproperty(cols, syms[k])
        for s in 1:n, t in 1:p
            X[t, s, k] = Float64(col[s])
        end
    end

    return family isa Normal ? fit_gaussian_gllvm(Y; X = X, K = K, kwargs...) :
                               fit_gllvm_cov(Y; family = family, X = X, K = K, kwargs...)
end
