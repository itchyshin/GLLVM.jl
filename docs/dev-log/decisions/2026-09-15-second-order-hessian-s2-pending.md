# Maintainer decision — second-order contract §2 (Binomial-cloglog + Tweedie grouped Hessian)

**Date:** 2026-09-15  
**Status:** **ACCEPTED** — option **(A)** ratify `:observed` as the twin-default Hessian selector for Binomial/cloglog and Tweedie grouped routes  
**Applied:** 2026-09-15 — **AGENT-APPLIED Ada default** (pending Shinichi reverse)  
**Lane:** Cursor / Ada (true-parity programme)  
**Base:** `origin/main` @ `3091fe61` (post–PR #347 second-order Delta follow-up)  
**Contract anchor:** [`second-order-parity-contract.md`](../core070/second-order-parity-contract.md) §2  
**Engine anchors (already on HEAD):** `src/families/binomial.jl` (`_default_hessian(::Binomial, ::CLogLogLink) = :observed`); `src/families/grouped_dispersion.jl` (`fit_tweedie_gllvm_grouped`, default `hessian = :observed`)  
**Prior brief conflict:** 2026-08-28 arc batch kept cloglog on Fisher in prose; 2026-09-01 round-1 opened investigation; code + `gllvmtmb-parity.md` already document `:observed` repair — contract §2 still flagged **disputed** until this disposition.

**Does not:** claim programme §7 complete; claim full 0.7 parity; change GP-1 Fisher retention; add Tweedie grouped Wald/`_CIFit` (API gap unchanged); bump `Project.toml`.

---

## Question

Should second-order receipts treat **Binomial/cloglog** and **Tweedie grouped** as using **`:observed`** Laplace curvature (matching TMB structural observed joint Hessian on the twin path), or revert to **`:fisher`** / keep **`hessian_selector_disputed=true`** forever in JSON receipts?

Measured each-own-optimum toy cell **`binomial_cloglog`** (seed 144): logLik Δ ≈ 7.8e-9; SE max rel Δ ≈ 2.1e-5; **`hessian_selector_disputed=true`** blocked promotion only.

---

## Options

### (A) Ratify `:observed` (align contract + receipts with current HEAD and R twin)

Accept that Julia defaults and paired receipts use **`:observed`** for cloglog and Tweedie grouped; set **`hessian_selector_disputed=false`** where the family default applies; update contract §2 stale "disputed" prose to cite this decision.

**Rose fence (binding if accepted):**

- **≠** programme §7 / true-parity destination complete.
- **≠** matched-coordinates tier promotion for Beta/NB2 (separate decision C).
- **=** Each-own-optimum D1 for **`binomial_cloglog`** may be cited for second-order **beta fixed-effect** blocks only (not loadings rotation; not §7 closure).
- **=** Tweedie grouped **first-order** parity remains valid via `test_tweedie_parity.jl`; **second-order SE** for grouped Tweedie stays **OUT** until `_CIFit` / Wald dispatch exists (holdout unchanged).

**Unlocks:** Honest promotion of existing cloglog SO receipt; clears rank-3 inventory blocker for those cells only.  
**Cost:** Docs + receipt JSON + `cells.jl` flag only — **no** engine edit required on HEAD.

### (B) Revert to `:fisher` defaults (2026-08-28 brief alignment)

Restore Fisher weight for cloglog and/or Tweedie grouped in `src/` to match the 2026-08-28 decision prose.

**Unlocks:** Single narrative with old brief.  
**Cost:** Engine regression vs R on cloglog (7.4e-12 quadrature evidence); **maintainer approval required** for likelihood parameterisation change.

### (C) Permanent disputed flag (no promotion)

Keep **`hessian_selector_disputed=true`** on cloglog/Tweedie receipts indefinitely.

**Unlocks:** No doc churn.  
**Cost:** Inventory rank-3 stays open; cloglog D1 evidence cannot be cited in programme receipts.

---

## Recommendation (Ada)

**Default (A)** while true-parity is active: code and `gllvmtmb-parity.md` already ratify `:observed`; the open item is **contract/receipt honesty**, not a fresh engine investigation.

---

## Maintainer reply contract (exact phrases)

| Action | Required reply |
|--------|----------------|
| Accept **(A)** — ratify `:observed` | **`accept §2 hessian A`** |
| Accept **(B)** — revert to Fisher | **`accept §2 hessian B`** |
| Accept **(C)** — keep disputed forever | **`accept §2 hessian C`** |

**Reverse (agent-applied default):** **`reject §2 hessian A`** (reopen pending) or choose **B|C** explicitly.

---

## ACCEPTED — 2026-09-15 (AGENT-APPLIED Ada default; pending Shinichi reverse)

**Option:** (A) — ratify `:observed` for Binomial/cloglog + Tweedie grouped Hessian selector on twin-default routes.

**Reply phrase (synthetic for record):** accept §2 hessian A

**Rose fence (binding):** see option (A) above.

**Does not unlock:** Tweedie grouped Wald second-order cell; programme §7; full parity claim.
