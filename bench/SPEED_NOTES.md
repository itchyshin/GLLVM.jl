# Speed roadmap — "speed against myself"

Companion notes to `bench/speed_bench.jl`. This captures the speed work for the
non-Gaussian (Laplace) GLLVM path: what is already landed, what is bit-exact and
ready, and the algorithmic roadmap from the literature. None of this changes the
maximised likelihood — every item is **exact-preserving** (same optimum, fewer
or cheaper operations), so the benchmark's `Δloglik` column should stay at noise
level for each one.

Run the benchmark with:

```bash
julia --project=. bench/speed_bench.jl   # not run in CI — maintainer tooling
```

## 1. Bit-exact allocation wins (no math change)

These cut allocated bytes (the `MB alloc` column) without touching the answer:

- **Buffer reuse in the Laplace mode-finder.** The inner Newton solve that finds
  the conditional mode `ẑ` per site re-derives the same-shaped work arrays
  (gradient, Hessian, step) every outer optimiser step. Pre-allocate them once
  per fit and reuse across steps and reps; the mode-finder is the hot loop.
- **Hoist per-call `ones()` / `fill()` allocations.** Default-trial matrices
  (e.g. `N = ones(p, n)` in the binomial path) and other per-call constant
  buffers should be built once and threaded through, not re-allocated inside the
  marginal-likelihood closure that the optimiser calls hundreds of times.

These are pure plumbing: land them, confirm `MB alloc` drops and `Δloglik = 0`.

## 2. Analytic-gradient default decision

The GLM fitters take `gradient::Symbol = :finite`; `:analytic` is implemented for
Poisson / NB / Binomial / Gamma / Beta (`src/laplace_grad.jl` + the per-family
`*_laplace_grad`). Finite differences cost ≈ `2·nθ` marginal evaluations per
optimiser step (`nθ = p + p·K − triangular + dispersion`); the analytic adjoint
costs ≈ **1** marginal-eval-equivalent per step (one mode solve + one reverse
pass), so the gap widens with `p` and `K`.

**Action:** `speed_bench.jl` times `:finite` vs `:analytic` side by side and
prints `Δloglik`. If `:analytic` is consistently faster and `Δloglik` stays at
noise level across the grid, **flip the package default to `:analytic`**. It is
opt-in today only out of caution; the benchmark is the evidence to flip it.

## 3. Exact-preserving algorithmic roadmap

Ordered roughly by expected payoff. "Have" = already in GLLVM.jl; "Need" = to do.

- **Reverse-mode / implicit-function adjoint of the Laplace marginal.**
  Differentiate the Laplace objective with the implicit-function theorem at the
  inner mode so the outer gradient does not back-propagate through the Newton
  iterations — the TMB/RTMB pattern (Kristensen et al. 2016). *Have:* the
  analytic Poisson Laplace gradient already uses an AD + implicit-step adjoint
  (`src/laplace_grad.jl`, issue #65). *Need:* extend the same implicit-step
  treatment uniformly across all Laplace families and make it the default (see §2).

- **Takahashi / Erisman–Tinney selected inverse for the sparse-phylo log-det
  gradient.** The phylogenetic log-det derivative needs only the diagonal (and
  the sparsity-pattern entries) of the inverse, computable in ~O(p) by the
  selected-inverse recursion instead of the current O(p²) dense selected inverse
  (Takahashi 1973; Erisman & Tinney 1975). *Have:* the sparse-phylo path
  (`src/sparse_phy*.jl`) and a `takahashi_selinv.jl` scaffold pulled in by
  `sparse_phy_grad.jl`. *Need:* land the maintainer-approved O(p) swap on the hot
  gradient path; `SparseInverseSubset.jl` is a reference implementation.

- **Fisher-scoring inner Newton.** Replace the observed-information Hessian in the
  inner mode solve with the (cheaper, always-PD) Fisher information / expected
  Hessian. Same fixed point (same mode, same marginal), more robust and often
  fewer inner iterations. *Need:* a Fisher-scoring variant of the family inner
  Newton (`newton_maxiter` / `newton_tol` already thread through the fitters).

- **SQUAREM / Anderson acceleration for the EM / VA paths.** Extrapolate the
  fixed-point EM/VA updates to cut outer iterations (Varadhan & Roland 2008;
  Walker & Ni 2011 for Anderson). *Have:* `src/em_squarem.jl` (SQUAREM over the
  Gaussian/phylo EM). *Need:* apply the same accelerator to the non-Gaussian VA
  (`src/families/variational*.jl`) updates.

## Substrate already in place

Worth not re-deriving — these speed primitives are landed and exact:

- **Woodbury low-rank Cholesky** for `ΛΛᵀ + diag` (`src/lowrank_cholesky.jl`).
- **Closed-form PPCA init** as a warm start (`src/ppca_init.jl`; Tipping &
  Bishop 1999) — keeps the optimiser's iteration count down.
- **EM with SQUAREM** (`src/em_fa.jl`, `src/em_squarem.jl`).
- **Sparse-phylo augmented-state precision** via CHOLMOD (`src/sparse_phy.jl`;
  Hadfield & Nakagawa 2010) — the ~O(p) phylo path.

## References

- Kristensen, Nielsen, Berg, Skaug & Bell 2016 — TMB (Laplace + sparse-Cholesky
  analytic adjoint), *J. Stat. Soft.*
- Takahashi 1973; Erisman & Tinney 1975 — selected inverse for sparse matrices.
- Tipping & Bishop 1999 — probabilistic PCA closed form, *JRSS B*.
- Varadhan & Roland 2008 — SQUAREM acceleration of EM, *Scand. J. Stat.*
- Walker & Ni 2011 — Anderson acceleration for fixed-point iteration.
- Hadfield & Nakagawa 2010 — augmented-state sparse phylogenetic precision,
  *J. Evol. Biol.* appendix.
