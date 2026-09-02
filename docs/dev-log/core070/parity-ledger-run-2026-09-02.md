# Parity ledger: gllvmTMB <-> GLLVM.jl export reconciliation (2026-09-02)

`tools/parity_ledger.py` ports DRM.jl's `tools/parity_ledger.py`
(`~/Dropbox/Github Local/DRM.jl/tools/parity_ledger.py`) to the
gllvmTMB<->GLLVM.jl pair. It reads gllvmTMB's `NAMESPACE` at a named git ref
via `git show <ref>:NAMESPACE` (never the working tree, which can sit
hundreds of commits behind) and GLLVM.jl's `export` block in `src/GLLVM.jl`,
then reports **both directions**: FORWARD (R exports with no Julia twin --
genuinely owed) and REVERSE (Julia exports with no R twin -- genuinely
ahead), each split into "accounted for in writing" versus "genuinely
owed/ahead" so the countdown does not overstate the gap. Value-add over the
DRM.jl original: every FORWARD name is cross-checked against
`docs/dev-log/core070/required-source-case-map.json`'s
`namespace/export/<name>` rows, showing that row's `disposition` or
`UNTRACKED` when no ledger row exists yet.

**Maintainer decision (2026-09-02)**: the public *qualification claim* is
one-directional, R -> Julia (does GLLVM.jl cover what gllvmTMB promises).
Capabilities are nonetheless **tracked in both directions** -- REVERSE
exists so a Julia-only capability (e.g. SPDE/Matern spatial, or the
phylogenetic engine -- neither has a gllvmTMB analogue) is a written
decision, not unnoticed drift, without folding REVERSE growth into the
R-parity countdown itself.

## Run 1 -- frozen 0.7.0 oracle (the qualification baseline)

