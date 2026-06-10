# Tables.jl / DataFrame + `@formula` front-end for GLLVM.jl  (lane A4).
#
# The matrix API (`fit_gaussian_gllvm(y; K)`, `fit_poisson_gllvm(Y; K)`, …,
# `fit_mixed_gllvm(Y; families, K)`) takes a p×n traits×sites matrix. This file
# is ADDITIVE sugar on top of it: it reads a table, builds that p×n matrix (plus,
# for the Gaussian path, the (p, n, q) fixed-effect array), dispatches to the
# right fitter, and returns the SAME fit struct wrapped with the trait /
# covariate NAMES preserved for display. It edits no fitter.
#
# ---------------------------------------------------------------------------
# GRAMMAR (the deliberate design choice)
# ---------------------------------------------------------------------------
# gllvmTMB embeds the latent term in the formula RHS, e.g.
#     value ~ 0 + trait + latent(0 + trait | unit, d = K)
# Reproducing that needs a custom StatsModels term (`latent(...)` as a
# special-function term with its own schema/modelcols), which is heavy and
# "magic". We instead split responsibilities the Julian way:
#
#   * StatsModels `@formula` does ONLY what it is good at — the FIXED-EFFECT
#     mean design Xβ. The LHS is ignored (the responses are named separately),
#     so write the RHS only:  `@formula(0 ~ 1 + temp)`.
#   * The GLLVM-specific roles are EXPLICIT keyword arguments: latent dim `K`,
#     the trait / site / response columns, and the response `family`.
#
# This keeps the front-end transparent (no hidden term rewriting), reuses the
# whole StatsModels contrast / interaction machinery for covariates for free,
# and maps 1-to-1 onto the matrix fitters.
#
# Two table layouts, both first-class:
#
#   WIDE  — one column per trait; each ROW is a site.
#     gllvm(df; responses = [:y1, :y2, :y3], K = 2)                  # Gaussian
#     gllvm(df; responses = [:y1, :y2, :y3], K = 2, family = Poisson())
#     gllvm(df; responses = [:y1, :y2, :y3], K = 2,
#               formula = @formula(0 ~ 1 + temp))                    # + covariate
#
#   LONG  — a trait key column + a value column + a site key column.
#     gllvm(df; response = :value, trait = :species, site = :plot, K = 2)
#
# Per-trait families (the mixed-family headline) — pass a length-p vector
# (WIDE order = `responses`; LONG order = sorted unique trait levels):
#     gllvm(df; responses = [:a, :b, :c], K = 1,
#               family = [Normal(), Poisson(), Binomial()])
#
# COVARIATE SCOPE: Gaussian covariates route to `fit_gaussian_gllvm`'s existing
# X path. NON-Gaussian + covariate FAILS LOUDLY (deferred to the A1-Xβ lane) —
# never a silent drop.

# ---------------------------------------------------------------------------
# Result wrapper: the underlying fit + the preserved names.
# ---------------------------------------------------------------------------

"""
    GllvmFormulaFit

Thin wrapper returned by [`gllvm`](@ref). Holds the underlying matrix-API fit
together with the names recovered from the table, so the result displays in
trait / covariate terms. The numerical fit is byte-for-byte the matrix-API fit.

Fields:
- `fit` — the wrapped fit struct (`GllvmFit`, `PoissonFit`, …, or `MixedFamilyFit`).
- `responses::Vector{Symbol}` — trait names, in the p-row order of the fitted `Y`.
- `coefnames::Vector{String}` — fixed-effect column names (`String[]` when none).
- `layout::Symbol` — `:wide` or `:long` (how the table was read).
- `Y::Matrix` — the p×n response matrix that was fitted (kept so post-fit
  helpers like `getLV` / `predict`, which need the data, can be called).
- `N::Union{Nothing, Matrix}` — Binomial trial counts (p×n) when supplied, else `nothing`.

Access the wrapped fit with `f.fit`; loglik / fields pass through it.
"""
struct GllvmFormulaFit{F}
    fit::F
    responses::Vector{Symbol}
    coefnames::Vector{String}
    layout::Symbol
    Y::Matrix{Float64}
    N::Union{Nothing, Matrix{Int}}
end

