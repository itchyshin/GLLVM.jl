# Vignette: Community Abundance & Joint Species Distribution Modeling (JSDM)

```@raw html
<div class="gllvm-route gllvm-route--applied">
  <div>
    <span class="gllvm-route__eyebrow">Applied species-distribution route</span>
    <p>Use the response matrix to connect environmental gradients, residual association, and community-level variation.</p>
  </div>
</div>
```

This vignette demonstrates how to analyze multivariate ecological abundance data
using **Joint Species Distribution Models (JSDMs)** in `GLLVM.jl`.

We cover:
1. Handling overdispersed count data with Poisson and Negative Binomial (NB2) GLLVMs.
2. Incorporating site-level environmental covariates ($X$).
3. Extracting and visualizing latent variable site ordination biplots (`getLV`, `getLoadings`).
4. Estimating residual species correlation networks (`correlation(fit)`) and variance partitioning (`communality(fit)`).

---

!!! warning "Matrix Orientation: $p \times n$ in Julia vs $n \times p$ in R"
    **GLLVM.jl expects species in rows and sites in columns ($p \times n$).**

    If your abundance matrix is in R's $n \times p$ format (sites in rows, species in columns), pass the transpose `Y'` to the fitting functions. Site covariate matrices $X$ have dimension $n \times q$ ($n$ sites, $q$ predictors).

---

## 1. Ecological Motivation & Mathematical Model

In community ecology, multispecies abundance surveys typically exhibit three key characteristics:
1. **Mean-variance relationships & overdispersion**: Abundance counts often have variance exceeding the mean ($\text{Var}(y) > \mu$).
2. **Environmental filtering**: Species respond differentially to measured habitat gradients (e.g., elevation, canopy cover, temperature).
3. **Biotic interactions & unmeasured gradients**: After controlling for environmental covariates, residual correlations between species reflect biotic interactions (competition, facilitation) or shared responses to unmeasured environmental drivers.

The Generalized Linear Latent Variable Model (GLLVM) integrates these components into a unified hierarchical framework:

$$\eta_{ij} = \alpha_i + \beta_i^\top x_j + \lambda_i^\top u_j$$

where:
- $y_{ij}$ is the abundance of species $i \in \{1, \dots, p\}$ at site $j \in \{1, \dots, n\}$.
- $\alpha_i$ is the species-specific baseline intercept.
- $\beta_i \in \mathbb{R}^q$ are species-specific environmental slopes corresponding to site predictors $x_j \in \mathbb{R}^q$.
- $u_j \sim \mathcal{N}(0, I_K)$ are site-specific unobserved latent variable coordinates on $K$ latent axes.
- $\lambda_i \in \mathbb{R}^K$ are species loadings (sensitivities to the latent axes).

For count data:
- **Poisson**: $y_{ij} \sim \text{Poisson}(\mu_{ij})$ with $\log(\mu_{ij}) = \eta_{ij}$ and $\text{Var}(y_{ij}) = \mu_{ij}$.
- **Negative Binomial (NB2)**: $y_{ij} \sim \text{NB2}(\mu_{ij}, \phi_i)$ with $\log(\mu_{ij}) = \eta_{ij}$ and $\text{Var}(y_{ij}) = \mu_{ij} + \phi_i \mu_{ij}^2$.

---

## 2. Simulating a Multispecies Count Dataset

Let us simulate an ecological community of $p = 12$ species sampled across $n = 100$ sites with $q = 2$ environmental predictors (e.g. elevation and moisture) and $K = 2$ latent axes:

```julia
using GLLVM, Random, LinearAlgebra, Distributions

Random.seed!(42)

p = 12   # number of species
n = 100  # number of sites
K = 2    # number of latent ordination axes
q = 2    # number of environmental covariates

# Environmental covariates: elevation (standardized) and moisture (standardized)
X = randn(n, q)

# True species parameters
α_true = randn(p) .* 0.5                  # baseline intercepts
B_true = [0.8 -0.5; -0.6 0.7; 1.2 0.0; 0.0 -0.9;
          0.4  0.5; -0.3 -0.4; 0.9 -0.8; -0.7 0.6;
          0.5  0.2; -0.1 0.8; 0.0 -0.5; 0.6 0.6]  # p × q slopes

# True latent loadings Λ (p × K) and site coordinates u (K × n)
Λ_true = 0.8 .* randn(p, K)
u_true = randn(K, n)

# Overdispersion parameters (dispersion ϕ > 0)
ϕ_true = fill(0.4, p)

# Construct linear predictor matrix (p × n)
η = zeros(p, n)
for i in 1:p, j in 1:n
    η[i, j] = α_true[i] + dot(B_true[i, :], X[j, :]) + dot(Λ_true[i, :], u_true[:, j])
end

# Generate overdispersed Negative Binomial counts
Y = zeros(Int, p, n)
for i in 1:p, j in 1:n
    μ = exp(η[i, j])
    # Parameterize NB2 using Distributions.jl NegativeBinomial(r, prob) where r = 1/ϕ, prob = 1/(1 + ϕ*μ)
    r = 1.0 / ϕ_true[i]
    prob = r / (r + μ)
    Y[i, j] = rand(NegativeBinomial(r, prob))
