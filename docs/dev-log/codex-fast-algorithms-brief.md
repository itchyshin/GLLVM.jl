# Codex hand-off brief — GLLVM.jl fast-algorithm track

*Drafted 2026-05-31 for the Codex group (engine/performance lane). The Claude
orchestration fleet owns the families, structured-covariance, formula front-end,
and docs tracks; this brief carves out the **fast-algorithm** work for Codex so the
two teams don't collide.*

## Context

GLLVM.jl now ships **7 response families** (Gaussian, Binomial, Poisson,
NegativeBinomial, Beta, Ordinal, Gamma), plus animal-model / spatial structured
covariance (`Σ_phy`). A two-part family tier (hurdle / zero-inflated / delta) and
non-Gaussian structured dependence are in active build.

**Already done — do NOT re-attempt:** the phylogenetic **O(p) gradient** is
complete (`src/node_gradient.jl`, benchmarked to p = 10⁴). A prior scoping pass
confirmed the Takahashi selected-inverse swap is **moot** for the phylo_unique case
(node-frame already O(p)) and **infeasible-as-stated** for the general multi-axis
case (dense p×p Hadamards make it method-independent). Skip it.

## Target #1 — analytic / AD gradients for the non-Gaussian fitters (biggest open win)

Every non-Gaussian fitter — `fit_poisson_gllvm`, `fit_nb_gllvm`, `fit_beta_gllvm`,
`fit_gamma_gllvm`, `fit_ordinal_gllvm`, `fit_binomial_gllvm` — optimises with
**`autodiff = :finite`** (finite-difference gradients in Optim). That costs
O(n_params) extra Laplace-marginal evaluations per L-BFGS step and is the dominant
fit-time cost today. Replace it with either:

- **ForwardDiff through the Laplace marginal**, where the inner Fisher-scoring
  mode-finder is AD-clean (dense `\` + `logdet` differentiate fine); or
- **the envelope / implicit-function approach** (TMB-style, Kristensen et al. 2016 —
  already a package reference): the inner score is zero at the mode, so the outer
  gradient avoids differentiating the Newton iterations.

The Gaussian fitter already uses ForwardDiff and the phylo fitter an analytic O(p)
gradient — mirror those patterns. Expect a large per-fit speedup; this is the
current user-facing bottleneck.

## Secondary targets (priority order)

1. **Scalable determinant for non-Gaussian structured dependence.** The new
   structured-RE marginal (design: `docs/superpowers/specs/2026-05-31-nongaussian-structured-dependence-design.md`)
   uses a dense O(p³) `log det S_u` for small/medium p. The large-p path
   (stochastic-Lanczos / Hutchinson probing, ≈ O(npK)) is the open fast algorithm.
   **Coordinate** — slice 0 of that subsystem is being built now.
2. **Whole-engine Allocs.jl + JET pass** (roadmap Phase 1.3): eliminate hot-loop
   allocations, prove type stability across `src/`.
3. **General K_aug ≥ 2 O(p) phylo gradient** — research-grade; needs a matrix-free
   edge-incidence or multi-axis node-frame formulation, *not* a selected-inverse
   swap. Only after (1)/(2).

## Lane / don't-collide

- A Claude `engine-perf` agent owns constant-factor cleanups in
  `src/sparse_phy_grad.jl` and `src/em_phylo.jl` (the `_CinvM` / `chol_Qcond` /
  `X_G` wins). **Stay out of those two files.**
- Codex lane: the **fitter gradients in `src/families/*.jl`**, benchmarking, and
  the scalable determinant (target #1 of secondaries).
- Base off the latest `main` and rebase often — it is moving fast.

## Discipline (hard rules)

- Verify any AD/analytic gradient matches the finite-difference gradient to ≤ 1e-6
  on a small case.
- Keep REML language Gaussian-only. HSquared-style AI-REML is a later scouting
  target for exact Gaussian variance-component cells; do not describe
  non-Gaussian Laplace acceleration as REML/AI-REML.
- Keep every family's recovery test **and** the full suite green — **no tolerance
  widening**.
- Benchmark before/after and report the per-fit speedup.
- slice → PR → local `Pkg.test()` → merge; stage files by name (never `git add -A`);
  one concern per commit.
- No engine surgery on R's `gllvmTMB` (read-only reference); no push without the
  maintainer's go.
