module GLLVM

using LinearAlgebra, Distributions, Optim, ForwardDiff, Random, SparseArrays, Statistics
using SpecialFunctions: digamma, trigamma

# Core
include("packing.jl")
include("lowrank_cholesky.jl")          # used by likelihood
include("likelihood.jl")
include("ppca_init.jl")                  # used by fit (warm-start)
include("em_fa.jl")                      # alternative EM solver
include("profile.jl")                    # σ_eps profile-out (used by fit)
include("fit.jl")
include("simulate.jl")

# Sparse phylogenetic path (evaluation-only — see docstring for AD limitation)
include("sparse_phy.jl")
include("likelihood_sparse_phy.jl")
include("sparse_phy_grad.jl")            # analytic gradient + SparsePhyState (self-includes takahashi_selinv.jl)
include("node_gradient.jl")              # O(p) node-frame gradient + per-species BLUPs (Phase 1.1)
include("fit_phylo.jl")                  # O(p) single-trait phylogenetic Gaussian fitter (Phase 1.4)

# Response families (Phase 3): Distributions types as markers + link functions
include("families/links.jl")
include("families/laplace.jl")           # generic family-dispatched Laplace marginal core
include("families/binomial.jl")          # Binomial family pieces + fit (Phase 3)
include("families/poisson.jl")           # Poisson family pieces (Phase 3)
include("families/negbin.jl")            # Negative-binomial family pieces (Phase 3)
include("families/beta.jl")              # Beta family pieces (Phase 3)
include("families/fit_gllvm.jl")         # unified fit_gllvm(Y; family) dispatcher

# Post-fit API (ordination, predict, residuals, summary)
include("postfit.jl")

# Confidence intervals
include("confint.jl")                    # Wald
include("confint_profile.jl")            # profile likelihood
include("confint_bootstrap.jl")          # parametric bootstrap
include("confint_derived.jl")            # derived quantities (Σ_y, communality, ...)

# Public API
export fit_gaussian_gllvm, GllvmModel, GllvmFit,
       confint, profile_ci, bootstrap_ci,
       ppca_init, em_fa,
       sigma_y_site, communality, correlation, phylo_signal,
       augmented_phy, gaussian_marginal_loglik_sparse_phy,
       node_grad, node_dσ_phy_only, NodePerSpecies, build_node_perspecies,
       grad_node_perspecies, node_blups,
       fit_phylo_gaussian, PhyloGaussianFit,
       LogitLink, ProbitLink, CLogLogLink, IdentityLink, LogLink,
       fit_binomial_gllvm, BinomialFit, fit_poisson_gllvm, PoissonFit,
       fit_nb_gllvm, NBFit, fit_gllvm,
       getLV, getLoadings, rotation,
       predict, fitted, residuals, aic, bic

end # module GLLVM
