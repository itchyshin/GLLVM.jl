# P2 repair pass — diagnostics.jl / extractors.jl / twolevel.jl

Source: `docs/dev-log/core070/post-m2-slice-review-2026-09-01.md` (post-M2
slice adversarial review, 2026-09-01). Six CONFIRMED defects assigned to this
repair lane. TDD red-first, one commit per defect, standalone
`test/test_diagnostics.jl` + `test/test_extractors.jl` runs pasted below each.

## 1. Principal angles (`diagnose_kernel_separability`, `compare_loadings`)

**Bug**: `svd(Λ_B'Λ_W).S` (or `svd(Λ1'Λ2).S`) on raw, non-orthonormal loading
matrices is not `cos(principal angle)`. Identical column spaces spanned by
small-magnitude or differently-scaled bases could report a large angle
("separable") when the true angle is 0.

**Fix**: new `_principal_angles(A, B)` helper — orthonormalize each column
space via thin QR first, then `svd(QA'QB).S` clamped to `[0,1]`, `acos.(...)`
(Björck & Golub 1973 construction). Both `diagnose_kernel_separability` and
`compare_loadings` now call it.

**Tests added**: `diagnose_kernel_separability — identical (non-orthonormal)
column spaces are NOT separable` and `compare_loadings — proper principal
angles for a small-magnitude identical subspace`, both reproducing the
review's `Λ_B = Λ_W = 0.2·ones(4,1)` scenario (old code: angle ≈ 1.41 rad;
fixed code: angle ≈ 0).

Commit: `884576c9`.

## 2. `gllvmTMB_diagnose` implied-Σ (all tiers)

