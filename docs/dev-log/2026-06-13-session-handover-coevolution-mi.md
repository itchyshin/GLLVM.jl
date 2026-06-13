# Session handover — coevolution + mi() axes (2026-06-13)

**Branch:** `coevolution-kernel` (worktree `GLLVM.jl-coevolution`) off
`consolidation-candidate` (`8690e8f`). **8 commits, unpushed** (no-push rule
held). Tree clean. The maintainer asked to finish the twin pair, "coevolution
first, then mi() etc.", and to follow the recorded order (R reference → Julia
mirror).

## What landed (all TDD, all green)

| Slice | File | Tests | Note |
|---|---|---|---|
| `make_cross_kernel` | `src/cross_kernel.jl` | 14/14 | cross-lineage kernel K*; **byte-identical to R (5.6e-17)** |
| `extract_Gamma` | `src/extract_gamma.jl` | 6/6 | Γ = Λ_phy Λ_phyᵀ block; rotation-invariant |
| cross-kernel fit/null | `test/test_cross_kernel_fit.jl` | 7/7 | K* beats the block-diagonal null by a wide logLik margin |
| `fit_gaussian_mi_fiml` | `src/missing_predictor_fiml.jl` | 9/9 · 11/11 slow | site-level missing predictor, closed-form FIML; beats complete-case under MAR |
| `fit_gaussian_mi_phylo` | `src/missing_predictor_phylo.jl` | 9/9 | **species-level phylo missing predictor (the high-value Phase 3)** |

**45 tests fast · 47 with `GLLVM_SLOW_TESTS=1`.** All five test files coexist
green; module loads clean (additive: 5 src includes + 5 exports + 5 test
includes). Full `Pkg.test()` (~25 min) is your terminal-side gate.

## Verification highlights

- **Cross-package parity** `make_cross_kernel`: max |K_julia − K_R| = **5.6e-17**.
- **Phylo-FIML marginal** validated vs a brute-force joint Gaussian: **3.6e-15**.
- **AD-clean** (ForwardDiff vs central FD): cross-kernel fit and both mi() drivers
  ≤ **1.7e-7** (the repo's ≤1e-6 gate; b_x enters the covariance).
- **MAR recovery**: FIML unbiased (+0.001) vs complete-case biased (−0.068),
  bias-ratio ≈ **3.0** over 50 reps.
- **Missing-response foundation** on this trunk: `test_missing_data.jl` 34/34.

## The one real correction this session

The handoff/plan said gllvmTMB coevolution was green-field — it is **not**:
gllvmTMB ships C0–C3 on `origin/main`. The green-field was **GLLVM.jl**, so the
Julia mirror IS the recorded next step. (Evidence-first rehydration caught this.)

## Decisions / gaps awaiting you

1. **Push `coevolution-kernel`?** 8 clean commits, local-only.
2. **Coevolution faithful recovery needs a Kronecker engine.** GLLVM.jl's phylo
   marginal is the Hadamard single-realisation form `B = (Λ_phy Λ_phyᵀ).*Σ_phy`,
   not R's trait⊗species Kronecker — so one dataset identifies Λ_phy only weakly
   (probe |cor(Γ̂,Γ_true)| ≈ 0.05–0.31). A faithful Γ-recovery gate (matching R's
   >0.9) needs a new Kronecker trait⊗species phylo fitter + a block-NA Σ_phy
   path. Substantial — flagged, NOT built autonomously. (See
   `2026-06-13-coevolution-mirror-jl.md`.)
3. **gllvmTMB CRAN** (`cran-bridge-docs` worktree): the #486 PDF-manual Unicode
   blocker is **verified clear** (R CMD Rd2pdf builds the 145-page manual, no
   Unicode errors). Remaining: 2 invalid DOIs + 3 `\doi{}`-URL notes (the
   bioRxiv DOI `10.1101/2025.12.20.695312` needs your confirmation — likely your
   own preprint; I won't fabricate a DOI).

## Recommended next slices (autonomous-ready)

- mi() polish: `mi(x)` formula token + `Z` covariate-model regressors (small).
- Non-Gaussian / discrete missing predictors (Laplace augmented-latent track).
- The Kronecker coevolution engine (needs your scoping first).

## Anchors

`docs/dev-log/2026-06-13-coevolution-mirror-jl.md`,
`after-task/2026-06-13-coevolution-mirror-c0c2.md`,
`2026-06-13-mi-predictor-fiml-jl.md`. R reference:
`gllvmTMB/R/kernel-helpers.R`, `R/extract-sigma.R`,
`docs/design/65-cross-lineage-coevolution-kernel.md`.
