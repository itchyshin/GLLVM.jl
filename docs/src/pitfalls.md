# Common pitfalls

A short guide to the things that most often trip people up when fitting GLLVMs.

## Latent factors are identified only up to rotation and sign

The loadings `Λ` and the factor scores are not unique: any rotation
`Λ → Λ R` (with `R` orthogonal) gives the same fit. So **do not compare raw
`Λ` across fits or against a known truth** — compare rotation-invariant
quantities instead:

- the model-implied covariance `Σ_y = Λ Λᵀ + Ψ` (`sigma_y_site`),
- per-response communalities (`communality`),
- cross-response correlations (`correlation`).

For a fixed, interpretable orientation, rotate the loadings (e.g. varimax)
*after* fitting.

## Choose the number of factors `K` deliberately

Too few factors miss real structure; too many invite over-fitting and weak
identifiability. Compare a few values of `K` by log-likelihood / information
criteria, and prefer the smallest `K` that captures the covariance you care
about.

## Check convergence

`fit_gaussian_gllvm` warm-starts from PPCA and usually converges in a step or
two; the non-Gaussian fitters use L-BFGS over a Laplace marginal. Always check
the `converged` flag — if it is `false`, try a different start or more
iterations. Standardising responses to a common scale helps the Gaussian path.

## Use the O(p) path for large phylogenies

The dense Gaussian fit with a phylogenetic covariance is `O(p³)` and assumes
`n ≥ p`. For many species, use the O(p) phylogenetic fitter
[`fit_phylo_gaussian`](@ref), which scales linearly (≈ 0.8 ms per gradient at
p = 10,000) by never forming the dense `p×p` covariance.

## Binary data: watch for separation

With binary responses, a response that is all-0 or all-1 drives its intercept
to ±∞ (complete separation). `fit_binomial_gllvm` clamps the linear predictor
for numerical safety, but a non-convergence flag or an extreme intercept is a
sign to inspect that response.

See also: [Get started](quickstart.md) · [Response families](response-families.md) · [Reference](api.md).
