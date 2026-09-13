# After Task: Exact GLLVM.jl Logo Rollout

## Goal

Apply the maintainer-supplied full and compact GLLVM.jl logo masters throughout
the documentation site without changing the approved landing-page typography or
scientific content.

## Implemented

The desktop landing hero uses the supplied full badge, including the internal
`GLLVM.jl` wordmark. Navigation, the favicon, and reusable interior route
panels use the supplied compact no-text badge. The landing-page wordmark and
headline remain native text, preserving their existing gradient and accessibility.
The supplied SVG masters contain opaque raster canvases. Their display
renditions therefore remove only the connected exterior matte. The full badge
has a centred, constant-width regular hexagonal navy frame; the compact badge
retains its native 277 × 304 proportion. Both remain clean on light and dark
surfaces without altering the supplied plot or internal wordmark.

## Mathematical Contract

N/A — visual documentation identity only; no model, likelihood,
parameterisation, or statistical claim changed.

## Files Changed

- `docs/src/.vitepress/theme/overrides.css` — full and compact display-asset
  placement, with native aspect ratios for both badges.
- `docs/src/assets/gllvmjl-full-logo.svg` — maintainer-supplied full master.
- `docs/src/assets/gllvmjl-icon.svg` — maintainer-supplied compact master.
- `docs/src/assets/gllvmjl-{full-logo,icon}-transparent.png` — alpha-masked
  display renditions; the full rendition has a constant-width regular outer
  navy frame.
- `docs/src/assets/logo.png` — 512 × 512 RGBA navigation rendition.
- `docs/src/assets/favicon.ico` — compact 64 × 64 favicon.
- `docs/src/assets/gllvmjl-{mark,favicon}.svg` and
  `gllvmjl-mark-logo-image25.png` — superseded assets removed.
- `docs/dev-log/check-log.md` and this report — verification record.

## Tests Added

No package test is appropriate for a static asset rollout. The independent
checks are a successful Documenter/VitePress build and browser review of the
actual generated pages in light mode, dark mode, and a 390 px phone viewport.

## Benchmark Numbers

N/A — no runtime or hot-path code changed.

## R-Parity Verdict

Parity: N/A — no R or Julia model surface changed.

## JET / Allocs / Aqua Verdicts

- JET: N/A — docs and static assets only.
- Allocs: N/A — no Julia hot path.
- Aqua: N/A — no dependency, export, or project change.

## Checks Run

```sh
julia --project=docs docs/make.jl
```

Exit 0. Browser review passed for the generated landing page, Quick start,
dark mode, and a 390 × 844 viewport.

```sh
git diff --check
```

Exit 0.

```sh
file docs/src/assets/gllvmjl-{full-logo,icon}.svg \
  docs/src/assets/{logo.png,favicon.ico}
```

Confirmed both SVG masters, a 512 × 512 RGBA PNG, and a 64 × 64 favicon.

## Consistency Audit

The following stale-asset scan returned no source references:

```sh
rg -n 'gllvmjl-mark|gllvmjl-favicon|gllvmjl-mark-logo-image25' \
  docs/src docs/make.jl README.md
```

The hero preserves the established wordmark/headline layout; all small-scale
uses consistently choose the compact icon.

## GitHub Issue Maintenance

No issue action needed: this is a maintainer-approved local branding update,
with no deployment, release, or capability change.

## What Did Not Go Smoothly

The supplied SVGs are wrappers around opaque raster exports rather than native
transparent vectors. A simple rectangular use would show a white matte, while
an approximate polygon clip left an uneven exterior rim. The retained
transparent display renditions remove the connected exterior matte; browser
review then caught and corrected the full badge's optically uneven rim with a
regular, constant-width exterior frame.

## Team Learning

For brand assets, inspect the generated site before accepting a source-level
asset path as valid; build transformations can change how relative SVG links
resolve.

## Remaining Risks

- The preview is local and uncommitted; publishing remains maintainer-gated.
- The supplied SVG masters rasterise embedded artwork, so their intrinsic
  clarity is bounded by that source artwork at very large display sizes.

## Known Limitations

The brand treatment does not alter GLLVM.jl's capability scope, parity status,
or any scientific documentation claims.

## Next Command

`git diff -- docs/src/.vitepress/theme/overrides.css docs/src/assets docs/dev-log/check-log.md`

## Rose Verdict

Rose verdict: PASS WITH NOTES — the built site was reviewed in all requested
display modes; publication and any commit remain maintainer-gated.
