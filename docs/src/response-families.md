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

# Overdispersed counts — per-species r by default (NBGroupedFit)
fit_gllvm(Yc; family = NegativeBinomial(), K = 2)

# Proportions in (0,1) — per-species φ by default (BetaGroupedFit)
fit_gllvm(Yp; family = Beta(), K = 2)

# Ordered categories — Laplace marginal
fit_gllvm(Yo; family = Ordinal(), K = 2)

# Heavy-tailed continuous — outlier-robust alternative to Normal()
fit_gllvm(Y;  family = StudentTFamily(4.0), K = 2)

# two-part continuous (occurrence × positive continuous)
fit_gllvm(Yd; family = DeltaLogNormal(), K = 2)
fit_gllvm(Yd; family = DeltaGamma(), K = 2)
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
link is `LogLink()`. For `StudentTFamily` it is `IdentityLink()` (the response is
a location on the real line). For `Beta` the default is `LogitLink()`. `Ordinal` defaults
to a cumulative `LogitLink()` and also supports `ProbitLink()`. Beta-binomial
supports `LogitLink()` (default), `ProbitLink()`, and `CLogLogLink()`.

## Supported families

| Family | Status | Link | Marginal | Extra parameter | Notes |
|--------|--------|------|----------|-----------------|-------|
| `Normal()` | ✅ available | identity | closed form | — | continuous; the original engine |
| `Binomial()` | ✅ available | logit / probit / cloglog | Laplace | — | binary (Bernoulli) and binomial counts |
| `Poisson()` | ✅ available | log | Laplace | — | counts |
| `NegativeBinomial()` | ✅ available | log | Laplace | dispersion `r` (Var = μ + μ²/r) | overdispersed counts; `r` jointly estimated |
| `NB1()` | ✅ available | log | Laplace | dispersion `φ` (Var = μ(1+φ)) | linear-variance (quasi-Poisson-like) overdispersed counts; `fit_gllvm` default is per-species `φ`; shared `φ` via `fit_nb1_gllvm` |
| `Beta()` | ✅ available | logit | Laplace | precision `φ` (Var = μ(1−μ)/(1+φ)) | proportions in (0,1); `φ` jointly estimated |
| `Ordinal()` | ✅ available | cumulative logit / probit | Laplace | cutpoints `τ` | ordered categories `1:C`; `fit_ordinal_gllvm()` uses shared cutpoints, `fit_ordinal_gllvm_pertrait()` uses trait-specific cutpoints for R-bridge parity |
| `Gamma()` | ✅ available | log | Laplace | shape `α` (Var = μ²/α) | positive continuous; `α` jointly estimated |
| `Exponential()` | ✅ available | log | Laplace | — | positive continuous, `Var = μ²` (Gamma with α=1) |
| `StudentTFamily(ν)` | ✅ available | identity | Laplace | scale `σ`; FIXED df `ν` on the marker | heavy-tailed continuous, `(y − η)/σ ~ t_ν`; outlier-robust alternative to `Normal()`; `σ` estimated, `ν` held fixed; → `Normal(η, σ²)` as `ν → ∞` |
| Tweedie | ✅ available | log | Laplace | dispersion `φ`, power `p` (1<p<2) | compound Poisson–Gamma; biomass / abundance with true zeros; `fit_tweedie_gllvm` |
| Ordered-beta | ✅ available | logit | Laplace | precision `φ`, cutpoints `c₀<c₁` | proportions / cover with point masses at 0 and 1; `fit_ordered_beta_gllvm` |
| `DeltaLogNormal()` | ✅ available | logit × identity(log) | two-part Laplace | log-SD `σ` (tag payload) | occurrence × positive lognormal; `fit_gllvm` / named `fit_delta_lognormal_gllvm` |
| `DeltaGamma()` | ✅ available | logit × log | two-part Laplace | shape `α` (tag payload) | occurrence × positive Gamma; `fit_gllvm` / named `fit_delta_gamma_gllvm` |
| Beta-hurdle | ✅ available | logit × logit | two-part Laplace | precision `φ` | occurrence × positive Beta; `fit_beta_hurdle_gllvm` |
| Hurdle-Poisson | ✅ available | logit × log | two-part Laplace | — | occurrence × zero-truncated Poisson; `fit_hurdle_poisson_gllvm` |
| Hurdle-NB | ✅ available | logit × log | two-part Laplace | dispersion `r` | occurrence × zero-truncated NB2; `fit_hurdle_nb_gllvm` |
| ZIP | ✅ available | logit × log | two-part Laplace | — | zero-inflated Poisson; `fit_zip_gllvm` / shared site-X via `fit_zip_gllvm_cov` (separate `γz`/`γc`, `Λz=0`; Julia-forward) |
| ZINB | ✅ available | logit × log | two-part Laplace | shared scalar `r` | zero-inflated NB2; `fit_zinb_gllvm` / shared site-X via `fit_zinb_gllvm_cov` (separate `γz`/`γc`, `Λz=0`, shared `r`; Julia-forward) |
| ZIB | ✅ available | logit × logit | two-part Laplace | — | zero-inflated Binomial; `fit_zib_gllvm` |
| `BetaBinom()` | ✅ available | logit / probit / cloglog | Laplace | precision `φ` (`a = μφ, b = (1−μ)φ`) | overdispersed binomial counts; `fit_gllvm` default is per-species `φ` and requires the p×n `N`; shared `φ` via `fit_beta_binomial_gllvm`; → Binomial as `φ → ∞` |

