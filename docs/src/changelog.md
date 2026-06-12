# Changelog

Notable changes to GLLVM.jl. Style mirrors `gllvmTMB`'s NEWS: status labels
**IN** (shipped), **PARTIAL** (limited), **PLANNED** (next), with issue/PR refs.

## GLLVM.jl (development version)

### Documentation
- **IN:** pkgdown-style documentation site (DocumenterVitepress) — dropdown
  navbar, full-text search, light/dark mode; homepage mirrors `gllvmTMB`'s with
  a Julia flavour. (#4)

### Engine
- **IN:** O(p) node-frame phylogenetic gradient; type-stable recursion kernels
  (function barrier + parametric state); Aqua + JET quality gates wired green.
- **IN:** single-trait (univariate) phylogenetic Gaussian fitter
  `fit_phylo_gaussian`, built on the O(p) node-frame gradient. (#5)

### Quality & infrastructure
- **IN:** `Pkg.test()` adopted as the full-suite command; Aqua (package
  hygiene) and JET (type-stability of the O(p) kernels) run in CI.
- **IN:** isolated RCall.jl parity scaffold (`test/parity/`, opt-in) for
  checking agreement against R `gllvmTMB`.

## GLLVM.jl v0.1.0

- **IN:** Gaussian + phylogenetic GLLVM engine — closed-form marginal
  likelihood, PPCA / EM initialisation, multiple phylogenetic representations
  (sparse precision, Felsenstein contrasts, edge-incidence) agreeing to machine
  precision.
- **IN:** Wald / profile-likelihood / parametric-bootstrap confidence
  intervals, including derived quantities (Σ_y entries, communality,
  cross-trait correlation, phylogenetic signal).
- **IN:** ~340× median per-fit speedup over R `gllvmTMB` on the **single-σ²
  Gaussian** benchmark grid, reproducing estimates and likelihoods to machine
  precision on that grid (R's per-species Gaussian default is not yet measured).
