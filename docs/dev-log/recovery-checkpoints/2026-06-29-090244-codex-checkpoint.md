# Recovery Checkpoint: phylo X_lv target-only DRAC diagnostics

Generated: `2026-06-29 09:02 MDT`
Agent: Codex
Repository: `/private/tmp/gllvmjl-phylo-xlv`
Branch: `codex/phylo-xlv-drac-launcher-20260628`
HEAD: `6423626`

## Goal

Resume latent(lv = ~ x) Phase 3 DRAC Model A coverage from the target-timing
diagnostics. The next question is whether p=200, K=2 phylo-signal intervals are
fast/unusable once B_lv is skipped, while the old all-target Nibi job continues
to measure the B_lv bottleneck.

## Git State

```sh
git status --short --branch
```

```text
## codex/phylo-xlv-drac-launcher-20260628
```

Recent commits:

```text
6423626 docs: record phylo xlv rorqual target backup
1e32dc9 docs: record phylo xlv target-only nibi launch
b39b355 docs: checkpoint phylo xlv drac timing
3b28c19 docs: close phylo xlv timing instrumentation
3bcbc84 bench: instrument phylo xlv target timing
```

## New Jobs

Old all-target Nibi canary:

- job `16923927_1`;
- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300`;
- source `328e5e8-rsync-no-git`;
- status at last poll: `RUNNING`, elapsed `01:27:15`;
- fit done: converged in 47 iterations after `1394.49` seconds;
- still inside `B_lv` Wald CI; no result CSV yet.

Nibi target-only diagnostic:

- job `16926545_1`;
- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-iter80-2h-20260629-0848`;
- staged source
  `/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac-targettiming/`;
- source label `b39b355-rsync-no-git`;
- `--targets phylo_signal`, `iterations=80`, `time=2h`, `mem=8G`;
- status at last poll: `RUNNING`, elapsed `00:10:20`, in fit step.

Rorqual target-only backup:

- job `14909542_1`;
- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-large-k2-rorqual-phylo-target-iter80-2h-20260629-0900`;
- staged source
  `/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac-targettiming/`;
- source label `1e32dc9-rsync-no-git`;
- `--targets phylo_signal`, `iterations=80`, `time=2h`, `mem=8G`;
- status at last poll: `RUNNING`, elapsed `00:04:32`, in fit step.

All target-only jobs use the same one-row design:
`scenario=main`, `lambda=0`, `n_species=200`, `n_sites=200`, `K=2`,
`q_lv=1`, `K_phy=1`, `seed=21371432`.

## Mission Control

Dashboard source: `/tmp/gllvm-dashboard/status.json`
Visible URL verified in the in-app browser:
`http://127.0.0.1:8770/?refresh=20260629-0904`

The page was verified to contain `2026-06-29 09:04 MDT`, commit `6423626`,
job `16923927`, job `16926545`, job `14909542`, and the p=200, K=2 timing
boundary.

## Next Commands

Poll Nibi:

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16923927,16926545 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923927,16926545 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 80; tail -n 160 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/logs/phylo_xlv-16923927-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/results/result_000001.csv 2>/dev/null || true; tail -n 160 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-iter80-2h-20260629-0848/logs/phylo_xlv_h2-16926545-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-iter80-2h-20260629-0848/results/result_000001.csv 2>/dev/null || true; seff 16923927 2>/dev/null || true; seff 16926545 2>/dev/null || true'
```

Poll Rorqual:

```sh
ssh -o BatchMode=yes rorqual 'squeue -j 14909542 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14909542 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 40; tail -n 160 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-rorqual-phylo-target-iter80-2h-20260629-0900/logs/phylo_xlv_h2-14909542-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-rorqual-phylo-target-iter80-2h-20260629-0900/results/result_000001.csv 2>/dev/null || true; seff 14909542 2>/dev/null || true'
```

## Claim Boundary

No production >=500 reps/cell coverage array has launched. These are one-seed
timing and denominator diagnostics only. Do not claim calibrated phylo Model A
coverage until the full DRAC grid is complete and summarised with MCSE and
failed-fit denominators.
