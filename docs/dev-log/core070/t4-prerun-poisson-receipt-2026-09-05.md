# T4 pre-run receipt — Poisson cell 2/3 (Totoro)

**Date:** 2026-09-05  
**Shape:** poisson · p=20 · n=500 · K=2 · seed=42  
**Host:** totoro.biology.ualberta.ca  
**Claim boundary:** RSZ scaling + tolerance evidence — **NOT** true-parity promotion.

## Result

**PASS** (informing receipt — each-own-optimum vcov + beta SE block within contract).

| Quantity | Julia | R | Delta |
|---|---:|---:|---:|
| logLik | −21202.416929894 | −21202.416930153 | 2.59e−7 |
| cond(H) | 112.4 | 516.3 | recorded |
| vcov Fro rel | — | — | **1.59e−5** (≤ 0.01) |
| max rel dSE (β) | — | — | **5.94e−6** |
| converged | yes | yes | — |
| pd Hessian | yes | yes | — |

## seff (measured)

| Step | Wall (s) |
|---|---:|
| Total (rsync + remote + JIT) | ~107 |
| Julia fit | 10.9 |
| Julia confint (Laplace mode solve) | **45.9** |
| R fit + sdreport | 3.1 |

Poisson confint is **7× slower** than Gaussian (45.9 s vs 6.5 s) — Laplace mode-solve cost at this shape.

## Launch notes

1. Launcher: `tools/t4_totoro_poisson_prerun.sh` (G1 PASS gate crossed).
2. Launch log: `logs/t4-poisson-prerun-launch-20260905-1312.log`
3. Outputs: `docs/dev-log/core070/t4-prerun-out/poisson/`

## Gate

**G2 PASS** → NB2 cell 3/3 may queue (Ada default; not launched in this slice).
