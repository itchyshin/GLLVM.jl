# Original Student public nlminb warm-start diagnostic

## 1. Goal
Test whether the existing fixed-df warm fit followed by public nlminb can satisfy
the unchanged original Student-t case. This is a diagnostic, not a new estimator.

## 2. Implemented
A separate diagnostic preserves the existing script and changes only the final
public optimizer from BFGS to nlminb, with predeclared controls. Dedicated verifier
reconstructs13 checks, reads serialized full R fits and checks archived/current
source pins, process exits, oracle checks and the earlier failures.

## 3a. Decisions and Rejected Alternatives
Keep seed71,p5,K1,n130, all20 final free parameters, scale/df estimation,
original TMB data/map and native400iteration fit. Fixed warm df initializes only;
it is not substituted for the final model. No degrees-of-freedom bound, ridge,
fixture replacement, R engine change or tolerance relaxation. Reject close
likelihood alone as a health certificate. Do not repeat these exact tested paths.

## 4. Files Touched
New tools/core070_student_nlminb_warmstart.jl and dedicated Python verifier;
leaf/evidence/after-task/check-log/checkpoint. Old diagnostic and production
likelihood files remain unchanged. Raw source snapshots and full fits ignored.

## 5. Checks Run
Totoro attempt02 ran26.77319s, within1–3minute estimate and300second cap,
one Julia/BLAS thread. Oracle before/after exit0; diagnostic exit1. Ten checks
pass and three fail: R optimizer code, R raw gradient and same-point density.
Absolute likelihood difference1.31578e-7 passes the required0.001 gate.
R gradient3.49241e-4 exceeds1e-4; native gradient6.17704e-6 passes.
R code1 reports false convergence(8). Same-point difference3.13728e-6 exceeds
1e-6. Source-preserving complete-fit readback passes. The historical BFGS
failure is verified against its archived source, not relabeled current evidence.

## 6. Tests of the Tests
Seventeen report mutations reject false check values, missing checks/coordinates
and altered gradient/difference summaries. Independent base-R deserialization
compares original/warm/final numerical fields and exact data/map/parameter names.
Unlazy evidence gate passes; health gate exits1 as required. Full programme is
also unpaid:1/3 gates met. No numerical pass token is printed on failed health.

## 7a. Issue Ledger
Original Student health remains unpaid. The tested public nlminb continuation
improves some numbers but does not resolve the frozen-reference boundary behavior.
First-trait df reaches2.99998e7; earlier same-point density diagnosis remains
relevant. This run alone does not prove every public optimizer or initialization
must fail. Additional Student well-identified and near-Gaussian coverage remains
required, without replacing the original case. Continue unaffected Core/AGHQ work.

## 8. Consistency Audit
All prior original-fixture attempts retained. Production source, original data,
final model and accepted tolerances unchanged. No new manifest binding or family
promotion. Full manifest remains DRAFT and M1 PARTIAL. Current environment is
the already-qualified parity Manifest with SHA cd19b802f10ae034c264af7e75ec17ec508fde770221e6747d1cd6d6c013f19e.

## 9. What Did Not Go Smoothly
Attempt01 reused an obsolete Manifest and failed before fitting because GLLVM's
SHA dependency was absent. Retained exit1 and source snapshot; attempt02 changed
only to the already-qualified current environment, without installing packages.
The old BFGS verifier correctly rejects current-source use after unrelated
postfit edits; archived-source plus full-fit readback verifies its historical
failure. Do not infer that source-pinning checks are broken when they catch drift.

## 10. Known Residuals
No Student health completion, independent numerical review or Rose sign-off.
Full package and specific external numerical-review permissions remain unchanged.
Mission Control4e9a647bf48b3c47c9bd9619023741107b264df0 served HTTP200, R fields
unchanged. No new remaining-hours estimate. Runtime handles are terminal.

## 11. Team Learning
Ada executed a bounded discriminating check and raw-evidence validation; no new
child or external numerical review was dispatched. Model/effort billing and
agent-hours were not fabricated. Recall current qualified environments when
reusing old launchers; preserve old failures without treating them as current.

## 12. Cross-Product Coverage
This does NOT cover full Student family parity, healthy original Student fit,
remaining covariance/multinomial/data/postfit/AGHQ, recovery/coverage, performance,
full package checks or final Documenter. R0.7.1/article/foreign lanes untouched.
No push, merge, release, cleanup or DRAC submission. ACTIVE/M1 PARTIAL.