The single-block families with a plain `Distributions` marker — `Normal`,
`Binomial`, `Poisson`, `NegativeBinomial` (NB2), `Beta`, `Ordinal`, `Gamma`,
`Exponential` — are reached through the unified `fit_gllvm` entry, as are `NB1`,
`BetaBinom`, `StudentTFamily`, `DeltaLogNormal`, and `DeltaGamma` via the package's
own exported markers. Tweedie and the remaining two-part / hurdle families currently
have dedicated
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
fit = fit_gllvm(Yc; family = NegativeBinomial(), K = 2)   # per-species r (default)
```

For overdispersed counts. The NB2 variance function is Var = μ + μ²/r. The
public `fit_gllvm` default estimates **per-species** dispersion (returns
`NBGroupedFit`; `fit.r_group`), matching gllvmTMB's length-`p` `log_phi_nbinom2`.
With shared site covariates (`@formula` / bridge `X`), the default is
[`fit_nb_gllvm_grouped_cov`](@ref) (per-trait `r` + shared `γ`). As `r → ∞` the
negative binomial collapses to Poisson. For a single shared `r` across species,
call [`fit_nb_gllvm`](@ref) (no-X) or [`fit_gllvm_cov`](@ref) (with X).

### Negative binomial type-1 — `NB1()`

```julia
fit = fit_gllvm(Yc; family = NB1(), K = 2)   # per-species φ (default)
```

The NB1 variance function is linear in the mean, Var = μ(1+φ) — quasi-Poisson-like
overdispersion, the alternative to NB2's quadratic tail. `NB1` is GLLVM.jl's own
exported marker (there is no `Distributions` counterpart) and matches R gllvm's
`negative.binomial1` with the same `φ`. The public `fit_gllvm` default estimates
**per-species** dispersion (returns `NB1GroupedFit`; vector `fit.φ`), matching
gllvmTMB's length-`p` `log_phi_nbinom1` and the estimand already used with shared
site covariates ([`fit_nb1_gllvm_grouped_cov`](@ref)). For a single shared `φ`,
call [`fit_nb1_gllvm`](@ref).

The marker's `φ` field is a tag payload: `NB1()` and `NB1(2.5)` give the same fit,
because `φ` is always estimated and never seeded from the marker. Pass `φ_init` to
the named fitters to set a starting value.

### Beta — `Beta()`

```julia
fit = fit_gllvm(Yp; family = Beta(), K = 2)   # per-species φ (default)
```

For proportions strictly inside (0,1) — e.g. cover fractions, frequencies.
The per-observation law is Beta(μφ, (1−μ)φ), so Var = μ(1−μ)/(1+φ). The
public `fit_gllvm` default estimates **per-species** precision (returns
`BetaGroupedFit`; vector `fit.φ`), matching gllvmTMB's length-`p` `log_phi_beta`.
With shared site covariates, the default is [`fit_beta_gllvm_grouped_cov`](@ref)
(per-trait `φ` + shared `γ`). For a single shared precision, call
[`fit_beta_gllvm`](@ref) (no-X) or [`fit_gllvm_cov`](@ref) (with X).

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

For native `gllvmTMB` bridge parity, use `fit_ordinal_gllvm_pertrait()` (no-X)
or `fit_ordinal_gllvm_pertrait_cov()` / `@formula`+X / bridge X (shared site-X):
per-trait cutpoints with τ₁=0 fixed and K−2 free log-spacings, plus shared `γ`
under X (twin API B). The shared-cutpoint `fit_ordinal_gllvm()` route remains a
Julia-side comparator and is **not** the public X default.

The shared-cutpoint route also admits predictor-informed latent-score means:

```julia
fit_xlv = fit_ordinal_gllvm(Yo; K = 1, X_lv = X_lv)
extract_lv_effects(fit_xlv)
confint_lv_effects(fit_xlv, Yo, X_lv; method = :profile,
                   profile_indices = [1])
