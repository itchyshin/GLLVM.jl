# Final missing-surface cluster (core070 §1) — small post-fit tables and
# helpers that did not have a natural home in postfit.jl / extractors.jl.
# Each function documents the R contract it mirrors (file:line in the frozen
# oracle readback) and any deliberate scope reduction.
#
# Item 1.1 — deviance (mirrors methods-gllvmTMB.R:2862-2864).

"""
    deviance(fit) -> Float64

`-2 * loglikelihood(fit)`. Mirrors `gllvmTMB`'s `deviance.gllvmTMB_multi`
(`methods-gllvmTMB.R:2862-2864`), which is exactly `-2 * logLik(object)` — no
null/saturated-model comparison, delegating through the same maximised
marginal log-likelihood that a ridged fit reports (R's "unpenalised logLik at
penalised MAP" caveat is inherited unchanged here).

Deliberately does not touch [`nobs`](@ref) or [`bic`](@ref) — the R/Julia
`nobs` convention mismatch (site count vs likelihood-contributing cells) is a
separate maintainer decision (core070 spec §3.1).
"""
StatsAPI.deviance(fit::AnyGllvmFit) = -2 * StatsAPI.loglikelihood(fit)

# ---------------------------------------------------------------------------
# Item 1.2 — profile_cross_rho_ci (mirrors kernel-helpers.R:294-359; the
# post-verification correction narrows the citation range — :361-372 are
# unrelated cross-kernel helpers).
# ---------------------------------------------------------------------------

# Linear-interpolation crossing of the line through (x1,y1)-(x2,y2) at y=threshold.
function _cross_rho_interp(x1::Real, y1::Real, x2::Real, y2::Real, threshold::Real)
    return x1 + (threshold - y1) * (x2 - x1) / (y2 - y1)
end

# Walk the (sorted-by-rho) grid away from `best_i` in direction `dir` (:down
# decreasing index / :up increasing index) looking for the first point whose
# delta_deviance crosses `threshold`. Returns (bound, bounded::Bool).
function _cross_rho_bracket(r::AbstractVector, dd::AbstractVector, best_i::Integer,
                            threshold::Real, dir::Symbol)
    n = length(r)
    if dir === :down
        j = best_i - 1
        while j >= 1
            if dd[j] >= threshold
                return _cross_rho_interp(r[j], dd[j], r[j + 1], dd[j + 1], threshold), true
            end
            j -= 1
        end
        return r[1], false
    else
        j = best_i + 1
        while j <= n
            if dd[j] >= threshold
                return _cross_rho_interp(r[j - 1], dd[j - 1], r[j], dd[j], threshold), true
            end
            j += 1
        end
        return r[n], false
    end
end

"""
    profile_cross_rho_ci(rho, delta_deviance; level = 0.95) -> NamedTuple

Confidence interval for the cross-lineage coevolution kernel parameter `rho`
by inverting a `delta_deviance` profile TABLE (as produced by
[`profile_cross_rho`](@ref)) — pure post-processing, no refitting. Mirrors
`gllvmTMB::profile_cross_rho_ci` (`kernel-helpers.R:294-359`).

`rho` and `delta_deviance` are equal-length vectors; non-finite pairs are
dropped, and at least 2 finite points must remain. `level ∈ (0, 1)`. The
threshold is `quantile(Chisq(1), level)` (the standard 1-df LRT cutoff). The
best (`estimate`) point is the grid value with the smallest `delta_deviance`.
Bounds are found by walking outward from the best point and LINEARLY
INTERPOLATING between the two grid points that bracket the threshold
crossing (not a quadratic/bisection refit — this is grid interpolation on an
already-computed table). A side that never crosses the threshold within the
grid returns that side's grid edge with the corresponding `*_bounded = false`
flag. Bounds are clamped to `[-1, 1]` (rho's admissible range).

Returns `(estimate, lower, upper, level, lower_bounded, upper_bounded,
threshold)`.
"""
function profile_cross_rho_ci(rho::AbstractVector{<:Real}, delta_deviance::AbstractVector{<:Real};
                              level::Real = 0.95)
    length(rho) == length(delta_deviance) ||
        throw(ArgumentError("rho and delta_deviance must have equal length."))
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))

    keep = findall(i -> isfinite(rho[i]) && isfinite(delta_deviance[i]), eachindex(rho))
    length(keep) >= 2 ||
        throw(ArgumentError("profile_cross_rho_ci needs >= 2 finite (rho, delta_deviance) points; got $(length(keep))."))

    perm = sortperm(rho[keep])
    r = Float64.(rho[keep][perm])
    dd = Float64.(delta_deviance[keep][perm])

    threshold = quantile(Chisq(1), level)
    best_i = argmin(dd)
    estimate = r[best_i]

    lower, lower_bounded = _cross_rho_bracket(r, dd, best_i, threshold, :down)
    upper, upper_bounded = _cross_rho_bracket(r, dd, best_i, threshold, :up)
    lower = clamp(lower, -1.0, 1.0)
    upper = clamp(upper, -1.0, 1.0)

    return (estimate = estimate, lower = lower, upper = upper, level = level,
            lower_bounded = lower_bounded, upper_bounded = upper_bounded,
            threshold = threshold)
