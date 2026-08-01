# Plan vs actual — gllvm-jl-catchup-loglik (Melissa CLOSE)

**Date:** 2026-08-01  
**Plan:** `docs/dev-log/plans/2026-08-01-gllvm-jl-catchup-loglik-oracle.md` / `LOOP/ultra-plan.md`  
**Lane tip (engine):** `387d267a`  
**Status:** **CLOSED** — GOAL definition of done met for light logLik oracles

## Planned arcs vs actual

| Arc | Plan | Actual | Verdict |
|---|---|---|---|
| A0 lane + drift | main worktree + twin | Done; `n_drift=0` | MATCH |
| A1 inventory | #132/#148/#133/#129 | Banked; #129/#128 fenced | MATCH |
| A2 Gaussian logLik | live green | Δ ≈ 9.78e-9 | MATCH |
| A2b bridge smoke | JuliaCall | PASS | MATCH |
| A3 Bin/Pois logLik | live green | both Δ ≪ 1e-6 | MATCH |
| A4/A5 param align | Julia→R | #133 committed; #132/#148 via **grouped** parity routes | MATCH (route-scoped) |
| A6 family logLik | NB2/Beta/Ordinal green | NB2 ~2.5e-4 (observed Hess. restored at closeout); Beta ~6e-9 @ `387d267a`; Ord probit ~5e-9 | MATCH |
| Close | check-log + after-task + Rose | this reconcile + claim fence | MATCH |

## Variance (why — resolved)

Plan assumed param alignment alone would unlock same-model logLik. Live cells
also needed **observed-Hessian** Laplace determinants (Fisher scoring ≠ TMB AD)
for NB2, Beta/logit, and ordinal_probit. Ordinal twin is **probit**, not Julia’s
logit default. Dispersion twin entries are **grouped 1:p**, not shared defaults.

## Claim language (final)

- **Allowed:** named-route light logLik oracles green with cited Δ on this branch.
- **Forbidden:** “full family parity”; ADEMP/coverage; equating `n_drift=0` with fit parity.

## Residual out of scope

- Default shared-dispersion NB2/Beta fitter alignment (separate slice if desired)
- Ordinal-logit twin cell
- #129 / #128
- Push / PR (maintainer instruction required)
