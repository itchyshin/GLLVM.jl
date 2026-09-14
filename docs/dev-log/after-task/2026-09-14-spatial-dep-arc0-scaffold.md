# After-task — spatial × dep Arc 0 fail-loud admission (2026-09-14)

**Branch:** `cursor/spatial-dep-070-20260914`  
**Base:** `origin/main` @ `5e4f38b8`  
**Rose fence:** Fail-loud admission only ≠ SPDE/mesh fitter ≠ formula/bridge parity ≠ ledger promote ≠ twin Δ.

## Scope

- ACCEPTED identity `docs/dev-log/decisions/2026-09-14-spatial-dep-identity.md`.
- Exported `fit_spatial_dep_gllvm` (matrix and coords arities) — all paths `ArgumentError`.
- Tests, api.md, check-log.

## Out of scope

- Mesh/FEM/`fit_spde_*` wiring; dense `spatial_cov` stand-in; `@formula` / bridge; S4 probe; capability promotion; version bump.

## Checks

| Check | Result |
|---|---|
| `test/test_spatial_dep.jl` | see check-log |
| Full `runtests.jl` | Not run (Arc 0 focused) |
| CI | Await draft PR workflow |

## Follow-up

- Arc 1+ must define SPDE/site transport before any successful fit.
- Kernel row (#13–15) unchanged.
