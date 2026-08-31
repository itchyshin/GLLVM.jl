# Complete Gaussian source means and explicit-source formulas

## 1. Goal
Extend the fixed Gaussian source model from trait means to a complete fixed-effect
design and Julia wide/long formulas, preserving all earlier covariance contracts.
This is a bounded local candidate, not Core070 programme completion.

## 2. Implemented
`fit_gaussian_sources` accepts matrix/tensor X, including zero columns. Results
retain copied design, response shape and coefficient names; legacy constructors
retain trait-mean metadata. Explicit-source Gaussian formulas support trait
intercepts, shared slopes, categorical contrasts and interactions. Long-table
predictor extraction deduplicates repeated symbols without changing site order.

## 3a. Decisions and Rejected Alternatives
No covariance, loading, normalization, seed or tolerance changes. The complete
mean is D beta with traits varying fastest. A saturated design requires positive
fixed residual noise; q=0 with empty sources and fixed noise has no optimizer.
A declared recovery regression exposed backtracking stopping on rounded objective
values before the1e-7 gradient gate. With identical starts, LBFGS/Hager-Zhang
reached1.56514e-8 in15iterations versus backtracking2.15127e-6 in26. Select the
former only for explicit X; the old default path remains unchanged. A Newton
step was diagnostic only and is not shipped. No convergence override or ridge.

## 4. Files Touched
Source fitter/formula routing; two new tests and central includes; paired R fixture
and runner; independent readback/verifier, optimizer diagnostic; symbolic decision
and leaf; structured-dependence examples, README and both changelogs. Check log,
programme checkpoint and Julia-only Mission Control reconciliation accompany it.
R source, foreign lanes, dependency versions and public release state are untouched.

## 5. Checks Run
Final evidence is recorded in source-design-formula-evidence.json. Current retained
unit qualification:253/253 assertions, including29 analytic design tests,5 declared
recovery tests,30 formula tests and189 existing source/pervar checks. Nine previous
covariance mode pairs and six earlier nonspatial source pairs pass on final engine
bytes. New paired fixture compares one actual public R fit to direct, wide and
reversed-long Julia calls; model/health/likelihood gates are separate from bridge
qualification. Final strict Documenter build113.66seconds PASS; desktop1440/mobile390 have
no body overflow, broken anchors or browser errors. The example prints trait_1:0.7
and x:0.8; longer code panels remain horizontally scrollable. New R pair33/33
checks PASS in23.36seconds, maximum absolute deltaLL2.01794e-11, R gradient
3.99791e-5 and Julia6.67752e-9. Unlazy reverify1/2; programme gate unpaid.
Full Pkg.test()/core suites, Aqua/JET/Allocs and final completion panels remain unpaid.
Existing VitePress bundle-size, default-branding and package.json warnings remain
M3 work; a passing strict Documenter build is not a claim of zero tool warnings.

## 6. Tests of the Tests
Before implementation, unsupported X and missing formula K failures were retained
on the actual source. Setup-only failures were not counted as API regressions.
Independent base-R readback reconstructs covariance, design and normalized density
from the saved full fit without TMB evaluation/refitting. Acceptance rejects missing
receipts, changed source pins, omitted routes/checks, wrong reference, nonzero exits,
unhealthy fits and altered parameter/likelihood/data values. Exact controls/counts
are in the executable verifier and evidence report, not inferred from this prose.
Seventeen damaged-record/dependency/stale-source controls reject correctly; an
additional pre-run missing-receipt check also rejected completion.

## 7a. Issue Ledger
Broader covariance grammar, random slopes, masks, spatial routes, missing data,
non-Gaussian source models, bridge, inference and multi-seed recovery remain open.
Original Student-t health and binomial AGHQ cases remain failed. Full manifest is
DRAFT; M1 stays PARTIAL. Full-suite and specific external-review approval boundaries
are unchanged. Do not retry the previously rejected private review payload.

## 8. Consistency Audit
The mean/design documentation states axes and complete-design semantics; long
source projections follow sorted sites. Reader-facing examples use the exported
Julia formula macro and execute assertions. Fixed predictors are distinguished from
unsupported random source slopes/R random-effect grammar. Public method signatures,
README, reference docstrings and changelogs match the bounded interface. No speed,
coverage, Hessian-identification or overall-parity claim is added.

## 9. What Did Not Go Smoothly
First qualification failed recovery health and a test's untyped internal contrast
Dict; its R pair also assumed the wrong R parameter order. Correcting the test
exposed duplicate long-table interaction symbols. The independent readback caught
last-bit Linux/macOS sin() differences; it verifies the formula within1e-15 and
uses retained X for density evaluation. Later reruns caught a missing parenthesis
in a new R assertion and a semicolon typo in a documentation repeat call. Those
failures remain stored. Pure Julia parsing was added before retry. No numerical
acceptance target was loosened or failed fixture relabelled.

## 10. Known Residuals
This dense fitter scales quadratically in memory and cubically in response-cell
count. Single-seed engineering recovery does not establish calibrated inference.
Full-covariance ordinary models identify total covariance, not source/residual
components separately. The historical unique-variance case retains nearly singular
curvature. No final package-level compatibility, performance or release claim.

## 11. Team Learning
Gauss and Boole were requested as Terra/high native workers with fresh context and
exclusive source files; each used one bounded follow-up. Ada owned fixtures,
regressions, integration, the line-search diagnosis/repair, executable docs and
independent evidence checks. Actual billed hours/models are not inferred from
requested labels. Seven DRAC systems responded with Slurm via existing sockets;
Nibi had none. Totoro checks used at most three concurrent one-thread processes;
no DRAC job, new Duo login, push, merge, release or destructive cleanup occurred.
Mission Control 11095c06a145539bbecc14d3ece19861e4163e69 served HTTP200 with R fields unchanged.

## 12. Cross-Product Coverage
This covers complete Gaussian source means and explicit-source Julia formulas;
it does not cover full R0.7.0 Core/AGHQ parity or the R bridge. R0.7.1 and article
lanes are protected. Programme ACTIVE/M1 PARTIAL; next resume point is LOOP checkpoint.

Rose verdict: NOT RUN for this slice — full programme completion panel remains required.
