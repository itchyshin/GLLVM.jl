# After Task: Woodbury Apply Correction In-Place

## Goal

Trim allocation in the exact Woodbury inverse-apply helper used by structured
Schur and structured Poisson determinant-lemma experiments.

## Implemented

`_schur_u_woodbury_inv_apply!` now overwrites the small `C'B^-1V` RHS buffer
with the solution of the Woodbury correction system instead of allocating a
separate correction matrix. The base solve remains unchanged, which keeps the
sparse CHOLMOD fallback safe.

## Mathematical Contract

The helper still computes:

```text
S_u^-1 V = B^-1 V + B^-1 C (I - C' B^-1 C)^-1 C' B^-1 V.
```

Only the temporary storage for `(I - C'B^-1C)^-1 C'B^-1V` changed.

## Files Changed

- `src/structured_schur.jl` - solve the small Woodbury correction in-place.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-woodbury-apply-correction-inplace.md` -
  this audit report.

## Tests Added

No new tests were needed because the existing structured Schur test already
checks dense and sparse Woodbury inverse-apply against dense `S_u \ R`, and the
structured Poisson test exercises the lemma-gradient route that calls this
helper.

## Benchmark Numbers

Dense-base helper microbenchmark:

```text
dense_base_apply p=512 n=128 K=2 old=0.003497 new=0.003417 speedup=1.02x old_bytes=3145920 new_bytes=2621584 alloc_reduction=1.20x err=0.00e+00
```

Structured Poisson exact lemma-gradient rerun:

```text
medium   p= 512 n= 128 K=2 dense=  0.0717 s lemma=  0.0458 s speedup= 1.57x bytes=(9.87e+06, 1.82e+07) valuediff=0.00e+00 gradrel=1.24e-16
large    p=1024 n= 256 K=2 dense=  0.1962 s lemma=  0.1227 s speedup= 1.60x bytes=(3.86e+07, 7.10e+07) valuediff=0.00e+00 gradrel=1.60e-16
xlarge   p=2048 n= 512 K=2 dense=  0.9555 s lemma=  0.5032 s speedup= 1.90x bytes=(1.53e+08, 2.80e+08) valuediff=0.00e+00 gradrel=1.72e-16
```

## R-Parity Verdict

Parity: N/A - this is an internal Julia structured Schur linear algebra helper,
not a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the full `Pkg.test()` quality battery.
- Allocs: improved for the helper microbenchmark; lemma-gradient route still
  allocates more than dense.
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
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-woodbury-apply-correction-inplace.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-woodbury-apply-correction-inplace.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
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

No issue action was taken. This is an internal allocation cleanup and does not
change public support.

## What Did Not Go Smoothly

An attempted dense output-reuse path reduced allocation further but made dense
apply slower and was not kept. CHOLMOD does not support matrix `ldiv!`, so the
sparse base solve remains on the previous safe allocation path.

## Team Learning

Karpinski: do not trade time for allocation unless it helps the fitted
large-p route. Gauss: the small correction solve can be made in-place safely
without touching the base solve.

## Remaining Risks

- Sparse CHOLMOD base solves still allocate for matrix RHS.
- This is a small helper cleanup, not a 100x path.
- Lemma-gradient route still allocates more than the dense route in the current
  benchmark cells, so this is not yet the default path.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no default policy change.

## Next Command

```sh
git status --short --branch
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - exactness and tests are clean, but this is a small helper allocation cleanup and the lemma-gradient route still has a memory budget to solve before changing defaults.
