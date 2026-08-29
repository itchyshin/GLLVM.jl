# API Reference

This page documents the public API of `GLLVM.jl`, categorized by functional domain.

---

## Model Fitting

### Unified & General Fitters

```@docs
fit_gllvm
gllvm
fit_gllvm_cov
fit_dep_gllvm
fit_mixed_gllvm
fit_gaussian_gllvm
fit_gaussian_pervar_gllvm
fit_gaussian_reml
fit_twolevel_gaussian
fit_gaussian_mi_fiml
fit_gaussian_mi_phylo
fit_gllvm_mi
fit_gllvm_mi_multi
```

### Discrete & Count Response Fitters

```@docs
fit_poisson_gllvm
fit_nb_gllvm
fit_nb1_gllvm
fit_gp1_gllvm
fit_compoisson_gllvm
fit_binomial_gllvm
fit_beta_binomial_gllvm
fit_truncated_poisson_gllvm
fit_censored_poisson_gllvm
fit_truncated_nbinom2_gllvm
fit_truncated_nbinom2_gllvm_pertrait
```

### Continuous, Proportion & Ordinal Fitters

```@docs
fit_beta_gllvm
fit_gamma_gllvm
fit_exponential_gllvm
fit_studentt_gllvm
fit_lognormal_gllvm
fit_tweedie_gllvm
fit_ordinal_gllvm
fit_ordinal_gllvm_pertrait
fit_ordinal_gllvm_pertrait_cov
fit_ordered_beta_gllvm
fit_multinomial_gllvm
```

### Two-Part & Zero-Inflated Fitters

```@docs
fit_delta_lognormal_gllvm
fit_delta_gamma_gllvm
fit_hurdle_poisson_gllvm
fit_hurdle_nb_gllvm
fit_beta_hurdle_gllvm
fit_zip_gllvm
fit_zip_gllvm_cov
fit_zinb_gllvm
fit_zinb_gllvm_cov
fit_zib_gllvm
fit_zib_gllvm_cov
```

### Grouped Dispersion & Covariate-Extended Fitters

```@docs
fit_nb_gllvm_grouped
fit_nb_gllvm_grouped_cov
fit_nb1_gllvm_grouped
fit_nb1_gllvm_grouped_cov
fit_beta_gllvm_grouped
fit_beta_gllvm_grouped_cov
fit_gamma_gllvm_grouped
fit_gamma_gllvm_grouped_cov
fit_tweedie_gllvm_grouped
fit_beta_binomial_gllvm_grouped
fit_beta_binomial_gllvm_grouped_cov
fit_gllvm_speciescov
fit_fourthcorner_gllvm
fit_roweffect_gllvm
fit_row_random_gllvm
fit_constrained_gllvm
fit_concurrent_gllvm
fit_rrr_gllvm
fit_quadratic_gllvm
fit_gaussian_random_slope
fit_poisson_random_slope
```

### Variational Approximation (VA) Fitters

```@docs
fit_poisson_gllvm_va
fit_binomial_gllvm_va
fit_nb_gllvm_va
fit_beta_gllvm_va
fit_gamma_gllvm_va
fit_exponential_gllvm_va
fit_delta_gamma_gllvm_va
```

### Initializers & Solvers

```@docs
ppca_init
em_fa
```

---

## Post-Fit & Ordination

```@docs
getLV
getLoadings
rotation
ordination
ordiplot
ordination_uncertainty
select_lv
cv_gllvm
simulate
predict
residuals
fitted
coef_table
loglikelihood
aic
bic
dof
nobs
stderror
vcov
coeftable
coef
lognormal_response_mean
observed_mask
```

---

## Inference & Confidence Intervals

```@docs
confint
profile_ci
bootstrap_ci
transformed_wald_ci_derived
correlation_wald_ci
communality_wald_ci
icc_wald_ci
phylo_signal_wald_ci
chibar2_pvalue
variance_lrt
profile_ci_variance
confint_spde_latent
confint_speciescov
confint_fourthcorner
confint_rrr
confint_constrained
confint_lv_effects
bridge_fit
bridge_capabilities
```

---

## Covariance & Summary Extractors

```@docs
sigma_y_site
communality
correlation
phylo_signal
link_residual
repeatability
communality_B
communality_W
correlation_B
correlation_W
row_effects
extract_lv_effects
extract_Gamma
coevolution_gamma
```

---

## Structured Covariance Builders

### Spatial & SPDE Models

```@docs
spatial_cov
spde_fem
spde_precision
spde_projector
matern_correlation
spde_mesh_grid
spde_mesh_delaunay
fit_spde_gaussian
fit_spde_latent_gllvm
predict_spatial
```

### Phylogenetic & Coevolution Models

