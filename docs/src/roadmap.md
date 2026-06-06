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
| **v0.1.0** | Gaussian complete | closed-form marginal, O(p) phylogenetic fitter, `predict`/`residuals`/`summary`, this docs site |
| **v0.2.0** | Full GLM family + structure | every GLM and two-part family via Laplace, the VA estimator, the ordination trio, covariates / fourth-corner / row effects, the SPDE spatial field and phylogenetic GLM, non-Gaussian CIs, and the `gllvm()` `@formula` front-end |
| **v1.0** | Full digital twin | full extractor / ordination / diagnostic parity, ~16 tutorials, the R bridge (`engine = "julia"`) |

## What works today

- Gaussian + phylogenetic GLLVM fitting (closed-form Gaussian marginal).
- An **O(p)** phylogenetic gradient — exact, linear-in-species scaling.
- **The full GLM response-family set** via a Laplace marginal: Poisson, negative
  binomial (NB2), Binomial / Bernoulli, Beta, Gamma, Exponential, Ordinal,
  Tweedie — plus the two-part / mixture families (Delta-lognormal, Delta-Gamma,
  Hurdle-Poisson, Hurdle-NB, beta-hurdle, ordered-beta, ZIP, ZINB, ZIB).
- A **variational (VA / ELBO)** estimator alongside Laplace, with VA-based SEs.
- The **ordination trio** — unconstrained, concurrent (`num.lv.c`), and
  constrained / RRR (`num.RR`) — plus species-specific covariates, fourth-corner
  trait–environment interactions, fixed community row effects, and quadratic
  response.
- Structured latent fields: **SPDE / Matérn spatial** (with kriging prediction)
  and phylogenetic — including a **phylogenetic GLM** fit (`fit_phylo_glm`) for
  non-Gaussian families via an augmented-state joint Laplace.
- The **`@formula` front-end** (`gllvm(...)`), offsets, and missing-data (NA)
  masks.
- Wald / profile-likelihood / parametric-bootstrap confidence intervals across
  the Gaussian, GLM, and two-part families (via `confint(fit, Y; method=…)`),
  including derived quantities (Σ_y, communality, phylogenetic signal).

## What's planned

- **Full extractor / ordination / diagnostic parity** with R `gllvm`, and the
  remaining `@formula` terms (`traits()` / `phylo()`, random slopes `(1+x|g)`).
- **The R bridge** — run a `gllvmTMB` model through the Julia engine
  (`engine = "julia"`).

This roadmap evolves; issue #11 is always current.
