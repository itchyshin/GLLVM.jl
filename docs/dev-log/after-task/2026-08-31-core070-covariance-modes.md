# After-task — Gaussian covariance-mode reference contracts

## 1. Goal
Close the missing fit-level specification for ordinary, animal and named-kernel
independent/common/dependent covariance modes against the frozen R0.7.0 source.
Full Core070+AGHQ programme remains ACTIVE/M1 PARTIAL/manifest DRAFT_NOT_FROZEN.

## 2. Implemented
Nine actual prepared model captures, two fixed points per model, an independent
dense Gaussian density/FD comparator, process/archive/artifact verifier, negative
controls and a source-grounded contract. Seven source-map rows now point to the
nine reference contracts, with zero executable parity promotions.

## 3. What Changed the Next Action
Do not infer covariance parameters from marker names: ordinary diagonal uses
log SD, animal common uses log variance, kernel common ties raw loadings. Keep
these transforms and residual maps in the B1/B2 representation contract. The
next specification work is source/mode/slopes/masks/known-covariance crossings,
not another replay of these unchanged nine fixtures.

## 3a. Decisions and Rejected Alternatives
Effective dense-source covariance includes the reference's 1e-8 diagonal
preprocessing. Preserve this explicitly rather than adding a new stabilization
or widening comparison tolerance. Common variance gives s²I, not s²11'.
Ordinary full dependent covariance plus free residual is not separately identified
in this observation-level fixture; no fit/recovery claim. Raw loading signs are
also not identified by covariance. R remains immutable and public interfaces
remain separately qualified obligations.

## 4. Files Touched
New covariance-mode R fixture, fixed-point evaluator, Python verifier and tests;
leaf, contract, evidence JSON and this report. Updated source-map reference
links, check-log and Core070 checkpoint. Mission Control changed only the Julia
next-action text. No production src, R source, API, tolerance or foreign edits.

## 5. Checks Run
Totoro R4.5.3/TMB1.9.21, one BLAS/OMP thread, frozen oracle verified before/after.
Capture:9/9 in1.067s (estimate under2min/cap120s). First points: exit1 in0.817s;
final18/18 points: exit0 in0.917s (estimate under3min/cap180s). Maximum absolute
nll difference2.557953849e-13; maximum scaled FD gradient error1.610688527e-9,
inside predeclared1e-6/1e-5 gates. Six wrong-common and18 shifted-mean controls
reject equality. No outer optimizer ran; TMB integrated conditional Gaussian
random effects. Local six verifier tests and six adjacent source-map tests pass.
No package suite, Documenter build, recovery or performance campaign claimed.

## 6. Tests of the Tests
Twenty-three corruptions reject across six tests, with the real positive control:
missing model/point/dependency/document/archive, stale plan, nonzero exit,
wrong nll/gradient, wrong common covariance, transform/map/free-count mismatch,
hidden source jitter, false scope or historical-success promotion, changed
summary, and four direct retained-matrix defects (rows/order/jitter/correlation).
Tests work on copies or mocked summary reads; all original artifacts remain.
ResourceWarnings from CSV files were fixed with context-managed reads; the final
suite passes with ResourceWarnings treated as errors.

## 7a. Issue Ledger
Native fitted-mode, formula and bridge parity remain unpaid for these contracts.
Original binomial seed43/k5, Student-t seed71, default-unique parameter mismatch,
remaining AGHQ admissions and broad covariance/data/postfit obligations remain.
No new B production worker or compute campaign, push, merge, release or cleanup.

## 8. Consistency Audit
All nine R calls and captured maps align with the dense model and named matrix
ordering. Master752 known-source facts unchanged; seven rows gained reference
links only. Earlier mapping-hash evidence is historical after these link changes;
it is not current full coverage. The amended human leaf is pinned separately
from the immutable pre-run version retained in every source archive. Executed
code/fixture pins still match current files; prose correction caused no rerun.

## 9. What Did Not Go Smoothly
Initial expectation used raw C. The source actually adds1e-8I before inversion;
that run stopped after six ordinary points and remains FAIL, never promoted.
The repair asserts the exact effective matrix at unchanged1e-12 tolerance.
Noether then found the verifier trusted a source-jitter declaration without
checking retained matrix entries. Parent added ordered dimension/value checks
and four mutation tests; all pass.

## 10. Known Residuals
Only Gaussian, dense named SPD input, three traits,18sites/six structured groups,
positive-diagonal points and intercept models are covered. Animal/kernel share
one nonidentity covariance challenge. Sparse precision, tree/pedigree, spatial,
unique companions, slopes/masks/known covariance, other families, rank ranges,
fitting/postfit/inference/recovery and public interfaces remain required.

## 11. Team Learning
Noether requested native gpt-5.6-terra/high, fresh context, one review and one
repair followup. He confirmed pointwise formulas and transformations, required
the identifiability qualifications, and found the retained-matrix verification
gap. Parent repaired and tested that final gap; no further independent rereview
or Rose programme signoff is claimed. Report measured command time only, not
invented actual model-hours. Ask-brain all-project retrieval returned no current
mode contract; pinned repository source supplied the technical evidence.

## 12. Cross-Product Coverage
Exactly3sources x3modes x2fixed parameter vectors. This slice does NOT cover
native fitted covariance modes, formula or bridge interfaces, source/rank/family
Cartesian products, identifiable variance recovery or interval calibration.
Independent and common coordinates must not be called latent rank-one models.
