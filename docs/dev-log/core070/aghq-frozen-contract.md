# AGHQ fixed-adaptation objective: implementation leaf

Reference: R b4d5fee64def88bc768dda1f1f77c29b295edd86,
`R/fit-multi.R:9543-9589`; the source archive is immutable. This implements the
reviewed prerequisite in `aghq-source-contract.md`, not its public estimator.

For each site let h(z;theta) be the **normalized** joint density including the
standard-normal latent prior. At a separately obtained conditional mode m and
observed negative log-joint Hessian H, define Hs=(H+H')/2. Try Cholesky Hs=R'R.
Only if that fails, the frozen R compatibility branch replaces eigenvalues by
max(lambda,1e-8). Report that repair and the original minimum eigenvalue; do not
apply a loading penalty, silently repair all SPD matrices or accept nonfinite H.
Define B=inv(R), logjac=-sum(log(diag(R))), z_j=m+B*u_j.

The fixed-adaptation log integral is
`Q(theta;A)=logjac+logsumexp_j(grid.logw[j]+log h(z_j;theta))`.
A=(m,B,logjac) is constant during AD. Its derivative is the quadrature-weighted
score at these fixed z_j. It is **not** the total derivative of Q(theta;A(theta)).
The later outer algorithm must compute fresh observed adaptation, accept short
surrogate steps against that re-adapted merit, and preserve convergence/reporting
rules in the reviewed source contract. No public estimator or settled-mode claim
is earned by this leaf. The cache constructor does not find/certify modes.

| Symbol | Julia representation | Check / known truth |
|---|---|---|
| m | cache.mode | supplied 2D nonzero Gaussian mean; copy, no caller alias |
| H | observed_hessian input | inverse known covariance; symmetric average |
| B | cache.inverse_root | B*B' = inv(Hs), exact frozen R orientation |
| logjac | cache.logjac | -0.5 logdet(Hs); no extra sqrt(2)/sqrt(pi) |
| h | logjoint callback | normalized Gaussian and independent Poisson/prior densities |
| theta | callback AD input | fixed-cache FD agreement <=1e-6 |
| A(theta) | separate reconstruction | directional FD chain term demonstrated, not hidden |
| repair | cache.curvature_repaired | indefinite synthetic R branch; SPD tiny eigenvalue untouched |

Predeclared stable cases:
AF-01: transformed normalized Gaussian integral and first/second moments, 1e-12.
AF-02: same-parameter k1 equality to observed Poisson Laplace, 1e-10.
AF-03: fixed-cache AD gradient vs centered FD at two steps, max error1e-6.
AF-04: node refinement vs independent Simpson integration on [-12,12], abs1e-8.
AF-05: finite-node total-vs-frozen derivative distinction; measurable chain term.
AF-06: R-compatible factor/repair branch (SPD, indefinite, singular, tiny SPD,
        asymmetric input), factor covariance relative1e-10, logjac abs1e-10.
AF-07: reject nonfinite/invalid shapes; cache and input buffers do not alias.

Parent exclusive ownership: src/families/aghq_grid.jl, test/test_aghq_frozen.jl,
central test include, tools/core070_aghq_frozen* and scoped developer records.
Original evaluator semantics and public exports are unchanged. A failed regression
must be observed before source edits. Totoro checks estimated1-2minutes each,
one Julia/BLAS thread,180s hard cap, no DRAC job or large recovery campaign.
