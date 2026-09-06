# After-task — parity destination super ultra-plan

## Scope

Created the single owner-facing destination map for the GLLVM.jl ↔ gllvmTMB
parity question. The artifact consolidates the prior #305 decision map
without rebuilding the canonical #291 programme plan or the #303 M2 baton.

## Outcome

- Replaced the undefined “0.7.1 parity” phrase with explicit A/B/C/D choices.
- Preserved frozen gllvmTMB 0.7.0 (`b4d5fee6`) as the qualification oracle
  available for option B and kept 0.7.1 Class-1 work separate.
- Recorded lane, session-ownership, branch-drift, and prior-work receipts.
- Stopped at G0: no implementation, `/goal`, GATES, campaign, R-engine edit,
  merge, or true-parity claim.

## Checks

- `git diff --check` — PASS.
- Structural scan for the GOAL block, four decision-map sections, G0 list,
  pre-authorisation envelope, and explicit GATES fence — PASS.
- `lane_preflight.sh` — recorded for the fresh GLLVM.jl lane and read-only
  gllvmTMB twin; same-platform overlap remains visible.
- `session_ownership.sh` and `branch_drift_check.sh` — recorded in the plan.
- `gh pr view` — prior PRs #291/#297/#298/#301/#303/#304/#305 read.

## Not run

Julia/R tests, Documenter, parity fits, Totoro/DRAC campaigns, and production
implementation were deliberately not run because this task ends at G0.

## Review and next owner action

Rose/domain review was not dispatched in this planning-only lane. The remaining
gate is Shinichi's read/approve decision: select A, B, C, or D and answer the
ten G0 questions in the plan. No execution route is authorized by silence.