```
$ python3 tools/parity_ledger.py --ref b4d5fee64def88bc768dda1f1f77c29b295edd86
gllvmTMB 0.7.0 @ b4d5fee64def88bc768dda1f1f77c29b295edd86 (b4d5fee64)
  R exports: 160   GLLVM.jl exports: 434

FORWARD -- RENAMED AWAY (0) -- the R name is deliberately NOT the Julia name (api-rename-notes.md)

FORWARD -- NOT CAPABILITY (4) -- R-idiom helper, no engine analogue
  gllvmTMBcontrol          R control-object constructor (fit-option bag); Julia takes options as keyword args, no matching constructor export
  gr                       R gradient/generic helper; not a distinct Julia-facing capability
  meta_known_V             meta-analysis known-V helper; not a GLLVM engine capability (DRM.jl carries the identical exclusion for its own meta_known_V)
  screen_control           R control-object constructor for screen_gllvmTMB(); same shape as gllvmTMBcontrol, no Julia analogue

FORWARD -- ACCOUNTED FOR IN WRITING (6) -- not owed, and why
  add_utm_columns          R-side coordinate-projection convenience for geospatial prep; no fitting-engine analogue
  categorical              an imputation family (categorical missingness), not a response family; same missing-data surface as impute_model
  get_crs                  R-side CRS/projection accessor for geospatial prep; no fitting-engine analogue
  impute_model             missing-data imputation-model surface; structurally separate from GLLVM.jl's Laplace/VA family fitters
  make_mesh                R-side geospatial mesh prep (sf, CRS) before any fit; SPDE fitters take a mesh/precision Julia already has, not this constructor
  miss_control             missing-data control-object constructor; same missing-data surface as impute_model

FORWARD -- gllvmTMB EXPORTS WITH NO GLLVM.jl TWIN (77) -- genuinely owed
  .proportions_bootstrap_ci    no disposition (classification=required_core)
  .proportions_wald_ci         no disposition (classification=required_core)
  Beta                         no disposition (classification=required_core)
  VP                           no disposition (classification=intentionally_excluded)
  animal_dep                   no disposition (classification=required_core)
  animal_indep                 no disposition (classification=required_core)
  animal_latent                no disposition (classification=required_core)
  animal_scalar                no disposition (classification=required_core)
  animal_slope                 no disposition (classification=required_core)
  animal_unique                BLOCKED_NEEDS_JULIA_SURFACE
  block_V                      no disposition (classification=intentionally_excluded)
  confirmatory_lambda          BLOCKED_NEEDS_JULIA_SURFACE
  delta_beta                   no disposition (classification=intentionally_excluded)
  delta_gamma_mix              no disposition (classification=intentionally_excluded)
  delta_gengamma               no disposition (classification=intentionally_excluded)
  delta_lognormal_mix          no disposition (classification=intentionally_excluded)
  delta_poisson_link_gamma     no disposition (classification=intentionally_excluded)
  delta_poisson_link_lognormal no disposition (classification=intentionally_excluded)
  delta_truncated_nbinom1      no disposition (classification=intentionally_excluded)
  delta_truncated_nbinom2      no disposition (classification=intentionally_excluded)
  dep                          no disposition (classification=required_core)
  extract_Sigma_B              no disposition (classification=required_core)
  extract_Sigma_W              no disposition (classification=required_core)
  extract_residual_split       no disposition (classification=required_core)
  flag_unreliable_loadings     no disposition (classification=required_core)
  gamma_mix                    no disposition (classification=intentionally_excluded)
  gengamma                     no disposition (classification=intentionally_excluded)
  gllvmTMB_wide                no disposition (classification=required_core)
  gllvm_julia_setup            no disposition (classification=required_core)
  indep                        PARTIAL_PENDING_DECISION_OPEN_QUESTION
  isdm_source                  BLOCKED_NEEDS_JULIA_SURFACE
  isdm_sources                 BLOCKED_NEEDS_JULIA_SURFACE
  kernel_dep                   no disposition (classification=required_core)
  kernel_indep                 no disposition (classification=required_core)
  kernel_latent                no disposition (classification=required_core)
  kernel_scalar                no disposition (classification=required_core)
  kernel_unique                no disposition (classification=required_core)
  latent                       BLOCKED_NEEDS_JULIA_SURFACE
  lognormal_mix                no disposition (classification=intentionally_excluded)
  meta                         BLOCKED_NEEDS_JULIA_SURFACE
  meta_V                       BLOCKED_NEEDS_JULIA_SURFACE
  nbinom2_mix                  no disposition (classification=intentionally_excluded)
  pedigree_to_A                BLOCKED_NEEDS_JULIA_SURFACE
  pedigree_to_Ainv_sparse      BLOCKED_NEEDS_JULIA_SURFACE
  phylo                        BLOCKED_NEEDS_JULIA_SURFACE
  phylo_dep                    BLOCKED_NEEDS_JULIA_SURFACE
  phylo_indep                  BLOCKED_NEEDS_JULIA_SURFACE
  phylo_latent                 BLOCKED_NEEDS_JULIA_SURFACE
  phylo_rr                     BLOCKED_NEEDS_JULIA_SURFACE
  phylo_scalar                 BLOCKED_NEEDS_JULIA_SURFACE
  phylo_signal_mi              BLOCKED_NEEDS_JULIA_SURFACE
  phylo_slope                  BLOCKED_NEEDS_JULIA_SURFACE
  phylo_unique                 BLOCKED_NEEDS_JULIA_SURFACE
  plot_Sigma_comparison        no disposition (classification=intentionally_excluded)
  plot_Sigma_heatmap           no disposition (classification=intentionally_excluded)
  plot_Sigma_table             no disposition (classification=intentionally_excluded)
  plot_anisotropy              no disposition (classification=intentionally_excluded)
  plot_anisotropy2             no disposition (classification=intentionally_excluded)
  plot_correlations            no disposition (classification=intentionally_excluded)
  plot_loadings_confidence_eye no disposition (classification=intentionally_excluded)
  plot_rotated_loadings        no disposition (classification=intentionally_excluded)
  ridge_path                   no disposition (classification=intentionally_excluded)
  scalar                       PARTIAL_PENDING_DECISION_OPEN_QUESTION
  screen_gllvmTMB              no disposition (classification=intentionally_excluded)
  screen_table                 no disposition (classification=intentionally_excluded)
  simulate_site_trait          BLOCKED_NEEDS_JULIA_SURFACE
  spatial                      BLOCKED_NEEDS_JULIA_SURFACE
  spatial_dep                  BLOCKED_NEEDS_JULIA_SURFACE
  spatial_indep                BLOCKED_NEEDS_JULIA_SURFACE
  spatial_latent               BLOCKED_NEEDS_JULIA_SURFACE
  spatial_scalar               BLOCKED_NEEDS_JULIA_SURFACE
  spatial_unique               BLOCKED_NEEDS_JULIA_SURFACE
  spde                         BLOCKED_NEEDS_JULIA_SURFACE
  suggest_lambda_constraint    BLOCKED_NEEDS_JULIA_SURFACE
  suggest_lambda_constraints   BLOCKED_NEEDS_JULIA_SURFACE
  traits                       BLOCKED_NEEDS_JULIA_SURFACE
  truncated_nbinom1            no disposition (classification=intentionally_excluded)

REVERSE -- AHEAD OF gllvmTMB, ACCOUNTED FOR IN WRITING (279) -- not a gap, and why
  @formula                         StatsModels macro mirroring R's built-in ~ formula literal; base R syntax needs no export
  [... 278 more lines omitted for length; full class breakdown in Closing list 2 below ...]
REVERSE -- GLLVM.jl EXPORTS WITH NO gllvmTMB TWIN (82) -- genuinely ahead, unclassified
  AnBSparseSolver
  [... 81 more lines omitted for length; full list in Closing list 2 below ...]

COUNTDOWN: 77 export gaps genuinely owed (0 UNTRACKED of those) · 0 renamed away · 4 not-capability · 6 accounted for · 82 genuinely ahead · 279 ahead-accounted
FORWARD=77 REVERSE=82
```

