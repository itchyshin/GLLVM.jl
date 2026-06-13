# After-task — cross-lineage coevolution mirror (C0/C2) into GLLVM.jl

**Branch:** `coevolution-kernel` off `consolidation-candidate` (`8690e8f`).
Unpushed (no-push rule). Commits `f2b054d`, `8b544e0`, `ab3d249`, `cbffc91`.

## Goal

Mirror gllvmTMB's cross-lineage coevolution (PGLLVM "two lineages") into the
Julia engine, following the recorded order (R leads — and C0–C3 already ship on
gllvmTMB `origin/main`, so the Julia mirror IS the recorded next step).

## Shipped (impl + tests, TDD)

- **`make_cross_kernel`** (`src/cross_kernel.jl`, exported) — the block
  coevolution kernel `K* = [A_H C_HP; C_HPᵀ A_P]`, `C_HP = ρ·L_H·W̃·L_Pᵀ`.
  `test_cross_kernel.jl` **14/14**. **Cross-package parity VERIFIED**: vs the R
  twin on the shared toy inputs, `max|K_julia − K_R| = 5.6e-17` (machine eps) —
  byte-identical. (Manual RCall-free check: sourced `gllvmTMB/R/kernel-helpers.R`;
  a gated `test/parity` lock is a cheap follow-on.)
- **`extract_Gamma`** (`src/extract_gamma.jl`, exported) — the coevolution
  estimand `Γ = (Λ_phy Λ_phyᵀ)[host, partner]`. `test_extract_gamma.jl` **6/6**
  (slice, rotation-invariance, validation). Positional integer indices (Julia
  idiom; R is name-based).
- **Cross-kernel fit + null contrast** — `test_cross_kernel_fit.jl` **7/7**: a
  complete-data stacked two-lineage Gaussian fit with `Σ_phy = K*` converges,
  `extract_Gamma` slices the fitted block, and **K\* beats the rho = 0 null by a
  wide logLik margin** (probe: +1900…+3200 at n = 400).

All three test files wired into `runtests.jl`. Each function watched RED
(`UndefVarError`) → GREEN before wiring.

## Honest scope (verified, not a defect)

The engine has **no block-NA + dense-Σ_phy path**, and its phylo marginal is the
**Hadamard single-realisation** form `B = (Λ_phy Λ_phyᵀ).*Σ_phy` (not R's
trait⊗species Kronecker). A single dataset therefore identifies `Λ_phy` only
weakly — the probe measured `|cor(Γ̂, Γ_true)| ≈ 0.05–0.31`, far below the R
twin's >0.9. So this slice asserts the **cross-vs-null logLik contrast**, NOT
tight Γ recovery. Verified by workflow `wf_a70e7327-455` + a Julia probe.

## Deferred (maintainer-gated engine track)

A *faithful* R-equivalent coevolution mirror needs a **Kronecker trait⊗species
phylo path** (multi-species replication ⇒ `Γ = Λ_H Λ_Pᵀ` identifiable) and/or a
**block-NA composition for `Σ_phy`**. Both are substantial new fitters — flagged
for maintainer scoping, NOT built autonomously.

## Verification tally

`make_cross_kernel` 14/14 · `extract_Gamma` 6/6 · cross-kernel fit 7/7 · parity
5.6e-17. Full `Pkg.test()` (~25 min, Aqua/JET + COM-Poisson) is the maintainer's
terminal-side gate; new files are additive (3 src includes + 2 exports + 3 test
includes), module loads clean, Gaussian fit path exercised green.

## Next

Missing-predictor `mi()` axis (the user's "then mi()").
