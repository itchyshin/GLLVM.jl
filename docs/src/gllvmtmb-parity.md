# Capability parity with gllvmTMB

GLLVM.jl is a from-scratch Julia twin of R's `gllvmTMB`, built for fitting speed
at moderate-to-large species counts while reproducing point estimates and
likelihoods to machine precision on the shared Gaussian + phylogenetic path. This
page is the live **catch-up scoreboard** — where GLLVM.jl stands against the
`gllvmTMB` feature set. For *speed* comparisons see
[Comparison](/comparison) and [Benchmarks](/benchmarks).

Legend: ✅ available · 🔨 in progress · ⬜ planned · ⚡ GLLVM.jl advantage.

## Response families

| Family | GLLVM.jl | Notes |
|--------|:---:|-------|
| Gaussian | ✅ | closed-form marginal |
| Binomial (Bernoulli / counts) | ✅ | logit / probit / cloglog |
| Beta-binomial | ✅ | overdispersed binomial; `fit_beta_binomial_gllvm`; `BetaBinomial(N, μφ, (1−μ)φ)`, precision `φ` matches gllvm family 15; `φ→∞ ⇒ Binomial` |
| Poisson | ✅ | log link |
| Negative binomial (NB2) | ✅ | size `r` jointly estimated; `Var = μ + μ²/r`. **gllvm uses dispersion `φ = 1/r`** (`Var = μ + μ²φ`) — see the bridge map below |
| Negative binomial (NB1) | ✅ | linear variance `Var = μ(1+φ)`; matches gllvm `negative.binomial1` (same `φ`) |
| Beta | ✅ | precision `φ` (matches gllvm) |
| Ordinal (cumulative) | ✅ | logit + probit links (`link=ProbitLink()` matches gllvm's default cumulative-probit); `P(y≤c)=F(τ_c−η)` convention verified == gllvm; common ordered cutpoints (species-specific cutpoints still a gap) |
| Gamma | ✅ | shape `α` |
| Delta-lognormal | ✅ | first two-part family; shared 2-block Laplace substrate |
| Delta-Gamma | ✅ | occurrence Bernoulli × positive Gamma (log-link mean) on the substrate |
| Hurdle (Poisson / NB) | ✅ | occurrence Bernoulli × zero-truncated Poisson / NB2 |
| Zero-inflated (ZIP / ZINB / ZIB) | ✅ | structural zero × Poisson / NB2 / Binomial; zero-inflation intercept-only (Λ_z = 0) so the coupled-zero cross-term drops out |
| Ordered-beta | ✅ | proportions / cover with point masses at 0 and 1; `fit_ordered_beta_gllvm` |
| Beta-hurdle | ✅ | occurrence Bernoulli × positive Beta; `fit_beta_hurdle_gllvm` |
| Exponential | ✅ | positive continuous, `Var = μ²` (Gamma with shape α=1) |
| Tweedie | ✅ | compound Poisson–Gamma (1<p<2); `fit_tweedie_gllvm`, Dunn–Smyth density series |

## Model structure

| Capability | GLLVM.jl | Notes |
|-----------|:---:|-------|
| Latent-variable ordination (loadings) | ✅ | any `K`; canonical SVD rotation |
| Fixed-effect covariates (`Xβ`) | ✅ Gaussian · ✅ non-Gaussian (GLM families) | `fit_gllvm_cov(Y; family, X, K)` adds an `Xβ` offset to the Laplace path (Poisson/NB/Binomial/Beta/Gamma); shared coefficients over the `(p,n,q)` design |
| Between / within (multilevel) | ✅ Gaussian | `K_W` + per-trait diagonal |
| Phylogenetic random effect | ✅ ⚡ | fast **O(p)** sparse path, benchmarked to p = 10⁴ |
| Animal model (relatedness / GRM) | ✅ Gaussian | `relatedness_cov`, via the `Σ_phy` input |
| Spatial (Matérn / exponential) | ✅ Gaussian | `spatial_cov`, via the `Σ_phy` input |
| Structured dependence × non-Gaussian | ✅ phylo · 🔨 spatial-latent / animal | phylogenetic GLM landed (`fit_phylo_glm`, augmented-state joint Laplace); SPDE / Matérn spatial latent field (`fit_spde_latent_gllvm`) for the non-Gaussian GLLVM |
| Random slopes `(1 + x \| g)` | 🔨 | formula front-end (c) |
| Per-species / grouped dispersion (`disp.group`) | ✅ all 5 dispersion families | `fit_{nb,beta,gamma,nb1,tweedie}_gllvm_grouped(Y; K, group)` give each species (or group) its own dispersion; reduces exactly to the shared fit at `G=1`. **gllvm's default is per-species** dispersion, so for parity route Julia through a grouped fitter with `group = 1:p` (or set gllvm `disp.formula = ~1` for the shared model) |
| Row effects (fixed **and random**) | ✅ | fixed per-site intercepts (`fit_roweffect_gllvm`) **and** random `ρ_s ~ N(0, σ_row²)` (`fit_row_random_gllvm`, gllvmTMB `row.eff="random"`); `σ_row→0` reduces exactly to no-row-effect |

## Post-fit & inference

| Capability | GLLVM.jl | Notes |
|-----------|:---:|-------|
| `getLV` / `getLoadings` / `rotation` | ✅ | all families |
| `predict` / `fitted` | ✅ | all families (ordinal adds `:prob` / `:class`) |
| `residuals` (Dunn–Smyth + Pearson) | ✅ | all families |
| `simulate` (parametric draw from a fit) | ✅ non-Gaussian | `simulate(fit, n)` / `simulate(fit, X)` for the GLM + covariate fits |
| `aic` / `bic` / `show` | ✅ | all families |
| Σ_y / communality / correlation / phylo signal H² | ✅ Gaussian | report-ready extractors |
| Confidence intervals (Wald / profile / bootstrap) | ✅ all families | Gaussian, the GLM families, the two-part families, and ordinal via `confint(fit, Y; method=…)`; bootstrap is thread-parallel |
| Ordination biplot | ✅ | |

## Interface

| Capability | GLLVM.jl | Notes |
|-----------|:---:|-------|
| Matrix-level fit API | ✅ | `fit_gllvm(Y; family, K, …)` |
| `@formula` front-end | ✅ fixed effects (wide + long) · 🔨 rest | `gllvm(@formula(y ~ 1 + x), Y, data; …)` and `gllvm(@formula(y ~ 1 + x), long; species, site, …)`; random slopes, `traits()`/`phylo()`, categoricals deferred |
| `traits()` / `phylo()` formula terms · random slopes `(1+x\|g)` | 🔨 | custom StatsModels terms + RE substrate (design spec'd) |

## Performance — the differentiator

⚡ ~340× per-fit median speedup over R `gllvmTMB` on the Gaussian + phylogenetic
path (with machine-precision agreement on estimates and likelihoods), and an O(p)
phylogenetic gradient benchmarked to p = 10,000. Poisson, NB2, Binomial, and
Beta use analytic Laplace outer gradients by default on plain no-mask/no-offset
fits, with finite-difference fallback; Gamma and the remaining finite-difference
Laplace paths stay conservative until their analytic gradients clear the runtime
accuracy gate. The sparse-Cholesky / CHOLMOD marginals are not generic-AD-friendly;
the VA estimator adds analytic inner and envelope-theorem outer gradients for
further fit-time gains.

## R bridge: parameterization map

R `gllvmTMB` can call GLLVM.jl as its default Julia fitting path through the
R-side bridge. For results to agree, the bridge must reconcile a few
**convention differences** — the underlying models are the same, but the
parameter scales/structures differ. These are translation rules for the bridge,
not bugs on either side.

| Quantity | gllvm (R) | GLLVM.jl | Bridge rule |
|----------|-----------|----------|-------------|
| NB2 dispersion | `φ` (dispersion), `Var = μ + μ²φ`; larger `φ` ⇒ more overdispersion | `r` (size), `Var = μ + μ²/r` | **`r = 1/φ`** (invert in both directions). Also propagates to ZINB / Hurdle-NB / grouped-NB |
| NB1 dispersion | `φ`, `Var = μ + μφ` | `φ`, `Var = μ(1+φ)` | identity (maps 1:1) |
| Gamma dispersion | `φ` = **shape**, `Var = μ²/φ` | `α` = **shape**, `Var = μ²/α` | relabel `α ↔ φ` (no inversion) |
| Beta precision | `φ`, `Var = μ(1-μ)/(1+φ)` | `φ` (same) | identity |
| Tweedie | power `ν`, `Var = φ·μ^ν`, default start `ν = 1.1` | power `p`, `Var = φ·μ^p`, default start `p_init = 1.5` | identity; set `p_init = 1.1` to reproduce gllvm's optimiser path |
| Gaussian dispersion | per-species SD `φ_j` | single shared `σ` (profiled) | needs a per-species-variance Gaussian fit for exact parity |
| Dispersion **structure** | per-species by default (`disp.formula = NULL`) | shared scalar by default; per-species via the grouped fitters | route Julia through `fit_*_gllvm_grouped(Y; K, group = 1:p)`, **or** set gllvm `disp.formula = ~1` |
| Estimation method | default `method = "VA"` | default Laplace; VA available via `fit_*_gllvm_va` | pin matching methods; VA and LA differ in finite samples |

Engine-side parity is broader than the current R bridge admission surface. The
current `gllvmTMB(..., engine = "julia")` bridge admits complete, balanced,
one-part reduced-rank models for Gaussian, Poisson, Binomial, NB2, Beta, Gamma,
and Ordinal no-X fits. Fixed-effect covariates (`X`) are admitted for complete,
balanced one-part Gaussian, Poisson, Binomial, NB2, Beta, and Gamma fits.
For Gaussian covariate fits the bridge returns `mean_coef`, the full coefficient
vector for the supplied `X` array, so the R side can reconstruct in-sample
fitted values without guessing from the per-trait mean summary.
Response-missing masks, mixed-family bridge metadata, ordinal covariate fits,
structured covariance terms, and user-selectable Julia-side optimizer controls
remain explicit bridge follow-ups, not silently supported cells.

REML is a Gaussian-only bridge/engine claim in this project. HSquared's very fast
AI-REML work is useful design input for exact Gaussian variance-component cells,
but it is not terminology to use for non-Gaussian Laplace GLLVMs. Non-Gaussian
speedups should be described as observed-information, Fisher/natural-gradient,
reverse-mode, or implicit-Laplace-adjoint work, each gated by reference-gradient,
point-estimate, and CI/status evidence.

The engine still carries additional gllvm/gllvmTMB parity rows that are not all
public through the R bridge yet:

- **`ZNIB`** (zero-and-N-inflated binomial) — deferred: the gllvm TMB template's
  `case ZNIB` appears to fall through (missing `break;`) into beta-binomial, so its
  likelihood needs upstream confirmation before building to it.
- **corAR1 / corExp / corCS structured row effects, and `lvCor` correlated latent
  variables** — these are `gllvm` features, **not in gllvmTMB**, so they are out of
  scope for this bridge. (GLLVM.jl does carry more general SPDE/Matérn-spatial and
  phylogenetic substrates, which gllvm/gllvmTMB lack.)
- **Ordinal species-specific cutpoints** — a minor remaining option (GLLVM.jl uses
  common ordered cutpoints).

## Honest gaps

What's **done**: every response family — including Tweedie, ordered-beta,
beta-hurdle, and ZIB; fixed-effect covariates (`Xβ`) and species-specific
coefficients for the non-Gaussian families; the VA estimator; the ordination
trio; the SPDE spatial latent field and the phylogenetic GLM; and confidence
intervals (Wald / profile / parametric bootstrap) for every family.

The remaining gaps are each scoped by an execution-ready spec in
`docs/superpowers/specs/` (design + slice plan + verifiable goals), so they can be
built *with* validation rather than shipped unverified:

- **Structured dependence × non-Gaussian (animal / spatial extensions)** — the
  phylogenetic GLM has landed (`fit_phylo_glm`, an augmented-state joint Laplace),
  and the SPDE / Matérn spatial latent field is wired into the non-Gaussian GLLVM
  (`fit_spde_latent_gllvm`). The remaining work is the general dense-`S_u`
  species random effect `u ~ N(0, σ²Σ)` shared across sites and the scalable
  large-`p` determinant. Spec:
  `2026-05-31-nongaussian-structured-dependence-design.md`.
- **`@formula` front-end** — **v1 landed**: `gllvm(@formula(y ~ 1 + covariates), Y,
  data; family, K)` for continuous fixed effects over wide data routes to the
  engine (StatsModels + Tables added). Still deferred (design spec'd in
  `2026-05-31-formula-frontend-random-slopes-design.md`): long-format data, the
  `traits()`/`phylo()`/`latent()` custom terms, categorical covariates, and the
  headline random slopes `(1 + x | g)` (which need the new RE engine substrate).
- **R bridge (`engine = "julia"`)** — deferred (post-v1.0); depends on the
  `@formula` front-end.
