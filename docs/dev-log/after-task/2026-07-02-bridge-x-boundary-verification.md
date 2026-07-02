# After Task: Bridge X Boundary Verification

## Goal

Verify the fixed-effect-X, predictor-informed `X_lv`, mixed-family, mask, and
CI boundaries after the bridge capability note sync.

## Implemented

No source behavior changed. This slice ran the focused bridge-X and bridge
predictor-informed-LV tests, audited R and Julia bridge ledgers, and recorded
that the current drift is intentional: Julia exposes `predictor_informed_lv` in
the engine ledger, while the R-side ledger keeps a stable public schema and
records narrower admission boundaries in notes.

## Mathematical Contract

No mathematical contract changed. Ordinary one-part fixed-effect-X rows and
ordinary one-part `X_lv` rows remain separate bridge surfaces. Mixed-family
vectors remain complete balanced point/postfit only with no fixed `X`, no
`X_lv`, no response masks, and no CIs.

## Files Changed

docs:

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-bridge-x-boundary-verification.md`

## Tests Added

None. This was a verification and evidence-banking slice.

## Benchmark Numbers

N/A - no hot-path or likelihood code changed.

## R-Parity Verdict

Parity: N/A - no R or Julia fit behavior changed. R `gllvmTMB` was read as the
reference ledger only.

## JET / Allocs / Aqua Verdicts

- JET: not run - verification/docs-only slice.
- Allocs: not run - no hot path changed.
- Aqua: not run - no dependency/export/project change.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_x.jl
# bridge fixed-effect X (non-Gaussian one-part families) | 195 pass

julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
# bridge predictor-informed latent-score X_lv | 207 pass
```

## Consistency Audit

Audited:

```sh
rg -n 'X_lv|fixed-effect X|mixed-family|mask|ci_x|predictor_informed_lv|source-specific|not wired|gated|follow-up' src/bridge.jl test/test_bridge_x.jl test/test_bridge_lv_predictor.jl test/test_bridge_capabilities.jl

rg -n 'X_lv|fixed-effect X|mixed-family|mask|ci_x|predictor_informed_lv|GJL-GATE-MIXED|not routed|gated|follow-up' R/julia-bridge.R tests/testthat/test-julia-bridge.R
```

Verdict: no new code patch is required. The remaining R/Jl schema drift is
accepted and already described: Julia has a `predictor_informed_lv` column;
R keeps that boundary in notes. Mixed-family still has no `X`, no `X_lv`, no
masks, and no CIs.

## GitHub Issue Maintenance

No issue action needed. This is local verification in the handover worktree.

## What Did Not Go Smoothly

No blocker. The tests are moderately slow but focused enough for the bridge
boundary gate.

## Team Learning

Hopper/Rose: after capability-note repair, the right next action is focused
boundary verification, not more wording churn.

## Remaining Risks

- R/gllvmTMB remains heavily dirty from other work and was not edited.
- R-side capability schema still lacks a public `predictor_informed_lv` column
  by design.
- Mixed-family `X`, `X_lv`, masks, missing responses, and CIs remain blocked.
- Source-specific `lv` remains parked.

## Known Limitations

This does not widen bridge parity, expose source-specific grammar, or run the
full Julia suite.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - bridge-X and ordinary `X_lv` boundaries are
verified by focused tests; remaining notes are deliberate mixed-family,
schema, and source-specific blockers.
