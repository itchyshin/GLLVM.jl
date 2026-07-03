# After Task: phylo X_lv partial-result checkpoints

**Date**: `2026-06-29`
**Executed by**: Codex, live DRAC lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## 1. Goal

Make future long-running phylo `X_lv` DRAC interval canaries more observable by
checkpointing completed method rows before a later profile/bootstrap method has
finished.

## 2. Implemented

- Added `partial_result_<task>.csv` writes to
  `bench/phylo_xlv_drac_task.jl` after each completed B_lv CI method and after
  phylo-signal CI work.
- Kept the final result contract unchanged: final `result_<task>.csv` writes
  remove the partial file.
- Added `--include-partial` to `bench/phylo_xlv_drac_summarise.jl`; default
  summaries continue to read only final `result_*.csv` files.

## 3a. Decisions and Rejected Alternatives

Partial files are intentionally opt-in. I did not make the ordinary summarizer
consume them because a partial row from a long-running canary is diagnostic
evidence, not production coverage evidence.

I also did not change resume semantics for final result files. A completed
`result_<task>.csv` remains the only default production artifact.

## 4. Files Touched

- `bench/phylo_xlv_drac_task.jl`
- `bench/phylo_xlv_drac_summarise.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-partial-result-checkpoints.md`

## 5. Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
julia --project=. bench/phylo_xlv_drac_summarise.jl --help
tmp=$(mktemp -d); header='task_id,scenario,pagel_lambda,n_species,n_sites,K,q_lv,K_phy,rep,seed,level,n_boot,bootstrap_iterations,target,method,fit_converged,fit_iterations,fit_seconds,ci_seconds,ci_status,total,usable,covered,coverage,bias_mean,bias_rmse,estimate_mean,truth_mean,max_abs_estimate,max_abs_truth,pd_hessian,bootstrap_converged,error'; printf '%s\n1,main,0.5,80,80,2,1,1,1,1,0.95,5,20,B_lv,wald,true,10,1,2,ok,80,80,76,0.95,0,0.1,0,0,1,1,true,,\n' "$header" > "$tmp/result_000001.csv"; printf '%s\n2,main,0.5,80,80,2,1,1,2,2,0.95,5,20,B_lv,bootstrap,true,10,1,3,ok,80,80,74,0.925,0,0.1,0,0,1,1,,4,\n' "$header" > "$tmp/partial_result_000002.csv"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$tmp"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$tmp" --include-partial
tmp=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$tmp/params.csv" --reps 1 --lambdas 0 --n-species 6 --n-sites 6 --K 1 --scenarios main; julia --project=. bench/phylo_xlv_drac_task.jl --params "$tmp/params.csv" --outdir "$tmp/results" --methods wald --targets B_lv --iterations 80 --n-boot 3; find "$tmp/results" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null || ls "$tmp/results"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$tmp/results"
git diff --check
```

## 6. Tests of the Tests

The synthetic fixture proves that partial files are excluded by default and
included only when `--include-partial` is supplied. The tiny real task proves
that the task runner writes a partial checkpoint after a completed method and
then removes it when the final `result_000001.csv` is written.

## 7a. Issue Ledger

- Fixed: future multi-method canaries can expose completed rows even if a later
  method runs long.
- Deferred: already-running Nibi, Narval, and Rorqual canaries use the prior
  runner and will not write partial files.

## 8. Consistency Audit

This is bench-runner observability only. It does not alter the Gaussian DGP,
likelihood, fit objective, CI calculations, or production summary defaults.

## 9. What Did Not Go Smoothly

The active Rorqual profile canary highlighted the problem: Wald completed, but
the result row is unavailable until the profile method returns or the job times
out. This change fixes that for future launches only.

## 10. Known Residuals

The current interval-rescue canaries still need to finish or time out before a
production-scale method decision is defensible.

## 11. Team Learning

Fisher: method-level checkpoint rows are useful diagnostics, but they must stay
separate from production coverage summaries.

Grace: long SLURM tasks should write conservative progress artifacts when a
later method can monopolize the allocation.
