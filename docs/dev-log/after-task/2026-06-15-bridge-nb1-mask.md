# After Task: Bridge NB1 Missing-Response Mask

## Goal

Extend the paired Julia bridge so `gllvmTMB` can admit NB1 missing-response
masks without broadening the unsupported CI, X, Gaussian-mask, or mixed-family
mask surfaces.

## Implemented

`GLLVM.bridge_fit(...; family = "nb1", mask = M)` now routes the observed-cell
mask through `fit_nb1_gllvm()` and `getLV(::NB1Fit, ...)`. The bridge capability
ledger now lists NB1 as a missing-response family, and the parity page/roadmap
now describe NB1 masks as admitted only where the live R bridge covers them.

## Mathematical Contract

For NB1 responses, only observed cells (`M = true`) contribute to the marginal
Laplace objective and latent-score reconstruction. Values in masked cells are
sentinels for transport only; they must not change `loglik`, `β`, `φ`, loadings,
or scores.

## Files Changed

`src/`:

- `src/bridge.jl`
- `src/postfit.jl`

`test/`:

- `test/test_bridge_capabilities.jl`
- `test/test_bridge_missing_mask.jl`

`docs/`:

- `docs/src/gllvmtmb-parity.md`
- `docs/src/roadmap.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-15-bridge-nb1-mask.md`

## Tests Added

- Added NB1 to the bridge capability ledger expectation; this would have failed
  while `nb1` remained outside `_BRIDGE_MASK_FAMILIES`.
- Added `NB1 mask parity and sentinel invariance`, comparing `bridge_fit()` to
  `fit_nb1_gllvm(...; mask = M)` and checking that garbage in masked cells does
  not alter likelihood, parameters, loadings, or scores.

## Benchmark Numbers

N/A — this is a bridge admission and post-fit mask propagation change, not a hot
path speedup. No speed claim is made.

## R-Parity Verdict

Parity: within bridge tolerance for the R-Julia route. The paired
`gllvmTMB` live bridge gate passed `571/571` expectations against this checkout,
including NB1 missing-response public admission and direct-wrapper sentinel
invariance.

## JET / Allocs / Aqua Verdicts

- JET: not run in the direct core suite; `test/runtests.jl` reported JET was not
  available in this environment. Run `Pkg.test()` for the full battery.
- Allocs: N/A — no allocation claim was made.
- Aqua: not run in the direct core suite; `test/runtests.jl` reported Aqua was
  not available in this environment. Run `Pkg.test()` for the full battery.

## Checks Run

- `~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl`:
  `20/20 pass`.
- `~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_missing_mask.jl`:
  `34/34 pass`.
- `GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'`:
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 571` in `70.7s`.
- `~/.juliaup/bin/julia --project=. --startup-file=no test/runtests.jl`:
  `3931 pass / 3 broken / 0 fail` in `31m06.6s`.
- Temporary docs build with `Documenter` and `DocumenterVitepress`: exit code 0;
  residual warnings were the known pre-existing local-link, optional asset, npm
  audit, and chunk-size warnings.
- `git diff --check`: clean.

## Consistency Audit

Stale-wording scan:

```sh
rg -n "R bridge still rejects mixed-family|mixed-family R bridge admission|do not admit family lists|NB1.*missing-response.*remain|NB1 covariate\s*or missing-response|missing-response masks are wired only for poisson, binomial, negbinomial, beta|17b2154|6056071|f1894bc" README.md CLAUDE.md CHANGELOG.md docs/src src test -S
```

Result: no matches.

## GitHub Issue Maintenance

No GitHub issue was mutated; pushing/commenting remains maintainer-gated.

## What Did Not Go Smoothly

The full direct core suite took 31 minutes because it exercises unrelated
heavy numerical cells. It passed, but the direct environment did not include
JET/Aqua, so `Pkg.test()` remains the later full-quality gate before PR/merge.

## Team Learning

Hopper/Gauss: if the R bridge admits a mask row, latent-score reconstruction
must receive the same mask as the likelihood. Rose: the docs must say NB1 masks
are admitted but masked CIs/simulations and NB1-X are not.

## Remaining Risks

- Masked CI/profile/bootstrap refits are still unsupported.
- Masked simulations are still unsupported.
- NB1 fixed-effect-X bridge fits remain unsupported.
- Gaussian masks and mixed-family masks remain separate slices.
- `Pkg.test()` was not run after this slice; direct `test/runtests.jl` passed
  but did not include Aqua/JET.

## Known Limitations

This slice is a point-fit and in-sample post-fit bridge row only. It does not
promote a calibrated CI, simulation, predictor-missing, fixed-effect-X, Gaussian
mask, or mixed-family-mask claim.

## Next Command

```sh
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — NB1 masked point fits and scores are covered by
focused, full-core, and live R-Julia bridge evidence; masked CIs/simulations,
NB1-X, Gaussian masks, mixed-family masks, and the full Aqua/JET battery remain
separate gates.
