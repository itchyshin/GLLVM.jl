# After-task — paired Julia branding

**Date:** 2026-09-05  
**GLLVM.jl branch:** `codex/g0-reader-journey-visual-20260905`  
**DRM.jl asset lane:** `codex/paired-julia-identity-20260905`

## 1. Scope and outcome

Created matched, original hex identity assets for GLLVM.jl and DRM.jl. Integrated
the GLLVM.jl mark into the local reader landing page only. No remote was changed.

## 2. Reader outcome

GLLVM.jl retains its visible text identity and uses the new mark only as a
decorative desktop badge. The existing wording still directs formula-first R
work to gllvmTMB and calls GLLVM.jl partial parity.

## 3. GLLVM.jl assets

- `docs/src/assets/gllvmjl-mark.svg`: response grid plus one curved latent axis.
- `docs/src/assets/gllvmjl-favicon.svg`: compact version of the same cue.
- `docs/src/assets/logo.png` and `favicon.ico`: local generated derivatives
  automatically recognised by DocumenterVitepress.

## 4. DRM.jl assets

In the isolated DRM.jl lane, `drmjl-mark.svg` and `drmjl-favicon.svg` use two
density curves with the same mean and different spreads: narrow teal and wide
indigo. The paired PNG logo and ICO favicon were generated there. The DRM.jl
landing-page lease remains with its separate owner; this slice did not edit it.

## 5. Design and licensing boundary

The marks are new geometry. They use a Julia-adjacent palette without copying
the Julia wordmark or its dot arrangement. This is a visual relationship, not
official Julia affiliation or endorsement.

## 6. Files changed in this slice

- `docs/src/index.md`
- `docs/src/.vitepress/theme/overrides.css`
- `docs/src/assets/gllvmjl-mark.svg`
- `docs/src/assets/gllvmjl-favicon.svg`
- `docs/src/assets/logo.png`
- `docs/src/assets/favicon.ico`
- `docs/dev-log/check-log.md`
- this report

## 7. Validation run

```sh
xmllint --noout docs/src/assets/gllvmjl-mark.svg docs/src/assets/gllvmjl-favicon.svg
rsvg-convert --output /private/tmp/gllvmjl-mark-preview.png --width 512 --height 512 docs/src/assets/gllvmjl-mark.svg
julia --project=docs docs/make.jl --local
```

The SVGs parse and the 512 px visual render was inspected. The local docs build
completed successfully, including DocumenterVitepress page rendering. It
explicitly skipped deployment in the local environment.

## 8. Accessibility and responsive check

The decorative image has empty alt text; the page's textual GLLVM.jl heading is
the accessible identity. The badge is hidden at 960 px and below, while the
existing 768--1100 px drawer-navigation guard remains unchanged. The DRM indigo
was lightened to `#4D6FE3`, yielding 3.70:1 contrast against navy.

## 9. Review

An independent asset review passed the original-geometry, Julia-adjacent palette,
semantic distinction, and small-scale checks. It identified the initial DRM
indigo contrast problem; that was corrected before this report.

## 10. Not claiming

- Official Julia branding, affiliation, or endorsement.
- GLLVM.jl feature or inference parity with gllvmTMB.
- A completed DRM.jl landing-page redesign.
- A deployed site update.

## 11. Follow-up

Hand the DRM.jl assets to the landing-page owner for its approved hero slice.
Inspect the rendered hero at desktop and narrow widths before any future public
documentation deployment.