# Pass-throughs so the wrapper is ergonomic without unwrapping.
_loglik(f::GllvmFormulaFit) = _loglik(f.fit)
aic(f::GllvmFormulaFit) = aic(f.fit)
bic(f::GllvmFormulaFit, n_sites::Integer) = bic(f.fit, n_sites)

function Base.show(io::IO, ::MIME"text/plain", f::GllvmFormulaFit)
    println(io, "GLLVM fit (formula/table front-end, ", f.layout, " layout)")
    println(io, "  responses (p=", length(f.responses), "): ",
            join(string.(f.responses), ", "))
    if !isempty(f.coefnames)
        println(io, "  fixed effects: ", join(f.coefnames, ", "))
    end
    print(io, "  ")
    show(io, MIME"text/plain"(), f.fit)
end

Base.show(io::IO, f::GllvmFormulaFit) =
    print(io, "GllvmFormulaFit(", f.layout, ", p=", length(f.responses),
          ", ", typeof(f.fit).name.name, ")")

# ---------------------------------------------------------------------------
# Table reading: WIDE / LONG → p×n response matrix (+ names).
# ---------------------------------------------------------------------------

# Wide layout: each `responses` column is one trait (a p-row of Y); rows = sites.
# Returns (Y::p×n, trait_names, site_count). Element type is the caller's choice
# at this point — we keep raw values and let the family-specific coercion decide.
function _read_wide(data, responses::AbstractVector{Symbol})
    cols = Tables.columns(data)
    isempty(responses) &&
        throw(ArgumentError("`responses` must list at least one trait column"))
    for r in responses
        Tables.columnindex(cols, r) == 0 &&
            throw(ArgumentError("response column :$r not found in the table"))
    end
    p = length(responses)
    coldata = [Tables.getcolumn(cols, r) for r in responses]
    n = length(coldata[1])
    all(length(c) == n for c in coldata) ||
        throw(ArgumentError("response columns have unequal length"))
    Y = Matrix{Any}(undef, p, n)
    @inbounds for t in 1:p, s in 1:n
        Y[t, s] = coldata[t][s]
    end
    return Y, collect(responses), n
end

# Long layout: pivot (trait, site, value) into p×n. Trait rows are sorted unique
# trait levels; site columns are sorted unique site levels. Errors on a missing
# (trait, site) cell or a duplicate (a long table must be one value per cell).
function _read_long(data, response::Symbol, trait::Symbol, site::Symbol)
    cols = Tables.columns(data)
    for (role, c) in ((:response, response), (:trait, trait), (:site, site))
        Tables.columnindex(cols, c) == 0 &&
            throw(ArgumentError("$role column :$c not found in the table"))
    end
    vals   = Tables.getcolumn(cols, response)
    traits = Tables.getcolumn(cols, trait)
    sites  = Tables.getcolumn(cols, site)
    trait_levels = sort(unique(traits))
    site_levels  = sort(unique(sites))
    p, n = length(trait_levels), length(site_levels)
    trait_pos = Dict(lv => i for (i, lv) in enumerate(trait_levels))
    site_pos  = Dict(lv => i for (i, lv) in enumerate(site_levels))
    Y = Matrix{Any}(undef, p, n)
    filled = falses(p, n)
    @inbounds for k in eachindex(vals)
        t = trait_pos[traits[k]]
        s = site_pos[sites[k]]
        filled[t, s] &&
            throw(ArgumentError(
                "duplicate (trait=$(trait_levels[t]), site=$(site_levels[s])) " *
                "rows in the long table; expected one value per cell"))
        Y[t, s] = vals[k]
        filled[t, s] = true
    end
    all(filled) || throw(ArgumentError(
        "the long table is not a complete trait×site grid " *
        "($(count(filled)) of $(p*n) cells present); GLLVM needs every cell"))
    return Y, Symbol.(string.(trait_levels)), n
end

# ---------------------------------------------------------------------------
# Family-appropriate coercion of the assembled p×n matrix.
# Counts (Poisson / NB / Binomial / Ordinal) want Integer; continuous families
# want Float64; Gaussian wants Float64. A per-trait mixed vector coerces each
# row by its own family.
# ---------------------------------------------------------------------------

_wants_integer(::Poisson)          = true
_wants_integer(::NegativeBinomial) = true
_wants_integer(::Binomial)         = true
_wants_integer(::Ordinal)          = true
_wants_integer(::Normal)           = false
_wants_integer(::Beta)             = false
_wants_integer(::Gamma)            = false
_wants_integer(fam) = throw(ArgumentError(
    "gllvm: unsupported response family $(nameof(typeof(fam)))"))

