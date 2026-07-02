# Confidence intervals

GLLVM.jl provides three complementary interval methods — **Wald**, **profile
likelihood**, and **parametric bootstrap** — for the Gaussian engine and the
admitted non-Gaussian CI rows.

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
`NB1Fit`, `BetaFit`, `GammaFit`), grouped-dispersion NB2/NB1/Beta/Gamma fits,
the two-part families (`DeltaLogNormalFit`, `DeltaGammaFit`, `BetaHurdleFit`,
`HurdlePoissonFit`, `HurdleNBFit`, `ZIPFit`, `ZINBFit`, `ZIBFit`), and
shared-cutpoint ordinal (`OrdinalFit`). Grouped Tweedie and per-trait ordinal
cutpoint CI endpoints are deliberate follow-ups.

### Term names

| Family group | Names |
|--------------|-------|
| GLM families | `beta[t]`, `Lambda[i,k]`, and a dispersion `r` / `phi` / `alpha` |
| Grouped NB2/NB1/Beta/Gamma | `beta[t]`, `Lambda[i,k]`, and group-level dispersion `r[g]` / `phi[g]` / `alpha[g]` |
| Two-part families | `betaz[t]` (occurrence / zero-inflation logits), `betac[t]` (value / count intercepts), `Lambda[i,k]`, and `sigma` / `alpha` / `r` |
| Ordinal (`OrdinalFit`, shared cutpoints) | `Lambda[i,k]`, `tau[c]` (cutpoints) |

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
Use `profile_iterations`, `profile_g_tol`, `profile_max_expand`, and
`profile_max_bisect` to tune the constrained-refit and bracketing budget when a
profile canary needs tighter or cheaper refits.

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

## Predictor-informed latent-score effects

For fits with `X_lv`, `confint_lv_effects(fit, Y, X_lv)` targets the induced,
rotation-stable trait-effect matrix `B_lv = Lambda * alpha_lv'`. Wald,
profile-likelihood, and bootstrap intervals are native Julia uncertainty
routes for admitted ordinary `X_lv` fits; bootstrap remains a cost-bounded
diagnostic complement rather than the default engine.

```julia
ci_all = confint_lv_effects(fit, Y, X_lv; method = :profile)
ci_some = confint_lv_effects(fit, Y, X_lv; method = :profile,
                             profile_indices = [2, 4])
```

`profile_indices` selects entries of `vec(B_lv)` in column-major order, matching
returned names such as `B_lv[2,1]` and `B_lv[4,1]`. It is intentionally only
accepted with `method = :profile`; Wald/bootstrap calls return their full
supported surface.

See also: [Response families](/response-families) · [Working with a fit](/working-with-a-fit) · [Reference](/api).
