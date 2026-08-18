# Decision: multinomial / unordered-categorical Identity (twin fid 16)

**Date:** 2026-08-18
**Status:** ACCEPTED (Arc 0 / Identity docs-only)
**Lane:** `cursor/lane-parity-beyond-20260818`
**Programme:** `LOOP/` on this worktree (`gllvmjl-parity-beyond`)
**Twin pin:** `gllvmTMB` `origin/main` **`af1218d8`** (cites via `git show`; Dropbox working tree unused)
**Julia pin:** `GLLVM.jl` `origin/main` **`3d5acba0`**
**Depends on (contrast only):** ordinal cutpoint Identity `2026-08-03-ordinal-x-cutpoint-identity.md` — **do not reuse packing**
**Do not:** invent a twin Δ; open `src/`; alias `categorical()`; copy Design 123 as v1; touch `aghq_grid.jl`

Ledger row `multinomial / categorical` stays **`missing`**. This note is not a surface admit and not an engine.

## Problem

Twin `gllvmTMB` already admits unordered categorical as **`multinomial()`** (fid 16).
Julia on `3d5acba0` has **no** likelihood, **no** family marker, **no** test.
`docs/design/capability-status.md:91` is `missing`. The only `src/` hits are AGHQ
Stage-1a **ineligibility** (`src/families/aghq_grid.jl` — **owned by another lane;
do not edit**). Other `Categorical(` uses are **ordinal** simulation
(`Distributions.Categorical`). Without this lock, an engine risks aliasing the
imputation family, copying TMB’s `K−1` pseudo-row bookkeeping, or inventing a Δ.

## Twin cites (load-bearing)

| Surface | Evidence at twin `af1218d8` |
|---|---|
| Enum | `R/enum.R` `.valid_family["multinomial"] = 16L`. `R/fit-multi.R` `family_to_id` switch is authoritative |
| Constructor | `R/families.R` `multinomial(link = "logit", baseline = NULL)` — class `c("multinomial", "family")`. Non-logit aborts |
| **Not** `categorical()` | `categorical()` is the missing-**predictor** imputation family (Design 68 / `man/categorical.Rd`). **Do not alias** |
| Categories | Unordered **`K ≥ 3`**. `K < 3` aborts and redirects to `binomial(link = "logit")` (`R/gllvmTMB.R`) |
| Baseline | First factor level, or `multinomial(baseline = …)` via `relevel`. That category is **category 1** in engine order |
| η | **`η₁ ≡ 0`**. For `k = 2…K`: `η_k = β0_k + xᵀ β_k`. Softmax `P(y=k) = exp(η_k) / Σ_j exp(η_j)` with implicit `exp(0) = 1` on the baseline (Design 83 §2; `man/multinomial.Rd`) |
| Twin data encoding (TMB **only**) | One observation → **`K−1` contiguous pseudo-rows** `"<trait>:<cat_k>"`, `k=2…K`. `y_j ∈ {0,1}` = “observed == this contrast”; **all zero ⇒ baseline**. Grouped log-density once at the anchor row |
| TMB dens | `src/gllvmTMB.cpp` fid 16: `Σ_j y_j η_j − logsumexp(0, η₂, …, η_K)`, `L = K−1`. **`obs_loglik` errors** — not a per-row GLM |
| dpars | **`μ` only** — `K−1` linear predictors. **No φ, no ordinal cutpoints** |
| AGHQ | Twin `use_aghq` errors on fid-16 rows. Not an Identity shape |
| Reporting, not estimand | Softmax Gumbel residual `(π²/6)(I+J)` is added only by `extract_Sigma(..., link_residual = "auto")`. Not a fitted dpar |

## Symbolic Identity (Design 83 §2)

For one unordered categorical trait with declared baseline = category 1:

- `η₁ ≡ 0` (structural pin; softmax is shift-invariant).
- `η_k = β0_k + xᵀ β_k` for `k = 2, …, K` (no-X: intercepts only).
- `P(y = k) = exp(η_k) / Σ_{j=1}^{K} exp(η_j)` with `exp(η₁) = 1`.
- Free count: **`(K−1)(1+p)`**. Packing is **contrast-major**, name-keyed to
  categories `2…K` at the **same** declared baseline.
