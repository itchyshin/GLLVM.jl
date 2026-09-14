# After-task: kernel × dep Arc 0 Gaussian wrapper (#14)

**Date:** 2026-09-14  
**Branch:** `cursor/kernel-dep-070-20260914`  
**Base:** `origin/main` @ `5e9bfcd4`  
**Rose fence:** Gaussian matrix admission only ≠ twin Δ ≠ ledger promote ≠ `@formula`/bridge parity.

## Scope

- Exported `fit_kernel_dep_gllvm(Y, K, groups)` → `SourceCovariance` `:dep` + `fit_gaussian_sources`.
- ACCEPTED identity `docs/dev-log/decisions/2026-09-14-kernel-dep-identity.md`.
- Tests, api.md, check-log.

## Out of scope

- `kernel_latent` (arc #15); `@formula` / bridge; S4 probe; capability promotion; version bump.

## Checks

| Command | Result |
|---|---|
| `julia --project=. test/test_kernel_dep.jl` | 10/10 pass (~11 s) |

## Reviewers

- Gauss/Karpinski: implementation
- Rose: not run pre-merge (draft PR)
