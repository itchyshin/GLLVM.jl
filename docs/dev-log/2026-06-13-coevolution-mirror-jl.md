# Cross-lineage coevolution — Julia mirror (PGLLVM "two lineages")

**Branch:** `coevolution-kernel` (worktree `GLLVM.jl-coevolution`), off
`consolidation-candidate` (`8690e8f`). Unpushed — no-push rule holds.

## Why this branch

The maintainer's standing goal is to finish the twin pair; the named frontier is
cross-lineage coevolution ("PGLLVM two lineages") + missing-predictor `mi()`.
Plan of record: `~/.claude/plans/please-have-a-robust-elephant.md` (phases
C0–C5), which says **gllvmTMB leads + implements, then mirror to GLLVM.jl**.

**Evidence-first correction (2026-06-13):** the R side is *not* green-field.
gllvmTMB ships **C0–C3 on `origin/main`** — `make_cross_kernel`,
`kernel_latent/kernel_unique` engine, `extract_Gamma`, the Γ-recovery gate, the
two-kernel + two-Ψ identifiability guardrail, and a methods-grade coevolution
article (commits incl. `6a467bf` #368, `7e98904`, `214023d` #439; design doc
`docs/design/65-cross-lineage-coevolution-kernel.md`). The handoff's "absent"
was about **GLLVM.jl (Julia)**. So the recorded-order prerequisite (C0 in R) is
already satisfied, and the live frontier is the **Julia mirror** — building it
*is* following the recorded order.

## The model (contract)

Stack two lineages H (host) and P (partner) into one block response with
structural NA off-diagonal blocks, and a block species covariance

    K* = [ A_H    C_HP ;          C_HP = rho * L_H * W̃ * L_P'
           C_HP'  A_P  ]          (L L' = A; W̃ = W spectrally scaled, PSD)

Per latent tier: G ~ N(0, K*), loadings Λ (T×d), per-trait uniqueness ψ.
Coevolution estimand: **Γ = Λ_H Λ_Pᵀ** (host-trait × partner-trait block of the
shared loadings), sliced post-fit. Null is rho = 0 → block-diagonal, Γ = 0.

## Slice status

- **C0.helper — `make_cross_kernel` — DONE** (`f2b054d`). `src/cross_kernel.jl`
  + export; `test/test_cross_kernel.jl` 14/14 (structural props, cross-block
  math L_H·W̃·L_P', rho-scaling + rho=0 null, validation). Same toy inputs as the
  gllvmTMB docstring example ⇒ byte-identical K* across the twins. TDD: watched
  RED (`UndefVarError`) → GREEN.
- **extract_Gamma — DONE.** `src/extract_gamma.jl` + export;
  `test/test_extract_gamma.jl` 6/6 (slices the host×partner block of
  Λ_phy Λ_phyᵀ, rotation-invariant, validation). Slices from `fit.pars.Λ_phy`
  (the phylo tier), positional integer indices (Julia idiom; R is name-based).
- **Cross-kernel fit + null contrast — DONE (in place of a tight Γ-recovery
  gate).** `test/test_cross_kernel_fit.jl` 7/7: a complete-data stacked
  two-lineage Gaussian fit with `Σ_phy = K*` converges, `extract_Gamma` slices
  the fitted block, and **K\* beats the block-diagonal (rho = 0) null by a wide
  logLik margin** (empirically +1900…+3200 at n = 400). The null forces the
  cross block to zero. This validates the coevolution machinery end to end.

## Engine findings (empirical, verified 2026-06-13)

Two structural facts decided the recovery slice (mapped by workflow
`wf_a70e7327-455`, then confirmed by a Julia probe):

1. **No block-NA + dense Σ_phy path.** `fit_gaussian_gllvm` has no mask/missing
   parameter and the Gaussian phylo marginal uses the `I_n⊗A + J_n⊗B` rank-1
   site trick that assumes complete data; `fit_mixed_gllvm` (the only NA-aware
   fitter) has no `Σ_phy`. So the *literal* block-NA two-lineage fit is not
   expressible — deferred. The complete-data stacked fit is the faithful subset.
2. **Hadamard single-realisation phylo ≠ R's Kronecker.** GLLVM.jl's phylo block
   is `B = (Λ_phy Λ_phyᵀ) .* Σ_phy` on a single shared-across-sites realisation,
   whereas gllvmTMB uses a trait⊗species Kronecker with many species. So a single
   dataset identifies Λ_phy only weakly — the probe measured |cor(Γ̂,Γ_true)| ≈
   0.05–0.31, far below the R twin's >0.9. **The honest deliverable asserts the
   cross-vs-null logLik contrast, not tight Γ recovery.**

**Follow-on engine track (for a faithful R-equivalent mirror):** add a Kronecker
trait⊗species phylo path (multi-species replication) so Γ = Λ_H Λ_Pᵀ is
identifiable, and/or a block-NA composition for `Σ_phy`. Both are substantial,
out of scope for these C0/C2 slices; flagged for maintainer review.

## R reference anchors (source of truth for the mirror)

- `gllvmTMB/R/kernel-helpers.R` — `make_cross_kernel` (mirrored).
- `gllvmTMB/tests/testthat/test-coevolution-recovery.R` — the DGP + recovery
  gate to mirror (trees → A via `ape::vcv(corr=TRUE)`, W = exp(-|Δ|/0.35),
  known Λ_H/Λ_P, Γ_true = Λ_H Λ_Pᵀ, ψ, residual sd, block-NA stacking, n_rep).
- `gllvmTMB/R/extract-sigma.R` — `extract_Gamma(fit, level, row_traits, col_traits)`.

## Next

C0/C2 mirror is functionally complete for the engine's native orientation
(`make_cross_kernel` + `extract_Gamma` + cross-vs-null fit). Remaining for a
*faithful* R-equivalent mirror is the Kronecker engine track above (maintainer
decision). Then: the missing-predictor `mi()` axis (the user's "then mi()").
