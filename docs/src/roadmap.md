# Roadmap

GLLVM.jl is being built as a fast Julia **digital twin of
[`gllvmTMB`](https://itchyshin.github.io/gllvmTMB/)**: the same model syntax,
usable directly in Julia and (in the future) through R, across all response
families. The live, detailed roadmap — with linked issues — is tracked on
GitHub:

➡️ **[GLLVM.jl roadmap (issue #11)](https://github.com/itchyshin/GLLVM.jl/issues/11)**

## Phase → release map

| Release | Theme | Highlights |
|:--------|:------|:----------|
| **v0.2.0** | Gaussian complete | O(p) phylogenetic fitter, post-fit tools, this docs site |
| **v0.3.0** | Non-Gaussian catch-up | one-part Laplace families, first two-part fitters, analytic-gradient hardening |
| **v0.4.0** | Interface catch-up | `@formula` front-end, wide/long parity, gllvmTMB-mirroring tutorials |
| **v1.0** | Full digital twin | extractor / ordination / diagnostic parity, structured non-Gaussian dependence, the R bridge (`engine = "julia"`) |

## What works today

- Gaussian + phylogenetic GLLVM fitting (closed-form marginal).
- An **O(p)** phylogenetic gradient — exact, linear-in-species scaling.
- Wald / profile-likelihood / parametric-bootstrap confidence intervals,
  including derived quantities (Σ_y, communality, phylogenetic signal).
- One-part Laplace families through `fit_gllvm`: Binomial, Poisson,
  NegativeBinomial, Beta, Ordinal, and Gamma.
- Dedicated two-part fitters for Delta-lognormal, Hurdle-Poisson, and
  Hurdle-NB.

## What's planned

- **Non-Gaussian inference** — confidence intervals and derived covariance
  summaries beyond the Gaussian path.
- **Structured non-Gaussian dependence** — phylogenetic, animal, and spatial
  covariance in the Laplace path.
- **Zero-inflated and additional two-part families** — ZIP/ZINB and
  Delta-Gamma after the current two-part substrate hardens.
- **Same-as-R model syntax**: `gllvm(@formula(traits(...) ~ … + phylo(...)), data; family = …)`.
- **The R bridge** — run a `gllvmTMB` model through the Julia engine
  (`engine = "julia"`).

This roadmap evolves; issue #11 is always current.
