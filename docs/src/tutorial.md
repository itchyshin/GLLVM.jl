# Tutorial

A practical, copy-pasteable walkthrough of the modern GLLVM.jl workflow: fit a
community matrix under any of the response families, read off the ordination and
estimates, build confidence intervals, add covariate / trait / row-effect
structure, and reach the structured-latent extensions (spatial SPDE fields,
phylogenetic GLLVMs). Every code block is static — copy it into a REPL with
GLLVM.jl installed to follow along. The data convention throughout is
**`Y` is `p × n`**: `p` species (rows) by `n` sites (columns).

```julia
using GLLVM, Distributions, Random
```

## 1. Core families

The most direct entry is the **unified** `fit_gllvm`, which dispatches on a
`Distributions.jl` family marker (the GLM.jl convention) and forwards `K` and any
family-specific keywords to the underlying fitter:

```julia
fit = fit_gllvm(Y; family = Poisson(), K = 2)   # counts, log link, Laplace marginal
```

`fit_gllvm` dispatches `Normal()`, `Poisson()`, `Binomial()`,
`NegativeBinomial()`, `Beta()`, `Gamma()`, `Exponential()`, and `Ordinal()`.
Each is equivalently reachable through its **family-specific driver**, which is
where the family-specific keyword arguments live:

```julia
fp = fit_poisson_gllvm(Y; K = 2)                       # Poisson (counts)
fn = fit_nb_gllvm(Y; K = 2)                            # NB2: Var = μ + μ²/r
fb = fit_binomial_gllvm(Y; K = 2, N = N)               # Binomial, N = trial counts
fβ = fit_beta_gllvm(Yp; K = 2)                         # Beta, proportions in (0,1)
fg = fit_gamma_gllvm(Yc; K = 2)                        # Gamma, positive continuous
fe = fit_exponential_gllvm(Yc; K = 2)                  # Exponential (no dispersion)
fo = fit_ordinal_gllvm(Yo; K = 2)                      # ordered categories 1:C
```

`fit_binomial_gllvm` takes `N` (a `p×n` integer matrix of trial counts; default
all-ones = Bernoulli). The default links are the canonical ones — `LogLink()`
for counts / positive continuous, `LogitLink()` for Binomial / Beta / Ordinal —
and can be overridden with `link = ...` (`LogitLink`, `ProbitLink`,
`CLogLogLink`, `LogLink`, `IdentityLink`).

Two negative-binomial variances are available. The default `fit_nb_gllvm` is
**NB2** (quadratic, `Var = μ + μ²/r`); `fit_nb1_gllvm` is **NB1** (linear,
`Var = μ(1 + φ)`, quasi-Poisson-like) for communities whose overdispersion grows
proportionally with the mean:

```julia
f2 = fit_nb_gllvm(Y;  K = 2)    # NB2, dispersion r
f1 = fit_nb1_gllvm(Y; K = 2)    # NB1, dispersion φ; Var = μ(1+φ)
```

For biomass / abundance with exact zeros and continuous positives, **Tweedie**
(compound Poisson–Gamma, `1 < p < 2`) fits the power mean–variance model
directly, estimating both the dispersion `φ` and the power `p`:

```julia
ft = fit_tweedie_gllvm(Y; K = 2)    # Tweedie; fitted φ and power p
ft.φ, ft.p
```

Displaying any fit prints a summary (family, dimensions, log-likelihood, AIC,
convergence):

```julia
fp            # rich REPL summary
```

## 2. Zero-inflated and two-part families

When zeros are *more* frequent than the count family predicts, use a
zero-inflated or hurdle/delta model. These carry **two** linear predictors — an
occurrence/zero part (`βz`) and a positive/count part (`βc`, with loadings `Λc`)
— so they have dedicated drivers rather than going through `fit_gllvm`:

