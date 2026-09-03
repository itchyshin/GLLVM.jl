# Binomial curvature diagnosis and public-control qualification

## 1. Goal
Resolve the remaining same-model reference health failures through a diagnosed public control path, preserving all original results.

## 2. Implemented
Retained-point curvature and fixed-step diagnostic; explicit singular-tolerance public refinement; one conditional public BFGS continuation. Added pre-run policies, runners, provenance and mathematical verifiers, result tables and honest catalogue updates. No numerical engine or R source edit.

## 3a. Decisions and Rejected Alternatives
Reject singular-model inference from an optimizer message. Do not reduce relative tolerance blindly: pinned R stores singular tolerance separately. Preserve complete fits and original default failures. Diagnostic Newton points are not fitted objects; only actual public-fit receipts qualify. BFGS continuation used only for the remaining healthy-gradient/nonzero-code case.

## 4. Files Touched
Curvature/singular/BFGS runners, verifiers, policies and immutable summaries; qualification report; binomial packet/catalogue; check-log and LOOP. R0.7.1/article lanes and Julia source unchanged.

## 5. Checks Run
Totoro curvature83.36s, singular-tolerance76.15s and one-case continuation12.60s, all bounded. All six final whole R fits code0/rawgradient≤1e-4 and matching likelihoods at unchanged rtol1e-6; maximum absolute delta6.83e-11. All source/runtime/fixture/process/oracle checks pass. Matrix algebra independently recomputed locally; seven matrix assertions, five whole-fit negatives and three bundle negatives pass. Native fits reused only at identical source/runtime pins.

## 6. Tests of the Tests
Matrix controls reject wrong dimensions, eigenvalues, steps, predicted decrease, stability and omitted grid points. Whole-fit controls reject mixed or false health records. Final bundle controls reject default-health promotion, omitted case and corrupt artifact hash. Historical failed aggregate remains nonzero.

## 7a. Issue Ledger
Qualified direct K1 binomial comparisons6of6; original baseline1of6 unchanged. Relative-only and singular-only failures remain retained. Full manifest, independent review, Student/truncated-NB2 health, older K2 binomial smoke, other required family cases and interfaces remain unpaid.

## 8. Consistency Audit
Six original fixtures and acceptance gates unchanged. The last one-case continuation exactly reproduces the preceding three PORT attempts. No conditional selection on likelihood agreement; each complete fit must pass independently. Catalogue remains PARTIAL for wider obligations rather than promoting scoped evidence to full support.

## 9. What Did Not Go Smoothly
Local NumPy was unavailable, so the independent matrix verifier uses the available Julia stdlib without installing dependencies. Explicit singular tolerance repaired two cases but left probit/varying code1 despite a passing gradient; retained that failure before a separately predeclared public BFGS continuation. An initial progress statement omitted the need to replay original fits to rebuild R objectives; corrected before execution.

## 10. Known Residuals
No full package tests, recovery/coverage, bridge, formula, current Documenter render or independent completion panel in this slice. No policy claim beyond the six predeclared models; the final BFGS fallback was tested on one case. Original defaults remain failed. Further adoption into the required manifest needs its pending review, without erasing default evidence.

## 11. Team Learning
Optimizer tolerance names can hide independent internal controls. Inspect effective values rather than assuming one tolerance updates another. Positive curvature and same-point Newton diagnosis separated a solver stopping issue from model indefiniteness without a ridge or tolerance-gate relaxation.

## 12. Cross-Product Coverage
This does NOT cover full Core/AGHQ, default cloglog Fisher equivalence, R0.7.1/article work, fitted inference/recovery, performance or release. Rose NOT RUN; M1 PARTIAL. No new child dispatch, push, merge or cleanup.
