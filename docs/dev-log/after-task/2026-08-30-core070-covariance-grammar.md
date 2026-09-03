# Core070 covariance grammar: source subset, not model parity

## 1. Goal
Expand the frozen R contract using actual covariance/modifier rewrite and helper
behavior; identify the model obligations before B1/B2 implementation.

## 2. Implemented
A pinned R source replay runner, 95-case manifest, fixture and negative tests.
Recorded source defaults and fit-stage restrictions separately. Added a pointer
from the still-DRAFT master contract; no required obligation was removed.

## 3a. Decisions and Rejected Alternatives
Do not test empty marker constructor bodies as capability evidence. Do not
interpret helper-family admission as permission for every source/slope model.
Do not infer multi-kernel unique rejection from documentation when source
prunes automatic companions but rejects explicit ones. No new agent dispatched.

## 4. Files Touched
`tools/core070_covariance_admission.py`, its test, the covariance fixture,
subset/evidence JSON, covariance-source-contract.md, master contract pointer,
check-log and programme checkpoint. Numerical Julia/R engines unchanged.

## 5. Checks Run
Local R4.6.0 and Totoro R4.5.3 each pass95 source cases, actual exit0; raw TSV
hashes match. Source files match the archived frozen oracle inventory. Commands
have30-second process limits; each local replay took under2seconds including
runner overhead. Tests execute positive and deliberately false cases and verify
omitted/stale inputs launch nothing. Unlazy G1 freshly reverified; G2/G3 are
manual evidence/readback and scope checks. No fitting or compilation. Collection regressions8/8 pass and full-contract
aggregation rejects DRAFT_CONTRACT with exit2. Mission Control Julia-only update
was verified HTTP200 at vault4267e292, preserving R fields.

## 6. Tests of the Tests
First attempt had76 passes/9 failures: four malformed positive indep/dep calls
and five mismatched cli diagnostic strings. Second attempt had91 passes/2
failures: animal source arguments are validated before the bar syntax. Third
attempt passes95 after retaining both rejection paths. The false-assertion
negative test retains a nonzero R process and FAIL receipt. Missing and stale
manifest cases reject before starting R.

## 7a. Issue Ledger
Source subset: verified. Actual fit-input/model intersections: OPEN. Full finite
capability contract: DRAFT. Julia covariance formula markers: not implemented
in current formula.jl. Native and bridge reachability: unverified per row.
Original Student health: still failed, not modified by this slice.

## 8. Consistency Audit
Compared rewrite functions with fit-multi's automatic-Psi and multinomial fences.
Recorded source-stage results separately from fit-level rules and existing Julia
covariance utilities. No public numerical claim or completed matrix asserted.
Master manifest status remains DRAFT; old numerical receipts are historical
pins, not fresh validation of the amended contract.

## 9. What Did Not Go Smoothly
An exploratory loader initially omitted the source deprecation environment and
missing-predictor walk helper. Retained probe logs show those setup failures.
Positive bar syntax and quoted cli diagnostics then needed correction; all
failed numbered attempts remain. No source admission rule was relaxed.

## 10. Known Residuals
The 95 rows include51 family/link helper combinations, not51 independent fitted
models. Fit-level matrices, family-specific Psi, multiple kernels, slopes,
loading masks, known V, postfit methods and actual estimator evidence remain.
No independent completion panel or rendered docs review occurred.

## 11. Team Learning
Validate the exact stage of a contract: rewrite flags, fit-input admission,
estimated model and public information are distinct. Keep source-dependent
normalization and exclusions visible before mapping either API.

## 12. Cross-Product Coverage
Covers selected ordinary/phylo/animal/kernel/spatial rewrite paths, unique
modifiers, ordinary common variance, selected aliases, source-lv rejections,
ordinary slopes and the slope family/link helper table. It does NOT cover a
complete covariance/source/mode/modifier cross-product, actual fits, singular
input behavior, likelihood/recovery, Julia formula/native/bridge equivalence,
all common/scalar routes, all data/postfit methods, AGHQ or Documenter rendering.
It does NOT cover or change the protected R0.7.1 and article lanes.
