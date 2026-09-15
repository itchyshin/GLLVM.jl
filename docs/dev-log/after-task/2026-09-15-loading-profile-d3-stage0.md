# After-task — D3 `loading_profile` Stage 0 (confirmatory substrate)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (true-parity; **test-only substrate**, no public export)  
**Branch:** `docs/loading-profile-d3-stage0-20260915`  
**Base:** `origin/main` @ `598e22ca` (Ada defaults #323 B + matched-θ C, #344)  
**Programme row:** `namespace/export/loading_profile` → **`BLOCKED_NEEDS_JULIA_SURFACE`** (unchanged)

## Scope

Stage 0 only: frozen Core070 pin fixtures, R-aligned free-index oracles, test-only pin/refit
helpers, and a JSON contract pointing at existing masks-known likelihood oracles. **No**
`src/` export, **no** `lambda_constraint` fitter, **no** ledger mutation, **no** `Project.toml`
bump, **no** S4 probe, **no** gllvmTMB edits.

## What landed

| Artifact | Role |
|----------|------|
| `docs/dev-log/core070/loading-profile-confirmatory-substrate.json` | Stage 0 contract, source pins, Stage 1 fences |
| `test/parity/fixtures/loading_profile_confirmatory_substrate.jl` | `MASK-B-PINS` / `UPPER` / `ALLFIXED` matrices + free-entry oracles |
| `test/parity/loading_profile_confirmatory_substrate.jl` | Test-only helpers: `lambda_constraint_is_pinned`, `normalize_*`, `enumerate_free_lambda_entries`, `profile_refit_lambda_constraint` |
| `test/test_loading_profile_stage0.jl` | 24 assertions (included from `test/runtests.jl`) |

Likelihood oracles remain **`docs/dev-log/core070/masks-known-contract.json`** +
`tools/core070_masks_known.jl` (P1/P2 for `MASK-B-PINS` et al.).

## Checks run

- Shannon preflight: **FOREIGN LANE ACTIVE** (cursor direct-to-main); took dedicated branch + lane lease on listed paths.
- `graft ask "loading_profile symbols D3" --source` (prior scout + this slice).
- `julia --project=. -e 'using Test; include("test/test_loading_profile_stage0.jl")'` → **24/24 pass**.
- **No** full `Pkg.test()` (focused Stage 0 file only).
- **No** ledger JSON edit; T5 arc stays **7/8**.

## STOP fences honoured

| Fence | Status |
|-------|--------|
| No confirmatory `loading_profile()` export | ✅ |
| No shim / rename change | ✅ |
| No ledger reclassify | ✅ |
| #323 waived state unchanged | ✅ |
| gllvmTMB read-only | ✅ |

## Rose fence

Stage 0 substrate **≠** T5 row 8 bound **≠** R grid parity **≠** confirmatory `loading_ci` **≠** Stage 1 API.

## Follow-up

1. **Maintainer G0 required before Stage 1:** public `loading_profile` export, fitter `lambda_constraint`, pin-and-refit grid, ledger bind + joint D3 wording.
2. Engineering: wire Gaussian ordinary latent fit to pin substrate; mechanism receipt on `MASK-B-PINS` (Totoro / frozen JSON per D-50).
3. Optional: extend `docs/src/derived-confidence-intervals.md` when Stage 1 lands (cascade rule).
