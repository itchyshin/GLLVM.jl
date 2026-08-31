# Six retained Gaussian source fits — paired validation checkpoint

## 1. Goal
Move Core070+AGHQ from typed source construction to paired fits against the
frozen public R reference. Previous turn was progress:117targeted tests passed.
Programme M1 remains PARTIAL and full manifest DRAFT_NOT_FROZEN.

## 2. Implemented
R public-fit exporter, Julia paired-fitting driver, R cross-evaluation and an
independent receipt checker for six retained nonspatial source fixtures. No
engine changes or new data. Typed source fitting now has paired point-estimate
and likelihood evidence on these fixtures, with a curvature caveat below.

## 3a. Decisions and Rejected Alternatives
Use original public R calls and seed700 with unchanged controls. Check their
objectives against captured TMB inputs before export. Map repeated parameter
names explicitly; only propto needs logvariance=2logSD and the corresponding
gradient transform. Do not substitute fixed effects for source terms, alter
likelihood tolerances or repair R optimization after observing results.
One Totoro thread; estimate3–5min, batch cap300s, actual batch about36s.

## 4. Files Touched
New tools/core070_gaussian_source_pair.R, core070_gaussian_source_pair.jl,
core070_gaussian_source_cross.R and core070_verify_source_pair.py; new leaf
and evidence JSON; updated binding/current candidate status, check-log, LOOP.
Ignored input copies, source archive, execution plan and all process/results
retained under .unlazy/core070-aghq/gaussian-source-pair-01. External change
is confined to Mission Control's Julia status fragment.

## 5. Checks Run
All six IDs passed original contracts: same-start NLL/gradient<=1e-6;
R-endpoint native NLL<=1e-6 and gradient<=1e-5; fitted deltaLL<=1e-3;
both optimizer convergence verdicts and absolute gradient<=1e-4; R objective
report agreement<=1e-6; R evaluation at native endpoints<=1e-6.
Largest fitted deltaLL2.198954e-9. Largest native final gradient7.588798e-7;
R gradients below4.392609e-5. Max reported per-source covariance relative
difference3.034856e-6, mean difference8.214502e-7; these descriptive quantities
have no retrospectively invented acceptance cutoff. Oracle source/build
verified before and after, all five process exits0. Unlazy pair gate passes.

## 6. Tests of the Tests
Seven checker negative controls reject bad health/gradient/cross-evaluation,
missing evidence, wrong fitted objective, omitted condition and NaN. A path
normalization positive/negative control distinguishes harmless trailing slash
from another directory. Expected six-case census, pins, command inventory,
logs and process exits checked. Prior source unit negative/analytic controls
remain separate evidence. No true TDD ordering claimed for recovered source API.

## 7a. Issue Ledger
Pair gate met; independent completion-review/recovery gate remains unmet.
Kernel unique-Psi native minimum curvature3.1185e-12 and R8.7959e-9 are near
singular. Do not interpret a positive sign as reliable identification or
uncertainty. Recovery/coverage and inference are unverified. All original
binomial/Student-t/default-unique/AGHQ and wider covariance/data/postfit/bridge/
multinomial requirements remain. Formula/parser surface still unpaid.

## 8. Consistency Audit
Six retained36-response fixtures; no omitted failed case. Source/loadings are
compared via covariance, avoiding raw loading sign conventions. All source
input bytes match retained RDS; no R engine edits. The report records runtimes
as operational costs, never an R-versus-Julia speed comparison. Full package,
Aqua/JET/Allocs and strict Documenter checks remain pending. Existing numerical
unit and pair evidence remain distinct.

## 9. What Did Not Go Smoothly
Parent review moved worker's include to top level to avoid Julia world-age
failure and added an actual loaded-root assertion. No failed runtime is
invented for those static fixes. Independent checker initially rejected a
trailing slash in script_root; normalized POSIX paths fix the provenance check.
Original verifier bytes from the pre-run source archive are retained, and
only that unused remote payload file is checked historically; every executed
script and numerical source must still match current pins. No fit replay was
needed for this pure verification correction.

## 10. Known Residuals
No executed source Documenter example, broad covariance grammar, estimated
kernel/spatial source fitting, calibration, final package check or performance
claim. Next execute and inspect source documentation, then resume remaining
contract rows and predeclared recovery designs. Do not treat six fixtures as
all-source or full Core070 parity.

## 11. Team Learning
Hopper production worker requested Terra/high with fresh context; owned only
native driver and returned ownership. Parent owned R, launcher and independent
checker. One delivery plus parent review corrections; no nested dispatch.
No actual model/hours receipt invented. Prior Noether source review remains;
no new numerical completion panel or Rose verdict. Totoro uses authorized
key-auth reconnect, DRAC remains existing sockets and scheduled compute only.

## 12. Cross-Product Coverage
This checkpoint does NOT cover formula/bridge/tree/pedigree/mesh parsers,
spatial/free-kappa, non-Gaussian sources, slopes/masks/missingness, intervals,
recovery/coverage, broad benchmarks, full package tests or rendered Documenter.
No push, merge, release or cleanup; R0.7.1/article/foreign lanes protected.

Rose verdict: NOT REQUESTED — interim evidence, not milestone completion.
