# After Task: Structured Poisson Mode Inverse Reuse

## Goal

Use the cached structured Schur site inverses inside the structured Poisson
inner mode solver, where the optimizer repeatedly pays for tiny site-level
systems.

## Implemented

`_structured_poisson_mode` now applies cached `A_i^{-1}` matrices for the
site-level RHS elimination and `ΔZ_i` updates instead of repeatedly calling
`ldiv!` on the corresponding Cholesky factors. The dense block-gradient and SLQ
trace-gradient paths also use `op.Ainvs[i]` directly as read-only matrices
instead of copying them into scratch buffers per site.

## Mathematical Contract

For each site, `A_i = I_K + Λ' Diagonal(W_i) Λ`. Since `_SchurUOperator`
already materializes `A_i^{-1} = cholesky(A_i) \ I_K`, replacing
`A_i \ r` with `A_i^{-1} r` is algebraically equivalent up to floating-point
roundoff. Existing dense/CG/SLQ structured Poisson tests verify the same
Laplace value and implicit gradient targets after the change.

## Files Changed

- `src/families/structured_poisson.jl` - reused cached `A_i^{-1}` in the mode
  solver and avoided read-only inverse copies in block/trace gradients.
- `docs/dev-log/check-log.md` - recorded tests, benchmarks, rejected scratch
  probe, and lane checks.

## Tests Added

No new test file was needed for this narrow internal rewrite. Existing
structured Poisson tests exercise the changed mode equations through dense/CG
Laplace value agreement, SLQ exact full-basis checks, implicit-gradient finite
difference checks, and the private fitted path.

## Benchmark Numbers

Fitted SLQ auto benchmark, `reps=3`, `warmups=3`, `iterations=10`:

| state | cell | p | n | K | dense (s) | CG (s) | dense / CG | abs loglik diff |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| before | small | 5 | 8 | 1 | 0.0030 | 0.0038 | 0.81x | 5.83e-12 |
| before | medium | 8 | 12 | 2 | 0.0042 | 0.0042 | 1.01x | 3.41e-12 |
| before | large | 20 | 25 | 2 | 0.0272 | 0.0229 | 1.19x | 5.12e-12 |
| after | small | 5 | 8 | 1 | 0.0032 | 0.0035 | 0.92x | 5.90e-12 |
| after | medium | 8 | 12 | 2 | 0.0042 | 0.0039 | 1.09x | 3.41e-12 |
| after | large | 20 | 25 | 2 | 0.0264 | 0.0220 | 1.20x | 4.89e-12 |

CG fitted-path times improved by about 1.09x, 1.08x, and 1.04x on the small,
medium, and large calibration cells.

Trace-gradient benchmark, `large,frontier`, `nprobes=4`, `lanczos_steps=20`,
`trace_solve=lanczos`:

| state | cell | p | n | K | dense (s) | SLQ (s) | dense / SLQ | value diff | grad rel |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| before | large | 320 | 160 | 2 | 0.1629 | 0.0657 | 2.48x | 6.15e-01 | 1.41e-01 |
| before | frontier | 640 | 160 | 2 | 0.5802 | 0.1281 | 4.53x | 2.46e+00 | 3.18e-01 |
| after | large | 320 | 160 | 2 | 0.1652 | 0.0647 | 2.55x | 6.15e-01 | 1.41e-01 |
| after | frontier | 640 | 160 | 2 | 0.5805 | 0.1283 | 4.53x | 2.46e+00 | 3.18e-01 |

The trace-gradient path was effectively neutral; the clearer win is in fitted
CG mode solves.

## R-Parity Verdict

Parity: N/A - this is an internal Julia structured Poisson prototype
optimization and does not touch public R `gllvmTMB` parity surfaces.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: no zero-allocation gate added; this removes repeated tiny factored
  solves and per-site inverse copies but does not claim an allocation-free loop.
- Aqua: clean through the `Pkg.test()` quality gate.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 111 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2325 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2337 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=slq --trace-solve=auto --reps=3 --warmups=3 --iterations=10
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large,frontier --trace-solve=lanczos --reps=3 --warmups=3 --nprobes=4 --lanczos-steps=20
```

Benchmarks completed before and after the code change and produced the tables
above.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked repo content: no matches.
- Stale-wording scan: expected hits only - the user-provided AGENTS.md
  "Gaussian only" snapshot, historical check-log command/result records, and
  this scan command.
- Performance-claim scan: expected hits only - existing Gaussian/gllvmTMB
  claims, historical internal structured benchmark records, benchmark-script
  column names, and this report's internal fitted-path benchmark evidence. This
  slice adds no R `gllvmTMB` parity claim and no public 20x-100x structured
  speedup claim.

## GitHub Issue Maintenance

No issue action was taken. Open PR #59 remains the separate draft formula and
family catch-up lane; this task did not overlap it.

## What Did Not Go Smoothly

A proposed `W_iΛ` cache was implemented in scratch and rejected before commit:
direct Schur matvec timing was neutral to slightly negative (`1.00x`, `1.02x`,
`0.96x`), so keeping that memory trade-off would not have been evidence-based.

## Team Learning

The structured path is now at the point where plausible algebraic caches need a
direct kernel benchmark before they are allowed into the fitted path.

## Remaining Risks

- The fitted benchmark cells are small calibration cells.
- This is a modest constant-factor change, not the 20x-100x structured
  determinant algorithm.
- Public R `gllvmTMB` comparison remains N/A for this private structured path.

## Known Limitations

This slice does not add adaptive probe counts, preconditioning, a public
structured non-Gaussian API, or R `gllvmTMB` comparison cells.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=slq --trace-solve=auto --reps=5 --warmups=5 --iterations=20
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - cached inverse reuse in the inner mode solver is
tested and modestly faster on fitted CG cells, but it remains an internal
constant-factor structured-prototype improvement.
