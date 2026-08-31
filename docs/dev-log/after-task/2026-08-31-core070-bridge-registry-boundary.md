# Public bridge registry and Gaussian boundary checkpoint

## 1. Goal
Bind supported public bridge models to required case IDs and verify the frozen
Gaussian default-unique warning on the original fixture.

## 2. Implemented
Three-case public R bridge subcontract frozen before replay; runner requires
all three IDs and records requested/completed IDs. Generated family plan links
these to a separate required R runner. Added Gaussian boundary fixture/verifier.

## 3a. Decisions and Rejected Alternatives
Do not put R/JuliaCall tests inside the Julia/RCall process. Keep separate runtime
receipts and connect them through the eventual aggregate verifier. Do not count
reference-rejected or model-changing combinations as successful same-model fits.
No blanket weakening of the full-family checker: admission-aware aggregation
still needs implementation and review.

## 4. Files Touched
Bridge model runner/verifier, family-case plan generator and generated plan,
public-bridge-required-cases.json, Gaussian boundary runner/verifier, evidence,
check-log and checkpoint. No Julia engine or R reference changes.

## 5. Checks Run
Totoro Gaussian boundary40.7139s; three-case registered bridge replay58.7913s,
one Julia/BLAS thread. Oracle before/after checks pass. Default Gaussian unique
request warns and yields exactly the same reduced fit as explicit unique=false:
zero means, common residual scale, five parameters rather than the original
eight-parameter fixed-residual unique model. Three bridge IDs cover six public
Poisson/Beta/NB2 fits, with the previous numerical gates unchanged and passing.

## 6. Tests of the Tests
Twelve bridge corruptions reject, including omitted/unknown required IDs. Five
Gaussian corruptions reject missing warning, incorrect parameter count, changed
likelihood/covariance and false parity scope. Existing interface and family
coverage tests pass; full-family promotion still fails when required evidence is
missing. Unlazy4/5 gates pass; full programme remains unpaid.

## 7a. Issue Ledger
Connect separate public R receipts to the final aggregate gate. Model-specific
reference admission must replace the current blanket bridge requirement for
every native family combination; Gaussian and truncated NB2 now have concrete
counterexamples. Other reference variants remain to inspect and test.

## 8. Consistency Audit
Family plan remains97 cases over69 descriptor facts. It now has5 native,
5 formula,3 separate public R and16 boundary bindings. Central source-to-executable
mapping remains10 links over5 partially covered family facts; not13 fully
integrated links. No full-family or complete-programme promotion. Full manifest
remains DRAFT_INCOMPLETE_NOT_FROZEN.

## 9. What Did Not Go Smoothly
The plan generator's previous26-bound-case assertion rejected the three new
separate bridge bindings. Updated it to29 and required the exact three IDs and
separate-runner status. No model test failed in this slice. Historical bridge
receipts remain retained; the new frozen-ID replay supersedes their registration
status without pretending they carried those IDs originally.

## 10. Known Residuals
Full suites and specific external numerical review still await their existing
approvals. No independent completion panel ran. Historical R model fits were
reverified, not rerun in the public bridge batch. No new hours estimate.

## 11. Team Learning
Ada parent performed this slice. Case IDs must be emitted by execution, not
inferred only from a later report. Reference capability boundaries can differ
between its native engine and bridge; each needs its own acceptance semantics.

## 12. Cross-Product Coverage
This does NOT cover final aggregate integration, complete family/link/covariance/
modifier/data/postfit/inference/AGHQ contracts, recovery/coverage, performance,
full package checks or final Documenter polish. R0.7.1 and article lanes untouched.
No push, merge, release, cleanup or DRAC submission. All checks terminal;
programme ACTIVE/M1 PARTIAL. Continue from the checkpoint.
