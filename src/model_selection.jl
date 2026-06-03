# Latent-dimension selection — a practical workflow tool.
#
# Fits the same GLLVM at a sweep of latent dimensions K = 1:Kmax via the
# unified `fit_gllvm` dispatcher, records the information criteria (using the
# same `_nparams`/`_loglik` path that `aic`/`bic` use), and picks the K that
# minimises the chosen criterion. Each fit is guarded so a single failing K
# (non-convergence, numerical blow-up) skips rather than aborts the sweep.

"""
    LVSelection

Result of a latent-dimension sweep (see [`select_lv`](@ref)). Vectors are
aligned by position: entry `i` describes the successfully fitted `K[i]`.

Fields:
- `K::Vector{Int}` — the latent dimensions that fitted successfully.
- `nparams::Vector{Int}` — free-parameter count per fit (the same `_nparams`
  path `aic`/`bic` use; loadings counted modulo the `K(K−1)/2` rotational df).
- `loglik::Vector{Float64}` — maximised marginal log-likelihood per fit.
- `aic::Vector{Float64}` — Akaike information criterion per fit.
- `bic::Vector{Float64}` — Bayesian information criterion per fit.
- `best_k::Int` — the `K` minimising the chosen criterion.
- `best::Any` — the chosen fitted model (the one at `best_k`).
"""
struct LVSelection
    K::Vector{Int}
    nparams::Vector{Int}
    loglik::Vector{Float64}
    aic::Vector{Float64}
    bic::Vector{Float64}
    best_k::Int
    best::Any
end

"""
    select_lv(Y; family = Normal(), Kmax = 3, criterion = :bic, kwargs...) -> LVSelection

Latent-dimension selection: fit `fit_gllvm(Y; family, K = k, kwargs...)` for
`k in 1:Kmax` and pick the `K` minimising `criterion` (`:aic` or `:bic`).

Each fit is wrapped in a `try`/`catch` so one bad `K` (non-convergence,
singular intermediate) is skipped rather than aborting the whole sweep; at
least one `K` must succeed or an error is thrown. The information criteria are
read straight off the fits via [`aic`](@ref) and [`bic`](@ref) (BIC uses
`size(Y, 2)` as the number of sites), so the parameter counting matches the
single-fit accessors exactly.

`family` is a Distributions.jl marker (the [`fit_gllvm`](@ref) convention);
`kwargs...` pass through to the underlying fitter.

```julia
sel = select_lv(Y; family = Poisson(), Kmax = 3)   # pick K by BIC
sel.best_k          # selected latent dimension
sel.best            # the fitted model at that K
```
"""
function select_lv(Y::AbstractMatrix; family = Normal(), Kmax::Integer = 3,
                   criterion::Symbol = :bic, kwargs...)
    criterion in (:aic, :bic) ||
        throw(ArgumentError("criterion must be :aic or :bic; got :$criterion"))
    Kmax >= 1 || throw(ArgumentError("Kmax must be ≥ 1; got $Kmax"))
    n = size(Y, 2)

    Ks       = Int[]
    nps      = Int[]
    lls      = Float64[]
    aics     = Float64[]
    bics     = Float64[]
    fits     = Any[]

    for k in 1:Kmax
        try
            fit = fit_gllvm(Y; family = family, K = k, kwargs...)
            push!(Ks, k)
            push!(nps, _nparams(fit))
            push!(lls, _loglik(fit))
            push!(aics, aic(fit))
            push!(bics, bic(fit, n))
            push!(fits, fit)
        catch
            # Skip this K — a single failing fit must not abort the sweep.
            continue
        end
    end

    isempty(Ks) && error("select_lv: every K in 1:$Kmax failed to fit")

    crit = criterion === :aic ? aics : bics
    ibest = argmin(crit)

    return LVSelection(Ks, nps, lls, aics, bics, Ks[ibest], fits[ibest])
end

# Tidy table display, best row marked with '*'.
function Base.show(io::IO, ::MIME"text/plain", sel::LVSelection)
    println(io, "GLLVM latent-dimension selection (best K = ", sel.best_k, ")")
    println(io, "      K   nparams        logLik           AIC           BIC")
    for i in eachindex(sel.K)
        mark = sel.K[i] == sel.best_k ? "*" : " "
        println(io, mark, " ",
                lpad(string(sel.K[i]), 5), "   ",
                lpad(string(sel.nparams[i]), 7), "   ",
                lpad(string(round(sel.loglik[i]; sigdigits = 7)), 11), "   ",
                lpad(string(round(sel.aic[i]; sigdigits = 7)), 11), "   ",
                lpad(string(round(sel.bic[i]; sigdigits = 7)), 11))
    end
end

Base.show(io::IO, sel::LVSelection) =
    print(io, "LVSelection(K=", sel.K, ", best_k=", sel.best_k, ")")
