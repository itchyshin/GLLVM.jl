---
name: julia-likelihood-review
description: Review Julia GLLVM likelihoods and parameterizations before merging.
metadata:
  authors:
    - Gauss
    - Karpinski
  applies_to: GLLVM.jl (Gaussian + phylogenetic GLLVM, Julia ≥ 1.10)
  successor_to: drmTMB/.agents/skills/tmb-likelihood-review (TMB C++ predecessor)
---

# Julia Likelihood Review

Use this skill for any change to Julia likelihood code, density evaluations,
parameter packing/unpacking, profile-out logic, or the Cholesky/precision
substrate that the likelihood depends on. In this repo that means anything
under `src/likelihood.jl`, `src/likelihood_sparse_phy.jl`,
`src/likelihood_contrasts.jl`, `src/likelihood_edge_incidence.jl`,
`src/packing.jl`, `src/profile.jl`, `src/lowrank_cholesky.jl`,
`src/sparse_phy.jl`, `src/sparse_phy_grad.jl`, `src/em_phylo.jl`, and the
forthcoming non-Gaussian Laplace path (Phase 3).

This skill is a Julia replacement for the C++ / TMB-era
`tmb-likelihood-review` skill in `drmTMB`. There is no TMB AD tape in this
package: the Gaussian marginal is closed-form, the phylogenetic precision is
sparse-Cholesky via CHOLMOD, and gradients are either analytic (e.g.
`sparse_phy_grad.jl`) or `ForwardDiff` over the closed-form objective.
Enzyme is a possible future option for the dense path; CHOLMOD is the
reason it is not the default today.

## Scope

This review covers correctness, numerical stability, parameterisation, type
stability, and AD compatibility for the *marginal* log-likelihood and its
components. It does **not** cover initialisation, optimisation strategy,
CI construction, or the simulator — those have their own review tracks.

## Five audit dimensions

Every likelihood change should be evaluated against all five. For trivial
edits (renaming a local, fixing a typo in a comment), say so and skip; for
anything that touches arithmetic, walk through each dimension explicitly.

### (a) Correctness vs symbolic derivation

- Re-derive the marginal symbolically before editing. For the dense
  Gaussian path, the marginal at fixed `Λ`, `Ψ`, `σ_eps` is
  `−½ [ n·log|Σ_y| + tr(Σ_y⁻¹ S) + n·p·log(2π) ]`
  with `Σ_y = ΛΛᵀ + Ψ + σ_eps² I` and `S = YᵀY / n` (centred). Match the
  implementation in `gaussian_marginal_loglik` against this expression term
  by term — do not skip the `n·p·log(2π)` constant, even if the optimiser
  does not care; downstream LR tests and AIC do.
- For the sparse phylogenetic path (`likelihood_sparse_phy.jl`), the
  augmented-state derivation (Hadfield & Nakagawa 2010 *JEB* appendix) gives
  a quadratic form in the joint precision `Q_aug`. Check that the log
  determinant uses `logdet(cholesky(Q_aug))` (or `logabsdet`), not
  `log(det(...))`; the latter overflows for large `p`.
- For the contrasts path (`likelihood_contrasts.jl`, Felsenstein 1985 /
  Lande 1979), each contrast is independent with branch-length-scaled
  variance; the sum of `n_internal − 1` contrasts must equal the
  augmented-state quadratic form to within `1e−10` on the test fixtures.
  This cross-check is the gold standard — if any new representation does
  not reproduce the existing ones to that tolerance on a fixed dataset,
  the change is wrong.
- For the σ_eps profile-out (`profile.jl`, lme4 / MixedModels.jl pattern),
  verify the optimal `σ̂_eps²` is `tr(R) / (n · p)` where `R` is the
  appropriate residual quadratic form. The concentrated objective should
  drop additive constants only after they have been folded into the
  reported `loglik` field.

### (b) Numerical stability

- All density evaluations must work in the log domain. No naive `exp` /
  `sum` patterns. If a `logsumexp` is needed (e.g. for forthcoming mixture
  / hurdle families), use `LogExpFunctions.logsumexp`, not a hand-rolled
  loop.
- For determinants, use `logdet(cholesky(A))` or `logabsdet(F)` where `F`
  is the factorisation. `log(det(...))` is forbidden for any `p ≥ 50`.