```julia
# Zero-inflated (a structural-zero mixture)
fzip  = fit_zip_gllvm(Y;  K = 2)              # zero-inflated Poisson
fzinb = fit_zinb_gllvm(Y; K = 2)             # zero-inflated NB2 (dispersion r)
fzib  = fit_zib_gllvm(Y;  K = 2, N = 10)     # zero-inflated Binomial — N trials (Int)

# Hurdle (Bernoulli occurrence × zero-truncated positive count)
fhp = fit_hurdle_poisson_gllvm(Y; K = 2)
fhn = fit_hurdle_nb_gllvm(Y;      K = 2)

# Delta / two-part continuous (occurrence × positive continuous)
fdl = fit_delta_lognormal_gllvm(Yc; K = 2)   # Bernoulli × lognormal
fdg = fit_delta_gamma_gllvm(Yc;     K = 2)   # Bernoulli × Gamma
fbh = fit_beta_hurdle_gllvm(Yp;     K = 2)   # Bernoulli × Beta (point mass at 0)
```

`fit_zib_gllvm` needs the number of trials `N` as a scalar `Int` (a shared trial
count for all entries). The two-part fits expose `βz` (occurrence/zero logits),
`βc` (positive-part intercepts), `Λc` (positive-part loadings), and the relevant
dispersion (`r` for ZINB / hurdle-NB, `σ` for delta-lognormal, `α` for
delta-Gamma).

## 3. Ordination and post-fit

All single- and two-part fits share one post-fit API. The headline ecology
summary is `ordination`, which returns the site/species coordinates in the shared
latent space as a named tuple:

```julia
o = ordination(fp, Y)        # Y must match the matrix passed to the fitter
o.sites                       # n×K site scores (the ordination point cloud)
o.species                     # p×K species loadings (the "arrows")
o.rotation                    # K×K canonical (principal-axis) rotation
```

The two coordinate sets are also available directly:

```julia
getLV(fp, Y)                  # n×K conditional latent scores (site ordination)
getLoadings(fp)               # p×K species loadings, canonically rotated
getLoadings(fp; rotate = false)   # raw fitted Λ
rotation(fp)                  # the canonical K×K rotation alone
```

Latent factors are identified only up to a `K×K` orthogonal rotation, so
`getLV` / `getLoadings` / `ordination` apply a canonical principal-axis,
sign-fixed rotation by default (`rotate = false` returns the raw fitted
orientation).

Fitted values come from `predict`, on the link or the response scale; `fitted` is
the response-scale shorthand:

```julia
predict(fp, Y; type = :link)        # linear predictor η = β + Λẑ
predict(fp, Y; type = :response)    # μ = linkinv(η) (e.g. exp(η) for counts)
fitted(fp, Y)                       # == predict(fp, Y; type = :response)
```

The standard goodness-of-fit check is the **Dunn–Smyth** randomized quantile
residual — approximately `N(0,1)` under a correct model and comparable across
families (a normal Q–Q plot is the usual diagnostic):

```julia
residuals(fp, Y)                    # Dunn–Smyth (default)
residuals(fp, Y; type = :pearson)   # Pearson, for comparison
```

For discrete families the Dunn–Smyth randomization draws on an RNG; pass a seeded
`rng` (e.g. `residuals(fp, Y; rng = MersenneTwister(1))`) to reproduce.

Information criteria come off a single fit; `bic` needs the site count passed
explicitly (the fit does not store the data):

```julia
aic(fp)                # 2k − 2·logLik
bic(fp, size(Y, 2))    # k·log(n_sites) − 2·logLik
```

To choose `K`, `select_lv` sweeps `K = 1:Kmax`, fits each, and reports the
criteria:

```julia
sel = select_lv(Y; family = Poisson(), Kmax = 3)
sel.aic; sel.bic; sel.best_k; sel.best     # sel.best is the fitted model at best_k
```

Lower AIC/BIC is better; BIC penalises extra factors more and tends to pick a
smaller `K`. Use `criterion = :aic` to switch.

Finally, `simulate` draws a fresh response matrix from a fitted model (useful for
posterior-predictive checks):

```julia
Ysim = simulate(fp, size(Y, 2))                 # p×n new draw
Ysim = simulate(fb, size(Y, 2); N = N)          # Binomial needs N
```

## 4. Inference