## Run 2 -- `origin/main` (drift check: how much has the R side moved since the frozen oracle)

```
$ python3 tools/parity_ledger.py --ref origin/main
gllvmTMB 0.7.1 @ origin/main (a15f9e46a)
  R exports: 168   GLLVM.jl exports: 434

FORWARD -- RENAMED AWAY (0) / NOT CAPABILITY (4) / ACCOUNTED FOR IN WRITING (6):
  identical to Run 1 above -- same R names (gllvmTMBcontrol, gr, meta_known_V,
  screen_control; add_utm_columns, categorical, get_crs, impute_model,
  make_mesh, miss_control), unaffected by the 0.7.0 -> 0.7.1 diff.

FORWARD -- gllvmTMB EXPORTS WITH NO GLLVM.jl TWIN (85) -- genuinely owed
  .proportions_bootstrap_ci    no disposition (classification=required_core)
  .proportions_wald_ci         no disposition (classification=required_core)
  Beta                         no disposition (classification=required_core)
  VP                           no disposition (classification=intentionally_excluded)
  animal_coef                  UNTRACKED
  animal_dep                   no disposition (classification=required_core)
  animal_indep                 no disposition (classification=required_core)
  animal_latent                no disposition (classification=required_core)
  animal_scalar                no disposition (classification=required_core)
  animal_slope                 no disposition (classification=required_core)
  animal_unique                BLOCKED_NEEDS_JULIA_SURFACE
  block_V                      no disposition (classification=intentionally_excluded)
  column_coef                  UNTRACKED
  confirmatory_lambda          BLOCKED_NEEDS_JULIA_SURFACE
  delta_beta                   no disposition (classification=intentionally_excluded)
  delta_gamma_mix              no disposition (classification=intentionally_excluded)
  delta_gengamma               no disposition (classification=intentionally_excluded)
  delta_lognormal_mix          no disposition (classification=intentionally_excluded)
  delta_poisson_link_gamma     no disposition (classification=intentionally_excluded)
  delta_poisson_link_lognormal no disposition (classification=intentionally_excluded)
  delta_truncated_nbinom1      no disposition (classification=intentionally_excluded)
  delta_truncated_nbinom2      no disposition (classification=intentionally_excluded)
  dep                          no disposition (classification=required_core)
  extract_Sigma_B              no disposition (classification=required_core)
  extract_Sigma_W              no disposition (classification=required_core)
  extract_residual_split       no disposition (classification=required_core)
  flag_unreliable_loadings     no disposition (classification=required_core)
  gamma_mix                    no disposition (classification=intentionally_excluded)
  gengamma                     no disposition (classification=intentionally_excluded)
  gllvmTMB_wide                no disposition (classification=required_core)
  gllvm_julia_setup            no disposition (classification=required_core)
  indep                        PARTIAL_PENDING_DECISION_OPEN_QUESTION
  isdm_source                  BLOCKED_NEEDS_JULIA_SURFACE
  isdm_sources                 BLOCKED_NEEDS_JULIA_SURFACE
  kernel_coef                  UNTRACKED
  kernel_dep                   no disposition (classification=required_core)
  kernel_indep                 no disposition (classification=required_core)
  kernel_latent                no disposition (classification=required_core)
  kernel_scalar                no disposition (classification=required_core)
  kernel_slope                 UNTRACKED
  kernel_unique                no disposition (classification=required_core)
  latent                       BLOCKED_NEEDS_JULIA_SURFACE
  lognormal_mix                no disposition (classification=intentionally_excluded)
  meta                         BLOCKED_NEEDS_JULIA_SURFACE
  meta_V                       BLOCKED_NEEDS_JULIA_SURFACE
  nbinom2_mix                  no disposition (classification=intentionally_excluded)
  pedigree_to_A                BLOCKED_NEEDS_JULIA_SURFACE
  pedigree_to_Ainv_sparse      BLOCKED_NEEDS_JULIA_SURFACE
  phylo                        BLOCKED_NEEDS_JULIA_SURFACE
  phylo_coef                   UNTRACKED
  phylo_dep                    BLOCKED_NEEDS_JULIA_SURFACE
  phylo_indep                  BLOCKED_NEEDS_JULIA_SURFACE
  phylo_latent                 BLOCKED_NEEDS_JULIA_SURFACE
  phylo_rr                     BLOCKED_NEEDS_JULIA_SURFACE
  phylo_scalar                 BLOCKED_NEEDS_JULIA_SURFACE
  phylo_signal_mi              BLOCKED_NEEDS_JULIA_SURFACE
  phylo_slope                  BLOCKED_NEEDS_JULIA_SURFACE
  phylo_unique                 BLOCKED_NEEDS_JULIA_SURFACE
  plot_Sigma_comparison        no disposition (classification=intentionally_excluded)
  plot_Sigma_heatmap           no disposition (classification=intentionally_excluded)
  plot_Sigma_table             no disposition (classification=intentionally_excluded)
  plot_anisotropy              no disposition (classification=intentionally_excluded)
  plot_anisotropy2             no disposition (classification=intentionally_excluded)
  plot_correlations            no disposition (classification=intentionally_excluded)
  plot_loadings_confidence_eye no disposition (classification=intentionally_excluded)
  plot_rotated_loadings        no disposition (classification=intentionally_excluded)
  ridge_path                   no disposition (classification=intentionally_excluded)
  scalar                       PARTIAL_PENDING_DECISION_OPEN_QUESTION
  screen_gllvmTMB              no disposition (classification=intentionally_excluded)
  screen_table                 no disposition (classification=intentionally_excluded)
  simulate_site_trait          BLOCKED_NEEDS_JULIA_SURFACE
  slope                        UNTRACKED
  spatial                      BLOCKED_NEEDS_JULIA_SURFACE
  spatial_coef                 UNTRACKED
  spatial_dep                  BLOCKED_NEEDS_JULIA_SURFACE
  spatial_indep                BLOCKED_NEEDS_JULIA_SURFACE
  spatial_latent               BLOCKED_NEEDS_JULIA_SURFACE
  spatial_scalar               BLOCKED_NEEDS_JULIA_SURFACE
  spatial_slope                UNTRACKED
  spatial_unique               BLOCKED_NEEDS_JULIA_SURFACE
  spde                         BLOCKED_NEEDS_JULIA_SURFACE
  suggest_lambda_constraint    BLOCKED_NEEDS_JULIA_SURFACE
  suggest_lambda_constraints   BLOCKED_NEEDS_JULIA_SURFACE
  traits                       BLOCKED_NEEDS_JULIA_SURFACE
  truncated_nbinom1            no disposition (classification=intentionally_excluded)

REVERSE -- AHEAD OF gllvmTMB, ACCOUNTED FOR IN WRITING (279) -- not a gap, and why
  @formula                         StatsModels macro mirroring R's built-in ~ formula literal; base R syntax needs no export
  [... 278 more lines omitted for length; full class breakdown in Closing list 2 below ...]
REVERSE -- GLLVM.jl EXPORTS WITH NO gllvmTMB TWIN (82) -- genuinely ahead, unclassified
  AnBSparseSolver
  [... 81 more lines omitted for length; full list in Closing list 2 below ...]

COUNTDOWN: 85 export gaps genuinely owed (8 UNTRACKED of those) · 0 renamed away · 4 not-capability · 6 accounted for · 82 genuinely ahead · 279 ahead-accounted
FORWARD=85 REVERSE=82
```

