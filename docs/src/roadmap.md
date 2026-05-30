# Roadmap

GLLVM.jl is being built as a fast Julia **digital twin of
[`gllvmTMB`](https://itchyshin.github.io/gllvmTMB/)**: the same model syntax,
usable directly in Julia and (in the future) through R, across all response
families. The live, detailed roadmap — with linked issues — is tracked on
GitHub:

➡️ **[GLLVM.jl roadmap (issue #11)](https://github.com/itchyshin/GLLVM.jl/issues/11)**

## Phase → release map

| Release | Theme | Highlights |
|---------|-------|-----------|
| **v0.2.0** | Gaussian complete | O(p) phylogenetic fitter, `predict`/`residuals`/`summary`, this docs site |
| **v0.3.0** | Binary + first tutorials | `Family` abstraction + Binomial (first non-Gaussian), the `gllvm()` `@formula` front-end, gllvmTMB-mirroring tutorials |
| **v1.0** | Full digital twin | all families, full extractor / ordination / diagnostic parity, ~16 tutorials, the R bridge (`engine = "julia"`) |

## What works today

- Gaussian + phylogenetic GLLVM fitting (closed-form marginal).
- An **O(p)** phylogenetic gradient — exact, linear-in-species scaling.
- Wald / profile-likelihood / parametric-bootstrap confidence intervals,
  including derived quantities (Σ_y, communality, phylogenetic signal).

## What's planned

- **Families** beyond Gaussian — binary first, then Poisson, negative
  binomial, ordinal, beta, hurdle / zero-inflated — via a Laplace marginal.
- **Same-as-R model syntax**: `gllvm(@formula(traits(...) ~ … + phylo(...)), data; family = …)`.
- **The R bridge** — run a `gllvmTMB` model through the Julia engine
  (`engine = "julia"`).

This roadmap evolves; issue #11 is always current.