The non-Gaussian family fits share one confidence-interval entry,
`confint(fit, Y; method = ...)`, with three flavours:

```julia
confint(fp, Y; method = :wald)                              # observed-information Wald
confint(fp, Y; method = :profile, parm = "beta[1]")         # LRT-inversion profile
confint(fp, Y; method = :bootstrap, n_boot = 500, parallel = true)  # parametric bootstrap
```

Wald is one finite-difference-Hessian solve (cheapest, locally quadratic);
profile inverts the likelihood-ratio test (respects skew); bootstrap resamples
from the fitted model (no quadratic assumption, but slowest). `parm` subsets
terms by name (`"beta[1]"`, `"Lambda[2,1]"`, `"r"`) or by group (`"beta"`,
`"Lambda"`); `N = N` supplies Binomial trial counts.

All three methods accept the scalar-μ GLM families (`PoissonFit`, `BinomialFit`,
`NBFit`, `BetaFit`, `GammaFit`, `ExponentialFit`), the two-part families
(`ZIPFit`, `ZINBFit`, `ZIBFit`, the hurdle/delta fits), and `OrdinalFit`,
`GllvmCovFit`, `RowEffectFit`. (The Gaussian `GllvmFit` uses the separate
`confint` / `profile_ci` / `bootstrap_ci` interface — see
[Confidence intervals](/confidence-intervals).)

For the headline regression-style summary, `coef_table` wraps the Wald entry and
adds the `z` statistic and two-sided p-value:

```julia
coef_table(fp, Y)                       # term, estimate, std_error, z, pvalue, lower, upper
coef_table(fp, Y; parm = "beta", level = 0.90)
```

Any extra keywords flow through to `confint`, so `X = X` (covariate fits) and
`N = N` (Binomial) work unchanged.

## 5. Covariates and structure

Real surveys carry site environment and species traits. GLLVM.jl exposes several
fixed-effect front ends, all taking the same `family` marker. The `(p, n, q)`
covariate array `X` follows the engine contract `X[t, s, k]` = covariate `k` for
species `t` at site `s`:

```julia
# Shared environmental slope γ (one coefficient per covariate, all species)
fit_gllvm_cov(Y; family = Poisson(), X = X, K = 2).γ

# Species-specific slopes B (one row per species)
fit_gllvm_speciescov(Y; family = Poisson(), X = X, K = 2).B

# Community row effects ρ_s (per-site intercepts; ρ[1] ≡ 0 reference)
fit_roweffect_gllvm(Y; family = Poisson(), K = 2).ρ
```

The **fourth-corner** model structures the species × environment interaction
through measured traits — `Xenv` is the `n×q` site-by-covariate matrix, `TR` the
`p×r` species-by-trait matrix, and the fitted `q×r` coefficient matrix `C`
couples them (far fewer parameters than free per-species slopes):

```julia
fit_fourthcorner_gllvm(Y; family = Poisson(), Xenv = Xenv, TR = TR, K = 2).C
```

