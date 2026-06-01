# After Task: Structured Poisson Fitted Probe Controls

## Goal

Let the fitted Structured Poisson benchmark compare Rademacher and orthogonal
SLQ probes without editing the script.

## Implemented

`bench/structured_poisson_fit_bench.jl` now accepts
`--probe-kind=rademacher|orthogonal`, uses the selected frozen probe matrix for
SLQ fitted cells, prints the probe kind in the startup line, and records it in
the CSV. `bench/README.md` documents the option next to the fitted SLQ
trace-solve controls. No public GLLVM.jl API, fitter default, or likelihood
path changed.

## Mathematical Contract

No likelihood parameterization changed. The fixed-covariance structured Poisson
Laplace prototype still compares the dense Schur determinant route against the
same SLQ/Lanczos determinant route; this slice only chooses the stochastic probe
basis used by the benchmark harness.

## Files Changed

- `bench/structured_poisson_fit_bench.jl` - added `--probe-kind`, probe
  validation, orthogonal probe generation, startup reporting, and CSV recording.
- `bench/README.md` - documented the fitted SLQ orthogonal-probe control.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-fitted-probe-controls.md`
  - this audit report.

## Tests Added

No package tests were added because this is a benchmark CLI/control-surface
slice, not a package API or likelihood change. Behaviour was checked by help
output, two forced-SLQ smoke runs, CSV header/row inspection, and an invalid
option smoke that exercises the failure path.

## Benchmark Numbers

Rademacher forced-SLQ smoke:

```text
Structured Poisson fitted benchmark (smoke); reps=1, warmups=1, iterations=4, gradient=implicit, logdet=auto, dense_cutoff=0, trace_solve=auto, probe_kind=rademacher
smoke   p=  5 n=  8 K=1 dense= 0.0009 s  cg= 0.0009 s  speedup= 0.99x  diff=2.97e-12 calls=(6,6)
```

Orthogonal forced-SLQ smoke:

```text
Structured Poisson fitted benchmark (smoke); reps=1, warmups=1, iterations=4, gradient=implicit, logdet=auto, dense_cutoff=0, trace_solve=auto, probe_kind=orthogonal
smoke   p=  5 n=  8 K=1 dense= 0.0009 s  cg= 0.0009 s  speedup= 1.04x  diff=5.24e-12 calls=(6,6)
```

CSV check: both `/tmp/structured-poisson-fit-probes-rademacher.csv` and
`/tmp/structured-poisson-fit-probes-orthogonal.csv` include the new
`probe_kind` column and record `trace_solve=lanczos` for the forced-SLQ route.
These are smoke/instrumentation checks, not fitted-grid speed claims.

## R-Parity Verdict

Parity: N/A - this is an internal fixed-covariance benchmark harness change,
not a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: N/A - no hot-path package code changed.
- Aqua: clean through the `Pkg.test()` quality gate.

## CI And Bootstrap Status

The local core suite stayed green after this benchmark slice. The existing
confidence-interval and bootstrap tests still pass in that run:

```text
confint                         | 14/14 pass
profile CI                      | 4/4 pass
parametric bootstrap CI         | 9/9 pass
derived-quantity CIs            | 45/45 pass
profile_ci_derived phylo cell   | 20/20 pass
```

No non-Gaussian CI or bootstrap code was edited; draft PR #59 still owns that
public catch-up lane.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 122 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2336 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2348 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --help
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --logdet=auto --dense-cutoff=0 --probe-kind=rademacher --nprobes=5 --lanczos-steps=5 --reps=1 --warmups=1 --out=/tmp/structured-poisson-fit-probes-rademacher.csv
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --logdet=auto --dense-cutoff=0 --probe-kind=orthogonal --nprobes=5 --lanczos-steps=5 --reps=1 --warmups=1 --out=/tmp/structured-poisson-fit-probes-orthogonal.csv
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --logdet=auto --dense-cutoff=0 --probe-kind=invalid --reps=1 --warmups=0 --out=/tmp/structured-poisson-fit-invalid.csv
head -n 2 /tmp/structured-poisson-fit-probes-rademacher.csv
head -n 2 /tmp/structured-poisson-fit-probes-orthogonal.csv
```

Benchmark CLI result: help, two valid forced-SLQ smokes, CSV probe-kind
recording, and invalid option validation all behaved as expected.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-fitted-probe-controls.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-fitted-probe-controls.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal benchmark-instrumentation record
  only.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## GitHub Issue Maintenance

No issue action was taken. This slice supports the local structured determinant
benchmark track and does not change public family support, CI/bootstrap
surfaces, or R parity commitments.

## What Did Not Go Smoothly

The trace-gradient workbench already had orthogonal-probe controls, but the
fitted benchmark still forced Rademacher probes. This made the next fitted-grid
comparison less ergonomic than it needed to be.

## Team Learning

Gauss/Karpinski/Fisher: probe-basis experiments need to be first-class
benchmark parameters, recorded in the CSV, otherwise accuracy and speed
differences become hard to audit after the terminal scroll is gone.

## Remaining Risks

- This is instrumentation, not a new determinant algorithm or speedup claim.
- Orthogonal probes still need large-p fitted-grid evidence before we make any
  accuracy or time recommendation.
- The structured Poisson fitted path remains an internal fixed-covariance
  prototype.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no non-Gaussian CI/bootstrap implementation changed in this slice.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=auto --dense-cutoff=0 --probe-kind=orthogonal --nprobes=8 --lanczos-steps=20 --reps=3 --warmups=3 --cells=large
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the fitted benchmark now records and exercises
Rademacher versus orthogonal SLQ probes; remaining notes concern large-p
fitted-grid evidence and public structured non-Gaussian API/parity work.
