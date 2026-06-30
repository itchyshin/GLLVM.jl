# Recovery Checkpoint: phylo X_lv bootstrap/profile canary poll

**Date**: 2026-06-30 03:42 MDT
**Agent**: Codex
**Branch**: `codex/phylo-xlv-drac-launcher-20260628`
**Worktree**: `/private/tmp/gllvmjl-phylo-xlv`

## Git State

At checkpoint start, the branch was clean at:

```text
7db960f docs: record bernoulli ci and canary hold
9aabac9 docs: record nibi bootstrap canary result
82a7020 docs: record partial checkpoint sync
7ecbd4a bench: checkpoint partial phylo xlv results
```

## Commands Already Run

Polled the three previously live weak-cell p=80, K=2, lambda=0.5 DRAC canaries:

```sh
ssh -o BatchMode=yes nibi '... job 16951694 ...'
ssh -o BatchMode=yes narval '... job 64365792 ...'
ssh -o BatchMode=yes rorqual '... job 14929297 ...'
```

Each command checked `squeue`, result-file count, log tail, result CSV if
present, and `seff`.

## Outcomes

- Nibi `16951694_1`: completed uncapped bootstrap-only `B_lv` canary, result
  file present. Coverage `0.9375`, RMSE `0.0629`, fit `169.4s`, CI `4843.7s`,
  bootstrap converged `30/30`, wall `01:23:48`, memory `465.55 MB / 4 GB`.
- Narval `64365792_1`: completed capped bootstrap-only `B_lv` canary with
  `bootstrap_iterations = 120`, result file present. Coverage `1.0`, RMSE
  `0.0346`, fit `148.5s`, CI `4055.2s`, bootstrap converged `30/30`, wall
  `01:10:34`, memory `875.61 MB / 4 GB`.
- Rorqual `14929297_1`: timed out after `03:00:20`, no result file. Fit and
  Wald completed; profile started and did not finish before timeout.

## Changed Files

This checkpoint should be committed with:

- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-06-30-0342-codex-phylo-xlv-canary-poll.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-canary-poll.md`

The live Mission Control JSON under `/tmp/gllvm-dashboard/status.json` should be
updated separately because it is outside this repository branch.

## Commands Still Needed

```sh
git diff --check
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-30-phylo-xlv-canary-poll.md
git add docs/dev-log/check-log.md docs/dev-log/recovery-checkpoints/2026-06-30-0342-codex-phylo-xlv-canary-poll.md docs/dev-log/after-task/2026-06-30-phylo-xlv-canary-poll.md
git commit -m "docs: record phylo xlv canary completion"
```

## Next Safest Action

Do not launch production coverage. The next bounded action is a small
multi-seed capped-bootstrap diagnostic for the weak cell, or a profile
batching/narrowing implementation before any further profile run.

## Blocking Question

No immediate blocker for recording this evidence. Production coverage remains
blocked until the maintainer accepts a bootstrap diagnostic plan and resource
budget.
