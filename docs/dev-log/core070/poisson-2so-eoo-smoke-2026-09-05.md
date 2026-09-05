# Poisson each-own-optimum 2SO smoke — M2 Foundation day-2 (2026-09-05)

**Contract:** `docs/dev-log/core070/second-order-parity-contract.md` (signed 2026-09-05)  
**Claim boundary:** M2 Foundation smoke — **NOT** programme §7 second-order parity claim.

## Cell

Same DGP as batch-1 / D-220 poisson: seed=44, p=5, K=2, n=60, per-trait intercepts on log link,
each-own-optimum (`matched_coordinates=false`). Julia uses `:observed` Hessian (explicit override;
package default for LogLink is `:fisher`).

## Tolerances applied (each-own-optimum tier)

| Quantity | Contract | Measured | Pass |
|---|---|---|---|
| SE (β intercepts) rel Δ | ≤ 1e-2 (cond scale 1.0; r_cond=23.6) | 5.81e-6 | yes |
| vcov Frobenius rel Δ | ≤ 1e-2 | 1.09e-5 | yes |
| Wald CI endpoint | abs ≤ 1e-4 or rel ≤ 5e-2 half-width | 5.27e-6 | yes (abs) |
| logLik Δ | diagnostic | 6.75e-9 | — |

**eoo_smoke_pass: true** · wall ≈ 26.5 s (local, threads=1)

## Artifacts

- JSON receipt: `docs/dev-log/core070/poisson-2so-eoo-smoke-receipt-2026-09-05.json`
- Driver: `tools/core070_second_order/smoke_poisson_eoo.jl`

## Re-run

```sh
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  julia --project=. tools/core070_second_order/smoke_poisson_eoo.jl
```