end

println("Simulated abundance matrix size: ", size(Y))  # (12, 100)
```

---

## 3. Model Fitting & Family Comparison

We fit both a Poisson model and a Negative Binomial model to evaluate the impact of accounting for overdispersion:

```julia
# Fit Poisson GLLVM (K = 2 latent axes with site covariates X)
fit_pois = fit_gllvm(Y; family = Poisson(), X = X, K = 2)

# Fit Negative Binomial (NB2) GLLVM
fit_nb = fit_gllvm(Y; family = NegativeBinomial(), X = X, K = 2)

# Compare model fit using AIC and BIC
println("Poisson AIC: ", round(aic(fit_pois), digits = 2))
println("NB2 AIC:     ", round(aic(fit_nb), digits = 2))
```

Because the simulated data contains quadratic overdispersion, the Negative Binomial model substantially improves the log-likelihood and penalised information criteria (AIC/BIC).

---

## 4. Latent Variable Ordination: Site Scores & Species Loadings

One of the primary applications of GLLVMs in community ecology is **model-based unconstrained ordination**. Unlike algorithmic ordination methods (such as PCA, CA, or NMDS), GLLVM ordination directly accounts for the discrete count distribution, mean-variance relationships, and environmental covariates.

### Extracting Coordinates

```julia
# Extract site ordination coordinates (n × K)
site_scores = getLV(fit_nb)

# Extract species factor loadings (p × K)
species_loadings = getLoadings(fit_nb)

# Inspect canonical rotation matrix
R = rotation(fit_nb)
```

### Interpreting the Biplot

- **Site Scores (`site_scores[j, :]`)**: Position of site $j$ in the residual latent space. Sites close together share similar species compositions beyond what is predicted by the environmental covariates $X$.
- **Species Loadings (`species_loadings[i, :]`)**: Direction and magnitude of species $i$'s sensitivity to the latent axes. Species pointing in the same direction tend to co-occur frequently.

```julia
# Example plotting code using Plots.jl or CairoMakie.jl
# (Plots is an optional visualization package)
using Plots

scatter(site_scores[:, 1], site_scores[:, 2],
    xlabel = "Latent Axis 1",
    ylabel = "Latent Axis 2",
    title = "JSDM Residual Site Ordination",
    label = "Sites",
    alpha = 0.6,
    markersize = 5)

for i in 1:p
    plot!([0, species_loadings[i, 1]], [0, species_loadings[i, 2]],
        arrow = true, color = :red, linewidth = 1.5,
        label = i == 1 ? "Species Loadings" : "")
end
```

---

## 5. Residual Species Correlation Network & Variance Partitioning

### Model-Implied Species Correlation Matrix

After conditioning on the environmental covariates, the residual covariance across species on the link (latent) scale is given by:

$$\Sigma_{\text{residual}} = \Lambda \Lambda^\top$$

The model-implied correlation matrix is computed via `correlation(fit)`:

```julia
# Compute the p × p species correlation matrix
R_species = correlation(fit_nb)

# Check dimensions (p × p)
println("Correlation matrix size: ", size(R_species))
```

Pairs of species with positive correlations ($\rho_{ij} > 0$) frequently co-occur more than expected by chance, whereas negative correlations ($\rho_{ij} < 0$) indicate competitive exclusion or habitat partitioning.

### Variance Partitioning (Communality)

How much of each species' residual variance is explained by the shared latent variables versus idiosyncratic noise? `communality(fit)` computes the proportion of shared variance:

$$c_i^2 = \frac{\sum_{k=1}^K \lambda_{ik}^2}{\sum_{k=1}^K \lambda_{ik}^2 + \sigma_{\varepsilon, i}^2}$$

```julia
# Extract communality for each species
comm = communality(fit_nb)

for i in 1:p
    println("Species $i$ shared-variance fraction (communality): ", round(comm[i], digits = 3))
end
```

High communality ($c_i^2 \approx 1$) indicates that species $i$ strongly responds to the community-wide latent gradients.

---

## 6. Inference on Environmental Covariates

To examine which environmental gradients significantly structure each species' abundance, extract the environmental coefficient matrix and their standard errors:

```julia
# Extract estimated regression slopes B (p × q)
B_est = fit_nb.pars.beta

# Compute Wald confidence intervals
ci_table = confint(fit_nb; method = :wald)
println("Fitted parameter table with 95% Wald CIs:")
```

You can also use the tidy summary table:

```julia
table = coef_table(fit_nb)
println(table)
```

---

## 7. Key Takeaways

1. **Matrix convention**: Always format input data as $p \times n$ ($p$ species in rows, $n$ sites in columns).
2. **Account for overdispersion**: Use `NegativeBinomial()` or `NB1()` when count variance exceeds the mean to avoid anti-conservative inference.
3. **Model-based ordination**: Extract site scores via `getLV(fit)` and species loadings via `getLoadings(fit)`.
4. **Residual associations**: Use `correlation(fit)` to infer unmeasured biotic networks and `communality(fit)` for variance decomposition.

For continuous traits and evolutionary questions across phylogenies, proceed to the [Phylogenetic GLLVM Vignette](phylogenetic-gllvm.md).
