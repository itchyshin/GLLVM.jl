# Estimated Tweedie power second-order cells

2026-09-15 docs-plan scout (this file only; no engine). Honest-0.7 / true-parity
vs frozen gllvmTMB `b4d5fee6`. Holdout: Tweedie shared + grouped
(`docs/dev-log/core070/second-order-holdouts-2026-09-04.md`). Identity:
`docs/dev-log/decisions/2026-08-30-core070-tweedie-power.md`. Handover pick:
Mac Studio ungated candidate 5
(`docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md`).

This leaf is a plan. Do not implement from this file in the same PR.

## Goal

Add each-own-optimum second-order cells for the two estimated-power contracts
(shared `ξ`, per-species `ξ_1…ξ_p`) that first-order already pairs. Fixed-power
SO plumbing already exists. Do not treat a live Δ as §7, coverage, or a Totoro
campaign.

## What fixed-power already has

| Piece | Where | Status |
|---|---|---|
| First-order logLik (seed 82, p=5, K=1, n=150, `power=1.5`) | `test/parity/test_tweedie_parity.jl` + `fit_gllvmtmb_parity_tweedie(...; p_fixed=)` | Exists (`se=FALSE`) |
| `TweedieGroupedFit` ∈ `_CIFit` | `src/confint_family.jl` (`_GroupedDispersionFit`) | #356 MERGED |
| Wald `_family_ci` | θ = `[β; pack(Λ); log φ_g]`; **power plug-in** | Wired |
| R SO helper | `r_fit_se_tweedie(y, K; p_fixed=)` in `tools/core070_second_order/common.jl` | `se=TRUE`; public `tweedie(p=pv)` |
| Cell + smoke | `cell_tweedie_fixed()`; `smoke_tweedie_fixed_eoo.jl` | Dispatch live; **D1 not asserted** |
| Always-on Julia tests | `test/test_second_order_tweedie_grouped_ci.jl` | Fixed-power packing + public Wald on `beta` |
| Live R Δ | same file, `GLLVM_PARITY_TESTS=1` | Records `se_max_relative_delta`; no §4 D1 gate |

Compared quantity on `tweedie_fixed` is the trait intercept block (`b_fix` vs
`beta[...]`). Power is fixed on both sides. After-task
`docs/dev-log/after-task/2026-09-15-tweedie-grouped-wald-ci.md` still owes a
local smoke receipt before any D1 promote.

Shared estimated power already has a **Julia-only** Wald test in that same
file: `_family_ci` still plug-ins `fit.power`, so
`length(ad.θ) == _nparams(fit) - 1`. Keep that plug-in length in the first
SO cell PR.

## What estimated shared / species still needs

First-order already covers both estimated contracts (`test_tweedie_parity.jl`):

- **shared:** Julia `power_group=:shared` (`TweedieGroupedFit`, +1 ξ);
  R uses the **reference-engine constraint adapter** (not a public
  `gllvmTMB()` knob). Helper returns logLik only (`se=FALSE`).
- **species:** Julia `power_group=:species` (`TweediePerTraitPowerFit`, +p ξ);
  R public default `tweedie()` (per-trait `logit_p_tweedie`). Same helper,
  `se=FALSE`.

Still missing for second-order:

1. **`r_fit_se_tweedie` estimated arms.** `common.jl` comments this out on
   purpose. Shared needs `sdreport` **after** the adapter rebuild
   (`MakeADFun` + `nlminb` on the tied-power map). Species can follow the
   public `tweedie()` fit with `se=TRUE`. Do not reuse
   `fit_gllvmtmb_parity_tweedie` as-is; it never builds `sd_report`.
2. **Cells + smoke.** No `tweedie_shared` / `tweedie_species` in
   `tools/core070_second_order/cells.jl` dispatch. No smoke drivers.
3. **Species Wald.** `TweediePerTraitPowerFit` is **out of `_CIFit`**. A
   species SO cell that calls `confint` needs a `_family_ci` adapter first
   (engine; not this docs PR). Shared does **not** need that for intercept-only
   pairing, because `TweedieGroupedFit` Wald already exists.
4. **Estimand fork (decide before coding).** R `par.fixed` for estimated power
   includes `logit_p_tweedie`. Julia grouped Wald does **not**. A full-block
   vcov compare is a parameterisation gap unless one of these is chosen:

   | Option | Meaning | When |
   |---|---|---|
   | **A (default, match `tweedie_fixed`)** | Compare `b_fix` only; keep Julia power plug-in; note the gap | First SO cells; no `_family_ci` change |
   | **B** | Put ξ (shared) or ξ_1…ξ_p (species) into `_family_ci` θ | Separate engine slice; also rethink `TweedieFit` plug-in sibling |

   Pick **A** unless Shinichi asks for power SEs. Option B is not required to
   clear "cells still not attempted."

