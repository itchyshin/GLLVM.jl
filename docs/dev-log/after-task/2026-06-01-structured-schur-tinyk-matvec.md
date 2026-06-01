# After Task: Structured Schur Tiny-K Matvec

## Goal

Speed up the matrix-free structured Schur path used by CG mode solves and
SLQ/Lanczos determinant work.

## Implemented

`_schur_u_mul!` now has direct tiny-`K` branches for `K = 1`, `K = 2`, and
`K = 3`. The branches keep the same Schur complement formula but avoid tiny
temporary-vector fills, small matrix-vector multiply dispatch, and inner
`k/l` loops inside the site sweep. The generic branch for `K >= 4` is unchanged.

## Mathematical Contract

For a vector `x`, the operator still applies

```text
S_u x = sigma2^-1 Qx + (sum_s w_s) .* x
        - sum_s D_s Lambda A_s^-1 Lambda' D_s x,
A_s = I_K + Lambda' D_s Lambda.
```

This slice changes only the small-`K` arithmetic used to compute
`A_s^-1 Lambda' D_s x` and the final correction.

## Files Changed

- `src/structured_schur.jl` - added direct `K = 1`, `K = 2`, and `K = 3`
  matvec branches.
- `test/test_structured_schur.jl` - added explicit `K = 1` and `K = 3`
  matvec checks against the dense Schur reference; existing checks already
  exercise `K = 2`.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-schur-tinyk-matvec.md` - this
  audit report.

## Tests Added

Two structured Schur matvec checks were added: one for `K = 1`, one for
`K = 3`, both comparing the matrix-free operator against the dense Schur
reference to `1e-10`.

## Benchmark Numbers

Manual matvec microbenchmark on `p = 1024`, `n = 256`, tridiagonal sparse
precision, 200 reps for `K = 1` and `K = 2`, 100 reps for `K = 3`, after one
warmup:

Before:

```text
K=1 matvec median=1286.7085 us bytes=80
K=2 matvec median=1824.1045 us bytes=80
K=3 matvec median=2227.7295 us bytes=80
```

After:

```text
K=1 matvec median=314.5835 us bytes=80
K=2 matvec median=335.0420 us bytes=80
K=3 matvec median=368.6670 us bytes=80
```

Interpretation: matrix-free Schur matvec improved by about `4.09x` for
`K = 1`, `5.44x` for `K = 2`, and `6.04x` for `K = 3`, with no allocation
increase.

Trace-gradient benchmark after the change:

```text
giant    p=1024 n= 256 K=2 dense=  0.1950 s  slq=  0.2253 s  speedup=   0.87x  valuediff=7.29e-01  gradrel=9.89e-02
```

Previous same-cell result from the direct-site-factor slice: dense `0.2220s`,
SLQ `0.7712s`. Interpretation: exact dense trace-gradient improved by about
`1.14x`, while the SLQ/Lanczos trace-gradient path improved by about `3.42x`.
This is internal algorithm evidence; the unchanged value/gradient differences
mean it is not an R `gllvmTMB` parity claim.

## R-Parity Verdict

Parity: N/A - this changes an internal structured Schur substrate and fixed
structured Poisson prototype path, not a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: unchanged in the matvec microbenchmark at 80 bytes.
- Aqua: clean through the `Pkg.test()` quality gate.

## CI And Bootstrap Status

No confidence-interval or bootstrap code was edited. The existing CI and
bootstrap tests are exercised by the core and full suite runs recorded below.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 139 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2348 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2360 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-tinyk-matvec.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-tinyk-matvec.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal Schur-matvec speed evidence only;
  no public 100x structured speed claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## GitHub Issue Maintenance

No issue action was taken. This is an internal structured substrate speed slice
and does not change public family support, CI/bootstrap, or R parity surfaces.

## What Did Not Go Smoothly

The dense path also improved slightly because the inner mode solve can use CG,
but the main payoff is in SLQ/Lanczos. The SLQ approximation error is still the
same; this slice makes the path cheaper, not more accurate.

## Team Learning

Karpinski/Gauss: tiny latent ranks deserve explicit arithmetic in the
matrix-free loop. The benchmark grid uses `K <= 3`, so removing generic
small-matrix overhead there pays directly in CG and SLQ.

## Remaining Risks

- This is still not the final large-p structured algorithm.
- SLQ value and gradient error remain governed by probes and Lanczos steps.
- The exact dense path still forms and factors the full Schur complement.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no non-Gaussian CI/bootstrap implementation changed in this slice.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant,huge,xlarge --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=3 --warmups=2
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the matrix-free Schur matvec is materially
faster for `K <= 3` and covered by dense-reference tests; remaining notes
concern SLQ approximation accuracy and public structured parity work.
