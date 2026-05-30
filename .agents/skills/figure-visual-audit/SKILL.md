---
name: figure-visual-audit
description: Audit and improve GLLVM.jl figures, Documenter.jl pages, simulation reports, and CairoMakie recipes when plots look poor, inconsistent, misleading, too sparse, missing raw or replicate data, or need Florence, Rose, Pat, Fisher, and Grace visual QA before being called done.
---

# Figure Visual Audit

Use this skill before declaring visualization work complete, and whenever a
reader says a rendered figure looks strange, ugly, inconsistent, too sparse, or
misleading. This skill applies to CairoMakie.jl figures shipped in GLLVM.jl
docs, examples, and ADEMP simulation reports.

## Shared Accountability

Do not treat poor figures as Florence's fault alone. Florence owns the final
scientific-figure standard, but the gate fails earlier if the statistical,
reader, systems, and reproducibility checks let an incomplete plot through.
Several team perspectives must cultivate visual judgment. A useful scientific
figure is not decoration; it helps users understand the model, helps reviewers
see the evidence, and helps the team catch wrong assumptions before they become
text. Beauty means legible hierarchy, honest uncertainty, informative negative
space, coherent colour, and a display that makes the result easier to reason
about than the table alone.

## Standing Roles

- Ada coordinates the audit and decides what changes before merge.
- Florence reviews the rendered image as a scientific figure: composition,
  hierarchy, labels, accessibility, and whether the plot looks publication
  ready.
- Rose searches for repeated failure patterns across figures, prose, NEWS,
  ROADMAP, after-task reports, and check logs.
- Pat checks whether an applied reader can decode the figure without knowing
  the implementation history.
- Fisher checks that the visual data grain matches the claim: raw observations,
  fitted-row predictions, replicate errors, aggregate means, MCSE intervals,
  profile intervals, Wald intervals, bootstrap intervals, and missing cells
  must not be blurred together.
- Grace verifies renderability, Documenter.jl readiness, and reproducibility.
- Boole checks whether the figure code and public syntax are memorable and do
  not make unsupported syntax look implemented.
- Noether checks that equations, parameter labels, axes, and prose all name the
  same estimand and reporting scale (e.g. SD vs variance, log-scale vs natural
  scale, signed loadings vs |loadings|).
- Curie checks whether simulation figures expose the replicate-level or
  aggregate artifacts actually produced by the runner.
- Darwin checks whether the biological question (species, traits, phylogeny,
  ordination) is visible and not buried under package-internal terminology.

Say explicitly when these are role perspectives rather than spawned agents.

## Visual Taste Standard

Before changing code, ask what the figure should help the reader do: compare
loadings, detect bias, see uncertainty on an SD or correlation, locate
unsupported cells, understand a phylogenetic signal, or choose the next
diagnostic. Then judge the figure against that purpose:

- A beautiful result figure has a clear visual hierarchy: the main comparison is
  visible first, uncertainty second, provenance and caveats nearby.
- Empty space should guide comparison, not make one point float in a giant
  panel.
- Colour should group meaningfully across articles and remain readable without
  the legend.
- Missing or unsupported cells (failed fits, non-identified parameters, NA
  intervals) should feel intentional, not like plotting bugs.
- Raw or replicate-level marks should add understanding; if they become noise,
  summarise them but keep the data grain explicit.
- A figure should help the package team too. If a plot hides non-convergence,
  failed intervals, missing surfaces, or impossible estimates, it is not ready.

## Confidence Eye Contract (Enforced Default)

GLLVM.jl inference summaries (loadings, SDs, correlations, communality,
phylogenetic signal H²) default to a **Confidence Eye** display. The contract is:

- **Pale CI region**: low-alpha fill (Makie `color = (palette_color, 0.25)` or
  `band!` with low alpha) spanning the full interval. The fill should make
  values near the estimate look more compatible than values near the boundary.
- **Darker outline**: stroke of the same hue at full opacity around the fill,
  so the interval edges are unambiguous on grayscale printout.
- **Darker center mark**: short tick (`vlines!` or `lines!` segment) at the
  point estimate, in the darker outline colour.
- **Hollow point-estimate circle**: `scatter!` at the point estimate with
  `color = :white` (or `color = (:white, 1.0)`) and `strokecolor = dark_hue`,
  `strokewidth ≥ 1.5`. The hollow interior is what makes the estimate
  legible inside the pale fill.

