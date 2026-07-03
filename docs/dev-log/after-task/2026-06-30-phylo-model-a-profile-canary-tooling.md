# After Task: Phylo Model A profile-LR canary tooling

## Goal

Make the redesigned phylo Model A profile-LR `B_lv` canary runnable on a small,
predeclared set of `vec(B_lv)` entries before any new broad compute launch or
source-specific R grammar exposure.

Superseded note, 2026-07-01: this report covers selected-entry endpoint-profile
tooling. A later cheaper `profile_truth` canary for the same task-8 entry-71
weak row converged locally and missed truth (`LR = 9.99181181962 >
3.84145882069`). The tooling remains useful for future renamed/narrowed targets,
but it is not a rescue for the old population-`B_lv` interval target.

## Implemented

- Added a private selected-entry route to `_lv_effect_profile(...)` through an
  internal `indices` keyword. The default remains the full `vec(B_lv)` profile.
- Added `--b-lv-entries all|1,5,9:12` to
  `bench/phylo_xlv_drac_task.jl`.
- Added `PHYLO_XLV_B_LV_ENTRIES` to
  `bench/phylo_xlv_drac_submit.sh`.
- Added `b_lv_entries` provenance to result/detail CSV schemas.
- Preserved original `vec(B_lv)` entry IDs in detail rows, so a selected-entry
  canary cannot be mistaken for a smaller trait dimension.
- Warm-started constrained profile solves from the nearest previous constrained
  solution across bracket and bisection points.
- Added bench-runner per-entry progress logging for selected `B_lv` profile
  canaries.
- Added an opt-in bench-only exact Gaussian profile engine for selected
  `B_lv` entries via `--profile-engine exact`; default remains `penalty`.
- Added `--profile-opt-iterations` and lower/upper side progress logging for
  the exact bench engine.
- Added a focused phylo Model A test for the internal selected-entry profile
  route.
- Refreshed the local gllvmTMB Mission Control JSON to say selected-entry
  profile canary tooling exists locally, while weak-cell evidence remained
  pending at that point and no compute fan-out was running. Later Mission
  Control updates record the negative `profile_truth` result and the
  no-bootstrap/profile-after-target-lock method policy.

## Mathematical Contract

The interval target is still the rotation-invariant trait/loading effect
`B_lv = Lambda * alpha_lv'`. Raw `alpha_lv` remains an axis/access-effect point
quantity only. The selected-entry path changes how much of `vec(B_lv)` is
profiled in a canary; it does not change the likelihood, estimand,
parameterisation, public API, or chi-square reference.
The warm-start path changes optimisation initialisation only; it should recover
the same constrained profile target more efficiently.

## Files Changed

