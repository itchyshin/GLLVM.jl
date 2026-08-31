# After-task — public Gaussian AGHQ candidate

## 1. Goal
Expose the verified ordinary shared-SD Gaussian adapter through GllvmFit while
preserving the default exact, zero-mean fitter. Programme ACTIVE/M1 PARTIAL;
full manifest DRAFT_NOT_FROZEN. This report closes a bounded implementation
slice, not the package or the approved programme.

## 2. Implemented
Public controls, eligibility, exact fallback, copied observations/design/masks/
offsets and integration provenance; generic/formula forwarding; fitted modes,
predictions/residuals/simulation; recorded-objective Wald/profile/bootstrap and
derived quantities. Seven-argument legacy GllvmFit constructor remains valid.
The original exact fitter's numerical body is byte-identical except its name.

## 3. What Changed the Next Action
Public Gaussian now passes its original seed42 k5 reference comparison and
postfit smoke. Remaining Stage1a admissions and original binomial convergence
remain open. A nearby default-off explicit zero-column/all-fixed design defect
was observed in the shared warm-start path and requires separate reproduction;
recorded Gaussian AGHQ/fallback warm starts are repaired and tested.

## 3a. Decisions and Rejected Alternatives
X=nothing retains zero mean; the adapter's intercept default is not inherited.
Observed-submatrix exact likelihood, not imputed data, governs missing-response
fits. Imputation is warm initialization only. Frozen-surrogate inference retains
its fitted target and refits retain the requested policy and actual estimator.
No loading ridge, tolerance widening, changed seed or fixture substitution.

## 4. Files Touched
src/fit.jl, families/aghq_gaussian_fit.jl, families/aghq_fit_info.jl, GLLVM.jl,
postfit and confint/derived families; test/test_aghq_public_gaussian.jl and runner;
three scoped tools, verifier, README/CHANGELOG, API/quickstart/low-level docs,
leaf contract, evidence/check-log/checkpoint. R and foreign worktrees untouched.

## 5. Checks Run
Totoro Julia1.12.6, frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86,
pinned dependency environment, one Julia/BLAS thread, oracle before/after.
Final green06:273 PASS in133.034208s (69 public Gaussian,41 internal Gaussian,
108 public binomial,52 public Poisson,3 Wald). Final pair03:112 prerequisites
and13 paired PASS in68.152257s; overlapping prerequisites are not unique tests.
Commands: julia --startup-file=no --project=test/parity with
 tools/core070_aghq_public_gaussian_run.jl and
 tools/core070_aghq_public_gaussian_pair_run.jl.
Original p5/K2/n80,15 free parameters,k5: absolute logLik delta5.4444626585e-10,
samepoint -1.1368683772e-13, sigma delta1.6665460134e-7, covariance4.2573715892e-6.
Both converge under declared absolute OR relative gradient rule: R max gradient
0.0003033363014 passes relative1e-6 only; Julia2.2515322939e-13.
Strict Documenter --local PASS89.996033s, warnonly=false. Retrieved HTML hash
matches remote; executed Gaussian example reports actual AGHQ,k3,converged=true.
No desktop/mobile visual audit/deployment. Existing asset/chunk warnings remain.
Bounds declared before runs: numerical2–5min/cap300s; docs3–8min/cap590s.
All processes terminal, no DRAC compute. Full Pkg.test/core/JET/Aqua/Allocs not run.

## 6. Tests of the Tests
Retained red phases expose missing integration, wrong inference target, display,
packed callback, free-beta indexing and bootstrap warm-start defects. Direct
bootstrap replay identifies zero(Type{Any}) from empty X; original failed
attempts retained. Final two-attempt smoke retains both successes/replicates;
no percentile-interval or coverage claim. Exact AD/FD covariance and perturbed
frozen-objective tests guard against convenient exact-likelihood substitution.
Evidence verifier rejects7 corruptions: missing RDS/process/dependency, corrupt
result, omitted case log, stale source pin, nonzero test exit. GU-PUBLIC and
GU-PAIR met; fresh reverify required at local commit, no abandoned gate.

## 7a. Issue Ledger
Full manifest/admissions and original binomial/Student reference failures remain.
Default-off explicit zero-column/all-fixed design is next bounded regression
lead, not a claimed repair. No issue messages or push/merge/release performed.

## 8. Consistency Audit
New public keywords and GllvmFit metadata documented in same candidate; README,
CHANGELOG, quickstart/API/low-level reference updated. Strict docs exposed a
misattached GllvmFit docstring after introducing AbstractIntegrationInfo; moved
the abstract declaration above the docstring and reran all final checks.
Existing default exact numerical body verified unchanged. No dependency/version
change. Earlier whole-source evidence remains historical until rerun.

## 9. What Did Not Go Smoothly
Derived interval helpers were initially bypassing recorded estimator identity.
Noether identified adjacent dispatch gaps; parent added failing regressions and
repaired them. A proposed fallback-node hypothesis was rejected by checking
actual versus requested metadata fields. Direct replay found the actual empty
bootstrap cause. Neither failures nor failed reviewer hypotheses were hidden.

## 10. Known Residuals
Full manifest, all Stage1a families, binomial original k5 convergence, Student R
health/density,17 link dispositions, covariance/modifiers, structured multinomial,
data/postfit breadth, bridge, recovery/coverage/performance, full package and
visual documentation remain unpaid. Census must refresh before disposition.

## 11. Team Learning
Noether native explicit Terra/high, fresh context, one repair follow-up: no
remaining actionable correctness gaps in reviewed surface. Source review only;
no fits by reviewer or completion panel. Parent ran independent fresh checks.
No new B production child. Ultra Plan/Unlazy and Superpowers TDD/debugging/
verification used. Measured command times are not invented aggregate agent hours.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ parity, calibrated inference, performance,
full package checks, R0.7.1/article, final worktree cleanup or release.
Rose programme verdict remains NOT DONE; this is not independent Rose signoff.
See core070/aghq-public-gaussian-evidence.json and LOOP/core070-checkpoint.md.

Mission Control local 36305013d4dc4c6c1c26efd37dd6aceecc974926: HTTP200, exact served Julia field, R fields unchanged; exact-file lease released.
