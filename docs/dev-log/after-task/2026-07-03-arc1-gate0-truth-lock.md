# After Task: Arc 1 Gate 0 Truth Lock

## Goal

Start the profile-first source-specific LV exposure-decision arc with an honest Gate 0 boundary before new compute or grammar exposure.

## Implemented

Four Ultra-Plan audit lanes produced file-backed starting evidence for profile/estimand validity, bridge/grammar truth, compute/test escalation, and Rose claim boundaries. The consolidated Gate 0 decision note records that source-specific `lv = ~ env` remains blocked, `B_eta_realized` is an internal changed target rather than old `B_lv` rescue, Totoro is diagnostic-only, DRAC/Nibi is the claim-bearing denominator, and no active compute is running.

## Mathematical Contract

Unchanged. This is a planning/truth-lock slice. The interval target remains selected-entry profile-LR evidence for explicit product or realized eta-scale targets, not raw `alpha_lv`.

## Files Changed

- `docs/dev-log/audits/2026-07-03-arc1-profile-estimand-audit.md`
- `docs/dev-log/audits/2026-07-03-arc1-bridge-grammar-audit.md`
- `docs/dev-log/audits/2026-07-03-arc1-compute-test-plan.md`
- `docs/dev-log/audits/2026-07-03-arc1-rose-claim-audit.md`
- `docs/dev-log/decisions/2026-07-03-arc1-profile-first-source-lv-gate0.md`
- `docs/dev-log/after-task/2026-07-03-arc1-gate0-truth-lock.md`

## Tests Added

No tests added. This is a planning/audit slice.

## Benchmark Numbers

N/A — no implementation or hot-path code changed.

## R-Parity Verdict

Parity: N/A — no R-facing API, bridge route, or likelihood implementation changed.

## JET / Allocs / Aqua Verdicts

- JET: not run — no implementation path changed.
- Allocs: not run — no implementation path changed.
- Aqua: not run — no package hygiene change.

## Verification

Verification run:

```text
git diff --check
rg -n "partial support|ready to expose|bootstrap rescue|mixed-family CI|source-specific.*covered|active compute" docs/dev-log/decisions/2026-07-03-arc1-profile-first-source-lv-gate0.md docs/dev-log/audits/2026-07-03-arc1-*.md
```

`git diff --check` passed. The phrase scan returned guard wording and Rose audit
warnings only; no accidental support, exposure, active-compute, bootstrap-rescue,
or mixed-family-CI claim was introduced.

PR #165 merged as GitHub merge commit `8617ba1` after the Poisson selected-entry
canary fix at head `2fdd7a6`. The GitHub Julia matrix was still reporting
in-progress jobs at Gate 0 closeout time, so any late CI failure remains a
follow-up fix and not a source-specific `lv` exposure signal.

## Remaining Risks

Mission Control still needs a careful label cleanup pass. Rose recommends avoiding `active_work` as a visible label when no compute is active, clarifying `partial`, and qualifying public CI prose that currently reads too unconditional.

## Rose Verdict

Rose verdict: PASS WITH NOTES — Gate 0 truth is clear, but Mission Control wording cleanup remains before public-facing operating-board polish.