```

Those intervals target the native Julia `B_lv = Λ * alpha_lv'` product. They do
not promote per-trait ordinal bridge CI parity.

### Gamma — `Gamma()`

For positive-continuous data with Var = μ²/α (constant coefficient of variation),
the no-X public default remains shared-shape [`fit_gamma_gllvm`](@ref) /
`fit_gllvm(...; family = Gamma())`. With shared site covariates, the public /
bridge default is [`fit_gamma_gllvm_grouped_cov`](@ref) (per-trait shape `α` +
shared `γ`; twin API B). Shared-α + X remains the opt-in
[`fit_gllvm_cov`](@ref). Per-species shape without X is available via
[`fit_gamma_gllvm_grouped`](@ref) / `disp_group`.

```julia
fit = fit_gllvm(Yp; family = Gamma(), K = 2)   # Yp > 0; shared α (no-X)
```

### Student-t — `StudentTFamily(ν)`

```julia
fit = fit_gllvm(Y; family = StudentTFamily(4.0), K = 2)   # heavy-tailed continuous
fit = fit_gllvm(Y; family = StudentTFamily(), K = 2)      # same, ν = 4 by default
```

An outlier-robust drop-in for `Normal()` on the identity link: the
per-observation law is the location–scale t, `(y − η)/σ ~ t_ν`. The heavy tail
bounds the influence of extreme cells — the score `(ν+1)r/(νσ² + r²)` *decreases*
in the residual `r`, so a handful of gross outliers barely move `β̂`, where a
Gaussian fit would chase them. As `ν → ∞` the family tends to `Normal(η, σ²)`.

The two marker fields play different roles. The degrees of freedom `ν` is
**structural**: it is held FIXED rather than estimated (estimating it jointly
needs a second auxiliary, which the scalar-auxiliary path does not support), so it
travels on the marker and `fit_gllvm` forwards it to
[`fit_studentt_gllvm`](@ref)'s `nu`. Passing `nu` as a separate keyword alongside
the marker is an error rather than a silent override. The scale `σ` is a **tag
payload** — it is always estimated (returned as `fit.σ`), so `StudentTFamily(4.0)`
and `StudentTFamily(4.0, 9.0)` give the same fit; seed it with `σ_init` on the
named fitter instead.

Student-t is a **no-X** surface: `fit_gllvm` and `gllvm(@formula(y ~ 1), …)` are
admitted, but covariates, `disp_group`, and row effects are not.


### Delta-lognormal — `DeltaLogNormal()`

