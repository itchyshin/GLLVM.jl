# Response families

A GLLVM links its latent factors to the responses through a **response family**
and a **link**. GLLVM.jl follows the Julia convention (as in GLM.jl): the family
is a `Distributions.jl` distribution, chosen with the `family =` keyword to
`fit_gllvm`.

## The unified one-part entry point

`fit_gllvm` is the matrix-level entry point for one-part response families:

```julia
using GLLVM, Distributions

# Gaussian responses (continuous) — exact closed-form marginal
fit_gllvm(Y;  family = Normal(),   K = 2)

# Binary / binomial responses — Laplace marginal
fit_gllvm(Yb; family = Binomial(), K = 2, link = LogitLink())

# Count data — Laplace marginal
fit_gllvm(Yc; family = Poisson(), K = 2)

# Overdispersed counts — Laplace marginal
fit_gllvm(Yc; family = NegativeBinomial(), K = 2)

# Proportions in (0,1) — Laplace marginal
fit_gllvm(Yp; family = Beta(), K = 2)

# Ordered categories — Laplace marginal
fit_gllvm(Yo; family = Ordinal(), K = 2)

# Positive continuous data — Laplace marginal
fit_gllvm(Yg; family = Gamma(), K = 2)
```

`fit_gllvm` dispatches on the family: `Normal()` uses the exact closed-form
Gaussian marginal; all non-Gaussian families use a Laplace approximation,
because the latent integral is non-conjugate for non-Gaussian families.

Two-part families are available through dedicated fitters for now, not through
`fit_gllvm`:

```julia
fit_delta_lognormal_gllvm(Y; K = 2)  # zeros + positive lognormal response
fit_hurdle_poisson_gllvm(Y; K = 2)   # zeros + positive counts
fit_hurdle_nb_gllvm(Y; K = 2)        # zeros + overdispersed positive counts
```

## Links

For binomial responses you can choose the link:

| Link | `linkinv(η)` | Use |
|:-----|:-------------|:----|
| `LogitLink()` *(default)* | logistic | log-odds; the canonical binary link |
| `ProbitLink()` | `Φ(η)` | latent-Gaussian threshold models |
| `CLogLogLink()` | `1 − exp(−eη)` | asymmetric; rare-event / occupancy |

```julia
fit_gllvm(Yb; family = Binomial(), K = 2, link = ProbitLink())
```

For `Poisson`, `NegativeBinomial`, and `Gamma` the default and only supported
link is `LogLink()`. For `Beta` and `Ordinal` the default is `LogitLink()`.

## Supported families

| Family | Entry point | Status | Link | Marginal | Extra parameter | Notes |
|:-------|:------------|:-------|:-----|:---------|:----------------|:------|
| `Normal()` | `fit_gllvm`, `fit_gaussian_gllvm` | available | identity | closed form | — | continuous; the original engine |
| `Binomial()` | `fit_gllvm`, `fit_binomial_gllvm` | available | logit / probit / cloglog | Laplace | — | binary and binomial counts |
| `Poisson()` | `fit_gllvm`, `fit_poisson_gllvm` | available | log | Laplace | — | counts |
| `NegativeBinomial()` | `fit_gllvm`, `fit_nb_gllvm` | available | log | Laplace | dispersion `r` (Var = μ + μ²/r) | overdispersed counts; `r` jointly estimated |
| `Beta()` | `fit_gllvm`, `fit_beta_gllvm` | available | logit | Laplace | precision `φ` (Var = μ(1−μ)/(1+φ)) | proportions in (0,1); `φ` jointly estimated |
| `Ordinal()` | `fit_gllvm`, `fit_ordinal_gllvm` | available | cumulative logit | Laplace | `C−1` cutpoints `τ` | ordered categories `1:C`; common cutpoints, no species intercept |
| `Gamma()` | `fit_gllvm`, `fit_gamma_gllvm` | available | log | Laplace | shape `α` (Var = μ²/α) | positive continuous; `α` jointly estimated |
| Delta-lognormal | `fit_delta_lognormal_gllvm` | available | logit + log | two-part Laplace | log-scale `σ` | zero mass plus positive continuous response |
| Hurdle-Poisson | `fit_hurdle_poisson_gllvm` | available | logit + log | two-part Laplace | — | zero mass plus positive count response |
| Hurdle-NB | `fit_hurdle_nb_gllvm` | available | logit + log | two-part Laplace | dispersion `r` | zero mass plus overdispersed positive counts |
| Delta-Gamma | — | planned | logit + log | — | shape `α` | next positive-continuous two-part family |
| zero-inflated Poisson / NB | — | planned | logit + log | — | count dispersion for ZINB | structural zero mixture, not hurdle truncation |

