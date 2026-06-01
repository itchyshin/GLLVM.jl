# After Task: Structured Fast-Algorithm Scout

## Goal

Turn the user's 100x structured-model ambition into a concrete, evidence-bounded
algorithm plan after the dense non-Gaussian gradient slice.

## Implemented

Added a repo-visible strategy memo that ranks the next fast-algorithm lanes:
sparse precision / node-frame structured Laplace first, warm inner-mode reuse
second, profiling third, then Kronecker, SPDE/GMRF, Vecchia/NNGP, and
low-rank-plus-sparse extensions. The branch was rebased onto current
`origin/main` before writing the memo so it refers to the live
non-Gaussian structured-dependence spec.

## Mathematical Contract

No likelihood code changed. The memo preserves the existing structured
non-Gaussian contract from
`docs/superpowers/specs/2026-05-31-nongaussian-structured-dependence-design.md`:
a joint Laplace approximation over per-site latent factors and a shared
structured species effect, with a Schur-complement structured block.

## Files Changed

- `docs/dev-log/2026-05-31-structured-fast-algorithm-scout.md`: added the
  100x algorithm lane memo.
- `docs/dev-log/check-log.md`: added the scout entry.
- `docs/dev-log/after-task/2026-05-31-structured-fast-algorithm-scout.md`:
  added this audit report.

## Tests Added

None. This is a planning and scout artifact, not an implementation slice.

Tests of the tests: N/A.

## Tests Run

Core:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Direct core run used the expected direct-run quality
placeholders for Aqua/JET.

Full:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: `Testing GLLVM tests passed`; quality block `12/12` pass. Manual tally
from emitted `Test Summary` blocks after the rebase: 2208 pass, 1 existing
broken sparse-phy precision check, 0 fail, 0 error.

## Benchmark Numbers

N/A - no hot-path code changed. The memo repeats the already-measured
canonical-gradient slice numbers and explicitly labels structured 100x speedups
as targets, not evidence.

## R-Parity Verdict

Parity: N/A - no likelihood, fitter, initialization, or R comparator code
changed.

## JET / Allocs / Aqua Verdicts

- JET: clean through `Pkg.test()` quality block.
- Allocs: not run - no hot path changed.
- Aqua: clean through `Pkg.test()` quality block.

## Rose Audit

- Public-source-only scout note; no source path or manuscript metadata was added.
- Existing 20x/25.6x evidence is separated from the unproven 100x structured
  target.
- The memo keeps the hard lane boundary: no edits to `src/sparse_phy_grad.jl` or
  `src/em_phylo.jl`.

Rose verdict: PASS WITH NOTES - this closes the scout memo only; the structured
algorithm itself remains unimplemented and must pass dense-reference,
finite-difference, recovery, and R-comparator gates before any 100x claim.
