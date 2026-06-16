# After-task report: grouped-dispersion CI bridge endpoints

**Date**: 2026-06-16  
**Branch**: `codex/julia-per-trait-dispersion`

## Purpose

Route no-X NB2, NB1, Beta, and Gamma grouped-dispersion fits through the same
Wald/profile/bootstrap CI bridge contract already used by scalar no-X families.
The paired R bridge needs these endpoints before it can honestly widen
`engine = "julia"` CI admission beyond Gaussian/Poisson/Binomial.

## Files Changed

- `src/confint_family.jl`
- `src/bridge.jl`
- `test/test_bridge_grouped_dispersion.jl`
- `test/test_bridge_capabilities.jl`
- `docs/src/index.md`
- `docs/src/gllvmtmb-parity.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-16-grouped-dispersion-ci-bridge.md`

## Implementation

- Added `_GroupedDispersionFit` CI adapters for `NBGroupedFit`, `NB1GroupedFit`,
  `BetaGroupedFit`, and `GammaGroupedFit`.
- Kept grouped nuisance parameters on the log working scale and returned public
  interval rows labelled `r[g]`, `phi[g]`, or `alpha[g]`.
- Routed bridge CI requests for NB2/NB1/Beta/Gamma through
  `_bridge_compute_ci_ng()`.
- Left per-trait ordinal-cutpoint CI requests as explicit bridge errors.

## Checks

```sh
julia --project=. --startup-file=no test/test_bridge_grouped_dispersion.jl
```

Result: `121/121` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Initial result: failed on the stale scalar-only CI expectation.  
Rerun after expectation update: `34/34` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `64/64` pass.

## Review Perspectives

- Karpinski: grouped CI adapters reuse the existing generic non-Gaussian CI
  layer rather than adding a bridge-only side path.
- Gauss/Noether: grouped nuisance terms keep the fitted log-scale parameter map
  and back-transform to public dispersion rows.
- Rose: capability metadata and docs were updated with the same boundary:
  grouped-dispersion CI rows admitted; ordinal CI rows still follow-up.

## Not Run

- Full `Pkg.test()` / `test/runtests.jl`.
- Documenter build.
- Paired R bridge tests; those belong to the next R-side admission commit.

## Remaining Work

Update `gllvmTMB` so its R bridge gate, capability table, tests, NEWS, validation
register, and dashboard consume these grouped CI endpoints without advertising
masked, fixed-effect-X, mixed-family, REML, or ordinal CI support.
