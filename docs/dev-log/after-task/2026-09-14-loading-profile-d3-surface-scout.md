# After-task — D3 `loading_profile` surface scout (T5 row 8)

**Date:** 2026-09-14  
**Lane:** Cursor / Ada (true-parity docs; **no engine export**)  
**Branch:** `docs/loading-profile-d3-surface-scout-20260914` (separate from `docs/second-order-parity-inventory-20260914` / matched-θ prep)  
**Programme row:** `namespace/export/loading_profile` → **`BLOCKED_NEEDS_JULIA_SURFACE`** (D3 decided 2026-09-04, option b)  
**T5 context:** 7/8 bound; row 8 is **not** a parity-defect re-bind (`docs/dev-log/after-task/2026-09-14-t5-partial-defect-inventory.md`).

## Scope

Read-only scout: what Julia ships today vs what R's exported `loading_profile()` does, what would be required to bind the ledger row, and what this docs slice deliberately does **not** do.

## What exists today

### R — `loading_profile()` (`gllvmTMB/R/loading-profile.R`)

| Aspect | Behaviour |
|--------|-----------|
| **Estimand** | Profile likelihood for **free** entries of `Lambda_<level>` on a **confirmatory** multi-trait fit: each grid point **refits** with that entry **pinned** via `lambda_constraint`. |
| **Gate** | Requires `gllvmTMB_multi`; MSPL + unweighted inference checks; skips entries pinned in `fit$lambda_constraint` and engine upper-triangle zeros. |
| **Return** | Long `data.frame` with class `profile_loadings`: columns `trait`, `axis`, `i`, `k`, `profile_value`, `objective` (−logLik), `delta_deviance`, `estimate`, `conf_level`. |
| **Args** | `level` (`"unit"` / `"unit_obs"`), `entries`, `n_grid` (default 11), `grid_extent`, `conf_level`. |
| **Downstream** | `loading_ci(..., method = "profile")` inverts the curve; `plot.profile_loadings` for LR U-shapes. |

Refit worker (conceptual): preserve user pins + other tier pins, set `M_test[i,k] <- c`, call `gllvmTMB(..., lambda_constraint = lc_test)`.

### Julia — `loading_profile_exploratory` (`src/confint_derived.jl`)

| Aspect | Behaviour |
|--------|-----------|
| **Estimand** | Profile CI **endpoints only** for **one** raw Λ entry `(t, k)` on the **exploratory (unpinned)** fit already stored in `fit` — no confirmatory gate. |
| **Mechanism** | Closure `θ -> Λ[t,k]` + [`profile_ci_derived`](@ref): **penalty**-constrained re-optimisation over full `θ`, not R-style hard pin + structural refit. |
| **Return** | `NamedTuple` `(lower, upper, estimate, method)` — **not** a grid / `profile_loadings`-shaped object. |
| **Args** | `t`, `k`, `level`, `y` (required), `component` (`:B` / `:W`), plus `profile_ci_derived` kwargs. |
| **Shim** | Exported `loading_profile` → `loading_profile_exploratory` with `Base.depwarn` reserving the name for a future R mirror (`src/confint_derived.jl:1185-1191`). |

Related but **not** ledger row 8: `loading_ci` on Julia runs Wald/profile table routes on exploratory fits where R's `loading_ci()` **refuses** unpinned fits (`src/confint_derived_wald.jl` documents the deviation). Same missing substrate: **no public `lambda_constraint` / confirmatory-fit object** in GLLVM.jl (`tools/core070_masks_known.jl` notes masks are R-only today; paired pins live in `test/parity/fixtures/core070_masks_known.R` only).

## Gap (one line)

**R profiles confirmatory Λ entries via pin-and-refit + curve table; Julia only has exploratory single-entry profile CI endpoints via penalty profiling — no `loading_profile`, no `profile_loadings`, no `lambda_constraint`.**

## Proposed Julia surface (design sketch — **not implemented**)

Maintainer G0 required before any export. Suggested **staged** shape aligned with R and with existing Julia kernels:

### Stage 0 — substrate (blocks row 8 and several deferred `loading_ci` rows)

