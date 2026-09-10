# Destination B B1 — pre-registered stationary four-source Gaussian reference

**Status:** pre-registered on 2026-09-10 before the first frozen-R execution.
This is a new fixed fixture; it does not replace or alter the retained p=2,
n=36 non-stationary diagnostic.

## Model and coordinates

For trait \(t\), long-format observation \(i\), unit \(u(i)\), nested
unit-observation \(w(i)\), cluster \(c(i)\), and second cluster \(c_2(i)\),

\[
Y_{ti} = \beta_t + \lambda_t z_{u(i)} + a_{t,w(i)} + q_{t,c(i)} +
r_{t,c_2(i)} + \epsilon_{ti}.
\]

The unit term is rank-one latent with `unique = FALSE`; all three remaining
sources are trait-diagonal independent Gaussian terms. The fitted frozen-R
formula is fixed as:

```r
value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) +
  indep(0 + trait | obs) + indep(0 + trait | cluster_id) +
  indep(0 + trait | cluster2_id)
```

The corresponding Julia terms are ordered
`unit`, `unit_obs`, `cluster`, `cluster2`; the packed Julia coordinate is
`[b_fix; theta_rr_B; theta_diag_W; theta_diag_species;
theta_diag_cluster2; log_sigma_eps]`. R's named outer coordinate order retains
`log_sigma_eps` before the four source blocks. The runner must extract named
fields through `parList(opt$par)`, never infer them by numeric offsets.

## Fixed design and draw

- Seed: `20260914L`; two traits; 12 units; three nested observations per unit;
  five replicates per nested observation; 180 wide observations / 360 long rows.
- Eight `cluster` and seven `cluster2` labels are deterministically assigned
  from all three unit, nested-observation, and replicate indexes, so neither
  source is nested within one of the other three.
- Fixed true scales: latent loadings `(0.72, -0.51)`; nested-observation SDs
  `(0.36, 0.27)`; cluster SDs `(0.43, 0.32)`; cluster2 SDs `(0.38, 0.29)`;
  residual SD `0.17`.
- The one run uses `n_init = 1`, `se = FALSE`, and a predeclared tightened
  `nlminb` control only. It has no post-hoc restart, warm start, data change,
  seed search, or acceptance-tolerance change.

## Acceptance and negative controls

The source reference is stationary only if it reports convergence code zero
and `max(abs(tmb_obj$gr(opt$par))) <= 1e-6`. This threshold is fixed; an
otherwise usable but non-stationary fit is retained as a negative receipt.

Only after that source gate passes may the paired Julia test compare the named
fixed effects, all four source covariances, and residual SD under independent
Julia refit. Three incidence controls move one observation's `cluster`,
`cluster2`, or nested `unit_obs` membership while retaining responses and the
same named R coordinates; each must change the fixed-coordinate likelihood.
They guard against a label being silently ignored. This is one frozen Gaussian
ML reference only, not B1 qualification, recovery, intervals, S3b/S4, dense
`vcv`, FRK, or a version-wide parity claim.

## Executed result

The single pre-registered frozen-R run completed in 0.77 seconds but did not
meet the gate: `nlminb` returned `singular convergence (7)` and the named
source gradient maximum was `9.9329370235209566e-5`, about 99 times the fixed
threshold. The immutable receipt is therefore a negative stationary-candidate
record. No Julia paired fit, covariance comparison, or incidence control was
run, because each is conditional on a stationary R reference. The precise next
blocker is a separately pre-registered, identification-based remedy that can
produce source convergence code zero and maximum source gradient at most
`1e-6`; it must not reuse this receipt name, alter this fixture after seeing
the result, or relax the threshold.
