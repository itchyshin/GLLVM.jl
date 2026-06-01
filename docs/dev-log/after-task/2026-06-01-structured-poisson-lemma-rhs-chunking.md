# After Task: Structured Poisson Lemma RHS Chunking

## Goal

Reduce scratch allocation in the exact structured Poisson determinant-lemma
gradient route without changing the likelihood or public API.

## Implemented

The `logdet_method = :lemma` block-gradient path now fills and applies
site-loading RHS matrices in chunks of at most 256 columns. This avoids
materializing all `K * n` RHS columns at once while still using the exact
Woodbury inverse helper. A 512-column chunk probe was benchmarked and rejected
because it saved less memory and was slower in the xlarge cell.

## Mathematical Contract

For each site `i`, the trace block still needs
`C_i = U_i' S_u^-1 U_i`, where `U_i = diag(W[:, i]) * Lambda`. The change only
batches the construction and application of the `U_i` matrices:

```text
S_u^-1 [U_1 ... U_n]
```

is now evaluated in contiguous chunks. The exact `S_u^-1` operator and all
site-level contractions are unchanged.

## Files Changed

- `src/families/structured_poisson.jl` - chunk exact lemma-gradient RHS
  construction and inverse application.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-lemma-rhs-chunking.md`
  - this audit report.

## Tests Added

No new tests were needed because the existing structured Poisson tests compare
the exact lemma-gradient value/gradient against the dense route and exercise the
internal fitter. This slice changes batching only, not the equations.

## Benchmark Numbers

256-column chunk benchmark:

```text
medium   p= 512 n= 128 K=2 dense=  0.0332 s lemma=  0.0311 s speedup= 1.07x bytes=(9.87e+06, 1.87e+07) valuediff=0.00e+00 gradrel=1.21e-16
large    p=1024 n= 256 K=2 dense=  0.1847 s lemma=  0.1111 s speedup= 1.66x bytes=(3.86e+07, 6.89e+07) valuediff=0.00e+00 gradrel=1.71e-16
xlarge   p=2048 n= 512 K=2 dense=  0.8321 s lemma=  0.4542 s speedup= 1.83x bytes=(1.53e+08, 2.64e+08) valuediff=0.00e+00 gradrel=1.73e-16
```

Rejected 512-column chunk probe:

```text
medium   p= 512 n= 128 K=2 dense=  0.0327 s lemma=  0.0282 s speedup= 1.16x bytes=(9.87e+06, 1.87e+07) valuediff=0.00e+00 gradrel=1.21e-16
large    p=1024 n= 256 K=2 dense=  0.1293 s lemma=  0.1050 s speedup= 1.23x bytes=(3.86e+07, 7.31e+07) valuediff=0.00e+00 gradrel=1.71e-16
xlarge   p=2048 n= 512 K=2 dense=  0.8257 s lemma=  0.4768 s speedup= 1.73x bytes=(1.53e+08, 2.72e+08) valuediff=0.00e+00 gradrel=1.73e-16
```

## R-Parity Verdict

Parity: N/A - this is an internal Julia structured Poisson exact-gradient
batching change, not a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the full `Pkg.test()` quality battery.
- Allocs: improved for the xlarge exact lemma-gradient benchmark, but still
  memory-heavier than dense.
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
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-lemma-rhs-chunking.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-lemma-rhs-chunking.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean for the pending/rerun guard patterns.
- Stale-wording scan: expected historical and command-pattern hits only; no
  public API/status claim changed by this internal memory cleanup.
- Performance-claim scan: expected existing Gaussian/gllvmTMB and internal
  benchmark-log hits only; no public 100x structured speed claim was added.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## GitHub Issue Maintenance

No issue action was taken. This is an internal exact-gradient memory cleanup and
does not change public support.

## What Did Not Go Smoothly

Chunk size is a real tradeoff. The 512-column variant had slightly better medium
timing but worse xlarge timing and allocation, so the smaller 256-column cap was
kept.

## Team Learning

Karpinski: chunk the memory pressure, but benchmark the BLAS batching loss
before claiming a win. Gauss: exact Woodbury batching can be rearranged without
changing the site-level trace contractions.

## Remaining Risks

- The lemma route remains memory-heavier than dense in these benchmark cells.
- This is still an opt-in exact fast-algorithm path, not a default-policy change.
- Chunking slightly reduces BLAS batching in the largest cell, so the setting
  should stay internal until broader benchmark evidence accumulates.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no default policy change.

## Next Command

```sh
git status --short --branch
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - exactness and tests are clean, but this is an internal memory-budget cleanup and does not justify changing the lemma route default.
