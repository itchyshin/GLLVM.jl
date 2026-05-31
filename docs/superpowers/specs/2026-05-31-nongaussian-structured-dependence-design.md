# Structured-dependence support for non-Gaussian GLLVM families — design spec

- Status: **SPEC ONLY — not implemented.** No code in `src/` is touched by this
  document. It is a design analysis with a slice plan and verifiable goals.
- Date: 2026-05-31
- Scope: add a species-level structured random effect (phylogenetic / animal-
  model / spatial) to the **non-Gaussian** families — Poisson, NB2, Binomial,
  Beta, Gamma, Ordinal — which currently carry only an iid per-site latent
  `z_s ~ N(0, I_K)`.
- Audience: the maintainer + any agent who picks up the build. Read the four
  source files cited under "Code grounding" first.

---

## 0. TL;DR / verdict up front

Adding a shared species-level structured effect `u ~ N(0, σ²Σ_phy)` to the
non-Gaussian path is **not a thin extension of the current per-site Laplace**. The
current marginal factorises over sites *because* the only latent is the per-site
`z_s`; a shared `u` couples all `n` sites into one `(nK + p)`-dimensional
integral. The honest options are:

1. **Joint Laplace** over `(z_1…z_n, u)` — correct, but the per-Newton-step cost
   is dominated by a dense `p×p` (or worse) cross-block unless the sparse-tree
   precision is exploited *and* the cross-site coupling is handled by a Schur
   complement. **Tractable at O(n·p) per iteration on a tree** if built
   carefully; **research-grade** if built naively.
2. **Structured prior on `z`** (`z` columns correlated through `Σ_phy`) — wrong
   axis: in this codebase the species dimension is the **rows** of `Λ`, not the
   columns, so this does not express phylogeny. Rejected (see §5.1).
3. **Variational / INLA-style** — lower implementation risk than a hand-coded
   joint-Laplace adjoint at scale, but a larger conceptual departure from the
   current closed-form/Laplace spine.

**Recommended path: joint Laplace with a Schur-complement (profile-`u`)
factorisation, sparse-tree `Σ_phy⁻¹`, finite-difference outer gradient first,
analytic adjoint later.** Size estimate: **a substantial multi-week build**, not a
slice. See §7 for the breakdown and §8 for the verdict.

---

## 1. Code grounding (read these first)

Orientation facts that the rest of the spec depends on — verified against the
source, not assumed.

### 1.1 Data orientation: species are ROWS, sites are COLUMNS

In every non-Gaussian family, `Y` is **`p × n`**: `p` rows = species/traits,
`n` columns = sites. `src/families/laplace.jl::marginal_loglik_laplace` iterates
over `axes(Y, 2)` (the **columns** = sites) and calls `laplace_loglik_site` once
per site:

```julia
function marginal_loglik_laplace(family, Y, N, Λ, β, link; kwargs...)
    acc = 0.0
    for i in axes(Y, 2)                       # i indexes SITES
        acc += laplace_loglik_site(family, view(Y, :, i), view(N, :, i),
                                   Λ, β, link; kwargs...)
    end
    return acc
end
```

So the current per-site latent `z_s ∈ ℝ^K` is shared across the `p` species
**within a single site column**, and the `n` site columns are independent. The
total marginal is a clean sum of `n` independent `K`-dim Laplace integrals
(`laplace_loglik_site`), each with its own `K×K` mode-finder
(`_laplace_mode`) and `K×K` log-determinant `logdet(Λ'WΛ + I)`.

**This is exactly the structure the new effect breaks.** The species-level
`u ∈ ℝ^p` (one value per species/row) is shared across *all* `n` site columns.
It couples the `n` previously-independent site integrals through the species
(row) dimension — the orthogonal axis to `z_s`.

### 1.2 The per-site Laplace core (`src/families/laplace.jl`)

The generic mode-finder is Fisher-scoring Newton on the per-site latent:

```julia
η  = β .+ Λ * z                       # length p
μ  = linkinv.(link, η)
s  = _glm_score.(family, μ, n, me, y) # length-p score wrt η
W  = _glm_weight.(family, μ, n, me)   # length-p Fisher weight (≥0)
A  = Symmetric(Λ' * (W .* Λ) + I)     # K×K, SPD by construction
Δ  = A \ (Λ' * s .- z)
z  = z .+ Δ
```

and the site log-marginal is `ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I)`. Three
family hooks dispatch on the `Distributions` marker type:
`_glm_score(family, μ, n, me, y)`, `_glm_weight(family, μ, n, me)`,
`_glm_logpdf(family, μ, n, y)`. Ordinal carries its own copy of this loop
(`src/families/ordinal.jl`) because its "mean" is a probability vector, but the
normalisation is identical.

**Key property to preserve:** the Laplace Hessian uses the **expected** (Fisher)
information `W = (dμ/dη)²/V(μ)`, which is `≥ 0` by construction, so the inner
Newton matrix is always SPD and never needs damping. The new joint Hessian must
keep this property (see §3.3).

### 1.3 The fit drivers (`src/fit.jl`, `src/families/*.jl`)

- Gaussian: `fit_gaussian_gllvm` runs L-BFGS with **ForwardDiff** gradients on a
  closed-form profile NLL; `Σ_phy` (a dense `p×p` species covariance) folds in
  analytically via the rotation trick (`I_n ⊗ A + J_n ⊗ B`,
  `B = (Λ_aug Λ_aug') ∘ Σ_phy`) — **no Laplace, no latent integral**, because
  Gaussian + identity is conjugate (`src/likelihood.jl` header).
- Non-Gaussian: each `fit_<family>_gllvm` runs `Optim.LBFGS` with
  `autodiff = :finite` on the negative Laplace marginal, packing
  `[β; pack_lambda(Λ); (dispersion if any)]`. Dispersion is carried on the log
  scale (`log r`, `log φ`) inside the marker (NB `NegativeBinomial(r,·)`, Beta
  `Beta(φ,·)`); Gamma similarly. Ordinal packs `[vec(Λ); ψ]` with ordered
  cutpoints `τ_c = τ_{c-1} + exp(ψ_c)`.

