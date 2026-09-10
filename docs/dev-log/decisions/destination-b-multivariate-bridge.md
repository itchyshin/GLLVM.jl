# Destination B: multivariate precision bridge contract

**Status:** candidate Julia-only bridge helper. It does not admit the R
`phylo_rr` public route, establish R parity, or qualify any fitting result.

## Frozen precision transport boundary

This helper reuses S3a admission and does not define a second tree or dense
covariance transport. On the R wire, the canonical payload keeps 1-based
sparse triplets, a unique 0-based tip-to-augmented-node map, applied `scale`,
and native **precision** `log_det = log|Q|`; the frozen R covariance
normalizer `log_det_A_phy_rr` has the opposite sign and must be negated before
admission. Inside Julia, both the returned `species_aug_id` and required
observation `species_id` are 1-based. Repeated observation entries are
preserved exactly, while ancestors remain in the admitted `Q` and are
marginalised by the fitter. This metadata receipt is transport evidence only:
the R public `phylo_rr` model remains closed pending paired model tests.

## Contract

`_bridge_fit_precision_multivariate(y, phylo; family, d, X=nothing,
options=Dict())` consumes either an admitted `PrecisionPhy` or the existing
flat precision payload. `y` is traits by observations and `d` is the
reduced-rank phylogenetic loading rank. The only family is Gaussian; aliases
normal/gaussian normalize to `"gaussian"`. The bridge requires an explicit,
1-based observation-to-tip `species_id` option so repeated observations are
never silently remapped.

Accepted options are `species_id`, `mode` (`barelowrank` or
`explicitunique`), `start`, `g_tol`, `iterations`, `ci_method` (`none` or
`wald`), and `ci_level`. The parent dispatcher may also pass
`phylo_model="multivariate"`; this marker is validated, not silently
ignored. Every other option and every unsupported family or interval method
is rejected rather than ignored. `X` is passed to the complete trait-major
mean-design route of the native fitter.

The return is a flat JuliaCall-safe NamedTuple: mean coefficients, loading,
phylogenetic unique and covariance terms, residual variance/covariance,
objective/convergence/curvature diagnostics, exact observation/tip/node maps,
and precision scale/log-determinant metadata. Wald output uses parallel flat
target arrays and status strings; `ci_method="none"` returns empty arrays and
`ci_status="not_requested"`.

## Gates

Tests construct one fixed-start Gaussian fixture and require native and
payload-admitted bridge routes to preserve the full packed coordinates and
metadata exactly. They cover explicit repeated maps, complete mean design,
flat Wald unavailable arrays, family/mode/map/shape/interval/unknown-option
rejections. No R adapter, export, public `bridge_fit` dispatch, profile
interval, recovery, coverage, or parity claim follows from this helper.
