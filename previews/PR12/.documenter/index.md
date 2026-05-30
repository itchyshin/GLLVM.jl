
# GLLVM.jl {#GLLVM.jl}

A Julia implementation of **Generalised Linear Latent Variable Models** for multivariate species-by-site data. GLLVM.jl targets the Gaussian + phylogenetic slice required for the benchmark study against R's `gllvmTMB` package, and is currently a research-stage pilot.

## What is a GLLVM? {#What-is-a-GLLVM?}

A GLLVM decomposes the response of each species at each site into a fixed linear predictor, a low-rank latent gradient shared across species (the _ordination axes_), optional site- and species-level random effects, and an optional phylogenetic component. The latent gradient and random-effect contributions are integrated out analytically under a Gaussian likelihood, giving a marginal model whose covariance structure encodes species-by-species correlation without an explicit species-by-species parameter.

## Why use this package? {#Why-use-this-package?}
- **Closed-form Gaussian marginal.** The latent factors are integrated out exactly — no Laplace approximation — so the marginal log-likelihood is evaluated to machine precision and the gradient is well-conditioned.
  
- **PPCA closed-form warm start.** For models without diagonal random effects or phylogeny the probabilistic-PCA initialiser of Tipping and Bishop (1999) is the exact ML solution, so L-BFGS converges in 0–1 iterations.
  
- **Reverse-mode-ready AD.** `ForwardDiff.jl` powers the current gradient; the engine is structured so a hand-coded analytic gradient or a `ReverseDiff.jl` backend can be slotted in without API change.
  

## Quick install {#Quick-install}

```julia
using Pkg
Pkg.add("GLLVM")
```


The package targets Julia 1.10 and above.

## Status {#Status}

GLLVM.jl is a **pilot** for the benchmark study described in the maintainer's active plan. The API surface in this release covers the Gaussian + multi-tier + phylogenetic path needed to compare against `gllvmTMB`. Non-Gaussian families, SPDE / spatial random fields and the animal model are out of scope for this version.

See the [Model](model.md) page for the math and the [Quick start](quickstart.md) page for an end-to-end fit.