```julia
fit = fit_gllvm(Y; family = DeltaLogNormal(), K = 2)   # occurrence × positive lognormal
fit = fit_gllvm(Y; family = DeltaLogNormal(9.0), K = 2)  # same — marker σ never read
```

Two-part Laplace: Bernoulli occurrence (`π = logistic(β^z)`, `Λ_z = 0` in v1) times
a positive lognormal with meanlog `η^c = β^c + Λ_c z` and shared sdlog `σ`. The
marker's `σ` is a **tag payload** — always estimated (returned as `fit.σ`). Named
fitter [`fit_delta_lognormal_gllvm`](@ref) remains available.

Delta-lognormal is a **no-X** surface: `fit_gllvm` and `gllvm(@formula(y ~ 1), …)`
are open; covariates, `disp_group`, and `row_eff` are not admitted. No bridge /
R-parity claim.

### Delta-Gamma — `DeltaGamma()`

```julia
fit = fit_gllvm(Y; family = DeltaGamma(), K = 2)   # occurrence × positive Gamma
fit = fit_gllvm(Y; family = DeltaGamma(4.0), K = 2)  # same — marker α never read
```

Two-part Laplace: Bernoulli occurrence times a positive Gamma with log-link mean
`μ = exp(η^c)` and shared shape `α` (`Var = μ²/α`). The marker's `α` is a **tag
payload** — always estimated (returned as `fit.α`). Named fitter
[`fit_delta_gamma_gllvm`](@ref) remains available.

Delta-Gamma is a **no-X** surface: same fence as Delta-lognormal (no +X, no
`disp_group`, no `row_eff`, no bridge / R-parity claim).

### Beta-binomial — `BetaBinom()`

```julia
fit = fit_gllvm(Yb; family = BetaBinom(), K = 2, N = trials)   # per-species φ (default)
```

For binomial counts that are **over-dispersed** relative to `Binomial(N, μ)` — the
per-trial success probability is itself random, `p ~ Beta(a, b)` with `a = μφ`,
`b = (1−μ)φ`. `Y` is a `p × n` matrix of integer successes; `N` the matching trial
counts. The Beta precision `φ` (the shape-sum `a + b`) is jointly estimated and
available as `fit.φ`; as `φ → ∞` the family collapses to `Binomial(N, μ)`. Links:
`LogitLink()` (default), `ProbitLink()`, `CLogLogLink()`.

`BetaBinom` is GLLVM.jl's own exported marker, named to avoid colliding with
`Distributions.BetaBinomial`. The public `fit_gllvm` default estimates
**per-species** `φ` (returns `BetaBinomialGroupedFit`; vector `fit.φ`), matching
gllvmTMB's length-`p` `log_phi_betabinom` and the estimand already used with shared
site covariates ([`fit_beta_binomial_gllvm_grouped_cov`](@ref)). For a single shared
`φ`, call [`fit_beta_binomial_gllvm`](@ref).

Unlike the named fitters, which default `N` to all-ones, **`fit_gllvm` and `gllvm`
require `N`** as a p×n matrix. At `N = 1` the beta-binomial collapses to
`Bernoulli(μ)` and `φ` is unidentifiable, so there is no safe default at a public
entry point; a missing `N` — or a scalar, which is not broadcast — raises a clear
error. As for `NB1`, the marker's `φ` field is a tag payload: `BetaBinom()` and
`BetaBinom(7.5)` give the same fit. Pass `φ_init` to the named fitters to set a
starting value.

### Per-species and grouped dispersion

For `NegativeBinomial`, `Beta`, `NB1`, and `BetaBinom`, the public `fit_gllvm`
default already uses per-species dispersion (`disp_group = :species`). Pass an
integer `disp_group` vector for custom grouping, or call the named shared fitters
(`fit_nb_gllvm` / `fit_beta_gllvm` / `fit_nb1_gllvm` /
`fit_beta_binomial_gllvm`) for one dispersion across all species.

