# Roadmap

GLLVM.jl is being built as a fast Julia **digital twin of
[`gllvmTMB`](https://itchyshin.github.io/gllvmTMB/)**: the same model syntax,
usable directly in Julia and (in the future) through R, across all response
families. The live, detailed roadmap — with linked issues — is tracked on
GitHub:

➡️ **[GLLVM.jl roadmap (issue #11)](https://github.com/itchyshin/GLLVM.jl/issues/11)**

Current sequencing is R-first. Native `gllvmTMB` functionality and the R user
workflow define the oracle; `GLLVM.jl` mirrors admitted rows, supplies parity
evidence, and accelerates them after point estimates, logLik/objective, CI or
CI-status, docs, tests, and Rose audit agree. REML is Gaussian-only; AI-REML is
future design input for exact Gaussian cells, not non-Gaussian Laplace.

## Phase → release map

| Release | Theme | Highlights |
|:--------|:------|:----------|
| **v0.2.0** | Gaussian complete | O(p) phylogenetic fitter, post-fit tools, this docs site |
| **v0.3.0** | Non-Gaussian catch-up | one-part Laplace families, first two-part fitters, analytic-gradient hardening |
| **v0.4.0** | Interface and bridge catch-up | `@formula` front-end, wide/long parity, gllvmTMB-mirroring tutorials, live `gllvmTMB` bridge gates |
| **v1.0** | Digital-twin milestone | extractor / ordination / diagnostic parity, structured non-Gaussian dependence, expanded R bridge coverage for supported models |

## What works today

- Gaussian + phylogenetic GLLVM fitting (closed-form marginal).
- An **O(p)** phylogenetic gradient — exact, linear-in-species scaling.
- Wald / profile-likelihood / parametric-bootstrap confidence intervals,
  including derived quantities (Σ_y, communality, phylogenetic signal).
- One-part Laplace families through `fit_gllvm`: Binomial, Poisson,
  NegativeBinomial, Beta, Ordinal, and Gamma.
- Wald/profile confidence-interval routes for the one-part Laplace families;
  parity and bridge exposure are still being audited.
- Conditional in-sample response simulation for Gaussian, Poisson, Binomial,
  NegativeBinomial, Beta, and Gamma.
- Dedicated two-part fitters for Delta-lognormal, Hurdle-Poisson, and
  Hurdle-NB.
- Minimal Julia-side `bridge_fit` for no-covariate one-part families.

## What's planned

- **Non-Gaussian inference hardening** — R-parity evidence, derived covariance
  summaries, and bridge exposure beyond the current one-part CI routes.
- **Structured non-Gaussian dependence** — phylogenetic, animal, and spatial
  covariance in the Laplace path.
- **Zero-inflated and additional two-part families** — ZIP/ZINB and
  Delta-Gamma after the current two-part substrate hardens.
- **Same-as-R model syntax**: `gllvm(@formula(traits(...) ~ … + phylo(...)), data; family = …)`.
- **The R bridge** — reconcile the live `gllvmTMB` JuliaCall route with the
  tested minimal Julia `bridge_fit`, then widen deliberately to fixed-effect
  `X`, missingness, mixed families, and post-fit methods.

This roadmap evolves; issue #11 is always current.
