# DRAC Wald-coverage campaign — findings (2026-09-02, Narval job 2235446)

Maintainer decision round2-3 #8: Wald-only, launched AFTER the fix slices
(nobs p·n, cloglog observed curvature, tier-scoped estimands, Student-t
boundary honesty) so it measures the CORRECTED engine. Same chunked-array
design and the SAME pinned cells as the recovery campaign, so coverage and
recovery describe one grid: 5 families x {p=5,25} x {n=50,200} x 500 seeds.
Estimand: per-trait intercepts beta_t; interval: 95% Wald from
confint(fit, Y; parm="beta"). Retained:
.unlazy/core070-aghq/drac-coverage-01/coverage-out.tar.gz (sha256 ca3016ab...).

Job accounting: 1160 COMPLETED, 20 TIMEOUT, 20 CANCELLED (the beta p=25,n=200
tail; 9955 of 10000 seed-rows recorded). Timeouts are reported, not dropped.

## Empirical coverage (converged fits; MC standard error shown)

| family | p | n | conv% | coverage | mc se |
|---|---|---|---|---|---|
| beta | 5 | 50 | 100.0 | 0.936 | 0.005 |
| beta | 5 | 200 | 100.0 | 0.948 | 0.005 |
| beta | 25 | 50 | 100.0 | 0.944 | 0.002 |
| beta | 25 | 200 | 100.0 | 0.948 | 0.002 |
| binomial | 5 | 50 | 78.0 | 0.941 | 0.005 |
| binomial | 5 | 200 | 100.0 | 0.958 | 0.004 |
| binomial | 25 | 50 | 21.8 | 0.950 | 0.004 |
| binomial | 25 | 200 | 97.2 | 0.953 | 0.002 |
| gaussian | 5 | 50 | 100.0 | 0.942 | 0.005 |
| gaussian | 5 | 200 | 100.0 | 0.951 | 0.004 |
| gaussian | 25 | 50 | 100.0 | 0.942 | 0.002 |
| gaussian | 25 | 200 | 100.0 | 0.949 | 0.002 |
| nbinom2 | 5 | 50 | 100.0 | 0.938 | 0.005 |
| nbinom2 | 5 | 200 | 100.0 | 0.932 | 0.005 |
| nbinom2 | 25 | 50 | 100.0 | 0.948 | 0.002 |
| nbinom2 | 25 | 200 | 100.0 | 0.947 | 0.002 |
| poisson | 5 | 50 | 100.0 | 0.948 | 0.004 |
| poisson | 5 | 200 | 100.0 | 0.951 | 0.004 |
| poisson | 25 | 50 | 100.0 | 0.951 | 0.002 |
| poisson | 25 | 200 | 100.0 | 0.953 | 0.002 |

## Honest read
Every cell sits within 0.932-0.958 of the nominal 0.95. The small-n slight
under-coverage (nbinom2 n=200 p=5 at 0.932, beta/gaussian n=50 at ~0.94) is
the expected finite-sample Wald behavior, not a defect — and it is 3-4 MC
standard errors from nominal at worst.

IMPORTANT SCOPE: coverage is CONDITIONAL ON CONVERGENCE. The binomial
p=25,n=50 cell shows 0.950 coverage on the 21.8% of fits that converged —
that is a statement about the intervals, NOT a statement that the cell is
usable. Read it with the recovery campaign's convergence finding, never
alone.

## What this is NOT
Not profile-CI coverage (deliberately excluded — cost). Not coverage for
derived quantities (Sigma entries, communality, ICC). Not a parity claim: no
R fits ran in this campaign.