- **`lambda_constraint` equivalent** on fit + fitter: user-supplied `p × K` pin matrix (`NaN` = free, numeric = fixed), engine upper-triangle enforcement, two-tier `:unit` / `:unit_obs` (`:B` / `:W`) preservation on refit (R #613 pattern).
- **Confirmatory fit constructor path** mirroring R's `gllvmTMB(..., lambda_constraint = list(unit = M))` for at least Gaussian + ordinary latent on the Core070 pin fixtures (`MASK-B-PINS`, `MASK-B-UPPER` in `test/parity/fixtures/core070_masks_known.R`).

### Stage 1 — export `loading_profile` (ledger row 8 target)

```julia
loading_profile(fit::GllvmFit;
                level::Symbol = :unit,          # :unit | :unit_obs (accept :B/:W with depwarn)
                entries::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
                n_grid::Integer = 11,
                grid_extent::Real = 6.0,
                conf_level::Real = 0.95,
                y::AbstractMatrix)              # required — same as exploratory helper
    -> ProfileLoadings  # Tables.jl-friendly struct or NamedTuple bundle + trait/axis labels
```

**Behaviour contract (match R, not `loading_profile_exploratory`):**

1. **Refuse** (or maintainer-chosen error) if `fit` has no confirmatory pin metadata — symmetric opposite of R refusing exploratory fits for `loading_ci`.
2. Enumerate **free** `(i, k)`; skip pinned + structural zeros; optional `entries` filter.
3. For each entry, build grid from Wald SE or `|Λ|/2 + 0.5` heuristic; at each `c`, **refit with pin** (preferred parity path) **or** documented penalty path only if proven equivalent on pin fixtures.
4. Return long table + metadata (`conf_level`, `n_grid`, `lam_name`) for inversion/plot stubs later.

**Name reservation (D3):** keep `loading_profile_exploratory` for the current penalty endpoint helper; **only** the confirmatory mirror takes `loading_profile` (shim removed in a later maintainer-approved API slice).

### Stage 2 — optional parity extras (out of row 8 minimum)

- `loading_ci(..., method = :profile)` inversion shared with R.
- Plot recipe for LR curves (Florence / CairoMakie — not required to bind namespace export row).

## Test / receipt plan

| Layer | Intent | Artifact |
|-------|--------|------------|
| **Unit** | Pin parsing, free-index enumeration, `k > t` structural zero | `test/test_loading_profile_confirmatory.jl` (new; after Stage 0) |
| **Mechanism** | One entry: grid objectives match R on `MASK-B-PINS` Gaussian fixture | Local `RCall` or frozen readback JSON under `.unlazy/core070-aghq/` (D-50: heavy grid on Totoro, not GHA) |
| **CI inversion** | Endpoints from Julia curve ≈ R `loading_ci(method = "profile")` at `rtol=1e-6` | Same paired batch |
| **Ledger** | `namespace/export/loading_profile` + `postfit/POSTFIT-SURFACE-loading_profile` | `tools/core070_surface_conversion_batch.jl` / wave contract — **only after** Stage 1 export; re-run `core070_ledger_counts.py` with **REQUIRED count unchanged** |
| **Regression** | Exploratory helper unchanged | Existing `test/test_derived_ci_surfaces.jl` §3a |

**Receipt gate for T5 row 8:** disposition moves from `BLOCKED_NEEDS_JULIA_SURFACE` to bound **only** with maintainer-approved joint-ledger wording (D3 seam) **and** paired confirmatory fixture evidence — not exploratory `loading_profile_exploratory` receipts.

## STOP fences (this slice and follow-ons)

| Fence | Rule |
|-------|------|
| **This PR** | Docs-only: this after-task + `check-log.md`. **No** `src/` export, **no** rename/shim change, **no** ledger JSON mutation. |
| **API ship** | **No** new `loading_profile` export without maintainer G0 on Stage 0+1 scope and deprecation removal timing. |
| **Ledger** | **Do not** reclassify row 8 to bound using exploratory surface; **do not** create FREE rows. |
| **#323** | **Not waived** — Frozen-R smoke / programme gate unchanged (`LOOP/GOAL.md`). |
| **T5 arc** | LOOP #16 stays **partial (7/8)** until row 8 is implemented **or** maintainer accepts permanent needs-surface (D3 option c — **not** chosen). |
| **Twin boundary** | R `gllvmTMB` engine read-only; Julia pin/refit implementation stays in GLLVM.jl. |

## Checks run (read-only)

- `graft ask "loading_profile loading_profile_exploratory D3" --source` (crux spans in `src/confint_derived.jl`)
- Read `gllvmTMB/R/loading-profile.R`, `docs/dev-log/core070/maintainer-decision-set-2026-09-03.md` §D3
- `python3 tools/core070_ledger_counts.py` — not re-run this slice (no ledger edit)
- No `Pkg.test()` (docs-only)

## Rose fence

- Scout **≠** Julia–R parity on `loading_profile` **≠** T5 row 8 bound **≠** #323 executed **≠** confirmatory `loading_ci` parity.

## Follow-up (ordered)

1. Maintainer: confirm Stage 0 scope (shared with deferred `loading_ci` confirmatory rows) vs row-8-only minimal pin path.
2. Engineering slice (future PR): Stage 0 fixture + fitter pins, then Stage 1 export + tests + ledger update.
3. Docs: extend `docs/src/derived-confidence-intervals.md` when confirmatory API lands (cascade with docstrings + tests).
