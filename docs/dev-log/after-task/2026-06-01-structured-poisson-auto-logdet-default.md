# After Task: Structured Poisson Auto Logdet Default

## Goal

Make the internal structured-Poisson fitted path use the shared automatic
exact-dense/SLQ determinant policy by default.

## Implemented

`_fit_structured_poisson_laplace` now defaults to `logdet_method = :auto`,
matching the structured Schur cutoff layer: exact dense for `p <= dense_cutoff`
and SLQ for larger cells. The fitted benchmark now defaults to `--logdet=auto`,
accepts `--dense-cutoff=N`, freezes probes for forced-auto SLQ runs, and records
the cutoff in CSV output. No public API changed.

## Mathematical Contract

No likelihood parameterization changed. The internal fitted path still targets
the same structured Poisson Laplace marginal. This slice changes only the
default algorithm selector for the Schur determinant term, so the fitted
prototype follows the same exact-dense/SLQ split as `_schur_u_logdet`.

## Files Changed

- `src/families/structured_poisson.jl` - private fitter default and docstring
  now use `logdet_method=:auto`.
- `test/test_structured_poisson_laplace.jl` - added default-auto exact-dense
  and forced-auto SLQ/Lanczos route assertions.
- `bench/structured_poisson_fit_bench.jl` - benchmark default and CLI support
  for `--logdet=auto --dense-cutoff=N`, with CSV cutoff recording.
- `bench/README.md` - benchmark instructions now describe the auto determinant
  default and forced-SLQ route.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-poisson-auto-logdet-default.md`
  - this audit report.

## Tests Added

Added five assertions in `structured Poisson internal fitter`: default auto
matches explicit dense at small `p`, default auto records `logdet_method=:auto`,
default auto maps `trace_solve=:auto` to `:solve`, forced auto with
`dense_cutoff=0` matches the explicit SLQ full-basis fit, and forced auto maps
to `trace_solve=:lanczos`.

## Benchmark Numbers

Default small-p smoke:

```text
Structured Poisson fitted benchmark (smoke); reps=1, warmups=1, iterations=4, gradient=implicit, logdet=auto, dense_cutoff=2048, trace_solve=auto
smoke   p=  5 n=  8 K=1 dense= 0.0005 s  cg= 0.0005 s  speedup= 1.08x  diff=5.26e-12 calls=(6,6)
```

Forced SLQ route smoke:

```text
Structured Poisson fitted benchmark (smoke); reps=1, warmups=1, iterations=4, gradient=implicit, logdet=auto, dense_cutoff=0, trace_solve=auto
smoke   p=  5 n=  8 K=1 dense= 0.0010 s  cg= 0.0009 s  speedup= 1.04x  diff=2.97e-12 calls=(6,6)
```

CSV check: `/tmp/structured-poisson-fit-auto-smoke.csv` and
`/tmp/structured-poisson-fit-auto-forced-slq-smoke.csv` include the new
`dense_cutoff` column. The recorded `trace_solve` values were `solve` for the
default small-p exact route and `lanczos` for the forced-SLQ route.

## R-Parity Verdict

Parity: N/A - this is an internal fixed-covariance structured Poisson prototype,
not a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: no zero-allocation claim; this slice changes determinant routing and
  benchmark coverage, not inner allocation contracts.
- Aqua: clean through the `Pkg.test()` quality gate.

## CI And Bootstrap Status

The existing uncertainty blocks stayed green in both core and full suite runs:

```text
confint                         | 14/14 pass
profile CI                      | 4/4 pass
parametric bootstrap CI         | 9/9 pass
derived-quantity CIs            | 45/45 pass
profile_ci_derived phylo cell   | 20/20 pass
```

No non-Gaussian CI code was edited; draft PR #59 still owns that lane.

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

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-auto-logdet-default.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-auto-logdet-default.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal structured Poisson route evidence
  only.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## GitHub Issue Maintenance

No issue action was taken. This task stays inside the private structured
Poisson prototype and benchmark harness, while PR #59 owns non-Gaussian CIs and
extra-family public catch-up.

## What Did Not Go Smoothly

The previous cutoff work made `:auto` meaningful, but the fitted benchmark still
defaulted to `:dense`, so large-p users of the internal harness would not
exercise SLQ unless they remembered a manual option. This slice aligns the
defaults and leaves explicit dense available.

## Team Learning

Ada/Gauss/Karpinski: when a lower layer gains an automatic algorithm selector,
the fitted benchmark and prototype default must adopt it too, otherwise the
large-p path exists but is not the default path being exercised.

## Remaining Risks

- This is route/default work, not a new SLQ accuracy breakthrough.
- The large-p SLQ path still needs better probes/preconditioning and full
  fitted-grid evidence beyond smoke.
- The structured Poisson path remains an internal fixed-covariance prototype.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no non-Gaussian CI/bootstrap implementation changed in this slice.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=auto --cells=large --reps=3 --warmups=3
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the private fitter and benchmark now exercise
the shared auto determinant route by default; remaining notes concern large-p
SLQ quality and public API/parity work.
