# After Task: Gamma Shared-Bridge Route

## Goal

Make the Julia bridge Gamma default match current native `gllvmTMB` ordinary
Gamma, which has one scalar coefficient of variation across Gamma traits.

## Implemented

- `src/bridge.jl` now routes `family = "gamma"` through
  `fit_gamma_gllvm_grouped()` with `group = fill(1, p)`.
- The per-trait grouped Gamma engine is unchanged and remains available for a
  later native per-trait Gamma expansion.
- `test/test_bridge_grouped_dispersion.jl` now expects Gamma to have one
  dispersion group and `df = p + rr_df + 1`, while NB2/NB1/Beta keep per-trait
  grouped dispersion.

## Checks Run

- `julia --project=. test/test_bridge_grouped_dispersion.jl` -> `49/49 pass`.
- `julia --project=. test/test_bridge_capabilities.jl` -> `34/34 pass`.
- Paired R bridge check from `../gllvmTMB`:
  `GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'devtools::test(filter = "julia-bridge", reporter = "summary")'`
  -> completed cleanly.

## Scope Boundary

This is a bridge-routing parity change only. It does not remove the grouped
Gamma fitter and does not claim native per-trait Gamma support in `gllvmTMB`.
