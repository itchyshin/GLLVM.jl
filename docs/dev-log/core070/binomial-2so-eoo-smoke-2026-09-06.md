# Binomial-logit each-own-optimum 2SO smoke — M2 remainder (2026-09-06)

**Contract:** `docs/dev-log/core070/second-order-parity-contract.md` §4  
**Claim boundary:** M2 remainder smoke — **NOT** programme §7 second-order parity claim.

## Cell

`binomial_logit` fixture: seed=43, p=5, K=2, n=60, each-own-optimum
(`matched_coordinates=false`). Observed Hessian override (package default for
LogitLink is Fisher).

## Tolerances applied (each-own-optimum tier)

| Quantity | Contract | Measured | Pass |
|---|---|---|---|
| SE rel Δ | ≤ 1e-2 (scale 1.0; r_cond=38.0) | 5.33e-6 | yes |
| vcov Frobenius rel Δ | ≤ 1e-2 | 6.44e-6 | yes |
| Wald CI endpoint | abs ≤ 1e-4 | 7.17e-6 | yes |
| logLik Δ | diagnostic | 1.82e-10 | — |

**eoo_smoke_pass: true** · wall ≈ 26.5 s · both Hessians PD · Julia and R converged.

Gate-tier **A7 remains partial** at toy EOO. This is not a matched-coordinate close.

## Artifacts

- JSON: `docs/dev-log/core070/binomial-2so-eoo-smoke-receipt-2026-09-06.json`
- Driver: `tools/core070_second_order/smoke_binomial_eoo.jl`
