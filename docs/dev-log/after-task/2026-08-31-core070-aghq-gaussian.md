# After-task — internal Gaussian AGHQ adapter

## 1. Goal
Verify the ordinary shared-SD Gaussian Stage1a numerical adapter against the
frozen R 0.7.0 reference. Programme ACTIVE, M1 PARTIAL; full manifest remains
DRAFT_NOT_FROZEN. Public Gaussian integration is the next slice.

## 2. Implemented
Internal aghq_gaussian_problem accepts traits-by-sites responses, masks, offsets
and complete X[p,n,q]. Default means are per-trait intercepts; supplied X defines
the entire mean without an implicit intercept, including q=0 for zero mean.
Exact conditional Gaussian modes and curvature feed the existing AGHQ grid and
frozen-surrogate outer optimizer. Inputs and returned inspection data are copied.

## 3. What Changed the Next Action
The numerical adapter passes the original seed42 paired case and independent
Gaussian marginal checks. Public GllvmFit controls, metadata, fallback, postfit
and inference still need integration. Preserve the public fitter's existing
zero-mean default; do not inherit the adapter's per-trait intercept default.

## 3a. Decisions and Rejected Alternatives
Frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86 uses one shared residual
SD for this unique=false, loadings-only model (R/fit-multi.R:5611–5649;
src/gllvmTMB.cpp:2717–2719). Per-trait dispersion is a different model.
The exact Gaussian fit supplies a warm start only: both starts actually run
aghq_multistart_optimize. No loading ridge, fixture or tolerance change.

## 4. Files Touched
src/families/aghq_gaussian.jl and module include; test/test_aghq_gaussian.jl
and central runner; separate unit/paired runners and evidence verifier;
internal Documenter reference, contract, evidence and programme records.
Protected Cursor/Claude/unknown lanes and both R programme lanes untouched.

## 5. Checks Run
Totoro Julia1.12.6 with one Julia/BLAS thread, pinned R library and dependency
manifest, oracle verification before and after every numerical run.
Final unit run: 41 PASS, 28.720338s. Final paired run: 112 prerequisite PASS
plus 13 paired PASS, 61.557242s. The prerequisites include the 41 unit checks;
these are not 166 unique tests. Both starts/traces, exact inputs and R fit saved.
Commands: julia --startup-file=no --project=test/parity
tools/core070_aghq_gaussian_run.jl and tools/core070_aghq_gaussian_pair_run.jl.

Original p5/K2/n80 seed42, k5, 15 free parameters, unpenalized: absolute
logLik difference 5.4438942243e-10; same-R-point difference -1.1368683772e-13.
Both engines converged under the declared absolute OR relative gradient rule.
Julia max gradient 2.0294876890e-13; R 0.0003033363014 passes relative 1e-6,
not absolute 1e-4. Sigma difference 1.6665460123e-7; identifiable covariance
difference 4.2573715899e-6. Exact marginal objective difference 0, gradient
6.0085270093e-13, Hessian 1.0231815395e-12.

Strict local Documenter/VitePress PASS in 81.232519s using
julia --startup-file=no --project=.docenv docs/make.jl --local, warnonly=false.
Existing logo/favicon/default-asset/chunk warnings remain. No deployment or
desktop/mobile visual signoff. Numerical runs estimated 2–5min, capped300s;
docs estimated3–8min, capped590s. All launched jobs terminal; no DRAC compute.
Full Pkg.test/core suite, JET, Allocs and Aqua not run in this bounded slice.
No benchmark or speed claim; performance and full-suite acceptance remain unpaid.

## 6. Tests of the Tests
Initial missing-symbol red retained. Review alias red: 37 PASS/4 FAIL/no errors;
identical test bytes then pass after defensive copies. Independent covariance
Cholesky checks use heterogeneous X/offsets. k1 gives exact likelihood but the
frozen gradient differs; k2 gradient agrees but Hessian differs. k3+ agrees on
both derivatives. These explicit negative controls prevent value-only validation.
Verifier checks source/environment/log/artifact pins and rejects seven corruptions:
missing RDS/process/dependency, corrupt result, omitted case log, stale plan pin,
and nonzero test exit. Unlazy AG-VERIFY approved/reverified; 1 met,0unmet,0abandoned.

## 7a. Issue Ledger
Bounded numerical adapter verified; public Gaussian implementation remains
required. Original binomial k5 and Student-t reference failures are retained.
No issue message, release, push or merge authorized or performed.

## 8. Consistency Audit
Searched AGHQ|aghq in README.md, CLAUDE.md, docs/PERF-plus-design.md and
docs/src/low-level-reference.md. New symbol is documented under internal
adaptation/optimization. No exported symbol, dependency, public API or version
change. Existing default Gaussian fitter untouched. Broader whole-source receipts
are historical after the new source include and need revalidation when integrated.

## 9. What Did Not Go Smoothly
Independent review caught returned-data aliasing despite copying caller inputs.
It also identified that constant offsets/intercept X did not exercise site
indexing. Both gaps now have tests. All failed attempts preserved.

## 10. Known Residuals
Full manifest, covariance/modifier grammar, structured multinomial, data and
fitted objects, bridge, recovery/coverage, performance, full package checks and
final visual documentation remain open. No capability-complete claim.

## 11. Team Learning
Noether native explicit Terra/high with fresh context reviewed source, then one
repair follow-up found no remaining actionable mathematical or mutation defect.
Parent independently reran numerical and documentation checks after repair.
This is not a completion panel or Rose programme signoff. No B production child.
Elapsed commands are measured; no invented model-provider receipt or agent hours.
Ultra Plan/Unlazy and Superpowers TDD/verification used; after-task skill's stale
Pkg.test prohibition is superseded by current repository instructions.

## 12. Cross-Product Coverage
This does NOT cover public Gaussian AGHQ, full Core+AGHQ parity, R0.7.1, the
article, calibrated inference, performance, full worktree disposition or release.
See core070/aghq-gaussian-evidence.json and LOOP/core070-checkpoint.md.

Rose verdict: FAIL for programme completion — bounded adapter verified, but public
integration/full-suite and programme acceptance remain unpaid; no independent
completion-panel signoff claimed.

Mission Control local ffca5680328896a1381a6c4344c0091d7e3c9af4: HTTP200, exact served Julia field, R fields unchanged; exact-file lease released.
