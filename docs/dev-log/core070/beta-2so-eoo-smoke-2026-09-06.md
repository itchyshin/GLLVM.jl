# Beta-logit each-own-optimum 2SO smoke — M2 remainder (2026-09-06)

**Contract:** `docs/dev-log/core070/second-order-parity-contract.md` §4  
**Claim boundary:** M2 remainder smoke — **NOT** programme §7 second-order parity claim.

## Cell

`beta_logit` fixture: seed=45, p=5, K=1, n=60, each-own-optimum.
Family default Hessian `:observed`. Shared φ (not per-trait matched θ).

## Tolerances applied (each-own-optimum tier)

| Quantity | Contract | Measured | Pass |
|---|---|---|---|
| SE rel Δ | ≤ 1e-2 (scale 1.0; r_cond=53.7) | 2.22e-6 | yes |
| vcov Frobenius rel Δ | ≤ 1e-2 | 5.99e-6 | yes |
| Wald CI endpoint | abs ≤ 1e-4 | 3.29e-6 | yes |
| logLik Δ | diagnostic | 5.97e-9 | — |

**eoo_smoke_pass: true** · wall ≈ 24.7 s · both Hessians PD · Julia and R converged.

Gate-tier **A9 remains each-own-optimum / θ-map-blocked**. This is not M2-R2.

## Artifacts

- JSON: `docs/dev-log/core070/beta-2so-eoo-smoke-receipt-2026-09-06.json`
- Driver: `tools/core070_second_order/smoke_beta_eoo.jl`