`--self-test` builds a synthetic NAMESPACE + export block, asserts the
forward/reverse counts, then mutates one alias (negative control: proves the
logic discriminates rather than reporting a fixed answer) and re-asserts.
It printed `SELFTEST_OK` and exited 0.

## Closing list 1 -- forward UNTRACKED names (candidate new ledger rows)

These 8 appear only in `origin/main`'s NAMESPACE (168 exports vs. the frozen
oracle's 160) with no `namespace/export/<name>` row yet in
`required-source-case-map.json` -- new R-side surface since the oracle
froze, not yet triaged into `required_core`/`compatibility_adapter`/
`intentionally_excluded`:

`animal_coef`, `column_coef`, `kernel_coef`, `kernel_slope`, `phylo_coef`,
`slope`, `spatial_coef`, `spatial_slope`

All 8 read as per-group/per-block **coefficient or slope accessors**
alongside the already-tracked `*_dep`/`*_indep`/`*_latent`/`*_scalar`/
`*_unique` family for `animal_*`/`kernel_*`/`phylo_*`/`spatial_*` -- a read
of the name, not a verified claim; needs maintainer triage before filing.

## Closing list 2 -- reverse names (Julia-ahead), each with its written class

The 279 REVERSE-accounted names group into these classes (from
`AHEAD_EXPLICIT`/`AHEAD_PATTERNS` in `tools/parity_ledger.py`; counts from
the `origin/main` run, identical at the frozen ref):

