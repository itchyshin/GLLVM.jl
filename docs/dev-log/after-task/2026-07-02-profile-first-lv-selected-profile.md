# After Task: Profile-First LV Selected-Entry Profile

## Goal

Harden the profile-first LV uncertainty route by making admitted `B_lv`
profile-likelihood intervals selectable and control-bounded, while keeping
bootstrap secondary and all source-specific/R-bridge/mixed-family claims gated.

## Implemented

`profile_ci()` and non-Gaussian `confint(...; method = :profile)` now expose
bounded refit/profile controls without changing defaults. `confint_lv_effects()`
now accepts `profile_indices` for selected entries of `vec(B_lv)` when
`method = :profile`, and rejects that selector for Wald/bootstrap methods.
Docs, README, changelog, check-log, and the local gllvmTMB Mission Control board
were refreshed to say native GLLVM.jl selected-entry profile-LR is covered
locally, not R bridge transport, R parity, coverage calibration, source-specific
LV support, or mixed-family CI support.

Follow-up goal closeout added the non-unique LV boundary and unique-lane join
gate: the concurrent `unique=` work is R/TMB-first and separate, and Julia
parity for `*_latent(unique=)` starts only after the relevant R contract is
green and a separate parity gate is opened.

## Mathematical Contract

The target is the rotation-stable induced trait effect
`B_lv = Lambda * alpha_lv'`. For a selected entry `idx`, the profile interval
inverts `D(c) = 2 * (NLL_constrained(B_lv[idx] = c) - NLL_hat)` against the
chi-square(1) cutoff, re-optimising nuisance parameters at each candidate. The
raw `alpha_lv` table remains an axis/access-effect output, not the interval
target.

## Files Changed

- `src/confint_profile.jl` - Gaussian profile refit/bracket controls.
- `src/confint_family.jl` - family profile controls and public
  `confint_lv_effects(...; profile_indices=...)`.
- `test/test_confint_profile.jl` - Gaussian profile control smoke and guards.
- `test/test_confint_family.jl` - non-Gaussian profile control smoke and guards.
- `test/test_lv_ci.jl` - public selected-entry `B_lv` profile and guard tests.
- `test/test_phylo_xlv.jl` - phylo augmented-objective selected-entry public
  profile smoke.
- `README.md`, `docs/src/confidence-intervals.md`, `docs/src/model.md`,
  `docs/src/gllvmtmb-parity.md`, `docs/src/changelog.md` - user-facing
  profile-first docs and bridge-boundary wording.
- `docs/dev-log/check-log.md` - command log and dashboard verification.
- `docs/dev-log/decisions/2026-07-02-lv-arc-final-closeout-and-next-capabilities.md`
  - unique-lane join gate for later Julia parity.
- External dashboard refresh in gllvmTMB:
  `docs/dev-log/dashboard/status.json`, `docs/dev-log/dashboard/sweep.json`.

## Tests Added

- Gaussian `profile_ci` control smoke: checks that explicit profile controls
  still bracket the clean sigma fixture and bad controls throw.
- Non-Gaussian profile control smoke: routes profile controls through Poisson
  `confint(...; method = :profile)` and checks bad controls throw.
- Public `confint_lv_effects` selected-entry profile smoke: checks
  `profile_indices = [2, 4]` returns the matching subset of full Gaussian
  `B_lv` profile output.
- Guard tests: empty, duplicate, out-of-range `profile_indices`,
  `profile_indices` with `method = :wald`, non-positive iterations, and
  non-finite gradient tolerance.
- Phylo Model A local smoke now uses the public `profile_indices` route.

Tests-of-tests clause: the new tests exercise public API behavior that did not
exist before, boundary/malformed selectors, and a neighbouring phylo augmented
objective path.

## Benchmark Numbers

N/A - this changes confidence-interval control plumbing and selected-entry
routing, not likelihood hot paths. No BenchmarkTools timing was run.

## R-Parity Verdict

Parity: N/A - R bridge `X_lv` profile/bootstrap transport remains intentionally
blocked. Bridge CI tests still pass native Julia routing/parity against native
GLLVM.jl outputs only.

## JET / Allocs / Aqua Verdicts

- JET: clean through `Pkg.test()` - full suite passed.
- Allocs: not run - no likelihood hot path or allocation target changed.
- Aqua: clean through `Pkg.test()` - full suite passed.

## Checks Run

