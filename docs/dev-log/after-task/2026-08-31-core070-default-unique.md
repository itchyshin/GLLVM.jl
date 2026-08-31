# Gaussian fixed-residual / unique-variance native checkpoint

## 1. Goal
Match the original R default-unique Gaussian model without substituting Julia's
has_diag model. Programme remains M1 PARTIAL, manifest DRAFT_NOT_FROZEN.

## 2. Implemented
Explicit fixed_residual_sd on the per-variance fitter. Optimize positive unique
variances inside total covariance, retain psi2 and total phi2 separately, preserve
old default and six-argument fit construction. Fixed scale adds no free parameter.
Registered new tests and updated docstrings, tutorial/reference, README/changelogs.

## 3a. Decisions and Rejected Alternatives
Math contract preceded code. R's row-level unique effects fix residual SD rather
than estimate another diagonal. Use exact Cholesky GLS and L-BFGS for positive
fixed scale; keep original EM/default route at zero. Do not subtract a fixed
variance after unconstrained fitting or silently choose the data-dependent R scale.
Reference b4d5fee64def88bc768dda1f1f77c29b295edd86, original seed81031 data retained.

## 4. Files Touched
src/families/gaussian_pervar.jl; test/test_gaussian_fixed_residual.jl and central
runner; two reproducible pairing helpers in tools; math/leaf/evidence/visual reports;
response-families/tutorial/README/changelogs, check-log/LOOP/full-run plan.
Mission Control changed only the Julia next-action fragment, commit3e53d55.

## 5. Checks Run
Baseline unsupported-keyword error observed before implementation. Corrected test
red replay24.18s; green23new+41adjacent assertions49.30s. Original R pair10/10 in25.41s:
deltaLL3.864101927e-9 <=1e-3; native gradient1.542e-10,R4.4453e-5, both converged.
Independent-point NLLdelta3.975e-9,gradientdelta2.477e-8; both endpoint cross-evaluations
below1e-6. Current-source Aqua/JET12/12 in106.85s, jointsubset217/217 in54.55s;
setup3.52s. Strict docs131.47s, executed example assertions pass. Desktop/mobile
output inspected; all launched jobs/browsers terminal. No full-suite claim.

## 6. Tests of the Tests
Six semantic corruptions reject false health, excess LL/gradient differences,
wrong random blocks/parameter counts and wrong unique/total decomposition.
Verifier binds original fixture, baseline/new source, test bytes and process/log
hashes. Baseline and green final regressions have identical bytes. Previous
quality assertion counts overlap reruns and are not summed as independent tests.

## 7a. Issue Ledger
Direct native parameter contract now has paired evidence for this one fixture.
Formula/bridge/AGHQ-fallback metadata, inference/recovery and full suites remain.
Independent Noether review was blocked by the safety gate over code transmission;
specific three-file Terra payload approval requested, no alternate dispatch tried.

## 8. Consistency Audit
phi2 remains total diagonal variance for existing consumers; psi2 stores the
unique component without subtraction. Eight free coordinates match R. Raw loading
and unique log-SD names verified from frozen theta_rr_B/theta_diag_B declarations;
log-variance transform is twice log-SD. No R engine or has_diag changes. Native
counterexample uses a sizable fixed SD so silently ignoring it fails the test.

## 9. What Did Not Go Smoothly
First green test reached8 passes then an unqualified non-exported packing helper;
qualified both helpers and replayed baseline/green. R attempts1/2 stopped before
fitting for missing cached StructUtils/provenance files. Attempt3 rejected guessed
parameter names; frozen C++ declarations established correct names. All failures
retained; no fixture/model/tolerance change. Initial browser output selector was
wrong; corrected against generated HTML, retained failure. Existing branding,
package-json/bundle and local-version-metadata warnings remain.

## 10. Known Residuals
Fullsuite plan now points to current-source qualification, not the earlier source.
Two full runs still await the required over30minute approval. Independent review
also awaits explicit code-sharing approval. Remaining families/covariance/data/
postfit/bridge/AGHQ and manifest remain substantial; no revised hours forecast.

## 11. Team Learning
Parent implemented/tested this slice. Requested Noether Terra/high dispatch was
rejected before execution: no model/effort/hours receipt or review verdict invented.
Fixed-point model equivalence and healthy fitted equivalence are separate checks;
both are required, neither establishes calibration or all-interface support.

## 12. Cross-Product Coverage
This checkpoint does NOT cover formula/bridge exposure, AGHQ fallback reporting,
intervals, recovery, other grouping/rank/family combinations, full package checks,
all-kernel JET, broad performance or complete Documenter polish. No push, merge,
release or destructive cleanup. Rose verdict: NOT REQUESTED; interim candidate.
