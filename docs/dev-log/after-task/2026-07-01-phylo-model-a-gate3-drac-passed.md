# After Task: Phylo Model A Gate 3 DRAC Passed

## Goal

Reduce and record the completed Gate 3 DRAC/Nibi claim-evidence array for the
non-v1 Phylo Gaussian Model A `B_eta_realized` profile-LR target.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md`
- `docs/dev-log/after-task/2026-07-01-phylo-model-a-gate3-drac-passed.md`

## Evidence

Remote source and result roots:

```text
source:  /scratch/snakagaw/GLLVM.jl-phylo-model-a-gate3
results: /scratch/snakagaw/phylo_model_a_gate3_20260701-1122
depot:   /scratch/snakagaw/julia_depot_gllvm_gate3
source commit for run: 97082bd
```

Final reducer:

```text
job id: 17049809
host: Nibi
result files: 500
detail files: 500
fit convergence: 500/500
profile status: 500/500 ok rows
selected entries: 2500
usable profile truth solves: 2500/2500
covered/planned: 2495/2500 = 0.998000000
task coverage mean: 0.998000000
task coverage MCSE: 0.000890835
Wilson 95 percent interval: 0.995326484 to 0.999145426
LR misses: 5
non-empty error logs: 0
```

Per-entry detail:

```text
entry 8:  500/500 covered, max LR 1.30738161784
entry 14: 498/500 covered, max LR 4.31498848912
entry 41: 497/500 covered, max LR 5.06137330611
entry 44: 500/500 covered, max LR 0.803688155171
entry 71: 500/500 covered, max LR 0.595386972622
```

Misses:

```text
task 124 entry 14 LR 3.99667410209 truth -0.0876639401679
task 134 entry 41 LR 4.64533256499 truth  0.154599570045
task 179 entry 41 LR 5.06137330611 truth  0.122797417305
task 423 entry 41 LR 4.62997900325 truth  0.170278825295
task 444 entry 14 LR 4.31498848912 truth -0.0670786076295
```

## Validation

```sh
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /scratch/snakagaw/phylo_model_a_gate3_20260701-1122/results
find /scratch/snakagaw/phylo_model_a_gate3_20260701-1122/results -maxdepth 1 -name 'result_*.csv' | wc -l
find /scratch/snakagaw/phylo_model_a_gate3_20260701-1122/results -maxdepth 1 -name 'detail_result_*profile_eta_realized.csv' | wc -l
find /scratch/snakagaw/phylo_model_a_gate3_20260701-1122/logs -maxdepth 1 -name '*.err' -size +0c | wc -l
sacct -j 17049809 --format=JobID,JobName%20,State,ExitCode,Elapsed,MaxRSS,AllocCPUS
git diff --check -- docs/dev-log/check-log.md docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md docs/dev-log/after-task/2026-07-01-phylo-model-a-gate3-drac-passed.md
```

## Claim Boundary

Gate 3 passes the amended MCSE-aware claim-evidence gate for the non-v1
`B_eta_realized` target. This closes gates 0-3 for this evidence arc, but it
does not by itself expose source-specific R grammar, reopen PR #127, widen the
package API, or turn the retired population-`B_lv` evidence positive.

## Rose Audit

PASS WITH NOTES. The result is strong DRAC claim evidence for the revised
eta-scale realized target. Public wording must still keep the old
population-`B_lv` route retired and keep source-specific `lv` exposure behind
explicit maintainer authorization.

## Next Command

Refresh gllvmTMB Mission Control so the local board shows Gate 3 passed and no
active compute, then perform the completion audit for gates 0-3.
