---
name: add-simulation-test
description: Add ADEMP-style simulation-based parameter-recovery tests for GLLVM.jl models using Test.jl and StableRNGs.
---

# Add a Simulation Test

Use this skill when adding or extending recovery tests for the Gaussian (and
future GLM-family) GLLVM models in this repo. Tests live under `test/` and are
run via `julia --project=. test/runtests.jl` (not `Pkg.test()`; see CLAUDE.md).

## Framework

- Use `Test.jl`: wrap each scenario in `@testset` and assert with `@test` /
  `@test_throws`.
- Use **`StableRNGs.StableRNG(seed)`** for every stochastic step — not
  `Random.MersenneTwister`. `StableRNGs` is reproducible across Julia minor
  versions; `MersenneTwister` is not, so a seeded `MersenneTwister` test can
  silently change tally on a Julia upgrade.
- Tag long simulation sweeps behind `ENV["GLLVM_PERF_TESTS"]` (the existing
  pattern in this repo) so routine `runtests.jl` stays fast and deterministic.

## Procedure

1. **Specify the data-generating process (DGP).** Write down, in the test
   header comment, the symbolic form of the model: loadings Λ, residual scale
   σ_eps, latent dimension d, sample size n, species count p, and — for phylo
   tests — the tree and per-trait λ (or H²). The implementation must match
   this symbolic form 1:1; recovery tests catch the mismatch.
2. **Simulate data from known parameters** using `simulate.jl` (or a local
   helper) with a `StableRNG(seed)`.
3. **Fit the intended model** (`fit_gaussian_gllvm`, `em_fit_phylo`, …).
4. **Check convergence diagnostics** (`Optim.converged`, gradient norm,
   non-degenerate Λ).
5. **Check estimates on the modelled scale**: signed loadings up to the
   identifiability rotation, log-σ for scales, and — where relevant — derived
   quantities (Σ_y entries, communality c², phylogenetic signal H²).
6. **Check CI coverage** on the response / derived scale: nominal 95% Wald,
   profile, and parametric-bootstrap intervals should cover the true value at
   the nominal rate over R replicates (R small for CI-time tests; large only
   under `GLLVM_PERF_TESTS`).
7. **Test edge cases** that are scientifically likely or numerically risky
   (list below).
8. **Test malformed inputs** with `@test_throws`: non-PSD Σ_y target, ragged
   `Λ`, phylogeny / data row mismatch, negative σ_eps in user-supplied init.

## Symbolic ↔ implementation alignment

Recovery tests are the maintainer-approved way to verify that the symbolic
likelihood (closed-form Gaussian marginal; sparse phylo augmented-state;
Felsenstein contrasts; edge-incidence Q = B·W·Bᵀ) and the in-code likelihood
agree. When you add a new representation or a Laplace step for a non-Gaussian
family, add a recovery test that fits from a `StableRNG(seed)`-simulated draw
and checks the point estimate against the truth to a tolerance that is *tight
enough to fail if the symbolic form has been transcribed wrong*. Do not widen
the tolerance to make a failing test pass — fix the bug.

## Required edge cases

- **Trees**: balanced (low star-likeness) and caterpillar / pectinate (high
  star-likeness, near-singular Q without regularisation).
- **Shape extremes**: `n = p`, `p = 1` (degenerate latent), and `p` large
  (≥ 100, behind `GLLVM_PERF_TESTS`).
- **Scale extremes**: σ_eps small and large; loadings near-orthogonal vs
  near-collinear.
- **Latent dimension**: `d = 1` and `d > 1` with rotation-invariant checks
  (compare ΛΛᵀ, not Λ entry-wise, unless you fix the rotation).
- **Phylogenetic signal**: H² near 0, intermediate, and near 1 per trait.
- **Missing data** (when the relevant family supports NA handling).
- **Malformed inputs** for `@test_throws`: tree-data row mismatch, bad init,
  non-conformable Λ.

## Recovery target

For each scenario, report or assert:

- **Bias** of key point estimates over R replicates: ``mean(theta_hat) - theta_true``.
- **CI coverage** at the nominal 95% level for at least one derived /
  response-scale quantity (e.g., a Σ_y entry or H²).
- For sparse-phylo / EM paths: a Louis-formula vs dense-Hessian SE agreement
  check (the existing `EM-Louis vs dense SE` gate, currently at 1e-2 — see
  `test/runtests.jl` history).

## Reporting framework

Follow **ADEMP** (Morris, White & Crowther 2019, *Stat Med*) — explicitly
state the **A**ims, **D**ata-generating mechanism, **E**stimands, **M**ethods,
and **P**erformance measures in the test header — and the transparent-
reporting items of **Williams, Nakagawa & Hector 2024** (*Methods Ecol Evol*):
state the random-seed mechanism (`StableRNG(seed)`), the number of replicates
R, and the Monte-Carlo SE of every performance estimate. ADEMP cells that
correspond to long sweeps belong behind `GLLVM_PERF_TESTS`; the cells in
routine `runtests.jl` should be small, seeded, and fast (≤ few seconds each).

## Anti-patterns

- Loosening a tolerance to silence a failure (fix the cause).
- Using `Random.MersenneTwister` or `Random.seed!()` instead of `StableRNG`
  (breaks across Julia versions).
- Comparing rotated loadings entry-wise without aligning the rotation
  (compare ΛΛᵀ or fix the rotation first).
- Putting a 60-second sweep in routine `runtests.jl` (gate behind
  `GLLVM_PERF_TESTS`).
