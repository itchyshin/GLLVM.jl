# Gaussian covariance modes: retained defaults and qualified explicit controls

## 1. Goal
Qualify the seven remaining ordinary/animal/known-kernel Gaussian covariance
mode shapes using actual frozen-R and native fits, without changing the engine.

## 2. Implemented
Separate declared full-rank fitting fixture, required RCall runner, independent
serialized-fit/dense-Gaussian readback and executable acceptance verifier. Native
source fitting uses independent default starts and the declared source matrix.

## 3a. Decisions and Rejected Alternatives
Preserve the old sine-data pointwise fixture. It has centered trait rank2 and
is unsuitable as a healthy ordinary full-rank fit oracle. New FIT-MODE IDs use
fixed seeds and an uncentered known DGP, without selecting successful seeds.
Compare only identifiable total covariance for ORD-DEP. Do not require a
positive Hessian or claim separate source/residual identification there.

## 4. Files Touched
New covariance_fits.R fixture; paired Julia driver, structure checker, R readback,
Python verifier; developer contract/leaf/evidence and scope links. Check log and
LOOP checkpoint updated. No source engine, original fixture, public API, README,
dependency, version, R source or foreign lane changes.

## 5. Checks Run
Default run35.64s:164pass/5fail assertions, four cases pass and three DEP cases
fail R gradient (2.74e-4/2.48e-4 >1e-4); structured DEP also fails covariance.
Predeclared follow-up tightens only public R stopping controls; all prepared
data/maps/free names match baseline. Follow-up34.24s:176/176 pass, all7cases,
max absolute likelihood difference7.44649e-12. Max R gradient2.43503e-5;
max Julia gradient8.10798e-8. Both runs one Totoro thread, below estimate/cap,
oracle before/after PASS. Raw readback verifies all14 fits. Unlazy1/2; full
programme gate unpaid. Exact receipts are covariance-mode-fits-evidence.json.

## 6. Tests of the Tests
Missing receipt fails before execution. Sixty-three damaged case records and
five aggregate mutations fail: omitted IDs, wrong source, missing receipt,
nonzero exit and stale source state. Independent R recomputes normalized Gaussian
objectives from saved data, maps and parameters; responses match TOML exactly.

## 7a. Issue Ledger
Default-control DEP health failures are retained, not relabelled as passing.
The new result is explicit-control fitted agreement only. Original Student health,
remaining Core/AGHQ, multinomial/data/postfit, covariance modifiers, formula/bridge,
recovery/inference, final package runs and completion panels remain unpaid.

## 8. Consistency Audit
Historical pointwise/fixed-residual contracts now link to the new qualification.
Original data and all src files remain unchanged. Full manifest stays draft;
the subset does not promote broad covariance grammar obligations. Public docs
and performance claims are unchanged. JET/Allocs/Aqua: not rerun, no engine or
dependency change. Benchmarks: N/A, timings describe qualification runs only.

## 9. What Did Not Go Smoothly
Review caught observation-versus-site group-vector length before fitting and
fixed the runner to verify within-site agreement. Native uses the declared exact
source matrix, avoiding numerical inverse asymmetry from R readback. A reviewer
orientation concern was disproved by direct trait/site indexing. Local readback
initially demanded bit equality of Linux/macOS matrix products; replaced that
with exact saved-value comparison plus independent covariance reconstruction
at1e-12. No fitted acceptance tolerance changed. All failed attempts/logs retained.

## 10. Known Residuals
Ordinary source/residual decomposition remains nonidentified despite numerical
optimizer/Hessian outputs. Same-mode animal/kernel data are shared deliberately;
they are two interface routes, not independent recovery replicates. No full suite
or strict Documenter run this slice because only development evidence changed.
Fullsuite/specific external numerical-review approval boundaries unchanged.

## 11. Team Learning
Hopper requested Terra/high native fresh-context worker, one bounded harness
and one repair follow-up. Ada owned fixture, contract, launcher, independent
verifier and reconciliation. Requested model/effort is not a billing receipt;
no agent-hour total invented. Rose completion panel not run; no programme
sign-off. Mission Control3cc32491f1415302b2843370ffa9ba434096b405 is limited to the Julia next-action fragment; served HTTP200, R fields unchanged.

## 12. Cross-Product Coverage
This does NOT cover full R0.7.0 Core/AGHQ parity, default-control health for all
cases, general covariance support, recovery/coverage, intervals, formula/bridge,
performance or final documentation. No DRAC job, push, merge, release or cleanup.
R0.7.1 and article lanes untouched. Programme ACTIVE/M1 PARTIAL.

Rose verdict: NOT RUN — M1 completion panel remains required; no completion claim.
