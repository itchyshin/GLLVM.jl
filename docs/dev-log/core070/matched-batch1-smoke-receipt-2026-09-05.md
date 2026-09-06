# Matched batch-1 smoke after M2-R1 θ-map implement (2026-09-05)

**Command** (worktree `~/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904`,
HEAD `c37ada2e`):

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  julia --project=. tools/core070_second_order/run_matched_batch1.jl \
  logs/matched-batch1-post-r1-20260905
```

**Start:** 2026-09-05T18:16:46-06:00  
**End:** 2026-09-05T18:18:43-06:00  
**Wall:** 91.6 s (process ~117 s including Julia startup)  
**Exit:** 0  
**Tally:** pass/fail/blocked/skip = **5/0/0/0**

Branch: `cursor/m2-r1-theta-map-implement-20260905` (draft PR #301).  
Anchor: R `opt$par` → Julia packed θ via `tools/core070_second_order/theta_map.jl`.  
Tier: contract §4 matched-coordinates diagnostic (rel ≤ 1e-4 SE / vcov).  
**Programme §7 claim: false.** This is a harness smoke, not second-order programme completion.

## PASS / FAIL

| Cell | Status | `matched_pass` | se_max_rel | vcov_fro_rel | logLik Δ | Julia θ len | R `log_phi_*` |
|------|--------|----------------|------------|--------------|----------|-------------|---------------|
| gaussian | **PASS** | true | 2.13e-7 | 4.26e-7 | 3.41e-13 | 10 | — (`log_sigma_eps`=1) |
| poisson | **PASS** | true | 1.92e-7 | 1.84e-7 | 2.09e-11 | 14 | — |
| binomial_logit | **PASS** | true | 4.18e-8 | 8.10e-8 | 8.24e-12 | 14 | — |
| beta_logit | **PASS** | true | 1.06e-7 | 1.79e-7 | 4.26e-13 | 15 | `log_phi_beta`=5 (=p) |
| nb2_log | **PASS** | true | 1.91e-7 | 2.48e-7 | 1.71e-12 | 19 | `log_phi_nbinom2`=5 (=p) |

## What changed vs the pre-R1 pilot

The 2026-09-05 morning pilot (`second-order-matched-pilot-batch1-20260905`,
HEAD `9a4b24bd`) was **3 pass / 0 fail / 2 blocked**. `beta_logit` and `nb2_log`
were blocked on a false length rule (R per-trait `|log_phi_*|==p` vs a harness
that only accepted shared length 1).

After `c37ada2e` (`map_r_theta_glm` accepts `|log_phi_*| ∈ {1, p}`):

- **beta_logit now maps.** No length block. `julia_theta_len=15` matches
  `b_fix(5)+theta_rr_B(5)+log_phi_beta(5)`.
- **nb2_log now maps.** No length block. `julia_theta_len=19` matches
  `b_fix(5)+theta_rr_B(9)+log_phi_nbinom2(5)`.

Both cells are inside the 1e-4 matched-coordinates SE/vcov tolerances.

## Honest caveats (nb2_log)

The NB2 cell still printed:

- Julia: grouped-dispersion boundary warning — groups `[1, 3]` have `r_group`
  outside `[1e-6, 1e6]`; optimizer flags for those groups are unreliable.
- RCall: `Warning in sqrt(diag(cv)) : NaNs produced` (twice).

The driver still returned `pilot_status=pass` / `matched_pass=true` and the
process exited 0. That is the smoke result; it is not a claim that the NB2
Wald/vcov surface is healthy on every diagnostic.

The driver's `summary.json` `note` field is **stale** (still says beta/nb2
are expected blocked). Trust the tally `5/0/0/0` and the per-cell JSON, not
that note.

## Artifacts

- Per-cell JSON + summary:
  `docs/dev-log/core070/second-order-matched-pilot-batch1-post-r1-20260905/`
- Raw run log (not committed): `logs/matched-batch1-smoke-20260905.log`
- Pre-fix contrast:
  `docs/dev-log/core070/second-order-matched-pilot-batch1-20260905/`

No `src/` edit. No R engine edit. No merge of #297 / #298 / #301.
