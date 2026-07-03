# Codex Recovery Checkpoint - phylo x X_lv live K2 canaries

Date: 2026-06-29 12:15 MDT

## Branch and State

- Worktree: `/private/tmp/gllvmjl-phylo-xlv`
- Branch: `codex/phylo-xlv-drac-launcher-20260628`
- HEAD: `eddb252 bench: export drac depot before params`
- `git status --short --branch`: clean (`## codex/phylo-xlv-drac-launcher-20260628`)
- `git diff --stat`: empty

## Coordination Check

- `gh pr list --state open` shows only draft PR #127:
  `[WIP] feat(phylo): Model A - predictor scores under phylogenetic trait-covariance + session handover`
  on `claude/phylo-xlv-modelA-20260627`.
- `git log --all --oneline --since="6 hours ago"` shows only this Codex DRAC
  sizing/checkpoint sequence on the current branch.

## Completed Since Previous Checkpoint

- Patched `bench/phylo_xlv_drac_submit.sh` so `PHYLO_XLV_DEPOT` is exported into
  `JULIA_DEPOT_PATH` before the launcher's parameter-writing step, not only
  inside the generated `sbatch` script.
- Verified `bash -n bench/phylo_xlv_drac_submit.sh`.
- Instantiated/precompiled the GLLVM.jl project on Narval and Rorqual under
  `/project/6098264/snakagaw/julia_depot`.
- Synced DRAC harness files to Narval and Rorqual.
- Submitted two extra one-task canaries after the existing Nibi lambda=1 canary:
  - Nibi `16933194_1`: p=125,K=2, lambda=1, `targets=all`,
    `iterations=400`, running on `c324`; latest poll at 12:12 MDT showed still
    in fit step after `41:36`.
  - Narval `64343216_1`: p=125,K=2, lambda=1, `targets=all`,
    `iterations=400`, running on `nc31109`; latest poll showed still in fit
    step after `15:06`.
  - Rorqual `14916246_1`: p=125,K=2, lambda=0.5, `targets=all`,
    `iterations=400`, running on `rc32430`; latest poll showed still in fit
    step after `14:51`.
- Updated `/tmp/gllvm-dashboard` to build `r82`; the in-app browser at
  `http://127.0.0.1:8770/` shows all three job IDs.
- Committed the launcher/check-log state as `eddb252`.

## Commands Already Run

```sh
bash -n bench/phylo_xlv_drac_submit.sh
git diff --check
gh pr list --state open
git log --all --oneline --since="6 hours ago"
ssh -o BatchMode=yes nibi 'squeue -j 16933194 ...'
ssh -o BatchMode=yes narval 'squeue -j 64343216 ...'
ssh -o BatchMode=yes rorqual 'squeue -j 14916246 ...'
```

## Commands Still Needed

Poll the live jobs:

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16933194 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16933194 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 20; tail -n 320 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-lambda1-all-iter400-2h-20260629-1124/logs/phylo_xlv-16933194-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-lambda1-all-iter400-2h-20260629-1124/results/result_000001.csv 2>/dev/null || true'
ssh -o BatchMode=yes narval 'squeue -j 64343216 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 64343216 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 20; tail -n 320 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-narval-lambda1-all-iter400-2h-20260629-1200/logs/phylo_xlv-64343216-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-narval-lambda1-all-iter400-2h-20260629-1200/results/result_000001.csv 2>/dev/null || true'
ssh -o BatchMode=yes rorqual 'squeue -j 14916246 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14916246 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 20; tail -n 320 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-rorqual-lambda05-all-iter400-2h-20260629-1200/logs/phylo_xlv-14916246-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-rorqual-lambda05-all-iter400-2h-20260629-1200/results/result_000001.csv 2>/dev/null || true'
```

If any job completes, collect `seff` and summarise:

```sh
ssh -o BatchMode=yes <cluster> 'seff <jobid> 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results <results-dir>'
```

## Next Safest Action

Wait for at least one of the three live canaries to leave the fit step. Do not
launch production `>=500 reps/cell` coverage until these canaries say whether
p=125,K=2,lambda in `{0.5,1}` is fit-convergent and whether B_lv/phylo-signal
interval rows are usable.

## Claim Boundary

IN: the DRAC launcher is usable for one-task canaries across Nibi/Narval/Rorqual,
and p=125,K=2 B_lv is a plausible large-cell boundary from one successful seed.
PARTIAL: lambda=0.5 and lambda=1 p=125,K=2 all-target canaries are still running;
phylo-signal remains unresolved. OUT: no production coverage launch, no
phylo-signal coverage claim, and no full Model A public claim.

## Maintainer Question

No blocking maintainer question right now. A maintainer decision will be needed if
the canaries imply splitting the V1 production evidence into B_lv-only coverage
plus a separate phylo-signal investigation.
