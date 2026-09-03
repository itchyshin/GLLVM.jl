# Realistic-size grid, paired by cell (T4) — 2026-09-03

Pairs `docs/dev-log/core070/realistic-size-prerun-2026-09-03.md`'s 24-cell grid
(`tools/core070_realistic_size_cells.tsv`) by `idx`: Julia from Nibi array
21053142 (+ resubmit 21053691), R from Totoro's completed 24-cell background
grid. Receipts, not a parity claim — nothing here is gated against
`second-order-parity-contract.md`. Local copies (small text only, nothing
>2 MB, none skipped): `docs/dev-log/core070/realistic-size-out/{nibi,totoro}/`.

## Status: 14 valid pairs / 2 invalid pairs / 8 pending (of 24)

**Data-integrity finding, checked before trusting any number below.** The
Totoro R-grid driver's log (`r_grid_driver.log:1,16,31`) reads `skip
<tag> (already done)` for `gaussian_p20_n500_K1`, `poisson_p20_n500_K1`,
`nb2_p20_n500_K1` — it found the prerun doc's STEP-1 spot-check outputs
already sitting under those exact filenames and reused them instead of
re-fitting with the grid's assigned seed, because the output filename
carries only `<family>_p<p>_n<n>_K<K>`, not the seed. STEP 1's spot-check
used its own ad hoc seeds (1001/1002/1003 for gaussian/poisson/nb2), which
only coincidentally equals the grid's `idx1` (`seed=1001`) for gaussian.
Verified by comparing every `seed=` line inside the `_r_summary.txt` /
`_julia_summary.txt` files against `tools/core070_realistic_size_cells.tsv`:

| idx | tag | grid seed | R file's seed | Julia file's seed |
|---|---|---|---|---|
| 1 | gaussian_p20_n500_K1 | 1001 | 1001 | 1001 (OK, coincidence) |
| 9 | poisson_p20_n500_K1 | 1009 | **1002** | 1009 (**mismatched pair**) |
| 17 | nb2_p20_n500_K1 | 1017 | **1003** | 1017 (**mismatched pair**) |

For idx 9 and 17 the R and Julia sides fit **different datasets** under
the same cell tag — R re-used the STEP-1 spot-check's fit (a valid,
already-reported STEP-1 receipt, just not this grid's idx9/idx17 cell).
logLik "deltas" for these two are meaningless (idx9: jl `-20407.47` vs r
`-20119.83`, Δ=-287.6; idx17: jl `-22572.12` vs r `-22813.51`, Δ=241.4)
and are **excluded from every statistic below**. Root cause: a
filename convention gap (no seed in the output filename), not a fitting
defect — flag for whoever re-runs R with the correct seed.

**8 cells pending** (idx 14, 15, 16, 20, 21, 22, 23, 24 — the p=50/n=2000
and larger K=2 cells): array 21053691 has all 8 tasks still `RUNNING` at
time of writing (~12 min elapsed of `--time=02:00:00`, `sacct -j 21053691
-X`). None `COMPLETED`. Two of the eight (idx14 `poisson_p50_n500_K2`,
idx15 `poisson_p50_n2000_K1`) have **stray partial `_julia_terms.csv`
files** on Nibi (13.6 KB / 9.0 KB, timestamped 20:53–21:07 during the
*original*, since-cancelled array 21053142, written before that task was
killed at 8m44s) with **no matching `_summary.txt` or `_vcov_*.csv`** — an
in-flight write from a run that never finished. The collector script
naively pairs any terms.csv it finds, silently producing non-receipts for
these two (`max_rel_dSE_beta` 3.76e-05 / 1.32e-04 in the raw CSV) —
**disregarded here**; delete or ignore these stale files once 21053691
completes, don't resubmit-and-forget them.

## Per-cell table (14 valid pairs; β block + shared scalars only — Λ is out of scope, §3)

| idx | family | p | n | K | logLik Δ (jl−r) | cond(H) jl | cond(H) r | max rel ΔSE (β) | vcov rel Frob (β) | max \|ΔWald\| | pd (jl/r) | conv (jl/r) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | gaussian | 20 | 500 | 1 | 1.44e-07 | 43.78 | 50.02 | n/a* | n/a* | n/a* | T/T | T/T |
| 2 | gaussian | 20 | 500 | 2 | 1.39e-07 | 2646.83 | 8694.49 | n/a* | n/a* | n/a* | T/T | T/T |
| 3 | gaussian | 20 | 2000 | 1 | 5.80e-08 | 67.54 | 104.04 | n/a* | n/a* | n/a* | T/T | T/T |
| 4 | gaussian | 20 | 2000 | 2 | 2.82e-08 | 822.62 | 1599.73 | n/a* | n/a* | n/a* | T/T | T/T |
| 5 | gaussian | 50 | 500 | 1 | 1.68e-08 | 310.85 | 911.07 | n/a* | n/a* | n/a* | T/T | T/T |
| 6 | gaussian | 50 | 500 | 2 | 6.89e-07 | 1746.89 | 3582.98 | n/a* | n/a* | n/a* | T/T | T/T |
| 7 | gaussian | 50 | 2000 | 1 | 4.29e-08 | 210.86 | 415.28 | n/a* | n/a* | n/a* | T/T | T/T |
| 8 | gaussian | 50 | 2000 | 2 | 1.07e-07 | 1718.10 | 2475.71 | n/a* | n/a* | n/a* | T/T | T/T |
| 10 | poisson | 20 | 500 | 2 | 3.91e-07 | 125.30 | 537.03 | 7.28e-06 | 1.96e-05 | 2.60e-06 | T/— | T/T |
| 11 | poisson | 20 | 2000 | 1 | 1.09e-08 | 19.30 | 52.69 | 1.14e-05 | 2.61e-05 | 2.94e-06 | T/— | T/T |
| 12 | poisson | 20 | 2000 | 2 | 1.62e-07 | 54.99 | 146.46 | 1.27e-05 | 2.44e-05 | 1.09e-06 | T/— | T/T |
| 13 | poisson | 50 | 500 | 1 | 8.29e-08 | 71.72 | 306.58 | 1.50e-05 | 2.95e-05 | 1.18e-05 | T/— | T/T |
| 18 | nb2 | 20 | 500 | 2 | 7.04e-07 | 192.01 | 806.73 | 1.58e-05 | 2.88e-05 | 4.40e-06 | T/— | T/T |
| 19 | nb2 | 20 | 2000 | 1 | 3.49e-07 | 67.93 | 79.72 | 6.95e-06 | 1.33e-05 | 5.35e-06 | T/— | T/T |

\* Gaussian has no β/intercept block for this DGP (centred Y per trait) —
same finding as every prior pre-run in this programme. `pd_hessian_r` is
not written to `_r_summary.txt` by `core070_realistic_size_cell.R` (field
absent, "—" above, not false); R's own `has_sd_report=TRUE` holds for all
14. NB2 `dispersion_boundary`/`boundary_terms` (T14 F1): no boundary hit
at this size for idx18/idx19 (`Bool[0×20]`, empty `boundary_terms`),
matching the STEP-1 finding that n≥500 identifies every per-trait `r`
cleanly.

## (1) Does agreement degrade with p, n, K, or cond(H)?

**Max rel ΔSE (β block) by (p, n)** — poisson/nb2 valid cells only
(gaussian has no β block):

| (p, n) | cells | max rel ΔSE |
|---|---|---|
| (20, 500) | idx10, idx18 | 1.58e-05 |
| (20, 2000) | idx11, idx12, idx19 | 1.27e-05 |
| (50, 500) | idx13 | 1.50e-05 |
| (50, 2000) | — (all 4 pending: idx15,16,23,24) | no data yet |

No monotone degradation with p or n visible in what has landed — all six
values sit in a narrow 6.95e-06–1.58e-05 band regardless of size. K=2
cells (idx10, idx12, idx18) are not systematically worse than K=1 cells
(idx11, idx13, idx19) either.

**Max rel ΔSE by cond(H) bucket** (Julia's `cond_H`, since that's the side
with a comparable ForwardDiff Hessian and every β-block cell has cond<1e3):

| cond(H) bucket | cells | max rel ΔSE |
|---|---|---|
| < 100 | idx11 (19.3), idx12 (55.0), idx13 (71.7), idx19 (67.9) | 1.50e-05 |
| 100–1000 | idx10 (125.3), idx18 (192.0) | 1.58e-05 |
| > 1000 | none with a β block yet | — |

The two buckets differ by less than 1.1x (1.50e-05 vs 1.58e-05) — no
visible conditioning effect on ΔSE **within the range measured so far**.
Every cond(H)>1e3 cell in this grid so far is Gaussian (no β block to
test), so the contract's conditioning-scaling clause (§4, below) is not
yet exercised by any comparable pair.

## (2) The conditioning finding

R's largest cell, `nb2_p50_n2000_K2` (idx24, Totoro, `cond_H=14137.7`), is
the number named in the ticket. **Julia's idx24 is still pending**
(21053691_24, RUNNING) — no paired Δ for this cell yet. What the grid does
show: cond(H) rises sharply with K, though not by a stable factor
(Gaussian K=2 cells run 3.9x–174x their K=1 siblings' cond(H) at matched
p,n across the four (p,n) combinations, both engines — idx2 vs idx1 is
the extreme, R's 8694.5 vs 50.0) and with p·n scale (R's nb2 cond(H)
climbs 99.5 → 806.7 → 14137.7 across the three sizes measured so far).
Per the contract's §4
each-own-optimum row (`rel ≤ 1e-2, ×cond(H)/1e3 when cond(H)>1e3`): none
of the 14 valid pairs exceeds cond(H)=1e3 on the β block, so the scaling
multiplier is inert (=1) everywhere it currently applies, and every
measured max rel ΔSE (worst 1.58e-05) sits roughly 3 orders of magnitude
inside the unscaled 1e-2 bound. Whether ΔSE actually degrades once
cond(H) crosses 1e3, as the contract's formula assumes, is **untested
until idx24 (and idx6, idx8, idx20-23) lands with a completed Julia
side** — the toy-fixture finding the multiplier was calibrated against
(2.2e-2 discrepancy at cond≈1e6, `parity-panel-2026-09-01.md:29-32`) is
far beyond any condition number this grid has reached on a β-comparable
cell so far.

## (3) Timing — not a compile-free speed comparison

`_julia_summary.txt`'s `wall_fit_sec` / `wall_confint_sec` are `@elapsed`
timers taken **inside** the running process, around the fit/confint calls.
They do **not** separate first-call JIT compilation from numerical work (a
fresh `julia --project=.` process per cell means the first call pays full
specialization cost, folded into `wall_fit_sec`), and exclude Julia
session startup/precompilation entirely (unmeasured, per-process). R's
`wall_fit_sec` is fit-only against an already-compiled TMB object (no
per-process JIT). **Raw numbers only, no ratio drawn**:

| idx | tag | R wall_fit (s) | Julia wall_fit (s) | Julia wall_confint (s) |
|---|---|---|---|---|
| 1 | gaussian_p20_n500_K1 | 1.08 | 13.32 | 10.94 |
| 8 | gaussian_p50_n2000_K2 | 31.89 | 12.52 | 37.36 |
| 13 | poisson_p50_n500_K1 | 4.68 | 147.39 | 154.49\*\* |
| 19 | nb2_p20_n2000_K1 | 45.75 | 160.11 | 154.49 |
| 24 | nb2_p50_n2000_K2 (R only; Julia pending) | 498.03 | — | — |

\*\* `wall_confint_sec` for idx13 is `poisson_p50_n500_K1`'s own value
(154.49); shown once for scale, not implying idx13=idx19.

## (4) What is NOT covered

- **8 cells pending** (idx14-16, 20-24; the p=50/n=2000 and larger K=2
  cells) — all still `RUNNING` on 21053691, none `COMPLETED`, so no D-201
  `seff` figures exist yet (see below).
- **idx9 (poisson_p20_n500_K1) and idx17 (nb2_p20_n500_K1) are invalid
  pairs** — R and Julia fit different seeded datasets under the same tag
  (data-integrity finding above); need a re-run of the R side with the
  correct grid seed before they can be trusted.
- **Λ (loadings)** — out of scope by contract §3 (rotation-invariant
  quantities only); not attempted here.
- **NB2/Poisson dispersion beyond β** — terms files carry a dispersion row
  (Julia `r[...]`, R `log_phi_nbinom2`) the collector doesn't pair.
- **Binomial-logit** — not in this grid (T4 named only Gaussian,
  Poisson-log, NB2-log; Binomial is in the toy-fixture batch instead).
- **K=2 gaussian/poisson/nb2 at p=50,n=2000** — exactly the untested
  high-cond(H) cells noted in (2); still pending.
- **Matched-coordinates diagnostic** — every number above is each-own-
  optimum (independent MLEs); no re-evaluation at the other engine's θ̂.

## D-201 resize note — cannot be written from `seff` yet

The task asks for a resize recommendation from `seff` on **completed**
21053691 tasks. **None of the 8 tasks has completed** — all 8 `RUNNING`
at ~12 min of the `--time=02:00:00` limit; `seff` returns `CPU Efficiency:
0.00%` / `Memory Utilized: 0.00 MB` with an explicit warning these fields
are unavailable before job end. No resize figure is honest to give from
this data. Best available proxy, not a measurement: none of the 8 has hit
the 2h/6G ceiling so far, and R's wall for the matching cells (idx24
`nb2_p50_n2000_K2`: 498 s fit-only) plus the STEP-1 pre-run's ~30-40x
Julia/R wall ratio suggest 15-40 min per task — inside `--time=02:00:00`.
**Re-run `seff 21053691_<idx>` once tasks finish** and size any
resubmission from that; don't reuse this extrapolation as a measured
figure.

## Files

- Cell map: `tools/core070_realistic_size_cells.tsv`.
- Collector: `tools/core070_realistic_size_collect.py` (used as-is; the
  partial/mismatched-pair issues are data problems, not script bugs —
  though its silent pairing of a partial terms.csv with no summary.txt is
  worth a future guard).
- Copied receipts (small text only, nothing skipped): `.../realistic-size-out/nibi/` (51 files, 1.0 MB), `.../realistic-size-out/totoro/` (132 files, 1.4 MB).
