# Realistic-size idx 9 & 17 — pairing disposition (2026-09-04)

## Original finding (archived Totoro tree)

R summaries embedded **wrong seeds** (1002 / 1003) for tags `poisson_p20_n500_K1` and
`nb2_p20_n500_K1` while Julia used grid seeds **1009 / 1017**. Large |ΔlogLik| was a
**pairing artifact**, not divergent optima.

## Repair (2026-09-04, local)

1. Regenerated authoritative Y CSV via Julia `core070_realistic_size_cell.jl … data-only`
   (seeds 1009, 1017).
2. Re-ran `Rscript tools/core070_realistic_size_cell.R` with matching argv; outputs in
   `realistic-size-out/totoro-repair-20260904/`.
3. Merged repair over archived Totoro outputs →
   `realistic-size-paired-20260904-merged.csv` via `core070_realistic_size_collect.py`.

## Post-repair counts (D1 each-own, object-level)

| Check | Count |
|---|---|
| `seed_match` | **24/24** |
| First-order paired (`|ΔlogLik| < 1e-4`) | **24/24** |
| idx 9 `max_rel_dSE_beta` | 4.99e-06 |
| idx 17 `max_rel_dSE_beta` | 1.89e-05 |
| SE D1 pass/fail/skip (all 24 realistic cells) | **24/0/0** (Gaussian idx 1–8 re-run after intercept-SE patch, 2026-09-04) |

**R package note:** local `gllvmTMB` 0.7.1 (R 4.6.0); logLik matches Julia to ~1e-8.
Frozen oracle pin `b4d5fee6` re-run optional if maintainer requires exact oracle build.

## Claim boundary

Repair fixes **pairing** for idx 9/17 only; it does not close contract §7 or §6 holdouts.

## Gaussian intercept SE re-run (2026-09-04)

Julia `core070_realistic_size_cell.jl` now passes per-trait intercept `X` to `fit_gaussian_gllvm` / `confint` (commit `5e55a205`). Re-ran idx 1–8 locally (8-way parallel, ~218 s wall); collector skips cleared. All eight Gaussian cells **SE D1 pass** (max rel ΔSE β = 2.23e-05 at idx 6).
