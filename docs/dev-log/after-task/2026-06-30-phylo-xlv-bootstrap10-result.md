# After Task: phylo X_lv capped-bootstrap 10-seed diagnostic result

**Date**: `2026-06-30`
**Executed by**: Codex, live DRAC lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## 1. Goal

Read the completed Narval capped-bootstrap diagnostic for the known weak
p=80, K=2, lambda=0.5 phylo `X_lv` `B_lv` coverage cell.

## 2. Implemented

No code changed. I polled Narval job `64397790`, summarised the 10 completed
result rows, collected scheduler/resource evidence, and recorded the result as
a negative interval-rescue diagnostic.

## 3a. Decisions and Rejected Alternatives

I did not launch production coverage or another rescue array. The 10-seed
capped-bootstrap result is already enough to reject this method as the next
production path for the weak cell.

I did not treat the one-seed Narval coverage of `1.0` as decisive; the 10-seed
result supersedes it and shows the expected uncertainty.

## 4. Files Touched

- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-06-30-0512-codex-phylo-xlv-bootstrap10-result.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap10-result.md`

## 5. Checks Run

```sh
ssh -o BatchMode=yes narval '... squeue/result count/summarise ...'
ssh -o BatchMode=yes narval '... seff/sacct/session/result head ...'
```

Results: all 10 result files were present; the summariser read 10 rows and
reported `10/10` fits OK, `800` usable entries, mean coverage `0.844` with MCSE
`0.071`, entry coverage `0.844`, RMSE `0.074`, mean fit time `228.594s`, mean
CI time `4153.291s`, `300/300` bootstrap refits converged, and CI status `ok`.
All array tasks completed with exit code `0`; elapsed times were roughly
`68-77` minutes and memory stayed below `1 GB`.

## 6. Tests of the Tests

The result is triangulated from the scheduler state, result-file count, summary
table, session metadata, result CSV, `seff`, and `sacct`. The summary uses only
final `result_*.csv` files, not partial files.

## 7a. Issue Ledger

- Found: capped bootstrap does not repair the p=80, K=2, lambda=0.5 weak-cell
  coverage problem (`0.844`, MCSE `0.071`).
- Found: bootstrap runtime is feasible for diagnostics but too costly to scale
  blindly: about `69` CI minutes per task on average.
- Deferred: diagnose whether the weak-cell failure is estimator bias, interval
  width/covariance mapping, DGP/target definition, or a need for narrower
  profile/batched inference.

## 8. Consistency Audit

The result is compared against the previous weak-cell diagnostics: normal Wald
`0.844`, t-Wald `0.845`, and now capped bootstrap `0.844`. The local Mission
Control wording must continue to call this negative diagnostic evidence, not
coverage calibration.

## 9. What Did Not Go Smoothly

The one-seed capped bootstrap result looked promising (`1.0` entry coverage),
but the 10-seed diagnostic removed that optimism. This is exactly why the
multi-seed diagnostic was necessary before production scaling.

## 10. Known Residuals

The LV arc remains incomplete. No supported interval method currently rescues
the p=80, K=2, lambda=0.5 weak cell. Phylo-signal intervals remain out of scope
for this result, and gllvmTMB source-specific `lv = ~ x` remains blocked.

## 11. Team Learning

Fisher: a one-seed bootstrap success is not evidence of calibration. Grace:
runtime is manageable for diagnostics, but not a reason to scale a method whose
coverage still fails. Rose: keep negative method evidence visible so the next
agent does not relaunch the same doomed production grid.