The unified entry point is `fit_gllvm(Y; family, K, kwargs...)` →
`_fit_gllvm(family, Y; …)` (`src/families/fit_gllvm.jl`). A structured-effect
build extends each `fit_<family>_gllvm` and threads `Σ_phy` / `phy` through this
dispatcher exactly as the Gaussian path threads `Σ_phy`.

### 1.4 The sparse phylo machinery (`src/sparse_phy.jl`, `src/node_gradient.jl`)

`AugmentedPhy` represents a binary tree of `p` species by a **sparse** precision
`Q_topology` over the `2p−1` augmented nodes (leaves + ancestors), ~`8p`
nonzeros. The Brownian species covariance is `Σ_phy = S Q_cond⁻¹ Sᵀ` where
`Q_cond` is `Q_topology` with the root row/col dropped (SPD) and `S` selects
leaves. **The point of the augmented frame: never materialise the dense `p×p`
`Σ_phy` or `Σ_phy⁻¹`.** A solve `Σ_phy⁻¹ v` is *not* directly a sparse solve, but
the equivalent computation in the node frame — solving the sparse `Q_cond`
system over the `2p−2` non-root nodes — is **O(p)** via CHOLMOD, because a tree
Cholesky factor has O(p) fill (`takahashi_diag`, `chol_Qcond \ rhs` in
`src/node_gradient.jl`).

`node_gradient.jl` already implements, for the **Gaussian** phylo-unique model,
the exact node-frame trick this spec needs as a substrate:

- `build_node_perspecies(phy, σ_phy, σ²_eps)` builds the augmented node
  precision `Λ̃ = Q_cond + σ_eps⁻² Sᵀ diag(σ_phy²) S` (sparse) and its Cholesky.
- `node_blups` returns the node posterior mean `û = Λ̃⁻¹(σ_eps⁻² Sᵀ Λ_φ (y−μ))`
  — exactly the conditional mode of `u` under a **Gaussian** likelihood.
- `takahashi_diag(cΛ̃)` gives the selected-inverse node diagonal in O(nnz L),
  i.e. the marginal posterior variances of the node values.

The non-Gaussian build reuses this substrate but replaces the constant
`σ_eps⁻²` working weight with the **family Fisher weights summed over sites** —
see §2–§3. **CHOLMOD is Float64-only ⇒ ForwardDiff.Dual cannot flow through it**
(`src/node_gradient.jl` header). This is why the inner mode-find and any
node-frame logdet must be evaluation-only or hand-differentiated; it dictates the
gradient strategy in §3 and §7.

### 1.5 CONSTANT we will lean on

`Σ_phy` here is the **same `p×p` form** for all three use-cases the task names:

- phylogenetic Brownian motion: `Σ_phy = S Q_cond⁻¹ Sᵀ` from a tree;
- animal model / pedigree: `Σ_phy = A` the numerator relationship matrix
  (its **inverse** `A⁻¹` is sparse — Henderson 1976 — exactly analogous to
  `Q_cond`);
- spatial: `Σ_phy` a Matérn / CAR / SPDE covariance (CAR and SPDE give a sparse
  *precision*, like the tree; a dense Matérn does not).

So the abstraction the build needs is **"a `p×p` SPD covariance with a cheap
solve against its inverse"** — sparse-precision for tree / pedigree / CAR / SPDE,
dense fallback for small `p` Matérn. The tree path (`AugmentedPhy`) is the
flagship; the others slot into the same interface.

---

## 2. Model

### 2.1 Generative model

For species (row) `t ∈ 1:p` and site (column) `s ∈ 1:n`:

```
η_{ts} = β_t + (Λ z_s)_t + u_t
y_{ts} | η_{ts} ~ Family(g⁻¹(η_{ts}) [, n_{ts}] [, dispersion])

z_s ~ N(0, I_K)           independent over sites s        (per-site latent)
u   ~ N(0, σ² Σ_phy)      ONE draw, shared over all sites  (species-level RE)
```

`g⁻¹` is the family inverse link (`src/families/links.jl`); `Σ_phy` is the `p×p`
species covariance of §1.5; `σ² ≥ 0` is a single scalar scaling the structured
effect (the obvious first parameterisation — §6 discusses per-trait `σ_phy[t]`,
which the Gaussian path already supports via `node_gradient.jl`).

This is the **phylogenetic GLMM** (a.k.a. PGLMM / phylogenetic mixed model) layered
onto the GLLVM's latent-factor mean. With `Λ = 0` it is exactly the
Ives & Helmus (2011) / Hadfield `MCMCglmm` phylogenetic GLMM; with `σ = 0` it is
exactly the current iid-latent GLLVM. Both reductions are verifiable goals (§7).

### 2.2 Why `u` is additive on `η` and shared across sites

`u_t` is a **species random intercept** with phylogenetic covariance: closely
related species have correlated `u`. It is shared across sites because phylogeny
is a property of the species, not the site. This is the standard PGLMM structure
and matches the Gaussian `phylo_unique` term `s_phy[t] = σ_phy[t]·φ[t]`,
`φ ~ N(0, Σ_phy)` in `src/likelihood.jl` (which is likewise added to every site
column). The non-Gaussian case differs *only* in that the likelihood is not
conjugate, so the integral over `u` is not closed-form.

### 2.3 Joint latent and the target marginal

Stack the latents: `z = (z_1, …, z_n) ∈ ℝ^{nK}` and `u ∈ ℝ^p`. The marginal
log-likelihood is the `(nK + p)`-dimensional integral

```
L(θ) = log ∫_{ℝ^{nK}} ∫_{ℝ^p}  exp{ ℓ(z, u) − ½ Σ_s z_s'z_s − ½σ⁻² u'Σ_phy⁻¹u } du dz
         − (n/2)·K·log(2π) − ½ log det(2π σ² Σ_phy)
```

