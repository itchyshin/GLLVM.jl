# After-task — twin-bridge headline estimand inventory (read-only)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (true-parity `/goal`, parallel inventory slice)  
**Branch:** `docs/twin-bridge-headline-inventory-20260915` from `origin/main` @ `25af0c0f1`  
**Scope:** Evidence map only — **no** engine edits, **no** ledger JSON mutation, **no** Totoro/DRAC
campaigns, **no** `Project.toml` bump, **no** covered-row promotion, **no** gllvmTMB engine surgery.

## Rose fence (read first)

- **This inventory ≠ true parity destination ≠ programme §7 closure ≠ harness `FREE=0` as user story.**
- **Live Δ** means an opt-in RCall test or tool asserts against gllvmTMB when
  `GLLVM_PARITY_TESTS=1` (or `CORE070_PARITY_REQUIRED=1` on the 17 family-smoke cells).
- **Receipt** means archived JSON / after-task numbers (Totoro or local batch) not wired as
  default CI parity gates.
- **Advisory-only** means one-sided bounds, `parameterisation_gap`, disputed Hessian, or
  bridge capability notes without a hard `@test` Δ gate.
- **Campaigns** (realistic-size grid, #323 frozen-R smoke, recovery at scale) stay **Totoro/DRAC
  only** — never GitHub Actions artifacts (**D-50**).

## Programme anchors

| Item | Path |
|------|------|
| Capability / bridge honesty | `docs/src/gllvmtmb-parity.md` |
| Ledger gap inventory | `docs/dev-log/after-task/2026-09-15-true-parity-ledger-gap-inventory.md` |
| Second-order inventory | `docs/dev-log/after-task/2026-09-14-second-order-parity-inventory.md` |
| Second-order contract | `docs/dev-log/core070/second-order-parity-contract.md` |
| D1 gate receipt | `docs/dev-log/core070/second-order-d1-gate-receipt-2026-09-04.json` |
| Parity suite entry | `test/parity/runparity.jl`, `test/parity/README.md` |
| RCall helpers | `test/parity/parity_helpers.jl` |
| Second-order batch driver | `tools/core070_second_order/cells.jl`, `run_cell.jl` |
| Twin capability join (read-only) | gllvmTMB `tools/parity_ledger.R` @ frozen oracle `b4d5fee6` |
| Machine table (this slice) | `docs/dev-log/core070/twin-bridge-headline-inventory-20260915.tsv` |

## Status legend

| Code | Meaning |
|------|---------|
| **live Δ** | `@test` (or required CORE-070 cell) compares Julia vs R at stated tolerance when parity env is on |
| **receipt** | Measured batch JSON / after-task; re-run via `tools/core070_second_order/` or dev parity, not default `runtests.jl` |
| **missing** | No paired RCall cell for this estimand on this route |
| **fenced** | Julia-only twin, bridge note “OWED”, disputed default, one-sided logLik bound, or `parameterisation_gap` — no promotion |

## Headline estimand × family/route

**Routes:** `no-X` = `value ~ 0 + trait + latent(0+trait|site,d=K,unique=FALSE)` (or family-specific twin shape); `+X shared` = one site-level covariate; `species-X` = `(0+trait):x`; `delta-shared` = two-part with `predictor=:shared` + twin-aligned dispersion grouping.

### logLik (first-order)

| Family / route | Status | Evidence |
|----------------|--------|----------|
| Gaussian no-X | **live Δ** | `test/parity/test_gaussian_parity.jl`; CORE-070 `NATIVE-01` |
| Binomial no-X (logit default) | **live Δ** | `test_binomial_parity.jl`; `NATIVE-02` |
| Poisson no-X | **live Δ** | `test_poisson_parity.jl` / `test_poisson_required.jl`; `NATIVE-03` |
| NB2 no-X (per-trait φ) | **live Δ** | `test_negbin_parity.jl`; public `fit_gllvm` → grouped; `NATIVE-06` |
| Beta no-X (per-trait φ) | **live Δ** | `test_beta_parity.jl` / `test_beta_required.jl`; `NATIVE-08` |
| Ordinal probit no-X | **live Δ** | `test_ordinal_probit_parity.jl`; `NATIVE-15` |
| Lognormal no-X | **live Δ** (parity) · **fenced** (bridge) | `test_lognormal_parity.jl`; bridge still prints “light RCall Δ still OWED” in `test_bridge_capabilities.jl` until receipt is wired into bridge notes |
| Truncated-Poisson no-X | **live Δ** (parity) · **fenced** (bridge) | `test_truncated_poisson_parity.jl`; bridge OWED same pattern |
| Truncated-NB2 no-X | **live Δ** | `test_truncated_nbinom2_parity.jl`; `NATIVE-12` |
| Gamma / NB1 / BetaBinomial no-X (per-trait disp.) | **live Δ** | `test_nox_dispersion_parity.jl`; `NATIVE-05/16/09` |
| Multinomial FE no-X | **live Δ** | `test_multinomial_parity.jl`; `NATIVE-17` |
| Student-t no-X | **fenced** (one-sided) | `test_studentt_parity.jl`: shared-σ arm `@test r.logLik >= jl - 1e-6`; species-σ arm tighter abs gate — not symmetric rtol 1e-6 |
| Tweedie no-X (shared / grouped power) | **live Δ** (relaxed atol) | `test_tweedie_parity.jl`; health + `_TW_LOGLIK_ATOL`, not 1e-6 rtol |
| Delta-lognormal / Delta-Gamma no-X (shared η) | **live Δ** | `test_delta_*_parity.jl`; PAID numbers in `gllvmtmb-parity.md` |
| Gaussian / Binomial / Poisson +X shared | **live Δ** | `test_x_covariate_parity.jl` |
| NB2 / Beta / Gamma / NB1 / Ordinal-probit / BetaBinomial +X shared | **live Δ** | same file (Arc 2 cohorts) |
| Poisson / Binomial species-X | **live Δ** | `test_species_x_parity.jl` |
| ZIP / ZINB / ZIB / Hurdle* / Ordered-beta / Beta-hurdle / CMP | **missing** | Julia engines exist; twin has no matching family or no parity scaffold |
| ZI Poisson / ZI NB2 / ZI Binomial (R 0.7 partial) | **missing** | gllvmTMB lane landed zi constructors; **no** `test/parity/*` cell in GLLVM.jl yet |
| Realistic-size paired logLik (p≥20, n≥500) | **receipt** | `second-order-d1-gate-receipt-2026-09-04.json` realistic_24cell; **Totoro** for full grid (`LOOP/arcs.md` #22) |

### Coef β / intercepts (fixed effects, link scale)

| Family / route | Status | Evidence |
|----------------|--------|----------|
| All standard no-X / +X logLik cells above | **missing** (explicit) | Parity suite compares **logLik** (and Gaussian Σ_y, σ); **no** suite-wide `@test β_jl ≈ β_R` — rotation / packing differs for loadings |
| Destination B bridge adapter | **receipt** | `test/test_destination_b_adapter_consumer.jl` checks `coefficients ≈ beta` for mocked JSON — not live gllvmTMB |
| Delta / Student / Tweedie parity files | **advisory-only** | Helpers return `b_fix`; printed for human diff, not gated |
| Core070 postfit R fixtures | **advisory-only** | `test/parity/fixtures/core070_postfit_contract.R` — contract routing, not MLE Δ |

**Honest read:** first-order **coef parity is not a headline gate** in the twin bridge today; agreement is inferred only where logLik + second-order SE receipts pass at each-own optimum.

### SE-Wald / vcov / Wald CI endpoints (second-order, where admitted)

| Family / route | Status | Evidence |
|----------------|--------|----------|
| Gaussian, Poisson, Binomial-logit/probit, Beta, NB2 no-X | **receipt** (D1 pass) | 20-cell batch + batch1 smoke in `second-order-d1-gate-receipt-2026-09-04.json` |
| Binomial-cloglog no-X | **fenced** | `hessian_selector_disputed`; batch ran with flag — **no claim** until §2 decision |
| Gamma / NB1 / BetaBinomial no-X (+ grouped pairing) | **receipt** | Same 20-cell batch |
| +X shared (Gaussian, Binomial, Poisson, NB2, Beta, Gamma, NB1, BetaBinomial) | **receipt** | 20-cell batch |
| Poisson / Binomial species-X | **receipt** | 20-cell batch |
| Realistic-size toy grid (24 cells) | **receipt** | JSON `se_d1_pass_fail_skip` 24/0/0 among β cells |
| Delta-lognormal / Delta-Gamma shared η | **fenced** | `test/test_second_order_delta_followup.jl`: live R only when `GLLVM_PARITY_TESTS=1`; **`parameterisation_gap`** (Julia shared σ vs R per-trait) — SE D1 **not** asserted |
| Lognormal / Truncated-Poisson / Truncated-NB2 | **missing** | No `confint(..., method=:wald)` on `LognormalFit` / `Truncated*` in `_CIFit` union (`second-order-batch-2026-09-03.md`) |
| Ordinal probit (per-trait cutpoints) | **missing** | Paired fixtures use `OrdinalPerTrait*Fit`; Wald dispatch on shared-cutpoint `OrdinalFit` only |
| Tweedie | **missing** | Contract §2 disputed default; no paired second-order fixture in batch 1 |
| Student-t (free ν) | **fenced** | Contract §6 holdout — Wald at ν boundary |
| GP-1 | **fenced** | Fisher-retained; holdout |
| Matched-coordinates θ transplant | **fenced** | `beta_logit`, `nb2_log` blocked (`second-order-matched-pilot-batch1-20260905.md`) |
| CI route adapter (B4) | **advisory-only** | `core070_inference_routes.tsv` — R-side routing expectations, not numerical Δ |

## CORE-070 required family smoke (17 cells)

When `CORE070_PARITY_REQUIRED=1`, `runparity.jl` runs **logLik-first** required cells
(`NATIVE-01` … `NATIVE-07`, etc.). Second-order is **not** part of that gate unless a
separate maintainer campaign is declared.

## Twin join (capability-status, read-only)

gllvmTMB `tools/parity_ledger.R` @ frozen oracle: **48 matched / 32 R-only / 33 J-only /
6 DIFFER** (same order of magnitude as Julia `tools/parity_ledger.py` on recent main).
Headline estimand receipts **do not** automatically promote a capability row — Rose fence
on the six **DIFFER** rows remains (#348 docs).

## Top 8 next local RCall cells (no Totoro; high leverage for honest 0.7)

Ordered for **measurable twin Δ** on headline estimands without multi-hour grids. Each
is runnable on a laptop with `GLLVM_PARITY_TESTS=1` and frozen `gllvmTMB` `b4d5fee6`
(unless noted as “new scaffold”).

| Rank | Cell | Estimand focus | Why high leverage | Runnable via |
|------|------|----------------|-------------------|--------------|
| 1 | **Lognormal no-X** | logLik | Clears bridge “OWED” fence; exact-vs-exact identity check | `test/parity/test_lognormal_parity.jl` (exists) |
| 2 | **Truncated-Poisson no-X** | logLik | Same bridge fence; fid 10 smoke already in required runner | `test/parity/test_truncated_poisson_parity.jl` |
| 3 | **Student-t no-X, `disp_group=:species`** | logLik | Tighten to symmetric rtol 1e-6 on per-trait σ twin — removes one-sided advisory | Extend `test/parity/test_studentt_parity.jl` |
| 4 | **ZI Poisson no-X** (new) | logLik | R twin landed `zi_poisson()` (partial); Julia ZIP engine — first honest zi headline | **New** `test/parity/test_zip_parity.jl` + helper |
| 5 | **ZI NB2 no-X** (new) | logLik | Same for `zi_nbinom2()` vs Julia ZINB | **New** `test/parity/test_zinb_parity.jl` |
| 6 | **Ordinal probit no-X** | SE-Wald | Biggest second-order hole among “green” logLik families — needs `_CIFit` for per-trait ordinal then `run_one_cell("ordinal_*")` | Engine slice + `tools/core070_second_order/` |
| 7 | **Lognormal no-X** | SE-Wald | Pairs with (1) once Wald dispatch exists | `confint_family.jl` + second-order tool |
| 8 | **Delta shared-φ alignment** | logLik + SE | Resolves `parameterisation_gap` so delta second-order can assert D1 | Identity decision + `cells.jl` / parity helper alignment |

**Explicitly not in this top-8 (Totoro/DRAC):** T4 full realistic-size second-order grid,
#323 frozen-R gradient-health smoke, multi-seed recovery, DRAC Wald **coverage** studies.

## Checks run (this slice)

- Read: ledger-gap inventory, second-order inventory, `gllvmtmb-parity.md`, `runparity.jl`,
  parity README, `second-order-d1-gate-receipt-2026-09-04.json`, bridge OWED tests,
  `test_second_order_delta_followup.jl`.
- **Not run:** `GLLVM_PARITY_TESTS=1` live suite (no R claim in this doc), `Pkg.test()`,
  Totoro.

## Follow-up

- Point true-parity `/goal` and pending board at this file for bridge evidence planning.
- Engine lanes own rows marked **missing** / **fenced** — this slice does not implement them.
