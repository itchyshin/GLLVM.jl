# Frozen data-control contract — partial checkpoint

## 1. Goal
Make shape, ordering, missingness and offset requirements explicit before native/formula/bridge data parity work.

## 2. Implemented
56 exact source-helper cases, runner, pinned evidence and verifier, live wrong-order negative control and eight metadata negative controls. Master draft and fit-input contract link the new subset. No engine changes.

## 3a. Decisions and Rejected Alternatives
Keep R matrix/traits() ordering and masked-cell behavior distinct. Do not interpret generic fractional weights as valid binomial trials or source helper return values as public fitted admission. No latent or optimizer computations and no remote restart.

## 4. Files Touched
test/parity/fixtures/core070_data_controls.R; tools/core070_data_controls.R; tools/core070_verify_data_controls.py; tools/core070_test_data_controls.py; scoped evidence/contract/report, master draft, fit-input contract, check-log and core070 checkpoint. Runtime under .unlazy/core070-aghq/data-controls.

## 5. Checks Run
R4.6.0/cli3.6.6;56 source-control cases PASS, process exit0. Wrong expected matrix ordering:55pass/1fail exit1. Eight metadata negative controls pass. Unlazy freshly reverified2met/1unmet, no abandonment. Mission Control served/readback verified, R fields preserved. Exact source hashes match frozen oracle inventory; no package initialization or fits.

## 6. Tests of the Tests
Negative live expectation detects confusing unit-major with trait-major flattening. Verifier rejects stale fixture, reference, omitted case, wrong count, corrupt receipt and false installed/native completion. Required numerical parity gate remains unpaid.

## 7a. Issue Ledger
B4/B2/B5 still owe long/wide/categorical/missing/trial fitted fixtures and interface reachability. Training offset rejects non-finite values, newdata helper does not; full prediction behavior still needs qualification. Full manifest DRAFT/M1 PARTIAL. Totoro socket absent and remote family-recheck-01 UNKNOWN; no restart.

## 8. Consistency Audit
All56 are source policies, not fitted model comparisons. Native traits×units mapping documented; no native behavior modified. MSPL/weighted inference boundaries unchanged. No tolerance, oracle, public API, version, push or release change.

## 9. What Did Not Go Smoothly
Different stacking conventions are easy to conflate. Retained masked-cell weight values also differ by route. miss_control's intended custom estimator guard is unreachable because its formals reject the argument first; recorded actual unused-argument behavior.

## 10. Known Residuals
No Julia/R transport, fitted row alignment, count validation, imputation, missing-response optimum or postfit restoration check. Offset helper tests cannot certify complete public prediction behavior. No independent review or broad completion claim.

## 11. Team Learning
Test exact sentinel vectors with asymmetric dimensions before fitting; equal shapes or repeated values can conceal a silent unit/trait permutation. Keep generic shape normalization separate from family-specific weight meaning.

## 12. Cross-Product Coverage
This does NOT cover numerical Core/AGHQ parity, fullsuite, original Student/truncated-NB2 fit health, recovery, performance or Documenter completion. Rose verdict NOT RUN; programme active.