# Whole p×n matrix to one element type for a single-family fit.
function _coerce_matrix(Yany::AbstractMatrix, family)
    if _wants_integer(family)
        return Matrix{Int}(_to_int.(Yany))
    else
        return Matrix{Float64}(float.(Yany))
    end
end

function _to_int(v)
    iv = round(Int, float(v))
    isapprox(float(v), iv; atol = 1e-8) ||
        throw(ArgumentError("count family needs integer responses; got $v"))
    return iv
end

# ---------------------------------------------------------------------------
# Fixed-effect design from the `@formula` RHS → (p, n, q) array + coef names.
# StatsModels builds an n×q site-level design X_site; the GLLVM X array repeats
# that design across the p trait rows (covariates are site-level, shared by all
# traits), matching `fit_gaussian_gllvm`'s (p, n_sites, q) contract.
# ---------------------------------------------------------------------------

function _build_fixed_effects(formula, data, p::Integer, n::Integer)
    formula === nothing && return (nothing, String[])
    # Apply the schema to the WHOLE formula (not the bare RHS): that wraps the
    # RHS terms in a MatrixTerm, so `modelcols` collapses them into one n×q
    # design matrix. (Applying it to the bare RHS leaves a raw term Tuple, whose
    # `modelcols` returns a per-term tuple — not what we want.) The LHS is a
    # placeholder constant we never read.
    sch = StatsModels.schema(data)
    f_t = StatsModels.apply_schema(formula, sch)
    Xm = StatsModels.modelcols(f_t.rhs, Tables.columntable(data))  # n×q
    Xm isa AbstractMatrix ||
        throw(ArgumentError("fixed-effect design did not resolve to a matrix; " *
                            "check the formula RHS"))
    size(Xm, 1) == n || throw(DimensionMismatch(
        "fixed-effect design has $(size(Xm,1)) rows; expected n_sites = $n"))
    q = size(Xm, 2)
    q == 0 && throw(ArgumentError(
        "the formula RHS produced no fixed-effect columns; drop `formula` for " *
        "an intercept-free latent-only model"))
    names_v = string.(StatsModels.coefnames(f_t.rhs))
    # (p, n, q): broadcast the site-level row s across all p traits.
    X = Array{Float64, 3}(undef, p, n, q)
    @inbounds for s in 1:n, t in 1:p, k in 1:q
        X[t, s, k] = Xm[s, k]
    end
    return (X, names_v)
end

# ---------------------------------------------------------------------------
# The public entry point.
# ---------------------------------------------------------------------------

