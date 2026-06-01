# After Task: Structured Schur Tiny-K Dense Batch

## Goal

Make exact dense structured Schur assembly substantially faster for the
`K <= 3` cells that dominate the current structured Poisson benchmark grid.

## Implemented

`_schur_u_dense` now dispatches `K <= 3` operators to
`_schur_u_dense_tinyk!`, which copies the scaled structured precision, adds
the diagonal site-weight sum, builds a tall site-factor matrix `C`, and applies
all Schur correction terms with one `mul!(S, C, C', -1, 1)`. The existing
generic direct dense assembler remains the fallback for `K >= 4`.

## Mathematical Contract

The dense matrix is still the same structured Schur complement,

```text
S_u = sigma2^-1 Q + diag(sum_s w_s)
      - sum_s D_s Lambda A_s^-1 Lambda' D_s,
A_s = I_K + Lambda' D_s Lambda.
```

For `K <= 3`, the implementation factors each cached `A_s^-1 = F_s F_s'` and
forms `C_s = D_s Lambda F_s`, so `sum_s C_s C_s'` is exactly the same Schur
correction computed by the generic direct assembler.

## Files Changed

- `src/structured_schur.jl` - added `_schur_u_dense_tinyk!` and tiny-`K`
  dispatch from `_schur_u_dense`.
- `test/test_structured_schur.jl` - added direct dense-batch correctness and
  guardrail tests.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-schur-tinyk-dense-batch.md` -
  this audit report.

## Tests Added

The structured Schur operator test now checks `K = 1`, `K = 2`, and `K = 3`
dense-batch assembly against the existing generic direct assembler to `1e-10`,
checks `_schur_u_dense(op)` returns the same result, and checks malformed
workspace / `K > 3` guardrails.

## Benchmark Numbers

Same-command dense assembly benchmark from the prior committed state versus
this dense-batch implementation:

| p | n | K | before dense assembly | after dense assembly | before / after | after bytes |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1024 | 256 | 2 | 84.013833 ms | 13.069604 ms | 6.43x | 12,636,256 |
| 2048 | 512 | 2 | 663.276958 ms | 116.877959 ms | 5.68x | 50,438,240 |
| 1024 | 256 | 3 | 123.875562 ms | 20.5697495 ms | 6.02x | 14,749,792 |

Current-code smoke after the test addition:

```text
p=1024 n=256 K=2 dense median_ms=9.885438 bytes_median=1.2636256e7
p=2048 n=512 K=2 dense median_ms=52.3524165 bytes_median=5.043824e7
p=1024 n=256 K=3 dense median_ms=14.981125 bytes_median=1.4749792e7
```

Trace-gradient benchmark after the change:

```text
giant    p=1024 n= 256 K=2 dense=  0.2122 s  slq=  0.2349 s  speedup=   0.90x  valuediff=7.29e-01  gradrel=9.89e-02
huge     p=1536 n= 320 K=2 dense=  0.4426 s  slq=  0.4180 s  speedup=   1.06x  valuediff=2.15e-01  gradrel=1.50e-01
xlarge   p=2048 n= 512 K=2 dense=  0.9094 s  slq=  0.9563 s  speedup=   0.95x  valuediff=1.98e-01  gradrel=1.67e-01
```

Compared with the previous tiny-`K` matvec slice, exact dense trace-gradient
time improved from `0.2740s` to `0.2122s` on `giant`, from `0.8152s` to
`0.4426s` on `huge`, and from `1.7342s` to `0.9094s` on `xlarge`. The SLQ
approximation error is unchanged, so this is a speed and exact-dense baseline
improvement, not an SLQ parity improvement.

## R-Parity Verdict

Parity: N/A - this changes an internal structured Schur substrate and fixed
structured Poisson prototype path, not a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: dense assembly allocates a larger `p x (K*n)` batch workspace; no
  allocation-reduction claim is made.
- Aqua: clean through the `Pkg.test()` quality gate.

## CI And Bootstrap Status

No confidence-interval, bootstrap, or public CI configuration code was edited.
The full suite still exercises the current CI/bootstrap tests, including
`confint`, profile CI, parametric bootstrap CI, and derived-quantity CI blocks.
No branch CI was triggered because this local branch was not pushed.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 147 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2356 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2368 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-tinyk-dense-batch.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-tinyk-dense-batch.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders after this
  report was finalized.
- Stale-wording scan: expected historical and command-pattern hits only,
  including the user-provided AGENTS.md "Gaussian only" snapshot; this slice
  adds no public API/status claim.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal Schur dense-assembly speed
  evidence only; no public 100x structured speed claim or new R `gllvmTMB`
  parity claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## GitHub Issue Maintenance

No issue action was taken. This is an internal structured substrate speed slice
and does not change public family support, CI/bootstrap, or R parity surfaces.

## What Did Not Go Smoothly

The exact dense path is now fast enough that the current SLQ configuration is
only tied or slightly faster through `p = 2048`; the large-`p` path still needs
accuracy/calibration work before it can support strong public claims.

## Team Learning

Karpinski/Gauss: for `K <= 3`, many small rank-`K` updates are worse than one
tall BLAS update, even though the batch workspace is larger. Fisher: the
result keeps the exact path attractive while SLQ remains approximate.

## Remaining Risks

- The batch workspace can be large for high `n`; this is an intentional
  time-memory tradeoff in the exact dense path.
- Exact dense still factors the full `p x p` Schur complement.
- SLQ value and gradient error remain governed by probes and Lanczos steps.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no non-Gaussian CI/bootstrap implementation changed in this slice.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=xlarge --trace-solve=lanczos --probe-kind=orthogonal --nprobes=32 --lanczos-steps=40 --reps=2 --warmups=1
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - tiny-`K` exact dense Schur assembly is faster
and dense-reference tested; remaining notes concern the larger batch workspace,
full dense factorization, and unchanged SLQ approximation error.