where `ℓ(z, u) = Σ_{t,s} log p(y_{ts} | η_{ts})` is the conditional
log-likelihood and `θ = (β, Λ, σ, dispersion, cutpoints)` are the
hyperparameters. **The `u`-coupling is what stops the `du dz` integral from
splitting into the product of `n` per-site integrals.** Conditional on `u`, it
*does* split (§3.4) — that conditional separability is the lever the whole build
turns on.

---

## 3. The core challenge — joint Laplace, honestly

### 3.1 Why the current per-site Laplace breaks

`marginal_loglik_laplace` is `Σ_s laplace_loglik_site(…)`. Each term is
`∫ p(y_s|z_s) N(z_s;0,I) dz_s`. That factorisation is valid **iff** the only
latent in `η_{·s}` is `z_s`. Adding `u` puts a latent in `η_{·s}` that is *the
same vector for every `s`*. Now

```
∫ ∏_s [ p(y_s | z_s, u) N(z_s;0,I) ] N(u;0,σ²Σ_phy) du dz
```

cannot be pulled apart over `s`, because the `du` integral sees every site. Any
implementation that keeps calling the per-site core and "adds `u` somewhere" is
**wrong** unless `u` is integrated jointly. This is the central correctness point
of the spec.

### 3.2 The joint Laplace objective

Define the negative joint log-density of the latents (the "inner objective" the
Laplace mode maximises, sign-flipped to a minimisation):

```
h(z, u) = −ℓ(z, u) + ½ Σ_s z_s'z_s + ½ σ⁻² u'Σ_phy⁻¹u
```

Laplace approximation:

```
L(θ) ≈ ℓ(ẑ, û) − ½ Σ_s ẑ_s'ẑ_s − ½ σ⁻² û'Σ_phy⁻¹û
        − ½ log det( H )  − ½ log det(σ² Σ_phy)   + const
```

where `(ẑ, û) = argmin h` and `H = ∇²h(ẑ, û)` is the `(nK+p)×(nK+p)` joint
Hessian. (The `− ½ log det(σ²Σ_phy)` and the `+½ log det` of the `u`-prior
precision inside `H`'s `u`-block combine to the usual `½ log det(Σ_phy⁻¹ /
(Σ_phy⁻¹ + …))` ratio; bookkeeping in §3.5.) This is the standard Laplace-marginal
used by `glmmTMB` / TMB and by INLA's first-order approximation.

### 3.3 Block structure of the joint Hessian

Order the latent as `(z_1, …, z_n, u)`. Write per-observation Fisher weights
`W_{ts} = (dμ/dη)²/V(μ)` (the family `_glm_weight`, evaluated at the current
`η_{ts}`) and per-site weight diagonals `W_s = diag(W_{1s}, …, W_{ps}) ∈ ℝ^{p×p}`.
Then (using the **Fisher/expected** information, mirroring §1.2, so all blocks are
PSD):

```
H_{z_s z_s} = Λᵀ W_s Λ + I_K          (K×K, one per site)      — block-diagonal
H_{z_s z_r} = 0  for r ≠ s                                      — sites uncoupled given u
H_{z_s u}   = Λᵀ W_s                   (K×p)                    — coupling block
H_{u u}     = Σ_{s} W_s + σ⁻² Σ_phy⁻¹  = W_• + σ⁻² Σ_phy⁻¹  (p×p)
             where W_• = diag(Σ_s W_{ts})_t  is DIAGONAL.
```

So `H` is a **block-arrow ("bordered block-diagonal") matrix**: `n` independent
`K×K` blocks on the diagonal, all bordered by the shared `u`-block. This is the
single most important structural fact in the spec, and it is what makes the
problem tractable:

```
        ┌ A_1            B_1ᵀ ┐         A_s = Λᵀ W_s Λ + I_K   (K×K)
        │    A_2         B_2ᵀ │         B_s = W_s Λ            (p×K)
   H =  │       ⋱         ⋮   │         D   = W_• + σ⁻²Σ_phy⁻¹ (p×p, sparse if tree/CAR/A⁻¹)
        │          A_n   B_nᵀ │
        └ B_1 B_2 … B_n   D   ┘
```

Note `H_{z_s u} = Λᵀ W_s` only has the `dμ/dη` factor once on each side via `W_s`;
the per-observation score `s_{ts}` (FD-checked in §3.7) enters the **gradient**
`∇h`, not the Fisher Hessian. (The exact observed Hessian would add a
`Σ_{ts} (∂²ℓ/∂η²)` correction; we deliberately use the Fisher form so blocks stay
PSD and SPD-after-prior, matching the existing per-site core. This is the same
choice `glmmTMB`'s default and the current code make.)

### 3.4 The lever: conditional-on-`u` the sites separate

Because `H_{z_s z_r}=0` for `r≠s`, the `z`-block of `H` is block-diagonal.
Eliminate `z` by a Schur complement onto `u` (equivalently: profile `z` out given
`u`). The Schur complement of the `z`-block is

```
S_u = D − Σ_s B_s A_s⁻¹ B_sᵀ
    = (W_• + σ⁻²Σ_phy⁻¹) − Σ_s W_s Λ (Λᵀ W_s Λ + I_K)⁻¹ Λᵀ W_s        (p×p)
