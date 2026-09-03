# Source-bound retained model replay checkpoint

## 1. Goal
Bind already demonstrated Poisson/Beta/NB2/truncated-NB2 cases to frozen source
obligations and replay them alongside Gaussian native/formula on current inputs.

## 2. Implemented
Five additional executable definitions and source links, preserving their stable
runner IDs. Generated family plan maps planned-role aliases to actual IDs. The
new subset verifier checks current supervised receipts and raw R fit readbacks.
No src/ or existing Julia fixture/helper code changed.

## 3a. Decisions and Rejected Alternatives
Poisson/Beta retain default R fits then use declared public start_from refinement;
truncated NB2 retains default failure then public BFGS refinement. NB2 remains its
original default R fit. Do not label these uniformly default-optimizer success.
The subset verifier does not bypass the draft guard by fabricating FROZEN status.

## 4. Files Touched
Master executable contract/map, generated family plan and generator, new registered
model contract/verifier/tests, metadata checks, evidence, case guide and checkpoint
records. No numerical engine, existing Julia fixture or foreign lane files changed.

## 5. Checks Run
Three new binding tests fail before registration and pass after. All five new
reference-call strings parse in R before execution. Totoro required replay passes
121assertions/6executions/7caseIDs in77.78s; registry28checks3.12s; oracle verification
before/after passes. Both engines' final absolute gradients<=1e-4 for all models.
Largest absolute logLik difference3.4128e-6 (NB2), within its original tolerance.
Raw R fit readback verifies retained numeric values, original/refined data/maps
and free parameter names. Local metadata42tests plus evidence self-test pass.

## 6. Tests of the Tests
Twenty-two controls reject changed truncation policy/data/fixture/optimizer,
failed convergence/gradients, missing case IDs, nonzero exit, stale contract,
double-counted Gaussian assertions and changed long-formula values. Existing
scope guards reject full-family promotion for every linked family. Unlazy2/3
freshly reverified; full-contract gate remains unpaid.

## 7a. Issue Ledger
Seven executable links across five partially covered family facts;710other
nonexcluded source facts remain unmapped. Full-family interface coverage is not
proved by a source link. Bridge and remaining formula/model variants remain.
Older receipts remain historical, with this combined replay providing current
subset evidence for unchanged numerical/fixture inputs and the new contract.

## 8. Consistency Audit
Exact original data hashes and declared parameter scales preserved. Poisson uses
canonical curvature; Beta/NB2/truncatedNB2 observed curvature. Refinements retain
original fits and failure metadata. Assertion accounting preserves the Gaussian
shared execution. Planned IDs are aliases, not duplicated extra fits. Full
manifest remains draft; no full-suite, recovery, coverage or speedup claim.

## 9. What Did Not Go Smoothly
R parsing caught an extra closing parenthesis in two newly transcribed reference
call records before fits ran; corrected the records and reran parsing. The first
readback assumed Poisson/Beta metrics repeated a source object that their actual
schema does not contain. Their logged metric hashes and enclosing supervised
source receipt provide that binding; corrected the verifier to use those facts.
The original truncated-NB2 default R failure remains retained, not hidden.

## 10. Known Residuals
Fullsuite and specific external numerical-review approvals remain pending. Other
required models/interfaces, AGHQ domain, covariance/data/postfit coverage, bridge,
recovery/performance and final Documenter work remain. No hours forecast revised.

## 11. Team Learning
Ada parent performed this bounded integration; no reviewer/model/agent-hours
receipt invented. Rose verdict NOT REQUESTED for this interim checkpoint.
Control-policy provenance matters as much as matching likelihood values: a
successful public refinement is not evidence that the original optimizer passed.

## 12. Cross-Product Coverage
This checkpoint does NOT cover complete response families, public R bridge,
remaining formula/covariance/data/inference/AGHQ combinations, recovery/coverage,
full package suites, independent review or final documentation/performance claims.
No push, merge, release, destructive cleanup or DRAC allocation. Totoro jobs ended.
