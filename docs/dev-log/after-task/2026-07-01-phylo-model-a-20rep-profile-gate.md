# After Task: Phylo Model A 20-replicate profile gate

## Goal

Run the small K = 1 `profile_truth` diagnostic gate that the 5-seed scout
justified, then decide whether profile-LR can move toward claim evidence.

## Implemented

Ran a local 20-replicate selected-entry diagnostic wave for Gaussian phylo Model
A with `K = 1`, `q_lv = 1`, `n_species = 20`, `n_sites = 200`, lambda `0.5`,
and entries `1,5,10,15,20`. No bootstrap, endpoint interval fan-out, package
API, R grammar, or production compute changed.

## Mathematical Contract

The tested target was the population induced trait/loading effect:

```text
B_lv[t, 1] = Lambda[t, 1] * alpha_lv[1, 1]
```

The canary criterion was the one-df profile-LR truth-inclusion diagnostic:

```text
2 * (nll_constrained(B_lv = truth) - nll_mle) <= qchisq(0.95, 1)
```

`alpha_lv` remains conditional axis/access-effect output only; Wald is fine for
that display, but it is not the rotation-invariant source-specific phylo Model A
claim.

## Files Changed

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-narrowed-regime-gate.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/dev-log/decisions/2026-06-30-phylo-model-a-council-final.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-phylo-model-a-20rep-profile-gate.md`
- `docs/dev-log/after-task/2026-07-01-phylo-model-a-structural-dependencies.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

## Tests Added

None. This was a diagnostic run plus documentation/status update.

## Benchmark Numbers

The diagnostic wave ran from
`/tmp/phylo_model_a_k1_diag20_20260630_220930`:

```text
fits converged:              20/20
selected entries usable:     100/100
selected entries covered:    98/100
mean task coverage (MCSE):   0.980 (0.014)
entry coverage:              0.980
LR range:                    2.65627995759e-05 to 5.14288022148
LR cutoff:                   3.84145882069
mean selected-entry LR:      0.630993528174
fit sec mean:                3.954
selected-entry CI sec mean:  5.616
```

The two misses were usable, `ci_status = ok`, and converged:

```text
task 15 rep 15 seed 35421008 entry 10 B_lv[10,1]:
  estimate -0.461291546426, truth -0.355095269986, LR 4.94199940694

task 19 rep 19 seed 39461048 entry 20 B_lv[20,1]:
  estimate -0.234136406101, truth -0.171615120502, LR 5.14288022148
```

## R-Parity Verdict

Parity: N/A - no R bridge, likelihood, fitter, init, or CI implementation
changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia source changed in this slice.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata, exports, or dependencies changed.

## Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_model_a_k1_diag20_20260630_220930/meta/params.csv --reps 20 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag20_20260630_220930/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag20_20260630_220930/results --task-id 1 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
# repeated for task-id 2:20 with the same selected-entry diagnostic settings
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_model_a_k1_diag20_20260630_220930/results
julia --project=. test/test_phylo_xlv.jl
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
```

Focused phylo Model A tests passed `25/25` in `1m06.0s`. Mission Control served
JSON updated to `2026-06-30 22:15 MDT` with `active = 0`, `queued = 0`, and
`blocked = 5`.

Follow-up closure: Design 73 and the council-final decision now include the
K = 1 20-replicate stop-rule result. This prevents the old weak-cell failure
from silently becoming a same-route K = 1 scale-up plan.

## Consistency Audit

The 20-replicate gate fired the stop rule. The docs and Mission Control should
now say that K = 1 same-route profile scaling is stopped, not queued.

## GitHub Issue Maintenance

No GitHub action was taken. PR #127 remains closed/parked as blocked evidence.

## What Did Not Go Smoothly

The five-seed wave was too optimistic. The 20-replicate wave found two converged
truth-inclusion misses, which is exactly why the diagnostic gate existed.

## Team Learning

Fisher and Curie should require zero converged selected-entry misses before any
promotion-grade profile-LR interval run. Grace should keep Totoro/DRAC out of
this route until a genuinely different target or regime is named.

## Remaining Risks

- The point likelihood plumbing is still useful, but source-specific phylo `lv`
  interval support is not validated.
- K = 2 remains failed under the old target.
- K = 1 now fails the local 20-replicate selected-entry gate.
- A realized/sampling-conditional target may be possible, but it would be a
  different scientific claim and needs a fresh ADEMP note.

## Known Limitations

This does not produce DRAC claim evidence, does not expose public grammar, and
does not validate endpoint profile intervals. It also does not choose a future
structural redesign; that remains a maintainer/science decision.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && rg -n "20-replicate|K = 1|partial support|source-specific.*unblock|ready to scale" docs/dev-log docs/design /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard
```

## Rose Verdict

Rose verdict: BLOCKED - the 20-replicate diagnostic gate has real converged
misses. Do not call source-specific phylo `lv` partially supported, do not scale
K = 1 profile runs, and do not restart bootstrap.
