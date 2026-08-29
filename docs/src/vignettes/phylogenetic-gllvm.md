# Vignette: Phylogenetic GLLVM & Evolutionary Covariance Partitioning

This vignette demonstrates how to model multivariate trait evolution, estimate
phylogenetic signal ($H^2$), construct transformed-Wald confidence intervals,
and partition evolutionary versus environmental covariance using `GLLVM.jl`.

We cover:
1. Formulating Phylogenetic GLLVMs (PGLLVM) for comparative biological data.
2. Fast $O(p)$ phylogenetic fitting with `fit_phylo_gaussian` and `fit_phylo_glm`.
3. Estimating phylogenetic signal ($H^2$) and bounded Wald CIs via `phylo_signal_wald_ci`.
4. Decomposing phenotypic covariance into phylogenetic (Brownian motion), ecological latent factors, and residual components.

---

!!! warning "Matrix Orientation: $p \times n$ in Julia vs $n \times p$ in R"
    **GLLVM.jl expects species/taxa in rows and traits/replicates/sites in columns ($p \times n$).**

    When importing phylogenetic data from R, ensure that the $p$ tips of the phylogeny match the $p$ rows of the response matrix $Y$.

---

## 1. Evolutionary Motivation & Mathematical Formulation

In evolutionary biology, comparative analyses across species must account for shared evolutionary history: species that recently diverged from a common ancestor tend to resemble one another. 

Standard Phylogenetic Comparative Methods (PCMs) often analyze traits individually (e.g. Pagel's $\lambda$, Blomberg's $K$) or via unconstrained multivariate Brownian motion. However, multivariate traits often share **low-rank functional syndromes** (e.g. pace-of-life, leaf economics spectrum) alongside phylogenetic structure.

### The Phylogenetic GLLVM Decomposition

For $p$ species observed across $n$ individuals, populations, or traits, the Gaussian Phylogenetic GLLVM models the $p \times n$ response matrix $Y$ as:

$$Y = A + \Lambda \eta^\top + E$$

where:
- $A \sim \mathcal{MN}_{p \times n}(0, \sigma_{\text{phy}}^2 C_{\text{phy}}, I_n)$ represents phylogenetic random effects evolving under Brownian motion along the tree covariance $C_{\text{phy}}$.
- $\Lambda \in \mathbb{R}^{p \times K}$ are species loadings on $K$ unobserved latent factors $\eta \sim \mathcal{MN}_{n \times K}(0, I_n, I_K)$, capturing correlated evolutionary/functional modules.
- $E \sim \mathcal{MN}_{p \times n}(0, \sigma_\varepsilon^2 I_p, I_n)$ is idiosyncratic residual variation (measurement error or individual plasticity).

The total across-species covariance matrix decomposes cleanly into three distinct biological sources:

$$\Sigma_{\text{total}} = \underbrace{\sigma_{\text{phy}}^2 C_{\text{phy}}}_{\text{Evolutionary History}} + \underbrace{\Lambda \Lambda^\top}_{\text{Functional Modules}} + \underbrace{\sigma_\varepsilon^2 I_p}_{\text{Residual Noise}}$$

---

## 2. Simulating a Phylogenetic Fixture

`GLLVM.jl` provides built-in utilities for generating tree fixtures using the Hadfield & Nakagawa (2010) augmented-state sparse representation:

```julia
using GLLVM, Random, LinearAlgebra

Random.seed!(20260829)

p = 32          # number of species (tips in phylogeny)
n = 50          # number of observations/sites/replicates per species
K = 2           # number of latent factors
σ_phy_true = 0.8 # phylogenetic standard deviation
σ_eps_true = 0.4 # residual standard deviation

# Generate a balanced phylogenetic tree with p tips
tree = random_balanced_tree(p)
phy = augmented_phy(tree)

# Dense phylogenetic correlation matrix C_phy (p × p)
C_phy = sigma_phy_dense(phy)

# Simulate phylogenetic random effect A (p × n)
L_phy = cholesky(Hermitian(C_phy)).L
A_true = σ_phy_true .* (L_phy * randn(p, n))

# True latent loadings (p × K) and latent scores (K × n)
Λ_true = 0.6 .* randn(p, K)
η_true = randn(K, n)

# Generate response matrix Y (p × n)
Y = A_true + Λ_true * η_true .+ σ_eps_true .* randn(p, n)

println("Simulated phylogenetic response matrix: ", size(Y)) # (32, 50)
```

---

## 3. Fast Phylogenetic Model Fitting

`GLLVM.jl` leverages the sparse precision matrix $Q_{\text{phy}} = C_{\text{phy}}^{-1}$ (Hadfield & Nakagawa 2010), achieving high-performance fitting without inverting large dense matrices:

```julia
# Fit Gaussian Phylogenetic GLLVM
fit_phy = fit_phylo_gaussian(Y, phy; K = K)

println("Estimated σ_phy: ", round(fit_phy.pars.sigma_phy, digits = 4))
println("Estimated σ_eps: ", round(fit_phy.pars.sigma_eps, digits = 4))
println("Marginal log-likelihood: ", round(fit_phy.logLik, digits = 2))
```

