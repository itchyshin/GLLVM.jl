# Second-order contract §6 holdouts (frozen list, 2026-09-04)

Source: `second-order-parity-contract.md` §6–§7. These families/cells are **out of the
first second-order batch claim** until the listed blocker clears.

| Holdout | Blocker | Disposition |
|---|---|---|
| Binomial-cloglog | §2 disputed default (`:observed` flip vs 2026-08-28 Fisher note) | Receipt with `hessian_selector_disputed=true` only; no claim |
| Tweedie shared + grouped | Same disputed-default class; no paired toy no-X/+X in arc | Not attempted |
| GP-1 | Fisher-retained; parity vs TMB Fisher alternative unsettled | Out of scope pending ruling |
| Student-t ν | Nonlinear boundary; Wald SE pathology (panel finding 4) | Batch 1 excluded |
| Ordinal per-trait cutpoints | No `confint(..., method=:wald)` on `OrdinalPerTrait*Fit` | API gap |
| Lognormal, Truncated-Poisson, Truncated-NB2 | No Wald `_CIFit` dispatch | API gap |
| Delta-lognormal, Delta-Gamma | In `_CIFit` but not reached in 20-cell window | Follow-up batch |
| Multinomial, BetaBinomial shared-φ | Scope discipline (per-trait pairing only in 20-cell) | Follow-up |
| Realistic Gaussian grid | Julia `confint` reports σ + Λ SEs; R pairs trait intercept `t1…tp` | **Estimand mismatch** — not a tolerance failure |
| Loadings Λ raw entries | Rotation ambiguity (§3) | Compare derived quantities or Procrustes (deferred) |

**Batch 1 (contract §6, five families):** Gaussian, Poisson-log, Binomial-logit, Beta-logit,
NB2-log — covered by toy 20-cell grid (superset) and merged-tip refresh
(`second-order-batch-out-20260904-merged-tip/`).
