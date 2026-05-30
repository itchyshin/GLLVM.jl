# After-task — Phase 1.4: `fit_phylo_gaussian` (O(p) phylogenetic fitter)

**Date:** 2026-05-30
**Issue:** #5 · **Branch:** `phylo-fitter` (off `phase-1-quality`)
**Models:** Opus (numerical port + verification design).

## Goal

Turn the verified O(p) node-frame gradient into a usable fit: an L-BFGS fitter
for the single-trait single-variance phylogenetic Gaussian model. The
plain-data signature is the contract the future R bridge calls.

## Implemented

- **`src/fit_phylo.jl`** (new): ported from bench `julia/P4_fit_sv.jl`.
  - Model `y ~ N(μ·1, σ²_eps·I + σ²_phy·Σ_phy_unit)`; `Σ_phy_unit` never formed
    densely — reuses `build_node_perspecies`/`NodePerSpecies`.
  - `_phylo_negll` (matrix-determinant lemma + Woodbury, O(p)),
    `_phylo_sigma_inv_apply`, `_phylo_profile_mu` (GLS-profiled μ̂).
  - `fit_phylo_gaussian(phy_or_newick, y; profile_mu=true, …) -> PhyloGaussianFit`
    — L-BFGS (BackTracking line search) on the log-variance scale, finite-diff
    gradient (CHOLMOD blocks ForwardDiff), still O(p). `PhyloGaussianFit` struct
    + `Base.show`.
  - Wired into `src/GLLVM.jl`; exports `fit_phylo_gaussian`, `PhyloGaussianFit`.
- **`test/test_fit_phylo.jl`** (new, 13 assertions), wired into `runtests.jl`.

## Scope correction (provenance)

The original issue-#5 sketch used `(Y, Σ_phy)`. The actual O(p) object (bench
`P4_fit_sv.jl`) is **single-trait, tree-based** — it takes a tree (`AugmentedPhy`
/ Newick), never a dense `Σ_phy` (that would defeat O(p)). Implemented the
bench-accurate `(phy, y)` API. Multi-trait (independent per trait) and coupled
multivariate are follow-ups (bench `P4_multitrait.jl` / `Pmv_multivariate.jl`).

## Verification

| Check | Result |
|-------|--------|
| O(p) `_phylo_negll` == dense negll (3 param points) | ✅ rtol 1e-8 |
| profiled μ̂ == dense GLS | ✅ rtol 1e-8 |
| fit-negll == dense negll at the fitted params | ✅ rtol 1e-6 |
| MLE optimality (fit negll ≤ negll at true params) | ✅ |
| profiled path ≡ joint (non-profiled) path | ✅ |
| Newick-string method + 256-tip tree converges | ✅ |
| Full core suite (`test/runtests.jl`) | ✅ exit 0, no regressions |

Dense reference Σ built from the same node machinery
(`Σ_phy_unit = (Q_cond⁻¹)[leaves, leaves]`), so the cross-check is exact and
deterministic.

## What did not go smoothly

- Two dispatch traps in the shared `runtests.jl` `Main` scope: an earlier test
  file shadows the exported `augmented_phy`/`build_node_perspecies`, so my test's
  `phy` was a *different* `AugmentedPhy` type → MethodError. Fixed by qualifying
  `GLLVM.augmented_phy` / `GLLVM.build_node_perspecies` in the test. (A real
  shared-scope hazard worth noting for future test authors.)
- Newick must be strictly bifurcating; a root trifurcation errored in
  `augmented_phy`.

## Definition of Done

Implementation ✅ · tests pass (core; Pkg.test verifying on CI) ✅ · docstrings on
both exports ✅ · check-log updated ✅ · this after-task ✅ · Rose pre-publish
deferred to the v0.2.0 tag.

## Next

- `predict`/`residuals`/`summary` for the fits (#9); multi-trait wrapper;
  orphan-test wiring (#8). Then a benchmark of the *fit* (not just the gradient)
  at scale.
