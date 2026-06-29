# Recovery Checkpoint: phylo X_lv K2 live sizing

Date: 2026-06-29 10:15 MDT

Branch: `codex/phylo-xlv-drac-launcher-20260628`

Head before this checkpoint: `a0e0f91 docs: record nibi p200 k2 blv timing result`

`git status --short --branch`:

```text
## codex/phylo-xlv-drac-launcher-20260628
 M bench/phylo_xlv_drac_submit.sh
 M docs/dev-log/check-log.md
```

`git diff --stat`:

```text
 bench/phylo_xlv_drac_submit.sh |  6 ++++-
 docs/dev-log/check-log.md      | 58 ++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 63 insertions(+), 1 deletion(-)
```

## Commands Already Run

- Pre-edit coordination check:
  - `gh pr list --state open` showed only GLLVM.jl draft PR `#127`.
  - `git log --all --oneline --since="6 hours ago"` showed only this branch's
    recent phylo X_lv DRAC commits.
- Dashboard:
  - `/tmp/gllvm-dashboard/index.html`, `status.json`, and `version.txt` updated
    through build `r69`.
  - Added a top-of-board compute-status table.
  - Browser render verified through the in-app browser at
    `http://127.0.0.1:8770/`.
- Cluster sweep:
  - Narval, Nibi, Rorqual, Fir, and Trillium accepted batch SSH queue probes.
  - Totoro rejected noninteractive SSH with
    `Permission denied (publickey,password)`, so do not use it for unattended
    commands until auth is fixed.
- Submitted one additional bounded fallback:
  - Nibi job `16929004`;
  - output
    `/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter80-2h-20260629-1008`;
  - `n_species=125`, `n_sites=125`, `K=2`, `targets=B_lv`, `iterations=80`,
    one seed/task, 2h cap.
- Patched `bench/phylo_xlv_drac_submit.sh` so a future unset
  `PHYLO_XLV_JULIA` records `command -v julia` as an absolute executable. This
  prevents generated sbatch files from reloading an unintended default Julia
  module after a specific module was loaded in the submit shell.
- Validation:
  - `bash -n bench/phylo_xlv_drac_submit.sh` passed.
  - A write-only tiny submit probe generated an sbatch containing
    `case "/Users/z3437171/.juliaup/bin/julia" in` and the absolute Julia
    command line.
  - `/tmp/gllvm-dashboard/status.json` parsed as JSON; served `version.txt`
    reads `r69`.
  - `git diff --check` passed.

## Live Jobs To Poll

- Narval `64331208_1`: p=150, K=2, `B_lv` only.
  - Output:
    `/project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939`.
  - Last poll: running at `42:58` wall time.
  - Fit converged in `67` iterations after `1001.39s`.
  - Still inside `B_lv CI start method=wald`.
- Nibi `16929004_1`: p=125, K=2, `B_lv` only.
  - Output:
    `/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter80-2h-20260629-1008`.
  - Last poll: running at `5:14` wall time on node `c9`.
  - Entered fit step at `2026-06-29T16:11:45.892Z`.
  - Caveat: generated before the launcher pin; stderr shows
    `julia/1.10.10 => julia/1.12.5`. Treat as timing-bracket evidence only.

## Next Commands

Poll live jobs first:

```sh
ssh -o BatchMode=yes narval 'squeue -j 64331208 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 220 /project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939/logs/phylo_xlv-64331208-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939/results/result_000001.csv 2>/dev/null || true'
ssh -o BatchMode=yes nibi 'squeue -j 16929004 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 220 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter80-2h-20260629-1008/logs/phylo_xlv-16929004-1.out 2>/dev/null || true; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter80-2h-20260629-1008/logs/phylo_xlv-16929004-1.err 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter80-2h-20260629-1008/results/result_000001.csv 2>/dev/null || true'
```

After either job finishes:

```sh
ssh -o BatchMode=yes <cluster> 'sacct -j <jobid> --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 30; seff <jobid> 2>/dev/null || true'
ssh -o BatchMode=yes <cluster> 'cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results <output>/results'
```

Then append a result entry to `docs/dev-log/check-log.md`, update
`/tmp/gllvm-dashboard/status.json`, and decide whether the V1 K=2 large boundary
can be p=150, p=125, or whether a new interval strategy is required.

## Next Safest Action

Wait for Narval p=150 and Nibi p=125 results. Do not launch a production
`>=500` reps/cell array until the K=2 large-cell boundary/interval strategy is
settled. Do not push this branch unless the maintainer explicitly asks.

## Blocking Question

No immediate maintainer question. The decision point is whether V1 production
coverage may define the K=2 large cell below p=200 if observed-information
`B_lv` intervals remain too slow.
