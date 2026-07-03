# After Task: phylo X_lv bootstrap-basic diagnostic tooling

## Goal

Add a cheap, bench-only way to test whether a basic parametric-bootstrap interval
can move the p=80, K=2, lambda=0.5 `B_lv` weak-cell intervals away from the
finite-sample fitted-effect shrinkage center.

## Implemented

Added `bootstrap_basic` to `bench/phylo_xlv_drac_task.jl` and documented it in
`bench/phylo_xlv_drac_submit.sh`.

The method reuses the existing internal `GLLVM._lv_boot_fns()` simulate/refit
closures, including the `bootstrap_iterations` cap, then computes the basic
bootstrap interval for each derived `B_lv` entry:

```text
lower_i = 2 * estimate_i - q_{1-alpha}(B_i^*)
upper_i = 2 * estimate_i - q_alpha(B_i^*)
```

This is deliberately not an exported `confint_lv_effects()` method. It is a
diagnostic candidate for the DRAC weak-cell lane.

## Files Changed

- `bench/phylo_xlv_drac_task.jl`
- `bench/phylo_xlv_drac_submit.sh`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-tooling.md`

## Checks Run

Pre-edit lane check:

```sh
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,title,headRefName,updatedAt,url,mergeStateStatus,isDraft
git log --all --oneline --since="6 hours ago" -- bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh docs/dev-log/check-log.md docs/dev-log/after-task
```

Result: one open draft PR, #127, remote head
`claude/phylo-xlv-modelA-20260627`, merge state `UNSTABLE`; recent touched-file
commits were the local diagnostic commits on this branch.

Validation:

```sh
git diff --check
bash -n bench/phylo_xlv_drac_submit.sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_basic_parse/params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 4 --K 1 --q-lv 1 --K-phy 1 --scenarios main --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_basic_parse/params.csv --outdir /tmp/phylo_xlv_basic_parse/results --task-id 1 --methods bootstrap_basic --targets none --iterations 1 --n-boot 10 --bootstrap-iterations 5 --dry-run
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0.5 PHYLO_XLV_N_SPECIES=4 PHYLO_XLV_N_SITES=4 PHYLO_XLV_K=1 PHYLO_XLV_Q_LV=1 PHYLO_XLV_K_PHY=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_METHODS=bootstrap_basic PHYLO_XLV_N_BOOT=10 PHYLO_XLV_BOOT_ITERATIONS=5 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_basic_submit_probe
rg -n "bootstrap_basic|bootstrap_iterations" /tmp/phylo_xlv_basic_submit_probe/meta/session.txt /tmp/phylo_xlv_basic_submit_probe/meta/phylo_xlv_array.sbatch
bash -n /tmp/phylo_xlv_basic_submit_probe/meta/phylo_xlv_array.sbatch
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_basic_real/params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 8 --K 1 --q-lv 1 --K-phy 1 --scenarios main --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_basic_real/params.csv --outdir /tmp/phylo_xlv_basic_real/results --task-id 1 --methods bootstrap_basic --targets B_lv --iterations 120 --n-boot 10 --bootstrap-iterations 40 --force
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_basic_detail/params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 8 --K 1 --q-lv 1 --K-phy 1 --scenarios main --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_basic_detail/params.csv --outdir /tmp/phylo_xlv_basic_detail/results --task-id 1 --methods bootstrap_basic --targets B_lv --iterations 120 --n-boot 10 --bootstrap-iterations 40 --write-details --force
find /tmp/phylo_xlv_basic_detail/results -maxdepth 1 -type f -exec basename {} \; | sort
```

Results: all checks passed. The n_sites=8 real smoke converged, wrote a
`B_lv/bootstrap_basic` result row with `bootstrap_converged=10`, and the detail
smoke wrote `detail_result_000001_bootstrap_basic.csv`.

Follow-up sidecar audit: the first committed transcript omitted the
`--write-params` command for the detail-smoke params file. The command is listed
above so the validation path is replayable. The audit also noted that
`bootstrap_basic` should not report `ci_status = "ok"` when fewer than 10
bootstrap refits converge; the runner now records
`bootstrap_underconverged` with an explanatory error field in that case.

## Consistency Audit

The exported CI API is unchanged. Existing percentile bootstrap remains
`method = :bootstrap`. `bootstrap_basic` is only a DRAC-runner candidate so the
weak-cell repair can be tested before any public method is considered.

## Known Limitations

This does not prove coverage, repair PR #127, push the local branch, or admit
gllvmTMB source-specific `lv = ~ x`. The next step is a bounded weak-cell
canary against the known p=80, K=2, lambda=0.5 diagnostic seed.
