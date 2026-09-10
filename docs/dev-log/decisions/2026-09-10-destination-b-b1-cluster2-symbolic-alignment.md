# Destination B B1 — Gaussian `cluster2` diagonal alignment

**Status:** retained frozen-R-to-Julia paired Gaussian `cluster2` fixture,
checked on 2026-09-10. It does not qualify B1, intervals, recovery, S3b/S4,
dense `vcv`, FRK, or any version-wide parity claim.

**Reference:** frozen `gllvmTMB` 0.7.0 at
`b4d5fee64def88bc768dda1f1f77c29b295edd86`. The R engine remains read-only.

## Model

For trait \(t = 1,\ldots,p\), observation \(i = 1,\ldots,n\), and second
cluster membership \(c_2(i)\), the first `cluster2` shape is

\[
Y_{ti} = \beta_t + r_{t,c_2(i)} + \epsilon_{ti},\qquad
r_{t,c_2} \sim \mathcal N(0,\kappa_t^2),\qquad
\epsilon_{ti} \sim \mathcal N(0,\sigma_\epsilon^2).
\]

Thus \(\Sigma_{\mathrm{cluster2}} =
\operatorname{diag}(\kappa_1^2,\ldots,\kappa_p^2)\). The retained fixture
has two traits, six `cluster2` levels, four unit labels recurring in every
`cluster2` level, and two repeats per unit--`cluster2` cell. It therefore
makes `cluster2` crossed with an unselected unit axis and gives repeated
information for both the cluster2 and residual components.

## Alignment table

| Symbol | Frozen R form | Julia form | Fixture / draw | Observable and boundary |
| --- | --- | --- | --- | --- |
| \(\beta_t\) | `0 + trait` | default trait mean design | finite two-trait intercepts | compare only in retained same-data fit |
| \(r_{t,c_2}\) | `indep(0 + trait | cluster2_id)` with `cluster2="cluster2_id"` | `GroupingTerm(:cluster2; mode=:indep)` | independent Normal draw per trait × cluster2 | diagonal cluster2 covariance |
| \(c_2(i)\) | second optional grouping column | `cluster2=cluster2_labels` | six labels crossing four shared units | incidence supplies sharing |
| unit\((i)\) | `unit="unit"` | unselected in Julia | the same four units recur in every cluster2 level | design evidence only; no unit covariance term |
| \(\sigma_\epsilon\) | Gaussian residual coordinate | final packed `log_sigma_eps` coordinate | positive shared residual SD | separated by replication |

The paired calls are deliberately idiomatic:

```r
gllvmTMB(
  value ~ 0 + trait + indep(0 + trait | cluster2_id),
  data = df, family = gaussian(), trait = "trait", unit = "unit",
  cluster2 = "cluster2_id", REML = FALSE,
  control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
)
```

```julia
fit_gllvm(Y; family=Normal(),
    grouping=[GroupingTerm(:cluster2; mode=:indep)],
    cluster2=cluster2_labels)
```

R owns the native optimizer map. For this active Gaussian ML route, its outer
coordinate order is `[b_fix; log_sigma_eps; theta_diag_cluster2]`; `r_c2` is
in TMB's random vector, not `opt$par`. The receipt runner extracts named
`b_fix`, `log_sigma_eps`, and `theta_diag_cluster2` fields through
`parList(opt$par)` and deliberately constructs the Julia packed start as
`[b_fix; theta_diag_cluster2; log_sigma_eps]`. It also retains trait-factor
levels and `X_fix_names`, so the two trait-indexed blocks are not silently
assumed to have lexical order. Both diagonal coordinates are log-SDs. The
retained covariance target is `extract_Sigma(fit, level = "cluster2",
part = "total", link_residual = "none")$Sigma`; with this diagonal-only
source it equals the corresponding unique diagonal matrix.

## Executed discrimination control

The Julia receipt test preserves responses and the retained fixed coordinates,
then moves one observation to another `cluster2` label. Unlike a bijective
rename, that changes the incidence partition and changes the fixed-coordinate
marginal likelihood. Frozen R converged at `-2.9311750821141498`; the
registered Julia shard passed `32/32` tests in 6.1 s at the retained source
coordinate and after an independent public refit.

## Evidence boundary

This receipt establishes one Gaussian diagonal `cluster2` pair with this
crossed replicated design. It does not establish latent or full
cluster2 covariance, joint grouping terms, intervals, recovery, S3b/S4, dense
`vcv`, FRK, 0.7.1, broad 0.7 parity, or Destination B completion.