- Baseline relabel: logLik and `p_ik` invariant under fixed effects;
  **coefficients relabel**. Recovery compares at the same reference.
- `K = 2` is exactly binomial-logit — **not this family**.

No dispersion. No ordinal cutpoints (`τ₁ = 0` / `K−2` log-spacings are **fid 14**).

## Julia estimand (v1 — this Identity)

First engine (a **later** arc; **not this commit**) estimates one unordered
trait, fixed effects. LV is a second Identity.

| Item | Lock |
|---|---|
| Marker name | **`Multinomial`** — not `Categorical`, not `categorical()` |
| Support | `y ∈ {1, …, K}` (or a length-`K` one-hot). **`K ≥ 3`** fail-loud; `K = 2` → tell the user to use binomial-logit |
| Linear predictor | `K−1` baseline-category logits; **`η₁ ≡ 0`**; do not allocate a free baseline predictor |
| Probability | Softmax as above; **one softmax per observation** (site × trait) |
| Packing (no-X) | `[β_contrast]` length `K−1` |
| Packing (+X, later) | `[β_contrast; γ_contrast]` — free count `(K−1)(1+p)`, contrast-major, same declared baseline |
| Dispersion / cutpoints | **None** |
| Residual `(π²/6)(I+J)` | **Not** in the MLE. Reporting-only if a later extract arc wants it |
| One trait | One multinomial response per fit (twin also gates more than one) |
| Recovery | Same declared baseline; do not invent a Δ this arc |

If a later LV slice is opened: **`K−1` contrast loadings**, not one loading per
categorical trait. That is **not** v1.

## What Julia will **not** copy (TMB idiosyncrasy)

1. **`K−1` pseudo-row expansion** / `multinom_group_id` / `multinom_K_per_trait` /
   anchor-row + sibling no-ops. Keep integer (or one-hot) `y` and evaluate softmax
   once per observation.
2. **`obs_loglik` error + long-loop skip** — TMB bookkeeping, not the model.
3. **`log(1e-12)` AD floor** — defensive, not Identity.
4. **`(π²/6)(I+J)` as a packed parameter** (or MCMCglmm `(1/K)(I+J)` / `c²`).
5. **`(1|g)` baseline-vs-rest** — one draw added to every contrast; `sigma_re` is
   reference-specific; relabelling baseline **changes the model**. Not ordinary
   per-category RI. Not v1.
6. **Design 123 structured campaign** (phylo/animal/kernel `V`, spatial SPDE,
   cluster, 5-draws-per-species). Twin marks those partial / campaign-gated.
   Julia v1 = FE softmax only.
7. **AGHQ reject-as-shape** (twin cpp; Julia `aghq_grid.jl`). Do not edit that file.
8. **Ordinal fid 14 packing**, or collapsing `K−1` contrasts to one scalar `σ²_d`.
9. **`categorical()` / MD6c `mi_family == 3`** softmax prior — missing **predictor**.
10. **Map-off contrast `Ψ` / `unique()`** — twin covstruct fence, not softmax.

## Twin light Δ

**FORBIDDEN** until an engine exists. No number is quoted here. A later engine
arc may run a FE-only light RCall cell at rtol `1e-6` against twin fid 16; it
must not invent the cell in this note.

## Out of scope (this arc and v1 engine)

- Any `src/` file, including a stub `Multinomial` marker that would admit a capability
- `fit_gllvm` / `@formula` / bridge admit
- Design 123 / phylo `V` / spatial / `(1|g)` / AGHQ / VA
- Ordinal (fid 14) / `categorical()` MI / mixed-family / weights
- `link_residual` matrix / ADEMP / coverage
- Ledger promote (`missing` until engine + focused test)
- Tweedie T2–T5, `truncated_nbinom2` Arc1b, `lognormal` bridge (stamped on
  `LOOP/arcs.md` as later Phase P chips — **not this arc**)

## STOP / CONTINUE

Identity ACCEPTED → **STOP before engine.** Next programme arc that may open
`src/` is a **separate** P1 engine arc after this note is on a pushed branch
(OPEN GATE = sibling push/PR). Public capability stays `missing`.

Rose fences: ≠ `categorical()` alias ≠ invented Δ ≠ stub marker ≠ Tweedie
`fit_gllvm` admit ≠ AGHQ row promote ≠ Design 123 as v1.
