# After Task: Responsive GLLVM.jl Homepage Mark

## Goal

Make the existing GLLVM.jl response-structure logo visibly part of the homepage
at desktop and mobile widths, in the same confident product-identification role
as DRM.jl's mark.

## Implemented

The homepage frontmatter now declares the response-structure mark as its hero
image, with useful alternative text.  The old absolute CSS pseudo-element and
its 1320px hiding rule are gone.  The small mobile rule leaves the hero image in
VitePress's ordinary stacked layout.  The public-root asset is a regular SVG,
not a symlink, because the documentation pipeline preserves symlinks rather
than dereferencing them.

## Mathematical Contract

N/A — documentation identity only; no model, likelihood, parameterisation, or
statistical claim changed.

## Files Changed

- `docs/src/index.md` — semantic hero image and alt text.
- `docs/src/.vitepress/theme/overrides.css` — responsive normal-flow treatment;
  removes the desktop-only pseudo-element.
- `docs/src/assets/gllvmjl-mark-logo.svg` — regular public-root-compatible SVG.
- `docs/dev-log/check-log.md` and recovery checkpoint — rendered-build record.

## Tests Added

`RENDERED_HERO_LOGO_ASSET_PASS` checks that the rendered public-root image is a
non-symlink file.  It would have failed for the original symlink alias.  The
rendered HTML additionally contains the expected hero `<img>` source and alt
text.

## Benchmark Numbers

N/A — no runtime hot path changed.

## R-Parity Verdict

Parity: N/A — no R or Julia model surface changed.

## JET / Allocs / Aqua Verdicts

- JET: N/A — docs/CSS/assets only.
- Allocs: N/A — no Julia hot path.
- Aqua: N/A — no dependency/export/project change.

## Checks Run

```sh
OPENBLAS_NUM_THREADS=1 julia --startup-file=no \
  --project=/private/tmp/destination-b-docs-BQmlwD docs/make.jl --local
```

Exit 0.  The VitePress stage reports `build complete in 7.21s`; the full local
run took longer than the earlier short build measurement because it reran
doctests before rendering.  Deployment was skipped in local mode.

```sh
julia --startup-file=no -e 'p="docs/build/.documenter/public/gllvmjl-mark-logo.svg"; @assert isfile(p) && !islink(p); @assert filesize(p)>0; println("RENDERED_HERO_LOGO_ASSET_PASS")'
```

Exit 0: `RENDERED_HERO_LOGO_ASSET_PASS`.  The rendered
`docs/build/1/index.html` contains the hero source
`/gllvmjl-mark-logo.svg` and the supplied alternative text.  `git diff --check`
also exits 0.

## Consistency Audit

The homepage no longer has a `.VPHomeHero .container::after` mark or a
`max-width: 1320px` rule that hides it.  The nav logo remains the existing
`/logo.png`; the hero receives a distinct responsive SVG route.  No capability,
parity, or release wording was changed.

## GitHub Issue Maintenance

No issue action needed: this is a requested local documentation improvement,
with no release or public deployment.

## What Did Not Go Smoothly

The first convenience alias was a symlink.  Inspecting the actual
DocumenterVitepress copy behavior showed that the generated public file would
also have been a symlink and its relative target would not exist there.  It was
replaced with a real SVG before the successful render.

## Team Learning

For DocumenterVitepress public-root assets, test the generated asset rather than
assuming a source-tree symlink will be dereferenced.

## Remaining Risks

- This verifies the generated local page and responsive layout contract, not a
  browser screenshot on every physical device.
- The change is local only until a maintainer explicitly chooses to push/deploy.

## Known Limitations

The mark improves visual orientation; it does not imply expanded GLLVM.jl
capabilities or parity with gllvmTMB.

## Next Command

none — homepage logo slice fully checked locally; the parent Destination B
programme remains active.

## Rose Verdict

Rose verdict: PASS WITH NOTES — rendered locally and responsive by theme layout;
no browser-device screenshot or deployment was performed.
