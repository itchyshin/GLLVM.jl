# Tidy inference / summary table — the first thing a user looks at after a fit.
#
# `coef_table(fit, Y; level, kwargs...)` is a thin presentation layer over the
# unified Wald entry point (`confint(fit, Y; method=:wald, …)` from
# confint_family.jl). It augments the Wald NamedTuple (term / estimate / se /
# lower / upper) with the two standard regression-table columns — the Wald z
# statistic `z = estimate / se` and its two-sided normal p-value
# `2·(1 − Φ(|z|))` — and packs everything into a `GllvmCoefTable` with a
# pretty `show`. All extra keyword arguments (`X`, `parm`, `N`, …) flow straight
# through to `confint`, so subsetting and covariate/Binomial designs work
# unchanged.

using Distributions: Normal, cdf
using Printf: @sprintf

"""
    GllvmCoefTable

Tidy coefficient table for a non-Gaussian family GLLVM fit, as produced by
[`coef_table`](@ref). One row per parameter, with the columns a regression
summary conventionally reports:

  - `term::Vector{String}`       — parameter name (`beta[t]`, `Lambda[i,k]`, a
                                    dispersion `r`/`phi`/`alpha`, …)
  - `estimate::Vector{Float64}`  — MLE on its natural (reported) scale
  - `std_error::Vector{Float64}` — Wald standard error (`NaN` if the
                                    observed-information Hessian was not
                                    invertible for that term)
  - `z::Vector{Float64}`         — Wald statistic `estimate / std_error`
  - `pvalue::Vector{Float64}`    — two-sided normal p-value `2·(1 − Φ(|z|))`
  - `lower::Vector{Float64}`,
    `upper::Vector{Float64}`     — Wald confidence-interval bounds

All vectors share the same length and ordering.
"""
struct GllvmCoefTable
    term::Vector{String}
    estimate::Vector{Float64}
    std_error::Vector{Float64}
    z::Vector{Float64}
    pvalue::Vector{Float64}
    lower::Vector{Float64}
    upper::Vector{Float64}
end

"""
    coef_table(fit, Y; level = 0.95, kwargs...) -> GllvmCoefTable

Tidy inference table for a non-Gaussian family GLLVM fit — the headline summary
of a fitted model. Internally calls `confint(fit, Y; method = :wald,
level = level, kwargs...)` (see [`confint`](@ref)) for the estimates, standard
errors, and confidence bounds, then adds the two standard regression columns:

  - the Wald statistic `z = estimate / std_error`, and
  - the two-sided normal p-value `pvalue = 2·(1 − Φ(|z|))`.

Where a standard error is `NaN` or non-finite (the observed-information Hessian
was not invertible for that term) the corresponding `z` and `pvalue` are `NaN`.

Any extra keyword arguments are forwarded verbatim to `confint`, so the usual
selectors and designs apply, e.g. `parm = "beta"` to subset terms, `X = X` for a
[`fit_gllvm_cov`](@ref) covariate fit, or `N = N` for Binomial trial counts.

```julia
fit = fit_poisson_gllvm(Y; K = 2)
coef_table(fit, Y)
coef_table(fit, Y; parm = "beta", level = 0.90)
```
"""
function coef_table(fit, Y::AbstractMatrix; level::Real = 0.95, kwargs...)
    return _coef_table_from_ci(confint(fit, Y; method = :wald, level = level, kwargs...))
end

"""
    coef_table(fit::SPDELatentFit, Y, locs; level=0.95, kwargs...) -> GllvmCoefTable

Tidy Wald inference table for the SPDE-latent model. It needs the observation `locs`
(to rebuild the projector), so it routes through [`confint_spde_latent`](@ref); β and Λ
are on the natural scale, κ/τ/dispersion on the positive scale.
"""
function coef_table(fit::SPDELatentFit, Y::AbstractMatrix, locs::AbstractMatrix;
                    level::Real = 0.95, kwargs...)
    return _coef_table_from_ci(confint_spde_latent(fit, Y, locs; level = level, kwargs...))
end

# Build the tidy estimate/SE/z/p/CI table from a Wald-CI NamedTuple.
function _coef_table_from_ci(ci)
    est = collect(Float64, ci.estimate)
    se  = collect(Float64, ci.se)
    m   = length(est)
    z   = Vector{Float64}(undef, m)
    pv  = Vector{Float64}(undef, m)
    nd  = Normal()
    @inbounds for i in 1:m
        if isfinite(se[i]) && se[i] > 0
            zi = est[i] / se[i]
            z[i]  = zi
            pv[i] = 2 * (1 - cdf(nd, abs(zi)))
        else
            z[i]  = NaN
            pv[i] = NaN
        end
    end
    return GllvmCoefTable(collect(String, ci.term), est, se, z, pv,
                          collect(Float64, ci.lower), collect(Float64, ci.upper))
end

# Compact field formatter: fixed 4 significant digits, "NaN" passed through.
_ct_num(x::Real) = isfinite(x) ? @sprintf("%.4g", x) : "NaN"
# p-values get a small-value floor so they don't print as a bare "0".
_ct_pval(x::Real) = !isfinite(x) ? "NaN" : (x < 1e-4 ? "<1e-4" : @sprintf("%.4f", x))

function Base.show(io::IO, ::MIME"text/plain", ct::GllvmCoefTable)
    m = length(ct.term)
    println(io, "GllvmCoefTable (", m, m == 1 ? " term)" : " terms)")
    headers = ["term", "estimate", "std.error", "z", "p", "lower", "upper"]
    cols = Vector{Vector{String}}(undef, 7)
    cols[1] = copy(ct.term)
    cols[2] = _ct_num.(ct.estimate)
    cols[3] = _ct_num.(ct.std_error)
    cols[4] = _ct_num.(ct.z)
    cols[5] = _ct_pval.(ct.pvalue)
    cols[6] = _ct_num.(ct.lower)
    cols[7] = _ct_num.(ct.upper)
    # Column widths: max of header and cell content.
    widths = [maximum(length, vcat(headers[c], cols[c]); init = length(headers[c]))
              for c in 1:7]
    # Header row (term left-aligned, numeric columns right-aligned).
    print(io, "  ", rpad(headers[1], widths[1]))
    for c in 2:7
        print(io, "  ", lpad(headers[c], widths[c]))
    end
    println(io)
    for r in 1:m
        print(io, "  ", rpad(cols[1][r], widths[1]))
        for c in 2:7
            print(io, "  ", lpad(cols[c][r], widths[c]))
        end
        r < m && println(io)
    end
end
