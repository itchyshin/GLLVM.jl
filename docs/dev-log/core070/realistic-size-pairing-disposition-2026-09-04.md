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
| SE D1 pass/fail/skip (cells with β metrics) | **16/0/8** (8 = gaussian estimand gap) |

**R package note:** local `gllvmTMB` 0.7.1 (R 4.6.0); logLik matches Julia to ~1e-8.
Frozen oracle pin `b4d5fee6` re-run optional if maintainer requires exact oracle build.

## Claim boundary

Repair fixes **pairing** for idx 9/17 only; it does not close contract §7 or §6 holdouts.
