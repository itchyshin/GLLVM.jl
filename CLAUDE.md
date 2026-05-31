# CLAUDE.md — guidance for AI coding agents in this repo

This file orients AI coding agents (Claude Code, Codex, etc.) to the GLLVM.jl repo conventions and current state. The maintainer is Shinichi Nakagawa (itchyshin).

## What this package is

GLLVM.jl is a Julia implementation of the Generalised Linear Latent Variable
Model (GLLVM) class. It is a from-scratch Julia twin of R's `gllvmTMB`,
prioritising fitting speed at moderate-to-large p (species count), rigorous
inference, and clear parity checks against the R reference. The Gaussian +
phylogenetic path remains the headline speed benchmark: ~340× per-fit median
speedup over R/`gllvmTMB` while reproducing point estimates and likelihoods to
machine precision.

**Status**: current development supports Gaussian plus six dense-Laplace
non-Gaussian fitters: Binomial, Poisson, Negative Binomial, Beta, Gamma, and
Ordinal. Binomial, Poisson, Negative Binomial, Beta, and Ordinal use Optim
L-BFGS with implicit dense-Laplace gradients: site modes are found once by
Fisher scoring, then the mode equation supplies `dz/dθ` without differentiating
through the Newton iterations. Gamma currently stays on direct ForwardDiff
through the dense Laplace objective until its inner mode convergence is hardened.
Two-part families and large-p non-Gaussian structured dependence are the next
algorithm tracks; see "Planned next" below.

**Size**: this repo is moving quickly; use `git rev-parse --short HEAD`,
`git status`, and `julia --project=. -e 'using Pkg; Pkg.test()'` for the live
state rather than relying on a static file-count snapshot.

## Working with this repo

### Dev environment

- Julia ≥ 1.10 (project compat). The maintainer's local Julia binary is at `~/.juliaup/bin/julialauncher`; `julia` may not be on every shell's PATH.
- Install deps: `julia --project=. -e 'using Pkg; Pkg.instantiate()'`
- **Full suite (canonical)**: `julia --project=. -e 'using Pkg; Pkg.test()'` — verified working on macOS + all CI runners (the earlier `can not merge projects` problem is resolved; root `Project.toml` carries no conflicting `[extras]`/`[targets]`). This is what CI runs, and the only invocation that loads the test-only quality tools (Aqua, JET) declared in `test/Project.toml`.
- **Quick core run**: `julia --project=. test/runtests.jl` runs the core suite directly — faster, no test-env setup, but skips the quality tools (they live in the test environment).

### Design discipline (apply throughout)

- **Surgical changes**: touch only what the task requires. Don't refactor adjacent code. Match existing style.
- **Verifiable goals**: state the goal as a test or measurable check before writing code.
- **No silent tolerance widening**: if a test breaks, fix the cause, not the test.
- **Stage by name**: `git add path/to/file` — **never** `git add -A` or `git add .` (sweeps in unintended files; we have agents working on disjoint files in parallel).
- **One concern per commit**: keep engineering changes, cosmetic renames, and chores in separate commits.
- **Verify before claiming**: run the full test suite and paste the actual pass/fail tally before reporting work as done.
- **Honest reporting**: if a result is mixed or negative, say so plainly. Don't oversell.

### Source layout (src/)

Core engine:
- `GLLVM.jl` — module + includes
- `packing.jl` — Λ pack/unpack (lower-triangular convention)
- `likelihood.jl` — Gaussian marginal log-likelihood (closed-form, dense reference)
- `lowrank_cholesky.jl` — Woodbury-based Cholesky for ΛΛᵀ + diag
- `ppca_init.jl` — Probabilistic PCA closed-form initialisation (Tipping & Bishop 1999)
- `em_fa.jl` — EM-FA solver (alternative; Rubin & Thayer 1982)
- `profile.jl` — σ_eps analytic profile-out (lme4 / MixedModels.jl pattern)
- `fit.jl` — `fit_gaussian_gllvm` (Optim LBFGS + PPCA warm-start)
- `simulate.jl` — Julia-side data simulator

Response families:
- `families/laplace.jl` — shared dense Laplace mode solve and marginal
- `families/binomial.jl`, `poisson.jl`, `negbin.jl`, `beta.jl`, `gamma.jl`,
  `ordinal.jl` — family likelihood pieces and non-Gaussian fit drivers
