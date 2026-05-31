# Covariance and correlation

A fitted Gaussian GLLVM gives you more than latent ordination axes — it gives
the full **among-response covariance** `Σ_y` those axes imply, and the
ecological quantities you read off it: how much of each response's variation is
*shared* (communality), and which responses *move together* (correlation).

## The model-implied covariance

For a Gaussian GLLVM with `K` latent factors and loadings `Λ`, the responses at
a site have covariance

```math
\Sigma_y = \Lambda \Lambda^{\top} + \Psi,
```

where `ΛΛᵀ` is the **shared** (latent) part and `Ψ = diag(ψ)` the
**response-specific** residual part. Three extractors return the pieces:

```julia
using GLLVM, Random
Random.seed!(1)
p, n, K = 6, 200, 2
Λtrue = 0.8 .* randn(p, K)
Y = Λtrue * randn(K, n) .+ 0.5 .* randn(p, n)   # p × n responses

fit = fit_gaussian_gllvm(Y; K = K)

Σ  = sigma_y_site(fit)    # p×p model-implied covariance ΛΛᵀ + Ψ
c² = communality(fit)     # per-response shared fraction (ΛΛᵀ)ₜₜ / Σₜₜ ∈ [0,1]
R  = correlation(fit)     # p×p cross-response correlation derived from Σ_y
```

## Reading the results

- **`communality(fit)`** — for each response, the fraction of its variance
  explained by the shared latent factors. A response with `c² ≈ 0.8` is largely
  driven by the shared gradient; one with `c² ≈ 0.1` is mostly idiosyncratic.
- **`correlation(fit)`** — the model's estimate of which responses co-vary. A
  strong positive entry means two species respond similarly to the latent
  gradient (e.g. a shared environmental axis); a negative entry means they
  trade off.
- **`sigma_y_site(fit)`** — the full covariance on the raw scale, e.g. to
  compare against an empirical covariance matrix.

## When you need `unique`

If some responses carry their own variance component beyond the shared factors
(the gllvmTMB `unique()` case), that variance flows into the diagonal of `Σ_y`
through `Ψ`, and `communality` reports the correspondingly smaller shared
fraction.

## Uncertainty on derived quantities

The extractors above are point estimates. For an interval on a *derived*
quantity — a `Σ_y` entry, a communality, a cross-response correlation — use the
derived-quantity confidence intervals (`confint_derived`, and the
transformed-scale Wald intervals for `[0,1]`- and `[−1,1]`-bounded quantities),
which provide profile-likelihood and parametric-bootstrap intervals.

See also: [Get started](/quickstart) · [Model](/model) · [Reference](/api).
