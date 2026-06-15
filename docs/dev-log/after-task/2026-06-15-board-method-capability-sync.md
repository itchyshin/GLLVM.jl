# Board Method Capability Sync

Date: 2026-06-15

## Goal

Update the mission-control dashboard after the R-first method-aware Julia bridge
capability ledger landed in `gllvmTMB` and the paired metadata target landed in
`GLLVM.jl-integration`.

## Files Changed

- `.claude/preview/status.json`
- `.claude/preview/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-15-board-method-capability-sync.md`

## Implementation

The board now treats R-first sequencing as the active operating rule:
`gllvmTMB` defines the user-facing bridge contract first, then `GLLVM.jl`
matches and accelerates the exact targets.

The new activity, evidence, and sweep rows record:

- `gllvmTMB` head `5272d7e`
- paired `GLLVM.jl-integration` head `78f8916`
- method-aware `gllvm_julia_capabilities()` rows for no-X CIs and in-sample
  post-fit methods
- live drift checking of all admitted R logical columns against
  `GLLVM.bridge_capabilities()`

## Tests Added

None. This was a dashboard and ledger sync only.

## Checks Run

```sh
jq empty .claude/preview/status.json .claude/preview/sweep.json
git diff --check -- .claude/preview/status.json .claude/preview/sweep.json
curl -fsS http://127.0.0.1:8770/status.json | jq -r '.generated_at, (.repos[] | select(.name=="gllvmTMB") | .head), .activity[0].html, .evidence[0].text'
curl -fsS http://127.0.0.1:8770/sweep.json | jq -r '.rows[] | select(.capability=="Method-aware Julia bridge capability ledger") | [.engine,.bridge,.inference,.evidence] | @tsv'
```

Result: JSON and whitespace checks passed. The running board served
`generated_at = 2026-06-15T21:15:00.000Z`, `gllvmTMB` head `5272d7e`, and a
new method-aware ledger activity/evidence row. The sweep row renders as
`partial / partial / partial`.

## Benchmarks

Not run. No performance code changed, and no speed claim was added.

## R-Parity Verdict

This board row reports already-banked R evidence only:

- no-Julia bridge gate: `219` pass / `18` expected skips
- live R-Julia bridge gate: `519/519`
- full `gllvmTMB` suite: `2989` pass / `724` skips / `0` failures /
  `3` pre-existing external warnings
- `pkgdown::check_pkgdown()`: green
- paired Julia metadata check: `19/19`

No new R parity was run in this repository for this board-only sync.

## JET / Allocs / Aqua

Not run. No Julia source changed.

## Rose Verdict

PASS WITH NOTES. The dashboard now records the method-aware R bridge contract
without claiming new fitters, estimates, likelihoods, CI numerics, REML
support, or speed. REML remains Gaussian-only. HSquared-style AI-REML remains
later exact-Gaussian scouting only, not non-Gaussian/Laplace terminology.

## Remaining Risks

- The dashboard `GLLVM.jl` worktree is still not the paired runtime engine for
  the latest bridge evidence; current live bridge evidence uses
  `GLLVM.jl-integration`.
- The board is evidence tracking, not a substitute for closing GitHub issues or
  merging branches.
- R-side method rows are contract metadata until each supported cell has point
  estimates, logLik/objective, CI or CI-status, tests, docs, and visual evidence.

## Next Command

```sh
git status --short --branch
```