- For positive-definite assembly:
  - Dense low-rank-plus-diag (`lowrank_cholesky.jl`): always go through
    the Woodbury / matrix-determinant lemma route. Forming `Σ_y` densely
    just to factor it is `O(p³)` and unacceptable above the smallest
    benchmark cells.
  - Sparse phylogenetic (`sparse_phy.jl`): the augmented precision must be
    assembled in CSC form and passed to `cholesky()` (CHOLMOD), not
    `lu()`. If CHOLMOD reports a `PosDefException`, do not catch and retry
    with a jitter — the failure means the parameterisation is wrong.
- For low-rank Cholesky updates, verify the residual
  `‖L Lᵀ − (ΛΛᵀ + D)‖_F` is `≤ 1e−10 · ‖D‖_F` on a fixed seed before
  declaring a refactor complete.
- Guard against `−Inf` log-likelihoods at the optimiser's edge: if a
  Cholesky fails for a parameter the optimiser is exploring, return
  `oftype(loglik, -Inf)` rather than throwing. Throwing forces the
  optimiser to restart and loses progress.

### (c) Parameterisation

- **Positive parameters on log scales**: σ_eps, Ψ diagonals, NB shape `r`
  (Phase 3), beta precision `φ` (Phase 3), per-branch evolution rates
  (`relaxed_clock.jl`). The optimiser should *never* see raw positive
  parameters; the back-transform should happen inside the marginal.
- **Bounded correlations on Fisher-z**: any `ρ ∈ [−1, 1]` (cross-trait
  correlation, derived from `Σ_y` off-diagonals) goes through `atanh`
  for inference and Wald CI, then `tanh` for reporting. See
  `confint_derived_wald.jl` for the established pattern; new bounded
  quantities should match.
- **Bounded `[0, 1]` quantities on logit**: communality `c²`, ICC,
  phylogenetic signal `H²`. Same pattern as Fisher-z, with `logit` /
  `logistic`.
- **Loadings `Λ` are signed and identified by lower-triangular structure**
  (see `packing.jl`). Do *not* impose positivity on the diagonal — that
  is a different identification convention from what the rest of the
  package and the R reference use. If you find yourself wanting to, stop
  and ask the maintainer; this is the kind of silent convention drift
  that breaks downstream consumers.
- **Profile-out parameters must not appear in the packed parameter
  vector** at all. If `σ_eps` is being profiled, it cannot also be a
  free coordinate; double-counting it produces a flat ridge.

### (d) Type stability

- Run `JET.@report_opt gaussian_marginal_loglik(...)` (and the analogue
  for any new marginal) before merging a change that touches the
  arithmetic. Zero warnings is the target. If JET reports `Union`
  return types from your edit, the edit is wrong — usually a missing
  `oftype` / `convert` on a constant.
- The marginal must be `eltype`-generic. If `θ::Vector{Float64}` works
  but `θ::Vector{ForwardDiff.Dual{...}}` does not, AD is broken.
  Concretely: avoid hard-coded `Float64` constants inside the
  arithmetic; use `one(T)`, `zero(T)`, or `oftype(x, π)` patterns.
- No `@inbounds` inside arithmetic that touches AD types unless you have
  benchmarked it and confirmed it actually helps; it routinely costs
  more than it saves once Dual numbers are in play.
- Allocations in the inner loop should be zero or near-zero. Use
  `BenchmarkTools.@btime` on the marginal at a representative `(n, p, q)`
  and compare against the pre-change baseline. A factor-of-two
  regression in allocations is a blocker.

### (e) AD compatibility

- `ForwardDiff.gradient` over the marginal must succeed at the warm-start
  point and at a perturbed point. If it fails, the most common cause is a
  hard `Float64` cast or a `sqrt` of something that briefly goes
  negative.
- The CHOLMOD path is **not** ForwardDiff-differentiable through
  `cholesky()` on a `SparseMatrixCSC{Float64}`. For the sparse phylo
  path, use the hand-coded analytic gradient (`sparse_phy_grad.jl`,
  TMB-style adjoint) rather than trying to push Duals through CHOLMOD.
  If you add a new sparse representation, you owe an analytic gradient
  unless you can prove `ForwardDiff` works end-to-end.
- Enzyme is not enabled by default. If a change is motivated by Enzyme
  compatibility, say so explicitly in the PR; do not silently rewrite
  for Enzyme and break ForwardDiff in the process.
- For the forthcoming Laplace path (Phase 3 / non-Gaussian families):
  the inner Newton solve for the latent mode must itself be AD-friendly,
  or wrapped in an implicit-function-theorem adjoint. Do not punt this
  to "we'll figure it out later" — the choice of inner solver constrains
  the outer AD strategy.

