# After Task: Multinomial name-clash vs Distributions (#257 CI)

**Date:** 2026-08-18
**Lane:** `cursor/lane-parity-beyond-20260818` (PR #257)
**Worktree:** `~/local-scratch/lanes/GLLVM.jl-parity-beyond-20260818`
**Julia pin:** `origin/main` `13ccb7d5` (#259 merged into this branch first)

## Goal

Clear Julia CI `UndefVarError: Multinomial not defined` in
`test/test_multinomial.jl` after `using Distributions` / GLLVM export,
without renaming the public Identity marker.

## Implemented

Root cause: earlier `runtests.jl` files `using Distributions`. Both
GLLVM and Distributions export `Multinomial`, so the bare name is
undefined in the shared test namespace (Julia ambiguous-import
`UndefVarError`). Focused file-only runs hid this because they never
imported Distributions.

Fix is test/local qualification only. Public API stays `Multinomial`
(`src/GLLVM.jl` still exports it). Tests use `GLLVM.Multinomial` and
keep `Distributions.Multinomial` usable. No `src/` export rename.

## Mathematical Contract

Unchanged. This slice does not touch the softmax / packing Identity.

## Files Changed

- `test/test_multinomial.jl` — `using Distributions`; qualify
  `GLLVM.Multinomial`; clash testset vs `Distributions.Multinomial`
- `docs/dev-log/check-log.md` — this slice
- `docs/dev-log/after-task/2026-08-18-multinomial-name-clash.md` — this report
- `AGENTS.md` — phase-snapshot line only
- `LOOP/arcs.md` — P1-eng tally 37 → 41

`src/families/multinomial.jl` and the `Multinomial` export **not**
edited.

## Tests Added

One clash testset (4 assertions): both qualified names construct, types
differ, `Distributions.Multinomial` still has length 3. Satisfies
"would have failed before" (bare `Multinomial()` after
`using Distributions`) and "neighbouring feature" (Distributions still
usable).

## Benchmark Numbers

N/A — no hot-path change.

## R-Parity Verdict

Parity: N/A — change does not touch the parity surface. No invented Δ.

## JET / Allocs / Aqua Verdicts

- JET: not run (Mac-light focused file; full suite = GitHub CI)
- Allocs: N/A — no inner-loop budget claimed
- Aqua: not run locally (same)

## Checks Run

```
export PATH="$HOME/.juliaup/bin:$PATH"
julia --project=. --startup-file=no test/test_multinomial.jl
```

```
Test Summary:                                | Pass  Total  Time
multinomial family (FE softmax, twin fid 16) |   41     41  2.6s
```

## Consistency Audit

`rg -n "Multinomial" test/` — only `test_multinomial.jl` and the
already-qualified `test_aghq_gate.jl` (`Distributions.Multinomial`).
No invented Δ. No Dropbox path. Ledger file not edited.

## GitHub Issue Maintenance

Fix goes onto OPEN PR #257. Do not merge until CI green.

## What Did Not Go Smoothly

`947c5ac5` already qualified the AGHQ-gate Distributions constructor
and still left `test_multinomial.jl` on the bare name. File-only
Mac-light hid the `runtests.jl` clash.

## Team Learning

When a new export collides with Distributions, qualify **every** test
that uses the bare name, not only the file that first failed.

## Remaining Risks

- Full suite not run locally — GitHub CI is the suite claim.
- Callers who `using GLLVM, Distributions` still need to qualify.
- Ledger still `missing`. No twin Δ.

## Known Limitations

Public `using GLLVM` still exports `Multinomial`. The clash is
namespace-level, not an engine bug.

## Next Command

Push to #257. Watch Julia CI. Merge with `--merge` only after SUCCESS.
Do not invent Δ. Do not touch Dropbox.

## Rose Verdict

Rose verdict: PASS WITH NOTES — Mac-light 41/41; public API unchanged;
full suite = GitHub CI; no twin Δ; ledger still `missing`. Notes =
remaining risks above.
