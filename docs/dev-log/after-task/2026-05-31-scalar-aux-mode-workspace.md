# After Task: Scalar-Aux Mode Workspace

## Goal

Reduce hot-loop allocations in the dense-Laplace non-Gaussian scalar-auxiliary
objectives without changing the likelihood, public API, or optimizer contract.

## Implemented

- Added `_LaplaceModeWorkspace` in `src/families/laplace.jl` to reuse Fisher
  scoring buffers inside the inner mode finder.
- Reused packed `β`, `Λ`, and scalar auxiliary views once per aggregate
  objective call.
- Enabled workspace mode solving only for scalar-auxiliary Beta/Gamma paths.
- Left NegativeBinomial on the previous BLAS-backed mode solve because the
  workspace loop reduced allocation but slowed the medium NB benchmark.
- Reverted the attempted canonical Poisson/Binomial workspace route after an
  isolated full-suite run exposed a `fit_poisson_gllvm` convergence failure.

No public API changed. No edits were made to `src/sparse_phy_grad.jl`,
`src/em_phylo.jl`, or the PR #59 non-Gaussian CI / two-part lane.

## Mathematical Contract

The objective and gradient target are unchanged:

```text
q_s(θ) = ℓ(y_s | zhat_s, θ) - 0.5 zhat_s'zhat_s
         - 0.5 logdet(I + Λ'W_sΛ),
```

where `zhat_s` solves the same Fisher-scoring mode equation. This slice changes
only scratch allocation in the inner solve for selected scalar-auxiliary paths.

## Files Changed

- `src/families/laplace.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-scalar-aux-mode-workspace.md`

## Tests

- `julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'`
  passed: 92/92.
- All six non-Gaussian family recovery tests passed: 45/45.
- `julia --project=. --startup-file=no test/runtests.jl` passed with exit code
  0. Manual tally from emitted summaries: 2214 pass, 3 broken placeholders, 0
  fail, 0 error.
- `julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'` passed:
  quality 12/12 and `Testing GLLVM tests passed`. Manual tally from emitted
  summaries: 2226 pass, 1 existing broken sparse-phy precision check, 0 fail, 0
  error.

## Allocation Evidence

Probe shape: `p = 30`, `n = 120`, `K = 2`; one warmed aggregate
value/gradient call measured with `@allocated`.

| family/path | before bytes | after bytes | allocation reduction |
| --- | ---: | ---: | ---: |
| Gamma scalar-aux | 8,650,448 | 1,974,224 | 4.38x |
| Beta scalar-aux | not recorded before this slice | 1,920,752 | after-only |
| Negative-binomial scalar-aux | 6,145,616 | 6,020,016 | intentionally near unchanged |

## Benchmarks

Julia-only warmed medium-cell benchmark:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=medium --families=negbin,beta,gamma --iterations=120 --warmups=2 --reps=3 --julia-only
```

| family | p | n | K | median seconds | convergence |
| --- | ---: | ---: | ---: | ---: | --- |
| negbin | 30 | 500 | 2 | 0.8786 | 3/3 |
| beta | 30 | 500 | 2 | 2.2930 | 3/3 |
| gamma | 30 | 500 | 2 | 1.1868 | 3/3 |

Against immediately prior logged medians on this branch, NB is unchanged
(`0.8803s` prior), Beta improves from `2.5687s`, and Gamma improves from
`1.5403s`.

## R-Parity Verdict

Parity unchanged. This slice changes only scratch allocation and a selected
inner-solve implementation route. Strict NB/Beta/Gamma likelihood parity against
R `gllvmTMB` remains under the existing parameterisation-audit label in the
benchmark harness.

## JET / Allocs / Aqua

JET: clean under the `Pkg.test()` quality block.

Aqua: clean under the `Pkg.test()` quality block.

Allocs: not run as a package gate because Allocs.jl is not installed in the
active project; allocation evidence was captured with `@allocated`.

## Structured-Determinant Scout

Curie completed a read-only scout for the next large-p structured-dependence
algorithm. The recommended next code slice is a separate internal `S_u` operator
and SLQ prototype, not further `laplace.jl` refactoring:

- matrix-free `S_u v = σ^-2Σ_phy^-1v + W_• .* v - Σ_s B_s(A_s \\ (B_s'v))`;
- frozen Rademacher probes for deterministic SLQ logdet estimates;
- dense equality and SLQ-vs-dense tests before any fitter wiring.

This belongs in a new internal file to avoid colliding with PR #59 and the
current dense-Laplace fitter lane.

## Hygiene Scans

- `git diff --check`: clean.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## Remaining Risks

- The workspace solver is intentionally limited to Beta/Gamma because broader
  use caused either NB slowdown or Poisson convergence risk.
- This is a constant-factor allocation improvement, not the 100x structured
  breakthrough. The 100x-class path is the structured `S_u` operator + SLQ
  determinant lane.

## Rose Verdict

Rose verdict: PASS WITH NOTES — the allocation win is real and verified, the
failed canonical workspace experiment was not shipped, and the remaining large
speedup work is clearly separated into the structured determinant slice.
