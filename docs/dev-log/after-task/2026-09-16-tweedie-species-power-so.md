# After-task: Tweedie estimated species-power SO cell (option A)

2026-09-16. Branch `cursor/tweedie-species-power-so-a0ce` from `origin/main` @ `67247f520` (#378).

## Rose fence

- ≠ programme §7 / true-parity destination.
- ≠ Totoro / T4 / D1 promote.
- ≠ #357 (bridge receipts).
- ≠ option B (ξ inside Wald θ).
- = `TweediePerTraitPowerFit` ∈ `_CIFit` + `cell_tweedie_species` + smoke + test hook.
  Compared quantity is the intercept block (`b_fix` / `beta[]`) only. Julia Wald plug-ins
  per-trait power.

## What landed

1. `TweediePerTraitPowerFit` added to `_GroupedDispersionFit` / `_CIFit` with `_family_ci`
   (θ = `[β; pack(Λ); log φ_g]`; power vector plug-in — option A).
2. `r_fit_se_tweedie_species`: public `gllvmTMB::tweedie()` + `se=TRUE`. Julia-side tools only;
   no R engine change. Returns `n_power_free=p`, `reference_constraint_adapter=false`.
3. `cell_tweedie_species()` on the seed-82 fixture (`p=5`, `K=1`, `n=150`, `hessian=:observed`).
   `parameterisation_gap=false` because only `b_fix` is paired.
4. `smoke_tweedie_species_eoo.jl` (manual; writes `tweedie_species.json`).
5. Always-on packing / public Wald tests for species; live R loop includes `tweedie_species`
   when `GLLVM_PARITY_TESTS=1`.
6. Holdouts / board / checkpoint / check-log updated. Goal **not** complete.

## Checks

```text
julia --project=. test/test_second_order_tweedie_grouped_ci.jl
# Test Summary: second-order TweedieGroupedFit Wald wiring | Pass: 22  Broken: 1 (R skip)  Total: 23
```

Not claimed: contract §4 D1. Promote only after a fresh smoke JSON on this tip.

## Follow-up

After this lands, remaining board items are paste-gated:

```text
accept delta dispersion A
G0 Stage 1
S4 probe yes
ack Totoro D-139 #323 Track A
```

OUT (ruling, not paste strings on the same form): GP-1 Fisher / Student-t free ν / Λ raw.
Leave #357 alone. Project.toml stays 0.3.0.

Rose verdict: PASS WITH NOTES. Wiring + named cell ≠ twin Δ receipt ≠ D1 ≠ §7.