| Count | Class | Example names |
|---|---|---|
| 87 | Julia fitting-verb entry point for one family/structure; R dispatches the same concept through `gllvmTMB()`'s `family=` argument, not a separate export per family | `fit_beta_gllvm`, `fit_zip_gllvm_cov`, `fit_ordered_beta_gllvm` |
| 67 | struct suffix `*Fit`: backs a fitted model; R represents the same as an S3 class tag, never a matching export | `BetaFit`, `PoissonFit`, `TweedieFit` |
| 48 | internal marginal-likelihood kernel; reached only from within the fit driver, never an R-facing name | `beta_marginal_loglik_va`, `tweedie_marginal_loglik_laplace` |
| 15 | phylogenetic engine substrate (sparse/contrasts/edge-incidence); no gllvmTMB analogue | `BranchRECache`, `EdgePhy`, `FelsensteinContrasts`, `augmented_phy` |
| 11 | named Wald/profile CI accessor for one derived quantity; gllvmTMB reaches CIs generically via `confint()` | `bootstrap_ci`, `communality_wald_ci`, `icc_wald_ci` |
| 7 | SPDE/Matern spatial substrate; no gllvmTMB analogue | `spde_fem`, `spde_mesh_delaunay`, `Q_perbranch` |
| 7 | CI-machinery entry point (Wald/profile/bootstrap) | `confint`, `confint_constrained`, `confint_fourthcorner` |
| 6 | hand-coded analytic-gradient kernel; engine internal | `beta_laplace_grad`, `nb_laplace_grad` |
| 5 | Julia link-function marker type; R takes the link as a string argument | `LogitLink`, `ProbitLink`, `CLogLogLink` |
| 4 | distribution-kernel helper (log-density/normalizer/CDF); engine internal | `compoisson_logpdf`, `tweedie_cdf` |
| 4 | EM/SQUAREM alternative-solver internal; gllvmTMB's TMB path never uses this solver family | `em_fa`, `em_fit_phylo_squarem` |
| 17 | individually-named: StatsAPI/Base generic mirrors (`predict`, `fitted`, `aic`, `bic`, `coef`, `vcov`, `nobs`, `dof`, `loglikelihood`, `stderror`, `coeftable`, `deviance`, `residuals`, `simulate`), plus `@formula`, `StatsAPI`, `coevolution_gamma`, `extract_rotated_loadings` -- each carries its own one-line reason in `AHEAD_EXPLICIT` | `predict`, `@formula`, `coevolution_gamma` |

The remaining **82 REVERSE names are genuinely ahead and unclassified** --
no pattern matched, so the tool reports them plainly instead of forcing a
class onto them. A read of the names (not a verified claim): mostly post-fit
derived-quantity accessors (`communality`, `correlation`, `repeatability`,
`lv_effects`, `ordination`, `rotation`, ...) and phylogenetic/EM internals
missed by the `phylo_`/`em_` prefix patterns (`node_blups`, `sigma_phy_dense`,
`simulate_relaxed_bm`, `estep_edge_moments`, ...), plus a residue of one-off
structs/functions (`GllvmModel`, `bridge_capabilities`, `gllvm`, `welch_t`,
...). Full 82-name list is reproducible via the command above.
