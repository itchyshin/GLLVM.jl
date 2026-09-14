# After-task: kernel × latent Arc 0 Gaussian wrapper (#15)

**Date:** 2026-09-14  
**Branch:** `cursor/kernel-latent-070-20260914`  
**Base:** `origin/main` (pre–PR #333; rebase when #333 lands)  
**Rose fence:** Gaussian matrix admission only ≠ twin Δ ≠ ledger promote ≠ `@formula`/bridge parity.

## Scope

- Exported `fit_kernel_latent_gllvm(Y, K, groups, d)` → `SourceCovariance` `:latent` / `:dep` when `d == p`.
- ACCEPTED identity `docs/dev-log/decisions/2026-09-14-kernel-latent-identity.md`.
- Tests, api.md.

## Out of scope

- `unique = true` fold; multi-kernel; `@formula` / bridge; capability promotion; version bump.

## Checks

| Command | Result |
|---|---|
| `julia --project=. test/test_kernel_latent.jl` | 12/12 pass (~16 s) |

## Reviewers

- Gauss/Karpinski: implementation
- Rose: not run pre-merge (draft PR)
