# Destination B B1 — joint Gaussian grouping alignment

**Status:** first joint four-source B1 frozen-R to Julia fixture and retained
optimizer diagnostic. It establishes fixed-coordinate objective identity and
source-incidence controls, but the R reference point is not stationary enough
for matched-parameter acceptance. It does not qualify B1, intervals, recovery,
S3b/S4, dense `vcv`, FRK, or any version-wide parity claim.

**Reference:** frozen `gllvmTMB` 0.7.0 at
`b4d5fee64def88bc768dda1f1f77c29b295edd86`. The R engine remains read-only.

## Model

For trait \(t\), observation \(i\), unit \(u(i)\), nested within-unit
group \(w(i)\), cluster \(c(i)\), and second cluster \(c_2(i)\), the first
joint shape is

\[
Y_{ti}=\beta_t+\lambda_t z_{u(i)}+a_{t,w(i)}+q_{t,c(i)}+
r_{t,c_2(i)}+\epsilon_{ti},
\]

with \(z_u\sim\mathcal N(0,1)\),
\(a_{t,w}\sim\mathcal N(0,\tau_t^2)\),
\(q_{t,c}\sim\mathcal N(0,\omega_t^2)\),
\(r_{t,c_2}\sim\mathcal N(0,\kappa_t^2)\), and
\(\epsilon_{ti}\sim\mathcal N(0,\sigma_\epsilon^2)\). Thus
\(\Sigma_{\rm unit}=\Lambda\Lambda^\top\) (rank one at \(p=2\)), while
the other three source covariances are diagonal.

The initial fixture has two traits; six units; two globally unique
`unit_obs` groups per unit; three repeated measurements per `unit_obs`; four
clusters crossing units; three `cluster2` groups crossing units; and 36
observation columns. It has no duplicate unit component: the unit term is
`latent(..., unique=FALSE)`, not `indep()` or `unique()` alongside it.

## Alignment table

| Source | Frozen R term and identifier | Julia term and labels | Fitted covariance |
| --- | --- | --- | --- |
| unit | `latent(0 + trait \| unit, d=1, unique=FALSE)`, `unit="unit"` | `GroupingTerm(:unit; mode=:latent, rank=1, unique=false)`, `unit=` | \(\Lambda\Lambda^\top\) |
| unit_obs | `indep(0 + trait \| obs)`, `unit_obs="obs"` | `GroupingTerm(:unit_obs; mode=:indep)`, `unit_obs=` | \(\operatorname{diag}(\tau^2)\) |
| cluster | `indep(0 + trait \| cluster_id)`, `cluster="cluster_id"` | `GroupingTerm(:cluster; mode=:indep)`, `cluster=` | \(\operatorname{diag}(\omega^2)\) |
| cluster2 | `indep(0 + trait \| cluster2_id)`, `cluster2="cluster2_id"` | `GroupingTerm(:cluster2; mode=:indep)`, `cluster2=` | \(\operatorname{diag}(\kappa^2)\) |
| residual | Gaussian residual coordinate | final packed `log_sigma_eps` | \(\sigma_\epsilon\) |

The paired R formula is:

```r
gllvmTMB(
  value ~ 0 + trait +
    latent(0 + trait | unit, d = 1, unique = FALSE) +
    indep(0 + trait | obs) +
    indep(0 + trait | cluster_id) +
    indep(0 + trait | cluster2_id),
  data = df, family = gaussian(), trait = "trait", unit = "unit",
  unit_obs = "obs", cluster = "cluster_id", cluster2 = "cluster2_id",
  REML = FALSE, control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
)
```

The frozen R active outer coordinate order is
`[b_fix; log_sigma_eps; theta_rr_B; theta_diag_W; theta_diag_species;
theta_diag_cluster2]`. `z_B`, `s_W`, `q_sp`, and `r_c2` are TMB random blocks,
not outer parameters. The receipt runner must reconstruct named blocks with
`parList(opt$par)`, retain the raw vector and its names, then explicitly form
the Julia start
`[b_fix; theta_rr_B; theta_diag_W; theta_diag_species;
theta_diag_cluster2; log_sigma_eps]` in the exact term order shown above.
The runner also retains trait levels and `X_fix_names`.

For every source, retain
`extract_Sigma(fit, level=<source>, part="total", link_residual="none")$Sigma`.
For `unit`, this is \(\Lambda\Lambda^\top\); for the remaining sources it
is the corresponding diagonal matrix.

## Executed discrimination controls

The joint Julia test will preserve the response and retained fixed
coordinates, then separately change one `cluster2` membership and one valid
nested `unit_obs` membership. Neither is a bijective relabeling; each must
change the joint marginal likelihood. It will also assert nesting and the
four source incidence patterns.

## Evidence boundary

The deterministic frozen-R default `nlminb` fit reports maximum outer-gradient
component (2.1410189650930688\times10^{-5}). Re-running the identical initial
state with `eval.max = iter.max = 10000` and `rel.tol = x.tol = xf.tol =
10^{-12}` returns the same point but convergence code 1. Same-start `optim`
with BFGS returns a lower log likelihood and a larger gradient. Julia's public
independent refit instead reaches a gradient norm below (10^{-7}) and a
slightly higher likelihood, while its first fixed effect differs by more than
(10^{-6}) from the non-stationary R point. The receipt and regression retain
these facts as an optimizer diagnostic; they must not be rewritten as a paired
parameter-match result.

This receipt establishes one mixed-covariance Gaussian joint four-source
optimizer diagnostic at this p=2, n=36 design. It does not establish all B1
covariance forms, non-Gaussian joint fits, interval feasibility, recovery,
coverage, S3b/S4, dense `vcv`, FRK, 0.7.1, broad 0.7 parity, or Destination B
completion.
