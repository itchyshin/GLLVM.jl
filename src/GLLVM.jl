module GLLVM

using LinearAlgebra, Distributions, Optim, ForwardDiff, Random, SparseArrays, Statistics

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
       augmented_phy, gaussian_marginal_loglik_sparse_phy

end # module GLLVM
