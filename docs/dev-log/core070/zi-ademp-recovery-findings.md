# ZI-trio ADEMP recovery campaign — findings (2026-09-02, Totoro)

**Campaign:** `zi-ademp-01` · **Host:** Totoro (snakagaw@totoro.biology.ualberta.ca)
**Window:** 2026-09-02T11:57:07Z → 2026-09-02T14:06:54Z (`zi-full.start`/`zi-full.end`)
**Decision:** maintainer round2-3 #12 — zip/zinb/zib ship as **JULIA-BEYOND**
capability (no R twin exists to pair against), so this is simulation-based
recovery evidence, **not parity**.
**Commit context:** df7009b3 (decision/context commit referenced by the task
brief) · worktree HEAD 56edda5e, branch `codex/core070-aghq-20260830`.

## ADEMP

- **Aim** — can `fit_zip_gllvm` / `fit_zinb_gllvm` / `fit_zib_gllvm` recover
  the DGP they are fitted to, across a small grid of p and n?
- **Data** — per-cell truth pinned by `cell_rng = Xoshiro(9100 + 13p + n)`
  (`Λ_true`, `βc_true` conditional/count intercepts, `βz_true` zero-inflation
  intercepts, `r_true = 2.0` for zinb); per-seed draws via `Xoshiro(300_000 +
  seed)`, seeds 1–500 per cell.
- **Estimand** — βz (zero-inflation intercepts), βc (count/conditional
  intercepts), and the rotation-invariant Λc·Λcᵀ (relative Frobenius error).
- **Methods** — `fit_zip_gllvm`, `fit_zinb_gllvm`, `fit_zib_gllvm` at
  defaults, K=1 latent factor, N_TRIALS=5 for zib.
