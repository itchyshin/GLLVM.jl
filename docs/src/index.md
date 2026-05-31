---
layout: home

hero:
  name: "GLLVM.jl"
  text: "Latent-variable models for multivariate ecology"
  tagline: "Ordination, trait correlation, and phylogenetic signal for multivariate species data — the gllvmTMB engine, rebuilt in Julia, ~340× faster."
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
  - title: "~340× faster than gllvmTMB"
    details: "The same Gaussian GLLVM class, the same estimates and log-likelihoods to machine precision — a closed-form marginal, a PPCA warm-start, and L-BFGS reach convergence in seconds, not minutes."
  - title: "Ordination & shared structure"
    details: "Latent factors give a model-based ordination of sites and responses. Read off the among-response covariance Σ_y, per-response communalities, and cross-trait correlations directly from the fit."
  - title: "Phylogenetic signal, O(p)"
    details: "An exact phylogenetic gradient that scales linearly in the number of species — one evaluation at p = 10,000 in 0.77 ms, where dense phylogenetic GLLVMs cap near p ≈ 500."
  - title: "Rigorous inference"
    details: "Wald, profile-likelihood, and parametric-bootstrap intervals — including derived quantities: Σ_y entries, communality, cross-trait correlation, and phylogenetic signal H²."
---

## Which responses vary together — and how much is shared?

GLLVM.jl fits **multivariate models for data where each site, individual, or
species carries several responses** — multi-species abundance, multi-trait
morphometrics, multi-assay panels — and answers the question behind ordination:
*which responses covary, and how much of that variation is shared across
responses versus response-specific?* It is a from-scratch Julia port of the
Gaussian + phylogenetic part of R's
[`gllvmTMB`](https://itchyshin.github.io/gllvmTMB/), reproducing its estimates
and likelihoods to machine precision while fitting markedly faster.

| Quantity | Julia extractor | Reads as |
|----------|-----------------|----------|
| `Σ_y` — among-response covariance | `sigma_y_site(fit)` | how responses covary overall |
| `ΛΛᵀ` — shared (latent) part | `communality(fit)` | variation shared across responses |
| cross-trait correlation | `correlation(fit)` | which responses move together |
| phylogenetic signal `H²` | `phylo_signal(fit)` | variation explained by shared ancestry |

## Start here

| If you want to… | Go to |
|------------------|-------|
| Fit your first model | [Get started](/quickstart) |
| See the math behind the model | [Model](/model) |
| See the O(p) speed story | [Benchmarks](/benchmarks) |
| Check agreement with R `gllvmTMB` | [Comparison](/comparison) |
| Look up a function | [Reference](/api) |
| See what's planned | [Roadmap](/roadmap) |

!!! note "Status"
    The **Gaussian + phylogenetic engine is production-ready and benchmarked**
    (v0.1.0 → v0.2.0). Non-Gaussian families — **binary first**, then Poisson,
    negative binomial, ordinal, and beta — are in active development; see the
    [Roadmap](/roadmap).

## Install

```julia
using Pkg
Pkg.add(url = "https://github.com/itchyshin/GLLVM.jl")
```

A quick taste — simulate a small multivariate dataset and fit a 2-factor model:

```julia
using GLLVM, Random
Random.seed!(1)
n, p, K = 80, 5, 2                       # sites, responses, latent factors
Λ = 0.7 .* randn(p, K)
Y = Λ * randn(K, n) .+ 0.5 .* randn(p, n)   # p × n responses

fit = fit_gaussian_gllvm(Y; K = K)
communality(fit)                         # shared variance per response
correlation(fit)                         # cross-response correlation matrix
```

Julia 1.10 or later.

## Citation & acknowledgements

If you use GLLVM.jl, please cite the methods it builds on: Hadfield &
Nakagawa (2010, *J. Evol. Biol.*) for the sparse phylogenetic precision;
Tipping & Bishop (1999, *JRSS-B*) for the probabilistic-PCA initialiser; and
Bates et al. (2015, *J. Stat. Soft.*) for the profile-out / sparse mixed-model
machinery. The edge-incidence phylogenetic representation follows Bolker's
`phylog.rmd`.

## Related packages

- [`gllvmTMB`](https://itchyshin.github.io/gllvmTMB/) — the R package GLLVM.jl ports.
- `drmTMB` — sibling R package for distributional regression.
- `DRM.jl` — the Julia counterpart of `drmTMB` (in development).
