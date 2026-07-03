# After Task: Ordinary Non-Gaussian LV Profile Gate

## Goal

Begin the non-Gaussian LV inference arc by proving the ordinary selected-entry
`B_lv` profile-LR route before any structural-source gate or compute launch.

## Implemented

Added a Gate 0 ADEMP decision note and a local Gate 1 Poisson canary. The canary
fits an ordinary `fit_poisson_gllvm(...; X_lv=...)`, profiles one selected entry
with `confint_lv_effects(...; method = :profile, profile_indices = [1])`, and
checks finite endpoints, MLE bracketing, and known DGP truth inclusion.

## Mathematical Contract

The interval target is the rotation-stable ordinary trait/loading effect
`B_lv = Lambda * alpha_lv'`. For a selected entry `idx`, the profile interval
inverts `D(c) = 2 * (NLL_constrained(B_lv[idx] = c) - NLL_hat)` against the
chi-square(1) cutoff, re-optimising nuisance parameters at each candidate.
Raw `alpha_lv` remains an axis/access-effect component, not the interval target.

## Files Changed

- `test/test_lv_ci.jl` - ordinary Poisson selected-entry profile canary.
- `docs/dev-log/decisions/2026-07-02-nongaussian-ordinary-lv-profile-ademp.md`
  - Gate 0 ADEMP note and gate ladder.
- `docs/dev-log/check-log.md` - command log and claim boundary.
- `docs/dev-log/after-task/2026-07-02-nongaussian-ordinary-lv-profile-gate.md`
  - this report.
- External dashboard refresh in gllvmTMB:
  `docs/dev-log/dashboard/status.json`, `docs/dev-log/dashboard/sweep.json`.

## Tests Added

- Poisson selected-entry profile canary: verifies public `confint_lv_effects`
  profile routing for one non-Gaussian ordinary `B_lv` entry against a known DGP
  truth.
- Tests-of-tests clause: the test combines the selected-entry profile feature
  with the neighbouring ordinary Poisson `X_lv` fit and checks an independent
  DGP truth value, not only shape.

## Benchmark Numbers

N/A - no likelihood hot path or optimizer implementation changed. Exploratory
smoke timing for the canary was 11.400565 seconds in a one-off Julia run; the
focused full `test/test_lv_ci.jl` file completed in 3m02.2s.

## R-Parity Verdict

Parity: N/A - this is native GLLVM.jl route evidence. R bridge profile/bootstrap
transport remains blocked.

## JET / Allocs / Aqua Verdicts

- JET: not run - no type or hot-path implementation changed.
- Allocs: not run - no allocation-targeted code changed.
- Aqua: not run - no dependency/export/project metadata changed.

## Checks Run

```text
julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 146 passed, 0 failed, 0 errored, 3m02.2s

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60

curl -s http://127.0.0.1:8770/status.json | rg -n "Ordinary non-Gaussian LV profile|Gate 0/1|146/146|No LV compute|unique= lane"
served status includes the new Gate 0/1 row and no-active-compute wording.
```

## Consistency Audit

Task-specific claim audit:

```sh
rg -n "partial support|ready to expose|bootstrap rescue|source-specific.*support|mixed-family CI|unique=.*parity|R bridge profile transport|coverage calibration" README.md docs/src docs/dev-log/decisions docs/dev-log/after-task src test
rg -n "Ordinary non-Gaussian LV profile|Gate 0/1|146/146|coverage calibration|source-specific lv support|unique= parity" docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
```

Returned historical and current guard wording only. The new hits in this slice
state that ordinary Poisson selected-entry profile is not coverage calibration,
not R bridge profile transport, not source-specific support, and not `unique=`
parity. Served `status.json` contains the same new row used by the local preview
at `http://127.0.0.1:8770/`.

## GitHub Issue Maintenance

No issue or PR action. PR #127 remains closed/parked; no push or PR reopen was
attempted.

## What Did Not Go Smoothly

The first exploratory canary was intentionally run before editing to confirm
cost and stability. It was finite and local-test scale, so it stayed in the
focused default test rather than being hidden behind the slow-test gate.

## Team Learning

Curie/Fisher rule for this arc: one selected-entry ordinary non-Gaussian profile
canary is route evidence only; coverage calibration needs a predeclared Gate 2
denominator and MCSE.

## Remaining Risks

- This is not coverage calibration.
- Only ordinary Poisson was canaried; Binomial, NB2, Gamma, and Beta still need
  their own gates before any broad non-Gaussian claim.
- R bridge profile/bootstrap transport remains blocked.
- Source-specific structural LV remains blocked behind separate derivation,
  tests, and Rose audit.
- The separate `unique=` lane remains R/TMB-first and non-blocking.

## Known Limitations

- `profile_indices` is still the practical route for GLM profile; profiling all
  entries is expensive.
- `alpha_lv` is not the interval target.
- No source-specific `lv = ~ env`, mixed-family `X_lv`, masks, missing
  responses, or Julia `unique=` parity was added.

## Next Command

```sh
git diff --check
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - Gate 0/1 route evidence is locally covered for
ordinary Poisson selected-entry `B_lv`; coverage calibration and all
structural-source claims remain gated.
