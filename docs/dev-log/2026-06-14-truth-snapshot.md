# Truth Snapshot: Full-Finish Restart

Date: 2026-06-14

This snapshot records the state used to restart the GLLVM.jl + gllvmTMB
full-finish plan. It is a local operating snapshot, not a release claim.

## Local Repositories

| Repository | Path | Branch | Head | Dirty | Notes |
| --- | --- | --- | --- | --- | --- |
| GLLVM.jl board worktree | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` | `codex/non-gaussian-fitter-gradients` | `6d8e158` | yes | Local dashboard, minimal `bridge_fit`, #92 scale fix, #96 mode-finder safeguard, and `bench/results/` are untracked/dirty. This is not the clean integration branch. |
| GLLVM.jl integration | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration` | `integration` | `65a1f10` | no | Integration contains PR #100 full-capability merge. PR #95 head is green on CI + Documenter, mergeable, and still draft/maintainer-gated. |
| gllvmTMB | `/Users/z3437171/Dropbox/Github Local/gllvmTMB` | `engine-julia` | `f046d0f` | no | Branch is ahead of remote `engine-julia` at `7a7e209` by four commits. Local `f046d0f` has no remote CI because it is unpushed. Rebuild a PR from current `origin/main`; do not push this branch as-is. |
| drmTMB | `/Users/z3437171/Dropbox/Github Local/drmTMB` | detached HEAD | `b4a4d7be` | yes | User-owned dirty Phase 18 / bridge / simulation work. Use read-only for cross-team lessons. |
| DRM.jl | `/Users/z3437171/Dropbox/Github Local/DRM.jl` | `shannon/ayumi-integration` | `23d8f79` | yes | User-owned dirty finish-audit files. Use read-only for bridge-drift and profile-CI lessons. |
| hsquared | `/Users/z3437171/Dropbox/Github Local/hsquared` | `main` | `3666363` | no | Clean R twin. Use capability-status and validation-debt patterns. |
| HSquared.jl | `/Users/z3437171/Dropbox/Github Local/HSquared.jl` | `codex/phase5-marker-region-data` | `2317133` | yes | User-owned dirty marker-region slice. Use AI-REML boundary language and diagnostics patterns, not algorithm claims. |

## Current Gates

1. GLLVM.jl #95 must not be merged to `main` until maintainer approval and
   current CI/docs truth are reconfirmed.
2. GLLVM.jl #94 must not be closed until unique content is accounted for:
   `genpoisson`, `studentt`, `truncnb`, `truncpoisson`, `anova.jl`, and
   `diagnostics.jl`. The PR is currently draft, diverged/non-mergeable, and has
   no visible check-runs for its exact head.
3. gllvmTMB `engine-julia` must be rebuilt from current `origin/main`.
   Cherry-pick bridge-only commits, especially `confint.gllvmTMB_julia` and
   the #488 X-gate fix. Do not replay stale `NEWS`, `cran-comments`, or man
   edits already merged by #487.
4. Release/tag/CRAN/registry work is blocked until the issue ledger, dashboard,
   docs, bridge parity, CI, and Rose audit agree.
5. The current local `GLLVM.jl` checkout now exposes a deliberately narrow
   `GLLVM.bridge_fit` for no-covariate one-part families. It passed
   `test/test_bridge_fit.jl` 175/175 on 2026-06-14. The R bridge still cannot
   be called complete until `gllvmTMB` live roundtrip tests, X support,
   missing-response masks, mixed-family metadata, and post-fit methods are
   reconciled.

## Live GitHub Snapshot

- `itchyshin/GLLVM.jl`: 2 open PRs and 18 open issues. Key PRs are #94
  (draft, non-mergeable) and #95 (draft, mergeable, green on latest CI +
  Documenter). Key issues for the finish plan include #98, #97, #96, #92, #91,
  #65, and #61.
- `itchyshin/gllvmTMB`: 0 open PRs and 26 open issues. Key issues include
  #488, #486, #485, #484, #483, #437, #361, #349, #344, and #343. Latest main
  has mixed workflow state: full check and R CMD check were green on recent
  runs, while a pkgdown run failed and scheduled power-pilot runs are noisy.

## Immediate Implementation Order

1. Dashboard and matrix: make the plan visible and evidence-linked.
2. Issue ledger: map every row to an issue before closing stale umbrellas.
3. Core blockers: #91 high-rate Poisson remains open. #96 mode-finder
   safeguards and #92 phylo-signal transformed-Wald scale are fixed locally on
   this branch and await issue/PR reconciliation.
4. gllvmTMB bridge drift: reconcile the R package against the tested minimal
   `bridge_fit` payload, then implement a gate-vs-engine test for #488.
5. Missing-response bridge: mask data terms only, preserve latent/structure
   priors, and prove complete-mask equality.
6. Speed and CI benchmark protocol: no speed claim without point estimates,
   objective/logLik, gradients where relevant, CI/status, and timing metadata.

## Rose Boundary

This snapshot may be used for planning and dashboard state. It is not evidence
that the packages are release-ready. The live rule remains:

> A capability is done only when engine support, R bridge support, point
> estimates, objective/logLik, CI or CI-status, docs/articles, visual evidence,
> tests, issue ledger, and Rose audit agree.
