# After Task: phylo X_lv weak-cell mechanism diagnosis

**Date**: `2026-06-30`
**Executed by**: Codex, live DRAC lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## 1. Goal

Diagnose the p=80, K=2, lambda=0.5 `B_lv` weak-cell failure before spending
more DRAC time on production phylo Model A coverage or exposing
`phylo_latent(..., lv = ~ x)` through `gllvmTMB`.

## 2. Implemented

- Added `--truth-init` to `bench/phylo_xlv_drac_task.jl`.
- Added `PHYLO_XLV_TRUTH_INIT=1` support to
  `bench/phylo_xlv_drac_submit.sh`.
- Ran a truth-start rerun for the original catastrophic task-8 seed.
- Completed per-entry Wald/bootstrap detail for rep 8 and bootstrap detail for
  reps 3, 6, and 7.
- Refreshed `/tmp/gllvm-dashboard/status.json` and verified the open browser
  widget at `http://127.0.0.1:8770/`.

## 3a. Decisions and Rejected Alternatives

I added truth starts as opt-in diagnostic tooling only. Default coverage runs
and CSV schemas are unchanged.

I cancelled the first truth-start job because it regenerated task id 8 with a
different seed. The corrected job used the original Narval parameter file and
seed `202614420856`.

I did not launch production coverage. The detailed rows show that the current
interval machinery is not admissible for this weak cell.

## 4. Files Touched

- `bench/phylo_xlv_drac_task.jl`
- `bench/phylo_xlv_drac_submit.sh`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-weak-cell-mechanism-diagnosis.md`

External dashboard artifact:

- `/tmp/gllvm-dashboard/status.json`

## 5. Checks Run

```sh
bash -n bench/phylo_xlv_drac_submit.sh
git diff --check
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_truthinit_smoke/params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 4 --K 2 --q-lv 1 --K-phy 1 --scenarios main
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_truthinit_smoke/params.csv --outdir /tmp/phylo_xlv_truthinit_smoke/results --task-id 1 --targets none --iterations 2 --truth-init --force
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
ssh narval 'scancel 64409162 || true; ... submit original-params truth-init job 64409200 ...'
ssh narval "sacct -j 64409200 --format=JobID,JobName%24,State,Elapsed,MaxRSS,ExitCode -P"
ssh narval "sacct -j 64403633 --format=JobID,JobName%24,State,Elapsed,MaxRSS,ExitCode -P"
ssh narval "sacct -j 64407702 --format=JobID,JobName%24,State,Elapsed,MaxRSS,ExitCode -P"
python - <<'PY'
# CSV-parser summaries for Wald/bootstrap detail rows and miss overlap.
PY
python -m json.tool /tmp/gllvm-dashboard/status.json >/tmp/gllvm-dashboard/status.validated.json
gh pr view 127 --json number,state,headRefName,headRefOid,isDraft,mergeStateStatus,statusCheckRollup,url,title,updatedAt
```

Browser verification:

- reloaded `http://127.0.0.1:8770/`;
- confirmed `live - 2026-06-30 07:39 MDT`;
- confirmed final rep 3/6/7/8 detail text and blocked production coverage.

## 6. Tests of the Tests

The truth-start smoke verified the new flag reaches an actual fit. The remote
rerun verified it on the real p=80, K=2 phylo task with the original seed.

The CSV analyses used Python's CSV parser because `term` values contain commas
inside quoted cells, so `awk -F,` would split fields incorrectly.

## 7a. Issue Ledger

- Found: task 8 is not an initialization basin failure. Truth-start Wald covered
  `34/80`, identical to default Wald, with mean absolute estimate shift
  `0.00009`.
- Found: task-8 bootstrap covered `26/80`, overlapped `45/46` Wald misses plus
  9 bootstrap-only misses, and had the same miss side for every overlapping
  miss.
- Found: bootstrap intervals were narrower than Wald for reps 3, 6, 7, and 8.
- Found: bootstrap reproduced the weak aggregate rows for reps 3 and 6, left
  rep 7 clean, and had `30/30` converged bootstrap refits in every detailed row.
- Pending: design a narrow estimator/interval repair or keep phylo Model A
  coverage blocked.

## 8. Consistency Audit

The dashboard now says the phylo row is blocked by finite-sample fitted-effect
shrinkage, not queued for production scaling. PR #127 remains open draft on old
head `b87a522` with CI red; local fixed commits remain unpushed under the
no-push rule.

No likelihood, formula grammar, public API, result schema, or default DRAC
coverage behavior changed.

## 9. What Did Not Go Smoothly

The first truth-start submission regenerated params and therefore used the
wrong seed for task 8. I caught this from the log, cancelled job `64409162`, and
submitted corrected job `64409200` against the original params file.

The bootstrap-detail jobs took the expected 1h16-1h18 wall time, so the session
spent most of its time waiting for compute rather than editing.

## 10. Known Residuals

The LV arc is still not complete. GLLVM.jl phylo Model A point/CI plumbing exists
locally, but production coverage is blocked for the p=80, K=2, lambda=0.5
`B_lv` weak cell. `gllvmTMB` should keep source-specific lv grammar fail-loud
until a repair or explicit blocked decision lands.

Full `Pkg.test()` was not rerun for this instrumentation slice; the changed path
was checked by a focused truth-init smoke, shell syntax, `git diff --check`, and
live Narval jobs.

## 11. Team Learning

Fisher: percentile bootstrap is not a rescue when the fitted effect is already
shrunk; it can narrow around the wrong center. Grace: opt-in diagnostics are the
right tool for cluster evidence without disturbing production schemas. Rose:
mission control must distinguish "active diagnosis" from "ready to scale" so a
weak cell does not drift into a public claim.
