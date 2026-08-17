# Decision: AGHQ Stage-1a live-pin grid (not an estimator)

**Date:** 2026-08-17
**Status:** ACCEPTED for the grid + `k = 1` golden only
**Lane:** `cursor/aghq-stage1a-20260817`
**Depends on:** Identity `docs/dev-log/decisions/2026-08-17-aghq-identity.md` (#248)
**Do not** promote either AGHQ ledger row. **Do not** add a public `aghq=`
knob. **Do not** invent a twin Δ. **Do not** call `_gauss_hermite` and
relabel it.

## Provenance

Ported (read-only) from R `gllvmTMB` `R/fit-multi.R`:

- `.gllvmTMB_gh_normal(k)` — probabilists' (standard-normal) 1-D
  Gauss–Hermite: Jacobi off-diagonals `√(1:(k-1))`, weights = squared first
  eigenvector components; `k = 1` → node `0`, weight `1`.
- `.gllvmTMB_aghq_grid(d, k)` — tensor product with
  `logw_j = Σ_m log w_{j_m} + (d/2) log(2π) + ½ u_j'u_j`.
- `.gllvmTMB_aghq_grid_ok` — `Σ_j exp(logw_j) φ_d(u_j) = 1`, and for
  `k > 1` the second-moment identity `Σ_j w_j u_j u_j' = I`.

The peer helper `.aghq_grid` in `R/aghq-control.R` (physicists' nodes,
`exp(u'u)` + `(√2)^d`) is **not** the pin and is not implemented here.
Julia VA `_gauss_hermite` remains physicists' ELBO quadrature.

## What this slice ships

1. Internal `aghq_grid(d, k)` / `aghq_grid_ok` on the live pin.
2. Stage-1a `k = 1` evaluator that applies the twin template identity
   `log L_i = logdet_i + logw + inner_ll(ẑ)` and must match
   `laplace_loglik_site` / `poisson_marginal_loglik_laplace`.
3. Fail-loud if `k ≠ 1` or if the random part is not a single loadings-only
   `z_B` (row effects, phylo, `mi()`, free `s_B` / `unique`, `use_lv_B`,
   multinomial). The `k = 1` golden evaluates the grid identity; it does
   **not** port the twin's fit-time route that skips the AGHQ template.

Both AGHQ capability rows stay `missing`. This is A4 item (1) only.