- `src/confint_family.jl`
- `bench/phylo_xlv_drac_task.jl`
- `bench/phylo_xlv_drac_submit.sh`
- `test/test_phylo_xlv.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-model-a-profile-canary-tooling.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

## Tests Added

`test/test_phylo_xlv.jl` now exercises `_lv_effect_profile(...; indices = ...)`
under the existing Gaussian phylo Model A fixture and checks:

- selected profile method is `:profile`;
- returned terms match the selected full-profile terms;
- estimates match the selected `B_lv` entries;
- finite bounds bracket the estimates;
- invalid index `0` throws `ArgumentError`.

After the warm-start change, the same focused test passed again.

## Benchmark Numbers

Tiny local smoke only, not a benchmark or coverage claim:

- p = 5, n_sites = 60, K = 1, lambda = 0.5, one seed, truth-init.
- selected profile entries: `2,4`.
- fit converged in 35 iterations.
- CI time: `33.336867094` seconds.
- result row: `total = 2`, `usable = 2`, `covered = 2`, `coverage = 1.0`.

These numbers prove runner plumbing and selected-entry accounting only. They do
not say the p = 80, K = 2 weak cell is fixed.

## R-Parity Verdict

Parity: N/A. This is Julia-side diagnostic tooling for a private canary route,
not R bridge or gllvmTMB grammar exposure.

## JET / Allocs / Aqua Verdicts

- JET: not run.
- Allocs: not run.
- Aqua: not run.

The changed hot route is an expensive diagnostic profile path, not an allocation
or type-stability-sensitive production inner loop.

## Checks Run

```sh
julia --project=. test/test_phylo_xlv.jl
bash -n bench/phylo_xlv_drac_submit.sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
smoke_dir=/tmp/phylo_xlv_profile_subset_smoke
julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$smoke_dir/meta/params.csv" --reps 1 --lambdas 0.5 --n-species 5 --n-sites 60 --K 1 --q-lv 1 --K-phy 1 --scenarios main
julia --project=. bench/phylo_xlv_drac_task.jl --params "$smoke_dir/meta/params.csv" --outdir "$smoke_dir/results" --task-id 1 --methods profile --targets B_lv --b-lv-entries 2,4 --iterations 250 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_profile_subset_smoke/results
git diff --check -- src/confint_family.jl bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh test/test_phylo_xlv.jl docs/dev-log/check-log.md
julia --project=. test/runtests.jl
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/version.txt
```

Results:

- `test/test_phylo_xlv.jl`: `25/25` pass in `1m19.2s`.
- After warm-starting constrained solves, `test/test_phylo_xlv.jl`: `25/25`
  pass in `1m09.4s`.
- After adding per-entry profile progress logging, `test/test_phylo_xlv.jl`:
  `25/25` pass in `1m03.9s`.
- After adding the opt-in exact profile engine, `test/test_phylo_xlv.jl`:
  `25/25` pass in `1m04.3s`.
- Submitter syntax: `bash -n` passed.
- Task help shows `--b-lv-entries all|1,5,9:12`.
- Tiny smoke wrote `result_000001.csv` and
  `detail_result_000001_profile.csv`.
- Summariser read one profile row with two usable entries and `ci_status = ok`.
- A second tiny bench-level smoke after the per-entry logging change printed
  entry start/done lines for entries `2` and `4`, wrote result/detail CSVs, and
  summarised one profile row with two usable entries and `ci_status = ok`.
- A tiny exact-engine smoke with `--profile-engine exact` wrote
  `method = profile_exact`, two usable entries, entry coverage `1.000`, and
  `ci_status = ok`; bounds matched the penalty smoke at the useful canary
  precision, while the two exact entry solves completed in `2.66s` and `0.04s`
  after shared Hessian setup.
- A capped exact smoke with default `--profile-opt-iterations 250` passed
  locally and printed lower/upper side progress lines.
- `git diff --check` passed.
- `julia --project=. test/runtests.jl` was attempted but not completed. I
  interrupted it after about 40 minutes of active CPU while it was in an
  unrelated two-part `test_confint_family.jl` bootstrap/profile path.
- Mission Control source JSON parsed, synced to the live local widget at
  `http://127.0.0.1:8770/`, and `version.txt` remained `r60`.

One shell smoke command ended nonzero only because the final `cat` guessed the
wrong detail filename after the successful task. The actual detail artifact was
then inspected and was correct.

## First Weak-Cell Canary Launch

After Shinichi clarified that bootstrap should not be the next route, I used the
selected-entry tooling to launch the first actual weak-cell profile canary:

- host: Narval / DRAC, Julia `1.10.10`;
- first job: `64462844`, canceled after cold-start profile remained running
  with no result;
- warm-start job: `64463813`;
- params: original task-8 weak-cell params from the Narval diagnostic run;
- task: `8`, seed `202614420856`;
- cell: p = 80, n_sites = 80, K = 2, lambda = 0.5;
- method: `profile`;
- target: `B_lv`;
- entries: `71,67,1,74`;
- bootstrap: none;
- scope: one-core diagnostic canary, not production fan-out.

The entries were chosen from the prior task-8 detail CSV as the largest
bootstrap-basic misses while preserving both miss directions. The first
cold-start job fit in `143.57s` but remained in profile with no result for about
22 minutes, so I canceled it after syncing the warm-started helper. The
warm-start job `64463813` ran on Narval, fit with `converged = true`,
`iterations = 116`, and `seconds = 141.01`, then entered `B_lv` profile
inversion for entries `71,67,1,74`. It was still running at `00:46:00` elapsed
with no result/detail CSV, so I canceled it at `00:46:38` as runtime/
observability evidence rather than statistical evidence. I then synced the
per-entry logging runner to Narval, verified the staged file contains
`B_lv profile entry ... start/done` progress lines, and launched job `64466208`
(`phylo_xlv_p71`) as a one-core logged canary for the same task-8 seed and entry
`71` only. At first poll, `64466208` was running on `nc30402` and had entered
the fit phase. Mission Control was updated and browser/curl-verified to show one
active diagnostic canary, no queued production row, and continued blocked status
for phylo Model A.

