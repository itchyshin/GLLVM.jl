# Tutorial: fit, read, ordinate, select, predict

This is the guided tour: take a species-by-site count matrix, fit a GLLVM,
read off the estimates, draw an ordination, choose the latent dimension,
predict, run residual diagnostics, and pick an estimator. Every code block is
static — copy it into a REPL with GLLVM.jl installed to follow along.

## What a GLLVM is

A **Generalised Linear Latent Variable Model** treats a multivariate response
matrix `Y` — typically *species × sites* (rows = responses, columns = sampling
units) — as driven by a handful of unobserved **latent factors**. Each site has
a low-dimensional latent score `z` (the "ordination" coordinate); each species
has a **loading** vector that says how strongly it responds to each factor. The
factors stand in for unmeasured environmental gradients and the residual
co-occurrence structure among species.

The mean of each entry is

```
g(μ[j,i]) = β[j] + Λ[j,:] · z[i]
```

a per-species intercept `β` plus a loading-weighted latent score, passed through
a link `g`. GLLVM.jl fits the **Gaussian** family in closed form and a wide range
of **non-Gaussian** families (counts, proportions, ordered categories,
zero-inflated/hurdle/delta) through a Laplace or variational marginal — fast
enough to scale to large species counts.

## 1. Get a response matrix

`Y` is `p × n` — `p` species (rows) by `n` sites (columns). For counts it is an
integer matrix. Here we simulate a two-factor Poisson GLLVM:

```julia
using GLLVM, Random

Random.seed!(2026)
p, n, K = 12, 150, 2          # 12 species, 150 sites, 2 latent factors

Λ_true = 0.7 .* randn(p, K)   # species loadings
β_true = randn(p)             # species intercepts (log scale)
Z      = randn(K, n)          # latent site scores

η = β_true .+ Λ_true * Z      # p×n linear predictor (log link)
Y = [rand(Poisson(exp(η[j, i]))) for j in 1:p, i in 1:n]   # p×n counts
```

In practice you would load your own community matrix (e.g. from a CSV with
species as rows, sites as columns) instead of simulating.

## 2. Fit the model

The family-specific driver is the most direct entry point:

```julia
fit = fit_poisson_gllvm(Y; K = 2)
```

Equivalently, the **unified entry point** dispatches on a `Distributions.jl`
family marker:

```julia
fit = fit_gllvm(Y; family = Poisson(), K = 2)
```

Both return the same `PoissonFit`. The unified `fit_gllvm` supports
`Normal`, `Poisson`, `NegativeBinomial`, `Binomial`, `Beta`, `Gamma`,
`Exponential`, and `Ordinal`; the two-part families — ZIP, ZINB, hurdle-Poisson,
hurdle-NB, delta-lognormal, delta-Gamma — have dedicated `fit_<family>_gllvm`
drivers (see [Response families](/response-families)). Displaying the fit prints
a summary with the family, dimensions, log-likelihood, AIC, and convergence:

```julia
fit          # rich REPL summary
```

## 3. Read the estimates

`coef_table` is the regression-style summary: one row per parameter, with the
point estimate, standard error, Wald `z`, p-value, and a confidence interval.

```julia
ct = coef_table(fit, Y)        # intercepts β and loadings Λ with SE, z, p, CI
```

The standard errors and CIs here are **Wald** intervals from the observed
information (the Hessian at the optimum) — one matrix solve, cheap and accurate
when the log-likelihood is locally quadratic. For parameters near a boundary or
when you want a likelihood-respecting interval, request a profile or parametric
bootstrap CI instead:

```julia
ci_profile   = confint(fit, Y; method = :profile)     # LRT inversion
ci_bootstrap = confint(fit, Y; method = :bootstrap)   # parametric bootstrap
```

Profile CIs invert the likelihood-ratio test (exact up to the bracketing
tolerance); bootstrap CIs resample from the fitted model and make no quadratic
assumption. Both cost much more than Wald — use them to spot-check the terms
that matter.

## 4. Ordinate

`ordination` packages the latent geometry into a single named tuple:

```julia
o = ordination(fit, Y)
o.sites       # n×K site scores  (the ordination point cloud)
o.species     # p×K species loadings (the ordination "arrows")
o.rotation    # K×K canonical rotation shared by sites and species
```

`o.sites` are the per-site latent scores you would scatter-plot as points;
`o.species` are the loadings you would draw as labelled arrows. Together they
make the **model-based ordination biplot** — species pointing the same way
co-occur along that latent gradient. Because latent factors are identified only
up to rotation, `ordination` returns a canonical (principal-axis, sign-fixed)
orientation by default so the picture is reproducible; pass `rotate = false` for
the raw fitted loadings.