Prohibited unless the user explicitly requests an exception:

- Filled (solid) points at the estimate. They flatten the eye and visually
  outweigh the interval.
- Horizontal CI bars (whisker-style error bars) used as the only uncertainty
  cue. Bars are acceptable as a secondary mark on simulation MCSE figures, but
  not as the inference default.
- Center lines that run all the way through the eye. The center mark is a
  short tick, not a full-height line.
- Row guide lines (long horizontal rules behind each row). They compete with
  the eye for visual weight.

When the user explicitly asks for a different display ("just bars please",
"hide the fill", "use a violin"), honour the request and note in the caption
that the default Confidence Eye was overridden.

## Uncertainty Language

Captions, axis labels, and legends must name the **source** and **scale** of
every interval shown. Use *frequentist* language for frequentist intervals.

- "95% Wald confidence interval (observed information; log scale for SDs,
  identity for signed loadings; back-transformed to natural scale)."
- "95% profile likelihood confidence interval (LRT inversion)."
- "95% parametric bootstrap percentile interval (B = 1000 replicates)."
- "95% Fisher-z transformed Wald confidence interval for cross-trait
  correlation (back-transformed to [−1, 1])."
- "95% logit-scale Wald confidence interval for communality c² / phylogenetic
  signal H² (back-transformed to [0, 1])."
- "Monte Carlo standard error (MCSE) for coverage proportion across S
  replicates" — for ADEMP simulation panels.

Do **not** use posterior, credible interval, or Bayesian language for any
GLLVM.jl interval. The package is fully frequentist (Wald, profile,
bootstrap); calling a Wald interval a "credible interval" misnames the
estimand. "Compatibility interval" is acceptable as a synonym for confidence
interval and is preferred when the visual cue is graded compatibility
(Confidence Eye fill).

If a figure ever displays a genuinely posterior object (e.g. from a downstream
Bayesian wrapper that is not in this repo), then and only then use posterior /
credible language, and say so in the caption.

## Render-Proof Discipline

CairoMakie figures cache by default in Documenter.jl previews, simulation
report directories, and on-disk PNG/PDF outputs. A stale thumbnail can
survive a code fix and make the audit look passed when it has not.

- After every fix, **save the rendered figure to a fresh filename** (e.g.
  `loadings_eye_v2.png`, or include a date/slice slug). Do not overwrite the
  old filename and assume the viewer has refreshed.
- **Inspect the rendered image directly** before claiming the fix worked. Open
  the PNG/PDF/SVG in an image viewer, or use the Read tool on the file path.
  Source inspection alone is not evidence; CairoMakie can produce a clean
  source and a broken image (clipped axes, missing legend, wrong colour map,
  scale collapsed to a single point).
- When linking to a figure in docs or a report, link the **fresh filename**.
  If the old filename is referenced elsewhere, decide whether to update the
  link or leave a redirect note.
- For Documenter.jl pages, run `julia --project=docs docs/make.jl` and inspect
  `docs/build/` outputs, not the source `.md`.

## Accessibility

- Use colourblind-safe palettes: Wong (8-class), Okabe-Ito, or viridis /
  cividis for sequential. CairoMakie ships these via `ColorSchemes.jl`; use
  `colormap = :viridis` for sequential and explicit hex codes for Wong /
  Okabe-Ito when grouping.
- Maintain contrast ratio ≥ 3:1 for text on its background (WCAG 2.1 Level AA
  for large text). Dark grey text on white is fine; pastel text on pastel
  background is not.
- Do not encode information by hue alone. Use shape, line style, or position in
  addition to colour so the figure survives greyscale printing.
- Label all axes with units and the reporting scale (log, identity,
  back-transformed). Avoid package-internal symbols where a plain phrase is
  clearer ("Species loading" not just "Λ").

## CairoMakie Specifics

- **Backend**: `using CairoMakie` for publication-quality vector output.
  GLMakie is interactive only and should not be used for docs / reports.
- **File formats**:
  - PDF or SVG for publication (vector, scales cleanly, embeds in LaTeX).
  - PNG for Documenter.jl docs site and quick previews. Use
    `CairoMakie.save("path.png", fig; px_per_unit = 2)` for retina-quality
    PNGs.
  - Do not ship JPEG for plots — lossy artefacts on text and thin lines.
- **Figure sizing**: explicit `Figure(size = (width, height))` in pixels.
  Default 800 × 600 is rarely right; sims often want 1200 × 800, single-panel
  docs figures want ~600 × 450.
