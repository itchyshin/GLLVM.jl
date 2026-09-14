# After-task — kernel × indep Arc 0 Gaussian wrapper (2026-09-14)

**Branch:** `cursor/kernel-indep-070-20260914`  
**Base:** `origin/main` @ `b2956e83`  
**Rose fence:** Gaussian matrix wrapper only ≠ twin Δ ≠ ledger promote ≠ formula/bridge parity ≠ non-Gaussian.

## Scope

- ACCEPTED identity `docs/dev-log/decisions/2026-09-14-kernel-indep-identity.md`.
- Exported `fit_kernel_indep_gllvm(Y, K, groups)` → `SourceCovariance` `:indep` + `fit_gaussian_sources`.
- `rho ≠ 1`, missing `groups`, and engine-knob kwargs fail-loud.
- Tests, api.md, LOOP tick, check-log.

## Out of scope

- `kernel_dep` / `kernel_latent` (arcs #14–15); `@formula` / bridge; S4 probe; capability promotion; version bump.

## Checks

| Check | Result |
|---|---|
| `test/test_kernel_indep.jl` | 10/10 pass (~11 s) |
| Full `runtests.jl` | Not run (Arc 0 focused) |
| CI | Await draft PR workflow |

## Follow-up

- Arc 0 twin light Δ optional; `kernel_dep` / `kernel_latent` named routes next.