For non-Gaussian traits (e.g. binary presence/absence or counts across phylogenies), use `fit_phylo_glm`:

```julia
# Non-Gaussian count example (Poisson phylogenetic GLM)
Y_count = rand.(Distributions.Poisson.(exp.(0.5 .* Y)))
fit_phy_pois = fit_phylo_glm(Y_count, phy; family = Distributions.Poisson(), K = 1)
```

---

## 4. Estimating Phylogenetic Signal ($H^2$)

Phylogenetic signal $H^2$ (phylogenetic heritability) measures the fraction of total variance explained by shared evolutionary history:

$$H^2 = \frac{\sigma_{\text{phy}}^2}{\sigma_{\text{phy}}^2 + \bar{c}^2 + \sigma_\varepsilon^2}$$

where $\bar{c}^2 = \frac{1}{p} \text{tr}(\Lambda \Lambda^\top)$ is the average variance explained by the latent factors.

```julia
# Compute point estimate of phylogenetic signal H²
H2_hat = phylo_signal(fit_phy)
println("Phylogenetic signal H²: ", round(H2_hat, digits = 3))
```

An $H^2$ close to 1 indicates strong phylogenetic conservatism (traits follow Brownian motion along the phylogeny), whereas $H^2 \approx 0$ indicates evolutionary lability or dominance of environmental/adaptive syndromes.

---

## 5. Transformed-Wald Confidence Intervals

Because $H^2$ is bounded on the interval $[0, 1]$, standard symmetric Wald intervals ($\hat{H}^2 \pm 1.96 \cdot \text{SE}$) often produce invalid confidence limits exceeding 1 or dropping below 0.

`GLLVM.jl` solves this by applying a logit-scale Fisher-style transformed Wald interval:

$$\zeta = \text{logit}(H^2) = \log\left(\frac{H^2}{1 - H^2}\right)$$

The Wald CI is constructed on the unconstrained $\zeta$-scale using the delta method and inverted back via the logistic function:

$$\text{CI}_{1-\alpha}(H^2) = \text{logistic}\left(\hat{\zeta} \pm z_{1-\alpha/2} \cdot \text{SE}(\hat{\zeta})\right)$$

This is computed directly via `phylo_signal_wald_ci(fit)`:

```julia
# Compute 95% transformed-Wald CI for H²
ci_H2 = phylo_signal_wald_ci(fit_phy; level = 0.95)

println("95% Transformed-Wald CI for H²: [", 
        round(ci_H2.lower, digits = 3), ", ", 
        round(ci_H2.upper, digits = 3), "]")
```

The transformed CI is guaranteed to lie strictly inside $(0, 1)$ without arbitrary truncation.

---

## 6. Covariance Partitioning: Evolution vs Environment

We can decompose the total among-species covariance surface into its evolutionary and functional components:

```julia
# Extract estimated covariance components
Σ_phy_hat = (fit_phy.pars.sigma_phy^2) .* C_phy
Λ_hat = fit_phy.pars.Lambda
Σ_latent_hat = Λ_hat * Λ_hat'
Σ_eps_hat = (fit_phy.pars.sigma_eps^2) .* I(p)

Σ_total_hat = Σ_phy_hat + Σ_latent_hat + Σ_eps_hat

# Proportion of total variance in each component
total_var = tr(Σ_total_hat)
phy_pct = (tr(Σ_phy_hat) / total_var) * 100
lat_pct = (tr(Σ_latent_hat) / total_var) * 100
eps_pct = (tr(Σ_eps_hat) / total_var) * 100

println("Variance Partitioning:")
println("  Phylogenetic component: ", round(phy_pct, digits = 1), "%")
println("  Latent functional axes: ", round(lat_pct, digits = 1), "%")
println("  Idiosyncratic residual: ", round(eps_pct, digits = 1), "%")
```

---

## 7. Ancestral State Reconstruction via BLUPs

The phylogenetic random effects $A$ double as ancestral state predictions (Best Linear Unbiased Predictors / BLUPs):

```julia
# Extract species-level BLUPs for phylogenetic effects
blups = node_blups(fit_phy)
println("Estimated ancestral/tip BLUPs matrix size: ", size(blups))
```

---

## 8. Summary

- **Fast scaling**: Hadfield & Nakagawa precision enables $O(p)$ likelihood and gradient computations.
- **Unified signal**: `phylo_signal(fit)` and `phylo_signal_wald_ci(fit)` provide rigorous, boundary-respecting inference for $H^2$.
- **Complete decomposition**: Separates historical ancestry ($\sigma_{\text{phy}}^2 C_{\text{phy}}$), functional modules ($\Lambda \Lambda^\top$), and noise ($\sigma_\varepsilon^2 I_p$).

For community count data and ordination biplots, refer to the [Community Abundance Vignette](community-abundance.md).
