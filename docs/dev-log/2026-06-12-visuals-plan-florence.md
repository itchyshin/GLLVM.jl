# Visualization plan — Florence (GLLVM.jl plotting layer)

Grounded in the two companion papers (overview Fig 3 + the behavioural-syndromes
two-level outputs) and JSDM/ordination norms. Implemented as a **Plots.jl package
extension** (registry-clean: Plots is a weak dependency; plot methods activate on
`using Plots`). All panels read the EXISTING extractors — `getLoadings`, `getLV`,
`correlation`, `communality`, `sigma_y_site`, `predict`, `residuals` — so the viz
layer adds presentation only, no new statistics.

## The figure set (prioritised)

### P1 — the core four (overview Fig 3) + ordination up to d=3
1. **Model-based ordination** (`gllvm_ordiplot` / `gllvm_biplot`):
   - **d=1**: 1-D ordination — ordered site scores as a rug/dotplot along LV1.
   - **d=2**: classic biplot — site scores as points + trait loadings as arrows.
   - **d=3**: a 2×2 panel of the three pairwise biplots (LV1–LV2, LV1–LV3, LV2–LV3),
     plus an optional `gllvm_ordiplot3d` 3-D scatter. Default to the pairwise grid
     (printable); offer the 3-D view as an option.
   - Options: `biplot=true/false` (arrows on/off), group colour, procrustes rotation,
     species/site labels, arrow scaling.
2. **Loadings grid** (`gllvm_loadings_plot`): trait × LV heatmap/grid, diverging colour
   by sign × magnitude (Fig 3b). Handles d=1..3 columns.
3. **Residual-correlation heatmap** (`gllvm_corrplot`): p×p, lower triangle, diverging
   colour (sign) × intensity (strength), diagonal = 1 (Fig 3c). Optional
   clustered/dendrogram ordering.
4. **Communality bars** (`gllvm_communality_plot`): per-trait shared-variance proportion
   in [0,1] (Fig 3d).
5. **`gllvm_fig3`**: composes 1–4 in one layout (the paper's Fig 3).

### P2 — partitioning, two-level, network, coefficients
6. **Variance-partition plot**: per-trait stacked bars by component (shared latent /
   fixed Xβ / residual). For multi-level fits: **between- vs within-individual**
   communality side-by-side (the behavioural-syndromes paper's headline output).
7. **Correlation network**: traits as nodes, edges = strong residual correlations
   (sign-coloured) — the common JSDM association graph; complements the heatmap.
8. **Caterpillar / coefficient plot**: fixed-effect (Xβ) and per-trait loading point
   estimates + CIs (Wald/profile/bootstrap, where available).

### P3 — diagnostics + signal + the Confidence Eye
9. **Residual diagnostics** (DHARMa-style): Dunn-Smyth / randomized-quantile residual
   QQ-plot + residual-vs-fitted (uses `residuals`/`quantile_residuals`).
10. **Phylo-signal / repeatability** plot (where the structured fit provides it).
11. **Confidence-Eye** figure (the lab's standing figure contract) — apply to the
    loadings/correlation uncertainty.

## Technical spec
- Files: `src/plots.jl` (exported generic stubs that error "load Plots.jl"; included in
  GLLVM.jl + exported), `ext/GLLVMPlotsExt.jl` (the real methods), `Project.toml`
  `[weakdeps]` + `[extensions]` + `[compat]` for Plots.
- Dispatch on every fit type (Gaussian `::GllvmFit` takes no `Y` in extractors;
  non-Gaussian + mixed take `Y` [+ `N` for Binomial]).
- Verification (no display): each function returns a valid `Plots.Plot` without error
  for Gaussian + Poisson + mixed fits, and the underlying data matches the extractor
  (corrplot matrix == `correlation`; bars == `communality`; loadings grid ==
  `getLoadings`). Visual aesthetics are maintainer review.
- Maybe a Makie backend later (the user can request) — keep the API backend-agnostic.

## Sequencing
P1 first (core four + d≤3 ordination) as the shippable slice → P2 (partitioning +
two-level + network + caterpillar) → P3 (diagnostics + Confidence-Eye). The two-level
communality plot (P2 #6) is gated on the two-level inference capability (P1 of the
finish-line DoD), so it lands when that does.
