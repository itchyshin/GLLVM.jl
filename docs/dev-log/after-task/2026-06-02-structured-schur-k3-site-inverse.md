# After Task: Structured Schur K3 Site Inverse

## Goal

Remove the generic tiny Cholesky setup from the `K == 3` structured Schur site
inverse/logdet constructor.

## Implemented

`_SchurUOperator` now has a `K == 3` scalar branch that accumulates the six
unique entries of each site matrix, computes its determinant and adjugate
entries directly, stores `A_s^-1`, and records `logdet(A_s)`. The change is
internal to the structured Schur determinant-lemma/Woodbury substrate.

## Mathematical Contract

For each site `s`, the operator needs
`A_s = I_K + Lambda' diag(w_s) Lambda`. For `K == 3`, the implementation writes
the symmetric inverse as `A_s^-1 = adj(A_s) / det(A_s)` and
`logdet(A_s) = log(det(A_s))`. This preserves the existing exact Schur
determinant-lemma contract; it changes only how the small site matrix is built
and inverted.

## Files Changed

- `src/structured_schur.jl` - added the closed-form `K == 3` site inverse and
  logdet branch.
- `test/test_structured_schur.jl` - added a workspace sentinel check proving the
  `K == 3` path bypasses the generic `Amats` construction while preserving
  dense Schur equivalence.
- `docs/dev-log/check-log.md` - added this task's verification log.
- `docs/dev-log/after-task/2026-06-02-structured-schur-k3-site-inverse.md` -
  this audit.

## Tests Added

Two assertions were added to `test/test_structured_schur.jl`.

- Dense equivalence for a workspace-backed `K == 3` operator exercises the new
  branch beside the existing allocating constructor checks.
- The `NaN` sentinel on `ws.Amats` would fail before this change because the
  generic branch materialized and factorized those buffers for `K == 3`.

Existing tests already compare every stored `K == 3` `A_s^-1` and `logdet(A_s)`
against an independent dense/Cholesky calculation at `1e-12`.

## Benchmark Numbers

Measured on the maintainer's Mac using a detached `HEAD` worktree at `3cd756d`
as baseline and the current working tree as the candidate.

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --break-even --cells=giant,xlarge --reps=3 --warmups=2 --out=/tmp/structured-schur-k3ainv-baseline-2026-06-02.csv
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --break-even --cells=giant,xlarge --reps=3 --warmups=2 --out=/tmp/structured-schur-k3ainv-current-2026-06-02.csv
```

Constructor timing:

```text
giant  baseline=0.004299 s current=0.000370 s speedup=11.61x
xlarge baseline=0.017711 s current=0.001396 s speedup=12.69x
```

Constructor allocations:

```text
giant  baseline=80432 bytes current=80432 bytes
xlarge baseline=160304 bytes current=160304 bytes
```

Current exact-logdet check:

```text
giant  dense=0.011113 s lemma=0.024175 s lemma_relerr=1.587e-15
xlarge dense=0.089015 s lemma=0.054723 s lemma_relerr=1.551e-15
```

Verdict: constructor speedup with stable constructor allocations. End-to-end
lemma timing is mixed in this short benchmark, but exact values remain at
roundoff relative error.

## R-Parity Verdict

Parity: N/A - internal structured Schur small-matrix construction only. The
Gaussian marginal likelihood, parameter packing, fitter surface, and public
R-parity scaffold were not changed.

## JET / Allocs / Aqua Verdicts

- JET: clean via `Pkg.test()` `quality` testset 12/12.
- Allocs: stable for the constructor in the giant/xlarge fixtures.
- Aqua: clean via `Pkg.test()` `quality` testset 12/12.

## Checks Run

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 185 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: 2399 pass, 3 expected broken placeholders, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: 2411 pass, 1 existing sparse-phy precision placeholder, 0 fail, 0
error. The `quality` testset passed 12/12.

## Consistency Audit

Patterns run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "[T]ODO|[F]IXME|[T]BD|[P]LACEHOLDER|[p]ending" docs/dev-log/after-task/2026-06-02-structured-schur-k3-site-inverse.md
rg -n "K3 Site Inverse|K == 3|c11|c12|c13|detA|structured-schur-k3ainv" src/structured_schur.jl test/test_structured_schur.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-02-structured-schur-k3-site-inverse.md
rg -n "K3 Site Inverse|site inverse|A_s\\^-1|structured Schur" README.md CLAUDE.md docs/src docs/PERF-plus-design.md 2>/dev/null
```

Results: whitespace clean; private-source trace clean; after-task placeholder
scan clean; implementation scan found the expected source and new-report
handles, plus historical K3 factor check-log handles from the broad `K == 3`
pattern; user-facing scan found no required README, CLAUDE.md, or docs updates
for this internal-only change.

## GitHub Issue Maintenance

No issue action was needed. This is a narrow internal performance slice on the
current branch. Open PR #59 remains the separate draft
`claude/package-work-catchup-mQiZM`; this task did not edit that lane.

## What Did Not Go Smoothly

The detached baseline worktree initially failed to load because `Manifest.toml`
is intentionally ignored and was not present in the worktree. I copied the
local ignored manifest into `/tmp/gllvm-k3ainv-baseline` only, then reran the
baseline benchmark with the same dependency set.

End-to-end exact lemma timing was noisy/mixed in the short benchmark: giant was
slower in the current row while xlarge was faster. The targeted constructor
timing improved clearly.

## Team Learning

Ada/Rose should keep separating constructor micro-evidence from end-to-end
logdet evidence in this structured Schur lane.

## Remaining Risks

- Short-rep end-to-end logdet timing remains noisy even when the targeted
  constructor speedup is clear.
- The branch is intentionally specialized to `K == 3`; `K > 3` still uses the
  generic small-matrix Cholesky path.

## Known Limitations

This does not change the fitter default, add a family, alter the Schur
determinant method, or claim allocation-free operator construction.

## Next Command

```sh
git status --short --branch
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - targeted constructor speedup is verified and
tested, while short-rep end-to-end logdet timing remains noisy.