**Bug**: the boundary-flag scan's implied `Σ_y` was built as `ΛΛᵀ +
σ_eps²·I`, ignoring `Λ_W`, `σ²_B`, `σ²_W` on multi-tier `GllvmFit`s — under-
counting the diagonal and over-reporting off-diagonal correlation, tripping
spurious `correlation_near_boundary` flags on genuinely well-separated fits.

**Fix**: `_implied_Sigma_y(fit::GllvmFit) = sigma_y_site(fit)` (all
non-phylo tiers, the existing machinery). Other fit types (single `Λ`,
single `σ_eps` by construction) keep the exact `ΛΛᵀ + diag(σ_eps²)` formula
via the generic fallback method. `gllvmTMB_diagnose` now calls
`_implied_Sigma_y(fit)` instead of duplicating the formula inline.

**Test added**: strong shared `Λ_B` factor + tiny `σ_eps` + large `Λ_W`
diagonal contribution — old formula flags `correlation_near_boundary`
spuriously; fixed formula (using the full `sigma_y_site`) does not.

Commit: `69942555`.

## 3. `var_tol` scale mixing

**Bug**: `σ_eps`/`σ_phy` (SD-parameterised) and `σ²_B`/`σ²_W`
(variance-parameterised) were compared against the same `var_tol` threshold
directly, both spelled `"variance_near_zero"` — thresholds differed by
orders of magnitude in effective sensitivity across parameterisations.

**Fix**: convention adopted and documented in the docstring — everything is
compared on the VARIANCE scale. `σ_eps`/`σ_phy` are squared before
comparison; `σ²_B`/`σ²_W` compare directly. Messages now name the
parameterisation and report the variance-scale value actually compared.

**Test added**: `σ_eps = 0.005` (SD > old-style var_tol=1e-4, so the old
SD-scale comparison would NOT flag it) but `σ_eps² = 2.5e-5 < var_tol`, so
the fixed variance-scale comparison DOES flag it.

Commit: `119fe1eb`.

## 4. `repeatability_bootstrap_ci` PSD Cholesky (`src/twolevel.jl`)

**Bug**: `cholesky(Symmetric(fit.Σ_B)).L` / `Σ_W` called with no
`PosDefException` guard; a boundary fit's `Σ_B = Λ_B Λ_Bᵀ + diag(σ²_B)` is
only PSD (rank-deficient at `σ²_B == 0`, `K_B < p`), so it threw and
aborted the whole call — inconsistent with the NaN-row convention used
elsewhere in this file (e.g. `repeatability_wald_ci`'s `failed` row).

**Fix**: new `_psd_sqrt_factor(Σ)` — eigendecomposition of the symmetrized
`Σ` with tiny/negative eigenvalues clamped to `0` (no jitter term); any
orthonormal-basis square root is valid for `N(0,Σ)` simulation, `L` need
not be lower-triangular. If even that fails (non-finite `Σ`), the function
now returns the standard NaN-row / `n_boot=0` convention instead of
raising.

**Test added** (in `test/test_diagnostics.jl` — no dedicated owned twolevel
test file for this repair pass; see file header note): a rank-1 `Λ_B` with
`σ²_B = 0` reproduces the `PosDefException` on plain `cholesky`; the fixed
`repeatability_bootstrap_ci` call completes without throwing and returns
finite per-trait rows.

Commit: `32989fcb`.

## 5. `extract_cross_correlations` level kwarg (`src/extractors.jl`)

**Bug**: the `GllvmFit` method accepted `level` but silently ignored it
(always forwarded to the single-tier `extract_correlations(fit)`), unlike
`bootstrap_Sigma`'s validate-and-throw pattern for the same "GLLVM.jl only
computes one tier" situation.

**Fix**: `level` is now run through `_canonical_level` and validated to be
`:unit`; any other value throws `ArgumentError`, matching `bootstrap_Sigma`.

**Tests added**: `level = :unit_obs` and `level = :bogus` both now throw
`ArgumentError`.

Commit: `3d1dddbf`.

## 6. `extract_communality` docstring (`src/extractors.jl`)

**Bug**: the docstring claimed this "mirrors `gllvmTMB::extract_communality()`
at `level = "unit"`" — numerically false whenever `σ_eps > 0` or a W-tier is
present. R's `level="unit"` denominator is the level="unit" tier total
alone; GLLVM.jl's denominator is the blended `Σ_y_site` total (every
non-phylo tier).

**Fix (docs only, no computation change — maintainer's estimand-alignment
call)**: docstring rewritten to state Julia's total-variance composition
explicitly and reference the pending estimand-alignment decision
(`docs/dev-log/core070/se-machinery-slice-notes.md`,
`docs/dev-log/core070/surface-conversion-notes.md`).

Commit: `9f267e7c`.

## Verification

Standalone runs after all six fixes (final state):

```
test/test_diagnostics.jl : diagnostics                                    | Pass 61 / Total 61
test/test_extractors.jl  : extractors.jl — post-fit extractor family      | Pass 73 / Total 73
```

`using GLLVM` loads clean (no errors; the pre-existing `Distributions.Multinomial`
name-conflict warning is unrelated and unchanged). No full-suite run performed
per task scope (standalone owned-file test runs only).

## Files touched

- `src/diagnostics.jl` — defects 1, 2, 3
- `src/twolevel.jl` — defect 4
- `src/extractors.jl` — defects 5, 6
- `test/test_diagnostics.jl` — regression tests for defects 1, 2, 3, 4
- `test/test_extractors.jl` — regression test for defect 5

Not touched (out of scope / other repair agents): `src/re_sd.jl`,
`src/confint_*`, `src/formula.jl`, `tools/`.

## Lane note

`git status`/PreToolUse lane checks flagged that `src/diagnostics.jl` and
`test/test_diagnostics.jl` also carry unmerged work on branches
`fam-ordprobit` and `a6-diagnostics` (a full randomized-quantile-residuals
rewrite of `src/diagnostics.jl`), and `src/twolevel.jl` carries unmerged
work on `tmp-reorder`. Those branches were not merged into this checkout at
the time of this repair and their diffs replace unrelated file regions (a
different feature, not overlapping the six defects fixed here); this repair
proceeded on the assigned branch as instructed. Flagging here for the
maintainer to reconcile when those branches merge.
