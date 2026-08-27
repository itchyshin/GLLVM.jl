# Curvature adjudication — campaign results (2026-08-27)

Run: Totoro, 12 workers, 900 cells (6 families × 3 regimes × 50 seeds, K = 1),
wall 5.1 min, tree `b0cd33c8`. 787 cells complete; all 113 failures are
Exponential (see finding 3). Raw rows: `results/` (tarball on Totoro:
`~/curv_results.tgz`); aggregation script in the check-log entry.

## The two metrics

- **Approximation error** |Laplace − exact| at the fit's own optimum: how
  truthful the *reported loglik* is (feeds AIC/BIC/LRT).
- **Estimator preference** (exact marginal at observed's θ̂ minus at
  Fisher's θ̂; > 0 ⇒ observed's estimates closer to the exact-ML optimum):
  what point-estimate users actually get.

## Verdict table (cells where both fits converged)

| family | n | mean pref (med/strong regimes) | % pref observed | approx. closer |
|---|---|---|---|---|
| gamma | 150 | +0.99 / +0.75 | 100% everywhere | observed (83%) |
| negbin | 150 | +0.20 / +0.17 | 100% med/strong | observed (87%) |
| beta | 150 | +0.08 / +0.12 | 100% med/strong (56% small) | **Fisher (100%)** |
| negbin1 | 150 | +0.17 / +0.14 | 90–100% med/strong | **Fisher (83%)** |
| studentt | 150 | +0.34 / +0.29 | 100% everywhere | **Fisher (67%)** |
| exponential | 37 | garbage | — | no verdict |

## Findings

1. **On estimator quality, `:observed` wins essentially everywhere** — every
   usable family prefers observed's estimates in 90–100% of medium/strong
   cells, with meaningful magnitudes (0.07–1.0 loglik units). The weakest
   signal is the small regime (56–76%), where the two optima nearly coincide.
2. **The two metrics genuinely disagree for beta, negbin1, studentt**: the
   Fisher objective's *value* approximates the exact marginal better even
   though its *optimum* lands farther from the exact-ML estimate. A default
   flip to observed for these three buys better estimates at the cost of a
   more biased reported loglik (e.g. beta: |err| 0.50 → 1.22). TMB reports
   the observed-curvature value, so twin parity also pulls toward observed.
3. **Exponential's engine bug now has a campaign-scale measurement**: 113 of
   150 cells (75%) died with DomainError inside the fit — the undamped-Newton
   divergence in the shared grouped-dispersion mode solver (roadmap Arc 2),
   previously known only as "platform-inconsistent". Among the 37 survivors,
   diverged observed-fits produce garbage (|err| ~1400). **No adjudication is
   possible until Arc 2 lands.**
4. Λ recovery differences are negligible (≤0.007 rmse) for all usable
   families — the curvature choice moves loglik reporting and fine estimate
   position, not gross recovery.

## Recommendation to the maintainer (decision #2)

- **Flip gamma and negbin defaults to `:observed`**: both metrics agree.
- **beta, negbin1, studentt**: your call on the estimator-vs-reporting
  trade-off; the twin-parity argument (TMB = observed) breaks the tie toward
  observed if parity is the priority. `hessian=:fisher` remains reachable.
- **exponential**: blocked on the Arc 2 mode-solver fix; re-run its 150 cells
  after.
- Scope caveats: K = 1 only; one dispersion level per family; the oracle is
  dense 1-D quadrature (8001 nodes) — K > 1 adjudication needs an AGHQ-grade
  oracle and is a separate arc.
