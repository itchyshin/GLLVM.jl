# Frozen R prepared-input contract

The public frozen R path was executed up to (but not into) `TMB::MakeADFun`.
A tracer in a disposable R process captured data, parameters, maps and random
blocks, then raised a typed stop condition. The original source and installed
package files were unchanged; the installed tree, marker and build log were
verified before and after. This is **prepared-input evidence, not fitted parity**.

The source-pinned fixture declares14 cases. After correcting one case-sensitive
diagnostic match, all14 expectations pass:11 prepared and3 rejected before tape.
The prior13/14 result is retained. A wrong-DLL tracer request is rejected, and
a deliberately false expected predicate produces process exit1. Retained
artifact verification rejects omitted cases, stale source, corrupt receipts and
an unsuccessful required process even when its receipt hash is refreshed.

## Observed models in the deterministic fixtures

Numeric fixtures have18 sites,3 traits and6 source groups, with one observation
per site-trait. The nominal fixture has18 sites and3 categories, expanded by R
to2 baseline-contrast pseudo-traits. A and B are named6-by-6 positive-definite
source matrices. Fixture construction and calls are retained in
`test/parity/fixtures/core070_fit_input.R`; all captured bytes have readback hashes.

| Input | Actual prepared model information |
|---|---|
| Gaussian ordinary default latent | `z_B,s_B`;3 free diagonal coordinates; separate Gaussian residual scale mapped fixed near zero. |
| Gaussian ordinary loadings only | `z_B`;no free diagonal coordinates;1 free Gaussian residual scale. |
| Gaussian ordinary common unique | `z_B,s_B`;1 free diagonal coordinate;separate residual scale fixed. |
| Poisson ordinary default latent | `z_B,s_B`;3 free diagonal coordinates. |
| Binomial ordinary default latent | `z_B`;all3 diagonal coordinates suppressed and mapped fixed. |
| Gaussian animal latent / single kernel | `g_phy`;one source factor;separate Gaussian residual scale free. |
| Two named Gaussian latent kernels | `g_kernel`;2 source tiers;no kernel diagonal component. |
| Two named kernels with automatic unique | Entire captured input object identical to the preceding loadings-only call. |
| Two named kernels with explicit unique | Rejected before tape with latent-only diagnostic. |
| Ordinary multinomial latent | `z_B`;2 contrast pseudo-traits;automatic diagonal coordinates suppressed. |
| Animal multinomial latent | `g_phy`;2 contrast pseudo-traits. |
| Animal multinomial latent with unique | Rejected with the specific multinomial structured-admission condition. |
| Multiple multinomial kernels | Rejected with that same condition and the multi-kernel diagnostic. |

The fixed Gaussian scale is a consequence of this observation-level fixture;
do not generalize it to replicated designs. Capturing a map does not establish
its likelihood constants, numerical conditioning, fitted covariance, convergence
or inference. The fixtures deliberately have simple deterministic responses;
separate known-generating-process fixtures are required for recovery.

## Implementation consequences

- B1 must match the actual residual and unique-variance maps. A default latent
  model cannot be compared against a loadings-only model just because both use
  one factor. The data grouping and residual fixed value belong in the contract.
- B3 must implement the admitted latent/structured nominal models, including
  reference-category and pseudo-trait ordering. Fixed-effect softmax is not a
  substitute. Source-Psi and multi-kernel rejection remain explicit.
- B2 and B5 must expose equivalent models through the formula and R bridge
  interfaces, with provenance for unsupported/pruned requests.
- Eleven numerical model candidates now have stable IDs and exact R calls in
  `fit-input-subset.json`. Julia calls and numerical acceptance tolerances remain
  UNRESOLVED/UNPAID; this is not the completed frozen numerical manifest.
- Next broaden prepared-input coverage to source/mode matrices, slopes, masks,
  known covariance, data and postfit; then freeze exact paired numerical fixtures.

No objective was constructed or optimized by these captured calls. The source
prefix can perform ordinary design/start-value calculations; this diagnostic
does not assert that every internal calculation is absent. The capture boundary
also precedes later AGHQ adaptation and postfit checks, which remain unpaid.

## Source data-control extension

[The data-control contract](data-controls-contract.md) adds56 exact source-helper
cases for weights ordering/masks, missing controls and offsets. Matrix and traits()
paths use different stacking orders; the adapter must retain unit/trait alignment.
These source controls do not extend the11 prepared numerical model candidates into
fitted parity, and no new installed-package or Julia interface proof is implied.
