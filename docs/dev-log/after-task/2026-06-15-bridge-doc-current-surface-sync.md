# After Task: Bridge Documentation Current-Surface Sync

## Goal

Remove stale wording that made the legacy direct R scaffold sound like the
current `gllvmTMB(..., engine = "julia")` bridge, and align the Julia-side
parity page with the R-first bridge plan.

## Implemented

- Updated `docs/src/gllvmtmb-parity.md` to list NB1 complete-data no-X bridge
  admission and to keep NB1-X, NB1/Gaussian response masks, masked CIs, mixed
  metadata, ordinal probability payloads, structured dependence, and broader
  post-fit methods as explicit follow-ups.
- Rewrote the "Honest gaps" section so broad engine capabilities are not
  automatically public R bridge claims.
- Renamed `r/README_bridge.md` as a legacy direct `gllvm_julia()` scaffold and
  pointed current R users to the `gllvmTMB` bridge guarded by
  `GLLVM.bridge_capabilities()`.
- Updated `r/gllvmtmb_julia.R` roxygen for `X` so the legacy direct scaffold's
  conservative rejection is not confused with current `gllvmTMB` bridge
  support.

## Files Changed

- `docs/src/gllvmtmb-parity.md`
- `r/README_bridge.md`
- `r/gllvmtmb_julia.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-15-bridge-doc-current-surface-sync.md`

## Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_capabilities.jl
```

Result: `9/9 pass` in `0.2s`.

```sh
git diff --check
```

Result: clean.

## Benchmark Numbers

N/A -- documentation/status sync only; no hot path changed.

## R-Parity Verdict

No new R parity claim is made by this slice. The current R bridge evidence lives
in the paired `gllvmTMB` branch and its live `julia-bridge` test results.

## JET / Allocs / Aqua Verdicts

- JET: not run; no source code changed.
- Allocs: not run; no source code changed.
- Aqua: not run; no source code changed.

## Remaining Risks

- `gllvmTMB` bridge admission is still partial and must remain issue-led.
- NB1-X, NB1/Gaussian response masks, masked CIs, mixed-family metadata, ordinal
  probability payloads, and structured-dependence bridge rows remain queued.
- Local Documenter rendering was not rerun for this docs-only slice; the docs
  environment still has the pre-existing local-package registration blocker
  recorded in earlier after-task reports.

## Rose Verdict

Rose verdict: PASS WITH NOTES -- stale bridge wording is corrected, but release
or "full R bridge" language remains blocked until the R package bridge, tests,
docs, and issue ledger all agree.
