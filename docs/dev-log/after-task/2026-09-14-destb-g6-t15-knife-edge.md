# Destination B — G6 T15 knife-edge fixture audit (list first)

**Date:** 2026-09-14  
**Lane:** `cursor/honest-070-destb`  
**Authority:** `docs/dev-log/core070/true-parity-decision-map.md` T15; post-T14 receipt in G5.

## Scope

Audit-only slice: **inventory** parity/bridge/confint fixtures that sit on dispersion,
Hessian, or Wald **knife-edges** (can flip pass/fail or NaN/`Inf` across Julia
version / BLAS). **No test or engine edits** this turn — dispositions only.

## Inventory (18 fixtures)

| # | Fixture / location | Risk | Disposition |
|---|-------------------|------|-------------|
| 1 | NB2 bridge `_bx_sim(3,70,seed=523)` degenerate Wald | Known Poisson-limit boundary; was CI regime A/B flip pre-T14 | **KEEP + document** — explicit degenerate case (`test_bridge_x.jl`, T14 F2) |
| 2 | NB2 bridge `_bx_sim(3,200,seed=523,nb_r=2,intercept=1.5)` well-conditioned Wald | Identity check; asserts `!dispersion_boundary` | **KEEP** — F2 well-conditioned DGP |
| 3 | NB2 `grouped_dispersion` seed-523 replicate | Same DGP as #1 | **KEEP + document** — F1 boundary flag test |
| 4 | NB2 `confint_family` seed-523 Wald degradation | Partial NaN on boundary `r[g]` only | **KEEP + document** — T14 F1 receipt |
| 5 | NB2 `confint_family` forced `r=[1e12]` (RNG 9001) | Deterministic boundary without optimizer luck | **KEEP** — red-first F1 contract |
| 6 | NB2 `confint_family` PD shared-dispersion (seed 4901) | Interior reference | **KEEP** — PD regression anchor |
| 7 | `test_known_sentinel_defects` seed 104 grouped-cov “healthy” | One group hits `dispersion_boundary`; must not look like sentinel | **KEEP** — assertion `converged == !any(dispersion_boundary)` (T14 F1 alignment) |
| 8 | Grouped NB2 trait boundary `StableRNG(202609091)`, r=[5,12] | FD Hessian PD sign + interval `:partial`/`:invalid_curvature` BLAS knife-edge | **DOCUMENT known-fail class** — invariant: `nb2_size[2]` never `:available` (already in test comments) |
| 9 | Grouped NB2 trait interior same seed, r=[5,3] | Paired interior control for #8 | **KEEP** |
| 10 | Precision multivariate 16-tip unique boundary (`StableRNG(20260900)`) | Structural variance collapse + BLAS-sensitive `:invalid_curvature` vs `:available` | **DOCUMENT** — structural boundary stable; coarse CI status not cross-version |
| 11 | Precision multivariate 32-tip intermediate (`MersenneTwister(20260907)`) | Julia-1.10-only `:invalid_curvature` artifact per file comment | **DOCUMENT** — retained diagnostic; assertion weakened to self-consistent status |
| 12 | Bridge Beta grouped-cov Wald seed 524 | Light parity cell; not flagged knife-edge in diagnosis | **KEEP** — monitor only |
| 13 | Bridge Gamma grouped-cov Wald seed 525 | Same | **KEEP** — monitor only |
| 14 | Tweedie confint seed 3 (repaired from seed 35) | Prior seed 35: flat `(φ,p)` ridge, platform phi SE flip | **KEEP** — **retarget already done** (2026-08-03 comment in `test_confint_family.jl`) |
| 15 | Tweedie `_tweedie_verdict` stall vector (~1e15 gradient) | Unit-level, not a fit fixture | **KEEP** — documents stall class |
| 16 | `destination_b_joint_other_families` grouped FD Hessian notes | BLAS knife-edge on interval path | **DOCUMENT** — no change; cross-ref DestB joint receipts |
| 17 | `destination_b_grouping_interval_matrix` marginal-curvature knife-edge | B1 closed-as-limit programme; not NB2 Wald | **DOCUMENT out of T14/T15 fix scope** |
| 18 | Cross-Julia well-conditioned seed for legacy 3×70 NB2 shape | ~35k search failed (check-log 2026-09-02) | **DOCUMENT open** — F2 uses alternate DGP (#2); no silent retarget of #1 |

## Summary

| Disposition | Count |
|---|---:|
| KEEP (stable or intentionally degenerate) | 11 |
| KEEP + document (named degenerate / boundary) | 4 |
| DOCUMENT known-fail / BLAS knife-edge (no edit) | 4 |
| Retarget already applied (historical) | 1 |
| Fix this slice | **0** |

**Audited fixtures:** **18** (focused on T15/T14/true-parity map callouts; not exhaustive over all `test/` seeds).

## Rose fence

Listing ≠ promoting parity. Several rows are **intentionally** degenerate to lock
behaviour (seed-523 family). Do not retarget #1/#3/#4 without a maintainer sweep.

## Verification

Static audit (grep + file read). No `Pkg.test()` this slice.

## Next programme slice

**G7** — advisory Frozen R smoke (#323) scoping / handoff (Totoro; Codex lane per G0 Q3).
