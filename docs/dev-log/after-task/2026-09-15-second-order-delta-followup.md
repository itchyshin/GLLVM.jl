# After-task — second-order Delta follow-up batch (rank 2 slice)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal`)  
**Branch:** `feat/second-order-delta-followup-20260915` from `origin/main` @ `0da63860`  
**Scope:** Delta-lognormal / Delta-Gamma shared-η Wald wiring + `core070_second_order` cells; **not** programme §7 closure; **not** holdout clearance for Lognormal/Truncated/Ordinal (still API gaps).

## Rose fence

- **≠** second-order parity or contract §7 complete.
- **≠** D1 pass at signed §4 tolerances for Delta cells (parameterisation gap — measured below).
- **=** Julia Wald path for `predictor = :shared` aligned to twin-identity packing; paired receipts **wired** with live Δ recorded.

## What landed

1. **`_family_ci` shared-η packing** for `DeltaLogNormalFit` / `DeltaGammaFit` (`beta[t]` block, single β in NLL) — `src/confint_family.jl`.
2. **`core070_second_order` cells** `delta_lognormal` / `delta_gamma` + `r_fit_se_delta` — `tools/core070_second_order/{cells,common}.jl`.
3. **Smoke drivers** `smoke_delta_{lognormal,gamma}_eoo.jl` (manual / receipt; **not** CI-gated pass).
4. **Tests** `test/test_second_order_delta_followup.jl` (Julia wiring always; R live Δ when `GLLVM_PARITY_TESTS=1` — records finite SE Δ, **does not** assert D1).

## Measured paired Δ (each-own-optimum, local R + frozen-style gllvmTMB)

| Cell | logLik Δ (J−R) | SE max rel Δ | vcov Fro rel Δ | CI endpoint max Δ | D1 smoke |
|------|----------------:|-------------:|---------------:|------------------:|----------|
| `delta_lognormal` (seed 61) | **−1.923** | **0.145** | **0.221** | **0.041** | **FAIL** |
| `delta_gamma` (seed 62) | (same class as parity fid 13) | **0.212** | **0.255** | **0.082** | **FAIL** |

**Blocker (unchanged from first-order parity):** R estimates **per-trait** dispersion (`sigma_lognormal_delta` / `phi_gamma_delta` CV); Julia default cells use **shared** scalar dispersion. Different models ⇒ different θ̂ ⇒ second-order comparison at §4 tolerances is **not** honest without a maintainer alignment choice (extend Julia `:species` Wald CI + cells, or pin R — no R engine edit in this slice).

## Holdout families not attempted

| Family | Reason |
|--------|--------|
| Lognormal, Truncated-Poisson, Truncated-NB2 | Still ∉ `_CIFit` — API gap |
| Ordinal per-trait | Still ∉ `_CIFit` |
| Binomial-cloglog / Tweedie grouped | §2 disputed default — **STOP** (no invented Hessian default) |

## Checks run

```text
julia --project=. test/test_second_order_delta_followup.jl   → 9 pass / 1 skip (no GLLVM_PARITY_TESTS)
julia --project=. tools/core070_second_order/smoke_delta_lognormal_eoo.jl → FAIL (measured; receipt written)
julia --project=. tools/core070_second_order/smoke_delta_gamma_eoo.jl     → FAIL (measured; receipt written)
```

**Not run:** full `Pkg.test()` (await CI).

## Next ranked slice

1. **T4 realistic-size second-order** (rank 1) — Totoro after `ack Totoro D-139 …`
2. **§2 disputed-default decision** (rank 3) — cloglog / Tweedie-grouped before promoting those cells
3. **Delta dispersion alignment decision** — unblock D1 for Delta SO (new maintainer fork; not started here)