The remaining dispersion families (`Gamma`, Tweedie) still default to a shared
parameter on `fit_gllvm` / their named drivers; use a `_grouped` driver or
`disp_group = :species` to vary by species (gllvm's `disp.group`):

```julia
fit_nb_gllvm_grouped(Yc;  K = 2, group = group)   # NB2 dispersion r per group
fit_nb1_gllvm_grouped(Yc; K = 2)                  # NB1 dispersion φ, default per-species
fit_beta_gllvm_grouped(Yp;    K = 2)              # Beta precision φ per species
fit_beta_binomial_gllvm_grouped(Yb; K = 2, N = trials)  # beta-binomial φ per species
fit_gamma_gllvm_grouped(Yc;   K = 2)              # Gamma shape α per species
fit_tweedie_gllvm_grouped(Yc; K = 2)             # Tweedie dispersion φ per species (shared power p)
```

(`fit_nb_gllvm_grouped` requires an explicit `group`; the other five default to
per-species. The beta-binomial drivers additionally need the trial counts `N`.)

```julia
fit_gllvm(Yc; family = NegativeBinomial(), K = 2)                 # default = per-species
fit_gllvm(Yc; family = NB1(), K = 2)                              # default = per-species
fit_gllvm(Yb; family = BetaBinom(), K = 2, N = trials)            # default = per-species; N required
fit_gllvm(Yp; family = Beta(), K = 2, disp_group = group)         # custom groups
fit_gllvm(Yp; family = Gamma(), K = 2, disp_group = :species)     # Gamma opt-in
```

`disp_group = :species` means one dispersion per species; an integer vector
assigns species to shared dispersion groups. Grouped dispersion is a single
specialised route: it is not combined with `row_eff` or Gaussian `pervar` in the
same call, and unsupported families fail with an `ArgumentError`.

### Gaussian with per-species variance — `fit_gaussian_pervar_gllvm`

```julia
fit = fit_gaussian_pervar_gllvm(Y; K = 2)   # heteroscedastic Gaussian
```

A heteroscedastic Gaussian GLLVM with a **separate residual variance per species**
(gllvm's heteroscedastic default), in contrast to the single shared `σ_eps` of
`fit_gaussian_gllvm`. The per-species intercepts are profiled out analytically
(column means), so only the per-species variances and the loadings are optimised.

## Two-part and mixture families (occurrence/zero × value)

Two-part and mixture families model a response with a point mass at zero (or at
the boundary) plus a distribution over the non-zero, count, or continuous part.
The hurdle, delta, and zero-inflated fits share a single latent `z` that loads on
the value/count part (`Λ_c`); the occurrence / zero-inflation part is a
per-species intercept (`β_z`, i.e. `Λ_z = 0`). Each has a dedicated fitter:

```julia
fit = fit_delta_lognormal_gllvm(Y; K = 2)   # Y ≥ 0; positive part lognormal, log-SD σ
fit = fit_delta_gamma_gllvm(Y;     K = 2)   # Y ≥ 0; positive part Gamma, shape α
fit = fit_beta_hurdle_gllvm(Y;     K = 2)   # proportions; occurrence × positive Beta, precision φ
fit = fit_hurdle_poisson_gllvm(Y;  K = 2)   # counts; occurrence × zero-truncated Poisson
fit = fit_hurdle_nb_gllvm(Y;       K = 2)   # counts; occurrence × zero-truncated NB2, r
fit = fit_zip_gllvm(Y;             K = 2)   # counts; structural zero × Poisson
fit = fit_zip_gllvm_cov(Y; X = X,  K = 2)   # ZIP + shared site-X (separate γz/γc; Λz=0)
fit = fit_zinb_gllvm(Y;            K = 2)   # counts; structural zero × NB2, shared r
fit = fit_zinb_gllvm_cov(Y; X = X, K = 2)   # ZINB + shared site-X (separate γz/γc; Λz=0; shared r)
fit = fit_zib_gllvm(Y;             K = 2, N = N)  # binomial counts; structural zero × Binomial(N, μ)
fit = fit_ordered_beta_gllvm(Y;    K = 2)   # proportions with masses at 0 and 1
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
