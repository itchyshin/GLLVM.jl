# Capability parity with gllvmTMB

GLLVM.jl is a from-scratch Julia twin of R's `gllvmTMB`, built for fitting speed
at moderate-to-large species counts while reproducing point estimates and
likelihoods to machine precision on the shared Gaussian + phylogenetic path. This
page is the live **catch-up scoreboard** — where GLLVM.jl stands against the
`gllvmTMB` feature set. For *speed* comparisons see
[Comparison](comparison.md) and [Benchmarks](benchmarks.md).

Legend: ✅ available · 🔨 in progress · ⬜ planned · ⚡ GLLVM.jl advantage.

## Response families

| Family | GLLVM.jl | Notes |
|--------|:---:|-------|
| Gaussian | ✅ | closed-form marginal |
| Binomial (Bernoulli / counts) | ✅ | logit / probit / cloglog |
| Poisson | ✅ | log link |
| Negative binomial | ✅ | dispersion `r` jointly estimated |
| Beta | ✅ | precision `φ` |
| Ordinal (cumulative logit) | ✅ | common ordered cutpoints |
| Gamma | ✅ | shape `α` |
| Delta-lognormal | ✅ | first two-part family; shared 2-block Laplace substrate |
| Delta-Gamma | ✅ | occurrence Bernoulli × positive Gamma (log-link mean) on the substrate |
| Hurdle (Poisson / NB) | ✅ | occurrence Bernoulli × zero-truncated Poisson / NB2 |
| Zero-inflated (ZIP / ZINB) | ✅ | structural zero × Poisson / NB2; zero-inflation intercept-only (Λ_z = 0) so the coupled-zero cross-term drops out |
| Exponential | ✅ | positive continuous, `Var = μ²` (Gamma with shape α=1) |
| Tweedie | ⬜ | planned (compound Poisson–Gamma) |

## Model structure

| Capability | GLLVM.jl | Notes |
|-----------|:---:|-------|
| Latent-variable ordination (loadings) | ✅ | any `K`; canonical SVD rotation |
| Fixed-effect covariates (`Xβ`) | ✅ Gaussian · ✅ non-Gaussian (GLM families) | `fit_gllvm_cov(Y; family, X, K)` adds an `Xβ` offset to the Laplace path (Poisson/NB/Binomial/Beta/Gamma); shared coefficients over the `(p,n,q)` design |
| Between / within (multilevel) | ✅ Gaussian | `K_W` + per-trait diagonal |
| Phylogenetic random effect | ✅ ⚡ | fast **O(p)** sparse path, benchmarked to p = 10⁴ |
| Animal model (relatedness / GRM) | ✅ Gaussian | `relatedness_cov`, via the `Σ_phy` input |
| Spatial (Matérn / exponential) | ✅ Gaussian | `spatial_cov`, via the `Σ_phy` input |
| Structured dependence × non-Gaussian | 🔨 | joint-Laplace substrate building (b) |
| Random slopes `(1 + x \| g)` | 🔨 | formula front-end (c) |

## Post-fit & inference

| Capability | GLLVM.jl | Notes |
|-----------|:---:|-------|
| `getLV` / `getLoadings` / `rotation` | ✅ | all families |
| `predict` / `fitted` | ✅ | all families (ordinal adds `:prob` / `:class`) |
| `residuals` (Dunn–Smyth + Pearson) | ✅ | all families |
| `aic` / `bic` / `show` | ✅ | all families |
| Σ_y / communality / correlation / phylo signal H² | ✅ Gaussian | report-ready extractors |
| Confidence intervals (Wald / profile / bootstrap) | ✅ all families | Gaussian, the GLM families, the two-part families, and ordinal via `confint(fit, Y; method=…)`; bootstrap is thread-parallel |
| Ordination biplot | ✅ | |

## Interface

| Capability | GLLVM.jl | Notes |
|-----------|:---:|-------|
| Matrix-level fit API | ✅ | `fit_gllvm(Y; family, K, …)` |
| `@formula` front-end (wide + long data) | 🔨 | gllvmTMB-parity grammar (c) |
| `traits()` / `phylo()` formula terms | 🔨 | custom StatsModels terms (c) |

## Performance — the differentiator

⚡ ~340× per-fit median speedup over R `gllvmTMB` on the Gaussian + phylogenetic
path (with machine-precision agreement on estimates and likelihoods), and an O(p)
phylogenetic gradient benchmarked to p = 10,000. The non-Gaussian fitters are
moving from finite-difference to analytic / forward-mode AD gradients for further
fit-time gains.

## Honest gaps

- **Confidence intervals** — Wald / profile / parametric bootstrap are wired for
  every family (Gaussian, the GLM families, the two-part families, and ordinal).
- **Structured dependence (phylo / animal / spatial) with non-Gaussian responses** — in design/build (b).
- **`@formula` interface and random slopes** — in build (c).
- **Tweedie / exponential families** — planned.
- **R bridge (`engine = "julia"`)** — deferred (post-v1.0).
