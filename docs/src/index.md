---
layout: home

hero:
  name: "GLLVM.jl"
  text: "Fast latent-variable models for multivariate ecology"
  tagline: "A Julia digital twin of gllvmTMB — the same model syntax, Gaussian + phylogenetic, at O(p) scale."
  actions:
    - theme: brand
      text: Get started
      link: /quickstart
    - theme: alt
      text: Reference
      link: /api
    - theme: alt
      text: View on GitHub
      link: https://github.com/itchyshin/GLLVM.jl

features:
  - title: "Familiar syntax"
    details: "Specify models the gllvmTMB way — traits(...) ~ predictors + phylo(...), family = … — so R users are immediately at home (formula front-end in progress)."
  - title: "O(p) phylogenetics"
    details: "An exact phylogenetic gradient that scales linearly in species: one evaluation at p = 10,000 in 0.77 ms, where gllvmTMB caps near p ≈ 500."
  - title: "Closed-form Gaussian marginal"
    details: "Latent factors integrated out exactly — no Laplace approximation — so the likelihood is machine-precise and the gradient is well-conditioned."
  - title: "Rigorous inference"
    details: "Wald, profile-likelihood, and parametric-bootstrap intervals — including derived quantities like Σ_y, communality, and phylogenetic signal."
---

## Which responses vary together — and how much is shared?

GLLVM.jl fits **multivariate models for data where each site, individual, or
species carries several responses**, and answers: *which responses covary, and
how much of that variation is shared across responses versus response-specific?*
It is a from-scratch Julia port of the Gaussian + phylogenetic slice of R's
[`gllvmTMB`](https://itchyshin.github.io/gllvmTMB/) — reproducing its estimates
and likelihoods to machine precision, while fitting markedly faster.

| Quantity | Julia extractor | Reads as |
|----------|-----------------|----------|
| `Σ_y` — among-response covariance | `sigma_y_site(fit)` | how responses covary overall |
| `ΛΛᵀ` — shared (latent) part | `communality(fit)` | variation shared across responses |
| `Ψ` — response-specific part | (residual variances) | variation unique to each response |

## Start here

| If you want to… | Go to |
|------------------|-------|
| Fit your first model | [Get started](/quickstart) |
| See the math behind the model | [Model](/model) |
| See the O(p) speed story | [Benchmarks](/benchmarks) |
| Check agreement with R `gllvmTMB` | [Comparison](/comparison) |
| Look up a function | [Reference](/api) |
| See what's planned | [Roadmap](/roadmap) |

!!! warning "Preview"
    GLLVM.jl is a **v0.1.0 → v0.2.0 preview**. The Gaussian + phylogenetic
    engine is production-ready and benchmarked; non-Gaussian families
    (binary first, then Poisson, ordinal, …) are on the [Roadmap](/roadmap).

## Install

```julia
using Pkg
Pkg.add(url = "https://github.com/itchyshin/GLLVM.jl")
```

A quick smoke test — simulate a small Gaussian dataset and fit:

```julia
using GLLVM, Random
Random.seed!(1)
n, p, K = 80, 5, 2                      # sites, responses, latent dim
Λ = 0.7 .* randn(p, K)
Y = (Λ * randn(K, n) .+ 0.5 .* randn(p, n))'   # n × p responses
fit = fit_gaussian_gllvm(Matrix(Y'); K = K)
communality(fit)                        # shared variance per response
```

Julia 1.10 or later.

## Citation & acknowledgements

If you use GLLVM.jl, please cite the method papers it builds on: Hadfield &
Nakagawa (2010, *J. Evol. Biol.*) for the sparse phylogenetic precision;
Tipping & Bishop (1999, *JRSS-B*) for the probabilistic-PCA initialiser; and
Bates et al. (2015, *J. Stat. Soft.*) for the profile-out / sparse mixed-model
machinery. The edge-incidence phylogenetic representation follows Bolker's
`phylog.rmd`.

## Sister packages

- [`gllvmTMB`](https://itchyshin.github.io/gllvmTMB/) — the R twin GLLVM.jl mirrors.
- `drmTMB` — sibling R package for distributional regression.
- `DRM.jl` — the Julia twin of `drmTMB` (in development).
