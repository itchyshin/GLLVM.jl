# After Task: Structured Schur Auto Dense Cutoff

## Goal

Move the internal structured Schur `:auto` determinant cutoff to match the new
direct-dense performance evidence.

## Implemented

The structured Schur default dense cutoff is now a shared internal constant,
`_STRUCTURED_SCHUR_DENSE_CUTOFF = 2048`. `_schur_u_logdet(...; method=:auto)`
and the structured Poisson prototype helpers use that cutoff by default, so
`p <= 2048` stays on the exact dense path and larger cells remain eligible for
SLQ. The Schur logdet benchmark also gained `--break-even` mode for future
dense-vs-SLQ cutoff runs.

## Mathematical Contract

No likelihood parameterization changed. This slice changes only the automatic
algorithm choice for evaluating the same `logdet(S_u)` term in the structured
Laplace approximation. The exact dense path and SLQ path already target the
same Schur-complement determinant; the new cutoff simply prefers the exact path
while it is faster on current evidence.

## Files Changed

- `src/structured_schur.jl` - shared internal dense cutoff constant and default.
- `src/families/structured_poisson.jl` - structured Poisson defaults now use the
  shared cutoff.
- `test/test_structured_schur.jl` - regression test proving default `:auto`
  chooses dense beyond the old `p=256` cutoff.
- `bench/structured_schur_logdet_bench.jl` - optional `--break-even` grid.
- `bench/README.md` - benchmark command note.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-schur-auto-cutoff.md` - this
  audit report.

## Tests Added

Added a `p=257` structured Schur logdet test where default `method=:auto` must
match exact `method=:dense`. This would have used SLQ under the old cutoff.

## Benchmark Numbers

Ad hoc larger-cell probe before editing the cutoff:

| p | n | K | dense exact (s) | SLQ (s) | dense / SLQ | relerr |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 640 | 160 | 3 | 0.0610 | 0.5669 | 0.108x | 5.441e-04 |
| 1024 | 256 | 3 | 0.0697 | 1.4366 | 0.048x | 8.351e-05 |
| 1280 | 320 | 3 | 0.1105 | 2.2370 | 0.049x | 4.740e-05 |
| 2048 | 512 | 3 | 0.4463 | 5.7495 | 0.078x | 3.135e-04 |

Reproducible `--break-even` benchmark:

| cell | p | n | K | dense exact (s) | SLQ (s) | dense / SLQ | relerr |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| frontier | 640 | 160 | 3 | 0.0258 | 0.5663 | 0.05x | 1.292e-03 |
| giant | 1024 | 256 | 3 | 0.0769 | 1.4375 | 0.05x | 1.845e-04 |
| huge | 1280 | 320 | 3 | 0.0899 | 2.2793 | 0.04x | 2.640e-04 |
| xlarge | 2048 | 512 | 3 | 0.4604 | 5.7120 | 0.08x | 3.157e-05 |

Interpretation: exact dense remains faster than frozen-probe SLQ through
`p=2048` on this grid, and avoids stochastic determinant error.

## R-Parity Verdict

Parity: N/A - this internal structured determinant algorithm choice is not a
public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: no zero-allocation claim; this changes the default algorithm choice,
  not the inner allocation contract.
- Aqua: clean through the `Pkg.test()` quality gate.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 113 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2327 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2339 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-auto-cutoff.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-auto-cutoff.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked repo content: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders remain after
  this update.
- Stale-wording scan: expected hits only - the user-provided AGENTS.md
  "Gaussian only" snapshot, historical check-log command/result records, and
  this scan command.
- Performance-claim scan: expected hits only - existing Gaussian/gllvmTMB
  claims, historical internal speed records, benchmark-script column names, and
  this report's internal structured Schur cutoff evidence. This slice adds no R
  `gllvmTMB` parity claim and no public 20x-100x structured speedup claim.
- GitHub lane check: open PR #59 is still the separate draft
  formula/family/CIs catch-up lane; no issue or PR was modified.

## GitHub Issue Maintenance

No issue action was taken. Open PR #59 remains the separate draft formula and
family catch-up lane; this task did not overlap it.

## What Did Not Go Smoothly

The break-even moved farther out than expected after direct dense assembly, so
the old SLQ-default intuition was no longer reliable. The useful outcome is
that exact dense is now the evidence-backed default through `p=2048`.

## Team Learning

Karpinski/Gauss: keep exact baselines aggressively optimized and benchmarked;
approximation should earn its place with a measured break-even, not just an
asymptotic argument.

## Remaining Risks

- The actual dense/SLQ crossing point is still above `p=2048`, not pinned down.
- Dense Cholesky memory will eventually dominate for very large structured
  dependence.
- This is not an R `gllvmTMB` comparison.

## Known Limitations

This slice does not add adaptive SLQ probes, preconditioning, or public
structured non-Gaussian API wiring.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --break-even --cells=xlarge --reps=3 --warmups=3
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the internal `:auto` cutoff now follows current
break-even evidence through `p=2048`, but the very-large-p crossing point
remains open.
