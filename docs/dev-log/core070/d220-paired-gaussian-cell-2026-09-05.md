# D-220 paired cell proof — Gaussian `latent()` bare (2026-09-05)

**Lane:** `cursor/m2-foundation-day1-20260905` · **Integrator:** Cursor coordinator  
**Claim boundary:** parity evidence only — **NOT** a true-parity claim.

## What this proves

One live R↔Julia paired cell on the Cursor twin lane: Gaussian identity +
ordinary `latent(0+trait|site,d=K,unique=FALSE)`, shared fixture with
`test/parity/test_gaussian_parity.jl` and the `core070_second_order` gaussian cell.

## Pins

| Item | Value |
|---|---|
| Oracle (export surface) | `b4d5fee64def88bc768dda1f1f77c29b295edd86` (gllvmTMB 0.7.0) |
| Live R package | `0.7.1` (installed; version recorded in receipt) |
| Julia HEAD | `ede4e2d7` @ branch `cursor/m2-foundation-day1-20260905` |
| Fixture | seed=42, p=5, K=2, n=80, trait-centred Y |

## Outcome

| Metric | Value | Gate |
|---|---|---|
| Δ logLik (jl − r) | 4.13e-9 | ≤ 1e-6 |
| Δ σ_eps (abs) | 7.79e-7 | rel ≤ 1e-4 |
| ‖Σ_y‖ Frobenius delta | 1.29e-5 | rel ≤ 1e-4 |
| Julia / R converged | true / true | both |

**first_order_pass: true**

## Artifacts

- JSON receipt: `docs/dev-log/core070/d220-paired-gaussian-cell-receipt-2026-09-05.json`
- Driver: `tools/d220_paired_gaussian_cell.jl`

## Re-run

```sh
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  julia --project=. tools/d220_paired_gaussian_cell.jl
```
