# After-task: Post-NB1 closeout programme (packaging A)

**Date:** 2026-08-05  
**LOOP:** `lanes/post-nb1-closeout-20260805/LOOP/`  
**Plan:** `docs/dev-log/plans/2026-08-05-post-nb1-closeout-programme-ultra-plan.md`

## Goal

Clear the post-#186 queue: (1) NB1 ledger truth + Distributions; (2) Species-XB
Poisson light land; (3) BetaBinomial+X Identity Arc 0 (docs-only). No next-family
engine.

## Landings

| Rung | PR | Tip / merge | Result |
|---|---|---|---|
| S1 Hygiene | [#187](https://github.com/itchyshin/GLLVM.jl/pull/187) | `f230b372` | Board/AGENTS truth; live NB1+X Δ≈1.53e-9; `using Distributions`; capabilities golden. #189 closed as superseded. |
| S2 Species-XB | [#190](https://github.com/itchyshin/GLLVM.jl/pull/190) | `a8d19579` | Poisson `(0+trait):x` light cell; Δ≈4.20e-9; CI green → merge. |
| S3 Identity | this PR | `docs/betabinomial-x-identity-20260805` | ACCEPTED BetaBinomial+X per-trait φ + shared γ; twin `log_phi_betabinom` fid 8. **No `src/`.** |
| S4 Board | this PR | — | START HERE → BetaBinomial+X engine (fresh plan); programme DONE. |

## Rose fence

**OK:** programme closed; Species Poisson light; Identity ACCEPTED.

**Not OK:** BetaBinomial engine / bridge admit / RCall green; full family parity;
ADEMP; Tweedie+X as next rung without a new G0.

## STOP

Next engine work = fresh chat + `/arc-creation` / `/ultra-plan` for
BetaBinomial grouped(+cov). Do not continue engine in this lane.
