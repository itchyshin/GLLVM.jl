# Boundary inference for variance components at the boundary of the parameter space
# (a variance → 0, on the edge of [0, ∞)). Adapted from the DRM-team toolkit
# (cross-pollination) — the honest answer to "is this RE / latent-factor variance 0?",
# where a naive χ²_q reference LRT is conservative because the parameter sits on the
# boundary. Self & Liang (1987) / Stram & Lee (1994): the null LRT follows a χ̄²
# MIXTURE of χ² distributions, not a single χ²_q.
#
# Use cases in GLLVM.jl: K-selection / over-factoring ("is the K-th latent factor real?"),
# and the RE variances (σ_row, the grouped/structured σ_u, the random-slope Σ_b diagonals,
# the Poisson OLRE ψ_t) — all are variances tested against 0. Methods-sharing with DRM
# (MIT/GPL clean).

"""
    chibar2_pvalue(LRT, q) -> Float64

p-value of a likelihood-ratio statistic `LRT = 2(ℓ_full − ℓ_reduced)` for the boundary
null that `q` INDEPENDENT variance components are simultaneously 0. The reference is the
χ̄² mixture `Σ_{j=0}^{q} C(q,j) 2^{-q} χ²_j` (Self–Liang case for q independent variances
on the boundary), so

    p = Σ_{j=1}^{q} C(q,j) 2^{-q} · P(χ²_j ≥ LRT)          (the j=0 atom contributes 0 for LRT>0).

For `q = 1` this is the familiar `½ P(χ²_1 ≥ LRT)` (half the naive χ²_1 p-value). Returns
1.0 for `LRT ≤ 0` (no evidence). NOTE: the independent-variances mixture; a variance that
is also correlated with others (a ρ → ±1 boundary) needs the cone-geometry weights — a
documented follow-on.
"""
function chibar2_pvalue(LRT::Real, q::Integer)
    q ≥ 1 || throw(ArgumentError("q (number of boundary variances) must be ≥ 1; got $q"))
    LRT > 0 || return 1.0
    p = 0.0
    @inbounds for j in 1:q
        p += binomial(q, j) * 2.0^(-q) * ccdf(Chisq(j), float(LRT))
    end
    return p
end

"""
    variance_lrt(ℓ_full, ℓ_reduced; n_boundary=1) -> NamedTuple

Boundary likelihood-ratio test that `n_boundary` variance components are 0, from the two
maximised log-likelihoods (full model vs the reduced model with those variances fixed at
0). Returns `(LRT, pvalue, n_boundary)` with the χ̄² mixture p-value
([`chibar2_pvalue`](@ref)). The naive `2·ΔlogLik ~ χ²` p-value would OVER-state the
evidence's conservatism (be too large) — the boundary correction halves (q=1) it.
"""
function variance_lrt(ℓ_full::Real, ℓ_reduced::Real; n_boundary::Integer = 1)
    LRT = 2 * (float(ℓ_full) - float(ℓ_reduced))
    return (LRT = LRT, pvalue = chibar2_pvalue(LRT, n_boundary), n_boundary = n_boundary)
end
