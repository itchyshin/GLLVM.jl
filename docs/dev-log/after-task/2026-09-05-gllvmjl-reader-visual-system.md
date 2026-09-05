# After-task — GLLVM.jl reader visual system

**Date:** 2026-09-05  
**Branch:** `codex/g0-reader-journey-visual-20260905`

## 1. Scope and outcome

Extended the approved GLLVM.jl identity from the landing page into the core
reader journey. The scope is visual orientation only: shared styling, small
route panels, and responsive navigation behaviour. No model, API, benchmark,
or capability implementation changed.

## 2. Reader outcome

The landing page remains the primary question-led entry point. Quick start,
covariance interpretation, model, capability-parity, comparison, and the two
applied vignettes now each begin with a compact route panel that tells a reader
what the page is for before its technical content begins.

## 3. Shared identity

The existing GLLVM.jl response-structure mark remains the navbar, favicon, and
desktop-home identity. Article panels use the same mark as a CSS decorative
element, so it stays out of the accessibility tree and is bundled by VitePress
instead of relying on a hand-written deployment path.

## 4. Visual-system implementation

`docs/src/.vitepress/theme/overrides.css` now supplies a small `gllvm-`
namespace: a gradient rule below first-level article headings, light and dark
route-panel tokens, a four-category accent treatment, and a single-column
mobile layout. The panels use a calm surface and border rather than copying the
DRM.jl dark hero treatment.

## 5. Wording and evidence boundary

The new page labels reinforce, rather than widen, existing wording. In
particular, the parity panel says that it is a route-specific evidence record,
not a promise of identical R workflows; comparison remains context rather than
a leaderboard. Existing experimental, partial-parity, benchmark, and inference
language was otherwise left intact.

## 6. Files changed

- `docs/src/.vitepress/theme/overrides.css`
- `docs/src/quickstart.md`
- `docs/src/covariance-correlation.md`
- `docs/src/model.md`
- `docs/src/gllvmtmb-parity.md`
- `docs/src/comparison.md`
- `docs/src/vignettes/community-abundance.md`
- `docs/src/vignettes/phylogenetic-gllvm.md`
- this report
- `docs/dev-log/check-log.md`

## 7. Validation run

```sh
julia --project=docs docs/make.jl --local
git diff --check
```

The local DocumenterVitepress build completed. The build reported only its
existing large-chunk advisory and correctly skipped deployment in local mode.

## 8. Visual and route review

Browser inspection of the local build confirmed the quick-start and
capability-parity panels render as HTML rather than escaped source text. At the
1280 px review width, the full navigation now collapses to the accessible drawer
before it overlaps the package title and search control; the home mark also
hides before it can compete with the hero actions. All seven modified routes
were present in the generated build output.

## 9. Coordination boundary

The separate `gllvmtmb-navigation-renewal` lane owns navigation taxonomy and
source ordering. This slice only changes GLLVM.jl page presentation and a
responsive overflow guard; it does not change `docs/make.jl` navigation,
gllvmTMB files, or the DRM.jl landing page.

## 10. Not claiming

- Official Julia affiliation or endorsement.
- GLLVM.jl feature, inference, or whole-workflow parity with gllvmTMB.
- New support, benchmark evidence, or an API change.
- A completed navigation-renewal programme.

## 11. Follow-up

After the navigation-renewal lane lands, map its final four reader groups to
these GLLVM.jl route panels and consider adding an actual guides landing page.
Do not add one merely as a menu heading: no `/guides` route currently exists.
