# Ordinary Gaussian fixed-point correspondence

**Six fixed points pass; optimized-fit and interface parity remain unpaid.**
R oracle b4d5fee6, Julia source snapshot pinned in the process receipt. No
numerical engine changed in this slice. Tests run on Totoro Julia1.12.6/R4.5.3.

For each site, the captured model is

```math
y_s \sim N(\beta,V),\qquad
V=\lambda\lambda^\top+\operatorname{diag}(\psi)+\sigma_\epsilon^2 I.
```

There are3 traits,18 sites and1 factor. The exact trait/site IDs and fixed-effect
matrix determine response ordering; no centering is performed. The R template
uses raw rank-one loadings, log unique SDs and log residual SD. Thus
`psi=exp.(2log_sd_B)`, not `exp.(log_sd_B)`. Common unique has one free log-SD
coordinate repeated across traits. Loadings-only has no unique coordinate.
Default/common preserve the captured fixed residual scale exactly; loadings-only
has one free residual scale. The rank-one restriction avoids implying that this
slice verifies higher-rank packing or rotations.

At each of two declared parameter points, the R objective is rebuilt from the
same captured data/parameters/map/random arguments. `obj$fn` integrates the
conditional Gaussian effects through TMB; no outer optimizer is called. Native
Julia `gaussian_marginal_loglik` uses the `sigma2_B` keyword spelled `σ²_B` in
code. It receives residual matrix `Y .- beta`, the same loading vector, the
same residual SD, and the same unique variances. Exact calls are recorded as
`native_density_mapping` in the three corresponding fit-input case rows.

Independent dense calculations use the normalized expression

```math
-\ell=\tfrac12\{np\log(2\pi)+n\log|V|
 +\sum_s(y_s-\beta)^\top V^{-1}(y_s-\beta)\}.
```

The R/dense/Julia absolute negative-log-likelihood gate is1e-6. The native/dense
Julia gate is1e-8. Outer gradient comparison uses
`max(abs(g_julia-g_R)/(1+abs(g_R))) <= 1e-6`; native/dense Julia derivatives
must agree within1e-8 on that scale. Deliberately shifting one fixed intercept
must fail likelihood equality. All48 assertions pass; largest R–Julia value
difference9.254e-10 and scaled gradient difference5.147e-10. Tolerances were
written before execution and were not widened.

An initial pre-comparison assertion rejected R's otherwise identical fixed-effect
matrix because it carried `assign`/contrast metadata. The corrected assertion
checks dimensions, explicit column order and exact numeric values. That failed
attempt and the downstream missing-artifact error are retained, not counted
as numerical passes.

This establishes a likelihood and derivative mapping for these six points.
It does not validate outer optimization, covariance identification, calibrated
intervals, boundary behavior, higher ranks, source covariance, mixed families,
formula grammar, R bridge or an exported default fit workflow. In particular,
optimizing a total residual variance and reporting it as unique variance would
lose the fixed residual component; fitted-object decomposition must preserve
both quantities. The current full Core+AGHQ contract remains DRAFT.
