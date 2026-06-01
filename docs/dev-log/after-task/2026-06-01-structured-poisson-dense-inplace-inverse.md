# After Task: Structured Poisson Dense In-Place Inverse

## Goal

Remove avoidable allocation from the current winning exact-dense structured
Poisson gradient path.

## Implemented

`_structured_poisson_block_implicit_value_grad` now forms the dense inverse
work matrix in place: it allocates one identity matrix `G` and overwrites it
with `ldiv!(Csu, G)`. The previous expression, `Csu \ Matrix{T}(I, p, p)`,
allocated an identity matrix and a separate inverse result.

## Mathematical Contract

No likelihood, Laplace approximation, mode equation, or gradient formula
changed. The exact dense block-gradient path still uses the Cholesky factor of
the Schur complement and the same dense inverse entries; this slice only changes
how the inverse matrix storage is produced.

## Files Changed

- `src/families/structured_poisson.jl` - changed the dense inverse solve to
  in-place `ldiv!`.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-dense-inplace-inverse.md`
  - this audit report.

## Tests Added

No new tests were added because this is a mechanical allocation/speed change on
an already tested internal exact-dense gradient path. Existing structured tests
cover dense/SLQ equality, implicit gradient checks, internal fitter routes, and
the sigma-to-zero reduction.

## Benchmark Numbers

Before:

```text
giant    p=1024 n= 256 K=2 dense=  0.2608 s  slq=  0.7842 s  speedup=   0.33x  valuediff=7.29e-01  gradrel=9.89e-02
```

After:

```text
giant    p=1024 n= 256 K=2 dense=  0.2329 s  slq=  0.7841 s  speedup=   0.30x  valuediff=7.29e-01  gradrel=9.89e-02
```

Interpretation: exact dense trace-gradient time improved by about `1.12x` on
the `p=1024, n=256, K=2` break-even cell. This is a constant-factor improvement
on the current dense path, not a new public speed claim.

## R-Parity Verdict

Parity: N/A - this changes an internal fixed-covariance structured Poisson
prototype path, not a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: improved in the exact dense block-gradient path by removing one
  avoidable dense `p-by-p` result allocation.
- Aqua: clean through the `Pkg.test()` quality gate.

## CI And Bootstrap Status

No confidence-interval or bootstrap code was edited. The existing core CI and
bootstrap tests are exercised by the core suite run recorded below.

## Checks Run

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=3 --warmups=2 --out=/tmp/structured-poisson-trace-giant-before-inplace-inv.csv
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=3 --warmups=2 --out=/tmp/structured-poisson-trace-giant-after-inplace-inv.csv
```

Benchmark result: exact dense median improved from `0.2608s` to `0.2329s`.

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 122 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2336 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2348 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-dense-inplace-inverse.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-dense-inplace-inverse.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal constant-factor dense-path
  improvement only; no public 100x structured speed claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## GitHub Issue Maintenance

No issue action was taken. This is an internal constant-factor speed slice and
does not change public family support, CI/bootstrap, or R parity surfaces.

## What Did Not Go Smoothly

The larger SLQ lane looked tempting at first, but sequential evidence showed
exact dense remains the current fast path through the tested cutoff. This slice
therefore takes the less flashy but more truthful route: improve the dense path
we actually use.

## Team Learning

Karpinski/Gauss: once evidence shows exact dense is the current winner, inspect
dense linear algebra for avoidable allocation before widening the stochastic
algorithm lane.

## Remaining Risks

- This is a modest constant-factor improvement, not the final large-p
  structured algorithm.
- The exact dense path still stores the full inverse; larger wins likely need a
  diagonal/low-rank inverse strategy or a better trace estimator.
- The structured Poisson path remains an internal fixed-covariance prototype.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no non-Gaussian CI/bootstrap implementation changed in this slice.

## Next Command

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the exact-dense block-gradient path avoids one
large allocation and is measurably faster; remaining notes concern the full
inverse storage and public structured non-Gaussian parity work.
