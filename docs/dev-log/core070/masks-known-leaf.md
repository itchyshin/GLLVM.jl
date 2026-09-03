# Loading-mask and known-covariance reference contracts

OWNS: new masks-known fixture, point runner, verifier/tests, developer records;
parent also owns central source census/mapping and shared checkpoint/check-log.
No production source or foreign checkout edits. R source remains immutable at
b4d5fee64def88bc768dda1f1f77c29b295edd86. Full manifest remains DRAFT.

Seventeen fixed public calls in test/parity/fixtures/core070_masks_known.R:
eight loading-mask cases and nine known-covariance cases. Capture expected
prepared maps or specific rejection before MakeADFun. Above-triangle mask
entries are ignored by the reference; do not treat them as free parameters.
NA means free, other lower-triangle entries are fixed raw loadings, packed
diagonal first then strict lower columns. All-fixed loadings retain latent
random effects. Independent phylogenetic terms reject user masks.

Known-V is a fixed covariance of additive Gaussian predictor effects e_eq.
For Gaussian identity models the marginal covariance is sigma^2 I + V + 1e-8 I.
For Poisson it is log-predictor covariance, not response sampling covariance.
The formula marker requires a separate known_V argument. A zero matrix is
regularized by frozen preparation; no claim that arbitrary non-SPD matrices
are valid. block_V uses study-aligned variances and within-study rho=.25;
verify row ordering and actual entries. Its lower rho bound is -1/(m-1),
not merely -1. This finite subset does not cover every block_V error branch.

Positive Gaussian cases receive two fixed-point normalized density and outer
derivative checks, no optimization. beta=(.2,-.1,.3)/(-.1,.25,.05), sigma=.8/.55.
For masks set only free packed loadings from (.8,.7,.1,.2,-.15) /
(.55,.9,-.1,.25,.15); keep fixed pins unchanged. Latent covariance is L L'.
Ordinary source I; animal source C=.7I+.3J+1e-8I. Match captured observation
order exactly, using trait/group indices; require nll absolute delta<=1e-6,
central-FD step1e-5 scaled gradient error<=1e-5. Shifted means must fail;
dropping nonzero known V must fail (zero-V case exempt from that control).
Retain every failed attempt; corrections need fresh receipts, not overwrite.

Totoro existing socket, one BLAS/OMP thread. Capture estimate<2min cap120s;
point checks estimate<3min cap180s. Verify frozen oracle before/after. No DRAC
campaign needed. No native Julia fit, inference, recovery or bridge claim.

CHECK: python3 tools/core070_verify_masks_known.py
EXPECT: CORE070_MASKS_KNOWN_CONTRACT_VERIFIED
Checker must bind cases, maps, source/runtime pins, raw records and exits;
negative corruption checks must fail. A passing R subset cannot freeze the
full programme manifest or discharge native Julia cases.
