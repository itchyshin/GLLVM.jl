# Destination B B1 — Gaussian `cluster` diagonal alignment

**Status:** retained frozen-R-to-Julia paired Gaussian `cluster` fixture, checked on 2026-09-10. It does not qualify B1, intervals, recovery, S3b/S4, dense `vcv`, FRK, or any version-wide parity claim.

**Reference:** frozen `gllvmTMB` 0.7.0 at `b4d5fee64def88bc768dda1f1f77c29b295edd86`. The R engine remains read-only.

## Model

For trait \(t = 1,\ldots,p\), observation \(i = 1,\ldots,n\), and cluster membership \(c(i)\), the first cluster shape is

\[
Y_{ti} = \beta_t + q_{t,c(i)} + \epsilon_{ti},\qquad
q_{t,c} \sim \mathcal N(0,\omega_t^2),\qquad
\epsilon_{ti} \sim \mathcal N(0,\sigma_\epsilon^2).
\]

Thus \(\Sigma_{\mathrm{cluster}} = \operatorname{diag}(\omega_1^2,\ldots,\omega_p^2)\). The retained fixture has two traits, six cluster levels, four shared unit labels within every cluster, and two observations per unit--cluster cell. `cluster` is deliberately distinct from and crossed with the intrinsic unit axis; no selected `unit` covariance is present.

## Alignment table

| Symbol | Frozen R form | Julia form | Fixture / draw | Observable and boundary |
| --- | --- | --- | --- | --- |
| `beta_t` | `0 + trait` | default trait mean design | finite two-trait intercepts | compare only in retained same-data fit |
| `q_{t,c}` | `indep(0 + trait | cluster_id)` with `cluster="cluster_id"` | `GroupingTerm(:cluster; mode=:indep)` | independent Normal draw per trait × cluster | diagonal cluster covariance |
| `c(i)` | third-slot `cluster` column, internally mapped by R to species | `cluster=cluster_labels` | six or more labels shared across distinct units | sparse incidence supplies sharing |
| `unit(i)` | `unit="unit"` | unselected in Julia | the same four units recur in every cluster, two repeats per unit--cluster cell | design evidence only; no unit covariance term |
| `sigma_eps` | Gaussian residual coordinate | final packed `log_sigma_eps` coordinate | positive shared residual SD | identified separately by repeated observations |
| `Y` | long rows ordered cluster, unit, replicate, trait | traits-by-observations matrix | deterministic 2 × 48 response | Julia `vec(Y)` remains trait-within-observation |

The paired calls are intentionally idiomatic:

```r
gllvmTMB(
  value ~ 0 + trait + indep(0 + trait | cluster_id),
  data = df, family = gaussian(), trait = "trait", unit = "unit",
  cluster = "cluster_id", REML = FALSE,
  control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
)
```

```julia
fit_gllvm(Y; family=Normal(),
    grouping=[GroupingTerm(:cluster; mode=:indep)],
    cluster=cluster_labels)
```

R's canonical target is `extract_Sigma(fit, level = "cluster", part = "total")$Sigma`. Retain native source fields `b_fix`, `log_sigma_eps`, and `theta_diag_species`; construct Julia's packed start as `[b_fix; theta_diag_species; log_sigma_eps]`. The source diagonal coordinate is log-SD and Julia likewise uses `exp(2 * log_sd)`.

## Executed discrimination control

The Julia receipt test preserves responses and fixed coordinates, then moves one observation to a different cluster. Unlike a bijective rename, that changes the incidence partition. It need not preserve a unit nesting condition: Julia intentionally permits crossed `cluster` labels, and frozen R's `unit == cluster` collision is excluded by the fixture design. The frozen R runner generated the receipt at marginal log likelihood `-9.3696900475934175`; the registered Julia shard passed `20/20` tests in 5.8 s at the retained source coordinate and after an independent public refit.

## Evidence boundary

This receipt establishes one Gaussian diagonal `cluster` pair with this crossed replicated design. It does not establish a latent or full cluster covariance, `cluster2`, joint groupings, intervals, recovery, S3b/S4, dense `vcv`, FRK, 0.7.1, broad 0.7 parity, or Destination B completion.
