# After Task: Structured Schur/SLQ Substrate

## Goal

Start the scalable determinant lane for non-Gaussian structured dependence
without colliding with the active non-Gaussian CI / extra-family PR.

## Implemented

Added an internal `_SchurUOperator` that applies the latent structured-response
Schur complement, preserves sparse precision matrices, and provides dense
reference materialization plus deterministic SLQ log-determinant estimation over
caller-supplied probes. It also adds an internal determinant selector that uses
exact dense `logdet` below a cutoff and frozen-probe SLQ above it. The code is
not exported and is not yet wired into fitters.

## Mathematical Contract

For response-level precision `Q`, loadings `Λ`, site weights `w_s`, and
`D_s = diag(w_s)`, the operator applies

```text
S_u x = σ⁻² Qx + (sum_s w_s) .* x
        - sum_s D_s Λ (I + Λ' D_s Λ)⁻¹ Λ' D_s x.
```

This is the Schur-complement determinant block identified in the
non-Gaussian structured-dependence design for replacing dense `O(p^3)`
log-determinants with matrix-free Lanczos/SLQ probes.

## Files Changed

src:

- `src/GLLVM.jl` — includes the internal structured Schur substrate.
- `src/structured_schur.jl` — new Schur operator, dense reference, frozen
  Rademacher probes, SLQ logdet helper, and dense-vs-SLQ selector.

test:

- `test/runtests.jl` — wires the new structured Schur tests.
- `test/test_structured_schur.jl` — dense/sparse operator and SLQ checks.

docs:

- `docs/dev-log/check-log.md` — evidence log for this slice.
- `docs/dev-log/after-task/2026-05-31-structured-schur-slq-substrate.md` — this
  audit.

## Tests Added

Added two testsets:

- `structured Schur operator`: 22 checks covering dense and sparse precision
  storage, `mul!` agreement with an independent dense Schur matrix, SPD
  positivity, and malformed-input paths.
- `structured Schur SLQ logdet`: 9 checks covering exact-basis agreement with
  dense `logdet`, deterministic repeatability with frozen Rademacher probes,
  dense/SLQ selector branches, and invalid selector inputs.

The tests satisfy the independent-calculation and malformed-input clauses of
the test-of-tests rule.

## Benchmark Numbers

Smoke timing on the maintainer Mac, Julia 1.10.0:

```text
slq_p80_n12_K2_steps20_probes8 elapsed=0.001644 allocated=103552
```

This is not a before/after fitter benchmark. It only records that the new SLQ
substrate runs quickly on a small sparse-precision probe cell. The meaningful
next benchmark is dense `logdet(S_u)` versus sparse/SLQ in the structured
non-Gaussian objective.

## R-Parity Verdict

Parity: N/A — this internal substrate does not change any public fitter,
likelihood surface, or R-comparable API.

## JET / Allocs / Aqua Verdicts

- JET: package quality gate passed through `Pkg.test()`; no new targeted
  `JET.@test_opt` was added for this internal prototype.
- Allocs: smoke allocation recorded at 103552 bytes for p=80, n=12, K=2,
  8 probes, 20 Lanczos steps; no before/after fitter allocation claim.
- Aqua: clean via `Pkg.test()` quality block, 12/12 pass.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl")'
julia --project=. --startup-file=no test/runtests.jl
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
git diff --check
```

Observed tallies:

```text
targeted structured Schur operator     | 22/22 pass
targeted structured Schur SLQ logdet   | 9/9 pass
core manual tally                      | 2257 pass, 1 existing broken, 2 expected quality placeholders, 0 fail, 0 error
Pkg.test manual tally                  | 2257 pass, 1 existing broken, 0 fail, 0 error
Pkg.test quality                       | 12/12 pass
Testing GLLVM tests passed
```

## Consistency Audit

Scans run:

```sh
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Results:

- No private-source trace in tracked repo content.
- The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
  snapshot. It was not edited because AGENTS.md changes require maintainer
  approval.
- Performance-claim scan found only existing Gaussian / benchmark wording; no
  new user-facing speed claim was added.

## GitHub Issue Maintenance

No issue action taken. The only open PR visible during the collision check was
draft PR #59, which owns non-Gaussian CIs / Delta-Gamma / ZIP-ZINB; this slice
stayed out of that lane.

## What Did Not Go Smoothly

The first sparse-preserving constructor reused `Symmetric(..., precision.uplo)`
directly, but Julia 1.10 stores `uplo` as a character while the constructor
expects a symbol. The focused test caught it and the fix is included.

## Team Learning

Karpinski's next pass should add a targeted type-stability/allocation check for
the Schur multiply before this substrate becomes a fitter hot path.

## Remaining Risks

- The substrate is not yet wired into structured non-Gaussian fitting.
- SLQ is deterministic for fixed probes but still approximate for stochastic
  probes; objective smoothness and optimizer behaviour are not proven yet.
- Log-determinant derivatives / implicit gradient coupling are not implemented.
- The direct core run still has the expected quality placeholders; `Pkg.test()`
  is the authoritative quality gate and passed.

## Known Limitations

This does not implement the full structured non-Gaussian Laplace objective,
does not choose dense versus SLQ automatically, and does not create any
user-facing API.

## Next Command

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — correct and tested internal substrate, but not
yet a fitted structured non-Gaussian algorithm or a public speed claim.