"""
    gllvm(data; K, family = Normal(), formula = nothing,
          responses = nothing,                       # WIDE: trait columns
          response = nothing, trait = nothing, site = nothing,  # LONG keys
          N = nothing, link = nothing, kwargs...) -> GllvmFormulaFit

Fit a GLLVM from a Tables.jl / DataFrame table. A thin, transparent wrapper over
the matrix API: it builds the p×n traits×sites response matrix from the table,
routes to the right matrix fitter, and returns the fit with names preserved.

Layouts (choose by which keywords you pass):
- **WIDE** — `responses::Vector{Symbol}` lists one column per trait; each table
  row is a site.
- **LONG** — `response`, `trait`, and `site` name the value / trait-key /
  site-key columns; the table is pivoted to a complete trait×site grid.

Model bits (explicit, not in the formula):
- `K::Integer` — latent dimension (required).
- `family` — a single `Distributions` marker (`Normal()`, `Poisson()`,
  `Binomial()`, `NegativeBinomial()`, `Beta()`, `Gamma()`, `Ordinal()`), OR a
  length-p `Vector` of markers → a mixed-family fit (`fit_mixed_gllvm`). Ordinal
  is single-family only (mixed Ordinal is unsupported upstream).
- `formula` — optional `@formula` whose RHS is the site-level fixed-effect mean
  design Xβ; the LHS is ignored (write `@formula(0 ~ 1 + x)`). **Gaussian only**;
  a non-Gaussian family with a `formula` raises a clear deferral error.
- `N` — Binomial trial counts. WIDE: a `Vector{Symbol}` of trial-count columns
  (one per trait) OR a p×n matrix. (Defaults to all-ones, i.e. Bernoulli.)
- `link` — override the family's canonical link (single-family paths).
- other `kwargs` pass through to the underlying fitter (`g_tol`, `iterations`, …).

```julia
using DataFrames
df = DataFrame(y1 = randn(50), y2 = randn(50), y3 = randn(50), temp = randn(50))
f  = gllvm(df; responses = [:y1, :y2, :y3], K = 2, formula = @formula(0 ~ 1 + temp))
```
"""
function gllvm(data;
               K::Integer,
               family = Normal(),
               formula = nothing,
               responses::Union{Nothing, AbstractVector{Symbol}} = nothing,
               response::Union{Nothing, Symbol} = nothing,
               trait::Union{Nothing, Symbol} = nothing,
               site::Union{Nothing, Symbol} = nothing,
               N = nothing,
               link = nothing,
               kwargs...)
    Tables.istable(data) ||
        throw(ArgumentError("`data` must be a Tables.jl-compatible table (e.g. a DataFrame)"))

    # --- Resolve layout & read the response matrix (+ trait names).
    is_wide = responses !== nothing
    is_long = response !== nothing || trait !== nothing || site !== nothing
    if is_wide && is_long
        throw(ArgumentError(
            "pass EITHER `responses` (wide) OR `response`/`trait`/`site` (long), not both"))
    elseif is_wide
        Yany, resp_names, n = _read_wide(data, responses)
        layout = :wide
    elseif is_long
        (response !== nothing && trait !== nothing && site !== nothing) ||
            throw(ArgumentError(
                "long layout needs all of `response`, `trait`, and `site`"))
        Yany, resp_names, n = _read_long(data, response, trait, site)
        layout = :long
    else
        throw(ArgumentError(
            "specify the layout: `responses=[…]` (wide) or " *
            "`response=…, trait=…, site=…` (long)"))
    end
    p = length(resp_names)

    # --- `N` (trial counts) is only meaningful when some trait is Binomial.
    # Checked here so it is rejected uniformly (the Gaussian path never consults
    # N, so a silent drop would otherwise slip through).
    if N !== nothing
        has_binom = family isa Binomial ||
            (family isa AbstractVector && any(f -> f isa Binomial, family))
        has_binom || throw(ArgumentError(
            "`N` (trial counts) given but no trait has a Binomial family"))
    end

    # --- Covariate guardrail (applies to mixed and single non-Gaussian alike):
    # only `fit_gaussian_gllvm` has an X path today.
    nongaussian_with_formula =
        formula !== nothing &&
        !(family isa Normal) &&                       # single non-Gaussian
        !(family isa AbstractVector && all(f -> f isa Normal, family))
    if nongaussian_with_formula
        fam_str = family isa AbstractVector ?
            "per-trait families [" *
                join((nameof(typeof(f)) for f in family), ", ") * "]" :
            string(nameof(typeof(family)))
        throw(ArgumentError(
            "gllvm: a `formula` (fixed-effect covariates) with a non-Gaussian " *
            "family ($fam_str) is not yet supported — non-Gaussian Xβ is " *
            "deferred (pending the A1-Xβ lane). Drop the formula, or use " *
            "family = Normal()."))
    end

    # --- Build the fixed-effect design once (Gaussian-only paths reach here).
    X, coef = _build_fixed_effects(formula, data, p, n)

    # --- Mixed (per-trait family vector) vs single family.
    if family isa AbstractVector
        length(family) == p || throw(DimensionMismatch(
            "`family` vector has length $(length(family)); expected one per " *
            "trait (p = $p)"))
        # `fit_mixed_gllvm` has no X path; the guardrail above only spares the
        # all-Normal case, so forbid a formula here too.
        formula === nothing || throw(ArgumentError(
            "gllvm: `formula` covariates are not supported with a per-trait " *
            "`family` vector yet (mixed-family Xβ is deferred). Drop the formula."))
        # Mixed rows mix types (counts / proportions / …): coerce each row by its
        # own family, then store as Float64 (fit reads each row by family).
        Ymix = _coerce_mixed(Yany, family, p, n)
        Nmat = _mixed_binom_N(family, N, p, n)
        links_v = link === nothing ? nothing : link
        fit = if Nmat === nothing
            fit_mixed_gllvm(Ymix; families = collect(family), K = K,
                            links = links_v, kwargs...)
        else
            fit_mixed_gllvm(Ymix; families = collect(family), K = K,
                            links = links_v, N = Nmat, kwargs...)
        end
        return GllvmFormulaFit(fit, resp_names, String[], layout,
                               Matrix{Float64}(Ymix), Nmat)
    elseif family isa Normal
        Y = _coerce_matrix(Yany, Normal())
        fit = X === nothing ? fit_gaussian_gllvm(Y; K = K, kwargs...) :
                              fit_gaussian_gllvm(Y; K = K, X = X, kwargs...)
        return GllvmFormulaFit(fit, resp_names, coef, layout, Y, nothing)
    else
        Y = _coerce_matrix(Yany, family)
        Nmat = _single_binom_N(family, N, p, n)
        fit = _fit_single(family, Y, K, link, Nmat; kwargs...)
        return GllvmFormulaFit(fit, resp_names, String[], layout,
                               Matrix{Float64}(Y), Nmat)
    end
