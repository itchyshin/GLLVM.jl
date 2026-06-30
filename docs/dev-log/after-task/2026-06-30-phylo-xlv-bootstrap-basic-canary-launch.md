# After-task: phylo X_lv bootstrap-basic canary launch

## Purpose

Launch a bounded Narval diagnostic for the p=80, K=2, lambda=0.5 `B_lv`
weak-cell block without changing exported APIs or pushing PR #127.

## Files changed

- `bench/phylo_xlv_drac_task.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-tooling.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-canary-launch.md`

## What changed

The bench-only `bootstrap_basic` runner now marks fewer than 10 converged
bootstrap refits as `bootstrap_underconverged` with an explanatory error field
instead of reporting `ok` with all-NaN interval bounds. The earlier tooling
report now includes the missing params-generation command for the detail smoke.

## Validation

```sh
git diff --check
bash -n bench/phylo_xlv_drac_submit.sh
rm -rf /tmp/phylo_xlv_basic_underconv && julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_basic_underconv/params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 8 --K 1 --q-lv 1 --K-phy 1 --scenarios main --force && julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_basic_underconv/params.csv --outdir /tmp/phylo_xlv_basic_underconv/results --task-id 1 --methods bootstrap_basic --targets B_lv --iterations 120 --n-boot 2 --bootstrap-iterations 40 --force && tail -n 1 /tmp/phylo_xlv_basic_underconv/results/result_000001.csv
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
ssh -o BatchMode=yes narval 'grep -n "bootstrap_underconverged" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl; squeue -j 64432230 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"'
ssh -o BatchMode=yes narval 'bash -s'  # submitted detail-array canary for task IDs 3,6,7
```

Results: local syntax and diff checks passed. The under-convergence smoke wrote
`ci_status=bootstrap_underconverged`, `usable=0`, `bootstrap_converged=2`, and
the expected error text. The patched runner was present on Narval before the
task-8 job moved past queue startup.

## Cluster jobs

- Task 8: job `64432230`, output
  `/project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-bootstrap-basic-task8-narval-20260630-155803`.
- Tasks 3, 6, 7: array job `64432317`, output
  `/project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-bootstrap-basic-detail367-narval-20260630-160111`.

Both jobs use `method=bootstrap_basic`, `target=B_lv`, `n_boot=30`,
`bootstrap_iterations=120`, and `iterations=400`.

## Claim boundary

IN: diagnostic launch for a bias-corrected bootstrap interval candidate on the
known weak-cell detail reps. OUT: no production coverage claim, no exported API
change, no PR #127 push, and no gllvmTMB phylo grammar exposure.

## Next action

Poll `squeue` and inspect result/detail CSVs when the jobs finish. If
`bootstrap_basic` still follows the same fitted-effect shrinkage, record the
interval wrapper route as blocked and move to estimator/design repair instead
of launching more coverage.
