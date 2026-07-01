# After Task: LV structural dependency truth lock

## Goal

Keep the Julia bridge ledger aligned with the R bridge truth-lock: source guards,
mixed-family point boundaries, and bridge capabilities must say the same thing.

## Implemented

Added explicit test assertions that the Julia `mixed-family vector` capability
row is point/postfit only. The row keeps `fit_no_x = true` and retained postfit
payloads, while fixed `X`, predictor-informed `X_lv`, missing-response masks,
and all CI routes remain unavailable. No source code, likelihood path, formula
grammar, package API, or compute launcher changed.

## Mathematical Contract

No model equation changed. This slice only preserves the bridge contract:
mixed-family vector parity is a complete balanced point/postfit bridge row, not
an interval, mask, fixed-effect, or source-specific latent-regression claim.

## Files Changed

- `test/test_bridge_capabilities.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-lv-structural-dependency-truth-lock.md`

## Tests Added

One focused boundary assertion block was added to
`test/test_bridge_capabilities.jl`. It satisfies the boundary/failure-path
clause by checking unavailable capability columns stay false rather than being
misread as supported.

## Benchmark Numbers

N/A - no hot-path source changed.

## R-Parity Verdict

Parity: N/A - no likelihood, fitter, init path, or CI machinery changed. The R
bridge truth was checked separately in `gllvmTMB` by parse plus pure-R bridge
smoke.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia source or hot path changed.
- Allocs: not run - no hot path changed.
- Aqua: not run - no dependency, export, or package metadata changed.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
julia --project=. --startup-file=no test/test_bridge_mixed.jl
julia --project=. --startup-file=no test/test_bridge_x.jl
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
julia --project=. --startup-file=no test/test_bridge_ci.jl
git diff --check -- test/test_bridge_capabilities.jl docs/dev-log/check-log.md
```

Results:

```text
bridge capabilities ledger: 63/63 pass
bridge mixed-family payload metadata: 18/18 pass
bridge fixed-effect X: 195/195 pass
bridge missing-response mask: 83/83 pass
bridge CI routing: 64/64 pass
```

## Consistency Audit

Searched current design/check-log/bridge surfaces for stale `ready to scale`,
source-specific support promotion, `partial support`, active compute, and
mixed-family CI/`X_lv` overclaims. Hits were historical or negative guard text;
the touched bridge ledger test contains no support promotion.

## GitHub Issue Maintenance

No GitHub action was taken. PR #127 remains closed/parked, and no push or PR
reopen was authorized.

## What Did Not Go Smoothly

The first R package-level test attempt in the twin checkout found a stale local
TMB shared object linked against R 4.5 while active R was 4.6. After rebuilding
the untracked DLL against R 4.6, the focused R files passed; the Julia ledger
tests were run directly here.

## Team Learning

Hopper and Rose should keep the bridge ledger as a truth matrix, not a roadmap
promise.

## Remaining Risks

- Full R package checks were not run; only the focused files in the council plan
  were run after rebuilding the stale local DLL.
- Mixed-family vector parity is still point/postfit only.
- Source-specific phylo `lv` remains parked for v1.

## Known Limitations

This does not expose `phylo_latent(..., lv = ~ x)`, does not add mixed-family
`X`/`X_lv`/mask/CI support, does not change `alpha_lv` or `B_lv` inference, and
does not launch new compute.

## Next Command

```sh
cd /Users/z3437171/Dropbox/Github\ Local/gllvmTMB && sh tools/start-mission-control.sh --background
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - Julia bridge ledger tests and the R twin
focused files are green, but this was not a full package-check slice.
