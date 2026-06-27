# Model

The Gaussian GLLVM that this package implements decomposes the response
of species `s` (a length-`p` vector across the `p` species at site `s`)
into a fixed linear predictor plus a sequence of latent contributions:

```math
y_s \;=\; X_s\,\beta \;+\; \Lambda_B\,\eta_B[s] \;+\; \Lambda_W\,\eta_W[:, s] \;+\; s_B[:, s] \;+\; s_W[:, s] \;+\; s_{\text{phy}} \;+\; \varepsilon[:, s].
```

Each term is independent across sites (except where the phylogenetic
covariance ties species together) and Gaussian. The latent factors and
random effects are integrated out *analytically*, producing a closed-form
marginal log-likelihood whose optimisation is the engine's main loop.

## Terms

**Fixed effects** `X_s β` — the standard linear predictor for trait or
intercept effects per species. `X_s` is the per-site design matrix
constructed by the caller (or by the R-side fixture generator); `β` is
estimated by ML jointly with the variance components.

**Latent factor block** `Λ_B η_B[s]` — the rank-`K` ordination axes
shared across species. `Λ_B` is a `p × K` loading matrix and
`η_B[s] ∼ N(0, I_K)` is the latent gradient at site `s`. Marginal
contribution to `Σ_y_site`: `Λ_B Λ_B'`.

**Predictor-informed latent-score mean** `Λ_B (X_lv[s] α_lv)` — a C1
ordinary unit-tier extension matching the current R `gllvmTMB` Design 73
surface for Gaussian, Poisson (log link), shared-dispersion NB2, shared-shape
Gamma, and complete-response binomial logit/probit/cloglog point fits. With
`fit_gaussian_gllvm(...; X_lv = X_lv)`, `fit_poisson_gllvm(...; X_lv = X_lv)`,
`fit_nb_gllvm(...; X_lv = X_lv)`, `fit_gamma_gllvm(...; X_lv = X_lv)`, or
`fit_binomial_gllvm(...; X_lv = X_lv)`, the site score is decomposed as
`η_B[s] = X_lv[s] α_lv + z_s`, where `z_s ∼ N(0, I_K)`.
The raw `α_lv` coefficients depend on the latent-axis orientation; the
rotation-stable trait-effect matrix is `B_lv = Λ_B α_lv'`, returned by
`extract_lv_effects(fit)`. This path is point-estimate only: confidence
intervals, response masks, fixed-effect `X` plus `X_lv`, other non-Gaussian
families, W-tier, and phylogenetic/source-specific extensions remain separate
validation gates.

**Unit-obs latent factor block** `Λ_W η_W[:, s]` — the per-site version
of the latent block, used when the model has a `latent(0 + trait |
site_species)` term. Loading matrix shape and packing are identical to
`Λ_B`; the marginal contribution to `Σ_y_site` is also `Λ_W Λ_W'`.

**Site-tier diagonal random effects** `s_B[:, s] ∼ N(0, diag(σ²_B))` —
per-species independent random effects at the site tier. The marginal
contribution to `Σ_y_site` is `diag(σ²_B)`.

**Unit-obs diagonal random effects** `s_W[:, s] ∼ N(0, diag(σ²_W))` —
the per-site version, contributing `diag(σ²_W)` to `Σ_y_site`.

**Phylogenetic component** `s_phy ∼ N(0, σ²_phy · Σ_phy)` — species are
tied by a user-supplied species-by-species covariance `Σ_phy`. The
marginal contribution at a single site is `σ²_phy · Σ_phy`. Across the
full data the structure becomes block-diagonal in site and dense across
species via `Σ_phy`.

**Observation noise** `ε[:, s] ∼ N(0, σ²_eps I_p)` — the iid residual
term.

## Closed-form Gaussian marginal

Integrating out `η_B`, `η_W`, `s_B`, `s_W` and (where present) the
phylogenetic random effect yields a Gaussian marginal in `y_s` with
mean `X_s β` and covariance

```math
y_s \sim \mathcal{N}\!\left(X_s\,\beta,\; \Lambda_B\,\Lambda_B^\top + \mathrm{diag}(d_{\text{total}})\right),
```

where `d_total = σ²_B + σ²_W + σ²_eps` collects every diagonal
contribution at a single site, plus the latent-W contribution which
behaves like an additional rank-`K` block at the unit-obs tier. The full
data log-likelihood is the sum of these per-site Gaussians, plus the
phylogenetic correction below.

The negative log-marginal-likelihood is evaluated via Woodbury so the
expensive `p × p` operations are reduced to `K × K` inversions plus a
`p`-vector solve, which is the same trick `MixedModels.jl` uses for
random-effect blocks.

## Rotation trick for phylogenetic terms

For models with `phylo_unique()` the full data covariance over the
`n × p` long-form response is

```math
\Sigma_{y,\text{full}} \;=\; I_n \otimes A \;+\; J_n \otimes B,
```

where `A` is the iid-across-sites covariance (latent + diagonal RE +
ε), `B` is the phylogenetic contribution `σ²_phy · Σ_phy`, and `J_n` is
the `n × n` all-ones matrix. Diagonalising in the site-dimension (which
amounts to rotating into the `1_n / √n` versus orthogonal-complement
basis) decomposes the determinant and quadratic form into the rank-1
component `A + n·B` and the `(n − 1)` copies of `A`, reducing the
phylogenetic likelihood evaluation to *one* `p × p` Cholesky plus
`(n − 1)` reuses of the iid Cholesky. The engine does this once per
gradient evaluation; the marginal log-likelihood remains closed-form.

## Identifiability

The loading matrix `Λ_B` is identified only up to an orthogonal rotation
in `K`-space — the marginal covariance `Λ_B Λ_B'` is invariant under
`Λ_B → Λ_B Q` for any orthogonal `Q`. The engine uses the standard
lower-triangular packing (matching the R-side `gllvmTMB::rr_theta_len(p,
K)`) as the identifying constraint at the optimum. The latent scores
`η_B[s]` are not estimated; they are integrated out.

The phylogenetic variance `σ²_phy` is identified separately from
`σ²_eps` only when the phylogenetic correlation structure differs
materially from the identity; very flat trees collapse the
identifiability and the engine will report a wide profile CI on
`σ²_phy` in those cases.
