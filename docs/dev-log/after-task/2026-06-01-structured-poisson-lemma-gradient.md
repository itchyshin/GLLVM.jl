# After Task: Structured Poisson Exact Lemma Gradient

## Goal

Turn the exact Schur determinant-lemma / Woodbury substrate into an opt-in
structured Poisson implicit-gradient route and benchmark it against the exact
dense block gradient.

## Implemented

`_structured_poisson_implicit_value_grad(...; logdet_method = :lemma)` now uses
the exact determinant-lemma / Woodbury factors for `logdet(S_u)`,
`diag(S_u^-1)`, batched `S_u^-1` application to all site-loading RHS columns,
and the adjoint Schur solve. The internal structured Poisson fitter and fitted
benchmark CLI now accept `logdet_method = :lemma`. The default `:auto` policy is
unchanged.

## Mathematical Contract

The route is exact for the same Schur complement used by the dense block
gradient:

```text
S_u = B - C C'
S_u^-1 = B^-1 + B^-1 C (I - C' B^-1 C)^-1 C' B^-1.
```

The gradient contribution is still the dense block-gradient target; only the
linear algebra used to obtain `logdet(S_u)`, `diag(S_u^-1)`, and
`S_u^-1 U_i` changes.

## Files Changed

- `src/families/structured_poisson.jl` - added exact `:lemma` routing, batched
  Woodbury inverse application in the block gradient, and a Woodbury adjoint
  solve.
- `test/test_structured_poisson_laplace.jl` - added lemma value/gradient,
  adjoint-solve, fitted-route, and invalid-logdet checks.
- `bench/structured_poisson_lemma_gradient_bench.jl` - new repeatable exact
  dense-vs-lemma gradient benchmark.
- `bench/structured_poisson_fit_bench.jl` - bench CLI accepts `--logdet=lemma`.
- `bench/README.md` - records the exact lemma-gradient benchmark command.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-lemma-gradient.md` -
  this audit report.

## Tests Added

Focused tests now prove lemma value/gradient agreement with the exact dense
block route, Woodbury adjoint agreement with the dense joint solve, fitted
`logdet_method = :lemma` agreement with dense, and an invalid-logdet guard.

## Benchmark Numbers

Repeatable harness:

```sh
julia --project=. --startup-file=no bench/structured_poisson_lemma_gradient_bench.jl --smoke --reps=2 --warmups=1 --out=/tmp/structured-poisson-lemma-gradient-smoke-rerun.csv
julia --project=. --startup-file=no bench/structured_poisson_lemma_gradient_bench.jl --break-even --reps=2 --warmups=1 --out=/tmp/structured-poisson-lemma-gradient-break-even-reps2.csv
```

Results:

```text
smoke    p= 160 n= 120 K=2 dense=  0.0085 s lemma=  0.0145 s speedup= 0.59x bytes=(1.74e+06, 6.80e+06) valuediff=0.00e+00 gradrel=1.20e-16
medium   p= 512 n= 128 K=2 dense=  0.0429 s lemma=  0.0269 s speedup= 1.60x bytes=(9.87e+06, 1.87e+07) valuediff=0.00e+00 gradrel=1.24e-16
large    p=1024 n= 256 K=2 dense=  0.1342 s lemma=  0.1235 s speedup= 1.09x bytes=(3.86e+07, 7.31e+07) valuediff=0.00e+00 gradrel=1.60e-16
xlarge   p=2048 n= 512 K=2 dense=  1.0541 s lemma=  0.4880 s speedup= 2.16x bytes=(1.53e+08, 2.89e+08) valuediff=0.00e+00 gradrel=1.72e-16
```

Interpretation: exact lemma is slower on the smoke cell but faster on the
medium-to-xlarge gradient cells. It currently allocates more memory than dense,
so it is not the final 100x path; it is a verified exact large-p direction.

## R-Parity Verdict

Parity: N/A - this is an internal Julia structured Poisson algorithm route, not
a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: benchmark records higher allocations for lemma than dense.
- Aqua: clean through the `Pkg.test()` quality gate.

## CI And Bootstrap Status

No confidence-interval, bootstrap, or public CI configuration code was edited.
The full package suite still exercises the current CI/bootstrap tests. No
branch CI was triggered because this local branch was not pushed.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 165 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2374 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2386 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-lemma-gradient.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-lemma-gradient.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
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
  Gaussian/gllvmTMB claims, and this internal exact lemma-gradient speed
  evidence only; no public 100x structured speed claim or new R `gllvmTMB`
  parity claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## GitHub Issue Maintenance

No issue action was taken. This is an internal structured Poisson algorithm
slice and does not change public family/API support.

## What Did Not Go Smoothly

The first site-by-site Woodbury implementation was exact but not faster at
xlarge. Batching all site-loading RHS columns made the route faster for the
medium-to-xlarge benchmark cells, at the cost of higher allocation.

## Team Learning

Gauss/Karpinski: exact Woodbury needs batched RHS application to beat dense
inverse materialization. Fisher: value and gradient agreement are roundoff-level
against the exact dense block target.

## Remaining Risks

- The lemma path allocates more memory than dense in the current benchmark.
- The route is opt-in and supports the determinant-lemma `K <= 3` path.
- The route is exact but still internal; public API/docs are intentionally not
  promoted.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no default `:auto` policy change.

## Next Command

```sh
julia --project=. --startup-file=no test/runtests.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - exact lemma gradient is verified and faster on
medium-to-xlarge benchmark cells, but it allocates more memory and remains
opt-in/internal.
