# Confidence intervals

GLLVM.jl provides three complementary interval methods — **Wald**, **profile
likelihood**, and **parametric bootstrap** — for both the Gaussian engine and
every non-Gaussian family.

## Non-Gaussian families — one entry point

For a fitted non-Gaussian model, all three methods are reached through a single
R-style call:

```julia
using GLLVM, Distributions

fit = fit_gllvm(Y; family = Poisson(), K = 2)

confint(fit, Y; method = :wald)                          # observed-information Wald
confint(fit, Y; method = :profile,  parm = "beta[1]")    # profile-likelihood (LRT)
confint(fit, Y; method = :bootstrap, n_boot = 500)       # parametric bootstrap
```

`Y` is the same response matrix you fitted — it is needed to reconstruct the
marginal likelihood. The call returns a `NamedTuple` with `term`, `estimate`,
`lower`, `upper`, and `method` (plus method-specific extras below).

Supported fits: the GLM families (`PoissonFit`, `BinomialFit`, `NBFit`,
`NB1Fit`, `BetaFit`, `GammaFit`) and the two-part families (`DeltaLogNormalFit`,
`DeltaGammaFit`, `BetaHurdleFit`, `HurdlePoissonFit`, `HurdleNBFit`, `ZIPFit`,
`ZINBFit`, `ZIBFit`), and ordinal (`OrdinalFit`).

### Term names

| Family group | Names |
|--------------|-------|
| GLM families | `beta[t]`, `Lambda[i,k]`, and a dispersion `r` / `phi` / `alpha` |
| Two-part families | `betaz[t]` (occurrence / zero-inflation logits), `betac[t]` (value / count intercepts), `Lambda[i,k]`, and `sigma` / `alpha` / `r` |
| Ordinal | `Lambda[i,k]`, `tau[c]` (cutpoints) |

Dispersion parameters are estimated on the log scale internally; their interval
**bounds are reported on the natural (positive) scale**.

`parm` subsets the terms: an exact name (`"beta[1]"`, `"r"`), a group (`"beta"`,
`"Lambda"`, `"betac"`, `"tau"`), or a vector of these.

## The three methods

### Wald — `method = :wald`

The Hessian of the negative Laplace log-likelihood is formed by **central finite
differences** at the MLE (the Laplace inner mode-finder is not forward-AD-
friendly, matching how the fitters themselves are optimised), then inverted for
the asymptotic covariance; `lower/upper = θ̂ ± z·SE`. Returns an extra
`pd_hessian::Bool` flagging whether the observed information was positive
definite. Cheapest method; assumes approximate normality on the working scale.

### Profile likelihood — `method = :profile`

Inverts the likelihood-ratio test: the deviance `D(c) = 2(ℓ̂ − ℓ_p(c))` is
χ²₁ under `θ_i = c`, and the interval is `{c : D(c) ≤ qchisq(level, 1)}`. Each
side is located by **bracket-then-bisection**, re-optimising the other
parameters at every candidate. Better coverage than Wald when the likelihood is
asymmetric. Returns a per-term `status` (`:profile` / `:partial` / `:failed`).

### Parametric bootstrap — `method = :bootstrap`

Simulates `n_boot` datasets from the fitted model, refits each, and takes
percentile bounds. The gold standard for skewed or bounded parameters, at the
cost of `n_boot` refits.

```julia
confint(fit, Y; method = :bootstrap, n_boot = 1000, parallel = true)
```

Set `parallel = true` to run replicates over `Threads.@threads`. **Each
replicate seeds its own RNG (`seed + b`)**, so the result is independent of
thread scheduling — multi-core and single-core give identical bounds. Returns an
extra `n_converged::Int` (replicates whose refit failed or changed dimension are
dropped). Start Julia with `julia -t auto` to use multiple threads.

## Gaussian engine

The Gaussian fit keeps its own dedicated functions (it has the richest parameter
structure — `σ_eps`, between/within tiers, phylogenetic blocks):

```julia
fit = fit_gaussian_gllvm(y; K = 2)
confint(fit; y = y)                       # Wald (observed information)
profile_ci(fit, "sigma_eps"; y = y)       # profile likelihood
bootstrap_ci(fit; y = y, n_boot = 500)    # parametric bootstrap
```

and derived-quantity CIs (Σ_y entries, communality, correlation, phylogenetic
signal H²) via [`confint_derived`-family helpers](/covariance-correlation).

See also: [Response families](/response-families) · [Working with a fit](/working-with-a-fit) · [Reference](/api).
