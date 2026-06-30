# After Task: phylo X_lv bootstrap/profile canary poll

**Date**: `2026-06-30`
**Executed by**: Codex, live DRAC lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## 1. Goal

Resolve the stale Mission Control state for the live weak-cell interval-rescue
canaries: uncapped bootstrap on Nibi, capped bootstrap on Narval, and
profile/bootstrap on Rorqual.

## 2. Implemented

No engine or runner code changed. This slice polled DRAC, recorded the final
canary states, and updated the local evidence ledger.

## 3a. Decisions and Rejected Alternatives

I did not launch a new production or diagnostic array. The existing canaries had
not yet been fully recorded, and launching another job before reading them would
muddy the evidence chain.

I treated Rorqual's full-vector profile timeout as timing evidence, not a method
failure: the fit and Wald interval completed, but profile did not return inside
three hours.

## 4. Files Touched

- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-06-30-0342-codex-phylo-xlv-canary-poll.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-canary-poll.md`

## 5. Checks Run

```sh
ssh -o BatchMode=yes nibi '... job 16951694 ...'
ssh -o BatchMode=yes narval '... job 64365792 ...'
ssh -o BatchMode=yes rorqual '... job 14929297 ...'
```

Results: Nibi uncapped bootstrap completed with coverage `0.9375` and wall
`01:23:48`; Narval capped bootstrap completed with coverage `1.0` and wall
`01:10:34`; Rorqual profile/bootstrap timed out at `03:00:20` after finishing
fit and Wald and entering profile.

## 6. Tests of the Tests

This was a read-only evidence-poll slice. The robustness check was triangulation
from scheduler state, result-file count, log tail, result CSV, and `seff` for
each job. For the two bootstrap jobs, the result CSV and scheduler exit state
agree. For the profile job, the absence of a result file, the log tail, and
`seff` all agree that it timed out in profile.

## 7a. Issue Ledger

- Fixed: Mission Control and local logs no longer treat Narval capped bootstrap
  and Rorqual profile as live/unknown.
- Found: capped bootstrap completed but still costs about 68 CI minutes for one
  p=80, K=2 weak-cell task.
- Found: full-vector profile is too slow in its current form for this weak cell.
- Deferred: multi-seed bootstrap diagnostic and production coverage remain
  unlaunched.

## 8. Consistency Audit

The three canaries correspond to the jobs listed in the previous live-rescue
checkpoint. No extra result directories were promoted. The conclusions are kept
as feasibility/timing evidence, not coverage calibration.

## 9. What Did Not Go Smoothly

The result evidence lives on three DRAC clusters rather than in one local folder,
so the poll commands had to read scheduler, log, and result state separately for
each cluster.

## 10. Known Residuals

The LV arc remains incomplete. Bootstrap has one-seed positive feasibility
evidence but no MCSE-backed coverage. Phylo-signal intervals remain unusable in
the current canaries. gllvmTMB source-specific `lv = ~ x` remains blocked.

## 11. Team Learning

Fisher: for this weak phylo cell, bootstrap is the only completed rescue path,
but one-seed success is not enough for production. Grace: profile needs a
narrower/batched implementation before another long run is worth the queue time.
