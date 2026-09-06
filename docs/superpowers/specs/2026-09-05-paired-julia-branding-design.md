# Paired Julia branding and GLLVM.jl landing integration

## Purpose

Give `GLLVM.jl` and `DRM.jl` a recognisable, matched visual identity while
keeping their scientific roles distinct.  The first implementation integrates
the GLLVM mark into the existing reader-first landing page and makes the R and
Julia routes explicitly complementary rather than claiming feature parity.

## Visual system

Both packages use a rounded hexagonal badge with a dark navy field and a thin,
flat accent border.  The shared Julia-adjacent palette is red `#CB3C33`, green
`#389826`, and purple `#9558B2`; blue `#4063D8` is an optional small accent.
These colours signal the Julia ecosystem, but neither mark reuses Julia's
wordmark or its exact circles arrangement.

* **GLLVM.jl:** a sparse response-by-unit grid crossed by one curved shared
  latent axis.  The grid means multiple responses; the axis means their shared
  structure.
* **DRM.jl:** a small directed dependency graph, with arrows and a highlighted
  conditional path.  It means dependence structure rather than latent axes.

Each package receives: an editable SVG master, light and dark page variants,
a square raster fallback, and favicon-sized exports.  At 16--32 px the interior
must reduce to its primary structural cue rather than text or fine detail.

## GLLVM.jl landing page

The existing reader-first hero remains its centrepiece.  The GLLVM badge appears
as a compact, decorative identity mark alongside the hero rather than replacing
the title.  The visible copy remains: matrix-first Julia workflow, covariance
first, and an honest companion-not-replacement boundary.

A short reciprocal link names `gllvmTMB` as the formula-first R workflow and
GLLVM.jl as the matrix-first Julia companion.  It must state that feature
coverage is partial and route-specific, with no implication of general parity.
The equivalent gllvmTMB-side link will be added only in its dedicated
documentation lane after its navigation renewal is reviewed.

## Non-goals

This does not change a model, estimator, public API, capability claim, or
release status.  It does not publish, deploy, alter the official Julia artwork,
or make GLLVM.jl look like an official Julia project.

## Verification

1. Render the GLLVM.jl Documenter/VitePress site locally.
2. Confirm the badge is legible on light and dark layouts and does not crowd
   the responsive navigation.
3. Check the cross-package wording against `docs/src/gllvmtmb-parity.md`.
4. Inspect the SVGs at favicon scale and retain only project-local assets.
5. Do not deploy or publish; present rendered local evidence for approval.
