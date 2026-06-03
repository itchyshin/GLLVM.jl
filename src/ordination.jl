# Ordination output — the headline ecology-facing summary of a fitted GLLVM.
#
# An ordination places SITES (samples/rows) and SPECIES (responses/columns) in a
# shared low-dimensional latent space. The two coordinate sets are:
#   * sites   = conditional latent-variable scores (see `getLV`) — the ordination
#               point cloud, one row per site;
#   * species = the fitted loadings Λ (or Λc for the two-part families) — the
#               "arrows" / response directions, one row per species.
#
# Loadings/scores are identified only up to a K×K orthogonal rotation: the linear
# predictor contribution S·Lᵀ (and hence Σ_y) is invariant under (S,L) → (S·R, L·R)
# for any R with RᵀR = I, since (S·R)(L·R)ᵀ = S·R·Rᵀ·Lᵀ = S·Lᵀ. We therefore fix a
# canonical PRINCIPAL orientation: R = V from the SVD of the centered site scores,
# so the rotated site axes are ordered by decreasing spread (principal axes first).

# Loadings accessor — Λ for the single-part families, Λc for the two-part
# (Delta-/Hurdle-/zero-inflated) families that store loadings on the positive part.
_loadings(fit) = hasproperty(fit, :Λ) ? fit.Λ : fit.Λc

"""
    ordination(fit, Y; rotate=true) -> (sites, species, rotation)

Ordination of a fitted GLLVM: site and species coordinates in the shared `K`-
dimensional latent space, returned as a `NamedTuple` `(sites, species, rotation)`.

- `sites`    — `n×K` matrix of latent SITE scores (ordination point cloud), the
               conditional latent-variable scores `getLV(fit, Y; rotate=false)`.
- `species`  — `p×K` matrix of SPECIES loadings (the ordination "arrows" / response
               directions), the fitted `Λ` (or `Λc` for the two-part families).
- `rotation` — the `K×K` orthogonal matrix `R` applied to both sets.

With `rotate=true` (default) a canonical PRINCIPAL rotation is applied: `R = V`, the
right singular vectors of the centered site scores `Sc = S .- mean(S; dims=1)`, so
the returned `sites = S*R` are ordered by decreasing spread (principal axes first)
and `species = L*R`. With `rotate=false`, `R = I` and the raw `sites`/`species` are
returned unrotated.

The rotation is orthogonal, so the fit is preserved exactly: the linear-predictor
contribution `sites * species' == S * L'` for any `R` with `R'R = I`.

`Y` (the `p×n` response matrix) must match what was passed to the fitting call — the
fit does not store the data.
"""
function ordination(fit, Y; rotate::Bool = true)
    S = getLV(fit, Y; rotate = false)      # n×K site scores
    L = _loadings(fit)                      # p×K species loadings
    K = size(L, 2)
    if !rotate
        return (sites = S, species = L, rotation = Matrix{Float64}(I, K, K))
    end
    Sc = S .- mean(S; dims = 1)
    R = Matrix(svd(Sc).V)                   # K×K right singular vectors (principal axes)
    return (sites = S * R, species = L * R, rotation = R)
end
