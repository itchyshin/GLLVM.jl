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

## Update 02:58Z–03:40Z: the large cells

Nibi array 21053691 finished 02:58Z: tasks 14, 15, 16, 20, 21, 22, 23
`COMPLETED`; task 24 (`nb2_p50_n2000_K2`) `TIMEOUT` at 2h00m17s (its `.batch`
step `CANCELLED` at the same instant, `MaxRSS` 488224K mid-run) and was
resubmitted as job `21059449_[24]` (`--array=24 --time=05:00:00 --mem=4G`,
currently `PD` on priority). Julia outputs re-synced from Nibi
(`~/projects/def-snakagaw/snakagaw/gllvm-realsize-01/repo/out/`, 69 files
now vs. 51 before) into `.../realistic-size-out/nibi/`; all 7 newly-landed
tags carry the grid's own seed in `_julia_summary.txt` (1014/1015/1016/
1020/1021/1022/1023, matching `tools/core070_realistic_size_cells.tsv`
exactly) and pair against R-side files already present locally from
Totoro's earlier complete 24-cell run (same seeds, checked). Collector
re-run: `python3 tools/core070_realistic_size_collect.py
docs/dev-log/core070/realistic-size-out/{nibi,totoro}` (unchanged script).

### Per-cell table (7 new pairs; same columns as above)

| idx | family | p | n | K | logLik Δ (jl−r) | cond(H) jl | cond(H) r | max rel ΔSE (β) | vcov rel Frob (β) | max \|ΔWald\| | pd (jl/r) | conv (jl/r) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 14 | poisson | 50 | 500 | 2 | 9.29e-07 | 367.85 | 2103.16 | 3.76e-05 | 7.82e-05 | 2.46e-05 | T/— | T/T |
| 15 | poisson | 50 | 2000 | 1 | 1.18e-07 | 177.80 | 794.23 | 1.32e-04 | 2.86e-04 | 2.20e-05 | T/— | T/T |
| 16 | poisson | 50 | 2000 | 2 | 2.64e-07 | 182.44 | 667.42 | 1.01e-04 | 2.29e-04 | 1.07e-05 | T/— | T/T |
| 20 | nb2 | 20 | 2000 | 2 | 5.22e-07 | 152.56 | 687.17 | 2.19e-05 | 3.70e-05 | 7.61e-06 | T/— | T/T |
| 21 | nb2 | 50 | 500 | 1 | 3.12e-07 | 69.68 | 132.06 | 2.88e-05 | 5.48e-05 | 2.33e-06 | T/— | T/T |
| 22 | nb2 | 50 | 500 | 2 | 8.55e-07 | 183.62 | 902.87 | 5.17e-05 | 1.16e-04 | 6.49e-06 | T/— | T/T |
| 23 | nb2 | 50 | 2000 | 1 | 1.25e-07 | 46.83 | 173.42 | 5.16e-05 | 1.42e-04 | 3.64e-06 | T/— | T/T |

`pd_hessian_r` is still not written by `core070_realistic_size_cell.R`
("—", not false, same convention as the first 14 rows); NB2
`dispersion_boundary`/`boundary_terms` show no boundary hit at these
sizes either (`Bool[0×p]`, empty `boundary_terms`, all 4 new NB2 cells).

**Wall time, including the job-level (sacct/seff) wall for Julia** — raw
numbers, no ratio drawn (same caveat as §3 above: `wall_fit_sec` /
`wall_confint_sec` are in-process `@elapsed` timers and exclude Julia
session startup/precompilation; sacct `Elapsed` is the full job wall and
so is the only number below that includes that overhead):

| idx | tag | R wall_fit (s) | Julia wall_fit (s) | Julia wall_confint (s) | Julia job wall (sacct) | Julia MaxRSS |
|---|---|---|---|---|---|---|
| 14 | poisson_p50_n500_K2 | 12.05 | 45.15 | 524.99 | 00:18:48 | 636 MB |
| 15 | poisson_p50_n2000_K1 | 36.41 | 31.36 | 555.04 | 00:19:25 | 780 MB |
| 16 | poisson_p50_n2000_K2 | 37.15 | 95.04 | 1554.06 | 00:53:00 | 590 MB |
| 20 | nb2_p20_n2000_K2 | 75.65 | 659.34 | 538.42 | 00:29:01 | 418 MB |
| 21 | nb2_p50_n500_K1 | 47.29 | 198.96 | 397.07 | 00:16:52 | 431 MB |
| 22 | nb2_p50_n500_K2 | 83.02 | 573.33 | 996.71 | 00:42:13 | 464 MB |
| 23 | nb2_p50_n2000_K1 | 184.84 | 852.89 | 1888.81 | 01:13:50 | 478 MB |

`seff` on the two extremes confirms ~99% CPU efficiency both ends
(21053691_15: 98.54% of 19m25s; 21053691_23: 98.94% of 1h13m50s) — these
are compute-bound single-core fits, not queue/IO artifacts. For idx23,
`wall_fit_sec + wall_confint_sec` = 2741.7 s (45.7 min) against a 73.8 min
job wall — roughly 28 min of session startup/precompilation/data-load
overhead outside the two measured phases, consistent with §3's caveat
that in-process timers understate the per-process cost.

### Updated summary

**21/24 valid pairs, 2 invalid pairs, 1 pending** (of 24): the 14 from the
first pass plus these 7 are valid; idx9 (`poisson_p20_n500_K1`) and idx17
(`nb2_p20_n500_K1`) remain invalid (R/Julia fit different seeded datasets
under the same tag — unchanged finding, see above); idx24
(`nb2_p50_n2000_K2`) is the sole cell still pending (resubmitted as
`21059449_[24]`).

