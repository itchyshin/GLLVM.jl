# After Task: Woodbury Diagonal Triangular Correction

## Goal

Speed up the exact Woodbury inverse-diagonal helper used by structured Schur
and structured Poisson determinant-lemma experiments.

## Implemented

`_schur_u_woodbury_inv_diag` now computes the Woodbury diagonal correction with
one triangular solve. For `H = L * L'`, the correction
`diag(BinvC * H^-1 * BinvC')` is evaluated as columnwise
`sum(abs2, L \\ BinvC')`. A CHOLMOD column-wise base-solve alternative was
benchmarked and rejected because it was slower and allocated more.

## Mathematical Contract

The helper still computes:

```text
diag(S_u^-1) = diag(B^-1) + diag(B^-1 C H^-1 C' B^-1),
H = I - C' B^-1 C.
```

Only the dense `H` correction is rearranged using
`b' H^-1 b = ||L \\ b||^2` for the Cholesky factor `H = L * L'`.

## Files Changed

- `src/structured_schur.jl` - use the triangular norm identity for the
  Woodbury diagonal correction.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-woodbury-diag-triangular.md` - this
  audit report.

## Tests Added

No new tests were needed because the existing structured Schur test checks the
dense and sparse Woodbury inverse diagonal against `diag(inv(S_u))`, and the
structured Poisson test exercises the exact lemma-gradient route that calls the
helper.

## Benchmark Numbers

Discarded CHOLMOD column-wise base-solve probe:

```text
cholmod_batch p=512 n=128 K=2 current=0.002258 colwise=0.002681 speedup=0.84x bytes=(6.82e+06, 9.07e+06) err=6.94e-18
```

Woodbury inverse-diagonal helper microbenchmark:

```text
woodbury_diag_tri p=512 n=128 K=2 old=0.002649 new=0.000719 speedup=3.68x bytes=(1.13e+06, 1.65e+06) err=1.73e-18
woodbury_diag_tri p=1024 n=256 K=2 old=0.006510 new=0.003240 speedup=2.01x bytes=(4.35e+06, 6.45e+06) err=1.73e-18
woodbury_diag_tri p=2048 n=512 K=2 old=0.026719 new=0.014880 speedup=1.80x bytes=(1.71e+07, 2.55e+07) err=8.67e-19
```

Structured Poisson exact lemma-gradient rerun:

```text
medium   p= 512 n= 128 K=2 dense=  0.0351 s lemma=  0.0286 s speedup= 1.23x bytes=(9.87e+06, 1.87e+07) valuediff=0.00e+00 gradrel=1.21e-16
large    p=1024 n= 256 K=2 dense=  0.1167 s lemma=  0.1092 s speedup= 1.07x bytes=(3.86e+07, 7.31e+07) valuediff=0.00e+00 gradrel=1.71e-16
xlarge   p=2048 n= 512 K=2 dense=  0.7969 s lemma=  0.4118 s speedup= 1.94x bytes=(1.53e+08, 2.89e+08) valuediff=0.00e+00 gradrel=1.73e-16
```

## R-Parity Verdict

Parity: N/A - this is an internal Julia structured Schur linear algebra helper,
not a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the full `Pkg.test()` quality battery.
- Allocs: helper runtime improved, but helper allocation rose; the
  lemma-gradient route remains memory-heavier than dense.
- Aqua: clean through the full `Pkg.test()` quality battery.

## CI And Bootstrap Status

No confidence-interval, bootstrap, or public CI configuration code was edited.
The full package suite passed locally after this slice. No branch CI was run
because this branch was not pushed.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 165 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2379 pass, 3 broken placeholders, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2391 pass, 1 existing broken sparse-phy precision placeholder,
0 fail, 0 error. The `quality` testset passed 12/12.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-woodbury-diag-triangular.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-woodbury-diag-triangular.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean for the pending/rerun guard patterns.
- Stale-wording scan: expected historical and command-pattern hits only; no
  public API/status claim changed by this internal helper cleanup.
- Performance-claim scan: expected existing Gaussian/gllvmTMB and internal
  benchmark-log hits only; no public 100x structured speed claim was added.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## GitHub Issue Maintenance

No issue action was taken. This is an internal allocation/speed cleanup and
does not change public support.

## What Did Not Go Smoothly

The first CHOLMOD column-wise solve idea was slower than the current matrix RHS
solve and allocated more, so it was rejected. The triangular diagonal identity
is faster but currently increases helper allocation.

## Team Learning

Gauss: use the Cholesky factor identity directly for quadratic diagonal terms.
Karpinski: avoid column-wise CHOLMOD solves unless a benchmark proves they win.

## Remaining Risks

- The helper speedup does not solve the lemma route's larger memory footprint.
- The exact lemma route is still opt-in; no default-policy change is justified.
- The helper speedup increases isolated helper allocation, so the broader
  memory budget still needs work.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no default policy change.

## Next Command

```sh
git status --short --branch
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - exactness and tests are clean, but this helper speedup increases isolated helper allocation and does not justify changing the lemma route default.
