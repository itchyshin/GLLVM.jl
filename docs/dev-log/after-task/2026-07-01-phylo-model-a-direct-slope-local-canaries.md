# After Task: Phylo Model A Direct-Slope Local Canaries

## Goal

Exercise the realized direct-slope `B_lv_direct_slope` canary beyond the tiny
smoke without launching production compute or changing public support claims.

## Implemented

Ran two local diagnostic canaries with `profile_direct_slope`: a K = 1,
p = 20, n_sites = 200 five-seed selected-entry wave, and the old failed
population-target task-8 entry-71 row at p = 80, K = 2. Both passed under the
realized/sampling-conditional target. Planning docs and local Mission Control
were refreshed to say the redesigned target is alive but still blocked from
public source-specific phylo `lv` exposure.

## Mathematical Contract

The canary computes the saturated direct-slope target per replicate:

```text
D = [1  X_lv]
Gamma_direct = D \ Y'
B_direct[t, c] = Gamma_direct[c + 1, t]
```

Selected fitted `B_lv` entries are constrained to `B_direct`, and truth
inclusion is checked by one-df LR against `qchisq(0.95, 1) = 3.84145882069`.
This is a descriptive realized target, not population `B_lv = Lambda * alpha'`
coverage.

## Files Changed

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-realized-direct-slope-ademp.md`
  - added K = 1 five-seed and task-8 entry-71 diagnostic results.
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md`
  - recorded positive evidence for the changed target.
- `docs/design/73-predictor-informed-latent-scores.md` - updated the honest
  scope note for the direct-slope canaries.
- `docs/dev-log/check-log.md` - recorded commands, output paths, denominators,
  and LR values.
- `gllvmTMB/docs/dev-log/dashboard/status.json` and `sweep.json` - refreshed
  local Mission Control source.

## Tests Added

No package tests were added. This slice runs local bench diagnostics only and
does not alter exported API, likelihood code, or package behavior.

## Benchmark Numbers

K = 1 five-seed canary:

- fits converged: `5/5`;
- usable selected entries: `25/25`;
- truth included: `25/25`;
- max LR: `3.65953749216 < 3.84145882069`;
- mean fit seconds: `4.193`;
- mean CI seconds: `8.042`;
- output: `/tmp/phylo_xlv_direct_slope_k1_5seed`.

Known failed-row canary:

- task: `8`, seed `202614420856`;
- entry: `71`, `B_lv[71,1]`;
- fit converged: `true`, `235` iterations;
- estimate: `-0.212294346248`;
- direct-slope target: `-0.220447386197`;
- LR: `0.00569099997301 < 3.84145882069`;
- output: `/tmp/phylo_xlv_direct_slope_task8_entry71_20260701`.

## R-Parity Verdict

Parity: N/A - this is Julia bench diagnostic evidence and does not touch R
grammar or the R bridge.

## JET / Allocs / Aqua Verdicts

- JET: not run - no package hot-path code changed in this slice.
- Allocs: not run - no package hot-path code changed in this slice.
- Aqua: not run - no dependencies, exports, or metadata changed.

## Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_direct_slope_k1_5seed/meta/params.csv --reps 5 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260702
for task in 1 2 3 4 5; do
  julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_direct_slope_k1_5seed/meta/params.csv --outdir /tmp/phylo_xlv_direct_slope_k1_5seed/results --task-id "$task" --methods profile_direct_slope --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
done
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_direct_slope_k1_5seed/results
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_params_20260630/phylo_xlv_params.csv --outdir /tmp/phylo_xlv_direct_slope_task8_entry71_20260701/results --task-id 8 --methods profile_direct_slope --targets B_lv --b-lv-entries 71 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_direct_slope_task8_entry71_20260701/results
julia --project=. test/test_phylo_xlv.jl
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
sh /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/tools/start-mission-control.sh --background
```

Result: K = 1 summary reported `25/25`; task-8 entry-71 summary reported
`1/1`, `ci_status = ok`. Focused package check `phylo x X_lv (Model A)`
passed `25/25` in `1m05.9s`. Mission Control served `version.txt` as `r60`
and showed the `Direct-slope local canaries` row at `2026-06-30 23:10 MDT`.

## Consistency Audit

The updated docs and dashboard deliberately retain blocked public scope. Current
wording says positive local realized-target canaries, no source-specific phylo
`lv` grammar, no bootstrap rescue, no production compute, and no population
`B_lv` recovery claim.

## GitHub Issue Maintenance

No GitHub action. PR #127 remains closed/parked; no push, PR reopen, or grammar
exposure was authorized.

## What Did Not Go Smoothly

The strongest K = 1 direct-slope row is close to the cutoff
(`3.6595 < 3.8415`). The route is promising, not settled.

## Team Learning

Curie should predeclare the next diagnostic denominator before any more local
or Totoro work, because a descriptive target can otherwise drift into an
overclaim.

## Remaining Risks

- The direct-slope target has only local diagnostic evidence, not calibrated
  support evidence.
- K = 1 five-seed coverage has no useful promotion-grade MCSE.
- The task-8 pass is one sentinel row, not a p = 80, K = 2 wave.
- Public source-specific phylo `lv` grammar remains blocked.

## Known Limitations

This does not finish phylo Model A support. It proves the changed target is
worth the next predeclared diagnostic wave.

## Next Command

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_direct_slope_k1_20rep/meta/params.csv --reps 20 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260702
```

Run only after explicitly choosing this denominator over a p = 80, K = 2
selected-row diagnostic.

## Rose Verdict

Rose verdict: PASS WITH NOTES - realized direct-slope local canaries are
positive and coherently documented, but public phylo Model A support remains
blocked pending a predeclared diagnostic wave.
