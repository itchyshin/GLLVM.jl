# Issue Action Map: Full-Finish Governance

Date: 2026-06-14

This file is the staging map for GitHub issue updates. It does not mutate
GitHub by itself. Use it to update issues deliberately, with one comment or
issue edit per narrow slice.

## Rules For Remote Issue Updates

Each issue update must state:

1. current status: `covered`, `partial`, `experimental`, `planned`, or
   `unsupported`;
2. owning role;
3. source files;
4. R bridge route or deliberate rejection;
5. CI/status support;
6. visual/doc requirement;
7. tests required;
8. claim boundary;
9. dashboard row;
10. after-task path.

Do not close broad stale issues until a narrower successor exists and is linked.

## GLLVM.jl

| Issue/PR | Action | Owner | Status | Claim boundary |
| --- | --- | --- | --- | --- |
| PR #95 | Maintainer gate | Grace/Shannon | partial | Green draft integration-to-main PR; do not merge from this slice. |
| PR #94 | Audit unique content | Shannon/Rose | blocked | Do not close until `genpoisson`, `studentt`, `truncnb`, `truncpoisson`, `anova.jl`, and `diagnostics.jl` are folded or explicitly deferred. |
| #98 | Rewrite as per-response family dispatch gate | Boole/Noether/Hopper | planned | Homogeneous vector must equal single-family fit exactly before mixed support. |
| #97 | Keep maintainer-gated REML issue | Fisher/Noether | planned | No REML/AI-REML wording for non-Gaussian Laplace without derivation and variance-component gates. |
| #96 | Regression-first mode-finder hardening | Gauss/Karpinski | local-fix | Backtracking and zero-restart safeguards are implemented locally with full `Pkg.test()` green; issue/PR reconciliation still required. |
| #92 | Phylo-signal CI scale/export/test | Fisher/Gauss | blocked | Derived Wald scale transforms must be tested and wired into the main suite. |
| #91 | High-rate Poisson divergence | Gauss/Curie | blocked | Add failing regression first; gate on finite logLik and sane beta/loadings. |
| #65 | Analytic gradient default/speed | Karpinski/Gauss | partial | No default flip unless faster across grid and logLik delta <= 1e-6; Gamma remains separately gated. |
| #61 | Sparse phylo gradient/Takahashi | Gauss/Karpinski | experimental | Wire O(p) only where equality to reference gradient is verified. |
| #62 | Shared SPDE/kernel substrate | Jason/Gauss | planned | Requires provenance/license, PSD/name alignment, prediction, CI status, and visuals. |
| #27 | Missing-data FIML/EM | Curie/Hopper/Fisher | partial | Mask data terms only; all-true mask equals complete logLik exactly; no mean-imputation claim. |
| #10 | R bridge broad goal | Hopper/Shannon | partial | Replace broad bridge claim with narrow bridge-fit, CI, missingness, and post-fit issues after #95/#94 are reconciled. |

## gllvmTMB

| Issue | Action | Owner | Status | Claim boundary |
| --- | --- | --- | --- | --- |
| #488 | First bridge drift implementation issue | Hopper/Emmy | partial | R gate must not silently lag GLLVM capability; current local GLLVM branch now has a tested minimal no-X `bridge_fit`, but the live gllvmTMB route, X gate, missing masks, metadata, and S3 surface remain open. |
| #486 | CRAN checklist | Grace/Rose | partial | Do not call CRAN-ready while pkgdown/latest workflow and NEWS/changelog drift remain open. |
| #485 | NEWS bridge wording | Pat/Rose | partial | Fix Gaussian-only X wording and avoid selectable-Julia-algorithm claims. |
| #484 | cran-comments | Grace | partial | Already partly handled by #487; verify against current main before closing. |
| #483 | NAMESPACE/man exports | Grace/Hopper | partial | Verify `confint`, `logLik`, `print`, and future post-fit methods on `gllvmTMB_julia`. |
| #437 | Cloud handover | Ada/Shannon | planned | Close or supersede only after this issue action map is linked. |
| #361 | Kernel/co-evolution | Gauss/Jason | planned | Preserve C0-C5 serialized gates; no API promotion before evidence. |
| #340 | Capability matrix drift | Rose/Pat | blocked | Sync with `docs/dev-log/capability-bridge-matrix.md`. |
| #332/#335-338 | Missing-data bridge | Curie/Hopper | planned | Response masks, predictor `mi()`, mixed missingness, and diagnostics need separate acceptance gates. |

## Cross-Team Tracking

| Repo | Issue(s) | Import | GLLVM action |
| --- | --- | --- | --- |
| DRM.jl | #165, #227 | exact implicit gradients and speed/accuracy guardrails | Add GLLVM speed+CI protocol before public speed claims. |
| DRM.jl | #280 | per-response-column family dispatch | Align with GLLVM #98. |
| DRM.jl | #49 | missing-response FIML/EM | Align with GLLVM #27 response-mask semantics. |
| DRM.jl | #270, #269 | kernel/SPDE/Pagel lambda | Keep structural dependency rows split by engine/bridge/CI/visual status. |
| drmTMB | #544 | bridge gate drift | Port to gllvmTMB #488 as CI gate. |
| HSquared/hsquared | #6, #7, #9, #10 | bridge contract, validation canon, status diagnostics, AI-REML boundary | Use status vocabulary and reject non-Gaussian AI-REML wording. |

## First Remote Update Batch

Do this only after maintainer approval for GitHub mutations:

1. Comment on GLLVM #96/#91/#92 with the Phase 4 evidence and remaining
   acceptance gates.
2. Comment on GLLVM #98 with the per-response dispatch acceptance ladder.
3. Comment on gllvmTMB #488 with the Hopper bridge audit: minimal no-X
   `bridge_fit` now exists on this local branch; X-gate drift, missing masks,
   metadata, and S3 surface remain open.
4. Comment on gllvmTMB #340 linking the capability/bridge matrix.
5. Comment on cross-project #13 or equivalent with the DRM/HSquared imported
   lessons.
