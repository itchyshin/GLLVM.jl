# After Task: Phylo Model A Direct-Slope Canary Tooling

## Goal

Add a bench-only realized direct-slope profile canary for phylo Model A and
refresh the planning/dashboard record without widening API, grammar, likelihood,
or compute scope.

## Implemented

The bench runner now accepts `profile_direct_slope` for selected `B_lv` entries.
It computes a saturated per-trait `Y ~ X_lv` direct-slope target, profiles the
fitted Model A `B_lv` product against that realized target, and labels results
as `B_lv_direct_slope`. A tiny local smoke at `p = 5`, `n_sites = 60`,
`K = 1`, `lambda = 0.5` passed `2/2` selected entries. This is diagnostic
tooling only; public source-specific phylo `lv` remains blocked.

## Mathematical Contract

For each simulated replicate:

```text
D = [1  X_lv]
Gamma_direct = D \ Y'
B_direct[t, c] = Gamma_direct[c + 1, t]
```

The canary checks whether the fitted structured Model A likelihood includes
the realized descriptive target by testing
`2 * (nll_constrained(B_lv = B_direct) - nll_mle) <= qchisq(0.95, 1)` for
preselected entries. This target is sampling-conditional; it is not population
`B_lv = Lambda * alpha_lv'` coverage.

## Files Changed

- `bench/phylo_xlv_drac_task.jl` - added `profile_direct_slope`, direct-slope
  target computation, target-specific detail labels, and help text.
- `bench/phylo_xlv_drac_submit.sh` - documented the bench method in launcher
  help.
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-realized-direct-slope-ademp.md`
  - new ADEMP/Williams diagnostic gate note.
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md`
  - linked the realized-target canary.
- `docs/design/73-predictor-informed-latent-scores.md` - aligned alpha/B_lv
  boundary and canary wording.
- `docs/dev-log/check-log.md` - recorded smoke, focused test, and dashboard
  refresh checks.
- `gllvmTMB/docs/dev-log/dashboard/status.json` and `sweep.json` - local
  Mission Control refresh only.

## Tests Added

No package tests were added because this slice is bench-only diagnostic tooling
with no exported API or likelihood change. The test-of-tests clause is satisfied
by the smoke comparing the profiled target to an independent saturated
calculation, plus the existing focused phylo suite remaining green.

## Benchmark Numbers

Tiny local smoke:

- fit converged: `true`, `25` iterations, `3.15259099007` seconds;
- canary/profile time: `3.30630111694` seconds;
- selected entries: `2/2` usable, `2/2` covered;
- LR values: `0.0895416648327`, `1.60222512548`;
- LR cutoff: `3.84145882069`.

No hot-path benchmark was run because the package likelihood/fitter code was
not changed.

## R-Parity Verdict

Parity: N/A - this is a Julia bench-runner diagnostic target and does not touch
the R bridge, R grammar, Gaussian marginal likelihood, or package CI surface.

## JET / Allocs / Aqua Verdicts

- JET: not run - no `src/` or package hot-path change.
- Allocs: not run - no package hot-path change.
- Aqua: not run - no dependencies, exports, or package metadata changed.

## Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
```

Result: help advertises `profile_direct_slope`.

```sh
bash -n bench/phylo_xlv_drac_submit.sh
```

Result: `submitter-syntax-ok`.

```sh
rm -rf /tmp/phylo_xlv_direct_slope_smoke
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_direct_slope_smoke/meta/params.csv --reps 1 --lambdas 0.5 --n-species 5 --n-sites 60 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260702
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_direct_slope_smoke/meta/params.csv --outdir /tmp/phylo_xlv_direct_slope_smoke/results --task-id 1 --methods profile_direct_slope --targets B_lv --b-lv-entries 2,4 --profile-opt-iterations 80 --iterations 250 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_direct_slope_smoke/results
```

Result: `B_lv_direct_slope`, `profile_direct_slope`, `2/2` usable and covered,
`ci_status = ok`.

```sh
julia --project=. test/test_phylo_xlv.jl
```

Result: `phylo x X_lv (Model A)` passed `25/25` in `1m03.7s`.

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/version.txt
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "22:54|profile_direct_slope|Direct-slope|blocked_no_active_compute|B_lv_direct_slope"
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool | rg -n "22:54|profile_direct_slope|Direct-slope|B_lv_direct_slope"
```

Result: JSON valid, whitespace clean, Mission Control served `version.txt` as
`r60`, and served JSON shows the direct-slope smoke plus no active compute.

## Consistency Audit

Patterns used:

```sh
rg -n "partial support|ready|source-specific .*lv|phylo_latent\(.*lv|profile_direct_slope|B_lv_direct_slope|bootstrap rescue|active compute|production compute" docs/dev-log/decisions docs/design docs/dev-log/check-log.md bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh
rg -n "do not report SEs|alpha Wald|conditional alpha|axis/access" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions docs/dev-log/check-log.md
```

Verdict: current planning docs use the intended guard language. Historical
check-log lines remain historical evidence. The only stale alpha wording found
in Design 73 was updated to say Wald is acceptable as conditional axis/access
display, not as the phylo Model A evidence target.

## GitHub Issue Maintenance

No issue action. PR #127 remains closed/parked as blocked evidence, and no
push or PR reopen was authorized.

## What Did Not Go Smoothly

The old route remains genuinely negative: `bootstrap_basic` cannot reach the
gate, `profile_truth` missed task 8 entry 71, and the K = 1 diagnostic wave
missed two converged selected entries. The new `profile_direct_slope` path is
therefore a redesign canary, not a rescue claim.

## Team Learning

Fisher and Curie should keep the target definition first-class: if the target
changes from population `B_lv` to realized direct slope, the ADEMP gate must be
rewritten before any scale-up.

## Remaining Risks

- `profile_direct_slope` has only a tiny `2/2` smoke, not a promotion-grade
  diagnostic wave.
- `B_lv_direct_slope` is descriptive and sampling-conditional; it cannot be
  advertised as population `B_lv` recovery.
- No source-specific R grammar, PR reopen, Totoro/DRAC claim job, or production
  sweep is authorized by this slice.

## Known Limitations

This does not finish public phylo Model A support. It adds the next defensible
canary target and refreshes Mission Control so the decision is visible.

## Next Command

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_direct_slope_k1_5seed/meta/params.csv --reps 5 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260702
```

Only run this if Shinichi authorizes the realized direct-slope route; otherwise
retire public source-specific phylo `lv` from v1.

## Rose Verdict

Rose verdict: PASS WITH NOTES - bench-only direct-slope canary tooling and
Mission Control refresh are coherent, but phylo Model A public support remains
blocked pending a predeclared realized-target gate or v1 retirement.
