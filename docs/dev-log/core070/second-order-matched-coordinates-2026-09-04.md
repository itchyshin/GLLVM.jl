# Matched-coordinates second-order tier — disposition (2026-09-04, pilot 2026-09-05)

Contract §4 defines **two** tolerance tiers:

1. **Matched-coordinates** (rel ≤ 1e-4 SE/vcov) — both engines' Hessians at the **same** θ̂.
2. **Each-own-optimum** (rel ≤ 1e-2, R `cond(H)` scaling) — what users actually compare.

**Shipped tier for receipts today:** each-own-optimum only (`matched_coordinates=false` in
`tools/core070_second_order/cells.jl` and all 20-cell JSON receipts).

**Pilot (2026-09-05, batch-1):** `run_matched_batch1.jl` + `theta_map.jl` implemented;
**3/5 pass** (gaussian, poisson, binomial_logit), **2/5 blocked** (beta_logit, nb2_log —
R per-trait dispersion vs Julia shared). Receipt:
`docs/dev-log/core070/second-order-matched-pilot-batch1-20260905/`. No §7 claim.

**Why matched-coordinates was not implemented before the pilot:**

- Transplanting one engine's θ̂ into the other's packed parameter vector requires a
  per-family mapping (Λ rotation/sign, log-scale dispersions, NB grouped φ ordering).
- The 2026-09-03 batch explicitly deferred this as out of time box; contract §4 allows
  reporting matched-coordinates **alongside** each-own for attribution, not as a substitute.

**θ-map status after pilot:**

| Family | Map | Blocker |
|--------|-----|---------|
| Poisson-log, Binomial-logit | `b_fix` + `theta_rr_B` direct copy | — |
| Gaussian | `log_sigma_eps` + `theta_rr_B`; R `b_fix` excluded | — |
| Beta-logit, NB2-log | — | R per-trait dispersion (p) vs Julia shared (1) |

**Next construction (remaining):** grouped/shared dispersion alignment for beta/NB2, or
document permanent blocker if batch-1 formula cannot be made same-parameterization on both sides.

**Claim boundary:** Passing each-own-optimum under D1 does **not** imply matched-coordinates
would pass at 1e-4 for all batch-1 cells; pilot measured 3 pass + 2 blocked. Programme §7
remains **not done**.