Later, job `64466208` fit with `converged = true`, `iterations = 116`, and
`seconds = 141.44`, then printed `B_lv profile entry 71 start (1/1)`. It was
still running at `00:22:08` elapsed with no done line. I prepared the exact
engine locally, but the attempted rsync to Narval hit a transport timeout and
Narval reported a transient `/home/snakagaw` I/O warning, so no exact Narval
replacement has been launched yet.
Follow-up: `scp` succeeded where `rsync` had timed out, and the staged Narval
runner now contains the exact profile code. I canceled penalty job `64466208` at
`00:32:04` elapsed with no result and launched exact job `64468504`
(`phylo_xlv_e71`) for the same task-8 seed and entry `71`, with no bootstrap and
no production fan-out. Mission Control now shows the exact Narval canary as the
active job.
Final remote state for this turn: exact job `64468504` fit successfully
(`converged = true`, `iterations = 116`, `seconds = 145.03`), entered exact
profile for entry `71`, anchored on `alpha[1]`, and hit the 30-minute SLURM
limit with no result/detail CSV. I prepared and attempted to launch a capped
exact retry with `--profile-opt-iterations 120`, but the combined sync/submit
command hung during Narval filesystem/transport instability and no new job id
was confirmed. Mission Control was corrected to `0 active`, `0 queued`,
`5 blocked`.
Continuation: Narval recovered enough to confirm `64468504` timed out. I added
`--profile-maxstep` and `--profile-bisect-iterations` plus lower/upper bracket
and bisection progress logging. Local progress-capped exact smoke passed with
`--profile-opt-iterations 80 --profile-maxstep 12 --profile-bisect-iterations
10`, summarising one `profile_exact` row with two usable entries and
`ci_status = ok`. Focused phylo tests passed again, `25/25` in `1m06.1s`.
I synced the staged Narval runner and launched capped exact job `64471433`
for task 8, entry `71`, same seed `202614420856`, no bootstrap, no production
fan-out. First poll confirmed it running on `nc11002`; later scheduler/log reads
were intermittently blocked by Narval filesystem/transport latency. Mission
Control now shows `1 active`, `0 queued`, `4 blocked`.

The first remote `rsync` accidentally copied three files into the remote repo
root. I immediately synced the files to their intended `src/` and `bench/`
locations and removed only those accidental root-level copies before the dry-run
and submission.
A later attempt to sync the per-entry logging runner to Narval timed out during
transport while the remote path was slow; a later retry succeeded and was
verified by grepping the staged bench runner for the per-entry progress lines.

## GitHub Issue Maintenance

No PR was opened, reopened, pushed, or commented. PR #127 remains parked as
blocked evidence.

## What Did Not Go Smoothly

The old full-vector profile route had already timed out on Rorqual for the
p = 80, K = 2, lambda = 0.5 weak cell. This slice therefore had to preserve full
profile behavior while adding a narrow canary path. The main implementation risk
was provenance: selected entries must be visible in the result schema so later
summaries cannot confuse a two-entry canary with a full-vector coverage row.

## Team Learning

Fisher owns the interval target, but Grace and Rose need schema hooks too:
selected-entry diagnostics must carry their denominator in every artifact before
they are eligible for later seed-matched evidence.

## Remaining Risks

- The p = 80, K = 2, lambda = 0.5 weak-cell one-entry exact endpoint-profile
  canary did not land from Narval (`64468504` timed out; `64471433` could not be
  read because Narval login/status reads stalled).
- A local seed-matched `profile_truth` canary for the same task-8 entry-71 row
  later converged and missed truth, so endpoint-profile fan-out is no longer an
  admissible rescue for the old target.
- No production coverage or public source-specific `lv` claim is established.
- Full `Pkg.test()` has not been run. The quick core suite was attempted but
  interrupted after about 40 minutes in an unrelated two-part CI path.
- Any future canary needs a renamed/narrowed estimand plus predeclared
  entries/replicate IDs before any Totoro or DRAC execution.

## Known Limitations

The selected-entry path is internal diagnostic tooling. It is not an exported
API, not R grammar, not source-specific phylo `lv` support, and not a replacement
for the final evidence gate.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && sed -n '1,140p' docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md
```

## Rose Verdict

Rose verdict: PASS WITH BLOCKERS REMAINING. The practical selected-entry
profile tooling exists and has a focused local smoke, but the old weak-cell
target is now blocked by the later negative `profile_truth` canary. Future use
requires structural redesign or a narrower target first.
