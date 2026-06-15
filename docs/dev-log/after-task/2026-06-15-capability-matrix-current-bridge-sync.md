# After Task: Capability Matrix Current R-Bridge Sync

## Goal

Update the dashboard-side capability/bridge matrix so it tracks current
`gllvmTMB` bridge evidence and supports the R-first completion plan.

## Implemented

- Clarified that this `GLLVM.jl` checkout is the dashboard/status checkout, not
  the current paired runtime for live `gllvmTMB` tests.
- Updated live bridge evidence to `394/394` against `GLLVM.jl-integration`,
  including the drift guard, fixed-effect-X rows, missing-response-mask rows,
  Gaussian CI transport, NB1 no-X admission, and NB1 post-fit methods.
- Changed NB1 from `planned` to engine `covered` / R bridge `partial`, with the
  tested complete-data no-X boundary and queued NB1-X, masks, masked
  simulation/profile/bootstrap, native parity, and mixed-family work.
- Changed response missingness, prediction/fitted, and residual rows from
  planned to partial where current R routes exist, keeping unsupported cells
  visible.

## Files Changed

- `docs/dev-log/capability-bridge-matrix.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-15-capability-matrix-current-bridge-sync.md`

## Checks Run

```sh
git diff --check
```

Result: clean.

## Benchmark Numbers

N/A -- documentation/status sync only.

## R-Parity Verdict

No new parity claim is made here. The matrix points to the paired `gllvmTMB`
live bridge evidence (`394/394`) and keeps broader rows partial.

## JET / Allocs / Aqua Verdicts

- JET: not run; no source code changed.
- Allocs: not run; no source code changed.
- Aqua: not run; no source code changed.

## Remaining Risks

- NB1-X, NB1/Gaussian response masks, masked CIs, ordinal probabilities,
  mixed-family metadata, structured-dependence bridge routes, and broader
  post-fit methods remain queued.
- The dashboard worktree and paired runtime worktree are separate; future board
  updates must keep SHAs explicit to avoid stale capability claims.

## Rose Verdict

Rose verdict: PASS WITH NOTES -- matrix rows now match current evidence and keep
unsupported bridge cells explicit; release language remains blocked until R
bridge, Julia engine, docs, issue ledger, and CI agree.
