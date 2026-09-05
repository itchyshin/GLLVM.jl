# G1 evidence — paired reader journey

Date: 2026-09-05
Status: **G1 COMPLETE; NOT PUBLISHED**

The companion gllvmTMB evidence record is
`gllvmTMB/dev/website-renewal/G1-EVIDENCE.md`. The Julia-specific evidence is:

- local `julia --project=docs docs/make.jl --local` rendered
  `docs/build/1/index.html` and `docs/build/1/quickstart.html`;
- the per-response `GaussianPerVarFit` smoke example constructed `Sigma`,
  correlation, and communality successfully from `Lambda` and `psi²`;
- the pages explicitly state that the shared-residual extractor methods do not
  yet dispatch on `GaussianPerVarFit`, so the explicit calculation is an
  experimental current route rather than a stable extractor promise;
- source/rendered scans retain partial-parity, orientation, and
  Gaussian-only-speed boundaries; `git diff --check` passes.
- after instantiating the declared `docs` environment in a fresh `origin/main`
  worktree, `julia --project=docs docs/make.jl --local` rendered the new
  VitePress landing page with its hero actions, feature cards, Skip to content
  link, and retained orientation/partial-parity boundaries.
- native Firefox opened that local output and exposed the desktop navigation,
  Skip to content link, mobile-navigation control, all three hero actions,
  feature cards, and retained scope warnings.

## Responsive and accessibility review

- An isolated local-browser review checked both rendered routes at **1440 px**,
  **768 px**, and **390 px**. Each had `scrollWidth == viewport width`.
  The R reader-route chooser remained present at every size; the Julia hero
  retained all three actions at 1440 and 390 px.
- At 768 px, the generated VitePress desktop menu was 1,060 px wide. The
  source theme override keeps the accessible drawer navigation through 1,100
  px; a fresh local build then showed no overflow, the drawer control, and no
  desktop menu at 768 px. The full menu returned at 1440 px.
- At 390 px, both navigation toggles opened. Keyboard tab traversal reached
  the R `Get started` control and Julia `Getting Started` control. The
  generated VitePress CSS supplies a `prefers-reduced-motion: reduce` rule.
- In-app screenshots were reviewed at each breakpoint, including the corrected
  Julia 768 px layout. No deployment or publication was attempted.
