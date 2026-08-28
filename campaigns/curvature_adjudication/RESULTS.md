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
| exponential | 150 (healed re-run) | +0.43 / +1.59 / +1.44 by regime | 100% everywhere | observed (67%) — **both metrics agree** |

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
3. **Exponential — healed and adjudicated (same day)**: the original run's
   75% mortality decomposed into an oracle fragility (campaign code) and the
   real engine defect — the `:observed` route's Gamma grouped-kernel detour,
   whose own undamped per-site Newton loop returned −5.0e23 at healthy
   parameters (exact: −1717.6), sending the optimizer into a runaway basin
   with `converged = true`. After re-routing through the generic core
   (retiring the detour), the 150-cell re-run is 150/150 convergent, and
   Exponential joins Gamma and NB2 in the both-metrics-agree club: observed's
   estimates preferred in 100% of cells in every regime (mean +0.4 to +1.6),
   approximation closer in 67%, Λ recovery equal. The long-shipped
   `:observed` default is now evidence-backed rather than inherited.
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

## Extension cells (2026-08-28): GP-1 and Binomial/probit adjudicated; cloglog and Tweedie fenced

| family | n | estimator preference | reported-loglik accuracy | verdict |
|---|---|---|---|---|
| gp1 | 150 (147 conv-both) | medians +0.11/+0.45/+0.37, %>0 = 98/86/74 — but MEANS −5.6/−10.3 in medium/strong (outlier tail) | Fisher far better (\|err\| 1.5 vs 15.2; observed closer in only 27%) | **KEEP FISHER** — a minority of cells derail badly under observed (the documented negative-curvature region `1+2αy−αμ<0`); the asymmetric downside outweighs the small median gain |
| binomial/probit | 150 | medians +0.11 to +0.25, %>0 = 74–92; means mildly negative in small/medium (thin outlier tail) | observed better (83% closer; 2.1 vs 2.6) | **lean observed — maintainer's call**; thinner than Beta's case, consistent with decision A's principle |
| binomial/cloglog | fenced | — | — | ENGINE FINDING: ‖Λ̂‖→20–27 (truth 0.9) under BOTH selectors, converged=true, Laplace overstates exact by +17…+75; probit clean on same shape ⇒ cloglog-specific weight/score suspect. Adjudication blocked until fixed |
| tweedie | fenced | — | — | oracle cost (series × 8001 nodes × sites ⇒ >10 min/cell); needs oracle optimization or a ~50–75 CPU-h remote campaign with its own D-139 approval |
