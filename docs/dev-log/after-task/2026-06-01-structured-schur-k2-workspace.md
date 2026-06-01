# After Task: Structured Schur K2 Workspace

## Goal

Trim overhead in the exact determinant-lemma/Woodbury path used by the internal
structured Poisson gradient.

## Implemented

The structured Schur tiny-`K` factor builder now uses a closed-form lower
factor for `K == 2` instead of calling a generic tiny Cholesky for every site.
The Woodbury inverse helper also has a workspace overload for reusing
`B^{-1}V` and correction-RHS storage, and the structured Poisson exact lemma
gradient uses that overload for chunked site RHS blocks. No public API or
default fitter policy changed.

## Mathematical Contract

For `K == 2`, the site factor still satisfies
`F_s F_s' = A_s^{-1}`. The new code writes the same lower Cholesky factor by
formula:

```text
l11 = sqrt(a11)
l21 = a21 / l11
l22 = sqrt(a22 - l21^2)
```

where `A_s^{-1} = [a11 a12; a21 a22]`. The Woodbury solve remains
`S_u^{-1}V = B^{-1}V + B^{-1}C H^{-1} C'B^{-1}V`; the change only reuses
scratch matrices for repeated calls.

## Files Changed

- `src/structured_schur.jl` - added `K == 2` closed-form factor path and
  workspace-aware Woodbury inverse apply.
- `src/families/structured_poisson.jl` - reused Woodbury apply workspaces across
  exact lemma-gradient chunks.
- `test/test_structured_schur.jl` - added workspace-overload correctness and
  dimension-guard tests.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-schur-k2-workspace.md` - this
  report.

## Tests Added

Three Schur tests were added: workspace-overload inverse apply agreement with
the dense solve, malformed `BinvV` workspace dimensions, and malformed RHS
workspace dimensions.

## Benchmark Numbers

Exact structured Poisson dense-vs-lemma gradient benchmark:

```sh
julia --project=. --startup-file=no bench/structured_poisson_lemma_gradient_bench.jl --break-even --reps=2 --warmups=1 --out=/tmp/structured-poisson-lemma-gradient-k2factor-workspace-2026-06-01.csv
```

Result:

```text
medium   p= 512 n= 128 K=2 dense=0.0317 s lemma=0.0288 s speedup=1.10x bytes=(9.85e+06, 1.97e+07) valuediff=0.00e+00 gradrel=1.20e-16
large    p=1024 n= 256 K=2 dense=0.1253 s lemma=0.1105 s speedup=1.13x bytes=(3.86e+07, 6.99e+07) valuediff=0.00e+00 gradrel=1.73e-16
xlarge   p=2048 n= 512 K=2 dense=0.7084 s lemma=0.4419 s speedup=1.60x bytes=(1.53e+08, 2.61e+08) valuediff=0.00e+00 gradrel=1.64e-16
```

Higher-rep spot check:

```sh
julia --project=. --startup-file=no bench/structured_poisson_lemma_gradient_bench.jl --break-even --cells=large,xlarge --reps=5 --warmups=2 --out=/tmp/structured-poisson-lemma-gradient-workspace-large-xlarge-reps5-2026-06-01.csv
```

Result:

```text
large    p=1024 n= 256 K=2 dense=0.1200 s lemma=0.1101 s speedup=1.09x bytes=(3.86e+07, 6.99e+07) valuediff=0.00e+00 gradrel=1.44e-16
xlarge   p=2048 n= 512 K=2 dense=0.8349 s lemma=0.5128 s speedup=1.63x bytes=(1.53e+08, 2.61e+08) valuediff=0.00e+00 gradrel=1.99e-16
```

The exact lemma path remains memory-heavier than dense but is faster in the
large and xlarge cells, with gradient agreement at roundoff scale.

## R-Parity Verdict

Parity: N/A - internal Julia structured Schur/Poisson prototype only. This does
not touch R `gllvmTMB` parity surfaces or non-Gaussian public fitters.

## JET / Allocs / Aqua Verdicts

- JET: clean through full `Pkg.test()` quality battery.
- Allocs: benchmark bytes recorded above; the lemma path still allocates more
  than dense but reuses per-chunk Woodbury solve workspaces.
- Aqua: clean through full `Pkg.test()` quality battery.

## CI And Bootstrap Status

No confidence-interval, bootstrap, public CI, or package metadata code changed.
No branch CI was run because this branch was not pushed.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 168 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2382 pass, 3 expected broken placeholders, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2394 pass, 1 existing sparse-phy precision placeholder, 0 fail,
0 error. The `quality` testset passed 12/12.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "mode_solve = :woodbury|mode_solve=:woodbury|K2 Workspace|k2factor|workspace" src/structured_schur.jl src/families/structured_poisson.jl test/test_structured_schur.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-k2-workspace.md
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean for the guard patterns used in this audit.
- Workspace scan: expected current helper/report hits plus older historical
  workspace ledger rows. The pre-existing exact lemma adjoint still calls the
  joint solve with `mode_solve = :woodbury`; the rejected inner-mode solver
  branch and fitter option do not remain.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## GitHub Issue Maintenance

No issue action was taken. This is an internal structured fast-algorithm slice.

## What Did Not Go Smoothly

An exact `mode_solve = :woodbury` scout was tested and rejected before this
commit. It matched dense to roundoff but was slower than CG on medium/large
cells and used more memory, so it was removed from the worktree.

## Team Learning

Karpinski: avoid tiny generic factorizations in site loops when `K == 2` has a
closed form. Gauss: workspace reuse helps bound chunk churn, but CG remains the
right mode-solve default for the fitted structured prototype.

## Remaining Risks

- The exact lemma route is still memory-heavier than the dense route in this
  benchmark grid.
- This is an internal prototype path, not public structured non-Gaussian API.
- The true very-large-`p` break-even for SLQ versus exact lemma remains a
  separate benchmark question.

## Known Limitations

No public fitter default changed, no R parity claim was added, and no structured
family formula interface was exposed.

## Next Command

```sh
git status --short --branch
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - exactness and full tests are clean, and the lemma path is faster on large/xlarge cells, but it remains memory-heavier than dense.
