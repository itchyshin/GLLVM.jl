# After Task: Ordinary NB2 LV Profile Gate

## Goal

Extend ordinary non-Gaussian selected-entry `B_lv` profile-LR route evidence
from Poisson and Binomial logit to NB2 before opening any structural-source
gate.

## Implemented

Added an NB2 Gate 1 canary to `test/test_lv_ci.jl` and updated the ordinary
non-Gaussian LV ADEMP note. The canary fits
`fit_nb_gllvm(...; X_lv=...)`, profiles one selected `B_lv` entry, checks finite
profile endpoints, brackets the MLE, includes the known DGP truth, and verifies
the fitted dispersion remains away from a Poisson-boundary collapse.

## Mathematical Contract

The interval target remains the rotation-stable ordinary trait/loading effect
`B_lv = Lambda * alpha_lv'`. For selected entry `idx`, the profile interval
inverts `D(c) = 2 * (NLL_constrained(B_lv[idx] = c) - NLL_hat)` against the
chi-square(1) cutoff, re-optimising nuisance parameters at each candidate. NB2
adds the shared dispersion `r`; the canary deliberately uses a dispersion-present
cell rather than a tiny cell where `r` races toward the Poisson limit.

## Files Changed

- `test/test_lv_ci.jl` - NB2 selected-entry profile canary.
- `docs/dev-log/decisions/2026-07-02-nongaussian-ordinary-lv-profile-ademp.md`
  - Gate 0 note now names Poisson, Binomial logit, and NB2 canaries.
- `docs/dev-log/check-log.md` - command log and claim boundary.
- `docs/dev-log/after-task/2026-07-02-nongaussian-nb2-lv-profile-gate.md`
  - this report.
- External dashboard refresh in gllvmTMB:
  `docs/dev-log/dashboard/status.json`, `docs/dev-log/dashboard/sweep.json`.

## Tests Added

- NB2 selected-entry profile canary: verifies public `confint_lv_effects`
  profile routing for one ordinary NB2 `B_lv` entry.
- Dispersion guard: checks the fitted `r` remains between `0.25` and `10.0` in
  the canary so this is not merely a Poisson-boundary proof.

## Benchmark Numbers

N/A - no likelihood hot path or optimizer implementation changed. Exploratory
NB2 smoke found the successful canary cell at about 4.86 seconds for the point
fit and 15.63 seconds for the selected-entry profile after compilation. The
focused `test/test_lv_ci.jl` file completed in 3m26.5s on the final rerun.

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
X_lv Wald CIs - confint_lv_effects: 162 passed, 0 failed, 0 errored, 3m26.5s
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
rg -n "Poisson, Binomial logit, and NB2|162/162|No LV compute|coverage calibration|source-specific lv support|unique= parity" docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
```

Expected hits are historical and current guard wording only.

## GitHub Issue Maintenance

No issue or PR action. PR #127 remains closed/parked; no push or PR reopen was
attempted.

## What Did Not Go Smoothly

An initial `p=2, n=60` NB2 profile smoke was interrupted after the point fit
because the selected-entry profile inversion had already exceeded local canary
scale. Smaller `p=2` smokes returned finite endpoints, but fitted `r` moved to a
large Poisson-like value. The banked canary therefore uses `p=4, n=45` and true
`r = 1.5`, with fitted `r` about `1.73`.

## Team Learning

Gauss/Fisher rule: NB2 selected-entry profiling needs a dispersion-present local
cell. A finite interval from a Poisson-boundary NB2 fit is useful diagnostic
information, but it is not the right proof of the NB2 route.

## Remaining Risks

- This is not coverage calibration.
- Ordinary Gamma and Beta still need their own selected-entry profile gates
  before any broad one-part non-Gaussian claim.
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
ordinary NB2 selected-entry `B_lv`; coverage calibration, remaining families,
and all structural-source claims remain gated.
