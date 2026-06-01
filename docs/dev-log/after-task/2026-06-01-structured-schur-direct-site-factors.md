# After Task: Structured Schur Direct Site Factors

## Goal

Speed up structured Schur operator setup without changing the structured
Poisson likelihood or gradient surface.

## Implemented

`_SchurUOperator` now stores each site factor as `logdet(A_s)` plus
`A_s^{-1}` instead of storing a per-site Cholesky object. For `K = 1` and
`K = 2`, the site factor uses closed-form determinant/inverse formulas; for
`K >= 3`, the existing Cholesky path still computes the same quantities locally
and stores only the values needed downstream. Structured Poisson code now sums
`op.Alogdets` instead of repeatedly calling `logdet(op.Achols[i])`.

## Mathematical Contract

For site `s`, the local latent-factor curvature remains
`A_s = I_K + Lambda' W_s Lambda`. This slice preserves the same
`logdet(A_s)` and `A_s^{-1}` used by the Schur complement; it only changes how
those two quantities are represented and computed for small `K`.

## Files Changed

- `src/structured_schur.jl` - replace stored Cholesky factors with stored
  log-determinants and direct `K = 1`/`K = 2` site inverses.
- `src/families/structured_poisson.jl` - sum `op.Alogdets` in the Laplace
  objective and implicit-gradient paths.
- `test/test_structured_schur.jl` - check `A_s^{-1}` and `logdet(A_s)` for
  direct `K = 2` and generic `K = 3` site factors.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-schur-direct-site-factors.md`
  - this audit report.

## Tests Added

Added a generic `K = 3` structured Schur site-factor check so the fallback
Cholesky path remains covered after the `K = 1`/`K = 2` direct-factor refactor.

## Benchmark Numbers

Manual setup microbenchmark, after one warmup on `p = 1024`, `n = 256`,
`K = 2`, tridiagonal sparse precision, 30 workspace reps, 20 operator reps:

Before:

```text
workspace median=0.0322495 ms bytes=68144
operator median=2.3687919999999996 ms bytes=68256
```

After:

```text
workspace median=0.0162085 ms bytes=64048
operator median=0.3101455 ms bytes=64160
```

Interpretation: workspace setup improved about `1.99x`; `_SchurUOperator`
construction improved about `7.64x` on the benchmarked `K = 2` setup cell.

Trace-gradient benchmark after the change:

```text
giant    p=1024 n= 256 K=2 dense=  0.2220 s  slq=  0.7712 s  speedup=   0.29x  valuediff=7.29e-01  gradrel=9.89e-02
```

Previous same-cell result from the dense-in-place slice: dense `0.2329s`, SLQ
`0.7841s`. Interpretation: about `1.05x` exact-dense trace-gradient
improvement and about `1.02x` SLQ trace-gradient improvement. This is internal
setup-path evidence, not an R `gllvmTMB` parity claim.

## R-Parity Verdict

Parity: N/A - this changes an internal structured Schur substrate and fixed
structured Poisson prototype path, not a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: lower setup allocation in the benchmarked `K = 2` cell, from 68144
  to 64048 bytes for workspace setup and from 68256 to 64160 bytes for operator
  construction.
- Aqua: clean through the `Pkg.test()` quality gate.

## CI And Bootstrap Status

No confidence-interval or bootstrap code was edited. The existing CI and
bootstrap tests are exercised by the core and full suite runs recorded below.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 137 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2346 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2358 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-direct-site-factors.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-direct-site-factors.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal setup-path speed evidence only;
  no public 100x structured speed claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## GitHub Issue Maintenance

No issue action was taken. This is an internal structured substrate speed slice
and does not change public family support, CI/bootstrap, or R parity surfaces.

## What Did Not Go Smoothly

The end-to-end trace-gradient gain is much smaller than the isolated operator
setup win because exact dense factorization and inverse work still dominate the
large `p` cell. The setup win is still worth keeping because it cleans a hot
shared substrate and helps the CG/SLQ route more directly.

## Team Learning

Karpinski/Gauss: when `K` is tiny, per-site matrix objects and Cholesky factors
are often overhead rather than math. Store the quantities the Schur operator
actually needs: `logdet(A_s)` and `A_s^{-1}`.

## Remaining Risks

- This is not the final large-p structured algorithm.
- The dense exact path still forms and factors the full Schur complement.
- The `K >= 3` path still uses local Cholesky work, though it no longer stores
  per-site Cholesky objects.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no non-Gaussian CI/bootstrap implementation changed in this slice.

## Next Command

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the structured Schur setup path is faster and
tested across direct and generic site-factor cases; remaining notes concern the
larger dense/SLQ structured algorithm and public parity work.