- **Performance** — convergence rate (fitter's own gate) with Monte-Carlo SE
  = √(r(1−r)/n); over converged fits, mean/median βz and βc bias/RMSE and
  crossprod relative error (median + p90); fit_seconds (median + max).
  Failures are recorded (`converged=false`), never dropped.

## Provenance

- Remote: `/home/snakagaw/core070-aghq-20260830/zi-ademp-01/repo/{zi-out/*.csv,
  zi-ademp.joblog, zi-full.start, zi-full.end}`.
- Local copy: `docs/dev-log/core070/zi-ademp-out/` (this dir): `zi-out/` (240
  CSVs) + `zi-ademp.joblog` + `zi-full.start` + `zi-full.end`.
- **Joblog totals:** 240 rows (12 cells × 20 chunks of 25 seeds), **0**
  non-zero `Exitval`, all `Signal` = 0.
- **Row totals:** 6,000 data rows (240 files × 25 rows), **0** rows with
  `converged=error` (worker's own `try/catch` never fired — every fit either
  returned a fitted object with `converged ∈ {true,false}` or the process
  itself would have shown as a non-zero joblog exit, which none did).
- **Seed integrity:** every one of the 12 (family, p, n) cells has exactly
  500 rows and 500 **unique** seeds (1–500); zero duplicate seed rows in any
  cell.
- **sha256 of the 240 CSVs concatenated in sorted-filename order:**
  `3e30ff1d58fd32494d3fda920ac9a180c78cf48395403b8476cb130b7650fe54`.

## Per-cell results (converged-only unless noted; MCSE on convergence rate)

| family | p | n | conv (n) | conv rate (MCSE) | βz bias mean/med | βz RMSE mean/med | βc bias mean/med | βc RMSE mean/med | Cerr med/p90 | fit_s med/max |
|---|---|---|---|---|---|---|---|---|---|---|
| zip  | 5  | 50  | 500/500 | 100.0% (0.00pp) | −1.213 / −0.342 | 2.834 / 0.901 | −0.177 / −0.173 | 0.467 / 0.455 | 1.245 / 2.035 | 1.09 / 4.69 |
| zip  | 5  | 200 | 500/500 | 100.0% (0.00pp) | 0.001 / 0.056  | 0.486 / 0.356 | −0.033 / −0.032 | 0.179 / 0.173 | 0.466 / 0.774 | 4.19 / 10.11 |
| zip  | 25 | 50  | **175/500** | **35.0% (2.13pp)** | −2.463 / −0.797 | 7.155 / 3.857 | −0.059 / −0.061 | 0.367 / 0.365 | 1.034 / 1.358 | 68.3 / 173.2 |
| zip  | 25 | 200 | 481/500 | 96.2% (0.86pp) | 0.009 / 0.014  | 0.568 / 0.365 | 0.147 / 0.000 | 0.307 / 0.167 | 0.313 / 0.935 | 172.2 / 932.5 |
| zinb | 5  | 50  | 500/500 | 100.0% (0.00pp) | −0.681 / 0.015 | 2.229 / 0.908 | −0.142 / −0.119 | 0.605 / 0.580 | 1.889 / 3.022 | 3.26 / 12.76 |
| zinb | 5  | 200 | 496/500 | 99.2% (0.40pp) | −0.349 / 0.003 | 1.238 / 0.515 | −0.079 / −0.076 | 0.305 / 0.298 | 0.833 / 1.302 | 9.17 / 43.18 |
| zinb | 25 | 50  | **350/500** | **70.0% (2.05pp)** | −0.981 / −0.419 | 4.457 / 3.487 | 0.009 / 0.004 | 0.468 / 0.458 | 1.483 / 1.906 | 129.8 / 373.7 |
| zinb | 25 | 200 | 493/500 | 98.6% (0.53pp) | 0.237 / 0.131 | 0.493 / 0.448 | 0.262 / 0.036 | 0.434 / 0.239 | 0.435 / 0.951 | 162.3 / 1515.2 |
| zib  | 5  | 50  | 500/500 | 100.0% (0.00pp) | 0.024 / 0.049 | 0.373 / 0.318 | −0.032 / −0.017 | 0.269 / 0.220 | 0.911 / 2.319 | 0.63 / 4.97 |
| zib  | 5  | 200 | 500/500 | 100.0% (0.00pp) | 0.079 / 0.082 | 0.177 / 0.177 | 0.002 / 0.003 | 0.102 / 0.099 | 0.408 / 0.611 | 2.27 / 6.41 |
| zib  | 25 | 50  | 500/500 | 100.0% (0.00pp) | −0.014 / −0.010 | 0.357 / 0.338 | −0.025 / −0.024 | 0.231 / 0.227 | 1.009 / 1.425 | 12.4 / 58.2 |
| zib  | 25 | 200 | 500/500 | 100.0% (0.00pp) | 0.028 / 0.030 | 0.172 / 0.170 | −0.009 / −0.006 | 0.116 / 0.105 | 0.297 / 0.444 | 55.4 / 686.8 |

**All-fits (incl. non-converged, where numeric) sanity check** for the two
cells with material non-convergence — reported to show the conditioning
matters, not to substitute for the converged-only numbers above:

- zip p=25,n=50 (325 non-converged of 500): all-fits βz bias mean/med
  −1.684/−0.939 (converged-only: −2.463/−0.797) — the failing 65% pull the
  mean toward zero because their (unreliable) point estimates are less
  extreme, not because they are better fits.
- zinb p=25,n=50 (150 non-converged of 500): all-fits βz bias mean/med
  −1.009/−0.548 (converged-only: −0.981/−0.419) — same direction of effect,
  smaller magnitude.
- All other 10 cells: all-fits and converged-only summaries match to 3–4
  decimals (≤19/500 non-converged, mostly 0).

**Timing:** p=5 cells all finished with fit_seconds well under 15 s median.
p=25 cells are far more expensive: zip p=25,n=50 median fit_seconds = 68.3 s
(converged-only) / 101.3 s (all fits, since the joblog brief's ~110 s/fit
figure blends converged and non-converged wall time within the same chunk);
zinb p=25,n=200 max fit_seconds reaches 1515 s (one outlier fit); zib
p=25,n=200 max reaches 687 s. No chunk exceeded its allotted wall time (0
non-zero joblog exits).

## Findings

1. **zib (Bernoulli/Binomial, N_TRIALS=5) recovers cleanly everywhere
   tested**: 100.0% convergence in all four (p,n) cells, βc RMSE
   monotonically halving n=50→n=200 (p=25: 0.231→0.116), crossprod relative
   error dropping with n. This is the cleanest of the three families across
   the whole grid.
2. **zip and zinb recover well at p=5 and at p=25,n=200**, all ≥96.2%
   convergence, with the expected bias/RMSE shrinkage as n grows
   (e.g. zip p=5: βc RMSE 0.467→0.179; zinb p=5: βc RMSE 0.605→0.305).
3. **The worst cell is zip, p=25, n=50: 35.0% convergence** (175/500,
   MCSE 2.13pp) — the majority of fits at this small-n/larger-p corner do
   not converge under the fitter's own gate. Among the fits that do
   converge, βz bias is large (mean −2.463, median −0.797) and βz RMSE is
   the largest anywhere on the grid (mean 7.155, median 3.857), while βc and
   crossprod stay reasonable (βc RMSE 0.367, Cerr median 1.034). This reads
   as an information-poverty/small-n boundary specific to the zero-inflation
   intercepts at p=25, n=50 — structurally analogous to the Bernoulli-family
   boundary documented in the sibling DRAC recovery campaign
   (`drac-recovery-campaign-findings.md`), but sharper here (35.0% vs 21.8%
   convergence for that campaign's worst binomial cell).
4. **zinb, p=25, n=50 is the second-worst cell**: 70.0% convergence
   (350/500, MCSE 2.05pp), with βz RMSE mean 4.457/median 3.487 among
   converged fits — again the zero-inflation intercepts, not the count
   parameters, carry the recovery difficulty.
5. **Both problem cells sit at the same (p=25, n=50) corner** — the smallest
   n paired with the larger p in this grid. n=200 at p=25 recovers to
   96.2–98.6% for zip/zinb, so the boundary is driven by n, not p alone.
6. **Crossprod relative error (Λc Λcᵀ) is well-behaved across every cell**,
   generally in the 0.3–1.9 range at the median even in the two problem
   cells — the loading recovery degrades far less than the zero-inflation
   intercept recovery does, suggesting the convergence failures are
   concentrated in the βz sub-problem rather than a global fit collapse.

## Honest limits

- **Λ_z = 0 by construction**: the DGP uses **intercept-only** zero-inflation
  (`betaz_true` only, no zero-inflation loadings), so this campaign says
  nothing about recovery when zero-inflation itself depends on a latent
  factor.
- **Single K=1** latent factor throughout; no multi-factor recovery tested.
- **N_TRIALS=5 fixed** for zib; no sweep over trial count.
- **No coverage/SE evaluation** — this campaign checks point-estimate
  bias/RMSE and the fitter's own convergence gate only, not CI coverage
  (unlike the sibling DRAC coverage campaign for the non-ZI families).
- **No R comparison exists** — by design (decision #12): these three
  families are JULIA-BEYOND, so there is no `gllvmTMB` twin to validate
  against. All evidence here is internal (simulation-based recovery), never
  parity.
- **Grid is {p∈{5,25}} × {n∈{50,200}} only** — no evidence for cells outside
  this grid, and specifically no evidence between n=50 and n=200 (e.g.
  n=100) or between p=5 and p=25.

## What is NOT claimed

- Not a parity comparison (no R fits exist for zip/zinb/zib).
- Not a CI-coverage claim (no SEs or intervals evaluated in this campaign).
- Not a claim that zip/zinb are production-ready at p=25, n=50 — that cell
  (and to a lesser extent zinb at the same corner) should be treated as a
  **documented limitation**, not a supported capability, until either the
  fitter improves at that corner or a health warning is added analogous to
  the Bernoulli small-n warning from the DRAC recovery campaign.
- Not evidence about zero-inflation-on-a-latent-factor models, multi-K
  fits, or non-default N_TRIALS.
