# After-task — ZIP+X engine Arc 0 (2026-08-09)

## Goal

Ship Julia-forward ZIP+X under ACCEPTED Identity
(`docs/dev-log/decisions/2026-08-09-zip-x-identity.md`): export
`fit_zip_gllvm_cov` / `ZIPCovFit` packing `[βz; γz; βc; γc; pack(Λc)]` with
`Λ_z = 0`, dual offsets into the ZIP Laplace marginal, identity + packed FD
≤ 1e-6, bridge/`@formula` admit one-part + X `zip`, docs cascade, Rose fence
(no twin Δ).

## What landed

- `ZIPCovFit` + `fit_zip_gllvm_cov` in `src/families/twopart.jl`
- Exports + `ZIPoisson` marker; `fit_gllvm` / `@formula` routes
- `getLV(::ZIPCovFit, Y, X)` post-fit hook
- Bridge: `zip` ∈ `_BRIDGE_ONEPART` + `_BRIDGE_X`; CI under X fenced
  (`_BRIDGE_NO_CI_X_FAMILIES`); assemble dual `gamma_z` / `gamma_c`
- Tests: `test/test_zip_x_identity.jl`; capabilities + bridge_x goldens
- Docs: response-families, capability-status, board START HERE, check-log,
  LOOP kit reattached on engine branch

## Tests (printed tallies)

| Suite | Result |
| --- | --- |
| `test_zip_x_identity.jl` | **28/28** — zero-X Δ ≈ 1.14e-13; FD max\|central−5pt\| ≈ 1.18e-8 ≤ 1e-6 |
| `test_bridge_capabilities.jl` | **139/139** |
| `test_bridge_x.jl` | **265/265** (incl. zip dual-γ + CI fence) |
| Full `Pkg.test()` | **5324 pass / 1 broken / 5325** (55m35s) — tests passed |

No rtol widen. Twin light RCall cell **not** added (gllvmTMB ZIP still cut).

## Rose claim fence

**OK to claim:** Julia ZIP+X engine path live under Identity — dual-γ packing,
identity/FD green, bridge/`@formula` admit one-part + X `zip`, CI under X
explicitly deferred (Q1).

**Not OK:** twin ZIP parity · light RCall Δ · ADEMP/coverage · ZINB+X · free
`Λ_z` default · full family parity · Phylo #127.

**Rose verdict: PASS WITH NOTES** — claim is Julia-engine only; twin Δ remains
forbidden until twin ZIP restores and Identity re-check.

## Remaining risks / next

- Optional Rung 2: ZIP+X confint adapter (not DoD)
- When twin ZIP returns: Identity re-check before any light cell
- Next arc: fresh `/arc-creation` for confint-under-X or twin re-check

## Workspace

- Branch: `feat/zip-x-engine-20260809`
- Worktree: `.worktrees/gllvmjl-zip-x-engine-20260809`
- Base: `origin/main` @ `6f9050e5` (#198)
