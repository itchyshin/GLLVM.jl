# Covariance and modifier contract from frozen R 0.7.0

Status: **source grammar subset verified; full model contract incomplete**.
Reference: `b4d5fee64def88bc768dda1f1f77c29b295edd86`. The 95 cases in
`covariance-admission-subset.json` replay actual source rewrite/parser/helper
functions, not the documentation-only marker constructors. Local R 4.6.0 and
Totoro R 4.5.3 process exits and matching raw results are recorded in
`covariance-admission-evidence.json`. They are not 95 fitted models.

## Semantics that B1 and B2 must share

Write between-group covariance as `C_source ⊗ V_trait`, preserving ordering.
For admitted intercept models, diagonal `V_trait`, full unstructured `V_trait`,
and `Lambda*Lambda'` (with optional diagonal Psi) are different contracts.
A scalar field shared across traits is also distinct from equal independent
trait variances; do not collapse them because both use one variance parameter.
Source matrices, level names, loading identification and residual distributions
must be frozen before comparing likelihoods or fitted predictions.

| Surface | Source-stage result | Remaining model obligation |
|---|---|---|
| Ordinary `latent()` | Default adds a diagonal Psi companion; `unique=FALSE` is loadings-only. `common=TRUE` ties the companion. | Family-specific automatic-Psi mapping, two-level/cluster behavior, loading masks and identifiability. |
| `indep()` | Separate trait variances; `common=TRUE` carries a common flag. | Confirm actual variance maps and covariance, not just flag propagation. |
| `dep()` | Full rank is deferred to trait count and marked dependent. | Full-rank loading/Cholesky convention, constants and supported intervals. |
| Phylogenetic/animal latent | Default is loadings-only; `unique=TRUE` creates a source-structured companion. | Tree/A/Ainv/pedigree alignment, precision normalization and singular/invalid inputs. |
| Phylogenetic/animal indep/dep | Require bar formulas. Animal inputs are validated before bar shape. | All mode-specific model and postfit evidence, with formula/native/bridge separated. |
| Named kernel latent | Default loadings-only; one source can add Psi. | Single versus multiple names and matrix validation are separate fit-stage cases. |
| Spatial latent | Default loadings-only; unique sets a spatial-diagonal flag. | SPDE mesh/projection, range/precision parameterization and fit-level admission. |
| Ordinary augmented slopes | Carries augmented loading and optional unique metadata. | Source/family intersections, coefficient-row ordering and random-regression covariance. |
| Source-specific `lv=` | Rejected rather than silently ignored. | Preserve rejected-domain tests; ordinary predictor-informed latent models remain required separately. |
| Known covariance | `meta_V` and legacy `meta_known_V` rewrite identically. | Actual known-covariance likelihood, alignment, matrix shapes and `block_V` values. |

The helper's augmented-slope family table is enumerated for 17 family IDs by
three link IDs. It admits its declared 11 families at link0 plus binomial link1;
this **does not establish every source/slope model**. Three entries explicitly
have partial evidence in the frozen R source. We retain those as required
admission review and numerical debt, not automatic exclusions.

## Fit-stage rules not yet exercised

In frozen `R/fit-multi.R:1121`, multiple named latent kernels cause automatically
created unique companions to be removed. At lines3626–3638, each name must have
exactly one latent term and explicit diagonal companions are rejected. Nearby
kernel documentation describes unique as unavailable, but does not fully explain
this automatic removal. Required tests must distinguish the two inputs and
record actual fitted covariance. Do not infer rejection from the documentation
or silently implement the pruned model as the requested model without provenance.

The multinomial checks at `R/fit-multi.R:4890–4930` further restrict combinations.
Source mode support is broader than fixed-effect softmax, while scalar, multiple
kernel names, augmented slopes and source-specific Psi remain fenced. Ordinary
auto-Psi can be mapped off for categorical contrasts. These are fit-level rules;
none is proved by passing the 95 grammar/helper cases.

## Julia mapping boundary

Current `src/formula.jl` exposes fixed-effect StatsModels terms with site-level
predictors and matrix responses; it does not implement the covariance markers
exercised here. That missing formula layer must be implemented in B2 using a
reviewed native covariance representation from B1. `src/structured_cov.jl`
builds dense covariance matrices for a Gaussian `Sigma_phy` input; that alone
is not proof of ordinary/source mode, SPDE, or named multi-kernel equivalence.
The separate `src/bridge.jl` routes need their own payload and fit receipts.
Existing native numerical functions are leads for reuse, not blanket PASS rows.

## Next required work

1. Exercise fit-input construction, including source/trait dimensions, masks,
   family-specific Psi admission, source matrices and multinomial exclusions.
2. Freeze numerical fixtures and R/Julia calls for the actual admitted models.
   Keep every missing Julia route visible and owned by B1/B2/B3/B4/B5.
3. Add slope/common/scalar, loading-mask, known-covariance, data and postfit
   cross-products. The present subset is not an exhaustive covariance manifest.
4. Revalidate affected evidence on the final integrated revision. The full
   `frozen-r070-contract.toml` remains DRAFT and must not accept a subset result.
