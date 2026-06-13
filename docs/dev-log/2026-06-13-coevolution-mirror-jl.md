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
- **extract_Gamma (Julia) — IN PROGRESS.** Slice the host×partner block of
  Λ Λᵀ from a fitted GllvmFit. Pending engine mapping (which fit field holds Λ).
- **Γ-recovery gate — IN PROGRESS / feasibility check.** Fit the stacked
  block-NA two-lineage model with `Σ_phy = K*`; assert Γ̂ recovers Γ_true
  (Procrustes-tolerant corr > 0.9), null K* = blockdiag → Γ̂ ≈ 0 + worse logLik.
  Open question (being mapped): does GLLVM.jl jointly support block-NA response +
  a dense user `Σ_phy`? If not, the faithful fallback is a complete-data stacked
  recovery that still validates the Γ = Λ_H Λ_Pᵀ machinery, deferring block-NA.

## R reference anchors (source of truth for the mirror)

- `gllvmTMB/R/kernel-helpers.R` — `make_cross_kernel` (mirrored).
- `gllvmTMB/tests/testthat/test-coevolution-recovery.R` — the DGP + recovery
  gate to mirror (trees → A via `ape::vcv(corr=TRUE)`, W = exp(-|Δ|/0.35),
  known Λ_H/Λ_P, Γ_true = Λ_H Λ_Pᵀ, ψ, residual sd, block-NA stacking, n_rep).
- `gllvmTMB/R/extract-sigma.R` — `extract_Gamma(fit, level, row_traits, col_traits)`.

## Next

extract_Gamma (TDD) → recovery gate (TDD, feasibility-gated) → worked example →
after-task note + check-log. Then the missing-predictor `mi()` axis.
