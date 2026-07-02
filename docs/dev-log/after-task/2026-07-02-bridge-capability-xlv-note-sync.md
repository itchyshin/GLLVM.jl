# After Task: Bridge Capability X_lv Note Sync

## Goal

Make the Julia bridge capability ledger describe the current one-part `X_lv`
surface accurately while preserving the mixed-family and source-specific
blockers.

## Implemented

Updated `src/bridge.jl` metadata and payload notes so they no longer say
non-Gaussian non-binomial `X_lv` is a future route after Poisson, NB2, Beta,
and Gamma `X_lv` paths already exist. The bridge now states the narrower true
boundary: complete-response one-part `X_lv` point routes are wired for
Gaussian, Poisson, NB2, Beta, Gamma, and binomial logit/probit/cloglog; Wald
`B_lv` CI payloads are routed for admitted `X_lv` rows; profile/bootstrap
`X_lv` CIs, response-mask `X_lv`, mixed-family `X_lv`, and source-specific
`X_lv` remain gates. Added regression tests to keep that capability wording
from drifting.

## Mathematical Contract

No likelihood or estimator changed. The standing bridge contract remains
`eta = beta + Lambda * (X_lv * alpha_lv + z_innovation)'` for ordinary
predictor-informed latent scores. This slice only reconciles bridge metadata
with existing fitted routes and CI gates.

## Files Changed

src:

- `src/bridge.jl`

test:

- `test/test_bridge_capabilities.jl`

docs:

- `docs/dev-log/decisions/2026-07-02-capability-baseline-review.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-bridge-capability-xlv-note-sync.md`

## Tests Added

Added capability-note assertions in `test/test_bridge_capabilities.jl`. These
would have failed on the stale Gaussian ledger text that said non-Gaussian
non-binomial `X_lv` remained a follow-up.

## Benchmark Numbers

N/A - metadata and tests only; no hot path changed.

## R-Parity Verdict

Parity: N/A - no fit, likelihood, transport, or R-side behavior changed. The
R bridge was read as the reference ledger but not modified.

## JET / Allocs / Aqua Verdicts

- JET: not run - metadata/test-only bridge change.
- Allocs: not run - no hot path changed.
- Aqua: not run - no dependency/export/project change.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
# bridge capabilities ledger | 105 pass

julia --project=. --startup-file=no test/test_bridge_mixed.jl
# bridge mixed-family payload metadata | 18 pass

julia --project=. --startup-file=no test/test_bridge_ci.jl
# bridge CI routing | 64 pass

git diff --check -- src/bridge.jl test/test_bridge_capabilities.jl docs/dev-log/decisions/2026-07-02-capability-baseline-review.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-02-bridge-capability-xlv-note-sync.md
# passed, no output

rg -n 'non-Gaussian non-binomial X_lv remain follow-ups|broader non-Gaussian X_lv routes remain separate|point-estimate-only Gaussian and binomial|Gaussian and binomial logit' src/bridge.jl docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-capability-baseline-review.md
# no output
```

## Consistency Audit

The audit compared Julia `bridge_capabilities()` notes and mixed-family CI
unavailable status against gllvmTMB `gllvm_julia_capabilities()` and
`GJL-GATE-MIXED-CI` / `GJL-GATE-MIXED-COMPONENTS` wording. The current drift is
acceptable: R still has a stable public schema without a separate
`predictor_informed_lv` column, while Julia exposes that boolean in the local
engine ledger. Mixed-family remains no `X`, no `X_lv`, no masks, and no CIs.

## GitHub Issue Maintenance

No issue action needed. This is a local capability-ledger correction inside the
handover worktree.

## What Did Not Go Smoothly

The first new assertion was too strict about punctuation in the note and failed
once before being corrected to check the substantive phrases separately.

## Team Learning

Hopper/Rose: capability notes need regression tests when they carry the public
claim boundary; otherwise they drift behind implementation quietly.

## Remaining Risks

- R-side capability schema still does not expose `predictor_informed_lv` as a
  public column; this is an accepted schema drift for now.
- Mixed-family `X`, `X_lv`, masks, missing responses, and CIs remain blocked.
- Source-specific phylo/spatial/animal/kernel `lv` remains parked.

## Known Limitations

This task does not add a new `X_lv` family, change CI math, widen mixed-family
components, or expose source-specific grammar.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_bridge_x.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - bridge capability wording now matches the
existing one-part `X_lv` and mixed-family boundaries; remaining notes are
deliberate parity and source-specific blockers.