```julia
using Plots                                  # not a GLLVM.jl dependency
scatter(o.sites[:, 1], o.sites[:, 2]; label = "sites", alpha = 0.4)
for j in 1:size(o.species, 1)
    plot!([0, o.species[j, 1]], [0, o.species[j, 2]]; arrow = true, label = "")
end
```

## 5. Choose the latent dimension

How many factors? `select_lv` sweeps `K = 1:Kmax`, fits each, and reports the
information criteria so you can pick the elbow:

```julia
sel = select_lv(Y; family = Poisson(), Kmax = 3)

sel.K          # the K values that fitted successfully
sel.loglik     # maximised log-likelihood per K
sel.aic        # AIC per K
sel.bic        # BIC per K   (uses size(Y,2) sites)
sel.best_k     # K minimising the criterion (BIC by default)
sel.best       # the fitted model at best_k
```

Lower AIC/BIC is better. BIC penalises extra factors more heavily, so it tends
to pick a smaller `K` than AIC. Use `criterion = :aic` to switch. `sel.best` is
a ready-to-use fit at the selected dimension.

## 6. Predict and run diagnostics

Fitted values come from `predict`, on either the link or the response scale:

```julia
η̂ = predict(fit, Y; type = :link)        # linear predictor β + Λz
μ̂ = predict(fit, Y; type = :response)    # expected counts (link applied)
```

The standard goodness-of-fit check is the **Dunn–Smyth** randomized quantile
residual, which is approximately `N(0, 1)` under a correct model and comparable
across families:

```julia
r  = residuals(fit, Y)                    # Dunn–Smyth (default)
rp = residuals(fit, Y; type = :pearson)   # Pearson, for comparison
```

For discrete families the Dunn–Smyth randomization draws on an RNG; pass a
seeded `rng` to reproduce. A normal Q–Q plot of `r` is the usual diagnostic —
systematic curvature flags the wrong family or too few factors.

Information criteria are also available directly off a single fit:

```julia
aic(fit)                # 2k − 2·logLik
bic(fit, size(Y, 2))    # k·log(n_sites) − 2·logLik  (pass n_sites explicitly)
```

`k` is the free-parameter count, with loadings counted modulo the `K(K−1)/2`
rotational degrees of freedom.

## 7. Laplace vs variational (VA)

The non-Gaussian fitters approximate the latent integral two ways. The
**Laplace** approximation is the default — a second-order expansion at the
conditional mode, fast and accurate for the common families. The
**variational approximation (VA)** instead optimizes an evidence lower bound
(ELBO) on the marginal likelihood. VA is steadier when the Laplace curvature is
unreliable — heavy dispersion or shape parameters, e.g. delta-Gamma or strongly
overdispersed counts — but it is slower and is therefore opt-in. For Poisson the
VA driver is a drop-in alternative:

```julia
fit_va = fit_poisson_gllvm_va(Y; K = 2)   # ELBO-based; slower, steadier
```

Reach for VA when a Laplace fit looks unstable (a degenerate Hessian, implausible
dispersion estimates); otherwise the default Laplace path is the right starting
point.

## 8. Covariates and traits

Real surveys come with site environment and species traits. GLLVM.jl exposes
several fixed-effect front ends, all taking the same `family` keyword:

```julia
# Shared environmental slope γ across species (X is p×n×q covariate array)
fit_gllvm_cov(Y; family = Poisson(), X = X, K = 2)

# Species-specific environmental responses B (one slope per species)
fit_gllvm_speciescov(Y; family = Poisson(), X = X, K = 2)

# Fourth-corner: trait × environment interaction
fit_fourthcorner_gllvm(Y; family = Poisson(), X = X, TR = TR, K = 2)

# Community row effects (per-site sampling intensity / total abundance)
fit_roweffect_gllvm(Y; family = Poisson(), K = 2)
```

For a familiar R-`gllvmTMB`-style interface, the `@formula` front end maps a
formula plus a site-level data table onto the engine:

```julia
gllvm(@formula(y ~ 1 + temp + depth), Y, site_data; family = Poisson(), K = 2)
```

The formula front end (v1) handles an intercept plus continuous main effects;
see [Structured dependence](/structured-dependence) for phylogenetic and
correlated-effect structures.

See also: [Get started](/quickstart) · [Working with a fit](/working-with-a-fit) ·
[Response families](/response-families) · [Confidence intervals](/confidence-intervals) ·
[Reference](/api).
