# After Task: Minimal bridge_fit No-X Contract

## Goal

Expose a narrow `GLLVM.bridge_fit` entrypoint on the current branch so the
R-Julia bridge has a tested plain-data target before the wider `gllvmTMB`
roundtrip work starts.

## Implemented

Added `src/bridge.jl` and exported `bridge_fit`. The contract is intentionally
small and explicit:

- no-covariate one-part families only: Gaussian, Poisson, Binomial, NB2, Beta,
  Gamma, and Ordinal;
- fixed-effect `X`, mixed-family vectors, NB1, and unknown CI methods reject
  before fitting;
- return payload is a flat `NamedTuple` with ASCII keys and primitive arrays,
  strings, numbers, and booleans;
- logLik/AIC/BIC, rotated loadings, scores where available, dispersion,
  covariance summaries, and link labels are returned;
- `ci_method = "wald"` uses native `confint`; bridge profile CIs report
  unsupported status for now; bootstrap is routed only for Gaussian and reports
  unsupported for non-Gaussian fits.

## Mathematical Contract

No likelihood, optimizer, family parameterization, or inference algorithm was
changed. The bridge delegates to the existing native fitters and checks that
the bridge payload matches direct Julia fits for objective and rotated loadings.

## Files Changed

- `src/GLLVM.jl` - include/export `bridge_fit`.
- `src/bridge.jl` - minimal flat bridge entrypoint.
- `test/runtests.jl` - include the bridge test file.
- `test/test_bridge_fit.jl` - no-X primitive payload, direct-fit parity, Wald
  CI parity, and unsupported-cell tests.
- `.claude/preview/status.json` and `.claude/preview/sweep.json` - board status
  updated from blocked to partial/covered for the exact tested slice.
- `docs/dev-log/check-log.md` - evidence entry.
- `docs/dev-log/capability-bridge-matrix.md` - current-branch bridge rows.
- `docs/dev-log/2026-06-14-truth-snapshot.md`,
  `docs/dev-log/2026-06-14-issue-action-map.md`, and
  `docs/dev-log/2026-06-14-full-finish-roadmap.md` - stale bridge-blocker
  wording corrected.

## Tests Added

`test/test_bridge_fit.jl` adds:

- payload-shape and direct-fit parity tests for Gaussian, Poisson, Binomial,
  NB2, Beta, Gamma, and Ordinal;
- logLik parity to direct Julia fits;
- rotated-loading parity to direct Julia fits;
- Poisson Wald CI parity to native `confint`;
- explicit rejection tests for fixed-effect `X`, mixed-family vectors, NB1, bad
  CI methods, and non-Gaussian bootstrap routing.

## Benchmark Numbers

N/A - no speed path changed.

## R-Parity Verdict

Partial. The Julia entrypoint exists and is tested against direct Julia fits.
Live `gllvmTMB` JuliaCall/R roundtrip is not yet tested, and the local R bridge
branch is not repaired in this slice.

## JET / Allocs / Aqua Verdicts

- JET: passed through `Pkg.test()` quality gate.
- Allocs: not run - no hot path changed.
- Aqua: passed through `Pkg.test()` quality gate.

## Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_bridge_fit.jl
```

Result:

```text
Test Summary:                    | Pass  Total   Time
bridge_fit minimal no-X contract |  175    175  25.5s
```

Core suite:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: exit code 0. The bridge test passed inside the core suite:

```text
bridge_fit minimal no-X contract | 175/175 pass
```

Full package suite:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result:

```text
bridge_fit minimal no-X contract | 175/175 pass
quality                            | 12/12 pass
Testing GLLVM tests passed
```

Known non-failing noise retained from the existing suite: duplicate-include
warnings in Takahashi/sparse/edge phylo tests and broken placeholders in the
direct core environment.

## Consistency Audit

The dashboard, sweep rows, capability matrix, truth snapshot, issue action map,
and roadmap were updated to remove the stale claim that this branch lacks
`GLLVM.bridge_fit`. They now state the narrower truth: minimal no-X
`bridge_fit` exists, while the full R bridge remains partial.

## GitHub Issue Maintenance

No GitHub issue was opened, edited, commented on, or closed. The staged remote
update language for `gllvmTMB#488` was updated locally in
`docs/dev-log/2026-06-14-issue-action-map.md`.

## What Did Not Go Smoothly

The first Julia command used `julia`, which is not on this shell's `PATH`. The
local runtime is `/Users/z3437171/.juliaup/bin/julia`.

## Team Learning

Hopper: a bridge can be useful before it is complete if unsupported cells are
rejected deliberately and the payload is flat. Rose: keep the row at `partial`
until the R object, CI labels, and live roundtrip agree.

## Remaining Risks

- `gllvmTMB` still needs branch repair from current `origin/main`.
- The R package still needs live JuliaCall tests against this payload.
- Fixed-effect `X`, missing-response masks, mixed-family metadata, profile CIs,
  non-Gaussian bootstrap CIs, and post-fit S3 methods are still open.
- Full `Pkg.test()` is green on Julia 1.10.0 for this bridge addition.

## Known Limitations

This is not a complete R bridge and not a new modeling capability. It is a
tested plain-data bridge entrypoint for the first supported no-X cells.

## Next Command

```sh
cd "/Users/z3437171/Dropbox/Github Local/gllvmTMB" && \
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl" \
Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-julia-bridge.R")'
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - minimal bridge entrypoint is covered; full
bridge claim remains partial.
