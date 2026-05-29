# PERF+ Design Memo: Beating MixedModels.jl at Gaussian GLLVM

**Date.** 2026-05-28
**Audience.** The PERF+ implementation agent, picking up after PERF round 1 (commit `24c7968` → reverse-mode AD, profile-out σ_eps, pre-allocated buffers).
**Status.** Read-only research; no source edits, no commits.
**Goal.** Identify structure-exploiting techniques that let `gllvmTMB.jl` *surpass* (not match) `MixedModels.jl` on Gaussian GLLVM fits.

The maintainer's brief: *"Be creative, be combined, be better than MixedModels (lme4-style) in Julia."* MixedModels.jl is the right ceiling to push against — it is the JuliaStats production solver, descended directly from `lme4`'s playbook. The key insight driving this memo is that **MixedModels.jl is general-purpose LMM machinery, and pays a generality tax that we do not have to pay**: our marginal likelihood is *Gaussian factor analysis with phylogenetic blocks*, a structured problem with a (partial) closed-form ML solution. The fastest possible engine exploits that.

---

## 1. MixedModels.jl architecture deep dive

### What it actually does

The fit pipeline (verified against `main` on 2026-05-28):

1. `StatsAPI.fit!(m::LinearMixedModel)` — top-level entry, `src/linearmixedmodel.jl` lines **559–636**.
2. It calls `optimize!(m; progress)` (line 480 inside the fit body) which dispatches via `optimize!(m, Val(m.optsum.backend); kwargs...)` declared in `src/optsummary.jl` ([source](https://github.com/JuliaStats/MixedModels.jl/blob/main/src/optsummary.jl)).
3. The NLopt backend lives in `ext/MixedModelsNLoptExt.jl` lines **20–45** (LMM) and **47–73** (GLMM).
4. Each NLopt iteration calls the in-place objective:

```julia
function objective!(m::LinearMixedModel{T}, θ) where {T}
    return objective(updateL!(setθ!(m, θ)))
end
```

`src/linearmixedmodel.jl` lines **1041–1043** (`objective!`), **1026–1038** (`objective`), **1481–1497** (`setθ!`), **1558–1595** (`updateL!`).

### Profile-out strategy

Profiled out **analytically** each objective evaluation:

- **β (fixed effects).** Recovered by back-substitution from the Cholesky factor `L`; see `fixef!` at lines **799–814**.
- **σ (residual SD).** Computed in closed form from the penalised residual sum-of-squares: `pwrss(m) = abs2(last(last(m.L)))` (lines **913–914**), then `σ̂ = √(pwrss/denomdf)` enters the profiled deviance:

```julia
val = logdet(m) + denomdf * (one(T) + log2π + log(pwrss(m) / denomdf))
```

(`objective`, lines **1026–1038**). When `m.optsum.sigma::Real` is supplied, σ is held fixed and not profiled.

Optimisation is therefore performed over **only θ** — the packed lower-triangular entries of the random-effects Cholesky factors Λ. For lme4-style models θ is typically O(K²) per random-effect term.

### Optimizer

**Default:** `:LN_NEWUOA`, backend `:nlopt` (`src/optsummary.jl` lines **89–90** of the `OptSummary` `@kwdef` block, comment: `# switched to :LN_BOBYQA for one-dimensional optimizations`).

**Gradient usage:** **None.** Verbatim from the NLopt backend ([source](https://github.com/JuliaStats/MixedModels.jl/blob/main/ext/MixedModelsNLoptExt.jl)):

```julia
function obj(x, g)
    isempty(g) || throw(ArgumentError("g should be empty for this objective"))
    ...
end
```

The signature accepts a gradient slot for NLopt API compatibility but throws on any caller that asks the objective to fill it. NEWUOA / BOBYQA / COBYLA / Nelder-Mead / PRAXIS are all **derivative-free** (`optimizers(::NLoptBackend)` returns the list `[:LN_NEWUOA, :LN_BOBYQA, :LN_COBYLA, :LN_NELDERMEAD, :LN_PRAXIS]`).

ForwardDiff support exists in `ext/MixedModelsForwardDiffExt.jl` via the `fd_` wrappers declared in `src/derivatives.jl`, but the docstring (`FORWARDDIFF` const, `src/derivatives.jl` lines 1–7) explicitly flags it experimental and the implementation is "slower and much more memory intensive". **Gradients are diagnostic, not part of the fit loop.** This is the single biggest opening for us.

### Cholesky reuse

`updateL!` (lines **1558–1595**) rebuilds the blocked lower-Cholesky factor `m.L` from `m.A` and the current Λ blocks **every objective call**. The inner loop:

```julia
for j in 1:(k + 1)
    Ljj = L[kp1choose2(j)]
    for jj in 1:(j - 1)
        rankUpdate!(Hermitian(Ljj, :L), L[block(j, jj)], -one(T), one(T))
    end
    cholUnblocked!(Ljj, Val{:L})
    ...
    for i in (j + 1):(k + 1)
        Lij = L[block(i, j)]
        for jj in 1:(j - 1)
            mul!(Lij, L[block(i, jj)], L[block(j, jj)]', -one(T), one(T))
        end
        rdiv!(Lij, LjjT')
    end
end
```

This is a **full blocked Cholesky from scratch**: rank updates against previous off-diagonal blocks, then `cholUnblocked!` on the diagonal, then triangular solves to fill the next row. There is no warm-start, no low-rank update from the previous θ, no Schur-complement reuse. The `A` matrices are pre-allocated and immutable across iterations; only `L` and `Λ` blocks change.

**Storage:** sparse when grouping factors create sparsity (`BlockedSparse` in `src/linalg.jl`, `src/Xymat.jl`, `src/arraytypes.jl`), dense otherwise. For a fully-crossed design with a low-dimensional Z'Z structure the dense path dominates.

### Pre-allocation

`m.A`, `m.L`, `m.reterms`, `m.Xymat` are all owned by the `LinearMixedModel` struct. `updateL!` writes into pre-existing block storage via `copyto!`, `mul!`, `rankUpdate!`, `rdiv!`, `cholUnblocked!` — entirely in-place. This is the pattern PERF round 1 is already adopting; we have parity here.

### Hot-loop cost

Per objective call, dominated by `updateL!`. For a single-term scalar RE on n observations with q levels, the kernel work is O(q) (sparse banded). For a vector RE with K random slopes, it scales as O(q · K²) plus a K³ Cholesky on the diagonal block. The blocked Cholesky over k random-effect terms is O((sum_j q_j K_j²)) per evaluation. NEWUOA typically needs 40–200 calls.

### What MixedModels.jl does *not* do (our openings)

1. **No gradient-based optimisation.** Each NEWUOA iteration is O(d²) in the quadratic-model bookkeeping where d = dim(θ). For our J3 layout d grows as p·K + 2p + p·K_phy + p; a gradient-driven LBFGS converges in linear-in-d cost per step and far fewer steps for d ≳ 20.
2. **No closed-form initialisation.** They start from a sensible-but-generic point (Λ = I, then optimise from scratch). They cannot use PPCA SVD initialisation because LMM is too general for it.
3. **No exploitation of low-rank dense factor structure.** `BlockedSparse` is designed for the sparse Z'Z that crossed/nested grouping factors generate, not for the **dense low-rank** Λ_B Λ_B' that defines a GLLVM marginal.
4. **No closed-form Woodbury per call.** Their Cholesky is on the whole augmented system; ours is K×K via Woodbury (`src/likelihood.jl` lines 184–202). For p ≫ K (our regime) Woodbury is dramatically cheaper.
5. **No analytic profile of additional variance components.** Only σ_eps and β are profiled. We can profile out more (Section 3 discusses).
6. **No structure-aware warm start across optimiser iterations.** Each `updateL!` is a cold rebuild.

### Published benchmarks (Section 6 details)

Per `docs/src/benchmarks.md` (2018 numbers, Intel i5-3570, Julia 1.0): Dyestuff 0.83 ms, sleepstudy 4.83 ms, InstEval (complex) 1.999 s, kb07 (simple) 3.488 s, d3 (complex) 49 s, ml1m 37 s. These are LMM problems, not GLLVM, but they set the bar for "Julia mixed-effects state of the art" on small/medium problems.

---

## 2. Probabilistic PCA / Factor Analysis closed-form solvers

### The mapping

For the J1 case (no W tier, no diag RE, no phy block, no β) our marginal is:

```
y_s ~ N(0, Λ_B Λ_B' + σ²_eps I_p),    s = 1, ..., n
```

This is **exactly the PPCA model** of Tipping & Bishop (1999, JRSSB 61:611–622). The maximum-likelihood solution is **closed form**:

```
σ̂²_ML = (1/(p − K)) · Σ_{k=K+1}^p s_k                             [TB eq. 8]

Λ̂_ML = U_K · (S_K − σ̂²_ML · I_K)^{1/2} · R                       [TB eq. 7]
```

where `S = (1/n) Y Y'` is the sample covariance (p × p), `U_K` are its top-K eigenvectors, `S_K = diag(s_1, ..., s_K)` are the top-K eigenvalues (sorted descending), and `R` is an arbitrary K×K orthogonal rotation (the rotational indeterminacy that the lower-triangular constraint in `unpack_lambda` resolves).

**Cost:** one p×p covariance build (O(n p²)) and one eigendecomposition (O(p³)). **No iteration.** For our typical p ∼ 5–50 and n ∼ 200–5000, this is ~milliseconds. Compare to ~20–50 LBFGS iterations of the current engine, each costing O(p² K + p K²) plus AD overhead.

### Sanity-check derivation

Worked example for the report: p = 3, K = 1, sample-covariance eigenvalues `[4, 2, 1]`.

- σ̂² = (1/(3 − 1)) · (2 + 1) = **1.5**
- Λ̂'s leading nonzero (in the rotated basis): √(s_1 − σ̂²) = √(4 − 1.5) = √2.5 ≈ **1.5811**

Both numbers are unique up to the sign convention and the orthogonal rotation `R`.

### Why this is a massive opening

MixedModels.jl cannot use this. PPCA is specific to dense, low-rank, p-dimensional Gaussian factor structure with constant-diagonal noise. lme4 / MixedModels target arbitrary sparse Z'Z. Our GLLVM lives entirely in the PPCA regime for J1, and very close to it for J2/J3 (Section 3).

### Generalisation to non-constant diagonal (J2-A-WD)

When `d_total[t]` is per-trait (W tier + diag RE), the marginal becomes

```
y_s ~ N(0, Λ_B Λ_B' + diag(d_total))
```

This is the **classical factor analysis** model with diagonal Ψ. The Tipping & Bishop closed form does **not** apply: when Ψ is not σ² I the principal eigenvectors of the sample covariance are not the ML solution. However, ML factor analysis admits a **closed-form EM** (Section 3) that has converged-fast properties closely related to PPCA: an EM step is essentially "rotate, threshold eigenvalues, recompute residual variances". The PPCA closed form is the **exact M-step at iteration 1 of EM if Ψ = σ² I**, and remains an excellent warm start for FA-EM or for direct gradient optimisation when Ψ has small per-trait departures from constancy.

### How fixed effects (X β) interact

X β contributes only to the **mean** of y. The closed-form route is:

1. Estimate β by OLS-on-the-marginal: `β̂_init = (Σ_s X_s' Σ̂_y^{-1} X_s)^{-1} Σ_s X_s' Σ̂_y^{-1} y_s`. For initialisation, plug Σ̂_y = I (i.e. just OLS on stacked y vs X) — it is correct to O(1) for the fit start.
2. Form residuals `r_s = y_s − X_s β̂_init`.
3. Run PPCA closed form on the residual sample covariance.
4. Hand all of (β̂_init, Λ̂, σ̂²) to LBFGS as the starting parameter vector.

For our existing engine (`src/fit.jl` lines 134–148) this drops in as a replacement for the current `β₀ = zeros(q)` and `θ_B₀ = init_theta_rr(p, K)` initialisation.

### Integration with PERF outputs

PPCA closed-form initialisation is **orthogonal** to reverse-mode AD, profile-out, and pre-allocation. PERF round 1 makes each LBFGS iteration cheaper; PPCA init makes us **need fewer iterations** (1–3 instead of 20–50). They multiply.

---

## 3. EM for factor analysis with non-constant diagonal

When Ψ ≠ σ² I, use Rubin & Thayer (1982, *Psychometrika* 47:69–76). The EM iteration is fully closed-form per step.

Notation: data Y is p × n, residual matrix after subtracting X β̂. Let `Σ = Λ Λ' + Ψ`, with Ψ = diag(ψ_1, ..., ψ_p), and current parameters (Λ, Ψ).

**E-step.** For each observation x_i (here x_i = r_s, our residual column):

```
β_mat = Λ' Σ^{-1}                              (K × p)
E[z_i | x_i]      = β_mat · x_i               (K)
E[z_i z_i' | x_i] = I − β_mat Λ + β_mat x_i x_i' β_mat'   (K × K)
```

Σ^{-1} is computed once per E-step via Woodbury (we already have the kernel — see `src/likelihood.jl` lines 179–202 for our existing path), cost O(p K² + K³).

**M-step (closed form).**

```
Λ_new = (Σ_i x_i E[z_i|x_i]') · (Σ_i E[z_i z_i'|x_i])^{-1}

Ψ_new = (1/n) · diag(Σ_i x_i x_i' − Λ_new E[z_i|x_i] x_i')
```

Both updates are matrix expressions whose ingredients are O(p² K) sufficient statistics. Per iteration cost: **O(n p K + p² K + K³)**, independent of complicated linear-algebra structure.

**Convergence.** Typically 10–30 EM iterations to within `f_tol = 1e-10` for moderate p, K — empirically more competitive than 40–200 NEWUOA calls when p is small. EM is monotonic in likelihood by construction, so it is always a safe inner loop. Implementations: `factor_analyzer.py` (sklearn), `factanal()` in R `stats`, R `psych::fa()`.

**Where to use EM in our engine.** Two options, in order of incremental risk:

- **Tier A (low risk): initialiser.** Run 5–10 EM iterations after the PPCA closed-form init (Section 2). This polishes the start point when `d_total` is non-constant. Hand the polished (Λ, Ψ) to LBFGS for final convergence. Expected total: 5–10 EM + 2–5 LBFGS.
- **Tier B (higher reward): full EM solver.** Replace LBFGS for the J2-A-WD path entirely. Need to verify monotonicity is preserved under our log-parameterisations and that the per-trait split into σ²_B, σ²_W (rather than a single ψ_t) is handled correctly. The split is identifiable iff we keep at least one of `K_W ≥ 1` or the σ²_B, σ²_W distinction informationally separable — see whether `gllvmTMB.cpp` documents the identifiability of σ²_B vs σ²_W separately or whether the engine in practice fits ψ_t = σ²_B + σ²_W. If the latter, EM is **directly applicable** to the J2-A-WD path.

**Where EM does *not* apply directly:** the J3 phylogenetic path (Section 4) because the cross-site covariance breaks the i.i.d. structure that the standard EM-FA E-step assumes. Section 4 handles that.

---

## 4. Phylogenetic extension (J3)

The J3 marginal (`src/likelihood.jl` lines 22–40):

```
Σ_y_full = I_n ⊗ A + J_n ⊗ B
A = Λ_B Λ_B' + diag(d_total),     B = (Λ_phy_aug Λ_phy_aug') ⊙ Σ_phy
```

The rotation trick (`src/likelihood.jl` lines 32–40, 233–248) diagonalises J_n into one mode (eigenvalue n, eigenvector 1_n/√n) plus n−1 zero modes. In the rotated basis, the (np × np) covariance is block-diagonal: one p×p block equal to `A + n B`, and (n−1) p×p blocks equal to `A`.

**Implication for closed-form factor analysis.** In the rotated basis the system *decouples* into two independent factor-analysis subproblems:

- **Mean mode:** one "observation" (the rescaled column mean) with covariance `A + n B`. Factor structure: `(Λ_B, σ_n_aug)` where `σ_n_aug = √n · Λ_phy_aug` augmented to Λ_B.
- **Centred modes:** (n−1) i.i.d. observations with covariance `A`. Plain PPCA / EM-FA on the column-centred residuals.

This means the **PPCA closed form applies block-wise**:

- Run PPCA on `Y_c = Y − m 1_n'` (column-centred residuals) with sample covariance `(1/(n−1)) Y_c Y_c'`. This gives a closed-form initialiser for (Λ_B, d_total) **without touching the phylogenetic block at all**.
- Then estimate the phylo block from `n · m m' − A` (i.e. infer `B = (rescaled mean residual covariance − A) / n`). A small eigendecomposition of the result gives (Λ_phy, σ_phy).

This is a *novel* (to my knowledge) closed-form initialisation for the phylogenetic GLLVM that exploits the rank-1 structure of J_n. It is exact when Σ_phy = I_p (no phylogeny) and provides a strong warm start otherwise.

**For the proper Σ_phy ≠ I case** with the Hadamard B = (Λ_phy_aug Λ_phy_aug') ⊙ Σ_phy, the closed form is no longer exact. Two options:

1. **Hadamard-relaxed init.** Pretend Σ_phy = (mean diag of Σ_phy) · I in the init, run the rotation-trick PPCA, hand to LBFGS. Should converge fast because Σ_phy is typically not very far from a scaled identity for shallow trees.
2. **Iterate.** Alternate (E-step over phy factors using current Λ_phy, σ_phy with the rotation trick) and (M-step closed-form factor analysis on the rotated residuals). This is the J3-EM analogue. Should converge in ~10–30 iterations.

Key references: Lynch & Walsh (1998, *Genetics and Analysis of Quantitative Traits*) for the kron(I, A) + kron(J, B) covariance structure as the standard QG mixed-model decomposition; Ovaskainen et al. (2017, *Ecology Letters* 20:561–576) and Tikhonov et al. (2020, *Methods Ecol Evol* 11:442–447) for HMSC's hierarchical factor formulation, which is the closest comparator in the JSDM literature though they use Gibbs MCMC rather than ML/EM.

---

## 5. Concrete prioritised recommendation list for PERF+

Listed in expected payoff order, with target site and PERF compatibility noted.

1. **PPCA closed-form initialisation for Λ_B and σ_eps.** Top priority. Patch `src/fit.jl` lines **134–168** to replace `σ_eps_init`-default and `init_theta_rr` with: build sample covariance `S = (1/n) Y_c Y_c'` (where Y_c is residuals after OLS β init or just raw Y when q=0), eigendecompose, plug in Tipping & Bishop closed form. Expected speedup: **5–20×** through reduction in LBFGS iteration count from ~20–50 to 1–5. Risk: low — strictly affects starting point, the fit objective and convergence test are unchanged. Compatibility with PERF round 1: **multiplicative.** New dep: none (`LinearAlgebra` covers it). Includes a fallback when the closed-form gives `s_k ≤ σ̂²` (PPCA can yield negative variances under the radical; clamp to small positive).

2. **OLS warm-start for β.** Companion to (1). At `src/fit.jl` lines **134–145**, replace `β₀ = zeros(q)` with the marginal OLS estimate `(Σ_s X_s' X_s)^{-1} Σ_s X_s' y_s`. Expected speedup: **1.2–2×** (small but nearly free). Risk: zero. Compatibility: independent of all PERF changes.

3. **Block-wise PPCA + Λ_phy init for the J3 path.** Section 4's rotation-trick closed form. Patch `src/fit.jl` to detect `K_phy > 0 || has_phy_unique` and route through the centred-residual PPCA + mean-residual-covariance Λ_phy estimator. Expected speedup: **3–10×** on J3 fits (the current J3 path uses generic init and converges slowly because the parameter count is large). Risk: medium — need a fallback when `Σ_phy` is far from `I`. Compatibility: compatible with PERF reverse-mode AD; uses the same `unpack_lambda` packing.

4. **Replace ForwardDiff with reverse-mode (Enzyme.jl).** Already on PERF round 1's plate. Reaffirming. Per-iteration speedup expected **2–5×** for large p, K because the parameter dim is much larger than the output dim (the NLL is scalar). The PERF round 1 design should choose Enzyme over Mooncake based on current Julia 1.10/1.11 maturity (verify at implementation time).

5. **Analytic profile-out of `σ²_B + σ²_W` for J2-A-WD.** Given Λ_B, fit `ψ_t = d_total[t] − (Λ_W Λ_W')[t,t] − σ²_eps` by closed form: `ψ̂_t = (1/n) Σ_s r_t,s² − (Λ_B Λ_B' + Λ_W Λ_W')[t,t] − σ²_eps`. This converts the J2-A-WD problem from "optimise over 2p log-variance params" to "no variance params to optimise". Risk: medium — must verify identifiability of σ²_B vs σ²_W; if not separately identifiable (engine fits only their sum) this is a strict simplification. Compatibility: compatible with PPCA init + reverse AD.

6. **EM-FA inner loop for the J2-A-WD path.** Section 3 Tier B. Expected speedup: hard to predict; could match or beat LBFGS depending on tolerance. Should be benchmarked head-to-head against the LBFGS path before committing. Risk: medium-high — re-architecture of the J2-A-WD `fit_gaussian_gllvm` body. Compatibility: replaces LBFGS for this path, so it sidesteps PERF's AD work (which is fine — no AD is needed for closed-form EM).

7. **Pre-allocated workspace for the marginal NLL.** Already on PERF round 1's plate. Reaffirming. The current `gaussian_marginal_loglik` allocates `d_inv`, `DinvΛ`, `A_K`, `Dinv_r`, `ΛtDr`, `z`, `DinvΛz`, `Σinv_r` per call (`src/likelihood.jl` lines 179–202). All should live in a `GllvmWorkspace` struct owned by the fit caller.

8. **Sign-anchor reparameterisation that *removes* a parameter rather than constraining it.** Currently `init_theta_rr` initialises diag(Λ) = 0.5 (`src/packing.jl` lines 94–101) and the sign convention is enforced post-hoc. Instead, parameterise `Λ[k, k] = exp(log_Λ_kk)` (strictly positive) in `unpack_lambda` (`src/packing.jl` lines 47–64). Risk: low — this *changes* the parameter manifold slightly but is a standard reparam (same idea as MixedModels' Λ being lower-triangular with positive diagonal). Compatibility: requires regenerating PPCA-init values; trivial. Expected speedup: small, but improves numerical conditioning and lets LBFGS take bigger steps near the boundary.

**The combined PERF + PERF+ stack** (PPCA init, OLS warm start, J3 block-wise init, reverse AD, profile-out ψ, pre-allocated workspace) is expected to give **30–100× total speedup** on J1, **10–30×** on J2-A-WD, **5–15×** on J3, relative to the commit `24c7968` engine. The bulk of the gain comes from `1` and `2`.

---

## 6. Benchmark targets

From `docs/src/benchmarks.md` (MixedModels.jl main, dated 2018-10-02, Intel i5-3570 @ 3.40 GHz, Julia 1.0.0):

| Dataset | Structure | Fit time |
|---|---|---|
| Dyestuff | 1 + (1\|batch), 30 obs | 0.83 ms |
| sleepstudy (scalar) | 1 + days + (1\|subj), 180 obs | 4.83 ms |
| sleepstudy (vector) | 1 + days + (1+days\|subj) | 4.83 ms |
| Animal | nested | 1.26 ms |
| Penicillin | crossed | 2.70 ms |
| Assay | crossed | 2.94 ms |
| InstEval (simple) | 73 421 obs | 1.25 s |
| InstEval (complex) | + dept interactions | 2.00 s |
| kb07 (simple) | crossed vector | 3.49 s |
| d3 (simple) | crossed vector | 0.30 s |
| d3 (complex) | crossed vector | 49.0 s |
| ml1m | 1M ratings | 36.7 s |

These are LMM problems, not GLLVM, so they are **not direct comparators**. They are the right ballpark for "what gradient-free Julia mixed-effects looks like at this hardware tier". For our head-to-head we need to construct an equivalent-size dataset on the GLLVM side (e.g. p = 30 traits, n = 1000 sites, K = 3) and time both engines. Recommended: add a `bench/perf_targets.jl` harness in PERF+ that fits MixedModels.jl on a `(1 | trait)` random-intercept LMM as an approximate comparator (it is a much simpler model than full GLLVM but its fit time is the floor we have to beat — anything slower than MixedModels on the trivial RE case is a fail).

External independent benchmark: Markwick (2022, [Mixed Models Benchmarking blog post](https://dm13450.github.io/2022/01/06/Mixed-Models-Benchmarking.html)) — football GLMM on 98 242 rows, 151 groups: MixedModels.jl 11.15 ms (standard), 5.94 ms (`fast=true`); R `glmer` 35.4 ms (standard), 8.06 ms (`nAGQ=0`). The ratio 11/35 ≈ 3× is the typical Julia-vs-R speedup MixedModels currently delivers; to "be better than MixedModels", we should aim for sub-Julia-MixedModels times on the GLLVM problem class.

---

## Sources

- MixedModels.jl source, branch `main`, accessed 2026-05-28:
  - [`src/linearmixedmodel.jl`](https://github.com/JuliaStats/MixedModels.jl/blob/main/src/linearmixedmodel.jl)
  - [`src/optsummary.jl`](https://github.com/JuliaStats/MixedModels.jl/blob/main/src/optsummary.jl)
  - [`src/derivatives.jl`](https://github.com/JuliaStats/MixedModels.jl/blob/main/src/derivatives.jl)
  - [`src/randomeffectsterm.jl`](https://github.com/JuliaStats/MixedModels.jl/blob/main/src/randomeffectsterm.jl)
  - [`src/profile/profile.jl`](https://github.com/JuliaStats/MixedModels.jl/blob/main/src/profile/profile.jl)
  - [`src/linalg.jl`](https://github.com/JuliaStats/MixedModels.jl/blob/main/src/linalg.jl)
  - [`ext/MixedModelsNLoptExt.jl`](https://github.com/JuliaStats/MixedModels.jl/blob/main/ext/MixedModelsNLoptExt.jl)
  - [`ext/MixedModelsForwardDiffExt.jl`](https://github.com/JuliaStats/MixedModels.jl/blob/main/ext/MixedModelsForwardDiffExt.jl)
  - [`benchmark/benchmarks.jl`](https://github.com/JuliaStats/MixedModels.jl/blob/main/benchmark/benchmarks.jl)
  - [`docs/src/benchmarks.md`](https://github.com/JuliaStats/MixedModels.jl/blob/main/docs/src/benchmarks.md)
  - [`docs/src/optimization.md`](https://github.com/JuliaStats/MixedModels.jl/blob/main/docs/src/optimization.md)
- Tipping & Bishop (1999) "Probabilistic Principal Component Analysis", *JRSSB* 61(3):611–622 — closed-form ML in eqs. 7–8 of that paper. Authoritative summary at [Columbia mirror PDF](https://www.cs.columbia.edu/~blei/seminar/2020-representation/readings/TippingBishop1999.pdf).
- Rubin & Thayer (1982) "EM algorithms for ML factor analysis", *Psychometrika* 47(1):69–76, [Springer link](https://link.springer.com/article/10.1007/BF02293851).
- EM-FA M-step derivation: [Gundersen (2018) "Factor Analysis in Detail"](https://gregorygundersen.com/blog/2018/08/08/factor-analysis/).
- Lynch & Walsh (1998) *Genetics and Analysis of Quantitative Traits* — Chapter 26 on multi-trait mixed models (the kron-I-plus-kron-J decomposition).
- Ovaskainen et al. (2017) "How to make more out of community data?", [*Ecology Letters* 20:561–576](https://onlinelibrary.wiley.com/doi/10.1111/ele.12757).
- Tikhonov et al. (2020) "Joint species distribution modelling with the r-package Hmsc", [*Methods Ecol Evol* 11:442–447](https://besjournals.onlinelibrary.wiley.com/doi/10.1111/2041-210X.13345).

## Uncertainty / unverified claims

- I read MixedModels.jl source at line numbers reported on 2026-05-28 from GitHub `main`. Line numbers shift across versions; the PERF+ agent should re-verify before quoting.
- The `BlockedSparse` / `UniformBlockDiagonal` storage classes are mentioned in `src/linalg.jl` and `src/arraytypes.jl` but I did not read the full struct definitions; the claim "no warm-start across iterations" is based on the absence of a low-rank-update kernel in `updateL!`, not an exhaustive proof.
- The σ²_B vs σ²_W identifiability question for J2-A-WD (recommendation 5) is flagged as needing verification against the R `gllvmTMB` engine before implementation.
- I could not read the Tipping & Bishop 1999 PDF directly through WebFetch (it returned binary data); the equations quoted are reconstructed from secondary sources (web search results, lecture notes, Gundersen 2018) which are consistent across multiple independent sources. The closed-form formulae are textbook-standard and unambiguous, but the PERF+ agent should cross-check against the original paper before publishing performance claims that depend on them.
