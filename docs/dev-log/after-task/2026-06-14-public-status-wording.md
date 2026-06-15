# After Task: Public Status Wording Cleanup

## Goal

Remove stale public status wording after the minimal `bridge_fit` and #92
phylo-signal Wald scale slices, without promoting the R bridge or release state
beyond the evidence.

## Implemented

- `docs/src/gllvmtmb-parity.md` now reports one-part non-Gaussian CI routes as
  partial rather than unwired, and the R bridge as minimal Julia-side
  `bridge_fit` plus open live `gllvmTMB` gates.
- `docs/src/index.md` names one-part CI routes and the minimal bridge route in
  the "What works today" box, while keeping mixed-family and missingness bridge
  support planned.
- `docs/src/roadmap.md` moves bridge work into the interface/bridge catch-up
  lane and keeps full bridge coverage as a v1.0 goal.
- `docs/src/changelog.md` records the partial bridge state and local #92 fix.

## Mathematical Contract

N/A - prose/status cleanup only.

## Files Changed

- `docs/src/gllvmtmb-parity.md`
- `docs/src/index.md`
- `docs/src/roadmap.md`
- `docs/src/changelog.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-14-public-status-wording.md`

## Tests Added

No tests added. This is a docs/status slice.

## Benchmark Numbers

N/A.

## R-Parity Verdict

Partial by design. The docs now say the R bridge still needs live `gllvmTMB`
roundtrip evidence and wider support for `X`, missingness, mixed families, and
post-fit methods.

## JET / Allocs / Aqua Verdicts

N/A - no Julia code changed in this slice. The immediately preceding code
slices passed full `Pkg.test()`.

## Checks Run

Stale-wording scan: `rg` over `docs/src`, `docs/dev-log`, `README.md`, and
`.claude/preview` for the old bridge, non-Gaussian-CI, and #92 blocker phrases.
Result: no stale bridge/non-Gaussian-CI/#92 hits. Remaining `not yet wired`
matches are for the structured Schur substrate, which is still true.

```sh
/Users/z3437171/.juliaup/bin/julia --project=docs docs/make.jl
```

Result: exit code 0. Known local warnings remain: deployment auto-detection is
skipped outside CI, optional Vitepress assets/package files are substituted or
missing, and npm audit reports 4 vulnerabilities in the local docs toolchain.

## Consistency Audit

The edited docs now align with the capability matrix: the bridge is `partial`,
non-Gaussian inference is implemented but still under parity/docs audit, and
release/tag wording remains blocked.

## GitHub Issue Maintenance

No GitHub issue was opened, edited, commented on, or closed.

## What Did Not Go Smoothly

The docs had drifted in both directions: some public pages said non-Gaussian CIs
were not wired, while newer internal evidence showed one-part Wald/profile
routes. The fix keeps this as partial rather than turning it into a broad
completion claim.

## Team Learning

Rose: status prose needs the same evidence discipline as code. A stale "planned"
can be as misleading as an overclaim.

## Remaining Risks

- Full issue-led public status cleanup is not complete.
- Live `gllvmTMB` bridge tests are still pending.
- Root `CHANGELOG.md` policy remains unresolved; the current project uses
  `docs/src/changelog.md`.

## Known Limitations

This slice updates status wording only. It does not add bridge capability,
examples, figures, or R parity tests.

## Next Command

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl" Rscript -e 'testthat::test_local("/Users/z3437171/Dropbox/Github Local/gllvmTMB", filter = "julia-bridge")'
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - specific stale public wording is fixed; release
and full-bridge claims remain blocked.