- **Resolution for raster**: `px_per_unit = 2` for retina; `= 4` for print
  PNG if vector is not possible.
- **Theme**: prefer a single project-wide theme set with
  `set_theme!(theme_minimal())` or a custom theme in a docs helper, so colour,
  font, and axis style stay consistent across the gallery.

## Workflow

1. Inventory the target figures and promises. Search the docs sources, NEWS,
   ROADMAP, design notes, after-task reports, and simulation runner outputs
   for the figure titles and claims such as "visual check", "raincloud",
   "raw", "replicate", "MCSE", "confidence", "compatibility", "supported",
   and "planned".
2. Render the actual docs page or report. Prefer `julia --project=docs
   docs/make.jl` for Documenter.jl pages and a direct
   `julia --project=. path/to/script.jl` for simulation reports.
3. Extract the rendered PNGs/PDFs and inspect them one by one. A contact sheet
   is a navigation aid only; it is not enough evidence by itself.
4. Write or update a per-figure audit table with: figure title or chunk,
   source object, visual data grain, uncertainty source and scale,
   missing-cell display, reader risk, verdict, and fix.
5. Run Rose's pattern scan before editing. Common failure patterns are:
   summary-only plots when row-level or replicate-level data are available;
   fake raw data reconstructed from aggregates; invisible or tiny intervals;
   filled points obscuring the Confidence Eye; horizontal CI bars used as the
   default inference cue; empty faceted panels with one point floating in
   whitespace; dodged points whose locations no longer align with eyes or
   intervals; unsupported cells (failed fits, non-identified parameters) that
   disappear silently; titles or subtitles promising uncertainty that the
   figure does not visibly show; Bayesian or "credible" language used for
   Wald/profile/bootstrap intervals; implemented-versus-planned status
   ambiguity; clipped labels, cramped legends, and inconsistent palettes or
   scales.
6. Edit the smallest recipe or prose needed to fix the figure. Do not add a
   new exported plotting helper unless the table contract is stable and
   tested.
7. Re-render to a **fresh filename** and inspect every changed figure
   directly. Save durable evidence under `docs/dev-log/figure-audits/<date-or-slice>/`
   when the figure gate is part of a meaningful task.
8. Close with a check-log entry and after-task report that names the figures
   inspected and the remaining limitations.

## Hard Gates

- Do not call a figure done from source inspection alone. Inspect the rendered
  PNG/PDF.
- Do not call a gallery visually checked unless the rendered images were
  inspected one by one and Rose recorded cross-figure patterns.
- Do not show raw-response points on an SD, variance, correlation, communality,
  or H² axis. Fitted predictions or simulation replicate errors can be shown
  on their own derived axis when the caption names that data grain.
- Do not draw error bars, ribbons, intervals, or Confidence Eyes without
  saying what they mean and where they came from: Wald confidence interval,
  profile confidence interval, parametric bootstrap interval, Fisher-z Wald,
  logit Wald, binomial MCSE for coverage, RMSE MCSE, or another named source.
  The transformation scale (log, logit, Fisher-z, identity) must also appear.
- The Confidence Eye contract above is the **default** for any
  inference-summary figure. Filled points, horizontal CI bars as the only
  cue, full-height center lines, and row guide lines are prohibited unless
  the user explicitly overrides.
- Do not use posterior, credible interval, or Bayesian language for Wald,
  profile, or bootstrap intervals. Use confidence or compatibility.
- Do not put loadings on one comparative axis unless they share a meaningful
  unit (standardised loadings on a common species or trait scale). Otherwise
  facet or label the units so visual magnitude comparisons are not misleading.
- Simulation coverage and power displays do not require Confidence Eyes.
  Their first duty is to show the replicate or replicate-block data grain,
  the aggregate proportion, and the named Monte Carlo uncertainty interval.
- Do not fake replicate-level clouds from aggregate summaries. If only
  aggregate rows exist, use aggregate points and MCSE bars and say so.
- Missing, unsupported, or failed cells (non-convergent fits, NA profile
  intervals, non-identified loadings) should remain visible through blank
  lanes, boundary marks, captions, or support tables.
- Always save renders to a fresh filename and inspect the image before
  claiming the fix worked. Stale thumbnails are a known failure mode.
- Use at most 10 cores for render, simulation, bootstrap, or profile work.
