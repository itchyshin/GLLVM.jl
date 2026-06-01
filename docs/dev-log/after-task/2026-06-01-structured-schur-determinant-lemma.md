# After Task: Structured Schur Determinant Lemma

## Goal

Add an exact structured Schur determinant alternative after higher-accuracy SLQ
proved slower while still approximate on the `xlarge` structured Poisson cell.

## Implemented

`_schur_u_logdet(op; method = :lemma)` now computes the exact Schur logdet via
a determinant-lemma factorization. The implementation reuses the tiny-`K`
site-factor matrix `C`, factors the sparse/dense base matrix
`B = sigma2^-1 Q + diag(sum_s w_s)`, forms `I - C' B^-1 C`, and adds the two
log-determinants. The default `:auto` policy is unchanged; this is an internal
candidate path for the structured determinant lane.

## Mathematical Contract

The Schur complement is written as

```text
S_u = B - C C',
B = sigma2^-1 Q + diag(sum_s w_s),
C_s = D_s Lambda F_s,
F_s F_s' = A_s^-1,
A_s = I_K + Lambda' D_s Lambda.
```

Then

```text
logdet(S_u) = logdet(B) + logdet(I - C' B^-1 C).
```

The tests compare this value against direct dense `logdet(S_u)`.

## Files Changed

- `src/structured_schur.jl` - added base-matrix construction, reusable tiny-`K`
  site-factor fill, and `_schur_u_logdet_lemma`.
- `test/test_structured_schur.jl` - added dense/sparse precision lemma logdet
  checks plus the `K > 3` guardrail.
- `bench/structured_schur_logdet_bench.jl` - records dense, lemma, and SLQ
  timing/error/bytes columns.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-schur-determinant-lemma.md` -
  this audit report.

## Tests Added

Three structured Schur logdet checks were added: dense precision lemma vs
dense logdet, sparse precision lemma vs dense logdet, and a malformed-use guard
for `K > 3`.

## Benchmark Numbers

SLQ calibration probe:

```text
xlarge   p=2048 n= 512 K=2 dense=  0.8562 s  slq=  2.5396 s  speedup=   0.34x  valuediff=3.73e-01  gradrel=1.17e-01
```

Durable Schur logdet benchmark:

```text
smoke    p=  80 n=  12 K=2 dense=  0.0001 s  lemma=  0.0001 s  slq=  0.0003 s  dense/lemma=   1.69x  dense/slq=   0.48x  lemma_relerr=0.000e+00  slq_relerr=5.371e-03
giant    p=1024 n= 256 K=3 dense=  0.0116 s  lemma=  0.0101 s  slq=  0.2415 s  dense/lemma=   1.15x  dense/slq=   0.05x  lemma_relerr=1.587e-15  slq_relerr=3.181e-04
xlarge   p=2048 n= 512 K=3 dense=  0.1159 s  lemma=  0.0666 s  slq=  1.0721 s  dense/lemma=   1.74x  dense/slq=   0.11x  lemma_relerr=1.551e-15  slq_relerr=2.610e-04
```

Current-method K=2 probe:

```text
p=1024 n=256 K=2 dense=0.01502425 lemma=0.005754917 dense/lemma=2.610680571066446 absdiff=9.094947017729282e-13
p=2048 n=512 K=2 dense=0.091694896 lemma=0.0296673545 dense/lemma=3.090767530350574 absdiff=1.6370904631912708e-11
```

The determinant lemma is exact to roundoff and faster than dense logdet on the
tested cells. It allocates more memory than dense logdet in the benchmark CSV
because it forms `C`, `B\\C`, and the `K*n` determinant matrix.

## R-Parity Verdict

Parity: N/A - this is an internal structured Schur determinant substrate, not a
public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: no allocation-reduction claim; benchmark CSV records lemma bytes and
  the path currently trades more memory for exact speed.
- Aqua: clean through the `Pkg.test()` quality gate.

## CI And Bootstrap Status

No confidence-interval, bootstrap, or public CI configuration code was edited.
The full suite still exercises the current CI/bootstrap tests. No branch CI was
triggered because this local branch was not pushed.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 150 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2359 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2371 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-determinant-lemma.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-determinant-lemma.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
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
  Gaussian/gllvmTMB claims, and this internal determinant-lemma speed evidence
  only; no public 100x structured speed claim or new R `gllvmTMB` parity claim
  was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## GitHub Issue Maintenance

No issue action was taken. This is an internal algorithm substrate and benchmark
slice; it does not change public family support or R parity surfaces.

## What Did Not Go Smoothly

The first prototype attempted in-place `ldiv!` with a CHOLMOD factor and dense
matrix RHS, which Julia 1.10 does not support for that factor type. The
implemented path uses `FB \\ C`, which is clear and correct but allocates.

## Team Learning

Gauss/Karpinski: the exact dense path was already strong, but the determinant
lemma gives a second exact option when `K*n` is smaller than `p` or when sparse
base solves are cheap. Fisher: this is a better near-term answer than throwing
more probes at an inaccurate SLQ trace-gradient.

## Remaining Risks

- This is logdet-only; fitted gradients still need a matching inverse/trace
  derivation before `:auto` should route to it.
- The method currently supports `K <= 3`.
- Memory use is higher than dense logdet in the current implementation.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no non-Gaussian CI/bootstrap implementation changed in this slice.

## Next Command

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl")'
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - determinant-lemma logdet is exact and faster on
tested cells, but remains an internal logdet-only candidate until the gradient
path has matching Woodbury inverse/trace support.
