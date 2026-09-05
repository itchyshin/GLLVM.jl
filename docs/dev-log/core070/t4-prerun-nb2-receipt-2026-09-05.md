# T4 pre-run receipt — NB2 cell 3/3 (Totoro)

**Date:** 2026-09-05  
**Shape:** nb2 · p=20 · n=500 · K=2 · seed=42  
**Host:** totoro.biology.ualberta.ca  
**Claim boundary:** RSZ scaling + tolerance evidence — **NOT** true-parity promotion.

## Result

**PASS** (informing receipt — each-own-optimum vcov + beta SE block within contract).

| Quantity | Julia | R | Delta |
|---|---:|---:|---:|
| logLik | −23429.668074435 | −23429.668074643 | 2.08e−7 |
| cond(H) | 79.1 | 168.0 | recorded |
| vcov Fro rel | — | — | **1.25e−5** (≤ 0.01) |
| max rel dSE (β) | — | — | **7.89e−6** |
| converged | yes | yes | — |
| pd Hessian | yes | yes | — |
| dispersion boundary | all false | — | no NaN vcov |

## seff (measured)

| Step | Wall (s) |
|---|---:|
| Total (rsync + remote + JIT) | ~306 |
| Julia fit | 95.2 |
| Julia confint (Laplace mode solve) | **99.0** |
| R fit + sdreport | 15.9 |

NB2 is **~2× Poisson** on confint and **~9× Gaussian** on total compute at this shape.

## Launch notes

1. Launcher: `tools/t4_totoro_nb2_prerun.sh` (G2 PASS gate crossed).
2. Launch log: `logs/t4-nb2-prerun-launch-20260905-1330.log`
3. Outputs: `docs/dev-log/core070/t4-prerun-out/nb2/`
4. Known risk (toy finding): boundary dispersion NaN vcov — **not triggered** at seed 42.

## Gate

**G3 PASS** → three-family pre-run complete; G4 re-estimate only (grid **NOT** launched).
