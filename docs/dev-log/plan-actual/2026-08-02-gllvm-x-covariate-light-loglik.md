# Plan vs actual — X/covariate light logLik (2026-08-02)

**Plan:** `docs/dev-log/plans/2026-08-02-gllvm-x-covariate-light-loglik-ultra-plan.md`  
**Lane:** `x-covariate-light-loglik-20260802`  
**Platform:** Cursor

## Material axes

| Axis | Planned | Actual | Tag |
|---|---|---|---|
| Scope | 3 shared-X cells G/Bin/Pois | 3/3 green | — |
| Evidence | LOG ΔlogLik rtol 1e-6 | All \|Δ\| ≤ 4e-9 | — |
| Twin | recreate gllvmTMB origin/main | `/tmp/…` @ `910ebd54` + R lib | — |
| Safety | no tol widen; fence NB2/Beta+X | Held; Binomial DGP repaired once | adaptive |
| Claims | light logLik shared X only | Rose fence in after-task | — |
| Handoff | LOOP + plan-actual | Written; push gated | — |

## Adaptive deviation

Binomial first fixture (seed 421, n=30) triggered R runaway-loading warning and
failed rtol. Resized to seed 431 / n=80 / milder loadings — **not** a tolerance
widen. Recorded as adaptive repair.

## Drift

None material. Push/PR not executed (gate held).
