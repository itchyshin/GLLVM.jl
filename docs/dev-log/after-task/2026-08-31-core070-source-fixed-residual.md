# Gaussian sources: explicit fixed residual noise

## 1. Goal
Represent the frozen R ordinary independent/common Gaussian models exactly by
allowing residual noise to be fixed, while retaining the existing free default.

## 2. Implemented
fit_gaussian_sources accepts sigma_eps_fixed. Fixed models omit that coordinate
from start, parameters, dof, gradients and Hessians. GaussianSourcesFit records
residual_fixed and reports the supplied Float64 SD exactly. The prior13-argument
constructor remains supported as a free-residual fit; this is constructor
compatibility, not a cross-version binary-serialization guarantee. Constant
responses are admitted with positive fixed noise. No implicit R suppression,
ridge, changed default or covariance parameterization was added.

## 3a. Decisions and Rejected Alternatives
The user supplies fixed noise explicitly; do not silently fix an unidentifiable
free-noise model. Positive finite non-Bool inputs must remain positive and finite
when converted to Float64. The full normalized Gaussian objective is unchanged;
only free coordinates are differentiated. Source/trait identification and
uncertainty remain model-specific. See decisions/2026-08-31-source-fixed-residual.md.

## 4. Files Touched
src/source_fit.jl; new fixed-residual unit and paired driver/readback/verifiers;
central test runner; README, CHANGELOG and structured-dependence/reference docs.
Local-only docs/make.jl version-index repair addresses a reproduced preview404.
Leaf, mathematical contract, evidence and logs retain exact scope. R source,
original fixtures, tolerances and other lanes are unchanged.

## 5. Checks Run
Totoro red9.43s demonstrated the unsupported keyword before implementation.
New unit37/37 PASS30.07s; existing source units46+71 PASS22.10s. Six retained
nonspatial source model comparisons and R cross-evaluations pass. New exact
MODE-ORD-INDEP/COMMON R comparisons PASS27 assertions in25.51s. Absolute
likelihood differences2.55937e-11 and3.97904e-13; R gradients3.65672e-5 and
4.32102e-7; Julia gradients2.05937e-8 and5.10125e-8. Both use exact reference
residual SD0.0007475049429920294, with6 and4 free parameters. No optimizer flags
or likelihood from different runs were combined. Oracle before/after checks pass.
Strict final Documenter build PASS110.90s, examples executed. All runs one thread,
below their estimates/caps. Unlazy2/3 gates pass; full programme remains unpaid.

## 6. Tests of the Tests
Analytic mean-only, ordinary independent and common-variance ML solutions test
likelihood, means, variance and free-coordinate diagnostics. Invalid scales,
wrong start length, copying and old-constructor tests pass. Sixteen paired-report
mutations reject false codes/gradients/counts/likelihood/covariance/parameter roles.
Independent base-R readback checks original serialized fields and fixed maps.
No full-family, recovery or coverage result is inferred from these controls.

## 7a. Issue Ledger
This qualifies two native ordinary fitted-mode cases, not the other seven exact
covariance-mode fit contracts. Formula/bridge, missing data, slopes, masks,
source-kernel estimation, remaining families/AGHQ and inference remain required.
Original Student fixture remains unhealthy. Full suites and specific external
numerical-review approvals remain unchanged. Source manifest remains draft.

## 8. Consistency Audit
Default free-noise source behavior and six existing pairs remain passing.
Current mathematical contract, docs, metadata and parameter counts agree.
Older covariance-modes-contract.md is historical qualification; the separate
source-fixed-residual-contract.md explicitly updates only two native cases.
Final source-fixed-residual-final-evidence.json binds current code and docs;
initial evidence remains retained. Older whole-source-pinned family/bridge receipts
need replay for a final candidate after this source change; no current whole-
programme verification is claimed. Documentation-only historical snapshots are
checked against archived bytes; no stale numerical source is exempted.

## 9. What Did Not Go Smoothly
First paired snapshot omitted parity_trial_inputs.jl and stopped before fitting;
retry copied the complete parity inputs. Initial docs launch reused a project
without declared Distributions and missed an internal docstring reference; fixed
launch project plus reference entry passed. The first browser check then caught
an existing local versions.js404. A local-build-only version index fixes it;
deployment is unchanged. Shorter code lines now fit mobile. Every failed attempt
and first screenshot is retained. The ledger parser rejected a missing space
after its ID colon before executing; corrected format, unchanged commands reran.

## 10. Known Residuals
Final desktop1440/mobile390 checks pass: no viewport overflow, broken local
anchors or captured page/request errors. Parent inspected both example images.
The browser still observes an optional favicon404; the builder also reports
missing optional branding, a default package.json and bundle-size warnings.
Do not call the whole site warning-free or M3 complete. Full package checks and
completion panels remain unpaid. Mission Control94a126b1e2a8921b421b49ec71913be31393d231
served HTTP200 and preserved all R0.7.1 fields.

## 11. Team Learning
Gauss worker owned only src/source_fit.jl, requested Terra/high native fresh
context. Parent captured red before dispatch, owned tests/math/docs and reviewed
free-coordinate reconstruction before runtime checks. One production child,
no numerical runs by worker and no independent Rose completion panel. Requested
model/effort is not an actual billing receipt; no hours fabricated. Reuse current
qualified dependency projects, not obsolete launch-script copies.

## 12. Cross-Product Coverage
This does NOT cover full R0.7.0 parity, formula/bridge source terms, the remaining
covariance crossings, recovery/coverage, performance, full package checks or
final Documenter campaign. No new R family/default, R0.7.1/article modification,
DRAC submission, push, merge, release or destructive cleanup. ACTIVE/M1 PARTIAL.
