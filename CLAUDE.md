# CLAUDE.md — guidance for AI coding agents in this repo

This file orients AI coding agents (Claude Code, Codex, etc.) to the GLLVM.jl repo conventions and current state. The maintainer is Shinichi Nakagawa (itchyshin).

## What this package is

GLLVM.jl is a Julia implementation of the **Gaussian + phylogenetic** Generalised Linear Latent Variable Model (GLLVM) class. It is a from-scratch port of the Gaussian subset of R's `gllvmTMB`, prioritising fitting speed at moderate-to-large p (species count) and rigorous inference. Headline result: ~340× per-fit median speedup over R/`gllvmTMB` while reproducing point estimates and likelihoods to machine precision.

**Status**: v0.1.0 pilot — **Gaussian only**. Non-Gaussian families (Poisson, binomial, ordinal, negative binomial, beta, hurdle/zero-inflated) are **not yet implemented**. Expanding to the full GLM family is the next planned stage; see "Planned next" below.

**Size**: 32 commits, 25 source files, 14 test files, 256 passing tests as of v0.1.0.

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

Phylogenetic representations (all compute the identical log-likelihood to machine precision; differ in cost and AD compatibility):
- `sparse_phy.jl` + `likelihood_sparse_phy.jl` — augmented-state sparse phylogenetic precision (Hadfield & Nakagawa 2010 *JEB* appendix), via CHOLMOD — **the fastest path**, ~O(p), but CHOLMOD blocks generic forward-mode AD
- `phylo_contrasts.jl` + `likelihood_contrasts.jl` — Felsenstein independent contrasts (Felsenstein 1985; Lande 1979)
- `edge_incidence.jl` + `likelihood_edge_incidence.jl` — edge-node incidence representation: matrix-free Q = B·W·Bᵀ; per-branch evolution rates naturally on `diag(W)`

Fitting at scale (closes the fast-and-fittable gap):
- `sparse_phy_grad.jl` — hand-coded analytic gradient for the sparse phylo path (TMB-style; the maintainer-approved Takahashi O(p) selected-inverse swap is the next planned optimisation, currently O(p²))
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

The maintainer has indicated this package should expand from **Gaussian-only** to the **full GLM family**: Poisson, binomial, ordinal, negative-binomial, beta, then hurdle / zero-inflated / delta families. That expansion will require:

- Link function infrastructure (`logit`, `log`, `probit`, `cloglog`, …). The current Gaussian path uses identity, so no link layer exists yet.
- **Laplace approximation** for the marginal likelihood. Gaussian + identity admits a closed-form marginal; non-conjugate families do not, so a Laplace step is unavoidable.
- Dispersion parameters where relevant (NB shape `r`; beta precision `φ`).
- A non-Gaussian-aware init (PPCA assumes Gaussian; either generalise or accept a slower init).
- Updated ADEMP simulation cells covering each new family.

Before starting that expansion, **study the design pattern** the Gaussian path follows: the marginal log-likelihood is a single function (`gaussian_marginal_loglik`), and `fit_gaussian_gllvm` is a thin driver. The non-Gaussian path likely wants `<family>_marginal_loglik_laplace` and `fit_<family>_gllvm` mirrors, with shared packing / Cholesky / init helpers.

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
