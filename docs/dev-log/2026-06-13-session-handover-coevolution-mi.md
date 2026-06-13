# Session handover — coevolution + mi() axes (2026-06-13)

**Branch:** `coevolution-kernel` (worktree `GLLVM.jl-coevolution`) off
`consolidation-candidate` (`8690e8f`). **10 commits, unpushed** (no-push rule
held). Tree clean. The maintainer asked to finish the twin pair, "coevolution
first, then mi() etc.", and to follow the recorded order (R reference → Julia
mirror). **gllvmTMB CRAN work is on a separate branch — see the end.**

## What landed (all TDD, all green)

| Slice | File | Tests | Note |
|---|---|---|---|
| `make_cross_kernel` | `src/cross_kernel.jl` | 14/14 | cross-lineage kernel K*; **byte-identical to R (5.6e-17)** |
| `extract_Gamma` | `src/extract_gamma.jl` | 6/6 | Γ = Λ_phy Λ_phyᵀ block; rotation-invariant |
| cross-kernel fit/null | `test/test_cross_kernel_fit.jl` | 7/7 | K* beats the block-diagonal null by a wide logLik margin |
| `fit_gaussian_mi_fiml` | `src/missing_predictor_fiml.jl` | 9/9 · 11/11 slow | site-level missing predictor, closed-form FIML; beats complete-case under MAR |
| `fit_gaussian_mi_phylo` | `src/missing_predictor_phylo.jl` | 9/9 | **species-level phylo missing predictor (the high-value Phase 3)** |
| mi() covariate model `Z` | `test/test_missing_predictor_z.jl` | 6/6 | `x ~ N(μ_x + Zγ, σ_x²)`; `Z=nothing` ≡ old fit to 1e-8 |
| `fit_coevolution_gaussian` | `src/coevolution_kronecker.jl` | 5/5 | **faithful Kronecker coevolution — RECOVERS Γ to \|cor\|>0.9** (closes the gap) |
| `fit_coevolution_blockna` | `src/coevolution_blockna.jl` | 4/4 · 6/6 slow | **block-NA coevolution** (host/partner each measure own traits); M exact; recovery scales with association |
| non-Gaussian mi (Poisson+Binomial) | `src/missing_predictor_poisson.jl` | 6/6 | **the hardest mi() phase (5a)** — augmented (z,x) Laplace; 3 oracles/family incl. 2-D Gauss–Hermite |

**~66 tests fast · 70 with `GLLVM_SLOW_TESTS=1`**, all coexisting green. The
**coevolution frontier is complete** (kernel · extract_Gamma · Hadamard contrast ·
faithful complete-data Kronecker · block-NA); the **mi() axis** spans Gaussian
site-level (2a) · `Z` covariate-model · phylo (3) · non-Gaussian Poisson+Binomial
(5a). Module loads clean (additive includes/exports). Base `runtests.jl` was
**3479 pass / 0 fail**; the new slices verified individually + in combined runs.

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

1. **Push `coevolution-kernel`?** 13 clean commits, local-only.
2. **Coevolution faithful recovery — DONE (no longer just a flag).** The Hadamard
   marginal `B = (Λ_phy Λ_phyᵀ).*Σ_phy` recovers Γ only weakly (probe ≈
   0.05–0.31), so I built the faithful path: `fit_coevolution_gaussian` — a
   standalone Kronecker matrix-normal fitter `Y ~ MN(0, ΛΛᵀ+σ²I, K*)` that
   **recovers Γ to |cor|>0.9**, matching R. Math validated to 1.1e-14; 5/5 tests.
   Complete-data only; **block-NA Σ_phy + replication still deferred** (the hard
   part). See `2026-06-13-coevolution-kronecker-design.md`. Your call whether to
   keep both (Hadamard fit = "K* necessary"; Kronecker = "Γ recovered") or fold.
3. **gllvmTMB CRAN** (`cran-bridge-docs` worktree, commit `c1dfb3e`): **both
   gating items now fixed.** PDF-manual Unicode cleared (`93640b7`, R CMD Rd2pdf
   builds the 145-page manual clean). DOI notes fixed + verified vs doi.org /
   CrossRef: bioRxiv DOI → `10.64898/2025.12.20.695312` (the old `10.1101` prefix
   404s); the Felsenstein (2005) reference corrected to *Phil. Trans. R. Soc. B*
   360:1427–1434 / `10.1098/rstb.2005.1669` (the cited `Genetics 169:925–942 /
   10.1534/...` is the wrong journal + a non-resolving DOI — **please sanity-check
   this citation correction**); 3 `\url{doi.org}` → `\doi{}`. Submit-ready bar a
   final `--as-cran` re-run, the pre-existing NEWS.md note (your call), and your
   submission. cran-comments.md updated.

## gllvmTMB CRAN — submit-ready

`cran-bridge-docs` is `0 errors`, `1 environmental warning`, `New submission` +
the tolerated NEWS.md note. The two earlier blockers (Unicode, DOIs) are both
cleared on-branch and verified. Your remaining steps: final `--as-cran`, decide
the NEWS reorg-vs-accept, and submit.

## Recommended next slices (autonomous-ready)

- mi() polish: `mi(x)` formula token (deferred — @formula front-end is v1) + `Z`
  for the phylo driver. (Site-level `Z` is DONE.)
- Non-Gaussian / discrete missing predictors (Laplace augmented-latent track).
- The Kronecker coevolution engine (needs your scoping first).

## Anchors

`docs/dev-log/2026-06-13-coevolution-mirror-jl.md`,
`after-task/2026-06-13-coevolution-mirror-c0c2.md`,
`2026-06-13-mi-predictor-fiml-jl.md`. R reference:
`gllvmTMB/R/kernel-helpers.R`, `R/extract-sigma.R`,
`docs/design/65-cross-lineage-coevolution-kernel.md`.
