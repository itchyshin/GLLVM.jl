# Missing-surface engineering work order (post-M2, 2026-09-01)

Source: the 142 BLOCKED_NEEDS_JULIA_SURFACE rows in
`required-source-case-map.json` (area split: postfit 83, namespace 38,
covariance 13, inference 5, fit-input 3). Goal: implement the Julia surfaces,
then convert BLOCKED rows to bound via fresh receipted batches. Merge
authority: every new export is an API addition — lands on this lane branch
only; maintainer approves before merge (AGENTS.md merge-authority table).

## Cluster 1 — post-fit extractor family (~30 rows; HIGHEST leverage)
`extract_Sigma`, `extract_Sigma_table`, `extract_loadings`,
`extract_rotated_loadings`, `extract_communality`, `extract_correlations`,
`extract_cross_correlations`, `extract_residual_cor/cov/split`,
`extract_ordination`, `extract_lv_effects`, `extract_cutpoints`,
`extract_proportions`, `extract_phylo_signal`, `extract_repeatability`,
`extract_ICC_site`, `extract_Gamma`, `extract_Omega`,
`extract_coevolution_modules`, `getLoadings` (level/rotate), `getREsd`,
`getResidualCor`, `getResidualCov`, `getLV`... Mostly thin readouts of
quantities the engine already computes. One coherent module
(`src/extractors.jl`), gllvmTMB-mirroring semantics, docstrings, TDD tests.

## Cluster 2 — derived-CI surfaces (~10 rows)
Two-level repeatability/ICC CI on `TwoLevelFit` (wald first; the R oracle's
profile route is a withdrawn-feature abort — mirror that refusal),
standardized-loading `loading_ci`/rho wald, `loading_profile`,
`profile_ci_phylo_signal`, `profile_ci_total_variance`, `slope_sd_ci`,
`standard_errors`. Builds on `confint_derived*.jl`.

## Cluster 3 — formula structured-term recognizers (38 namespace + 13 covariance rows)
`src/formula.jl` term recognizers for dep()/indep()/scalar()/kernel_latent()/
phylo_latent()/spatial terms mapping to the existing SourceCovariance fit
path. FORMULA GRAMMAR = maintainer-approval-required class: build on the lane,
flag for explicit approval, do not merge.

## Cluster 4 — diagnostics/control/plot (~25 rows; LAST)
`check_gllvmTMB`, `gllvmTMB_diagnose`, `sanity_multi`, `predictive_check`,
`diagnostic_table`, `compare_*`, `gllvmTMBcontrol` options mirror, print/plot
methods (plot needs a Florence/CairoMakie decision — parked).

## Sequencing
Wave A (parallel, disjoint files): Cluster 1 (src/extractors.jl + tests) ·
Cluster 2 (src/confint_derived*.jl + src/twolevel.jl + tests) · M3 Documenter
shell audit (docs/). Wave B: Cluster 3 recognizers. Wave C: receipted
conversion batches on Totoro re-binding the BLOCKED rows. Cluster 4 + plots:
after maintainer review.

## M3 (running alongside)
- Documenter: local build green, reference pages for existing exports,
  quickstart accuracy pass.
- Performance: benchmark plan vs frozen R on qualified models (Gaussian +
  the receipted non-Gaussian cells); D-139 applies — estimate + pre-run test
  before any campaign; Totoro; comparison harness stays outside package tests.
