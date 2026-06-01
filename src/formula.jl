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

"""
    gllvm(formula, long_data; family = Normal(), K, species = :species, site = :site, kwargs...)

Long-format (melted) front door: one row per `(species, site)` observation. Pivots
`long_data` to the wide `(Y, site_data)` representation and calls the wide
[`gllvm`](@ref) — so the two data shapes share one engine path.

```julia
# long_data has columns y, species, site, temp (site covariate repeated per species)
gllvm(@formula(y ~ 1 + temp), long_data; family = Poisson(), K = 2,
      species = :species, site = :site)
```

The formula LHS names the response column; `species`/`site` name the grouping
keys (default `:species`/`:site`). `Y` is built in sorted species×site order, so
`gllvm(f, long)` and `gllvm(f, Y, site_data)` give **identical** fits (a tested
round-trip identity). v1 requires a **complete** species×site grid (no missing
cells) and site covariates that are **constant within site** (both validated with
a clear error), matching the wide-mode contract.
"""
function gllvm(formula::FormulaTerm, long_data; family = Normal(), K::Integer,
               species::Symbol = :species, site::Symbol = :site, kwargs...)
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

    syms = _formula_covariates(formula.rhs)
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

    return gllvm(formula, Y, site_data; family = family, K = K, kwargs...)
end