### (2) revisited — the conditioning finding

Updated **max rel ΔSE (β block) by (p, n)** table (poisson/nb2 only):

| (p, n) | cells | max rel ΔSE |
|---|---|---|
| (20, 500) | idx10, idx18 | 1.58e-05 |
| (20, 2000) | idx11, idx12, idx19, idx20 | 2.19e-05 |
| (50, 500) | idx13, idx14, idx21, idx22 | 5.17e-05 |
| (50, 2000) | idx15, idx16, idx23 (idx24 K2 pending) | 1.32e-04 |

This is the first departure from the "no size trend" reading of the first
14 pairs: the (50, 2000) cells now show the grid's largest ΔSE (1.32e-04,
idx15), roughly 8x the (50,500) max and 60x the (20,500) max — a real,
if still small in absolute terms, trend with n·p scale that the first-pass
data hadn't reached.

Updated **max rel ΔSE by cond(H) bucket** (Julia's `cond_H`, unchanged
convention):

| cond(H) bucket | cells | max rel ΔSE |
|---|---|---|
| < 100 | idx11, idx12, idx13, idx19, idx21 (69.7), idx23 (46.8) | 5.16e-05 (idx23) |
| 100–1000 | idx10, idx18, idx14 (367.9), idx15 (177.8), idx16 (182.4), idx20 (152.6), idx22 (183.6) | 1.32e-04 (idx15) |
| > 1000 | none (Julia cond(H) tops out at 367.9 in this grid) | — |

By Julia's cond(H), no cell yet crosses 1e3, so the bucket boundary the
contract's ×cond(H)/1e3 clause cares about is still unexercised on that
side. **But R's cond(H) does cross 1e3 for the first time in this grid**:
idx14 (`poisson_p50_n500_K2`) has `cond_H_r = 2103.16` against
`cond_H_jl = 367.85`. This is a genuine β-comparable pair (Poisson has an
intercept block, unlike Gaussian) and is the first test — partial, since
only one engine's Hessian crosses the threshold — of the contract's §4
each-own-optimum row (`rel ≤ 1e-2, ×cond(H)/1e3 when cond(H)>1e3`):

- Unscaled tolerance (1e-2): idx14's max rel ΔSE = 3.76e-05, about 266x
  inside the bound.
- Scaled tolerance (×cond(H)/1e3, using R's 2103.16 → multiplier 2.103,
  bound = 2.103e-2): 3.76e-05 is about 559x inside the (looser) bound.

**No exceedance either way.** Whether the contract's scaling clause is
meant to key off Julia's cond(H), R's, or the max of the two is still not
specified anywhere it's been written down (same ambiguity the first pass
flagged) — idx14 doesn't resolve it, since Julia's own Hessian stays
under 1e3 here; a cell where *both* sides cross 1e3 (the remaining
candidate is idx24, `cond_H_r = 14137.7`, Julia pending) is still needed
to exercise the clause on its own terms. The toy-fixture finding the
multiplier was calibrated against (2.2e-2 discrepancy at cond≈1e6,
`parity-panel-2026-09-01.md:29-32`) remains far beyond anything measured
here.

### D-201 resize note (from `seff`/`sacct` on completed 21053691 tasks)

Measured, not extrapolated — `sacct -j 21053691_<idx>` / `seff` on the 7
completed tasks plus the timed-out idx24:

- Elapsed wall range: 16m52s (idx21, `nb2_p50_n500_K1`) to 1h13m50s
  (idx23, `nb2_p50_n2000_K1`) among the 7 completions; idx24
  (`nb2_p50_n2000_K2`) hit the 2h00m00s limit and was killed at 2h00m17s
  still running — its true wall is unknown but exceeds 2h.
- Memory: 418 MB (idx20) to 780 MB (idx15) `MaxRSS`, all against a 6 GB
  request (7–13% memory efficiency) — the array was never memory-bound.
- CPU efficiency ~99% throughout (98.5–98.9% measured on the two
  extremes) — these are compute-bound fits, not queueing artifacts.

**Recommendation for future p=50/n=2000 submissions**: the K=1 cells
(idx15, idx23) needed up to 1h13m50s — recommend **≥1h15m** as a floor,
but submit at **3 h** for margin (K=1 poisson/nb2 wall varies ~4x within
this grid, idx15 19m vs idx23 74m, so a tight floor risks a repeat
timeout); the nb2 K=2 cell (idx24) exceeded **2 h** outright — recommend
**5 h**. Memory: **1 GB** covers every measured cell (780 MB observed max)
with headroom, well below the 6 GB originally requested. This matches
what `21059449_[24]`'s actual resubmission already used (`--time=05:00:00
--mem=4G`) — 4G rather than the 1G recommended above is not wrong (still
comfortably inside 6h/8h queue tiers) but is more memory than measured
data supports needing.

### What remains

- **idx24 (`nb2_p50_n2000_K2`) pending** — job `21059449_[24]`,
  `--time=05:00:00 --mem=4G`, currently `PD` (priority) on Nibi. Once it
  lands this grid reaches 22/24 valid (all cells except the 2 invalid
  seed-mismatch pairs) and is the one cell that can test the contract's
  §4 scaling clause with both engines' cond(H) over 1e3 (R already at
  14137.7).
- **Owed: idx9 and idx17 need a re-run of the R driver with the grid's
  own seed** (1009, 1017) baked into the output filename or otherwise
  disambiguated from the STEP-1 spot-check outputs it silently reused —
  until then these two stay excluded from every statistic in this
  document.
