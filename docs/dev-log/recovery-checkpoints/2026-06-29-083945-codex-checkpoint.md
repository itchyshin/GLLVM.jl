# Recovery Checkpoint: phylo X_lv DRAC target timing

Generated: `2026-06-29 08:39 MDT`
Agent: Codex
Repository: `/private/tmp/gllvmjl-phylo-xlv`
Branch: `codex/phylo-xlv-drac-launcher-20260628`
HEAD: `3b28c19`

## Goal

Resume latent(lv = ~ x) Phase 3 DRAC Model A coverage from the committed
target timing instrumentation. Monitor Nibi p=200, K=2 job `16923927` before
launching production arrays.

## Git State

```sh
git status --short --branch
```

```text
## codex/phylo-xlv-drac-launcher-20260628
```

```sh
git diff --stat
```

```text
(no output)
```

Recent commits:

```text
3b28c19 docs: close phylo xlv timing instrumentation
3bcbc84 bench: instrument phylo xlv target timing
1ba1f00 docs: record phylo xlv large k2 timing split
```

## Completed In This Slice

- Added bench-only `ci_seconds` timing and `--targets` controls to
  `bench/phylo_xlv_drac_task.jl`.
- Threaded `PHYLO_XLV_TARGETS` through
  `bench/phylo_xlv_drac_submit.sh`.
- Added mean fit/CI seconds to `bench/phylo_xlv_drac_summarise.jl`.
- Recorded evidence in `docs/dev-log/check-log.md`.
- Wrote after-task report
  `docs/dev-log/after-task/2026-06-29-phylo-xlv-target-timing.md`.
- Updated local dashboard `/tmp/gllvm-dashboard/status.json` and opened
  `http://127.0.0.1:8770/?refresh=20260629-0834` in the in-app browser.

## Validation Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
bash -n bench/phylo_xlv_drac_submit.sh
d=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$d/params.csv" --reps 1 --lambdas 0 --n-species 3 --n-sites 3 --K 1 --scenarios main; julia --project=. bench/phylo_xlv_drac_task.jl --params "$d/params.csv" --outdir "$d/results" --task-id 1 --targets none --dry-run; julia --project=. bench/phylo_xlv_drac_task.jl --params "$d/params.csv" --outdir "$d/results" --task-id 1 --targets all --dry-run
d=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$d/params.csv" --reps 1 --lambdas 0 --n-species 3 --n-sites 8 --K 1 --scenarios main; julia --project=. bench/phylo_xlv_drac_task.jl --params "$d/params.csv" --outdir "$d/results" --task-id 1 --targets none --iterations 20 --force; julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$d/results"; cat "$d/results/result_000001.csv"
```

Results: help rendered; `bash -n` passed; dry-run target parsing passed; tiny
fit-only task converged in 12 iterations, wrote `ci_seconds`, and summarised.

## Live DRAC State

Nibi job `16923927_1` at last poll:

- state `RUNNING`;
- elapsed `00:59:33`;
- node `c481`;
- fit converged in 47 iterations after `1394.49` seconds;
- still in `B_lv` Wald CI;
- no result CSV yet.

Rorqual job `14901949_1` previously completed the same p=200, K=2 one-seed
diagnostic in `03:59:54`, with usable B_lv Wald rows but unusable phylo-signal
rows.

## Next Safest Command

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16923927 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923927 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 40; sstat -j 16923927.batch --format=JobID,AveCPU,AveRSS,MaxRSS -P 2>/dev/null || true; tail -n 160 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/logs/phylo_xlv-16923927-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/results/result_000001.csv 2>/dev/null || true; seff 16923927 2>/dev/null || true'
```

If it completes, record the result and `seff`, update
`docs/dev-log/check-log.md`, update mission control, and then decide whether to
launch target-instrumented B_lv-only or fit-only canaries from a separate
staged source tree. Do not launch production 500 reps/cell arrays until the
p=200, K=2 interval strategy is resolved.

## Blocking Questions

None for the current instrumentation slice. Maintainer sign-off is still needed
before PR #127 merge/public R exposure, and GLLVM.jl push remains disallowed
without explicit maintainer instruction.
