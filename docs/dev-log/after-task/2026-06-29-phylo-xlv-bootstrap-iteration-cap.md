# After Task: phylo X_lv bootstrap-refit iteration cap

**Date**: `2026-06-29`
**Executed by**: Codex, live toolchain lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## 1. Goal

Make the phylo `X_lv` DRAC bootstrap rescue canary controllable after the
uncapped p=80,K=2,lambda=0.5 bootstrap-only task proved non-trivial and the
profile canary stayed in profile for more than an hour.

## 2. Implemented

- Added optional `bootstrap_iterations` to `confint_lv_effects(...; method =
  :bootstrap)`.
- Threaded the cap into bootstrap refits for Gaussian and GLM-family `X_lv`
  `B_lv` intervals.
- Preserved existing behavior when `bootstrap_iterations = nothing`.
- Added a fail-loud guard for non-positive `bootstrap_iterations`.
- Added `--bootstrap-iterations` to `bench/phylo_xlv_drac_task.jl`.
- Added `PHYLO_XLV_BOOT_ITERATIONS` to `bench/phylo_xlv_drac_submit.sh`,
  session metadata, and sbatch task invocation.
- Added a focused test that the non-default cap is accepted and invalid zero
  iterations are rejected.
- Recorded live canary status and the no-production/no-duplicate decision in
  `docs/dev-log/check-log.md`.

## 3a. Decisions and Rejected Alternatives

I did not launch a capped canary immediately after adding the knob. The current
uncapped Nibi bootstrap-only canary `16951694` is still running, and a duplicate
Nibi canary `16951692` had just been cancelled. Launching another job before
the active canary finishes would muddy the evidence ledger.

The cap defaults to `nothing` rather than changing the bootstrap default. This
keeps existing statistical behavior unchanged and makes cheaper refits an
explicit DRAC-canary choice.

## 4. Files Touched

- `src/confint_family.jl`
- `bench/phylo_xlv_drac_task.jl`
- `bench/phylo_xlv_drac_submit.sh`
- `test/test_lv_ci.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-06-29-162800-codex-phylo-xlv-live-rescue.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-bootstrap-iteration-cap.md`

The local mission-control widget was also updated out-of-repo under
`/tmp/gllvm-dashboard`.

## 5. Checks Run

```sh
bash -n bench/phylo_xlv_drac_submit.sh
julia --project=. test/test_lv_ci.jl
julia --project=. test/test_phylo_xlv.jl
git diff --check
```

Passed:

- `test/test_lv_ci.jl`: `127/127` in `2m56.3s`;
- `test/test_phylo_xlv.jl`: `19/19` in `59.0s`;
- shell syntax and whitespace checks clean.

```sh
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0.5 PHYLO_XLV_N_SPECIES=20 \
  PHYLO_XLV_N_SITES=20 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main \
  PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_METHODS=bootstrap PHYLO_XLV_N_BOOT=2 \
  bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_dry_empty
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0.5 PHYLO_XLV_N_SPECIES=20 \
  PHYLO_XLV_N_SITES=20 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main \
  PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_METHODS=bootstrap PHYLO_XLV_N_BOOT=2 \
  PHYLO_XLV_BOOT_ITERATIONS=5 \
  bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_dry_5
bash -n /tmp/phylo_xlv_submit_dry_empty/meta/phylo_xlv_array.sbatch
bash -n /tmp/phylo_xlv_submit_dry_5/meta/phylo_xlv_array.sbatch
```

Passed: write-only submit dry-runs generated one-task sbatch files with and
without the cap. The unset script has a false `if [[ -n "" ]]` guard; the set
script has `if [[ -n "5" ]]`. Both generated sbatch files are syntax-clean.

Live polls:

- Nibi `16951694_1`: running at `00:29:05`, still in bootstrap, `0` result
  files.
- Rorqual `14929297_1`: running at `01:12:52`, still in profile, `0` result
  files.

## 6. Tests of the Tests

The new test exercises the non-default keyword on a Gaussian K=2 bootstrap path
and checks that `bootstrap_iterations = 0` throws before refits. This would
fail if the keyword were not threaded into `_lv_bootstrap()` or if invalid caps
were silently ignored.

The submit dry-runs check that `PHYLO_XLV_BOOT_ITERATIONS` changes the generated
sbatch command only through the guarded bootstrap argument array.

## 7a. Issue Ledger

- Fixed: DRAC bootstrap canaries can now explicitly cap bootstrap refit
  iterations.
- Fixed: session metadata records the cap, avoiding hidden differences between
  canaries.
- Found: uncapped p=80,K=2 bootstrap is still running after the fit, so it is
  not a cheap immediate rescue.
- Deferred: no capped canary result exists yet.

## 8. Consistency Audit

The option was threaded through all local layers that need to agree:
`confint_lv_effects`, `_lv_bootstrap`, family-specific refit functions,
`bench/phylo_xlv_drac_task.jl`, `bench/phylo_xlv_drac_submit.sh`, task help,
session metadata, tests, and check-log.

The t-Wald and profile code paths were left unchanged. No public `gllvmTMB`
grammar or R bridge claim was changed.

## 9. What Did Not Go Smoothly

A duplicate bootstrap-only Nibi job, `16951692`, existed and was cancelled by
the live rescue checkpoint before this report. The active job is `16951694`.
The dashboard briefly showed the duplicate id; the board was corrected to the
active job id. Totoro is available for staging/coordination, but DRAC remains
the evidence source for these interval canaries.

## 10. Known Residuals

- Nibi `16951694` is still running the uncapped `n_boot=30` bootstrap-only
  canary.
- Rorqual `14929297` is still running the profile/bootstrap canary in the
  profile step.
- The new cap has local tests and parser validation, but no capped DRAC result
  yet.
- Full `Pkg.test()` was not rerun for this narrow harness change.

## 11. Team Learning

Fisher: interval-rescue methods need timing gates before coverage gates. For
p=80,K=2, profile and bootstrap are both real compute paths, not harmless
post-processing.

Grace: every rescue canary needs explicit metadata for `n_boot` and refit
iterations; otherwise later timing comparisons are ambiguous.

Rose: when duplicate compute appears, clean the job ledger first and only then
add the next knob or canary.
