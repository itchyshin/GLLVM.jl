# Response families

A GLLVM links its latent factors to the responses through a **response family**
and a **link**. GLLVM.jl follows the Julia convention (as in GLM.jl): the family
is a `Distributions.jl` distribution, chosen with the `family =` keyword to
`fit_gllvm`.

## The unified entry point

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
```

`fit_gllvm` dispatches on the family: `Normal()` uses the exact closed-form
Gaussian marginal; all non-Gaussian families use a Laplace approximation,
because the latent integral is non-conjugate for non-Gaussian families.

## Links

For binomial responses you can choose the link:

| Link | `linkinv(η)` | Use |
|------|--------------|-----|
| `LogitLink()` *(default)* | logistic | log-odds; the canonical binary link |
| `ProbitLink()` | `Φ(η)` | latent-Gaussian threshold models |
| `CLogLogLink()` | `1 − exp(−eη)` | asymmetric; rare-event / occupancy |

```julia
fit_gllvm(Yb; family = Binomial(), K = 2, link = ProbitLink())
```

For `Poisson`, `NegativeBinomial`, and `Gamma` the default and only supported
link is `LogLink()`. For `Beta` the default is `LogitLink()`. `Ordinal` defaults
to a cumulative `LogitLink()` and also supports `ProbitLink()`. Beta-binomial
supports `LogitLink()` (default), `ProbitLink()`, and `CLogLogLink()`.

## Supported families

| Family | Status | Link | Marginal | Extra parameter | Notes |
|--------|--------|------|----------|-----------------|-------|
| `Normal()` | ✅ available | identity | closed form | — | continuous; the original engine |
| `Binomial()` | ✅ available | logit / probit / cloglog | Laplace | — | binary (Bernoulli) and binomial counts |
| `Poisson()` | ✅ available | log | Laplace | — | counts |
| `NegativeBinomial()` | ✅ available | log | Laplace | dispersion `r` (Var = μ + μ²/r) | overdispersed counts; `r` jointly estimated |
| NB1 | ✅ available | log | Laplace | dispersion `φ` (Var = μ(1+φ)) | linear-variance (quasi-Poisson-like) overdispersed counts; `fit_nb1_gllvm` |
| `Beta()` | ✅ available | logit | Laplace | precision `φ` (Var = μ(1−μ)/(1+φ)) | proportions in (0,1); `φ` jointly estimated |
| `Ordinal()` | ✅ available | cumulative logit / probit | Laplace | `C−1` cutpoints `τ` | ordered categories `1:C`; common cutpoints, no species intercept |
| `Gamma()` | ✅ available | log | Laplace | shape `α` (Var = μ²/α) | positive continuous; `α` jointly estimated |
| `Exponential()` | ✅ available | log | Laplace | — | positive continuous, `Var = μ²` (Gamma with α=1) |
| Tweedie | ✅ available | log | Laplace | dispersion `φ`, power `p` (1<p<2) | compound Poisson–Gamma; biomass / abundance with true zeros; `fit_tweedie_gllvm` |
| Ordered-beta | ✅ available | logit | Laplace | precision `φ`, cutpoints `c₀<c₁` | proportions / cover with point masses at 0 and 1; `fit_ordered_beta_gllvm` |
| Delta-lognormal | ✅ available | logit × identity(log) | two-part Laplace | log-SD `σ` | occurrence × positive lognormal; `fit_delta_lognormal_gllvm` |
| Delta-Gamma | ✅ available | logit × log | two-part Laplace | shape `α` | occurrence × positive Gamma; `fit_delta_gamma_gllvm` |
| Beta-hurdle | ✅ available | logit × logit | two-part Laplace | precision `φ` | occurrence × positive Beta; `fit_beta_hurdle_gllvm` |
| Hurdle-Poisson | ✅ available | logit × log | two-part Laplace | — | occurrence × zero-truncated Poisson; `fit_hurdle_poisson_gllvm` |
| Hurdle-NB | ✅ available | logit × log | two-part Laplace | dispersion `r` | occurrence × zero-truncated NB2; `fit_hurdle_nb_gllvm` |
| ZIP | ✅ available | logit × log | two-part Laplace | — | zero-inflated Poisson; `fit_zip_gllvm` |
| ZINB | ✅ available | logit × log | two-part Laplace | dispersion `r` | zero-inflated NB2; `fit_zinb_gllvm` |
| ZIB | ✅ available | logit × logit | two-part Laplace | — | zero-inflated Binomial; `fit_zib_gllvm` |
| Beta-binomial | ✅ available | logit / probit / cloglog | Laplace | precision `φ` (`a = μφ, b = (1−μ)φ`) | overdispersed binomial counts; `fit_beta_binomial_gllvm`; → Binomial as `φ → ∞` |

The single-block families with a plain `Distributions` marker — `Normal`,
`Binomial`, `Poisson`, `NegativeBinomial` (NB2), `Beta`, `Ordinal`, `Gamma`,
`Exponential` — are reached through the unified `fit_gllvm` entry. NB1,
beta-binomial, Tweedie, and the two-part families currently have dedicated
`fit_<family>_gllvm` drivers (they carry estimated parameters — `σ`, `α`, `r`,
`φ`, the Tweedie power — or trial counts that do not yet share a single
`Distributions` marker). Calling `fit_gllvm` with an unimplemented family raises a
clear error listing what is currently available.

**Phylogenetic GLM.** For a per-species phylogenetic random intercept under a
non-Gaussian family, `fit_phylo_glm(Y, phy; family = …)` fits the augmented-state
joint Laplace marginal (Poisson / NB / Binomial, with a dispersion parameter for
the dispersion families) over the sparse phylogenetic precision.

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
`fit.τ`. The cumulative link is `LogitLink()` by default; pass
`link = ProbitLink()` for a cumulative-probit (ordered-probit) model.

### Gamma — `Gamma()`

For positive-continuous data with Var = μ²/α (constant coefficient of variation),
fit with `fit_gamma_gllvm` — or the unified entry point — which jointly estimates
the shape `α`:

```julia
fit = fit_gllvm(Yp; family = Gamma(), K = 2)   # Yp > 0
```

### Beta-binomial — `fit_beta_binomial_gllvm`

```julia
fit = fit_beta_binomial_gllvm(Yb; K = 2, N = trials)   # overdispersed binomial
```

For binomial counts that are **over-dispersed** relative to `Binomial(N, μ)` — the
per-trial success probability is itself random, `p ~ Beta(a, b)` with `a = μφ`,
`b = (1−μ)φ`. `Y` is a `p × n` matrix of integer successes; `N` the matching trial
counts (default all-ones, i.e. an over-dispersed Bernoulli). The Beta precision
`φ` (the shape-sum `a + b`) is jointly estimated and available as `fit.φ`; as
`φ → ∞` the family collapses to `Binomial(N, μ)`. Links: `LogitLink()` (default),
`ProbitLink()`, `CLogLogLink()`. This family has a dedicated driver rather than
going through `fit_gllvm`.

### Per-species and grouped dispersion

For the five dispersion families, the dispersion can vary across species (gllvm's
`disp.group`) instead of being shared. Each has a `_grouped` driver taking a
length-`p` `group` vector of integer group ids (default `1:p` = a separate
dispersion per species); with one group the result matches the shared-dispersion
fit:

```julia
fit_nb_gllvm_grouped(Yc;  K = 2, group = group)   # NB2 dispersion r per group
fit_nb1_gllvm_grouped(Yc; K = 2)                  # NB1 dispersion φ, default per-species
fit_beta_gllvm_grouped(Yp;    K = 2)              # Beta precision φ per species
fit_gamma_gllvm_grouped(Yc;   K = 2)              # Gamma shape α per species
fit_tweedie_gllvm_grouped(Yc; K = 2)             # Tweedie dispersion φ per species (shared power p)
```

(`fit_nb_gllvm_grouped` requires an explicit `group`; the other four default to
per-species.)

### Gaussian with per-species variance — `fit_gaussian_pervar_gllvm`

```julia
fit = fit_gaussian_pervar_gllvm(Y; K = 2)   # heteroscedastic Gaussian
```

A heteroscedastic Gaussian GLLVM with a **separate residual variance per species**
(gllvm's heteroscedastic default), in contrast to the single shared `σ_eps` of
`fit_gaussian_gllvm`. The per-species intercepts are profiled out analytically
(column means), so only the per-species variances and the loadings are optimised.

## Two-part families (occurrence/zero × value)

Two-part families model a response with a point mass at zero plus a distribution
over the non-zero (or count) part. They share a single latent `z` that loads on
the value part (`Λ_c`); the occurrence / zero-inflation part is a per-species
intercept (`β_z`, i.e. `Λ_z = 0`). Each has a dedicated fitter returning a
result with `βz`, `βc`, `Λc` (and a dispersion where relevant):

```julia
fit = fit_delta_lognormal_gllvm(Y; K = 2)   # Y ≥ 0; positive part lognormal, log-SD σ
fit = fit_delta_gamma_gllvm(Y;     K = 2)   # Y ≥ 0; positive part Gamma, shape α
fit = fit_hurdle_poisson_gllvm(Y;  K = 2)   # counts; occurrence × zero-truncated Poisson
fit = fit_hurdle_nb_gllvm(Y;       K = 2)   # counts; occurrence × zero-truncated NB2, r
fit = fit_zip_gllvm(Y;             K = 2)   # counts; structural zero × Poisson
fit = fit_zinb_gllvm(Y;            K = 2)   # counts; structural zero × NB2, r
```

**Hurdle vs zero-inflated.** A *hurdle* model treats every zero as a
non-occurrence and the positive part as a **zero-truncated** count. A
*zero-inflated* model mixes a structural-zero process with an **ordinary** count
that can itself produce zeros: `P(y=0) = π + (1−π)·P_count(0)`. ZIP → Poisson as
the zero-inflation `π → 0`; ZINB → ZIP as `r → ∞`.

`predict` exposes the parts: `:occurrence` / `:zeroinfl` (the Bernoulli
probability), `:positive` / `:mean` (the value-part mean), and `:response` (the
unconditional mean). `residuals` gives randomized-quantile (Dunn–Smyth) residuals
under the correct two-part CDF.

## Extractors

The same post-fit extractors (`communality`, `correlation`, `sigma_y_site`, …)
work for all implemented families:

```julia
communality(fit)   # shared-variance fraction per response
correlation(fit)   # cross-response correlation matrix
getLV(fit)         # latent variable scores (sites × K)
```

See [Working with a fit](/working-with-a-fit) for the full extractor reference.

See also: [Get started](/quickstart) · [Covariance and correlation](/covariance-correlation) · [Reference](/api).