## Phase 3 (non-Gaussian) extension — additional checks

When the package grows beyond Gaussian + identity link (Poisson, binomial,
ordinal, NB, beta, hurdle / zero-inflated), the above checks still apply,
plus:

- **Link function arithmetic is in the log domain.** `logit`, `cloglog`,
  `log` links should never compute the inverse link via
  `1 / (1 + exp(−η))` literally; use `LogExpFunctions.logistic` and
  related primitives.
- **Laplace approximation correctness.** Verify the Laplace marginal
  matches a quadrature / Monte Carlo marginal at a low-dimensional
  fixture (e.g. `q = 1`, `n = 20`, `p = 3`) to within `0.01` nats. If
  it does not, the Hessian at the mode is wrong.
- **Inner solver convergence.** The latent-mode Newton step must report
  iteration count and gradient norm at convergence in a log channel the
  caller can opt into. Silent non-convergence is the single most
  common Laplace-GLLVM failure mode in the wild.
- **Dispersion parameters.** NB `r` and beta `φ` go on log scale; verify
  the marginal is finite and AD-differentiable at `log(r) = −5` and
  `log(r) = 5` (i.e. across the Poisson and overdispersed limits).
- **Boundary behaviour.** Binomial with all-zero or all-one columns;
  Poisson with all-zero columns; ordinal with empty categories. The
  marginal should either skip or return a finite value with a warning,
  never throw.

## Cross-representation invariants (phylo paths)

The three phylogenetic representations
(`likelihood_sparse_phy`, `likelihood_contrasts`, `likelihood_edge_incidence`)
must return the same log-likelihood to within `1e−10` on the test fixtures.
Any change to one of them is incomplete until the cross-check is run and
passes. The check belongs in `test/` alongside the change, not as a
manual one-off.

## Profile-out invariant

For any parameter being profiled (currently `σ_eps`, possibly more in
Phase 3): the concentrated marginal at `σ̂_eps(θ_rest)` must equal the
joint marginal evaluated at `(θ_rest, σ̂_eps(θ_rest))` to within
machine precision. Add a unit test that asserts this if you touch
`profile.jl`.

## Review checklist (use this verbatim in PRs)

- [ ] Symbolic derivation written out in the PR description, term by
      term, and matched to the code.
- [ ] All positive parameters on log scale; bounded parameters on the
      appropriate transform (Fisher-z / logit); profile-out parameters
      absent from the packed vector.
- [ ] `logdet(cholesky(...))` everywhere; no `log(det(...))`; no naive
      `exp` / `sum` outside log-domain helpers.
- [ ] Cross-representation invariant holds across the three phylo paths
      to `1e−10` on the standard fixture.
- [ ] Profile-out invariant verified (if applicable).
- [ ] `JET.@report_opt` clean on the touched marginal.
- [ ] `ForwardDiff.gradient` succeeds at warm-start and at a perturbed
      point (or, for sparse CHOLMOD paths, the analytic gradient is
      updated and its finite-difference check passes to `1e−6`).
- [ ] `BenchmarkTools.@btime` on the marginal at the representative
      `(n, p, q)` cell shows no regression in time or allocations
      beyond noise.
- [ ] Full test suite (`julia --project=. test/runtests.jl`) green, with
      the actual pass tally pasted in the PR.
- [ ] Simulation recovery: on the standard ADEMP cell for the change,
      bias and coverage at `n_sims = 200` are within the pre-registered
      tolerances. Negative or mixed results reported plainly.
- [ ] Boundary and weak-identification cases tested: `q = p`,
      `q = 0`, all-zero column (Phase 3 families), perfectly collinear
      traits, ultrametric tree with zero internal branch lengths.

## Why this skill exists

The Gaussian marginal in this package is a 50-line closed-form
expression. It is short enough that "I'll just eyeball it" is tempting
and wrong. The five-dimension audit is what keeps the 340× speedup
honest — every term in that 50-line function is doing structural work,
and silent drift in any one of them (a missing `log(2π)`, a hard
`Float64`, a `log(det(...))` snuck back in) costs orders of magnitude
in either accuracy or speed. The phylo paths are even less forgiving:
the augmented-state precision matrix is sparse for a reason, and
breaking that sparsity is a one-line change that quietly turns an
`O(p)` cost into `O(p³)`.

When in doubt, prefer the dense reference path
(`gaussian_marginal_loglik`) as the ground truth for correctness, and
the sparse phylo path (`likelihood_sparse_phy`) as the ground truth for
speed. Any new representation has to match both.
