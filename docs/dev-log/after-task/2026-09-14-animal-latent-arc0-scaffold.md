# After-task — animal × latent Arc 0 scaffold (2026-09-14)

**Branch:** `cursor/animal-latent-070-20260914`  
**Base:** `origin/main` @ `b6e6dfcb`  
**Rose fence:** Julia Arc 0 matrix fitter only ≠ formula/bridge parity ≠ ledger promote ≠ twin Δ.

## Scope

- ACCEPTED identity `docs/dev-log/decisions/2026-09-14-animal-latent-identity.md`.
- Exported `fit_animal_latent_gllvm(Y, A, d)` with rank `d` on existing Gaussian J3 block;
  `d == p` delegates to `fit_animal_dep_gllvm`; `unique = true` fail-loud.
- Tests, api.md, LOOP checkpoint/arcs, check-log.

## Out of scope

- `@formula` / `gllvm()` / bridge; S4 probe; capability-status promotion; version bump.

## Checks

| Check | Result |
|---|---|
| `test/test_animal_latent.jl` | 16/16 pass (~10 s) |
| Full `runtests.jl` | Not run (Arc 0 focused) |
| CI | Await draft PR workflow |

## Follow-up

- ADEMP recovery for rank-1 animal_latent before promotion.
- `phylo_latent()` matrix fitter (parallel pattern) not this slice.
