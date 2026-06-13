# Capability parity with gllvmTMB

GLLVM.jl is a from-scratch Julia twin of R's `gllvmTMB`, built for fitting speed
at moderate-to-large species counts while reproducing point estimates and
likelihoods to machine precision on the shared **single-σ² Gaussian** path. This
page is the live **catch-up scoreboard** — where GLLVM.jl stands against the
`gllvmTMB` feature set. For *speed* comparisons see
[Comparison](comparison.md) and [Benchmarks](benchmarks.md).

Legend: ✅ available · 🔨 in progress · ⬜ planned · ⚡ GLLVM.jl advantage.

## Response families

| Family | GLLVM.jl | Notes |
|:-------|:--------:|:------|
| Gaussian | ✅ | closed-form marginal |
| Binomial (Bernoulli / counts) | ✅ | logit / probit / cloglog |
| Poisson | ✅ | log link |
| Negative binomial | ✅ | dispersion `r` jointly estimated |
| Beta | ✅ | precision `φ` |
| Ordinal (cumulative logit) | ✅ | common ordered cutpoints |
| Gamma | ✅ | shape `α` |
| Delta-lognormal | ✅ | first two-part family; shared 2-block Laplace substrate |
| Delta-Gamma | ⬜ | planned on the two-part substrate |
| Hurdle-Poisson / Hurdle-NB | ✅ | dedicated two-part fitters; `Λz = 0` occurrence block |
| Zero-inflated (ZIP / ZINB) | ⬜ | planned; not wired in this branch |
| Tweedie · Exponential | ⬜ | planned (Exponential ⊂ Gamma) |

## Model structure

| Capability | GLLVM.jl | Notes |
|:-----------|:--------:|:------|
| Latent-variable ordination (loadings) | ✅ | any `K`; canonical SVD rotation |
| Fixed-effect covariates (`Xβ`) | ✅ Gaussian · 🔨 non-Gaussian | adding `Xβ` to the Laplace path is a (c) prerequisite |
| Between / within (multilevel) | ✅ Gaussian | `K_W` + per-trait diagonal |
| Phylogenetic random effect | ✅ ⚡ | fast **O(p)** sparse path, benchmarked to p = 10⁴ |
| Animal model (relatedness / GRM) | ✅ Gaussian | `relatedness_cov`, via the `Σ_phy` input |
| Spatial (Matérn / exponential) | ✅ Gaussian | `spatial_cov`, via the `Σ_phy` input |
| Structured dependence × non-Gaussian | 🔨 | joint-Laplace substrate building (b) |
| Random slopes `(1 + x \| g)` | 🔨 | formula front-end (c) |

## Post-fit & inference

| Capability | GLLVM.jl | Notes |
|:-----------|:--------:|:------|
| `getLV` / `getLoadings` / `rotation` | ✅ | Gaussian and implemented Laplace fit objects |
| `predict` / `fitted` | ✅ | implemented Laplace fit objects; ordinal adds `:prob` / `:class` |
| `residuals` (Dunn–Smyth + Pearson) | ✅ | implemented one-part families; two-part residuals are dedicated |
| `aic` / `bic` / `show` | ✅ | implemented fit objects |
| Σ_y / communality / correlation / phylo signal H² | ✅ Gaussian | report-ready extractors |
| Confidence intervals (Wald / profile / bootstrap) | ✅ Gaussian · ⬜ non-Gaussian | a genuine gap |
| Ordination biplot | ✅ | |

## Interface

| Capability | GLLVM.jl | Notes |
|:-----------|:--------:|:------|
| Matrix-level fit API | ✅ | `fit_gllvm(Y; family, K, …)` |
| `@formula` front-end (wide + long data) | 🔨 | gllvmTMB-parity grammar (c) |
| `traits()` / `phylo()` formula terms | 🔨 | custom StatsModels terms (c) |

## Performance — the differentiator

⚡ ~340× per-fit median speedup over R `gllvmTMB` on the **single-σ² Gaussian**
benchmark grid (machine-precision agreement on estimates and likelihoods on that
grid). The number rides on the closed-form σ²_eps profile; R's per-species
(heteroscedastic) Gaussian default and the phylogenetic path are not yet
benchmarked head-to-head against R. A separate O(p) phylogenetic gradient is
benchmarked to p = 10,000. The non-Gaussian fitters are
moving from finite-difference to analytic / forward-mode AD gradients for further
fit-time gains.

## Honest gaps

- **Confidence intervals for non-Gaussian families** — not yet wired.
- **Structured dependence (phylo / animal / spatial) with non-Gaussian responses** — in design/build.
- **`@formula` interface and random slopes** — in build.
- **Unified `fit_gllvm` dispatch for two-part families** — not wired yet; use the dedicated fitters.
- **Zero-inflated, Tweedie, and exponential families** — planned.
- **R bridge (`engine = "julia"`)** — deferred (post-v1.0).
