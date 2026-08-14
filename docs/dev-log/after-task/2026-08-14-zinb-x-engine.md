# After-task — ZINB+X engine Arc 0 (2026-08-14)

## Goal

Ship Julia-forward ZINB+X under ACCEPTED Identity
(`docs/dev-log/decisions/2026-08-13-zinb-x-identity.md`): export
`fit_zinb_gllvm_cov` / `ZINBCovFit` packing `[βz; γz; βc; γc; pack(Λc); log r]`
with `Λ_z = 0` and **one shared scalar `r`**, identity + packed FD ≤ 1e-6
(including `r`), bridge/`@formula` admit one-part `zinb` + ZINB+X
(`ZINegBin()`), docs cascade, Rose fence (no twin Δ). Confint under X is
**not** in DoD.

## S0 twin re-cite

Local `gllvmTMB` @ `9518d1bf` (same as Identity):

1. `docs/dev-log/known-limitations.md` L146–148 — ZIP/ZINB cut from 0.2.0.
2. `R/fit-multi.R` `family_to_id` — no ZIP/ZINB arm.

Identity not re-opened.

## What landed

- `ZINegBin` public marker + `ZINBCovFit` + `fit_zinb_gllvm_cov` in
  `src/families/twopart.jl` (kernel `ZINB(r)` stays internal)
- Exports; `fit_gllvm` / `@formula` routes (no-X → `fit_zinb_gllvm`,
  X → `fit_zinb_gllvm_cov`)
- `getLV(::ZINBCovFit, Y, X)` post-fit hook
- Bridge: `zinb` ∈ `_BRIDGE_ONEPART` + `_BRIDGE_X`; CI under X fenced
  (`_BRIDGE_NO_CI_X_FAMILIES`); assemble dual `gamma_z` / `gamma_c` +
  shared `r` on `dispersion`
- Tests: `test/test_zinb_x_identity.jl`; capabilities + bridge_x goldens
- Docs: response-families, tutorial, capability-status, board START HERE,
  check-log, AGENTS snapshot

## Tests (printed tallies)

| Suite | Result |
| --- | --- |
| `test_zinb_x_identity.jl` | **42/42** — zero-X Δ ≈ 3.41e-13; r_cov ≈ r_nox (2.56586712 vs 2.56586710); γz=γc=0; FD max\|central−5pt\| ≈ 1.66e-8 ≤ 1e-6 (log r included) |
| `test_bridge_capabilities.jl` | **152/152** |
| `test_bridge_x.jl` | **314/314** (incl. zinb dual-γ + CI-under-X fence) |
| Full `Pkg.test()` | **5464 pass / 1 broken / 5465** (54m17.7s) — tests passed |

No rtol widen. Twin light RCall cell **not** added (gllvmTMB ZINB still cut).
Shared `r` retained; NB2 per-trait φ **not** copied.

## Rose claim fence

**OK to claim:** Julia ZINB+X engine path live under Identity — dual-γ packing
plus shared scalar `r` (`log r`), identity/FD green, bridge/`@formula` admit
one-part + X `zinb`, CI under X explicitly deferred (G0).

**Not OK:** twin ZINB parity · light RCall Δ · ADEMP/coverage · confint under
X · free `Λ_z` default · per-trait `r` · hurdle+X / Tweedie+X · re-open
Identity · full family parity · Phylo #127.

**Rose verdict: PASS WITH NOTES** — claim is Julia-engine only; twin Δ remains
forbidden until twin ZINB restores and Identity re-check. Confint under X is
a follow-up, not this DoD.

## Remaining risks / next

- Optional Rung 2: ZINB+X confint adapter (not DoD)
- When twin ZINB returns: Identity re-check before any light cell
- Next arc: fresh `/arc-creation` for confint-under-X or twin re-check

## Workspace

- Branch: `feat/zinb-x-engine-20260814`
- Worktree: `.worktrees/gllvmjl-zinb-x-engine-20260814`
- Base: `origin/main` @ `daf95da6` (#202)
