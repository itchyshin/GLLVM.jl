# After Task: Ordinary Binomial LV Profile Gate

## Goal

Extend ordinary non-Gaussian selected-entry `B_lv` profile-LR route evidence
from Poisson to Binomial logit before opening any structural-source gate.

## Implemented

Added a Binomial logit Gate 1 canary to `test/test_lv_ci.jl` and updated the
Gate 0 ADEMP note so it now records Poisson plus Binomial logit local canaries.
The Binomial canary fits `fit_binomial_gllvm(...; X_lv=..., N=...)`, profiles
one selected `B_lv` entry, and checks finite endpoints, MLE bracketing, and
known DGP truth inclusion.

## Mathematical Contract

The interval target remains the rotation-stable ordinary trait/loading effect
`B_lv = Lambda * alpha_lv'`. For selected entry `idx`, the profile interval
inverts `D(c) = 2 * (NLL_constrained(B_lv[idx] = c) - NLL_hat)` against the
chi-square(1) cutoff, re-optimising nuisance parameters at each candidate.
Binomial trial counts are part of the likelihood and are threaded through the
profile call via `N`.

## Files Changed

- `test/test_lv_ci.jl` - Binomial logit selected-entry profile canary.
- `docs/dev-log/decisions/2026-07-02-nongaussian-ordinary-lv-profile-ademp.md`
  - Gate 0 note now names Poisson and Binomial logit canaries.
- `docs/dev-log/check-log.md` - command log and claim boundary.
- `docs/dev-log/after-task/2026-07-02-nongaussian-binomial-lv-profile-gate.md`
  - this report.
- External dashboard refresh in gllvmTMB:
  `docs/dev-log/dashboard/status.json`, `docs/dev-log/dashboard/sweep.json`.

## Tests Added

- Binomial logit selected-entry profile canary: verifies public
  `confint_lv_effects` profile routing for one ordinary Binomial `B_lv` entry
  with trial counts.
- Tests-of-tests clause: the test combines selected-entry profile with the
  neighbouring ordinary Binomial `X_lv` fit and checks an independent DGP truth
  value.

## Benchmark Numbers

N/A - no likelihood hot path or optimizer implementation changed. Exploratory
smoke timing for the Binomial canary was 17.583830 seconds in a one-off Julia
run; the focused full `test/test_lv_ci.jl` file completed in 3m17.3s.

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
X_lv Wald CIs - confint_lv_effects: 153 passed, 0 failed, 0 errored, 3m17.3s

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
rg -n "Ordinary non-Gaussian LV profile|Poisson and Binomial|153/153|coverage calibration|source-specific lv support|unique= parity" docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
```

Returned historical and current guard wording only. The dashboard hits state
that Poisson and Binomial logit Gate 0/1 evidence is not coverage calibration,
not R bridge profile/bootstrap transport, not source-specific support, and not
`unique=` parity. Served JSON at `http://127.0.0.1:8770/` validates and still
reports `version.txt` as `r60`.

## GitHub Issue Maintenance

No issue or PR action. PR #127 remains closed/parked; no push or PR reopen was
attempted.

## What Did Not Go Smoothly

The focused file is now slightly heavier because it includes two derivative-free
non-Gaussian profile canaries. The total remained focused-test scale at 3m17.3s,
so the canary stays in the default LV CI file for now.

## Team Learning

Hopper/Fisher rule: Binomial profile evidence must thread `N` explicitly; a
profile route that works without trial-count propagation would be the wrong
proof.

## Remaining Risks

- This is not coverage calibration.
- Only ordinary Poisson and Binomial logit have selected-entry profile canaries;
  NB2, Gamma, and Beta still need their own gates before any broad
  non-Gaussian claim.
- R bridge profile/bootstrap transport remains blocked.
- Source-specific structural LV remains blocked behind separate derivation,
  tests, and Rose audit.
- The separate `unique=` lane remains R/TMB-first and non-blocking.

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
ordinary Binomial logit selected-entry `B_lv`; coverage calibration, remaining
families, and all structural-source claims remain gated.