```

and the joint log-determinant factorises **exactly**:

```
log det H = Σ_s log det A_s + log det S_u
```

- `Σ_s log det A_s`: `n` independent `K×K` determinants — **exactly the cost of
  the current per-site core** (one `logdet(Λ'W_sΛ + I)` per site). Reuses
  `laplace.jl`'s machinery verbatim.
- `log det S_u`: one `p×p` determinant. **This is the entire new cost.** Whether
  it is O(p), O(p²), or O(p³) is decided by how `S_u` is represented (§3.6).

The mode-finding mirrors this. Newton on `(z,u)`: given `u`, each `ẑ_s(u)` solves
its own `K×K` system (the per-site solve, but with `η` including `+u_t`); then a
single `p`-dim Newton step on `u` uses the Schur-complement gradient and `S_u`.
This is a **block / nested Newton**, and each outer `u`-step costs one solve
against `S_u` plus `n` cheap `K×K` solves.

### 3.5 Score wrt the latent (the gradient `∇h`)

Let `s_{ts}` be the per-observation score `∂ℓ/∂η_{ts}` (FD-checked, §3.7). Then

```
∂h/∂z_s = z_s − Λᵀ s_{·s}                       (length K, per site)
∂h/∂u   = σ⁻² Σ_phy⁻¹ u − Σ_s s_{·s}            (length p)
        = σ⁻² Σ_phy⁻¹ u − s_•,   s_• = (Σ_s s_{ts})_t  (row sums of the score)
```

The `z_s`-stationarity `z_s = Λᵀ s_{·s}` is exactly the current per-site mode
equation (`Δ = A\(Λ's − z)` in `laplace.jl`) with `η` now carrying `+u_t`. The
`u`-stationarity is the new equation: it balances the prior pull `σ⁻²Σ_phy⁻¹u`
against the summed data score `s_•`. On a tree, `Σ_phy⁻¹ u` is the **node-frame
sparse solve** of §1.4 (apply `Q_cond` in the augmented frame), so the gradient is
O(p).

### 3.6 logdet of the joint Hessian and cost per Newton step — the crux

Everything hinges on `log det S_u` and solving `S_u x = b`. `S_u` is a `p×p`
matrix of the form **(sparse SPD) + (low-rank / diagonal data terms)**:

```
S_u = σ⁻²Σ_phy⁻¹ + W_• − Σ_s W_s Λ A_s⁻¹ Λᵀ W_s
       └ sparse ┘  └ diag ┘ └──────── n rank-K corrections ─────────┘
```

Three regimes, reported honestly:

1. **Naive dense (`O(n p² + p³)`) — research-grade cost, do NOT ship.** Form
   `S_u` densely: the `Σ_s W_s Λ A_s⁻¹ Λᵀ W_s` sum alone is `n` dense `p×p`
   rank-K outer products = **O(n p² K)** to assemble, and `log det S_u` /
   `S_u⁻¹` is **O(p³)** dense. At `p = 10⁴` this is the 16-second-per-eval regime
   the whole sparse-phy effort exists to avoid (`src/sparse_phy.jl` header).
   Acceptable only for small-`p` validation.

2. **Sparse-precision + per-site low-rank, matrix-free `O(n p K + p^{1.5})` on a
   tree — the target.** Keep `Σ_phy⁻¹` as the sparse node operator (never dense).
   The data correction `Σ_s W_s Λ A_s⁻¹ Λᵀ W_s` is **`W_• − S_data`** where
   `S_data = Σ_s (W_s Λ) A_s⁻¹ (W_s Λ)ᵀ`. Crucially `W_• − S_data` is a *diagonal
   minus a sum of `n` rank-`K` terms* — it is **dense in general**, BUT it acts on
   vectors in **O(n p K)** matrix-free (apply each `W_sΛ A_s⁻¹ (W_sΛ)ᵀ v`
   per site without forming it). So `S_u v` is O(npK + nnz(Σ_phy⁻¹)) matrix-free.
   That gives a matrix-free **solve** (PCG against `S_u`) in O(#iter · npK). The
   **log-determinant is the hard part**: there is no free lunch for
   `log det(sparse + dense-low-rank-sum)`. Options:
   - **Stochastic Lanczos quadrature / Hutchinson** for `log det S_u` and its
     derivative — O(#probes · npK), the scalable choice, but introduces Monte
     Carlo noise into the objective (bad for a smooth optimiser; needs fixed
     probe vectors per fit, à la "frozen randomness").
   - **A single global low-rank update**: if `K` is small and the `n` corrections
     can be amortised, `S_data` has rank `≤ min(nK, p)`; when `nK < p` a Woodbury
     / matrix-determinant-lemma on `σ⁻²Σ_phy⁻¹ + W_•` (sparse, with a sparse
     Cholesky giving its logdet in O(p) on a tree) plus a rank-`nK` correction
     gives `log det S_u` in O(p + (nK)³ + (nK)²p). **This is attractive only when
     `nK ≪ p`**, which is the *opposite* of the usual ecology regime (`n` sites in
     the hundreds, `p` species in the hundreds-to-thousands, `K` = 2–5 ⇒
     `nK ≫ p`). So Woodbury-on-rank-`nK` generally loses.
   - **Honest assessment:** the clean O(p) determinant the *Gaussian* sparse path
     enjoys does **not** carry over, because the data-dependent `W_s` differ
     across sites and inject an `n·K`-rank dense perturbation into `S_u` that has
     no sparse structure. The realistic target is **O(n p K) per `S_u` apply,
     determinant via SLQ** — fast and scalable but approximate, or **O(p³) dense
     determinant** — exact but only for moderate `p`. This mirrors the **same
     honest ceiling already documented for the Gaussian analytic gradient**
     (`src/sparse_phy_grad.jl` header: the cross-leaf block is inherently O(p²)).

3. **Animal model / CAR / SPDE:** identical analysis with `Σ_phy⁻¹ = A⁻¹`
   (sparse, Henderson) or the CAR/SPDE precision. Same `S_u` structure; same
   determinant ceiling.

**Cost per Newton step (target regime, tree, matrix-free + SLQ determinant):**

| piece | cost |
|---|---|
| `n` inner `z_s` solves (`K×K`) | O(n K³) — same as current per-site core |
| assemble `s_•`, `W_•` (row sums over sites) | O(n p) |
| `Σ_phy⁻¹ u` (node-frame sparse solve) | O(p) on a tree |
| one `u`-Newton step: PCG solve `S_u x = b` | O(#cg · n p K) matrix-free |
| `log det S_u` + its `θ`-derivative | O(#probes · n p K) (SLQ) or O(p³) (dense) |

So **per outer optimiser evaluation** (a full inner mode-find = a few block-Newton
sweeps, then one logdet): **O(n p K) on a tree with SLQ**, vs **O(n p² + p³)
naive dense**. The `n p K` term is unavoidable (it is just "touch every
observation a constant number of times") and matches the data size.

### 3.7 FD-check of the per-observation scores (the gradient's atoms)

The joint gradient `∇h` (§3.5) is built entirely from the per-observation score
`s_{ts} = ∂ℓ/∂η_{ts}` and the Fisher weight `W_{ts}` already in the codebase.
I FD-checked each family's score wrt `η` against central differences
(`(ℓ(η+δ)−ℓ(η−δ))/2δ`, `δ=1e-6`), at three `(η, y[, n/r/φ/ν])` points each.
**Max abs residual ≤ 1.8e-9 across all six families.** Verbatim residuals:

```
Poisson  (log):  s=(y−μ)                 resid ∈ {1.4e-11, 3.0e-11, 4.1e-10}
Binomial (logit):s=(y−nμ)                resid ∈ {1.1e-11, 1.7e-10, 2.0e-10}
NB2      (log):  s=(y−μ)/(1+μ/r)         resid ∈ {1.8e-10, 3.8e-11, 3.7e-10}
Beta     (logit):s=φ(y*−μ*)·μ(1−μ)       resid ∈ {6.1e-10, 1.8e-9, 1.3e-10}
Gamma    (log):  s=ν(y−μ)/μ              resid ∈ {8.3e-11, 2.5e-11, 2.8e-10}
Ordinal  (logit):s=(f(τ_{c−1}−η)−f(τ_c−η))/P(y=c)  resid ∈ {3.2e-11, 7.5e-11, 4.3e-11}
```

(`y* = logit(y)`, `μ* = ψ(μφ)−ψ((1−μ)φ)`; `f` = logistic density.) These are
*exactly* the `_glm_score` definitions in `src/families/{poisson,binomial,negbin,
beta,gamma,ordinal}.jl`, so the joint mode equation `∂h/∂u = σ⁻²Σ_phy⁻¹u − Σ_s
s_{·s}` reuses verified atoms. **No new per-observation formula is introduced by
this design** — the structured effect only changes *which `η`* the existing score
is evaluated at (now `β_t + (Λz_s)_t + u_t`) and adds the prior-coupling terms,
which are linear-Gaussian and trivially correct. The reproduction script is in
§9.

---

## 4. Alternatives and trade-offs

### 4.1 Additive `u` (this spec) vs structured prior on `z`

**Structured prior on `z` (`z ~ N(0, Σ_phy ⊗ ·)`) is the WRONG axis here and is
rejected.** In this codebase `z_s ∈ ℝ^K` is the *site's* latent and the species
dimension is the **rows of `Λ`**. Correlating the *columns* (`z_s` across sites)
would express *site*-level dependence (spatial structure over sampling
locations), not phylogeny over species. To express phylogeny as a structured `z`
you would have to redefine the latent so that one axis indexes species — i.e. a
per-species latent — which is precisely the additive `u` (a rank-1, identity-
loading version of "structured `z`"). So the two are not competing designs for
the *phylogenetic* goal; additive `u` is the correct one. (A structured *site*
prior is a separate, also-useful feature — spatial random fields over sites — and
would correlate the `z_s` columns; out of scope here but the same Schur
machinery applies with the roles of `n` and `p` swapped.)

### 4.2 Full-rank `u` vs reduced-rank `u`

- **Full-rank `u ∈ ℝ^p`** (this spec): one structured intercept per species. The
  `u`-block is `p×p`. Correct and standard.
- **Reduced-rank `u = Φ a`, `a ∈ ℝ^r`, `r ≪ p`** (phylogenetic factor /
  "phylogenetic PCA" reduced rank, or a low-rank spatial basis à la predictive
  processes / SPDE-reduced): the `u`-block shrinks to `r×r`, killing the `p³`
  determinant outright and making the whole thing O(npK + nr·…). **This is the
  pragmatic escape hatch** if full-rank `Σ_phy⁻¹` determinant work proves too
  costly. Trade-off: it is an *approximation* to the full phylogenetic effect
  (rank-`r` truncation of `Σ_phy`); defensible for spatial (Datta et al. 2016
  NNGP, Banerjee et al. 2008 predictive processes) but less standard for
  phylogeny. Recommend offering it as an option, not the default.

### 4.3 Laplace vs variational vs MCMC

| approach | accuracy | impl. effort here | scaling | notes |
|---|---|---|---|---|
| **Laplace (this spec)** | good for unimodal posteriors; first-order | medium–high (joint mode + logdet + adjoint) | O(npK) tree, SLQ det | matches `glmmTMB`/TMB; reuses existing per-site core + node-frame solves |
| **Adaptive GH quadrature** | gold standard for **small** latent dim | low for `K+`small, infeasible for `+u` | exponential in latent dim | only usable for the **validation cross-check** (§7), not production: the joint latent is `nK+p`-dim |
| **Mean-field VI** | biased variances (underestimates) | medium | O(npK) | avoids the joint logdet; but the additive `u` couples `z` and `u`, so a structured (not mean-field) `q` is needed for honest `σ²` — that is ~as hard as Laplace |
| **INLA-style nested Laplace** | very good for latent-Gaussian models | high (would be a new spine) | O(npK) on sparse | conceptually the *right* tool (this IS a latent-Gaussian model), but a large departure from the current code; realistic only as a long-term direction |
| **MCMC (`MCMCglmm`-style)** | exact (up to MC) | low to *prototype*, but a different engine | slow | use as an **external ground-truth oracle** for the spec's validation, not as the production fitter |

**Recommendation:** **Laplace**, because (i) it reuses the existing per-site
Fisher-scoring core and the node-frame sparse solves almost verbatim; (ii) it is
exactly what the reference packages (`glmmTMB`, TMB, `gllvm`'s `method="LA"`) do
for this model class; (iii) the package's whole identity is "fast + rigorous
Laplace/closed-form", and a VI/INLA spine would be a different package. Keep VI /
reduced-rank as documented fallbacks for the `p³`-determinant regime.

### 4.4 Determinant strategy trade-off (the real decision)

The fork is **not** Laplace-vs-VI; it is **how to compute `log det S_u`**:

- **Exact dense** (`O(p³)`): simplest, correct, smooth objective; ceiling
  `p ≲ 1500–2000` before it dominates. **Ship this first.**
- **SLQ / stochastic** (`O(#probes·npK)`): scalable to `p = 10⁴`, but injects MC
  noise — must freeze probe vectors per fit and accept a slightly noisy gradient,
  or pair with a derivative-free / trust-region outer loop. **Ship second, gated
  behind a `p` threshold.**
- **Reduced-rank `u`** (§4.2): sidesteps the determinant entirely. **Offer as an
  option.**

---

## 5. Identifiability and numerical caveats

1. **`σ²` vs `Λ` confounding at low signal.** Both `u` and the `z`-factors add
   variance to `η`. With few sites or weak phylogenetic signal, `σ²` and the
   `Λ`-implied per-trait variance trade off. The Gaussian path already fights a
   version of this (the `σ_phy` sign-flip restarts in `fit.jl`); expect the
   non-Gaussian fit to need a sensible `σ²` floor and a warm start that does *not*
   start `σ²` at 0 (which would make the `u`-block ill-conditioned:
   `σ⁻²Σ_phy⁻¹ → ∞`).
2. **`σ → 0` limit.** The `u`-block `D = W_• + σ⁻²Σ_phy⁻¹` blows up; `û → 0` and
   the contribution must reduce **exactly** to the current iid marginal. This is
   both a correctness requirement and a numerical hazard (parameterise on
   `log σ`, and special-case / regularise the `σ→0` evaluation). Verifiable goal
   §7-G2.
3. **Mode-finder SPD.** Using Fisher weights keeps every `A_s` SPD and
   `S_u = σ⁻²Σ_phy⁻¹ + (W_• − S_data)` SPD **provided** `W_• − S_data ⪰ 0`. This
   holds because `S_data = Σ_s W_sΛ(ΛᵀW_sΛ+I)⁻¹ΛᵀW_s ⪯ Σ_s W_s = W_•` (each term
   is `W_s^{1/2}` times an orthogonal projector times `W_s^{1/2}`, `⪯ W_s`). So
   `S_u ⪰ σ⁻²Σ_phy⁻¹ ≻ 0`: **the Schur complement is SPD without damping** — a
   clean structural guarantee worth stating as a test (§7-G5). (Confirm this
   numerically as part of the build; the projector bound is exact for the Fisher
   form but the inner mode may not be fully converged, so a fallback ridge should
   exist.)
4. **CHOLMOD Float64 ⇒ no ForwardDiff through the node solves.** Same constraint
   as the Gaussian sparse path. Dictates: outer gradient is **finite-difference
   first** (consistent with every existing non-Gaussian fitter,
   `autodiff = :finite`), analytic adjoint later (§7 slice 6).
5. **Ordinal has no `β`.** Its intercept is the cutpoint vector. The `u_t`
   species effect still attaches per species/row; just note the packing differs
   (no `β` to add `u` "alongside" — `u` enters `η = (Λz)_t + u_t`, cutpoints stay
   global). Minor.

---

## 6. Parameterisation choices

- **Scalar `σ²`** (this spec's default): one structured-effect magnitude.
  Simplest; `log σ` packed into the optimiser vector like the existing
  dispersion parameters.
- **Per-trait `σ_phy[t]`**: the Gaussian path's `phylo_unique` form
  (`node_gradient.jl`). Strictly more general; the `u`-block becomes
  `diag(σ_phy) Σ_phy^{eff} diag(σ_phy)`-flavoured. Defer to a later slice; the
  scalar version is the right first target.
- **`Λ_phy` (phylogenetic latent factors)**: the Gaussian path also supports a
  *low-rank* structured term `Λ_phy η_phy`, `η_phy ~ N(0,Σ_phy)` per axis. This is
  exactly the reduced-rank `u` of §4.2 and is a natural unification — but it
  multiplies the latent dimension by `K_phy·p` and is a separate build. Out of
  scope for v1.
- **Dispersion (NB `r`, Beta `φ`, Gamma `ν`)**: unchanged; estimated jointly as
  now, just with `u` present in `η`.

---

## 7. Slice plan and verifiable goals

Each slice ends with a runnable check. The plan front-loads **correctness on
small `p`** (where a dense/quadrature oracle exists) before any scaling work.

**Slice 0 — `Σ_phy` interface + dense reference.** Define the covariance
abstraction (`apply_prec(Σ_phy⁻¹, v)`, `logdet_prec`, dense fallback +
`AugmentedPhy` node-frame impl). No fitting yet.
- *Goal G0:* `apply_prec` on an `AugmentedPhy` matches `inv(sigma_phy_dense(phy))
  * v` to ≤1e-10 on a small tree (reuse `sigma_phy_dense`, already in
  `sparse_phy.jl`).

**Slice 1 — joint Laplace marginal, DENSE `S_u`, ONE family (Poisson).**
Implement `h(z,u)`, block-arrow Newton (per-site `z_s` solves + Schur `u`-step),
exact dense `log det S_u`. FD outer gradient.
- *Goal G1 (Λ=0 reduction):* with `Λ = 0`, the GLLVM marginal must equal an
  independent phylogenetic-Poisson-GLMM marginal computed by a standalone Laplace
  over `u` only. Cross-check against a direct `p`-dim Laplace (no `z`). Agreement
  ≤1e-6 (Laplace-vs-Laplace, same approximation, so should be tight).
- *Goal G2 (σ→0 reduction):* as `σ → 0`, `joint marginal → current
  `poisson_marginal_loglik_laplace(Y, Λ, β)`. Check at `σ = 1e-4`: relative
  difference ≤1e-4, and monotone → 0 as `σ` shrinks.
- *Goal G3 (small-p quadrature cross-check):* for `p = 3`, `n = 5`, `K = 1`,
  compute the **exact** marginal by adaptive Gauss–Hermite quadrature over the
  `(nK + p) = 8`-dim latent (feasible at this size with sparse-grid GH or nested
  1-D GH on the conditionally-separable structure: integrate each `z_s` by GH
  given `u`, then the `p`-dim `u` by sparse-grid GH). The Laplace marginal must
  match the quadrature value to within the known Laplace error (expect ~1e-2–1e-3
  relative for these counts; report the actual gap, do **not** tune a tolerance
  to pass).

**Slice 2 — fit driver for Poisson, dense `S_u`.** Extend `fit_poisson_gllvm`
with `Σ_phy`/`phy` + `log σ` in the param vector; L-BFGS `autodiff=:finite`.
- *Goal G4 (parameter recovery):* simulate from the model (small `p`, moderate
  `n`), recover `(β, Λ, σ)` within Monte-Carlo CI over ~50 reps; `σ̂ → σ_true`,
  and the `σ=0`-simulated data recovers `σ̂ ≈ 0`.
- *Goal G5 (Schur SPD):* assert `S_u` is SPD at every accepted inner iterate on a
  battery of random configs (the §5.3 guarantee); log any fallback-ridge events.

**Slice 3 — generalise to the scalar-`μ` families** (Binomial, NB, Beta, Gamma)
via the existing `_glm_score`/`_glm_weight` dispatch. Ordinal as a follow-up
(its own mode loop). Each family: re-run G1–G4 analogues.
- *Goal G6:* every family passes the Λ=0 and σ→0 reductions and a small-p
  recovery.

**Slice 4 — sparse node-frame `Σ_phy⁻¹` + matrix-free `S_u` apply.** Swap the
dense prec for the `AugmentedPhy` node solve; make `S_u v` matrix-free O(npK).
Keep the **dense determinant** for now.
- *Goal G7 (sparse==dense):* node-frame marginal matches the dense-`Σ_phy`
  marginal to ≤1e-8 on a small tree (the same equivalence the Gaussian path
  verifies).
- *Goal G8 (scaling of the apply):* empirical `S_u`-apply time scales ~linearly
  in `p` on balanced trees (report the slope, as `bench/sparse_phy_grad_bench.jl`
  does for the Gaussian gradient).

**Slice 5 — scalable determinant (SLQ), gated by `p`.** Add stochastic-Lanczos
`log det S_u` with frozen probes; auto-select dense (small `p`) vs SLQ (large
`p`).
- *Goal G9:* SLQ logdet matches dense logdet to within probe-count-controlled
  tolerance on mid-`p`; the *fitted* parameters from SLQ-objective match
  dense-objective fits to within optimiser tolerance.

**Slice 6 — analytic adjoint (optional, performance).** Hand-code `∂L/∂θ` (the
TMB/`sparse_phy_grad.jl` pattern) to replace finite differences, reusing
`takahashi_diag` for the trace terms.
- *Goal G10:* analytic gradient matches central FD of the marginal to rel<1e-6
  (the bar `node_gradient.jl` already meets for the Gaussian case).

**Slice 7 — ADEMP simulation cells.** Per CLAUDE.md "Planned next" and the
Morris/Williams framework: add structured-effect cells (vary `σ²`, tree
size/shape, `n`, family) to the external benchmark repo.

---

## 8. Feasibility verdict and size estimate

**Verdict: a reasonable but substantial engineering build, with one genuinely
research-grade subproblem (the scalable exact determinant at large `p`).**

- **Correctness and the small/medium-`p` build are engineering, not research.**
  The block-arrow Hessian, Schur-complement factorisation, and conditional-on-`u`
  separability are textbook (this is the standard latent-Gaussian Laplace, and
  `glmmTMB`/TMB do exactly it). The per-observation atoms already exist and are
  FD-verified. The node-frame sparse solves already exist for the Gaussian case.
  Slices 0–4 are well-posed.
- **The research-grade edge is `log det S_u` at `p = 10⁴` with site-varying
  weights.** The Gaussian path gets an O(p) determinant because its `B`-block is
  data-independent; here the `W_s` differ across sites and inject an `nK`-rank
  dense perturbation with no sparse structure, so the clean O(p) determinant does
  **not** transfer. The realistic answers are *exact-dense (moderate `p`)* or
  *SLQ-approximate (large `p`, MC-noisy objective)* — both are known techniques,
  but tuning SLQ to give a smooth-enough objective for L-BFGS, or pairing it with
  a noise-tolerant optimiser, is the part that needs experimentation rather than
  just implementation. This is the same honest ceiling already written into
  `src/sparse_phy_grad.jl`'s header for the Gaussian gradient.

**Size estimate (rough, for the maintainer working in this codebase's style):**

| slices | content | effort |
|---|---|---|
| 0–2 | interface + joint Laplace + Poisson fit, **dense `S_u`**, FD gradient, validated to small-p quadrature | ~1 focused week |
| 3 | roll out to the other scalar-μ families + ordinal | ~2–4 days |
| 4 | sparse node-frame `Σ_phy⁻¹`, matrix-free `S_u` | ~3–5 days |
| 5 | SLQ determinant + `p`-gating (the risky one) | ~1–2 weeks incl. tuning |
| 6 | analytic adjoint | ~1 week |
| 7 | ADEMP cells | external repo, ~few days |

So: **a usable, correct, small-to-medium-`p` feature in ~2 weeks; the
fully-scalable large-`p` version is a multi-week research-flavoured push.** This
matches the package's stated "Planned next" sequencing (get Laplace families
right first; structured dependence is the stage after). It is a reasonable build
to commit to *if* the first deliverable is scoped to the dense-determinant,
moderate-`p` regime and the large-`p` determinant is treated as a separate,
explicitly-research milestone.

**Recommendation:** build slices 0–3 (dense `S_u`, all families, FD gradient,
validated against quadrature and the two reductions) as the v1 of structured
non-Gaussian support, ship it with an honest `p` ceiling in the docstring, and
treat slices 5–6 as a follow-on performance project — exactly the way the
Gaussian sparse path was staged (value first, then analytic gradient, then the
documented O(p²) determinant ceiling).

---

## 9. Reproduction: the FD score check (§3.7)

Run from the repo root (`~/.juliaup/bin/julialauncher --project=. -e '…'`). The
script evaluates each family's `∂ℓ/∂η` analytically (the codebase's `_glm_score`
formulas) and against central differences of `Distributions.logpdf`, printing the
residual. Verbatim output is in §3.7 (max residual 1.8e-9).

```julia
using Distributions, SpecialFunctions, Printf
logit(x)=log(x/(1-x)); logistic(η)=1/(1+exp(-η))
# Poisson:  s=(y-μ),  μ=exp(η)
# Binomial: s=(y-nμ), μ=logistic(η)
# NB2:      s=(y-μ)/(μ+μ²/r)*μ
# Beta:     s=φ(logit(y) - [ψ(μφ)-ψ((1-μ)φ)])·μ(1-μ)
# Gamma:    s=ν(y-μ)/μ
# Ordinal:  s=(f(τ_{c-1}-η)-f(τ_c-η))/P(y=c),  f=logistic·(1-logistic)
# For each: fd = (logpdf(η+1e-6)-logpdf(η-1e-6))/2e-6 ; assert abs(s-fd) < 1e-8
```

(The full loop with the three test points per family is what produced the §3.7
residuals; reproduce by expanding each line to evaluate `logpdf` at the matching
`Distributions` constructor — `Poisson(exp η)`, `Binomial(n, logistic η)`,
`NegativeBinomial(r, r/(r+μ))`, `Beta(μφ,(1-μ)φ)`, `Gamma(ν, μ/ν)`, and the
cumulative-logit `P(y=c)` for ordinal.)

---

## 10. References

Phylogenetic / structured GLMMs:
- Hadfield, J.D. (2010). MCMC methods for multi-response generalised linear mixed
  models: the **MCMCglmm** R package. *J. Stat. Soft.* 33(2). — phylogenetic GLMM
  via MCMC; the ground-truth oracle for §7 validation.
- Hadfield, J.D. & Nakagawa, S. (2010). General quantitative genetic methods for
  comparative biology. *J. Evol. Biol.* 23. — augmented-state sparse precision
  (already the basis of `src/sparse_phy.jl`).
- Ives, A.R. & Helmus, M.R. (2011). Generalized linear mixed models for
  phylogenetic analyses of community structure. *Ecol. Monogr.* 81. — the PGLMM
  this spec implements (`Λ=0` case).
- Brooks, M.E. et al. (2017). **glmmTMB** balances speed and flexibility…
  *R Journal* 9(2). — Laplace-marginal GLMM via TMB; the engineering template for
  the joint Laplace + structured covariance.
- Niku, J., Hui, F.K.C., Taskinen, S. & Warton, D.I. (2019/2021). **gllvm**:
  Fast analysis of multivariate abundance data (`method="LA"`/`"VA"`). *Methods
  Ecol. Evol.* — the GLLVM reference; note its phylogenetic support
  (`gllvm(..., colMat=)` / `phylo` random effects in recent versions) is the
  closest existing analogue and uses VA + a sparse phylogenetic precision.
- Henderson, C.R. (1976). Rapid method for computing the inverse of a numerator
  relationship matrix. *Biometrics* 32. — sparse `A⁻¹` for the animal-model
  use-case.

Laplace / INLA / sparse latent-Gaussian:
- Kristensen, K. et al. (2016). **TMB**: Automatic Differentiation and Laplace
  Approximation. *J. Stat. Soft.* 70(5). — the sparse-Cholesky analytic-adjoint
  pattern (already cited in CLAUDE.md; the template for slice 6).
- Rue, H., Martino, S. & Chopin, N. (2009). Approximate Bayesian inference for
  latent Gaussian models using **INLA**. *JRSS-B* 71. — the nested-Laplace
  approach for exactly this model class (the §4.3 "right tool, big departure").
- Lindgren, F., Rue, H. & Lindström, J. (2011). An explicit link between Gaussian
  fields and Gaussian Markov random fields: the **SPDE** approach. *JRSS-B* 73. —
  sparse precision for the spatial use-case.
- Banerjee, S., Gelfand, A.E., Finley, A.O. & Sang, H. (2008). Gaussian
  predictive process models. *JRSS-B* 70; **and** Datta, A. et al. (2016).
  Nearest-neighbour Gaussian processes (**NNGP**). *JASA* 111. — reduced-rank /
  sparse spatial `u` (§4.2 fallback).

Numerics:
- Takahashi, K. (1973); Erisman, W.F. & Tinney, W.F. (1975). Selected-inverse
  recursion — the node-diagonal trace pieces (already in `takahashi_selinv.jl`).
- Ubaru, S., Chen, J. & Saad, Y. (2017). Estimating `tr(f(A))` via stochastic
  Lanczos quadrature. *SIAM J. Matrix Anal.* 38. — the scalable `log det S_u`
  of slice 5.

Simulation reporting:
- Morris, T.P., White, I.R. & Crowther, M.J. (2019). Using simulation studies to
  evaluate statistical methods. *Stat. Med.* 38; Williams, M.N. et al. (2024)
  (MEE). — ADEMP cells for slice 7 (already cited in CLAUDE.md).
