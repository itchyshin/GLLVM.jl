# G1 evidence — paired reader journey

Date: 2026-09-05
Status: **STOPPED AT G1; NOT PUBLISHED**

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

The 1440/768/390 screenshot, full keyboard/focus traversal, reduced-motion,
and overflow checks remain open. No deployment or publication was attempted.
