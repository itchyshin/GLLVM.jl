# Core070 per-variance Gaussian formula checkpoint

## 1. Goal
Expose the already verified fixed-residual Gaussian model through Julia formula
and complete long-table inputs without changing the shared-variance route.
Programme remains ACTIVE, M1 PARTIAL; the full manifest is DRAFT_NOT_FROZEN.

## 2. Implemented
`gllvm(...;family=Normal(),pervar=true)` builds a complete mean design and routes
through the native per-variance dispatcher. Trait intercepts, zero mean, shared
site slopes, categorical rank/contrast rules and long/wide inputs are covered.
An explicit fixed residual SD passes through; no automatic R scale or new engine.

## 3a. Decisions and Rejected Alternatives
Keep the existing shared-variance formula behavior separate. Use StatsModels'
full-rank schema before expanding its intercept into one coefficient per trait.
Do not strip `0`/`1` and accidentally replace a zero-mean model with row means.
Do not claim formula support by comparing different mean/covariance contracts.
The original frozen-R Gaussian fixture and parameter/health gates are unchanged.

## 4. Files Touched
src/formula.jl; test/test_formula_pervar.jl and central runner; paired replay helper;
README, both changelogs, tutorial/response-families; leaf/evidence/visual report,
check-log and LOOP. Mission Control changed only the Julia next-action fragment.
No R engine, foreign checkout, AGENTS or CLAUDE changes.

## 5. Checks Run
First baseline lacked direct StatsModels dependency and stopped before testing;
retained. Qualified baseline reached unsupported pervar keyword in22.02s, before
code changes. Final identical-test baseline replay failed as expected in30.04s.
Final candidate35new+27existing formula+23fixed-residual assertions pass in114.70s.
Original R pair10native+9formula checks pass in38.37s, plus oracle verification
before/after. Formula/native log-likelihoods are identical; R difference3.864e-9.
Native/formula maxgradient1.542e-10; R4.4453e-5; both converged.
Strict docs107.60s, executed formula/matrix assertions pass. Four desktop/mobile
screenshots inspected. No full package/core suite or new quality-battery claim.

## 6. Tests of the Tests
Seven corrupted receipt variants reject stale fixture, false convergence, excess
gradient, wrong mean dimension/parameter count, and excess likelihood differences.
Verifier binds source archive contents, plans, process exits, logs, original fixture
and final regression bytes. Four of five Unlazy gates pass after fresh reverify;
full-suite/independent review gate stays UNMET. First visual selector chose code,
not output; the aggregate gate rejects it and the corrected capture passes.

## 7a. Issue Ledger
Formula dispatch gap closed at tested scope. R bridge, AGHQ fallback and intervals
for the default-unique decomposition remain required. Independent review awaits
the previously requested specific code-sharing approval; no alternate dispatch.
Full suite runs still await over30minute approval. Neither approval is inferred
from goal continuation. No workers or numerical jobs remain active at closure.

## 8. Consistency Audit
Parameter count includes the full fixed-effect design; fixed residual adds none.
Per-variance `y~0` has no coefficients; `y~1` has p trait intercepts; covariate-only
syntax has an implicit intercept, and `0`/`-1` removes it. Dummy/effects coding
and full categorical coding without intercept are checked. Existing shared-
variance behavior is unchanged; its broader legacy intercept documentation needs
its own audit and must not be treated as evidence for this new route.

## 9. What Did Not Go Smoothly
Parity-only environment omitted StatsModels; used the already qualified package-
test environment with corrected candidate path and retained version pins. Final
parallel green run exceeded20-90second estimate at114.70s; observed terminal and
reported, below180second timeout. No automatic rerun after timeout. Browser's first
selector captured code; corrected and retained both. Unlazy approval-store write
initially hit sandbox EPERM; normal escalation succeeded, no permission bypass.

## 10. Known Residuals
No changes to likelihood kernel; its prior independent review remains pending.
Full checks, actual AGHQ fallback, bridge, intervals, recovery, covariance and
multinomial gaps, performance and complete docs polish remain. No hours forecast
updated from these bounded checks. Existing documentation build warnings remain.

## 11. Team Learning
Ada parent implemented and checked this slice. No child dispatched; no independent
review or model/hour receipt invented. Native/formula agreement needs an explicit
mean contract, and StatsModels schema context determines categorical rank.

## 12. Cross-Product Coverage
This checkpoint does NOT cover R bridge, AGHQ fallback, interval calibration,
recovery/coverage, full suites, all interfaces or full Core070 parity. No push,
merge, release or cleanup. Rose independent verdict: NOT REQUESTED; interim
candidate only. Required gates remain explicit in the acceptance ledger.