```@docs
relatedness_cov
fit_phylo_gaussian
fit_phylo_glm
fit_coevolution_gaussian
fit_coevolution_blockna
fit_coevolution_glm
make_cross_kernel
augmented_phy
random_balanced_tree
sigma_phy_dense
node_grad
node_dσ_phy_only
node_blups
build_node_perspecies
grad_node_perspecies
FelsensteinContrasts
felsenstein_contrast_matrix
felsenstein_contrasts
contrast_transform
edge_phy
sigma_phy_dense_edge
log_det_Q
solve_Q
Q_times_x
path_membership
simulate_branch_re
branch_blups
branch_re_profile_negll
fit_branch_re
fit_branch_re_dense
clade_edges
find_clade_root
clade_detection
build_AnB_sparse
solve_AnB
blup_phylo_sparse
em_fit_phylo
em_observed_information
em_fit_phylo_squarem
edge_W_diag
Q_perbranch
simulate_relaxed_bm
estep_edge_moments
shrink_logrates
fit_relaxed_clock
spearman
shrinkage_factor
welch_t
rank_sum_z
excess_kurtosis
qq_max_dev
```

### Likelihood & Gradient Kernels

```@docs
poisson_laplace_grad
binomial_laplace_grad
nb_laplace_grad
gamma_laplace_grad
beta_laplace_grad
gaussian_reml_loglik
gaussian_grouped_intercept_loglik
twolevel_marginal_loglik
random_slope_marginal_loglik_laplace
gaussian_pervar_marginal_loglik
compoisson_marginal_loglik_laplace
compoisson_logpdf
compoisson_logz
gaussian_marginal_loglik_sparse_phy
phylo_glm_marginal_loglik
coevolution_glm_marginal_loglik
gaussian_marginal_loglik_contrasts
gaussian_marginal_loglik_edge_phy
mixed_marginal_loglik_laplace
truncated_poisson_marginal_loglik_laplace
truncated_nbinom2_marginal_loglik_laplace
truncated_nbinom2_pertrait_marginal_loglik_laplace
gp1_marginal_loglik_laplace
nb1_marginal_loglik_laplace
nb_grouped_marginal_loglik_laplace
beta_grouped_marginal_loglik_laplace
gamma_grouped_marginal_loglik_laplace
nb1_grouped_marginal_loglik_laplace
tweedie_grouped_marginal_loglik_laplace
studentt_marginal_loglik_laplace
lognormal_marginal_loglik
exponential_marginal_loglik_laplace
tweedie_marginal_loglik_laplace
tweedie_logpdf
tweedie_cdf
delta_lognormal_marginal_loglik_laplace
hurdle_poisson_marginal_loglik_laplace
hurdle_nb_marginal_loglik_laplace
delta_gamma_marginal_loglik_laplace
beta_hurdle_marginal_loglik_laplace
zip_marginal_loglik_laplace
zinb_marginal_loglik_laplace
zib_marginal_loglik_laplace
row_random_marginal_loglik_laplace
constrained_marginal_loglik_laplace
rrr_marginal_loglik
quadratic_marginal_loglik_laplace
ordered_beta_marginal_loglik_laplace
betabinomial_marginal_loglik_laplace
betabinomial_grouped_marginal_loglik_laplace
beta_marginal_loglik_va
delta_gamma_marginal_loglik_va
poisson_marginal_loglik_va
binomial_marginal_loglik_va
nb_marginal_loglik_va
gamma_marginal_loglik_va
exponential_marginal_loglik_va
spde_gaussian_marginal_loglik
spde_latent_marginal_loglik
```

---

## Types & Link Functions

### Link Functions

```@docs
LogitLink
ProbitLink
CLogLogLink
IdentityLink
LogLink
```

### Fit Result Types

```@docs
GllvmFit
GllvmModel
GllvmCovFit
GllvmSpeciesCovFit
PoissonFit
NBFit
NB1Fit
NBGroupedFit
NBGroupedCovFit
NB1GroupedFit
NB1GroupedCovFit
BetaFit
BetaGroupedFit
BetaGroupedCovFit
BetaBinomialFit
BetaBinomialGroupedFit
BetaBinomialGroupedCovFit
GammaFit
GammaGroupedFit
GammaGroupedCovFit
OrdinalFit
OrdinalPerTraitFit
OrdinalPerTraitCovFit
TweedieFit
TweedieGroupedFit
StudentTFit
LognormalFit
MultinomialFit
DeltaLogNormalFit
DeltaGammaFit
HurdlePoissonFit
HurdleNBFit
BetaHurdleFit
OrderedBetaFit
ZIPFit
ZIPCovFit
ZINBFit
ZINBCovFit
ZIBFit
ZIBCovFit
GP1Fit
COMPoissonFit
PhyloGaussianFit
PhyloGLMFit
CoevolutionGLMFit
SPDEGaussianFit
SPDELatentFit
TwoLevelFit
GaussianREMLFit
GaussianRandomSlopeFit
PoissonRandomSlopeFit
GaussianPerVarFit
ConstrainedOrdinationFit
ConcurrentOrdinationFit
RRRFit
QuadraticFit
RowEffectFit
RowRandomFit
MixedFamilyFit
BranchREFit
BranchRECache
RelaxedClockFit
EMPhyloFit
AnBSparseSolver
AugmentedPhy
GllvmCoefTable
LVSelection
CVResult
```

### Family & Distribution Markers

```@docs
StudentTFamily
Lognormal
Multinomial
DeltaLogNormal
DeltaGamma
HurdlePoisson
HurdleNB
BetaHurdle
OrderedBeta
ZIPoisson
ZINegBin
ZIB
BetaBinom
COMPoisson
TruncatedPoisson
CensoredPoisson
TruncatedNegBin2
NB1
```
