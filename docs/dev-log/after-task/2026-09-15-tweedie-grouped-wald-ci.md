# After-task — TweedieGroupedFit Wald `_family_ci` (post §2 A)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal`)  
**Branch:** `feat/tweedie-grouped-wald-ci-20260915` from `origin/main` @ `789856b90`  
**Scope:** Clear the §6 holdout **`_CIFit` gap** for `TweedieGroupedFit`; **not** paired SO D1 cell; **not** programme §7.

## Rose fence

- **≠** second-order parity / contract §7 complete.
- **≠** `TweediePerTraitPowerFit` CI (still out of `_CIFit`).
- **=** Julia Wald path for grouped shared-power Tweedie; power held at `fit.power` (same plug-in contract as `TweedieFit`).

## What landed

1. `TweedieGroupedFit` added to `_GroupedDispersionFit` / `_CIFit`.
2. `_family_ci(::TweedieGroupedFit)` — θ = `[β; pack(Λ); log.(φ_g)]`; power fixed.
3. `test/test_second_order_tweedie_grouped_ci.jl` + `runtests.jl` include.
4. Holdouts table updated (`second-order-holdouts-2026-09-04.md`).

## Checks

```text
julia --project=. test/test_second_order_tweedie_grouped_ci.jl
# Test Summary: … | Pass: 10 Fail: 0
```

**Not run:** full `Pkg.test()` (await CI); paired R SO cell (`r_fit_se` has no `:tweedie`).

## PR sweep (same turn)

| PR | Outcome |
|----|---------|
| [#354](https://github.com/itchyshin/GLLVM.jl/pull/354) | **MERGED** — Delta dispersion PENDING decision (Documenter green) |
| [#353](https://github.com/itchyshin/GLLVM.jl/pull/353) | **MERGED** — twin-bridge headline inventory (8/8 Julia + Documenter; Frozen R advisory FAIL OK) |
| [#355](https://github.com/itchyshin/GLLVM.jl/pull/355) | OPEN — parity_ledger aliases; waiting Julia shards (advisory FAIL OK when settled) |

## Follow-up

- Wire `r_fit_se(..., family=:tweedie)` + SO cell when ready (local/RCall; no Totoro).
- Delta dispersion paste: `accept delta dispersion A` (PENDING on main via #354).
- Gates still held: **S4 probe yes** · **G0 Stage 1** · **ack Totoro D-139**.
