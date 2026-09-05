# Gaussian each-own-optimum 2SO smoke — M2 Foundation day-1 (2026-09-05)

**Contract:** `docs/dev-log/core070/second-order-parity-contract.md` (signed 2026-09-05)  
**Claim boundary:** M2 Foundation smoke — **NOT** programme §7 second-order parity claim.

## Cell

Same DGP as D-220 / batch-1 gaussian: seed=42, p=5, K=2, n=80, trait-centred Y,
each-own-optimum (`matched_coordinates=false`).

## Tolerances applied (each-own-optimum tier)

| Quantity | Contract | Measured | Pass |
|---|---|---|---|
| SE (log σ_eps) rel Δ | ≤ 1e-2 (cond scale 1.0; r_cond=8.82) | 1.02e-6 | yes |
| vcov Frobenius rel Δ | ≤ 1e-2 or skip | null (1×1 σ block) | skip |
| Wald CI endpoint | abs ≤ 1e-4 or rel ≤ 5e-2 half-width | 9.20e-7 | yes (abs) |
| logLik Δ | diagnostic | 4.13e-9 | — |

**eoo_smoke_pass: true** · wall ≈ 36 s (local, threads=1)

## Artifacts

- JSON receipt: `docs/dev-log/core070/gaussian-2so-eoo-smoke-receipt-2026-09-05.json`
- Driver: `tools/core070_second_order/smoke_gaussian_eoo.jl`

## Re-run

```sh
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  julia --project=. tools/core070_second_order/smoke_gaussian_eoo.jl
```
