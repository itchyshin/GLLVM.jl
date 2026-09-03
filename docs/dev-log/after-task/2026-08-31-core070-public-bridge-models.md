# Original public R bridge model checkpoint

## 1. Goal
Exercise the original Poisson, Beta and NB2 models through the frozen public R
bridge, preserve model identity, and test actual reference rejections.

## 2. Implemented
R matrix and reversed-long formula entry points compared with fresh default
native Julia fits on the original fixtures. Checked likelihood, intercepts,
rotation-invariant loading covariance, dispersion, dimensions and parameter count.
Finite-difference gradients at two steps check native fit health. No engine edits.

## 3a. Decisions and Rejected Alternatives
Retain the existing frozen-R fit policies and their raw evidence. Reverify those
receipts before using their likelihoods; label them historical, not newly fitted
in this batch. Do not manufacture a same-model bridge obligation for a combination
the reference rejects. Do not silently weaken a check because serialization fails.

## 4. Files Touched
tools/core070_bridge_models.R/.jl, core070_bridge_receipt.R,
test_core070_bridge_receipt.R and core070_verify_bridge_models.py; evidence,
check-log, checkpoint and this report. Julia source and frozen R remain unchanged.

## 5. Checks Run
Second Totoro batch passes58.7983s with one Julia/BLAS thread. Six public fits:
likelihood and intercept differences from fresh native fits exactly zero;
loading covariance differences<=5.56e-17; dispersion differences zero.
Native gradients<=7.37e-6 and finite-difference step differences<=5.17e-8.
Parameter counts14/15/19; shapes, links, AIC and observation counts checked.
Frozen oracle checks before/after pass. Retained R likelihood differences are
approximately1.43e-11 (Poisson),1.78e-11 (Beta),3.413e-6 (NB2).
Two public requests reject: truncatedNB2 family and explicit diagonal terms.

## 6. Tests of the Tests
Ten corrupted reports reject omitted models, bridge errors, failed convergence,
wrong parameter counts, unhealthy gradient, altered likelihood/loading/link,
omitted health assertion and a missing required rejection. Serializer regression
reproduces unsupported JuliaNamedTuple, preserves numeric matrix shape after
conversion, and rejects empty/missing/false/NA assertion values. Unlazy2/3 gates
verified; full programme remains unpaid. The prior ten-case native/formula
verifier also passes against its retained raw R evidence and current source.

## 7a. Issue Ledger
Public bridge results are a qualified subset, not yet registered required-case
receipts. Next bind their stable planned IDs into the manifest/harness and test
default-unique Gaussian warning semantics explicitly. Full-family coverage still
requires every admitted variant and surface, not just these three fixtures.

## 8. Consistency Audit
R bridge uses per-trait Beta precision and NB2 size, matching these native routes.
Native fit controls are bridge defaults; Beta's previous tighter native controls
are not silently claimed here. Each fresh default native fit passes its own health
check. Link labels are the engine's LogLink/LogitLink type names, explicitly
consumed by the frozen R wrapper. Do not compare rotationally arbitrary loadings.

## 9. What Did Not Go Smoothly
First batch58.49s passed model comparisons but failed JSON serialization of a
JuliaNamedTuple. Full RDS results survived. Repair removes transport-only classes
for JSON while retaining full raw RDS, then reruns the entire batch. Independent
readback initially expected log/logit labels; source showed LogLink/LogitLink.
Corrected the verifier and added a wrong-link negative control, not an API change.

## 10. Known Residuals
No new R fits, independent completion panel, full package suite, recovery,
coverage or performance evidence in this slice. Full-suite and specific external
review approvals remain pending. Rose verdict not requested for this interim
checkpoint; programme NOT DONE. No measured-hours claim invented.

## 11. Team Learning
Ada parent performed this slice. No child dispatch or model/effort receipt
invented. Save full attempts before reporting; distinguish numeric success from
successful evidence collection, and model identity from payload representation.

## 12. Cross-Product Coverage
This does NOT cover default-unique Gaussian bridge behavior, full family/link
coverage, covariance/modifiers, missing data, post-fit/inference, all Stage1a
AGHQ, recovery/coverage, measured performance or final Documenter polish.
R0.7.1 and article lanes are untouched. No push, merge, release, destructive
cleanup or DRAC submission. Processes terminal; continue from the checkpoint.