end

# ---------------------------------------------------------------------------
# Single-family dispatch (link-aware; threads N only for Binomial).
# Routes to the matrix fitters in src/families/*.jl. `link === nothing` lets each
# fitter pick its canonical default link.
# ---------------------------------------------------------------------------
function _fit_single(family, Y, K, link, Nmat; kwargs...)
    lk = link === nothing ? NamedTuple() : (link = link,)
    if family isa Binomial
        return Nmat === nothing ?
            fit_binomial_gllvm(Y; K = K, lk..., kwargs...) :
            fit_binomial_gllvm(Y; K = K, N = Nmat, lk..., kwargs...)
    elseif family isa Poisson
        return fit_poisson_gllvm(Y; K = K, lk..., kwargs...)
    elseif family isa NegativeBinomial
        return fit_nb_gllvm(Y; K = K, lk..., kwargs...)
    elseif family isa Beta
        return fit_beta_gllvm(Y; K = K, lk..., kwargs...)
    elseif family isa Gamma
        return fit_gamma_gllvm(Y; K = K, lk..., kwargs...)
    elseif family isa Ordinal
        return fit_ordinal_gllvm(Y; K = K, lk..., kwargs...)
    else
        throw(ArgumentError(
            "gllvm: unsupported response family $(nameof(typeof(family)))"))
    end
end

# ---------------------------------------------------------------------------
# Binomial trial counts. WIDE allows `N` as a Vector{Symbol} of trial-count
# columns (one per trait) read from the table, OR a p×n matrix. Non-Binomial
# families ignore `N` (must be nothing). Returns a p×n Int matrix or nothing.
# ---------------------------------------------------------------------------
function _single_binom_N(family, N, p, n)
    N === nothing && return nothing
    family isa Binomial || throw(ArgumentError(
        "`N` (trial counts) is only meaningful for a Binomial family"))
    return _as_N_matrix(N, p, n)
end

function _mixed_binom_N(families, N, p, n)
    N === nothing && return nothing
    any(f -> f isa Binomial, families) || throw(ArgumentError(
        "`N` (trial counts) given but no trait has a Binomial family"))
    return _as_N_matrix(N, p, n)
end

function _as_N_matrix(N::AbstractMatrix, p, n)
    size(N) == (p, n) ||
        throw(DimensionMismatch("N matrix must be $(p)×$(n); got $(size(N))"))
    return Matrix{Int}(N)
end
_as_N_matrix(N, p, n) = throw(ArgumentError(
    "`N` must be a p×n matrix of trial counts (got $(typeof(N)))"))

# ---------------------------------------------------------------------------
# Per-row coercion for a mixed-family fit: each trait row to Int (count families)
# or Float64 (continuous), stored in a shared Float64 matrix (`fit_mixed_gllvm`
# reads each row by its family marker).
# ---------------------------------------------------------------------------
function _coerce_mixed(Yany, families, p, n)
    Y = Matrix{Float64}(undef, p, n)
    @inbounds for t in 1:p
        if _wants_integer(families[t])
            for s in 1:n
                Y[t, s] = float(_to_int(Yany[t, s]))
            end
        else
            for s in 1:n
                Y[t, s] = float(Yany[t, s])
            end
        end
    end
    return Y
end
