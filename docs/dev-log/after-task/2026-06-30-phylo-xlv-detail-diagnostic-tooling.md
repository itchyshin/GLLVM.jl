# After Task: phylo X_lv per-entry weak-cell diagnostic tooling

**Date**: `2026-06-30`
**Executed by**: Codex, live DRAC lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## 1. Goal

Move from aggregate weak-cell coverage toward diagnosis by making the DRAC
runner able to write per-entry `B_lv` interval details for selected reruns.

## 2. Implemented

- Added `--write-details` to `bench/phylo_xlv_drac_task.jl`.
- Added diagnostic detail files named `detail_result_<task>_<method>.csv`.
- Detail rows record each `B_lv` entry's term, estimate, lower bound, upper
  bound, truth, coverage flag, miss side, and interval width.
- Added `PHYLO_XLV_WRITE_DETAILS=1` support to
  `bench/phylo_xlv_drac_submit.sh`.
- Synced the updated bench scripts to the Narval project checkout and launched
  one worst-seed detail rerun.

## 3a. Decisions and Rejected Alternatives

I kept the default result schema unchanged. Detail output is opt-in because
production coverage summaries should not suddenly grow per-entry artifacts or
change denominator semantics.

I chose task 8 for the first detail rerun because it was the catastrophic seed
in the 10-seed capped-bootstrap diagnostic: `26/80` covered, coverage `0.325`.

I did not launch a new production grid. The point of this slice is to learn
which entries miss and on which side before spending more DRAC time.

## 4. Files Touched

- `bench/phylo_xlv_drac_task.jl`
- `bench/phylo_xlv_drac_submit.sh`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-detail-diagnostic-tooling.md`

## 5. Checks Run

```sh
ssh -o BatchMode=yes narval '... concatenate 10 capped-bootstrap result rows ...' > /tmp/phylo_xlv_bootstrap10_results.csv
awk -F, '... coverage-by-seed table ...' /tmp/phylo_xlv_bootstrap10_results.csv | sort -k3,3n
tmp=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$tmp/params.csv" --reps 1 --lambdas 0 --n-species 6 --n-sites 6 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260630 --force; julia --project=. bench/phylo_xlv_drac_task.jl --params "$tmp/params.csv" --outdir "$tmp/results" --methods wald --targets B_lv --iterations 80 --n-boot 3 --write-details
PHYLO_XLV_WRITE_DETAILS=1 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_detail_submit_probe
bash -n /tmp/phylo_xlv_detail_submit_probe/meta/phylo_xlv_array.sbatch
tmp=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$tmp/params.csv" --reps 1 --lambdas 0 --n-species 4 --n-sites 6 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260631 --force >/dev/null; julia --project=. bench/phylo_xlv_drac_task.jl --params "$tmp/params.csv" --outdir "$tmp/results" --methods wald --targets B_lv --iterations 60 --n-boot 3 >/tmp/phylo_xlv_no_detail_probe.log
git diff --check
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
ssh -o BatchMode=yes narval '... sbatch detail-task8.sbatch ...'
```

Results:

- the opt-in local run wrote `result_000001.csv` and
  `detail_result_000001_wald.csv`;
- the default local run wrote only `result_000001.csv`;
- the submitter probe wrote `write_details=1`, generated `detail_args`, passed
  `--write-details`, and `bash -n` passed;
- `git diff --check` passed;
- Narval job `64403633` was submitted and was running on `cpubase_b` at the
  first poll.

## 6. Tests of the Tests

The local opt-in/default pair checks both sides of the new contract: detail
files appear only when requested, and ordinary result files still appear in the
old location. The submitter probe checks the generated sbatch text rather than
only the shell variables in the parent process.

## 7a. Issue Ledger

- Found: capped-bootstrap coverage heterogeneity is severe. Seeds 1, 2, 4, 5,
  7, 9, and 10 are near nominal, while seeds 3, 6, and 8 drive the aggregate
  failure.
- Fixed: future diagnostic reruns can expose per-entry miss side and width.
- Pending: Narval job `64403633` must finish before we can say whether misses
  concentrate by entry/block or side.

## 8. Consistency Audit

This change is bench-runner instrumentation only. It does not change the DGP,
likelihood, optimiser, interval formulas, bootstrap seed convention, production
result schema, or summariser default. Mission Control should continue to show
phylo production coverage as blocked.

## 9. What Did Not Go Smoothly

The first submitter patch used Bash `${var,,}` lowercasing, which is not
portable to the local Bash. I replaced it with an explicit `case` pattern and
reran the submitter probe before syncing to Narval.

The first remote wrapper submitted the job but failed while capturing the job id
because `$4` was expanded under `set -u`. I recovered the job id from `squeue`;
the running job is `64403633`.

## 10. Known Residuals

The LV arc remains incomplete. We still need the detail result from job
`64403633`, analysis of the missed entries, and a decision about whether the
failure is target/DGP mismatch, estimator bias, covariance/SE mapping, or an
interval-method limitation. No public R exposure follows from this tooling.

## 11. Team Learning

Fisher: aggregate coverage alone is now too blunt; the next table must expose
entry-level miss direction. Grace: keep diagnostic artifacts opt-in so
production summaries stay stable. Rose: negative coverage evidence is still the
source of truth until the detail rerun proves a narrower explanation.
