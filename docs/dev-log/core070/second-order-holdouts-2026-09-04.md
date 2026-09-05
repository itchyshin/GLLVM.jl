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

---

## Disposition pass (Option D, 2026-09-05)

**Scope:** contract §6 holdouts only. No programme-level second-order parity claim
(contract §7). Status legend:

- **OUT** — excluded from any batch claim until blocker clears
- **PARTIAL** — first-order or health-only / each-own-optimum receipts; no second-order bind
- **NOT ATTEMPTED** — no honest paired run in this arc

**Summary:** OUT **9** · PARTIAL **3** · NOT ATTEMPTED **1** (plus batch-1 NB2 noted below)

| Holdout | Status | Reason (measured) | Evidence |
|---|---|---|---|
| Binomial-cloglog | OUT | §2 disputed default; receipt flags `hessian_selector_disputed=true`; numeric D1 would pass but claim blocked | `tools/core070_second_order/out/binomial_cloglog.json` (`hessian_selector_disputed: true`, SE max rel Δ = 2.1e-5) |
| Tweedie shared + grouped | NOT ATTEMPTED | Disputed-default class (§2); no paired toy no-X/+X cell in 20-cell arc | Contract §2 lines 88–96; no `core070_second_order` cell |
| GP-1 | OUT | Fisher-retained on Julia side; no ruling on whether R parity compares against a TMB Fisher alternative | Contract §6 lines 205–207; `GP1Fit` in `_CIFit` but no paired SO cell |
| Student-t ν (free) | OUT | Wald SE pathology at ν boundary (§3); `StudentTFit` ∉ `_CIFit`; no SO pairing | Contract §3 lines 120–123; `src/confint_family.jl:44-45` |
| Student-t fixed-ν | PARTIAL | First-order logLik parity exists; not in batch-1 or 20-cell SO window | Parity fixtures; no `core070_second_order` cell |
| Ordinal per-trait cutpoints | OUT | `OrdinalPerTraitFit` / `OrdinalPerTraitCovFit` ∉ `_CIFit` Union | `src/confint_family.jl:44-45` vs `src/GLLVM.jl:262-263` |
| Lognormal, Truncated-Poisson, Truncated-NB2 | OUT (SO) / PARTIAL (1st) | `LognormalFit`, `TruncatedPoissonFit`, `TruncatedNegBin2Fit` ∉ `_CIFit`; logLik parity fixtures only | `src/confint_family.jl:31-45`; parity tests |
| NB2-log (batch-1) | PARTIAL (SO) | In batch-1 each-own-optimum receipts (20/20 SE D1 toy; 5/5 batch-1 smoke); **not** matched-coordinates; vcov full-block skipped on boundary | `second-order-d1-gate-receipt-2026-09-04.json`; `t14-nb2-wald-nan-diagnosis.md` |
| Delta-lognormal, Delta-Gamma | OUT | `DeltaLogNormalFit`/`DeltaGammaFit` ∈ `_CIFit` but absent from 20-cell window | `second-order-batch-2026-09-03.md` cell list |
| Multinomial, BetaBinomial shared-φ | OUT | 20-cell arc paired per-trait dispersion only; shared-φ grouping not attempted | `second-order-batch-2026-09-03.md` lines 37–39 |
| Realistic Gaussian grid | PARTIAL | **Repaired 2026-09-04:** intercept-`X` patch clears estimand mismatch; 8/8 realistic Gaussian cells SE D1 pass (max rel ΔSE β = 2.2e-5). Still outside toy batch-1 scope | `second-order-gaussian-intercept-disposition-2026-09-04.md`; `realistic-size-pairing-disposition-2026-09-04.md` |
| Loadings Λ raw | OUT | Rotation ambiguity (§3); compare derived Σ_y / communality / correlation instead | Contract §3 lines 108–119 |

**Advisory note (CI + local 0.7.1):** Retained pinned-build oracle remains authority
(`ci-oracle-reproducibility-finding.md`). Local live **0.7.1** smoke is receipt-only —
see `advisory-r071-smoke-2026-09-05.md` (NB2 health gate fails on advisory build; not
a holdout disposition upgrade).

**Claim boundary (§7):** A passing batch-1 or realistic-size D1 gate is wiring +
tolerance read on named fixture shapes only. It is **not** second-order parity,
matched-coordinates parity, coverage, or holdout clearance.
