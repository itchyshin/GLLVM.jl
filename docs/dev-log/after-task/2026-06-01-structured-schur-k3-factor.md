# After Task: Structured Schur K3 Factor

## Goal

Remove generic tiny Cholesky overhead from the `K == 3` exact
determinant-lemma path.

## Implemented

`_schur_u_tinyk_factor!` now writes the `K == 3` lower Cholesky factor of each
site-level `A_s^{-1}` by closed form, matching the existing `K == 1` and
`K == 2` specializations. The Schur tests now verify each tiny-`K` site factor
directly against `B_s A_s^{-1} B_s'`. No public API, fitter default, likelihood
parameterization, confidence-interval, bootstrap, or R-parity surface changed.

## Mathematical Contract

For `K == 3`, the site factor still satisfies `F_s F_s' = A_s^{-1}` and the
assembled block contribution is unchanged:

```text
C_s C_s' = B_s A_s^{-1} B_s'
```

where `B_s = diag(W[:, s]) * Lambda`. The new code only replaces
`cholesky(Symmetric(A_s^{-1})).L` with the equivalent scalar lower-factor
formula.

## Files Changed

- `src/structured_schur.jl` - added closed-form `K == 3` lower-factor path.
- `test/test_structured_schur.jl` - added direct per-site tiny-factor checks.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-schur-k3-factor.md` - this
  report.

## Tests Added

The structured Schur operator test now checks, for `K = 1, 2, 3` and each site,
that the factor produced by `_schur_u_tinyk_factor!` satisfies
`C_s C_s' ≈ B_s A_s^{-1} B_s'`.

## Benchmark Numbers

Baseline K=3 scout before this change:

```text
frontier p= 640 n= 160 K=3 factor=0.00046 s bytes=4.35e+04 lemma=0.00507 s dense=0.00443 s dense/lemma=0.87x
giant    p=1024 n= 256 K=3 factor=0.00116 s bytes=6.96e+04 lemma=0.00952 s dense=0.01479 s dense/lemma=1.55x
xlarge   p=2048 n= 512 K=3 factor=0.00464 s bytes=1.39e+05 lemma=0.05562 s dense=0.07578 s dense/lemma=1.36x
```

After closed-form `K == 3` factor:

```text
frontier p= 640 n= 160 K=3 factor=0.00009 s bytes=0.00e+00 lemma=0.00383 s dense=0.00259 s dense/lemma=0.68x
giant    p=1024 n= 256 K=3 factor=0.00032 s bytes=0.00e+00 lemma=0.01114 s dense=0.01098 s dense/lemma=0.99x
xlarge   p=2048 n= 512 K=3 factor=0.00130 s bytes=0.00e+00 lemma=0.04694 s dense=0.06841 s dense/lemma=1.46x
```

Repo benchmark:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --break-even --cells=giant,xlarge --reps=3 --warmups=2 --out=/tmp/structured-schur-logdet-k3factor-2026-06-01.csv
```

Result:

```text
giant  p=1024 n=256 K=3 dense=0.0136 s lemma=0.0126 s slq=0.2406 s dense/lemma=1.08x lemma_relerr=1.587e-15 slq_relerr=3.181e-04
xlarge p=2048 n=512 K=3 dense=0.1189 s lemma=0.0880 s slq=1.0137 s dense/lemma=1.35x lemma_relerr=1.551e-15 slq_relerr=2.610e-04
```

Interpretation: the tiny-factor step itself is about 3.6x-5.1x faster and
allocates zero bytes in the scout. The full exact lemma logdet is faster than
dense in the benchmark giant/xlarge cells and exact to roundoff; SLQ is still
slower at these sizes.

## R-Parity Verdict

Parity: N/A - internal structured Schur determinant substrate only. This does
not touch R `gllvmTMB` comparison surfaces.

## JET / Allocs / Aqua Verdicts

- JET: clean through full `Pkg.test()` quality battery.
- Allocs: K=3 factor scout went from nonzero allocation to zero allocation.
- Aqua: clean through full `Pkg.test()` quality battery.

## CI And Bootstrap Status

No confidence-interval, bootstrap, public CI, package metadata, or public docs
changed. No branch CI was run because this branch was not pushed.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 183 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2397 pass, 3 expected broken placeholders, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2409 pass, 1 existing sparse-phy precision placeholder, 0 fail,
0 error. The `quality` testset passed 12/12.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "K3 Factor|K == 3|l31|l32|l33|structured-schur-logdet-k3factor" src/structured_schur.jl test/test_structured_schur.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-k3-factor.md
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean for the guard patterns used in this audit.
- K3 factor scan: expected current source/report hits only.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## GitHub Issue Maintenance

No issue action was taken. This is an internal structured fast-algorithm slice.

## What Did Not Go Smoothly

The micro-scout showed noisy full-logdet timings even though the factor itself
was clearly faster. The repo benchmark was therefore used as the deciding
evidence.

## Team Learning

Karpinski: tiny `K` specializations pay off most when they avoid allocation
inside repeated site loops. Gauss: exact lemma remains the better large-cell
path than SLQ at these K=3 benchmark sizes, but dense can still win at the
frontier cell.

## Remaining Risks

- This is a constant-factor improvement, not the final very-large-`p` SLQ
  breakthrough.
- The exact lemma route is still not the public default for structured
  non-Gaussian user APIs.
- Dense can still beat lemma at smaller frontier cells.

## Known Limitations

No public formula/API support changed, no R parity claim was added, and no
adaptive dense/lemma/SLQ policy changed.

## Next Command

```sh
git status --short --branch
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - exactness and full tests are clean, and K=3 factor overhead is lower, but this is a constant-factor internal substrate improvement.
