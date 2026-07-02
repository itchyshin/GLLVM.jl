# After Task: Core Suite Interrupted Check

## Goal

Record the attempted consolidated quick core-suite check after the LV and
postfit slices.

## Implemented

No source behavior changed. This is a verification-attempt record only.

## Mathematical Contract

N/A - no model, likelihood, inference, or bridge behavior changed.

## Files Changed

docs:

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-core-suite-interrupted-check.md`

## Tests Added

None.

## Benchmark Numbers

N/A.

## R-Parity Verdict

N/A - no R bridge behavior changed.

## JET / Allocs / Aqua Verdicts

- JET: not run.
- Allocs: not run.
- Aqua: not run.

## Checks Run

```sh
julia --project=. --startup-file=no test/runtests.jl
# interrupted after a long CPU-active run; not counted as passing
# last explicit progress before interrupt:
# masked-objective analytic vs FD
#   maxdiff_poisson = 5.417778936589457e-8
#   maxdiff_binomial = 2.4065222259395114e-8
# interrupt landed in test/test_va_vs_laplace.jl:14
# process exited with code 130 after a second interrupt

pgrep -fl 'julia.*test/runtests|julia.*runtests' || true
# clean, no output

julia --project=. --startup-file=no test/test_va_vs_laplace.jl
# VA vs Laplace comparison | 8 pass
```

## Consistency Audit

The interrupted broad suite is not green evidence. The file where the interrupt
landed passed when isolated, so no regression is inferred from that interruption.
The current accepted evidence for tonight's changes remains the focused green
tests and successful docs build recorded in the preceding after-task reports.

## GitHub Issue Maintenance

No issue or PR action taken.

## What Did Not Go Smoothly

`test/runtests.jl` was much slower than expected in this integration worktree
and stayed CPU-active for a long quiet stretch. It was interrupted to keep the
autonomous run moving.

## Team Learning

Grace: for this branch, the focused tests are the practical per-slice gate;
`test/runtests.jl` should be saved for an explicit broad validation window or
run with enough time budget.

## Remaining Risks

- No complete quick-core or full `Pkg.test()` pass is available after tonight's
  local commits.
- The next broad validation should be a fresh `test/runtests.jl` run with an
  explicit long-run time budget.

## Known Limitations

This is a failed/interrupted check record only.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/runtests.jl
```

## Rose Verdict

Rose verdict: WARN - broad core-suite validation was attempted but interrupted.
The focused VA-vs-Laplace file passed in isolation, but do not claim a green core
suite from this run.