- `families/fit_gllvm.jl` — unified family-dispatch entry point

Phylogenetic representations (all compute the identical log-likelihood to machine precision; differ in cost and AD compatibility):
- `sparse_phy.jl` + `likelihood_sparse_phy.jl` — augmented-state sparse phylogenetic precision (Hadfield & Nakagawa 2010 *JEB* appendix), via CHOLMOD — **the fastest path**, ~O(p), but CHOLMOD blocks generic forward-mode AD
- `phylo_contrasts.jl` + `likelihood_contrasts.jl` — Felsenstein independent contrasts (Felsenstein 1985; Lande 1979)
- `edge_incidence.jl` + `likelihood_edge_incidence.jl` — edge-node incidence representation: matrix-free Q = B·W·Bᵀ; per-branch evolution rates naturally on `diag(W)`

Fitting at scale (closes the fast-and-fittable gap):
- `sparse_phy_grad.jl` — hand-coded analytic gradient for the sparse phylo path (TMB-style). Do not re-open the Takahashi selected-inverse swap as a default next step; the current fast lane is non-Gaussian gradients and scalable non-Gaussian structured dependence.
- `em_phylo.jl` — gradient-free EM fit using the fast sparse phylo solves in the E-step; conditional means double as ancestral-state BLUPs
- `em_squarem.jl` — SQUAREM extrapolation accelerator for EM (Varadhan & Roland 2008)
- `relaxed_clock.jl` — per-branch evolution-rate prototype on the edge-incidence substrate (with the hierarchical-prior identifiability caveat)

Confidence intervals:
- `confint.jl` — Wald via observed information (Hessian; log-scale back-transform for SDs, identity for signed loadings)
- `confint_profile.jl` — profile likelihood (LRT inversion + bracket-then-bisect)
- `confint_bootstrap.jl` — parametric bootstrap
- `confint_derived.jl` — profile + bootstrap CIs for derived quantities (Σ_y entries, communality c², cross-trait correlation, phylogenetic signal H²)
- `confint_derived_wald.jl` — transformed-scale Wald (Fisher-z for [−1,1] correlations, logit for [0,1] communality / ICC / H²); matches the bootstrap to within MC error at one-Hessian cost for interior-valued bounded quantities

## Planned next

The active fast-algorithm track is now about making the implemented
non-Gaussian families fast and scalable:

- Keep every non-Gaussian packed objective AD-clean and verified against a
  central finite-difference gradient to ≤ 1e-6.
- Benchmark GLLVM.jl against R `gllvmTMB` on the same simulated data across
  sample-size grids; keep the comparison harness outside package tests.
- Keep the implicit/envelope site-gradient ahead of direct ForwardDiff-through-
  Newton on medium/large cells; use direct ForwardDiff only as a verification
  oracle and small-cell fallback candidate.
- Build the large-p determinant path for non-Gaussian structured dependence.
- Add two-part / zero-inflated / delta families with ADEMP recovery tests and
  provenance notes when their likelihood parameterisations land.

## Hard boundaries

- **No engine surgery on R's `gllvmTMB`** from this repo. That R package is a read-only reference; do not modify it.
- **No push without an explicit instruction** from the maintainer. Always commit locally first; ask before pushing.
- A separate benchmark/comparison repo exists locally (mixed R + Julia, comparison-final.md report, ADEMP simulation infrastructure). It is **not** in this repo and is intentionally separate.

## Key references

- Tipping & Bishop 1999 (PPCA closed form, *JRSSB*)
- Bates et al. 2015 (lme4 / MixedModels.jl; σ_eps profile-out, sparse Z'Z, *J Stat Soft*)
- Rubin & Thayer 1982 (EM for factor analysis, *Psychometrika*)
- Hadfield & Nakagawa 2010 (augmented-state sparse phylogenetic precision, *J Evol Biol* appendix)
- Felsenstein 1985; Lande 1979 (phylogenetic contrasts)
- Kristensen et al. 2016 (TMB; the sparse-Cholesky analytic-adjoint pattern, *J Stat Soft*)
- Morris et al. 2019; Williams et al. 2024 (ADEMP simulation reporting framework)
- Takahashi 1973; Erisman & Tinney 1975 (selected-inverse recursion for sparse matrices)
