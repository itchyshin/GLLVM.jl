# After Task: Phylo Model A Direct-Slope 20-Rep Gate

## Goal

Run the K = 1 20-replicate realized direct-slope diagnostic wave and decide
whether it clears the strict local promotion canary.

## Implemented

No package code was changed in this slice. I ran the local
`profile_direct_slope` K = 1, p = 20, n_sites = 200 diagnostic with selected
entries `1,5,10,15,20` across 20 seeds. The aggregate result was `96/100`
truth-included with all fits converged, but four converged selected entries
missed the one-df LR cutoff. Under the predeclared no-miss stop rule, the
realized-target route is not promoted.

## Mathematical Contract

For each replicate:

```text
D = [1  X_lv]
Gamma_direct = D \ Y'
B_direct[t, c] = Gamma_direct[c + 1, t]
```

Selected fitted `B_lv` entries are constrained to the realized
`B_lv_direct_slope` target and checked with
`2 * (nll_constrained - nll_mle) <= 3.84145882069`. This is a descriptive
realized target, not population `B_lv` coverage.

## Files Changed

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-realized-direct-slope-ademp.md`
  - recorded the 20-replicate stop-rule result.
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md`
  - updated the structural fork verdict.
- `docs/design/73-predictor-informed-latent-scores.md` - updated honest-scope
  wording.
- `docs/dev-log/check-log.md` - recorded commands, output path, misses, and
  interpretation.
- `gllvmTMB/docs/dev-log/dashboard/status.json` and `sweep.json` - refreshed
  local Mission Control source.

## Tests Added

No package tests were added; this was a bench diagnostic run and docs/dashboard
refresh only.

## Benchmark Numbers

```text
output: /tmp/phylo_xlv_direct_slope_k1_20rep_20260701
fits converged: 20/20
usable entries: 100/100
truth included: 96/100
coverage: 0.960
coverage MCSE: 0.0196
RMSE mean: 0.026
mean fit seconds: 4.176
mean CI seconds: 6.859
max LR: 6.66143949118
cutoff: 3.84145882069
```

Misses:

| task | rep | seed | entry | term | estimate | direct-slope target | LR |
| ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| 7 | 7 | 27340929 | 5 | `B_lv[5,1]` | -0.141132756958 | -0.0896177522692 | 5.65080204201 |
| 10 | 10 | 30370959 | 5 | `B_lv[5,1]` | -0.144284593088 | -0.0888739640536 | 6.66143949118 |
| 16 | 16 | 36431019 | 5 | `B_lv[5,1]` | -0.139598210616 | -0.0894642329239 | 5.43956667108 |
| 17 | 17 | 37441029 | 20 | `B_lv[20,1]` | -0.110154156887 | -0.0654424555058 | 5.62375223457 |

## R-Parity Verdict

Parity: N/A - local Julia bench diagnostic only; no R grammar, bridge, or
likelihood surface changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - no package hot-path code changed.
- Allocs: not run - no package hot-path code changed.
- Aqua: not run - no dependency, export, or metadata change.

## Checks Run

```sh
out=/tmp/phylo_xlv_direct_slope_k1_20rep_20260701
julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$out/meta/params.csv" --reps 20 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260702
seq 1 20 | xargs -I{} -P4 sh -c 'julia --project=. bench/phylo_xlv_drac_task.jl --params "$0/meta/params.csv" --outdir "$0/results" --task-id "$1" --methods profile_direct_slope --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force > "$0/logs/task_${1}.log" 2>&1' "$out" {}
julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$out/results"
julia --project=. test/test_phylo_xlv.jl
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
sh /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/tools/start-mission-control.sh --background
```

Result: `20/20` fits converged, `100/100` usable selected entries, `96/100`
truth-included, `ci_status = ok`. Focused package check
`phylo x X_lv (Model A)` passed `25/25` in `1m05.7s`. Mission Control served
`version.txt` as `r60` and showed the `Direct-slope 20-rep gate` row at
`2026-06-30 23:19 MDT`.

## Consistency Audit

The current docs and dashboard now say that aggregate coverage is compatible
with nominal 95% at this small denominator, but the strict no-miss canary failed
and source-specific phylo `lv` remains blocked.

## GitHub Issue Maintenance

No GitHub action. PR #127 remains closed/parked; no push, PR reopen, or grammar
exposure was authorized.

## What Did Not Go Smoothly

The early direct-slope canaries were promising, but the 20-replicate wave found
four converged misses. The misses concentrate in weaker direct targets
(`B_lv[5,1]`, `B_lv[20,1]`), so a future target/gate revision must be explicit
rather than post hoc.

## Team Learning

Fisher and Curie should decide whether the next defensible target is
magnitude-qualified realized slope or a larger nominal-coverage simulation
before any more compute.

## Remaining Risks

- The strict local canary failed, so public source-specific phylo `lv` support
  remains blocked.
- The aggregate `96/100` result is too small for a promotion-grade MCSE.
- A post hoc magnitude threshold would be overclaiming unless it is predeclared
  in a new ADEMP gate.

## Known Limitations

This does not finish phylo Model A support. It rules out promotion under the
current strict realized-target gate.

## Next Command

None for compute. Write a revised ADEMP gate first if Shinichi wants to pursue
a magnitude-qualified realized-slope target or a larger nominal-coverage study.

## Rose Verdict

Rose verdict: PASS WITH NOTES - the 20-rep direct-slope evidence is recorded
honestly and blocks public support under the strict canary; further work needs a
new predeclared gate, not more same-route reruns.