Calling `fit_gllvm` with an unimplemented family raises a clear error listing
what is currently available through that unified one-part dispatcher.

## Family details

### Gaussian — `Normal()`

```julia
fit = fit_gllvm(Y; family = Normal(), K = 2)
```

The Gaussian GLLVM admits a **closed-form marginal** (no Laplace approximation).
The latent integral is conjugate, so the optimiser works directly on the exact
log-likelihood. This is the fastest and most accurate path. The response matrix
`Y` is `p × n` (responses × sites).

### Binomial — `Binomial()`

```julia
fit = fit_gllvm(Yb; family = Binomial(), K = 2)                    # Bernoulli
fit = fit_gllvm(Yb; family = Binomial(), K = 2, N = trials)        # binomial counts
fit = fit_gllvm(Yb; family = Binomial(), K = 2, link = ProbitLink())
```

For binary responses (Bernoulli), `Y` is a `p × n` integer matrix of 0/1.
For binomial *counts*, pass the trial counts as `N` — a `p × n` integer matrix;
the default is all-ones (Bernoulli). Link choices: `LogitLink()` (default),
`ProbitLink()`, `CLogLogLink()`.

### Poisson — `Poisson()`

```julia
fit = fit_gllvm(Yc; family = Poisson(), K = 2)
```

For count data (`Y` a `p × n` integer matrix). Uses a log link and a Laplace
marginal. Poisson GLLVMs are a natural starting point for species-abundance
matrices before considering overdispersion.

### Negative Binomial — `NegativeBinomial()`

```julia
fit = fit_gllvm(Yc; family = NegativeBinomial(), K = 2)
```

For overdispersed counts. The NB2 variance function is Var = μ + μ²/r; the
dispersion `r` is jointly estimated alongside `β` and `Λ`. As `r → ∞` the
negative binomial collapses to Poisson. The fitted dispersion is available as
`fit.r`.

### Beta — `Beta()`

```julia
fit = fit_gllvm(Yp; family = Beta(), K = 2)
```

For proportions strictly inside (0,1) — e.g. cover fractions, frequencies.
The per-observation law is Beta(μφ, (1−μ)φ), so Var = μ(1−μ)/(1+φ). The
precision `φ` is jointly estimated; the estimate is available as `fit.φ`.

### Ordinal — `Ordinal()`

```julia
fit = fit_gllvm(Yo; family = Ordinal(), K = 2)
```

For ordered categorical responses coded `1:C` (e.g. Likert scales, abundance
classes). Uses a proportional-odds cumulative-logit model with `C−1` ordered
cutpoints `τ` shared across species. There is no species intercept — the
cutpoints carry the category levels. The fitted cutpoints are available as
`fit.τ`.

### Gamma — `Gamma()`

For positive-continuous data with Var = μ²/α (constant coefficient of variation),
fit with `fit_gamma_gllvm` — or the unified entry point — which jointly estimates
the shape `α`:

```julia
fit = fit_gllvm(Yp; family = Gamma(), K = 2)   # Yp > 0
```

### Two-part fits

Two-part models separate occurrence from the positive response. The current
public surface fixes the occurrence loading block to intercepts only
(`Λz = 0`) and places the low-rank latent structure in the positive block:

```julia
fit_delta_lognormal_gllvm(Y; K = 2)  # zero or positive real values
fit_hurdle_poisson_gllvm(Y; K = 2)   # non-negative integer counts
fit_hurdle_nb_gllvm(Y; K = 2)        # overdispersed non-negative integer counts
```

Treat these as dedicated fitters while the same-as-R formula layer and
response-scale two-part correlation estimands are still being built.

## Extractors

The same post-fit extractors (`communality`, `correlation`, `sigma_y_site`, …)
work for the Gaussian covariance surface and the one-part fit objects. For
non-Gaussian families, `getLV`, `predict`, `fitted`, `residuals`, `aic`, `bic`,
and display summaries are the primary post-fit tools; covariance-scale
extractors are still Gaussian-only unless the specific fit object documents
otherwise.

```julia
gfit = fit_gllvm(Y; family = Normal(), K = 2)  # Gaussian fit (Y continuous)
communality(gfit)   # shared-variance fraction per response  (Gaussian-only)
correlation(gfit)   # cross-response correlation matrix       (Gaussian-only)
getLV(gfit, Y)      # latent variable scores (sites × K)      (all families)
```

See [Working with a fit](working-with-a-fit.md) for the full extractor reference.

See also: [Get started](quickstart.md) · [Covariance and correlation](covariance-correlation.md) · [Reference](api.md).
