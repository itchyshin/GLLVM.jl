# Destination B: grouped-profile dense-oracle evidence

**Status:** deterministic internal check only. This is evidence that one
predeclared scalar Gaussian grouped-variance profile agrees with an independent
dense calculation. It is not a recovery study, coverage result, public API
admission, R-parity result, or generic profile claim.

## Fixed fixture and target

The test fixture in `test/test_grouped_profile_dense_oracle.jl` is fixed before
evaluation:

- one trait, 12 balanced groups, five observations per group;
- `MersenneTwister(20260907)`;
- simulated group-intercept SD `0.65`, residual SD `0.35`, and mean `1.1`;
- one `GroupingTerm(:unit; mode=:indep, common=false)`;
- selected natural group variance `v`, with a separately positive residual
  variance and intercept refitted at every fixed `v`.

The private production route under test is
`_grouped_gaussian_variance_profile` in
`src/grouped_profile_interval.jl`. Its bounded LR endpoint contract is
`tol_D = 1e-4`; the test does not alter that tolerance.

## Independent oracle

For the independently assembled one-hot incidence `Z`, the oracle uses

```
V(v, sigma_eps^2) = v Z Z' + sigma_eps^2 I.
```

At each returned endpoint, it computes the GLS intercept from the dense
Cholesky factor of `V`, then independently minimizes the exact dense Gaussian
NLL over `log(sigma_eps)`. It does not call a GLLVM likelihood, objective,
refitter, profile callback, or sparse kernel. Its LR is

```
D_dense(v) = 2 { NLL_dense(v) - NLL_dense(v_hat) }.
```

The zero-variance check additionally evaluates the production reduced
fixed-variance adapter at the oracle's independently optimized intercept and
residual variance. The selected covariance is exactly zero and the selected
log-SD coordinate remains missing; its NLL agrees with the dense oracle at
`1e-10` absolute/relative tolerance.

## Recorded deterministic receipt

The bounded test was estimated under 30 minutes and completed in 1.1 seconds
of Julia test time (14 assertions, 2026-09-07). The fixed replay produced:

| Quantity | Value |
| --- | ---: |
| fitted center variance | 0.4397301086573058 |
| lower endpoint | 0.20414411248624464 |
| upper endpoint | 1.1438243268284336 |
| chi-square cutoff | 3.8414588206941245 |
| independent dense LR, lower | 3.8413742285465275 |
| independent dense LR, upper | 3.8414447018360107 |
| dense zero-variance NLL | 67.912842738231 |

Both independent dense endpoint LRs are within the existing `1e-4` cutoff
gate. The test also requires the wrapper's retained final endpoint-refit LR to
meet that same gate, with no tolerance widening.

## Boundary of the evidence

This one balanced random-intercept cell exercises a scalar independent grouped
variance only. It says nothing about unbalanced or crossed designs,
multi-trait covariance, structurally unidentified latent-plus-unique targets,
non-Gaussian likelihoods, profile coverage, or R `phylo_rr` admission.