end

# ---------------------------------------------------------------------------
# Item 1.3 — predict_cross_covariance, positional form (mirrors
# extract-sigma.R:1837-1957; kernel from `.kernel_level_matrix`, :1961-2005).
# ---------------------------------------------------------------------------

"""
    predict_cross_covariance(fit, K; row_levels, col_levels, row_traits, col_traits)
        -> NamedTuple of vectors

Cross-lineage predicted covariance table `covariance = kernel_value * gamma_shape`
for every combination of `(row_level, col_level, row_trait, col_trait)`, one row
per combination (nested loop order: `row_levels` outer, `col_levels`, `row_traits`,
`col_traits` inner). Mirrors `gllvmTMB::predict_cross_covariance`
(`extract-sigma.R:1837-1957`), point estimates only.

`K` is the `n × n` cross-lineage kernel (e.g. from [`make_cross_kernel`](@ref));
`row_levels`/`col_levels` are 1-based integer indices into `K`. `gamma_shape`
is `Γ = (Λ_phy Λ_phyᵀ)[row_traits, col_traits]` via [`extract_Gamma`](@ref)
(already on R's "shape" scale) — `row_traits`/`col_traits` are 1-based integer
indices into the stacked two-lineage entity set that `fit` was fitted on.

Returns a `NamedTuple` of equal-length vectors with fields
`row_level, col_level, row_trait, col_trait, kernel_value, gamma_shape,
covariance` — the positional analogue of R's table (R's `rho` /
`kernel_includes_rho` metadata columns are deferred to the `CrossKernel`
metadata wrapper, core070 spec §2.6, since GLLVM.jl's kernel is presently an
unnamed matrix with no stored `rho`).

Throws `ArgumentError` if any level index falls outside `axes(K)` (mirroring
R's abort at `extract-sigma.R:1885-1908`).
"""
function predict_cross_covariance(fit::GllvmFit, K::AbstractMatrix;
                                  row_levels::AbstractVector{<:Integer},
                                  col_levels::AbstractVector{<:Integer},
                                  row_traits::AbstractVector{<:Integer},
                                  col_traits::AbstractVector{<:Integer})
    nK1, nK2 = size(K)
    all(l -> 1 <= l <= nK1, row_levels) ||
        throw(ArgumentError("row_levels must index 1:$nK1 (rows of K)."))
    all(l -> 1 <= l <= nK2, col_levels) ||
        throw(ArgumentError("col_levels must index 1:$nK2 (columns of K)."))

    Γ = extract_Gamma(fit; row_traits = row_traits, col_traits = col_traits)

    n = length(row_levels) * length(col_levels) * length(row_traits) * length(col_traits)
    row_level = Vector{Int}(undef, n)
    col_level = Vector{Int}(undef, n)
    row_trait = Vector{Int}(undef, n)
    col_trait = Vector{Int}(undef, n)
    kernel_value = Vector{Float64}(undef, n)
    gamma_shape = Vector{Float64}(undef, n)
    covariance = Vector{Float64}(undef, n)

    idx = 0
    for rl in row_levels, cl in col_levels, (ti, rt) in enumerate(row_traits), (tj, ct) in enumerate(col_traits)
        idx += 1
        kv = Float64(K[rl, cl])
        gs = Γ[ti, tj]
        row_level[idx] = rl
        col_level[idx] = cl
        row_trait[idx] = rt
        col_trait[idx] = ct
        kernel_value[idx] = kv
        gamma_shape[idx] = gs
        covariance[idx] = kv * gs
    end

    return (row_level = row_level, col_level = col_level,
            row_trait = row_trait, col_trait = col_trait,
            kernel_value = kernel_value, gamma_shape = gamma_shape,
            covariance = covariance)
end
