# After Task: Ordinal-Probit Bridge Mask

## Goal

Make the GLLVM.jl bridge target match the public gllvmTMB ordinal family:
`ordinal_probit()` must route to a cumulative-probit ordinal fit, not the
cumulative-logit ordinal default.

## Implemented

`bridge_fit` now accepts `family = "ordinal_probit"` and
`family = "ordered_probit"`, dispatching to
`fit_ordinal_gllvm(..., link = ProbitLink())`. The existing `family = "ordinal"`
key remains cumulative-logit. The masked bridge allowlist includes the new key,
and the flat payload reports `family = "ordinal_probit"`,
`model = "ordinal_probit_rr"`, and `link = "ProbitLink"`.

## Mathematical Contract

For `ordinal_probit`, the bridge uses the cumulative-probit threshold model
`P(Y <= c | z) = Phi(tau_c - eta)` with `eta = Lambda z`, matching the R
`ordinal_probit()` family rather than GLLVM.jl's cumulative-logit ordinal
default.

## Files Changed

- `src/bridge.jl`
- `test/test_bridge_missing_mask.jl`
- `docs/src/gllvmtmb-parity.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-15-ordinal-probit-bridge-mask.md`

## Tests Added

- `test/test_bridge_missing_mask.jl`: added an `ordinal_probit` masked bridge
  row comparing `bridge_fit` to native `fit_ordinal_gllvm(..., link =
  ProbitLink(), mask = M)`.

Tests of the tests: the new row would fail if `ordinal_probit` were only an R
alias to the cumulative-logit `ordinal` bridge key.

## Benchmark Numbers

N/A — this is a bridge dispatch/keying change, not a hot-path algorithm change.

## R-Parity Verdict

R bridge transport parity: live `gllvmTMB` tests pass against this checkout for
Poisson, Bernoulli Binomial, NB2, Beta, Gamma, and Ordinal-probit masked no-X
fits. R/TMB-vs-Julia statistical parity remains a separate gate.

## JET / Allocs / Aqua Verdicts

- JET: not run; bridge dispatch-only change.
- Allocs: not run; no hot inner loop changed.
- Aqua: not run; no dependency/export/Project.toml change.

## Checks Run

- `~/.juliaup/bin/julia --project=. test/test_bridge_missing_mask.jl`:
  `23/23 pass` in `16.8s`.
- `~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl`:
  `66/66 pass` in `46.2s`.
- `GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'`:
  `232/232 pass` in `50.9s`.

## Consistency Audit

Updated `docs/src/gllvmtmb-parity.md` to distinguish the R-facing
Ordinal-probit route from the GLLVM.jl cumulative-logit `ordinal` default and
to keep ordinal prediction/residual payloads as a follow-up.

## GitHub Issue Maintenance

No GitHub issue was mutated; pushing/commenting is maintainer-gated.

## What Did Not Go Smoothly

The family name looked like a simple alias at first, but it was a link-function
semantic mismatch. The explicit bridge key is the safer contract.

## Team Learning

Hopper/Rose: bridge aliases must be checked against parameterization, not just
family names.

## Remaining Risks

- Masked ordinal-probit prediction/residual methods still need cutpoint and
  probability payloads.
- Masked CI/profile/bootstrap refits are still unsupported.
- R/TMB-vs-Julia statistical parity is not claimed by this transport test.

## Known Limitations

This slice does not add covariates, Gaussian masks, mixed-family masks, or CI
support for masked fits.

## Next Command

`GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'`

## Rose Verdict

Rose verdict: PASS WITH NOTES — the bridge key and R-live masked family matrix
are proven, but masked inference and ordinal post-fit payloads remain partial.
