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
|---------|-------|-----------|
| **v0.2.0** | Gaussian complete | closed-form marginal, O(p) phylogenetic fitter, post-fit tools, this docs site |
| **v0.3.0** | Non-Gaussian catch-up | one-part Laplace families, first two-part fitters, analytic-gradient hardening |
| **v0.4.0** | Interface and bridge catch-up | `@formula` front-end, wide/long parity, gllvmTMB-mirroring tutorials, live `gllvmTMB` bridge gates |
| **v1.0** | Full digital twin | extractor / ordination / diagnostic parity, structured non-Gaussian dependence, complete R bridge coverage for supported models |

## What works today

- Gaussian + phylogenetic GLLVM fitting (closed-form Gaussian marginal).
- An **O(p)** phylogenetic gradient — exact, linear-in-species scaling.
- Wald / profile-likelihood / parametric-bootstrap confidence intervals,
  including derived quantities (Sigma_y, communality, phylogenetic signal), where
  the family/structure row has passed its local evidence gate.
- One-part Laplace families through `fit_gllvm`: Binomial, Poisson,
  NegativeBinomial, Beta, Ordinal, and Gamma.
- Wald/profile confidence-interval routes for the one-part Laplace families;
  parity and bridge exposure are still being audited.
- Dedicated two-part fitters for Delta-lognormal, Hurdle-Poisson, and
  Hurdle-NB.
- Minimal Julia-side `bridge_fit` for no-covariate one-part families and selected
  fixed-effect-X / missing-response rows tested by the paired `gllvmTMB` branch.

## What's planned

- **Non-Gaussian inference hardening** — R-parity evidence, derived covariance
  summaries, and bridge exposure beyond the current one-part CI routes.
- **Structured non-Gaussian dependence** — phylogenetic, animal, and spatial
  covariance in the Laplace path.
- **Zero-inflated and additional two-part families** — ZIP/ZINB and Delta-Gamma
  after the current two-part substrate hardens.
- **Same-as-R model syntax**: `gllvm(@formula(traits(...) ~ ... + phylo(...)), data; family = ...)`.
- **The R bridge** — keep the live `gllvmTMB` JuliaCall route as the admission
  oracle, then widen deliberately from the current partial rows: fixed-effect
  `X` for selected one-part families, response masks for selected no-X
  non-Gaussian families, complete balanced mixed-family no-X/no-mask/no-CI point
  fits, and in-sample post-fit methods. Remaining bridge work is X+mask,
  mixed-family X/masks/CIs, ordinal prediction payloads, newdata, richer
  diagnostics, and parity evidence for every promoted row.

This roadmap evolves; issue #11 is always current.
