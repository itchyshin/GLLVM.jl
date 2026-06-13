# Faithful coevolution recovery — the Kronecker (matrix-normal) fitter

**Status:** design + implementation plan (2026-06-13). Addresses the gap flagged
in `2026-06-13-coevolution-mirror-jl.md`: the shipped Hadamard cross-kernel fit
proves K\* is necessary (logLik contrast) but **cannot recover Γ tightly** from a
single dataset (probe |cor(Γ̂,Γ_true)| ≈ 0.05–0.31). The R twin recovers Γ to
>0.9 because it uses a **trait⊗species Kronecker** identifiability. This is the
plan to give GLLVM.jl the same.

## Why the Hadamard form can't recover Γ

GLLVM.jl's phylo marginal is `B = (Λ_phy Λ_phyᵀ) .* Σ_phy` on a SINGLE index p
(rows of Y), shared across sites — one realisation, rank-limited. R's coevolution
is `Var(vec η) = (Λ Λᵀ + Ψ) ⊗ K*` with the **trait** dimension T and the
**species** dimension n_species kept separate; Λ (T×d) is identified from
covariation across the many species. Different factorisations ⇒ different
identifiability.

## The faithful model (matrix-normal)

Stack host+partner traits into T = T_H + T_P, host+partner species into
n = n_H + n_P, with K\* = `make_cross_kernel(A_H, A_P, W, ρ)` over species. With
one observation per species (complete data):

    Y  (T × n)  ~  MN(0, Σ_T, K*),   Σ_T = Λ Λᵀ + σ² I_T   (T×T, Λ is T×d)

i.e. `Cov(vec Y) = K* ⊗ Σ_T`. The coevolution estimand is the host×partner block
of the trait covariance:

    Γ = (Λ Λᵀ)[1:T_H, (T_H+1):T]            # host-trait × partner-trait

Γ is identified (up to rotation, which cancels in Λ Λᵀ) because Λ is estimated
from cross-species covariation — exactly the R identifiability.

## Marginal likelihood — the Kronecker eigentrick (O(n³ + T³))

Eigendecompose the species kernel once: `K* = V diag(d) Vᵀ` (d = eigenvalues).
Rotate the species axis: `Ỹ = Y V` (T×n). Then the columns of Ỹ are independent,
`Ỹ[:,j] ~ N(0, d_j Σ_T)`, so

    −2 logL = T n log(2π) + T Σ_j log(d_j) + n logdet(Σ_T)
              + tr( Σ_T⁻¹ · Ỹ diag(1/d_j) Ỹᵀ )

Cost: one n×n eigendecomposition of K\* (constant across the optimisation) + a
T×T solve of Σ_T = ΛΛᵀ+σ²I per NLL eval. Optimise [vec(Λ), log σ] with
L-BFGS + ForwardDiff (Σ_T cholesky is AD-clean; the K\* eigendecomp is constant
data). Validate the closed form against a brute-force `MN`/`kron` density to
machine precision FIRST (as for the phylo-FIML marginal).

## API + slice

    fit_coevolution_gaussian(Y, K_star; d, ...) -> NamedTuple
      # Y: T×n (traits × species, host block first); returns Λ (T×d), σ,
      #    logLik, converged, and Γ via extract_Gamma on the trait loadings.

`extract_Gamma` already slices a `Λ Λᵀ` block — reuse it (this fitter's Λ is the
*trait* loadings, so the existing `extract_Gamma(fit; row_traits, col_traits)`
applies directly once the fit exposes `Λ_phy = Λ`).

## Verification (the headline gate, matching R)

`test_coevolution_kronecker.jl`:
1. **Marginal correctness:** closed-form −2logL == brute-force `logpdf(MvNormal(0,
   kron(K*, Σ_T)), vec(Y))` to ≤1e-8.
2. **Known-Γ recovery (the win the Hadamard form lacked):** DGP with planted
   Λ_H/Λ_P, Γ_true = Λ_H Λ_Pᵀ, simulate Y ~ MN(0, ΛΛᵀ+σ²I, K*); fit; assert
   `|cor(vec(Γ̂), vec(Γ_true))| > 0.9` (Procrustes-tolerant, as R
   test-example-coevolution-kernel.R:114-120).
3. **Null contrast:** K*_null = blockdiag(A_H, A_P) fits strictly worse.
4. **AD-clean:** ForwardDiff vs central FD ≤1e-6.

## Scope / deferred

- **Complete data only** (every species has every trait). The faithful R model
  also handles **block-NA** (host species lack partner traits) — that breaks the
  clean Kronecker eigentrick (per-species observed-trait subsets ⇒ a per-species
  Woodbury). Deferred as a follow-on, exactly as the Gaussian block-NA path is.
- **Replication** (multiple individuals/sites per species) adds an `I_rep ⊗`
  block — a later extension; one-obs-per-species is the smallest faithful slice.
- Per-trait uniqueness Ψ (vs a single σ²) is a small generalisation.

## Why this is a standalone fitter, not engine surgery

It's a self-contained matrix-normal fit (like `make_cross_kernel` /
`fit_gaussian_mi_*`), NOT a change to the main `fit_gaussian_gllvm` path. So it
ships without touching the existing Gaussian engine, and the Hadamard
fit-contrast test stays as the "K\* is necessary" evidence while this adds the
"Γ is recovered" evidence.
