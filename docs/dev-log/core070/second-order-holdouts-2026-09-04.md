# Second-order contract §6 holdouts (frozen list, 2026-09-04)

Source: `second-order-parity-contract.md` §6–§7. These families/cells are **out of the
first second-order batch claim** until the listed blocker clears.

| Holdout | Blocker | Disposition |
|---|---|---|
| Binomial-cloglog | ~~§2 disputed~~ **ACCEPTED (A) 2026-09-15** — `:observed` ratified | Each-own-optimum D1 promotable (`binomial_cloglog`); ≠ §7 |
| Tweedie shared + grouped | Default `:observed` ratified (A); **no Wald `_CIFit`** for grouped fit | First-order parity only; SO cell still not attempted |
| GP-1 | Fisher-retained; parity vs TMB Fisher alternative unsettled | Out of scope pending ruling |
| Student-t ν | Nonlinear boundary; Wald SE pathology (panel finding 4) | Batch 1 excluded |
| Ordinal per-trait cutpoints | **OrdinalPerTraitFit + OrdinalPerTraitCovFit ∈ `_CIFit` 2026-09-15** | Native Wald wired; bridge CI guards held (#357 foreign) |
| Lognormal, Truncated-Poisson, Truncated-NB2 | **LognormalFit + TruncatedPoissonFit + TruncatedNegBin2Fit ∈ `_FamilyFit` 2026-09-15** | Native Wald wired; bridge CI guards held for #357 |
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

**Summary:** OUT **8** · PARTIAL **3** · NOT ATTEMPTED **1** (plus batch-1 NB2 noted below)

| Holdout | Status | Reason (measured) | Evidence |
|---|---|---|---|
| Binomial-cloglog | **PARTIAL (SO promoted)** | §2 **(A)** 2026-09-15; `hessian_selector_disputed=false`; SE max rel Δ ≈ 2.1e-5 each-own-optimum | `docs/dev-log/core070/second-order-batch-out/binomial_cloglog.json` |
| Tweedie shared + grouped | NOT ATTEMPTED (SO) / PARTIAL (1st) | §2 default signed; no paired SO toy cell; `_CIFit` gap | `test/parity/test_tweedie_parity.jl`; no `core070_second_order` cell |
| GP-1 | OUT | Fisher-retained on Julia side; no ruling on whether R parity compares against a TMB Fisher alternative | Contract §6 lines 205–207; `GP1Fit` in `_CIFit` but no paired SO cell |
| Student-t ν (free) | OUT | Wald SE pathology at ν boundary (§3); `StudentTFit` ∉ `_CIFit`; no SO pairing | Contract §3 lines 120–123; `src/confint_family.jl:44-45` |
| Student-t fixed-ν | PARTIAL | First-order logLik parity exists; not in batch-1 or 20-cell SO window | Parity fixtures; no `core070_second_order` cell |
| Ordinal per-trait cutpoints | **PARTIAL (native Wald)** | `OrdinalPerTraitFit` / `OrdinalPerTraitCovFit` ∈ `_CIFit` + `_family_ci` (2026-09-15); bridge `ci_method` guard still refuses until post-#357 lift; no paired SO toy cell yet | `test/test_second_order_ordinal_pertrait_ci.jl`; `src/confint_family.jl` |
| Lognormal | **PARTIAL (native Wald)** | `LognormalFit` ∈ `_FamilyFit` + `_family_ci` (2026-09-15); bridge `ci_method` guard still refuses until post-#357 lift; no paired SO toy cell yet | `test/test_second_order_lognormal_ci.jl`; `src/confint_family.jl` |
| Truncated-Poisson | **PARTIAL (native Wald)** | `TruncatedPoissonFit` ∈ `_FamilyFit` + `_family_ci` (2026-09-15); bridge guard held; no paired SO cell | `test/test_second_order_truncpois_ci.jl` |
| Truncated-NB2 | **PARTIAL (native Wald)** | `TruncatedNegBin2Fit` ∈ `_FamilyFit` + `_family_ci` (2026-09-15); no paired SO cell; bridge untouched | `test/test_second_order_truncnb2_ci.jl` |
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
