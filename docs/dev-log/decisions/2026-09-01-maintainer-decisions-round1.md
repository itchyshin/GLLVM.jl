# Maintainer decisions, round 1 (2026-09-01, interactive)

1. **nobs/BIC**: adopt R's p·n (cell-count) convention in GLLVM.jl; BIC
   audit + tests in the same slice. (Was: PARTIAL_PARITY_DEFECT_PENDING.)
2. **Binomial cloglog likelihood disagreement**: open the reviewed repair
   leaf now — diagnose per-cell at R's coordinates on the retained fixture
   (seed 81012) against the analytic cloglog Bernoulli-Laplace marginal;
   fix whichever engine deviates if it is ours.
3. **Estimand alignment** (communality/correlations/proportions/Omega):
   align to R's tier-scoped decomposition as the default, mirroring R's
   level= arguments; keep the total-variance variant behind an explicit
   option. R is the frozen contract.
4. **Landing**: push both lanes and open DRAFT PRs (merge remains a
   separate decision).
