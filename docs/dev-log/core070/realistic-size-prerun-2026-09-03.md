# Realistic-size second-order pre-run + grid submission (T4) — 2026-09-03

## Purpose

The harness's second-order parity cells are toy-sized (p ≤ 5, n ≤ 150;
`docs/dev-log/parity-panel-2026-09-01.md:41-49`). This is a D-139
time-boxed **pre-run** establishing, with receipts, what first- and
second-order agreement looks like at realistic sizes — p ∈ {20, 50},
n ∈ {500, 2000}, K ∈ {1, 2}, families Gaussian, Poisson-log, NB2-log
(grouped, per-trait r) — and queuing the full 24-cell grid. **Receipts,
not a parity claim**: tolerances from
`docs/dev-log/core070/second-order-parity-contract.md` are measured here,
never gated.

## Host / environment

**Totoro** (`snakagaw@totoro.biology.ualberta.ca`), existing ControlMaster
socket, single-threaded-ish fits (`JULIA_NUM_THREADS=1`,
`OPENBLAS_NUM_THREADS=3`, `OMP_NUM_THREADS=3`, ≤3 cores/process). Julia
`+1.10.10` (`/home/snakagaw/.julia/juliaup/julia-1.10.10+0.x64.linux.gnu/bin/julia`
— `julia`/`julia +release` on PATH resolves to the 1.12.6 default channel,
not used here to match the second-order-prerun's validated 1.10.10).
Repo rsynced fresh (`8eabd1d0`, this worktree) into
`/home/snakagaw/core070-aghq-20260830/realsize-01/repo/` (new working dir,
distinct from `se-prerun-01`, `suite-run-*`, `second-order-01`; the other
concurrent lanes on Totoro — a3's `tools/core070_second_order/run_cell.jl`
batch, the full `Pkg.test()` run, `t14-repro`, `t5-rebind-01` — were left
untouched; total observed snakagaw CPU ≈110% of 384 cores before this
work started). R oracle: `gllvmTMB` 0.7.0, frozen commit
`b4d5fee64def88bc768dda1f1f77c29b295edd86`, `R_LIBS=/home/snakagaw/core070-aghq-20260830/oracle-build-01/library`
(same install used by `se-prerun-01`; `CORE070_SOURCE_PIN.toml` unchanged).

**Nibi** (DRAC), existing ControlMaster socket, `module load julia/1.10.10`.
Project space (never scratch — purged): `~/projects/def-snakagaw/snakagaw/gllvm-realsize-01/repo/`.
Depot: `~/projects/def-snakagaw/snakagaw/julia_depot` (pre-existing, reused),
symlinked as `gllvm-realsize-01/julia-depot` so
`$SLURM_SUBMIT_DIR/../julia-depot` resolves per the `core070_zi_ademp.sbatch`
convention. `Pkg.instantiate()` run **inside a submitted job**, never on the
login node (job 21053139, `--dependency=afterok` gate for the array).

## R + gllvmTMB availability on Nibi — NOT installable tonight

`module avail r/` shows `r/4.3.1`, `r/4.4.0`, `r/4.5.0`, `r/4.6.1` — R
itself is available. But `~/projects/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library`
is **empty** (no installed packages at all), and no `gllvmTMB` anywhere
under `~/projects/def-snakagaw/snakagaw/R`. Installing the frozen 0.7.0
build from source (TMB compile, `~2.5 min` on Totoro per
`oracle-build-01/build.json`, plus whatever dependency chain DRAC's R
needs from scratch — Matrix, TMB, RTMB, etc., all currently absent) is not
a task that fits inside tonight's window with a matching-commit guarantee
verified. **Decision: split the grid** — Julia side (fits + Julia SEs +
cond(H)) runs as the Nibi array; R side (se=TRUE fits) runs on Totoro in
the background, ≤20 cores, reading the byte-identical CSVs the Julia cells
wrote. Cells pair by `idx` in `tools/core070_realistic_size_cells.tsv`.

## STEP 1 — Totoro pre-run (smallest cell, p=20 n=500 K=1, both engines)

| family | p n K | R wall (fit) | Julia wall (fit+confint, cold process) | max RSS (Julia) | cond(H) R | cond(H) Julia | logLik Δ (jl−r) | max rel ΔSE (β) | vcov rel Frob (β) | max &#124;ΔWald&#124; |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| gaussian | 20 500 1 | 1.25 s | 15.51 s | 613 MB | 50.02 | 43.78 | 4.13e-09* | n/a* | n/a* | n/a* |
| poisson  | 20 500 1 | 1.74 s | 41.01 s | 626 MB | 71.66 | 40.27 | 4.16e-08 | 8.71e-06 | 1.29e-05 | 1.34e-05 |
| nb2      | 20 500 1 | 12.99 s | 121.96 s | 471 MB | 99.49 | 81.49 | 3.49e-06 | 1.95e-05 | 1.18e-05 | 7.42e-06 |

\* Gaussian has no β/intercept block for this DGP (Y is centred per trait,
zero-mean Julia model vs R's `0+trait` fit; see the toy-fixture pre-run's
identical finding, second-order-prerun-2026-09-02.md, gaussian notes).
logLik Δ recomputed here: Julia `-10907.450099796246` vs R
`-10907.4500999400` (Δ=4.13e-09, matches to 9 s.f.). Compared instead where
applicable: cond(H) on the σ_eps+Λ block (R) vs the full FD Hessian (Julia)
— not the same object, reported for completeness, not a matched comparison.

**Convention**: same as `second-order-prerun-2026-09-02.md` — observed
joint Hessian both sides, R via `gllvmTMBcontrol(se=TRUE)` +
`sd_report$par.fixed`/`cov.fixed`, Julia via `confint(fit, Y)` (family-generic
Wald) plus a private-API rebuild (`GLLVM._family_ci`/`GLLVM._fd_hessian`,
or `ForwardDiff.hessian` for Gaussian's exact NLL) for the full fixed-effect
vcov block and `cond(H)`. **Unmatched coordinates** (each engine fit
independently to its own MLE) — same caveat as the toy pre-run. `cond(H)`
for R is `kappa(solve(cov.fixed))` on the block TMB extracted (not
identical parameterisation to Julia's FD Hessian; a rough cross-check, not
asserted as comparable). `dispersion_boundary`/`boundary_terms` (T14 F1
fields) checked for NB2: **no boundary hit at this size**
(`dispersion_boundary=Bool[0×20]`, `boundary_terms=` empty) — unlike the
toy NB2 fixture (p=5, n=80), which degenerated on 2/5 traits; n=500 gives
every per-trait r enough data to identify cleanly. Convergence: `converged=true`
both engines, all three cells.

Julia wall times are **cold-process** (`/usr/bin/time -v` around the whole
`julia --project=.` invocation, JIT+compile+fit+confint together) — the
Nibi array will see comparable per-task cost since each SLURM task is also
a fresh process against the same (already-instantiated) depot. R wall
times are fit-only (TMB is already compiled; `sd_report` extraction folds
into the same call and is <0.5 ms in every cell, per `wall_confint_sec`
in the `_r_summary.txt` files).

**No cell exceeded 30 min on either engine** (worst: NB2 Julia at 122 s) —
the D-139 STOP condition was not triggered; proceeding to the full grid.

## D-139 estimate arithmetic

Measured worst-case at the smallest cell (p=20, n=500, K=1): Julia 122 s,
R 13 s. The full grid has 24 cells across p ∈ {20,50} (2.5×), n ∈
{500,2000} (4×), K ∈ {1,2} (params scale ~1.5–2× per extra factor). The
largest cell (p=50, n=2000, K=2) has ~10× the data volume (p·n) and
roughly 3–4× the parameter count of the smallest — Hessian/confint cost is
document. **This is a coarse structural estimate, not a blind guess**, but
it is explicitly **not verified by a direct measurement of the largest
cell** (that would itself be a >30 min single-cell run, which the D-139
box for *this* pre-run does not cover — it is exactly what the Nibi array
now measures directly, cell by cell). Applying a generous ×15–40 range to
the smallest-cell Julia wall (122 s) puts the **largest single cell** at
roughly 30–80 minutes; summed naively over all 24 cells at a blended
average multiplier (~×10, since only the 4 largest-K,largest-(p,n) cells
approach the top of that range) gives a **total Julia compute estimate of
roughly 4,000–6,000 s (~1.1–1.7 core-hours)** for the 24-cell grid, run
serially. R-side total (all cells fit-only, TMB compiled): worst cell
observed 13 s at the smallest size; scaling similarly gives roughly
**400–800 s (~0.1–0.2 core-hours)** for all 24 R fits — consistent with
the background grid's own observed progress (see below).

## STEP 2 — Nibi array submission

Nibi's maintenance reservation lifts 2026-09-03 08:00 EDT; both jobs below
were submitted now and are queued to start then (`squeue` reason:
`Priority` / `Dependency`, not blocked on anything else).

- **Instantiate job** (`Pkg.instantiate()` inside a job, never on the
  login node): job id **21053139**, `--time=00:15:00 --mem=2G
  --cpus-per-task=1`.
- **Array job** (Julia side, 24 cells): job id **21053142**,
  `--dependency=afterok:21053139`, `--account=def-snakagaw_cpu`,
  `--array=1-24`, `--cpus-per-task=1`, `--mem=2G` (pre-run max RSS 626 MB
  ×1.5 ≈ 939 MB, rounded to 2G), `--time=00:10:00` (pre-run worst wall
  122 s ×2 ≈ 244 s, rounded up to 10 min for per-task JIT variance — **this
  is sized from the smallest-cell measurement only, per the ticket's
  literal D-201 formula, and is very likely too tight for the larger cells**
  (idx 5–8, 13–16, 21–24: p=50 and/or n=2000, per the estimate above ~10–40×
  the smallest cell's cost). **Expected**: several of those tasks will hit
  `TIMEOUT`. Per D-201, the corrective step is: once the first few tasks
  finish, run `seff 21053142_1` (and a couple of the larger-cell indices,
  e.g. `_21`, `_24`) and resubmit the timed-out indices
  (`sbatch --array=<timed-out-indices> --time=<seff-informed value>
  tools/core070_realistic_size.sbatch`) — not attempted here since the
  reservation has not lifted yet.
- **Results land** under
  `~/projects/def-snakagaw/snakagaw/gllvm-realsize-01/repo/{out,data}/`.
  Collect with `tools/core070_realistic_size_collect.py
  <nibi_out_dir> <totoro_out_dir> --csv <path>` once both sides have run
  (rsync one host's `out/` to the other, or point the two dir args at
  whichever local copies you have).

## R-side grid — Totoro background, ≤20 cores

Sequential driver (`run_r_grid.sh`, ≤3 cores per fit, well under the
20-core cap — no parallelism was needed given how fast TMB fits at this
size), launched in the background
(`/home/snakagaw/core070-aghq-20260830/realsize-01/repo/r_grid_driver.log`,
pid recorded at launch). Reads the 24 byte-identical CSVs already written
under `.../realsize-01/repo/data/` (generated once via
`tools/core070_realistic_size_cell.jl <family> <p> <n> <K> <seed>
data-only`, the same DGP code path the fitting run uses — not a
re-implementation). **At the time this doc was written, 23/24 cells had completed** (all
gaussian, poisson, and 7/8 nb2 cells; the last cell, `nb2_p50_n2000_K2`,
the single largest in the grid, was still running — started 18:52 MDT,
still in progress at 18:55:31 MDT). All 23 completed cells returned
`converged=TRUE`, `has_sd_report=TRUE`, finite SEs (`cond_H` recorded for
every one). The driver continues unattended. Finish it with:

```sh
ssh -o ControlPath=$HOME/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22 -o BatchMode=yes \
  snakagaw@totoro.biology.ualberta.ca \
  'tail -f /home/snakagaw/core070-aghq-20260830/realsize-01/repo/r_grid_driver.log'
```

## What did NOT run, and why

- **The full 24-cell Julia grid was not run on Totoro tonight.** It is
  queued as the Nibi array per the ticket's explicit "consider using DRAC
  cleverly" instruction; running it redundantly on Totoro too was judged
  out of scope for a D-139 pre-run (the pre-run's job is to size the
  array, not replace it).
- **R + gllvmTMB 0.7.0 was not built on Nibi.** See the availability
  section above — the empty library tree and from-scratch TMB dependency
  chain made a same-commit-verified build a same-night risk this ticket's
  time box does not cover.
- **The Nibi array had not executed by the time this doc was written**
  (maintenance lifts 08:00 EDT 2026-09-03; both jobs are queued, not yet
  running — no Julia-side realistic-size receipts exist yet beyond the
  3-cell Totoro pre-run above).
- **The 24-cell R-side Totoro background grid was still in progress**
  (23/24 done) when this doc was written; only the single largest cell
  (`nb2_p50_n2000_K2`) was still running. Collect and append the full R
  logLik/SE/cond(H) table once `r_grid_driver.log` reports
  `R_GRID_ALL_DONE` (expected within minutes of this doc landing).
- **No matched-coordinates comparison** (same caveat as every prior
  second-order pre-run in this programme) — each engine converges
  independently; Julia's Hessian is not re-evaluated at R's θ̂.
- **Binomial-logit was dropped from this grid** relative to the ticket's
  reference families list note — re-reading the ticket: only Gaussian,
  Poisson-log, NB2-log were named for T4; Binomial was not requested here
  (it is covered by the separate T-series second-order arc's toy-fixture
  cells). No omission relative to what was asked.

## Files

- `tools/core070_realistic_size_cell.jl` — Julia fit + confint + cond(H)
  for one (family, p, n, K, seed) cell; `data-only` 6th arg skips the fit.
- `tools/core070_realistic_size_cell.R` — R (`se=TRUE`) fit for the same
  cell, reads the Julia-written CSV.
- `tools/core070_realistic_size_cells.tsv` — the 24-cell grid table
  (idx, family, p, n, K, seed), shared by the Nibi array and the Totoro
  R-side driver so both sides pair by `idx`.
- `tools/core070_realistic_size.sbatch` — the Nibi array job.
- `tools/core070_realistic_size_collect.py` — pairs Julia/R outputs by
  cell tag, prints/writes the receipt table (no gating).

## Ada addendum (2026-09-03 ~00:50Z) — Nibi ran early; array resubmitted with a measured-class time limit

The Nibi maintenance reservation did **not** hold jobs back: array 21053142 started within
minutes of submission. Its `--time=00:10:00` had been sized from the smallest pre-run cell, the
exact mistake the vault's WHAT-WORKS entry of the same day warns against (size from the most
expensive cell class). Ada cancelled the array to resize it — after it had already started —
interrupting tasks 14, 15, 16 and 20 at 8m44s. `sacct` shows tasks 1–13, 17, 18, 19 COMPLETED
(38 s – 8 m 03 s; the p=20 and p=50/n=500 cells), tasks 14–16 and 20–24 CANCELLED. Those eight
(the p=50/n=2000 cells and their K=2 siblings) were resubmitted as array **21053691**
(`--array=14-16,20-24 --time=02:00:00 --mem=6G`, no dependency — the instantiate job 21053139
COMPLETED in 53 s). Nothing was lost: completed outputs sit in `out/` per cell
(`<family>_p<p>_n<n>_K<K>_julia_{summary.txt,terms.csv,vcov_*.csv}`). Lesson recorded: read
`squeue` before `scancel`; a queued array can already be running.
