# After Task: Ordinary Gamma LV Profile Gate

## Goal

Extend ordinary non-Gaussian selected-entry `B_lv` profile-LR route evidence
from Poisson, Binomial logit, and NB2 to Gamma before opening any
structural-source gate.

## Implemented

Added a Gamma Gate 1 canary to `test/test_lv_ci.jl` and updated the ordinary
non-Gaussian LV ADEMP note. The canary fits
`fit_gamma_gllvm(...; X_lv=...)`, profiles one selected `B_lv` entry, checks
finite profile endpoints, brackets the MLE, includes the known DGP truth, and
verifies the fitted shape remains in a non-degenerate positive-continuous range.

## Mathematical Contract

The interval target remains the rotation-stable ordinary trait/loading effect
`B_lv = Lambda * alpha_lv'`. For selected entry `idx`, the profile interval
inverts `D(c) = 2 * (NLL_constrained(B_lv[idx] = c) - NLL_hat)` against the
chi-square(1) cutoff, re-optimising nuisance parameters at each candidate.
Gamma adds the shape parameter `alpha`; the canary checks that this nuisance
component remains finite and away from a near-deterministic limit.

## Files Changed

- `test/test_lv_ci.jl` - Gamma selected-entry profile canary.
- `docs/dev-log/decisions/2026-07-02-nongaussian-ordinary-lv-profile-ademp.md`
  - Gate 0 note now names Poisson, Binomial logit, NB2, and Gamma canaries.
- `docs/dev-log/check-log.md` - command log and claim boundary.
- `docs/dev-log/after-task/2026-07-02-nongaussian-gamma-lv-profile-gate.md`
  - this report.
- External dashboard refresh in gllvmTMB:
  `docs/dev-log/dashboard/status.json`, `docs/dev-log/dashboard/sweep.json`.

## Tests Added

- Gamma selected-entry profile canary: verifies public `confint_lv_effects`
  profile routing for one ordinary Gamma `B_lv` entry.
- Shape guard: checks the fitted Gamma shape remains between `0.5` and `10.0`
  in the canary.

## Benchmark Numbers

N/A - no likelihood hot path or optimizer implementation changed. Exploratory
Gamma smoke found the successful canary cell at about 5.07 seconds for the
point fit and 14.87 seconds for the selected-entry profile after compilation.
The focused `test/test_lv_ci.jl` file completed in 3m39.1s.

## R-Parity Verdict

Parity: N/A - this is native GLLVM.jl route evidence. R bridge
profile/bootstrap transport remains blocked.

## JET / Allocs / Aqua Verdicts

- JET: not run - no type or hot-path implementation changed.
- Allocs: not run - no allocation-targeted code changed.
- Aqua: not run - no dependency/export/project metadata changed.

## Checks Run

```text
julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 171 passed, 0 failed, 0 errored, 3m39.1s
```

Mission Control checks were run after the dashboard source refresh:

```text
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

## Consistency Audit

Task-specific claim audit:

```sh
rg -n "partial support|ready to expose|bootstrap rescue|source-specific.*support|mixed-family CI|unique=.*parity|R bridge profile transport|coverage calibration" README.md docs/src docs/dev-log/decisions docs/dev-log/after-task src test
rg -n "Poisson, Binomial logit, NB2, and Gamma|171/171|No LV compute|coverage calibration|source-specific lv support|unique= parity" docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
```

Expected hits are historical and current guard wording only.

## GitHub Issue Maintenance

No issue or PR action. PR #127 remains closed/parked; no push or PR reopen was
attempted.

## What Did Not Go Smoothly

No failure in the banked Gamma cell. The focused LV CI file is getting heavier
as selected-entry GLM profile canaries accumulate, but the final runtime stayed
within a focused-test envelope at 3m39.1s.

## Team Learning

Curie/Fisher rule: positive-continuous families need their own likelihood proof
even when the selected-entry profile machinery is shared. A Gamma canary should
show finite endpoints and a sensible fitted shape, not only a generic `B_lv`
interval.

## Remaining Risks

- This is not coverage calibration.
- Ordinary Beta still needs its own selected-entry profile gate before any broad
  one-part non-Gaussian claim.
- R bridge profile/bootstrap transport remains blocked.
- Source-specific structural LV remains blocked behind separate derivation,
  tests, and Rose audit.
- The separate `unique=` lane remains R/TMB-first and non-blocking for this
  ordinary inference slice.

## Known Limitations

- `profile_indices` remains the practical route for GLM profile; profiling all
  entries is expensive.
- `alpha_lv` is not the interval target.
- No source-specific `lv = ~ env`, mixed-family `X_lv`, masks, missing
  responses, or Julia `unique=` parity was added.

## Next Command

```sh
git diff --check
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - Gate 1 route evidence is locally covered for
ordinary Gamma selected-entry `B_lv`; coverage calibration, Beta, and all
structural-source claims remain gated.
