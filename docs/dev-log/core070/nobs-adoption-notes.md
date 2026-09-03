# nobs/BIC p·n adoption — resume notes (2026-09-01)

Decision: docs/dev-log/decisions/2026-09-01-maintainer-decisions-round1.md #1
— adopt R's p·n (observed-cell) `nobs` convention in GLLVM.jl; was
`PARTIAL_PARITY_DEFECT_PENDING`.

## R oracle readback confirmation

`.unlazy/core070-aghq/oracle-source/readback/R/methods-gllvmTMB.R`:

- `nobs.gllvmTMB_multi` (line ~1133) returns
  `fit$missing_data$counts$likelihood_rows`, falling back to
  `sum(is_y_observed == 1)`, falling back to `length(y)` — i.e. the count of
  **observed response cells**, not sites. All three forms "agree by
  construction" per the R comment.
- `logLik.gllvmTMB_multi`'s `nobs` attribute (line ~1113) uses the same
  `is_y_observed` mask (design 59 sec.4b: "nobs stays likelihood-contributing;
  original-row counts live in `fit$missing_data`").
- `stats::BIC.default` uses `k·log(nobs(object)) − 2·ll`, so R's BIC is
  computed on the cell count, not the site count.

GLLVM.jl's convention: `mask` is `p×n` with `true` = observed (opposite
polarity from R's `is_y_observed == 1` being the *positive* selector, but the
same semantic — count where TRUE/1). `count(mask)` and
`sum(iyo == 1)` are the same operation under this polarity. Confirmed
direction is correct.

## What the partial work (found on resume) had right

- `src/postfit.jl`: `nobs(fit, Y; mask)` correctly implements the cell-count
  convention (`count(mask)` / `count(!ismissing, Y)` / `length(Y)`), and the
  per-struct `nobs(fit)` overloads for `TwoLevelFit`, `GaussianRandomSlopeFit`,
  `PoissonRandomSlopeFit`, `RowEffectFit`, `SPDELatentFit` were all correctly
  updated to `size(fit.Λ, 1) * <stored unit count>` (p × n). `SPDEGaussianFit`
  was correctly left unchanged (p = 1, univariate spatial GP — noted inline).
  `bic(fit, Y; mask)` correctly threads through `nobs(fit, Y; mask)`.
- `src/bridge.jl`: the `bic` field's formula was fixed from `df·log(n) −
  2·ll` (site count `n`) to `df·log(nobs_val) − 2·ll` — bringing it into
  agreement with the `nobs` field two lines below, which already used
  `nobs_val = mask === nothing ? p*n : count(mask)`. This was a genuine
  internal-consistency bug (the flat bridge contract's `bic` and `nobs`
  fields disagreed under any mask) — now fixed and cited to the decision doc.

## What was broken (found and fixed this session)

1. **`src/model_selection.jl`: undefined variable.** The partial diff removed
   `n = size(Y, 2)` from `select_lv` (correctly — the new convention doesn't
   want the site count) but left the call site `push!(bics, bic(fit, n))`
   referencing the now-undefined `n`. This was a hard crash (`UndefVarError`)
   on every call to `select_lv`, not merely a wrong-convention bug. Fixed to
   `push!(bics, bic(fit, Y))`, which dispatches to the `bic(fit, Y; mask)`
   Y-inference method (no `mask` kwarg on `select_lv`/`fit_gllvm`, so masking
   there is only via `Y` containing `missing`, which `nobs` already detects
   via `eltype`).

## BIC audit findings

- Confirmed no other `_bridge_assemble` call site in `src/bridge.jl` forwards
  a `mask`-derived `nobs` except the one at `_bridge_assemble_ng` (the shared
  non-Gaussian assembler used by the masked no-X routes); every other route
  either doesn't support `mask` at all (throws `ArgumentError` up-front — e.g.
  reduced-rank Gaussian, ordinal, X-covariate routes) or is complete-data, so
  defaulting `nobs_val = p*n` there is correct and not a double-count risk.
- Confirmed no other `AnyGllvmFit` union member has a bare `nindiv` /
  `nlevels` / `nodes` / `ρ` field that would silently fall through to the
  generic un-scaled `nobs(fit::AnyGllvmFit)` fallback at the bottom of
  `src/postfit.jl` — the five struct-count types with those fields all have
  the new p-scaled specific method, which Julia dispatch prefers over the
  generic fallback. Phylogenetic fit types (`PhyloGaussianFit`,
  `GaussianREMLFit`, `PhyloGLMFit`, `CoevolutionGLMFit`, `EMPhyloFit`,
  `BranchREFit`) have none of those fields and correctly still require an
  explicit `Y` (unaffected by this change, out of scope).

## Tests added / updated (red-first where noted)

- `test/test_model_selection.jl`: was hard-crashing (`UndefVarError: n`)
  before the fix above — this is the red-first evidence for the
  `model_selection.jl` bug. Added an explicit BIC-formula check
  (`sel.bic[i] ≈ nparams[i]*log(p*n) − 2*loglik[i]`) pinning the new
  convention.
- `test/test_statsapi.jl`: updated all `nobs(fit, Y) == n` (site count)
  assertions to `== pn` (`p*n`); updated the `bic(fit, y) ≈ bic(fit, n)`
  cross-check to `bic(fit, y) ≈ bic(fit, pn)` — decided behavior change, cited
  inline. Added a new masked-cell testset covering both the explicit `mask`
  kwarg and a `Missing`-carrying `Y`.
- `test/test_bridge_missing_mask.jl`: added a red-first check that
  `br.bic ≈ br.df * log(br.nobs) - 2*br.loglik` under a mask (this would have
  failed before the `src/bridge.jl` fix, since `bic` used `log(n)` while
  `nobs` used `log(count(mask))`), plus a negative check that it does *not*
  match the old site-count formula.
- `test/test_nobs_pn_convention.jl` (new file): direct-construction unit
  tests (no optimizer run — structs built with synthetic field values, fast
  and deterministic) for `nobs(fit)` on `TwoLevelFit`, `GaussianRandomSlopeFit`,
  `PoissonRandomSlopeFit`, `RowEffectFit`, `SPDELatentFit` (all `p * <count>`)
  and `SPDEGaussianFit` (unchanged, p = 1).

## Verification run (standalone, per-file — no full suite)

```
julia --project=. test/test_nobs_pn_convention.jl   # 11/11 pass
julia --project=. test/test_statsapi.jl              # 74/74 pass
julia --project=. test/test_bridge_missing_mask.jl   # 92/92 pass
julia --project=. test/test_model_selection.jl       # 16/16 pass
julia --project=. -e 'using GLLVM'                   # clean load
```

Full suite (`Pkg.test()`) was **not** run per task scope — only the four
affected test files plus a clean `using GLLVM` load.

## Files touched this session

- `src/postfit.jl` — unchanged from partial diff (verified correct; no edits
  needed).
- `src/model_selection.jl` — fixed the `n`-undefined crash
  (`bic(fit, n)` → `bic(fit, Y)`).
- `src/bridge.jl` — unchanged from partial diff (verified correct; no edits
  needed).
- `test/test_statsapi.jl`, `test/test_bridge_missing_mask.jl`,
  `test/test_model_selection.jl` — updated to the new convention / added
  masked-case coverage.
- `test/test_nobs_pn_convention.jl` — new file, struct-level `nobs` unit
  tests for the five p-scaled fit types.
- `docs/dev-log/core070/nobs-adoption-notes.md` — this file.
