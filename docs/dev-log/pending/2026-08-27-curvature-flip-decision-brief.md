# Decision brief — the three remaining curvature flips (Beta, NB1, Student-t)

One decision, three families, campaign evidence attached. Gamma and NB2 are
done (both metrics agreed). Exponential is excluded until the Arc-2
mode-solver fix. Poisson/Binomial-logit are canonical (no choice exists).

## The trade-off, in one sentence

For these three families the two quality metrics **disagree**: `:observed`
produces point estimates closer to the exact-ML optimum, while `:fisher`
produces a reported log-likelihood closer to the true marginal value (which
feeds AIC/BIC/LRT).

## The numbers (900-cell campaign, 2026-08-27, K=1)

| family | observed's estimates preferred | mean preference (med/strong) | reported-loglik error F → O |
|---|---|---|---|
| beta | 100% med/strong (56% small) | +0.08 / +0.12 | 0.50 → 1.22 (worse) |
| negbin1 | 90–100% med/strong | +0.17 / +0.14 | 0.54 → 1.09 (worse) |
| studentt | 100% everywhere | +0.34 / +0.29 | 1.60 → 2.08 (worse) |

Λ-recovery differences are negligible (≤0.007 rmse) for all three.

## The three coherent positions

**A. Flip all three to `:observed` (full TMB parity).** Estimates improve
everywhere measured; every family matches gllvmTMB's log-det; the fault-class
ledger closes for all one-part families except Exponential. Cost: reported
logliks become measurably more biased for these three (up to ~2 loglik units
for Student-t on this fixture scale) — AIC/BIC comparisons inherit that bias.
This is TMB's own trade-off; R users live with it today.

**B. Keep all three at `:fisher` (status quo).** Reported logliks stay closer
to truth; cost: point estimates measurably farther from the exact-ML optimum,
permanent ~0.1–0.3-unit twin mismatch on these families' loglik surfaces, and
the class ledger keeps three open cells indefinitely.

**C. Split by user-facing surface** (flip the fit default, keep `:fisher` for
any displayed IC) — rejected as incoherent: AIC must be computed from the
fitted objective; mixing curvatures inside one fit is exactly the
gradient-desync fault class this programme exists to kill.

## Recommendation

**A**, on two grounds: (1) usability doctrine (D-139) says estimates users
act on outrank internal value accuracy, and the estimator metric favours
observed in 90–100% of realistic cells; (2) the twin-parity goal makes TMB's
convention the reference — a documented, consistent bias beats an
undocumented mismatch. The CHANGELOG/docs cascade would state the reported-
loglik cost explicitly, as the NB2 entry already does.

Caveats that stand regardless: K=1 evidence only; one dispersion level per
family; Beta's observed curvature can be negative (the PD guard at the
assembly handles it — measured, load-bearing); Student-t's negative-curvature
region likewise.

## What a "go" costs

Per family ≈ the NB2 flip: default + specialised obs weight (Beta and
Student-t already have theirs; NB1 needs one) + coupled gradient where an
analytic path exists + census/contract/docs cascade + one full suite. All
three in one arc ≈ half a day plus one 78-min suite, or three Totoro suites
in parallel.

**Answer:** _____

---

## Addendum (2026-08-28): the final two flips — Tweedie and Binomial/probit

Decision A resolved Beta/NB1/Student-t. The campaign has since adjudicated the
rest; two cells await a flip word:

| family | evidence | recommendation |
|---|---|---|
| **tweedie** | observed preferred in 98–100% of 145 cells in every regime, means ≡ medians (no outlier tail), approximation cost ≈ nil (0.56 vs 0.61) | **flip** — the cleanest case in the entire table |
| **binomial/probit** | observed preferred in 74–92% (medians +0.1…+0.25) but a thin outlier tail turns two regime means slightly negative; observed approximates better (83%) | **lean flip** — consistent with decision A's principle, weaker margin |

Already settled by evidence, no action needed: GP-1 (Fisher RETAINED — outlier
derailment under observed), cloglog (intrinsic saturation pathology — guard
shipped 2026-08-28; curvature adjudication deferred until the twin-parity
experiment).

**Answer (tweedie):** _____
**Answer (probit):** _____
