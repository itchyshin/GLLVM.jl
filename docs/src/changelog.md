# Changelog

Notable changes to GLLVM.jl. Style mirrors `gllvmTMB`'s NEWS: status labels
**IN** (shipped), **PARTIAL** (limited), **PLANNED** (next), with issue/PR refs.

## GLLVM.jl (development version)

### Documentation
- **IN:** pkgdown-style documentation site (DocumenterVitepress) — dropdown
  navbar, full-text search, light/dark mode; homepage mirrors `gllvmTMB`'s with
  a Julia flavour. (#4)
- **PARTIAL:** public status pages now distinguish the minimal Julia-side
  `bridge_fit` route from the still-open live `gllvmTMB` bridge, fixed-effect
  `X`, missingness, mixed-family, and post-fit-method gates.

### Engine
- **IN:** O(p) node-frame phylogenetic gradient; type-stable recursion kernels
  (function barrier + parametric state); Aqua + JET quality gates wired green.
- **IN:** single-trait (univariate) phylogenetic Gaussian fitter
  `fit_phylo_gaussian`, built on the O(p) node-frame gradient. (#5)
- **IN:** `phylo_signal_wald_ci` scale fix for signed identity-scale
  `sigma_phy`; packed phylogenetic signal now matches `phylo_signal(fit;
  Σ_phy)` and is in the main test suite. (#92)
- **IN:** Laplace mode-finder safeguards: large Fisher-scoring steps are
  backtracked against the conditional mode objective, near-mode full steps are
  preserved, and non-finite/factorization failures restart once from zero.
  This fixes the local #96 engine blocker but does not by itself flip any
  gradient default.
- **IN:** `simulate_response` draws conditional in-sample response matrices for
  Gaussian, Poisson, Binomial, NegativeBinomial, Beta, and Gamma fits; Ordinal
  response simulation remains gated.
- **PARTIAL:** minimal `bridge_fit` entrypoint for no-covariate one-part
  families; unsupported bridge cells reject deliberately. Live R roundtrip is
  still a bridge slice, not a release claim.

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
