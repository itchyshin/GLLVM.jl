# After-task: Tweedie estimated-power SO cells (shared + species, option A)

**Date:** 2026-09-16  
**Merge:** [#391](https://github.com/itchyshin/GLLVM.jl/pull/391) squash @ **`c4dba35c4`**  
**Supersedes:** [#384](https://github.com/itchyshin/GLLVM.jl/pull/384) (closed without merge)

## Rose fence

- ≠ programme §7 / true-parity destination complete.
- ≠ contract §4 **D1** promote (`eoo_claimed=false` on both smokes).
- ≠ jointly-optimised power parity (option A plug-in / EOO cells only).
- ≠ #357 bridge logLik receipts (foreign lane).
- = native Wald wiring + `cell_tweedie_shared` / `cell_tweedie_species` + logLik smokes.

## What landed

1. **`TweediePerTraitPowerFit`** (and shared estimated-power path) in `_family_ci` /
   confint family dispatch (`src/confint_family.jl`).
2. **`cell_tweedie_species()`** + `r_fit_se_tweedie_species` in second-order tools;
   extends shared EOO smoke drivers (`smoke_tweedie_*_eoo.jl`) with
   `eoo_claimed=false` and informational `eoo_would_pass`.
3. Tests: `test/test_second_order_tweedie_grouped_ci.jl` extended for species cell wiring.

## Checks (post-merge on `origin/main`)

```text
gh run view 35058263626  # push for c4dba35c4 / #391
# Julia 1.10 + Julia 1: 8/8 shards success
# Documenter: success (35058263640, 35060057689 on later doc tips)
# Frozen R 0.7.0 family smoke: FAILURE (advisory; #323 waived — OK)
```

Focused tests (local, not re-run this receipt): `julia --project=. test/test_second_order_tweedie_grouped_ci.jl`.

## Status

**PARTIAL:** native Wald + named SO cells + logLik receipts; power coordinates compared on
**β / `b_fixed` block only**; not paired as jointly estimated with R; **not D1 EOO**.

## Follow-up

Paste-gated only: Delta dispersion A, D3 Stage 1, S4 probe, Totoro T4 (D-139 ack), #357 when
unblocked. Goal stays **IN PROGRESS**.

Rose verdict: **PASS WITH NOTES** — engine receipt on main; twin Δ / D1 / §7 unchanged.
