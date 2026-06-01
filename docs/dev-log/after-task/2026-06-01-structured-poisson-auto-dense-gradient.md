# After Task: Structured Poisson Auto Dense Gradient

## Goal

Make `logdet_method = :auto` use the fast exact dense structured-Poisson
implicit gradient whenever the Schur determinant is below the dense cutoff.

## Implemented

`_structured_poisson_implicit_value_grad` now routes `:auto` with
`p <= dense_cutoff` to `_structured_poisson_block_implicit_value_grad`, matching
the exact dense determinant choice made by the Schur logdet layer. The old
ForwardDiff implicit-gradient scaffold remains only as a fallback for other
method combinations. Public API and fit-object behavior are unchanged.

## Mathematical Contract

No likelihood parameterization changed. For fixed structured precision `Q`, the
code still differentiates the same Laplace approximation at the joint mode,
`q(theta, x) = ell(y | theta, x) - 0.5 u'Q u / sigma2 - 0.5 sum_i z_i'z_i -
0.5 logdet(H)`, using the envelope/implicit-gradient identity. This slice only
aligns the `:auto` branch with the exact dense Schur determinant already chosen
for `p <= dense_cutoff`; it does not introduce any private-source provenance or
new citation requirement.

## Files Changed

- `src/families/structured_poisson.jl` - route small/medium `:auto` gradients to
  the dense block implicit-gradient path.
- `test/test_structured_poisson_laplace.jl` - assert `:auto` value/gradient
  equality with the exact dense path and add a generous allocation guard that
  catches the old AD fallback.
- `docs/dev-log/check-log.md` - record tests, benchmark, hygiene scans, and
  lane status.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-auto-dense-gradient.md`
  - this audit report.

## Tests Added

Added four assertions in `structured Poisson implicit gradient`: `:auto` value
equals dense block value, `:auto` gradient entries are finite, `:auto` gradient
matches the dense block gradient to `1e-10`, and a small fixed cell allocates
less than 200 KB on the auto path. The allocation guard would have failed under
the old route: the old AD scaffold allocated about 445 KB on this tiny test
cell, while the routed path allocated about 13 KB in the same shape.

## Benchmark Numbers

Maintainer Mac, fixed-seed warmed `time_ns` probe, `p = 8`, `n = 12`, `K = 2`:

```text
p=8 n=12 K=2 old_ad_auto=0.000429 s fast_auto=8.762e-5 s speedup=4.896x valuediff=0.0 gradmax=1.11e-15
old_alloc_bytes=3936824 new_alloc_bytes=31168 allocation_reduction=126.3x
```

Interpretation: this is a narrow route fix that removes an accidental AD
fallback below the dense cutoff. It is not an R `gllvmTMB` comparison and not a
new 100x public speed claim.

## R-Parity Verdict

Parity: N/A - this is an internal fixed-covariance structured Poisson prototype
path, not a public `gllvmTMB`-equivalent fitter surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: improved on the fixed probe from 3,936,824 bytes to 31,168 bytes;
  test guard keeps the tiny auto path below 200 KB.
- Aqua: clean through the `Pkg.test()` quality gate.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 117 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2331 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2343 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-auto-dense-gradient.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-auto-dense-gradient.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal structured Poisson route-fix
  evidence only.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## GitHub Issue Maintenance

No issue action was taken. This is a private internal structured-Poisson route
fix and does not touch the public PR #59 formula/family/CIs work.

## What Did Not Go Smoothly

`BenchmarkTools` is not available in the active package environment, so the
microbenchmark used a warmed `time_ns` loop plus `@allocated` instead of adding
or modifying dependencies.

## Team Learning

Karpinski/Gauss: after raising an `:auto` cutoff, check every caller that makes
an independent algorithm decision. The determinant path was exact dense, but
the gradient dispatcher still paid the older AD scaffold until this route was
aligned.

## Remaining Risks

- This is a small/medium exact-dense route fix; it does not solve the large-p
  SLQ trace-gradient algorithm.
- The allocation guard is intentionally generous and checks route shape, not a
  formal zero-allocation contract.
- This remains an internal fixed-covariance structured Poisson prototype.

## Known Limitations

No public structured non-Gaussian API, no R `gllvmTMB` parity benchmark, and no
new confidence-interval or bootstrap work is included in this slice.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=implicit
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the `:auto` gradient route is now aligned with
the exact dense cutoff and locally verified; remaining notes are limited to
large-p SLQ and public API/parity work.