5. **Live receipt.** Same rule as fixed: record Δ locally; promote D1 only
   after `smoke_*_eoo.jl` writes a JSON under
   `tools/core070_second_order/second-order-batch-out/`. No Totoro.

## Files a later implementation PR may touch

**Tools / tests (A, intercept-only):**

- `tools/core070_second_order/common.jl`: `r_fit_se_tweedie` estimated
  methods, or siblings `r_fit_se_tweedie_shared` / `_species`.
- `tools/core070_second_order/cells.jl`: `cell_tweedie_shared()`,
  `cell_tweedie_species()`; same seed-82 fixture as first-order /
  `cell_tweedie_fixed`; `parameterisation_gap=false` only if the compared
  block is `b_fix`.
- `tools/core070_second_order/smoke_tweedie_shared_eoo.jl`
- `tools/core070_second_order/smoke_tweedie_species_eoo.jl`
- `test/test_second_order_tweedie_grouped_ci.jl` (or a new
  `test/test_second_order_tweedie_estimated_power_ci.jl` included from
  `test/runtests.jl`)

**Engine (species Wald, or option B). Do not mix into the first tools PR
unless the species cell is in that same slice:**

- `src/confint_family.jl`: `_CIFit` / `_family_ci(::TweediePerTraitPowerFit)`.
  Mirror grouped packing; decide plug-in vs free ξ **before** writing θ.
  Leave `TweedieFit` plug-in alone unless option B is explicit.

**Docs after a passing slice (not this file's job):**

- holdouts table (PARTIAL → SO cells attempted; still ≠ §7)
- `docs/dev-log/check-log.md` + after-task
- Mac handover / pending board tip

**Do not touch:** #357 (`feat/lognormal-truncpois-loglik-receipts-20260915`);
`gllvmTMB` TMB/likelihood; `Project.toml`; D3 Stage 1; S4; Totoro scripts.

`second-order-parity-contract.md` §2 still says TweedieGrouped Wald is OUT
until `_CIFit` exists. That sentence is stale after #356. Fix it in the
implementation docs pass, not here, if a board/lease owner is already on
`docs/dev-log/`.

## Test shape

Always-on (no R):

- Shared: keep the existing plug-in length check (`θ` = `_nparams - 1`).
- Species (only if `_family_ci` lands): packing length, `beta` Wald finite on
  a small draw (n about 60 to 80, not n=150), `isa TweediePerTraitPowerFit`.

`GLLVM_PARITY_TESTS=1` (local RCall; frozen oracle):

```julia
d = run_one_cell("tweedie_shared")   # and "tweedie_species"
@test get(d, "skip_reason", nothing) === nothing
@test get(d, "parameterisation_gap", true) == false
@test isfinite(d["se_max_relative_delta"])
# do not assert contract §4 D1 until smoke JSON exists
```

Fixture: seed 82, p=5, K=1, n=150, `hessian=:observed` (signed A). Compared
quantity: `b_fix` / `beta[...]`. Shared R path must set
`reference_constraint_adapter=true` and `n_power_free=1`; species
`n_power_free=p`.

Manual smoke (not CI): the two `smoke_*_eoo.jl` drivers, same pattern as
`smoke_tweedie_fixed_eoo.jl`.

## Fences

- **≠ §7** / true-parity destination / `v0.true-parity` sign-off.
- **≠ Totoro / T4 / DRAC** without paste `ack Totoro D-139 #323 Track A`
  (or an explicit D-139 that names this slice). Local RCall only.
- **≠ D1 promote** from a test that only records Δ.
- **≠ #357** rebase, bridge `ci_method` lift, or any file on that PR.
- **≠ gllvmTMB engine surgery.** Shared-power adapter stays Julia-side tools,
  as in `fit_gllvmtmb_parity_tweedie`.
- **≠ coverage / ADEMP / matched-θ.**
- **≠ `Project.toml` bump** (stays `0.3.0`).
- **≠ option B** (ξ inside Wald θ) unless a later G0 names it.

## Suggested later sequence (not this PR)

1. Tools: `r_fit_se` estimated arms + `tweedie_shared` cell + smoke; extend
   the existing grouped CI test. Intercept-only (option A).
2. Engine (own PR): `TweediePerTraitPowerFit` `_family_ci` +
   `tweedie_species` cell + smoke.
3. Docs: holdouts / check-log / after-task. Still PARTIAL; ≠ §7.

Rose: Julia wiring + named-cell plumbing ≠ twin Δ receipt ≠ D1 ≠ §7.