```text
julia --project=. --startup-file=no test/test_confint_profile.jl
profile CI: 8 passed, 0 failed, 0 errored, 22.5s

julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 139 passed, 0 failed, 0 errored, 3m02.2s

julia --project=. --startup-file=no test/test_phylo_xlv.jl
phylo x X_lv (Model A): 25 passed, 0 failed, 0 errored, 1m16.8s

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60

julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

julia --project=. --startup-file=no test/test_confint_profile.jl
profile CI: 8 passed, 0 failed, 0 errored, 21.6s

julia --project=. --startup-file=no test/test_confint_family.jl
Non-Gaussian confidence intervals: 124 passed, 0 failed, 0 errored, 4m30.5s

julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 139 passed, 0 failed, 0 errored, 2m51.6s

julia --project=. --startup-file=no test/test_phylo_xlv.jl
phylo x X_lv (Model A): 25 passed, 0 failed, 0 errored, 1m17.6s

julia --project=. --startup-file=no test/test_bridge_capabilities.jl
bridge capabilities ledger: 105 passed, 0 failed, 0 errored, 0.4s

julia --project=. --startup-file=no test/test_bridge_ci.jl
bridge CI routing: 64 passed, 0 failed, 0 errored, 31.7s

julia --project=. --startup-file=no test/test_bridge_x.jl
bridge fixed-effect X (non-Gaussian one-part families): 195 passed, 0 failed,
0 errored, 36.1s

julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
bridge missing-response mask: 83 passed, 0 failed, 0 errored, 26.6s

julia --project=. --startup-file=no test/test_bridge_mixed.jl
bridge mixed-family payload metadata: 18 passed, 0 failed, 0 errored, 6.4s

julia --project=docs --startup-file=no docs/make.jl
Documenter/Vitepress build completed. Existing invalid local-link warnings and
npm audit warnings remained; no build failure.

julia --project=. -e 'using Pkg; Pkg.test()'
GLLVM.jl: 4981 passed, 1 broken, 0 failed, 0 errored, 4982 total, 52m59.0s

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/version.txt
r60
```

Browser preview at `http://127.0.0.1:8770/` was visible and confirmed
`Native profile B_lv`, `Profile-first LV uncertainty`, `profile_indices`,
`bootstrap_basic 591/720`, the bridge profile boundary, and no active compute.

## Consistency Audit

Searched:

```sh
rg -n "partial support|ready to expose|bootstrap rescue|Gate 3 passed|profile is the main uncertainty engine|source-specific.*support|mixed-family CI|R bridge profile transport|coverage calibration" README.md docs/src docs/dev-log/after-task docs/dev-log/decisions src test CLAUDE.md
rg -n "partial support|ready to expose|bootstrap rescue|Gate 3 passed|profile is the main uncertainty engine|source-specific.*support|mixed-family CI|R bridge profile transport|coverage calibration" docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
git diff --check
```

Hits were historical guard text or negative boundary wording. The current
dashboard explicitly says native selected-entry profile is not source-specific
support, not R bridge profile transport, not R parity, and not coverage
calibration.

## GitHub Issue Maintenance

`gh pr list --limit 5` returned no open PR rows in this handover worktree. No
issue or PR action was taken; PR #127 remains closed/parked.

## What Did Not Go Smoothly

The initial browser wait used an unsupported `networkidle` state; verification
was retried with `load`. The broad claim-audit search necessarily returns many
historical notes because prior after-task reports quote the forbidden wording as
guard text.

## Team Learning

For LV uncertainty, expose cheap selected-entry profile controls before asking
for cluster compute, and keep bootstrap language secondary unless a gate names it
explicitly.

## Remaining Risks

- R bridge `X_lv` profile/bootstrap transport remains blocked; only native
  GLLVM.jl selected-entry `B_lv` profile was hardened.
- GLM `B_lv` profile remains expensive; selected entries are the intended
  practical route.
- Documentation build has pre-existing invalid local-link warnings and npm audit
  warnings unrelated to this slice.
- Allocation-specific checks were not run because no likelihood hot path changed.

## Known Limitations

- `profile_indices` is accepted only with `method = :profile`.
- `profile_indices` indexes `vec(B_lv)` in column-major order.
- No source-specific `phylo_latent(..., lv = ~ x)`, spatial/animal/kernel
  `lv`, mixed-family `X_lv`, mask `X_lv`, or R bridge profile/bootstrap
  support was added.
- `alpha_lv` remains an axis/access-effect output; intervals target `B_lv`.
- The separate `unique=` lane must land its R/TMB contract before this work can
  join any Julia parity implementation.

## Next Command

```sh
git status --short
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - profile-first implementation, focused tests,
full `Pkg.test()`, docs build, Mission Control refresh, and the unique-lane join
gate are recorded; R bridge profile/bootstrap transport, source-specific LV
exposure, mixed-family CIs, coverage calibration, and Julia `unique=` parity
remain explicitly blocked until their own gates open.
