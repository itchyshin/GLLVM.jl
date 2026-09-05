# Matched-coordinates batch-1 pilot receipt (2026-09-05)

**Tier:** contract §4 matched-coordinates diagnostic (rel ≤ 1e-4 SE/vcov at R-anchored θ).  
**Anchor:** R `opt$par` → Julia packed θ via `tools/core070_second_order/theta_map.jl`.  
**Programme §7 claim:** **false** — this pilot does not complete the second-order programme.

## Result summary

| Cell | Status | se_max_rel | vcov_fro_rel | Notes |
|------|--------|------------|--------------|-------|
| gaussian | **pass** | 2.1e-7 | — | σ-only block; R `b_fix` excluded (Y pre-centred) |
| poisson | **pass** | 1.9e-7 | 1.8e-7 | Direct `b_fix` + `theta_rr_B` map |
| binomial_logit | **pass** | 4.2e-8 | 8.1e-8 | Direct `b_fix` + `theta_rr_B` map |
| beta_logit | **blocked** | — | — | R per-trait `log_phi_beta` (5) vs Julia shared `log(φ)` (1) |
| nb2_log | **blocked** | — | — | R per-trait `log_phi_nbinom2` (5) vs Julia shared `log(r)` (1) |

**Tally:** 3 pass / 0 fail / 2 blocked / 0 skip  
**Wall:** ~74 s local (OPENBLAS/OMP/JULIA_NUM_THREADS=1)  
**Base:** post-#281 merged tip (`origin/main` @ 51e43a4a)

## Object artifacts

- Summary: `docs/dev-log/core070/second-order-matched-pilot-batch1-20260905/summary.json`
- Per-cell JSON: same directory (`gaussian.json`, `poisson.json`, …)
- Driver: `tools/core070_second_order/run_matched_batch1.jl`
- θ map: `tools/core070_second_order/theta_map.jl`

## Blocker detail (beta_logit, nb2_log)

Each-own-optimum receipts compare only the `b_fix` / β block and can pass while dispersion
parameterizations differ. Matched-coordinates requires transplanting the **full** R parameter
vector into Julia's NLL domain. R's default `Beta()` / `nbinom2()` on the batch-1 formula
uses **per-trait** log-dispersion (`log_phi_beta` × p, `log_phi_nbinom2` × p); Julia's
batch-1 fitters use **one shared** log-dispersion. No honest map exists without changing
the model on one side.

## Claim boundary

- Passing each-own-optimum D1 (5/5 batch-1 smoke) does **not** imply matched-coordinates
  would pass for all five cells — now measured: 3/5 pass, 2/5 blocked on θ map.
- This pilot does **not** satisfy contract §7 programme-level second-order parity.
