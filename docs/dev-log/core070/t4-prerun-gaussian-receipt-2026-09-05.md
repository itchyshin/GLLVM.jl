# T4 pre-run receipt — Gaussian cell 1/3 (Totoro)

**Date:** 2026-09-05  
**Shape:** gaussian · p=20 · n=500 · K=2 · seed=42  
**Host:** totoro.biology.ualberta.ca  
**Claim boundary:** RSZ scaling + tolerance evidence — **NOT** true-parity promotion.

## Result

**PASS** (informing receipt — each-own-optimum vcov block within contract).

| Quantity | Julia | R | Delta |
|---|---:|---:|---:|
| logLik | −11511.897471698 | −11511.897471922 | 2.24e−7 |
| cond(H) | 438.2 | 660.3 | recorded |
| vcov Fro rel | — | — | **1.30e−5** (≤ 0.01) |
| converged | yes | yes | — |
| pd Hessian | yes | yes | — |

## seff (measured)

| Step | Wall (s) |
|---|---:|
| Total (rsync + remote + JIT) | ~47 |
| Julia fit | 10.0 |
| Julia confint | 6.5 |
| R fit + sdreport | 2.0 |

Mid estimate was ~6 min; measured **~17 s compute** after warm depot — revise Poisson/NB2 downward.

## Launch notes

1. First launch failed: remote `t4-prerun-01/repo` directory absent → `mkdir -p` then retry.
2. Launch log: `logs/t4-gaussian-prerun-launch-20260905-retry2.log`
3. Outputs: `docs/dev-log/core070/t4-prerun-out/gaussian/`

## Gate

**G1 PASS** → Poisson cell 2/3 may queue (Ada default in programme plan).
