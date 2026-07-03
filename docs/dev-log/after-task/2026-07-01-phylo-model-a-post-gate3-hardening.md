# After Task: Phylo Model A Post-Gate3 Hardening

## Goal

Freeze the Gate 0-3 evidence packet and make the post-Gate3 claim boundary
clear before any new modelling, R grammar exposure, or non-Gaussian work.

## Implemented

Added a compact evidence-freeze decision note, tightened the Design 73 status
paragraph, and updated the structural-dependencies note so it reflects the
Gate 3 pass while still blocking source-specific exposure.

## Mathematical Contract

No likelihood, fitter, confidence-interval, or simulation code changed. The
frozen target is the eta-scale realized/design-conditional
`B_eta_realized`; the old population `B_lv = Lambda * alpha_lv'` route remains
retired/parked for v1.

## Files Changed

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-phylo-model-a-post-gate3-hardening.md`

## Tests Added

None. This was a documentation and claim-boundary hardening slice.

## Benchmark Numbers

N/A - no hot-path code changed.

## R-Parity Verdict

Parity: N/A - no R bridge, likelihood, fitter, init, or CI machinery changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia source changed.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata, exports, or dependencies changed.

## Checks Run

```sh
git diff --check -- docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-01-phylo-model-a-post-gate3-hardening.md
rg -n "B_eta_realized|2495/2500|0\\.998000000|explicitly authorizes|separate derivation and ADEMP" docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md
rg -n "Gate 3 running|active compute only|result files: 0/500|detail files: 0/500|1 active|ready to scale|source-specific phylo lv.*covered|non-Gaussian.*covered" docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md
```

## Consistency Audit

Rose scan target: Gate 3 evidence present, public support still blocked, no
live "ready to scale", "Gate 3 running", "1 active", or source-specific covered
wording in the touched current notes. Historical failed-route records were left
intact in append-only check logs.

## GitHub Issue Maintenance

No GitHub action was taken. PR #127 remains closed/parked as blocked evidence.

## What Did Not Go Smoothly

The active desktop GLLVM.jl checkout is not the handover worktree that carries
the Gate 3 evidence. This hardening intentionally edits
`/private/tmp/gllvmjl-phylo-xlv`, the evidence worktree, and leaves the desktop
checkout untouched.

## Team Learning

Ada and Rose should freeze evidence separately from exposure decisions; Fisher
should keep target identity visible whenever a new finite-sample target passes.

## Remaining Risks

- Gate 3 does not automatically authorize R grammar exposure.
- Non-Gaussian/source-specific extensions remain separate derivation and ADEMP
  arcs.
- The old population-`B_lv` route remains negative despite the changed-target
  Gate 3 pass.

## Known Limitations

This does not expose `phylo_latent(..., lv = ~ x)`, does not reopen PR #127,
does not push, and does not launch Totoro or DRAC compute.

## Next Command

```sh
cd /Users/z3437171/Dropbox/Github\ Local/gllvmTMB && python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the evidence packet is frozen, with exposure
and non-Gaussian work still blocked behind explicit authorization.
