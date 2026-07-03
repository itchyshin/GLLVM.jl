# Recovery Checkpoint: phylo X_lv t-comparator diagnostic

## Branch And Status

- Branch: `codex/phylo-xlv-drac-launcher-20260628`
- Worktree: `/private/tmp/gllvmjl-phylo-xlv`
- `git status --short --branch` at checkpoint:

```text
## codex/phylo-xlv-drac-launcher-20260628
 M bench/phylo_xlv_drac_submit.sh
 M bench/phylo_xlv_drac_task.jl
 M docs/dev-log/check-log.md
 M src/confint_family.jl
 M test/test_lv_ci.jl
 M test/test_phylo_xlv.jl
?? docs/dev-log/recovery-checkpoints/2026-06-29-154800-codex-phylo-xlv-t-comparator.md
```

## Diff Stat

```text
bench/phylo_xlv_drac_submit.sh |  2 +-
bench/phylo_xlv_drac_task.jl   |  4 ++--
docs/dev-log/check-log.md      | 99 ++++++++++++++++++++++++++++++++++++++++++
src/confint_family.jl          | 44 ++++++++++++++++---
test/test_lv_ci.jl             | 15 ++++++-
test/test_phylo_xlv.jl         |  5 +++
```

## Implemented

- Added Gaussian-only `confint_lv_effects(...; method = :wald_t_unit)` for
  `B_lv`.
- `:wald_t_unit` reuses the same delta-method SE as `:wald`, with
  `TDist(max(n_sites - K - 1, 1))` as the critical value.
- GLM `confint_lv_effects` still rejects `:wald_t_unit`.
- DRAC task parser and submit help now accept `wald_t_unit`.
- Added tests in `test/test_lv_ci.jl` and `test/test_phylo_xlv.jl`.

## Commands Already Run

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_lv_ci.jl
# PASS: 123/123 in 2m37.9s

export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl
# PASS: 19/19 in 57.3s

bash -n bench/phylo_xlv_drac_submit.sh
# PASS

export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_t_params.csv --reps 1 --lambdas 0.5 --n-species 20 --n-sites 80 --K 2 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260629 --force
# PASS

export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_t_params.csv --outdir /tmp/phylo_xlv_t_dry_results --task-id 1 --methods wald,wald_t_unit --targets none --iterations 1 --dry-run
# PASS

git diff --check
# PASS
```

DRAC connectivity:

- Rorqual, Nibi, and Narval accepted non-interactive SSH and have
  `sbatch`/`squeue`.
- Fir failed keyboard-interactive auth.
- Totoro failed publickey/password auth.

## Live DRAC Job

Active comparator run:

```text
cluster: nibi
job: 16950659
out: /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-t-nibi-lambda05-rep10-20260629-1553
shape: scenario=main, lambda=0.5, n_species=80, n_sites=80, K=2, q_lv=1, K_phy=1
targets: B_lv
methods: wald,wald_t_unit
reps: 10
iterations: 400
time: 20m
mem: 4G
latest poll: pending, reason Priority, 0 result files
```

Superseded attempts:

- Rorqual `14932460`: cancelled pending duplicate.
- Nibi `16950453`: cancelled after 21s, 0 result files.
- Narval `64362890`: cancelled pending duplicate.

## Commands Still Needed

Superseded by the 2026-06-29 16:00 MDT update below. The Nibi job completed;
do not use this section as current state.

Historical poll command for the active Nibi job:

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16950659 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-t-nibi-lambda05-rep10-20260629-1553/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l); cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-t-nibi-lambda05-rep10-20260629-1553/results 2>/dev/null || true'
```

When complete, collect:

```sh
ssh -o BatchMode=yes nibi 'seff 16950659 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-t-nibi-lambda05-rep10-20260629-1553/results'
```

Then update `/tmp/gllvm-dashboard/status.json`, `/tmp/gllvm-dashboard/version.txt`,
`docs/dev-log/check-log.md`, and this branch commit.

## Next Safest Action

Wait for Nibi `16950659`. Do not launch production. The next decision depends on
whether `wald_t_unit` materially repairs the λ=0.5 undercoverage seen with
normal Wald (`entry coverage = 0.870` in the prior p=80,K=2 10-rep diagnostic).

## Maintainer Question

None blocking. This is still a diagnostic comparator, not a public coverage
claim.

## 2026-06-29 16:00 MDT Update

Focused local checks were rerun after the `wald_t_unit` wiring:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_lv_ci.jl
# PASS: 123/123 in 2m44.5s

export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl
# PASS: 19/19 in 1m01.7s

git diff --check
# PASS

bash -n bench/phylo_xlv_drac_submit.sh
# PASS
```

Nibi array `16950659` completed:

| method | tasks | fit ok | usable entries | mean coverage (MCSE) | entry coverage | RMSE mean | fit sec mean | CI sec mean | CI status |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| wald | 10 | 10 | 800 | 0.844 (0.058) | 0.844 | 0.093 | 177.633 | 119.286 | ok |
| wald_t_unit | 10 | 10 | 800 | 0.845 (0.058) | 0.845 | 0.093 | 177.633 | 106.874 | ok |

Conclusion: `wald_t_unit` did not materially rescue the known λ=0.5
undercoverage. Keep it as a diagnostic comparator only.

Additional live job at this checkpoint:

```text
cluster: rorqual
job: 14929297
out: /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525
shape: scenario=main, lambda=0.5, n_species=80, n_sites=80, K=2, q_lv=1, K_phy=1
targets: B_lv
methods: wald,profile,bootstrap
n_boot: 30
latest poll: running in profile CI after 34m11s, 0 result files
```

Next safest action is to poll Rorqual `14929297`. Do not launch production, and
do not advertise a t-coverage fix.
