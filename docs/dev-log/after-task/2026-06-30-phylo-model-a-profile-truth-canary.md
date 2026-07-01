# After Task: Phylo Model A profile-truth canary

## Goal

Test whether a cheaper profile-LR truth-inclusion canary can rescue the
p = 80, K = 2, lambda = 0.5 phylo Model A `B_lv` weak cell without bootstrap,
source-specific grammar exposure, or broad compute.

## Implemented

Added a bench-only `profile_truth` method to `bench/phylo_xlv_drac_task.jl`.
For selected `vec(B_lv)` entries, it fits the model, constrains the selected
trait/loading effect to the known simulation truth, optimizes the remaining
parameters, and records the one-df LR deviance and chi-square cutoff. The row is
not treated as an endpoint CI, and nonconverged constrained solves are not
usable evidence. `bench/phylo_xlv_drac_submit.sh` now documents
`profile_truth` as an allowed diagnostic method.

## Mathematical Contract

For a selected rotation-invariant `B_lv` entry, the canary tests whether
`2 * (nll_constrained(B_lv = truth) - nll_mle) <= quantile(Chisq(1), level)`.
This is the truth-inclusion decision for a one-df profile-LR interval. Raw
`alpha_lv` remains an axis/access-effect point quantity; Wald output is
acceptable for that ordinary/default side, but it is not the phylo Model A
claim gate.

## Files Changed

- `bench/phylo_xlv_drac_task.jl`
- `bench/phylo_xlv_drac_submit.sh`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-model-a-profile-truth-canary.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

## Tests Added

No package test file was added. This is bench-runner instrumentation. The
diagnostic path was exercised end-to-end by a tiny local smoke and by the
seed-matched task-8 entry-71 local canary. Existing focused phylo Model A tests
still cover the public/internal Model A likelihood and selected profile helper.

## Benchmark Numbers

Tiny smoke, p = 5, n_sites = 60, K = 1, lambda = 0.5, selected entries `2,4`:
two usable profile_truth entries, both covered, `ci_status = ok`.

Weak-cell local diagnostic, task 8 entry 71, seed `202614420856`:
`fit_converged = true`, `fit_iterations = 235`, `fit_seconds = 125.1365`,
`ci_seconds = 59.4776`, `lr_deviance = 9.99181181962`,
`lr_cutoff = 3.84145882069`, `usable = 1`, `covered = 0`,
`coverage = 0`, `ci_status = ok`.

## R-Parity Verdict

Parity: N/A. This is Julia-side diagnostic instrumentation for an already
blocked phylo Model A canary, not R bridge or gllvmTMB grammar exposure.

## JET / Allocs / Aqua Verdicts

- JET: not run; no exported package path or hot likelihood kernel changed.
- Allocs: not run; this is expensive diagnostic optimization, not an inner-loop
  performance claim.
- Aqua: not run; no dependencies, exports, or package hygiene files changed.

## Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
bash -n bench/phylo_xlv_drac_submit.sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_profile_truth_smoke/meta/params.csv --reps 1 --lambdas 0.5 --n-species 5 --n-sites 60 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_profile_truth_smoke/meta/params.csv --outdir /tmp/phylo_xlv_profile_truth_smoke/results --task-id 1 --methods profile_truth --targets B_lv --b-lv-entries 2,4 --profile-opt-iterations 80 --iterations 250 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_profile_truth_smoke/results
julia --project=. test/test_phylo_xlv.jl
git diff --check -- bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_params_20260630/phylo_xlv_params.csv --outdir /tmp/phylo_xlv_profile_truth_task8_entry71_local_20260701/results --task-id 8 --methods profile_truth --targets B_lv --b-lv-entries 71 --profile-opt-iterations 80 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_params_20260630/phylo_xlv_params.csv --outdir /tmp/phylo_xlv_profile_truth_task8_entry71_local_250_20260701/results --task-id 8 --methods profile_truth --targets B_lv --b-lv-entries 71 --profile-opt-iterations 250 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_profile_truth_task8_entry71_local_250_20260701/results
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
```

Results:

- task help parsed and advertises `profile_truth`;
- submitter syntax passed;
- tiny smoke wrote a `profile_truth` row with two usable entries and
  `ci_status = ok`;
- focused phylo Model A tests passed: `25/25` in `1m03.5s`;
- 80-iteration weak-cell constrained solve was correctly nonusable:
  `profile_truth_underconverged`;
- 250-iteration weak-cell constrained solve converged and missed truth:
  `9.9918 > 3.8415`;
- dashboard JSON parsed and `git diff --check` passed.

## Consistency Audit

Searched Mission Control sources for stale active-profile language:

```sh
rg -n "running|active capped|active compute|64471433|pending canary|profile-LR evidence exists|profile_truth|9\\.9918|3\\.8415" docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
```

Remaining `64471433` mentions now say the job is unread due to Narval
login/status stalls, not active evidence. Dashboard text says blocked after the
profile_truth miss.

## GitHub Issue Maintenance

No PR was opened, reopened, pushed, or commented. GLLVM.jl PR #127 remains
closed/parked as blocked evidence.

## What Did Not Go Smoothly

Narval status reads stalled, including plain scheduler/login checks, so I did
not use DRAC for a new claim row. The local 80-iteration constrained truth solve
also did not converge, which confirmed that the profile engine itself is a
structural dependency. Increasing the cap to 250 gave a converged negative
result.

## Team Learning

Fisher and Curie should prefer LR truth-inclusion decisions before endpoint
inversion, but Rose should require a pass/fail row to be labeled as a canary,
not a CI.

## Remaining Risks

- The decisive negative profile_truth result is local seed-matched diagnostic
  evidence, not a completed DRAC row.
- Narval job `64471433` remains unread due to login/status stalls in this turn.
- No full `Pkg.test()` or `julia --project=. test/runtests.jl` completion was
  obtained in this slice.
- Phylo Model A still needs a structural redesign, narrower supported regime, or
  v1 retirement decision before any source-specific `lv` exposure.

## Known Limitations

`profile_truth` is bench-only instrumentation. It does not return CI endpoints,
does not modify `confint_lv_effects()`, does not expose R grammar, and does not
make `alpha_lv` intervals rotation-invariant.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && rg -n "profile_truth|9\\.9918|source-specific phylo lv|partial support|active compute" docs/dev-log bench
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — the negative profile_truth canary is recorded
and Mission Control no longer claims active compute, but phylo Model A remains
blocked pending structural redesign, narrower regime, or v1 retirement.