For **constrained ordination**, the latent axes are driven by site covariates.
`fit_constrained_gllvm` (= `fit_concurrent_gllvm`, gllvm's `num.lv.c`) keeps a
residual random effect, `z_s ~ N(B' x_s, I_K)`; `fit_rrr_gllvm` (gllvm's
`num.RR`, reduced-rank regression) makes the axes a deterministic `z_s = B' x_s`
(no residual integral). Both take a 2-D `n×q` site-covariate matrix `X`:

```julia
fc = fit_constrained_gllvm(Y; family = Poisson(), X = X, K = 2)
fr = fit_rrr_gllvm(Y;         family = Poisson(), X = X, K = 2)
fr.B               # q×K constrained ordination axes (environment → latent)
fr.Λ               # p×K species loadings on those axes
getLV(fr, X)       # n×K deterministic site scores z_s = B' x_s
```

For a familiar R-`gllvmTMB`-style interface, the `@formula` front end maps a
formula plus a site-level data table onto the engine (v1: an intercept +
continuous main effects; dispatches to `fit_gaussian_gllvm` for `Normal()` and
`fit_gllvm_cov` otherwise):

```julia
gllvm(@formula(y ~ 1 + temp + depth), Y, site_data; family = Poisson(), K = 2)
```

## 6. Structured latent fields

The latent variables can themselves be given spatial or phylogenetic structure.

### Spatial SPDE fields

`fit_spde_latent_gllvm` makes the `K` latent variables **spatially smooth**
Matérn-GMRF fields over a triangular mesh (gllvm's `corLV = "spatial"`). Build a
mesh from the site coordinates with `spde_mesh_delaunay` (or `spde_mesh_grid`),
then fit with the observation locations `locs` (`M×2`):

```julia
nodes, tris = spde_mesh_delaunay(locs)          # mesh from site coordinates
fs = fit_spde_latent_gllvm(Y, nodes, tris, locs; family = Poisson(), K = 1)
fs.κ, fs.τ                                       # fitted Matérn range / precision params
```

The headline capability is **kriging** to new, unobserved locations:
`predict_spatial` finds the field mode from the training data, then interpolates
the fitted Matérn field to `new_locs`:

```julia
μ_new = predict_spatial(fs, Y, locs, new_locs; type = :response)   # p×M′
```

### Phylogenetic GLLVM

`fit_phylo_glm` fits a per-species phylogenetic random intercept correlated
across species by a tree, via an augmented-state joint Laplace over the sparse
phylogenetic precision. Build the augmented tree from a Newick string with
`augmented_phy` (its leaf order must match the rows of `Y`, and
`p == phy.n_leaves`):

```julia
phy = augmented_phy("((A:0.1,B:0.2):0.3,C:0.5);")   # p = phy.n_leaves
fph = fit_phylo_glm(Y, phy; family = Poisson())      # Y is p×n
fph.σ²_phy                                            # estimated phylogenetic variance
```

`family` accepts the usual markers (`Poisson()`, `NegativeBinomial()`,
`Binomial()`, …); supply `N` for Binomial. As `σ²_phy → 0` the fit reduces to the
independent-family marginal.

## 7. Choosing a family

Match the family to the response support and its mean–variance behaviour:

- **Counts.** Start with `Poisson()`. If the data are overdispersed (variance
  grows faster than the mean), move to `NegativeBinomial()` — NB2
  (`fit_nb_gllvm`, `Var = μ + μ²/r`) for quadratic overdispersion, NB1
  (`fit_nb1_gllvm`, `Var = μ(1+φ)`) when it grows linearly.
- **Excess zeros.** If zeros are more common than the count family predicts,
  use a zero-inflated model (`fit_zip_gllvm`, `fit_zinb_gllvm`) for a structural-
  zero mixture, or a hurdle model (`fit_hurdle_poisson_gllvm`,
  `fit_hurdle_nb_gllvm`) when presence and abundance are governed by distinct
  processes.
- **Presence/absence and trials.** `Binomial()` (with `N` trials; `N ≡ 1` is
  Bernoulli for presence/absence).
- **Proportions in (0,1).** `Beta()`. If there are point masses at 0 (or at 0 and
  1), use `fit_beta_hurdle_gllvm` (zero) or `fit_ordered_beta_gllvm` (zeros and
  ones).
- **Positive continuous (biomass, size).** `Gamma()` (or `Exponential()` with no
  dispersion). With exact zeros mixed in, use a delta model
  (`fit_delta_gamma_gllvm`, `fit_delta_lognormal_gllvm`) or `fit_tweedie_gllvm`
  (which estimates the power `p` and handles the zeros in one model).
- **Ordered categories.** `Ordinal()` (proportional-odds cumulative logit).

When a Laplace fit looks unstable (a degenerate Hessian, implausible dispersion),
the variational (`fit_*_gllvm_va`) drivers optimise an ELBO instead — slower but
steadier; see [Response families](/response-families).

See also: [Get started](/quickstart) · [Working with a fit](/working-with-a-fit) ·
[Response families](/response-families) · [Structured dependence](/structured-dependence) ·
[Confidence intervals](/confidence-intervals) · [Reference](/api).
