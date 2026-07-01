# After Task: Phylo Model A narrowed-regime diagnostic wave

## Goal

Check whether a narrowed Gaussian Model A regime merited a formal ADEMP
diagnostic gate after the old p = 80, K = 2 population-`B_lv` target failed.

Current status: superseded by
`docs/dev-log/after-task/2026-07-01-phylo-model-a-20rep-profile-gate.md`. The
20-replicate K = 1 selected-entry diagnostic gate found two converged
truth-inclusion misses, so K = 1 same-route profile scaling is now stopped.

## Implemented

Ran one local diagnostic-only `profile_truth` scout for K = 1, then repeated it
as a 5-seed selected-entry local diagnostic wave. Updated the narrowed K = 1
ADEMP gate and refreshed Mission Control with the result. No package API,
likelihood, R grammar, source-specific `lv` exposure, bootstrap, or production
compute changed.

## Mathematical Contract

The candidate narrowed target remains the population induced trait/loading
effect:

```text
B_lv[t, 1] = Lambda[t, 1] * alpha_lv[1, 1]
```

`alpha_lv` remains the conditional axis/access-effect output. The scout uses the
one-df profile-LR truth-inclusion diagnostic
`2 * (nll_constrained(B_lv = truth) - nll_mle) <= qchisq(0.95, 1)`.

## Files Changed

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-narrowed-regime-gate.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-phylo-model-a-narrowed-regime-scout.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

## Tests Added

None. This was a diagnostic run plus documentation/status update.

## Benchmark Numbers

N/A - no hot-path implementation changed. The 5-seed diagnostic wave averaged
about `3.740s` per fit and `5.367s` per selected-entry `profile_truth` pass
across five entries.

## R-Parity Verdict

Parity: N/A - no R bridge, likelihood, fitter, init, or CI implementation
changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia source changed in this slice.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata, exports, or dependencies changed.

## Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_model_a_narrow_k1_profile_truth_20260701/meta/params.csv --reps 1 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_narrow_k1_profile_truth_20260701/meta/params.csv --outdir /tmp/phylo_model_a_narrow_k1_profile_truth_20260701/results --task-id 1 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 160 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_narrow_k1_profile_truth_20260701/meta/params.csv --outdir /tmp/phylo_model_a_narrow_k1_profile_truth_20260701_entry5_retry/results --task-id 1 --methods profile_truth --targets B_lv --b-lv-entries 5 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_model_a_narrow_k1_profile_truth_20260701/results
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_model_a_narrow_k1_profile_truth_20260701_entry5_retry/results
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --reps 5 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results --task-id 1 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results --task-id 2 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results --task-id 3 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results --task-id 4 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results --task-id 5 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results
julia --project=. test/test_phylo_xlv.jl
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "updated|Narrowed K=1|tiny K=1|active|queued|blocked|no bootstrap|ADEMP gate|source-specific"
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool | rg -n "updated|Narrowed K=1|tiny K=1|active|queued|blocked|no bootstrap|ADEMP gate|source-specific"
```

Results:

- one-seed scout: first run had 4/5 usable entries, all 4 included truth;
- one-seed entry-5 retry with `--profile-opt-iterations 500` converged and
  included truth;
- 5-seed diagnostic wave: 5/5 fits converged;
- 5-seed diagnostic wave: 25/25 selected entries usable;
- 5-seed diagnostic wave: 25/25 selected entries included truth;
- LR range: `2.65627995759e-05` to `2.54639208502`;
- LR cutoff: `3.84145882069`;
- mean selected-entry LR: `0.45583577218`;
- max-LR row: task 1, seed `21280868`, entry 20, `B_lv[20,1]`.
- focused phylo Model A tests passed after the documentation/status refresh:
  `25/25` in `1m03.9s`.
- Mission Control served JSON updated to `2026-06-30 21:54 MDT`, with the
  diagnostic K = 1 scout visible, `active = 0`, `queued = 0`, and `blocked = 5`.

Exact selected-entry LR values:

```text
entry 1:  LR = 2.3052625172    < 3.84145882069
entry 5:  LR = 0.0686506851789 < 3.84145882069  (retry)
entry 10: LR = 0.309444810472  < 3.84145882069
entry 15: LR = 0.16730512331   < 3.84145882069
entry 20: LR = 2.54639208502   < 3.84145882069
```

## Consistency Audit

The updated gate explicitly labels this as diagnostic-only. It does not revive
bootstrap, does not claim K = 2 support, does not make a coverage claim, and
does not widen R grammar.

## GitHub Issue Maintenance

No GitHub action was taken. PR #127 remains closed/parked as blocked evidence.

## What Did Not Go Smoothly

One selected constrained solve underconverged at 160 optimiser iterations in the
first one-seed scout. The entry-specific retry and the 5-seed wave converged at
500 iterations, suggesting the diagnostic is numerically recoverable, but future
gates need convergence-rate stop rules.

## Team Learning

Curie should treat convergence rate as a first-class performance measure in the
narrowed-regime gate, not just truth inclusion among usable rows.

## Remaining Risks

- Five seeds and twenty-five selected entries are not promotion-grade coverage
  evidence.
- K = 2 remains failed under the old target.
- The narrowed K = 1 regime has not passed ADEMP evidence or MCSE-backed
  coverage.
- Source-specific phylo `lv` remains blocked.

## Known Limitations

This does not produce DRAC claim evidence, does not expose public grammar, and
does not validate endpoint profile intervals.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_model_a_k1_diag20_next/meta/params.csv --reps 20 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
```

## Rose Verdict

Rose verdict: SUPERSEDED - this 5-seed scout justified the 20-replicate gate,
but that gate later found two converged misses. Source-specific phylo `lv`
remains blocked, and K = 1 same-route scaling is stopped.
