# Public bridge runtime checkpoint

## 1. Goal
Qualify the frozen R public setup route on Totoro before comparing models, and
verify the user's restored DRAC connections without submitting compute.

## 2. Implemented
A no-install R qualification script calls JuliaCall setup with installation
disabled, then exported gllvm_julia_setup. It asserts the loaded candidate path,
one Julia/BLAS thread, numeric roundtrip, deliberate exception and recovery.
Dependency snapshots record installed JuliaCall files, Julia and libunwind bytes.

## 3a. Decisions and Rejected Alternatives
Keep the parent R libunwind preload but clear inherited LD_PRELOAD before
JuliaCall constructs its child environment. Do not edit the shared JuliaCall
installation or the frozen R package. Version strings alone do not identify the
locally patched JuliaCall installation; record actual file hashes.

## 4. Files Touched
tools/core070_bridge_runtime.R, core070_bridge_dependencies.py and
core070_verify_bridge_runtime.py; evidence, this report, check-log and checkpoint.
Mission Control receives only a guarded Julia fragment correction.

## 5. Checks Run
Runtime03: oracle checks before/after exit0; runtime exit0 in13.492930343s on
Totoro, R4.5.3/Julia1.12.6/JuliaCall0.17.6. Dependency manifests match before and
after. Source, process, log and scalar receipt bindings pass local verification.
All eight DRAC logins respond and their user queues are empty at17:22UTC;
Killarney's scheduler requires a login shell. Totoro responds. No job submitted.

## 6. Tests of the Tests
Ten corrupted receipts reject failed/nonzero/incomplete processes, changed
source state, wrong source path, wrong roundtrip, excess threads, missing
exception and missing/changed dependency inventories. Unlazy runtime gate passes;
the distinct model gate remains unpaid (1/2 met, expected aggregate exit1).

## 7a. Issue Ledger
Next: executable frozen public bridge admission/rejection tests, then admitted
Poisson/Beta/NB2 same-model replay. No public bridge model fits ran in this slice.
Retain existing full-suite and specific external-review approval boundaries.

## 8. Consistency Audit
Frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86 remains unchanged. Its
R/julia-bridge.R family switch rejects truncatedNB2 (GJL-GATE-FAMILY); its
.gllvmTMB_julia_dispatch drops auto-emitted unique Gaussian Psi with a warning.
Explicit diagonal terms reject. These are source-inspection findings pending
executable boundary evidence, not permission to promote altered-model fits.
They qualify the earlier blanket statement that all five models need successful
same-model public bridge fits. The full manifest remains draft and unpromoted.

## 9. What Did Not Go Smoothly
Runtime01 failed before setup because the installed JuliaCall patch joined two
LD_PRELOAD paths with an unquoted space. The shell treated the second path as a
command (status139). Runtime02 passed the scoped workaround; runtime03 adds
dependency provenance. Both earlier attempts remain retained. Killarney initially
returned squeue-not-found; login-shell follow-up succeeded without a new login.

## 10. Known Residuals
This is an operational runtime qualification on one installed environment.
No model, inference, recovery, full-suite, performance or portable-install claim.
No independent numerical review or Rose completion panel ran; programme NOT DONE.

## 11. Team Learning
Ada parent performed this bounded slice; no child or agent-hour receipt invented.
Distinguish an embedding startup fault from a model fault, and installed package
version from exact bytes. Distinguish authenticated login from compute allocation.

## 12. Cross-Product Coverage
This does NOT cover public bridge same-model parity, all response families,
covariance/modifiers/data/postfit, complete Stage1a AGHQ, recovery/coverage,
performance, full package checks or final Documenter polish. R0.7.1, article and
foreign checkouts remain untouched. No push, merge, release, destructive cleanup
or DRAC allocation. All launched checks terminated; resume from the checkpoint.
