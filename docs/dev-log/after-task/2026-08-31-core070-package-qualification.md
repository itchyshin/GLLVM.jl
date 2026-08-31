# Package quality qualification — interim checkpoint

## 1. Goal
Qualify the current candidate's test environment and quality checks before the
full registered suites. Full Core070+AGHQ remains incomplete.

## 2. Implemented
Fresh isolated Totoro test environment, fail-closed quality launcher, joint
regression subset, source/environment receipt verifier and sized full-run plan.
No package source, tests, dependency declarations or tolerances changed.

## 3a. Decisions and Rejected Alternatives
Use actual test/test_quality.jl; require both Aqua and JET before inclusion.
Do not substitute optional skips for quality evidence. Ignore obsolete skill
advice forbidding Pkg.test: current repository instructions explicitly require it.
The pre-run estimate5–10minutes had a600second total cap; actual about101seconds.
One Julia/BLAS/OMP thread. Longer full checks await the stated run approval.

## 4. Files Touched
New package-qualification-evidence.json and full-package-run-plan.md; check-log,
LOOP and this report. Ignored package-qualify-01 stores scripts, source archive,
logs, resolved environment, hashes and gate receipts.

## 5. Checks Run
Environment exit0 in3.73s; actual Aqua/JET12/12 exit0 in72.25s including compilation;
packing/source-kernel/source-fitting194/194 exit0 in24.52s. No skipped tests.
Fresh source and environment hashes verified against remote readback. Unlazy4met,
1unmet (full suite), exit1; no full-suite success claim. Source pinfb928667.

## 6. Tests of the Tests
Positive receipt replay and six negative controls: omitted command, nonzero exit,
changed source flag, stale plan, changed log and missing manifest. All rejected.
Loaded-package path asserted in both test commands; source checked before/after.

## 7a. Issue Ledger
No bounded test failure. Full core/Pkg.test still pending. Existing unwired
phylogenetic tests, parity failures, manifest scope and recovery remain unpaid.

## 8. Consistency Audit
Aqua0.8.16/JET0.12.1 on Julia1.12.6; numerical deps include Optim1.13.3 and
ForwardDiff0.10.39. JET checks only the existing two Takahashi kernels, not all
engine paths. Source tests are wired in the central runner. Complete source
archives must include tools and docs consumed by registry/binding tests.

## 9. What Did Not Go Smoothly
Initial skill lookup used the global directory; actual skill is repository-local.
Its obsolete Pkg.test prohibition conflicts with current repository instructions.
The run completed below estimate; no dependency installation error or retry.

## 10. Known Residuals
Await requested approval for two separate-copy one-thread full suites on Totoro,
85–100minutes each,120minute hard stops. The short pre-run cannot establish exact
full runtime. No package or programme completion claim; remaining manifest and
capability work continues independently.

## 11. Team Learning
Parent owned this bounded qualification; no new agents or claimed independent
panel verdicts. Explicit dependency assertions prevent optional skips from
masquerading as full quality evidence. Raw and environment hashes are retained.

## 12. Cross-Product Coverage
This pre-run does NOT cover full package/core suites, all-kernel type stability,
R parity, inference calibration, performance, full-site polish, or manifest
completion. No source changes, push, merge, release or destructive cleanup.
Rose verdict: NOT REQUESTED — qualification evidence only.
