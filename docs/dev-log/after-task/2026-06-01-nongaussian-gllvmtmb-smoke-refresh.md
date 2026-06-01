# After Task: Non-Gaussian gllvmTMB Smoke Refresh

## Goal

Refresh local smoke evidence comparing warmed GLLVM.jl non-Gaussian fitters
against R `gllvmTMB`.

## Implemented

No source code changed. The existing `bench/non_gaussian_gllvmtmb_bench.jl`
harness was run in cold and warmed smoke mode with local R and `gllvmTMB` 0.2.0.

## Mathematical Contract

The benchmark uses the harness's same simulated data for both engines. The
strict likelihood interpretation is limited by the harness status column:
Gaussian, Binomial, and Poisson are same-data log-likelihood comparable;
NegBin, Beta, and Gamma still need parameterization audit; Ordinal uses
non-equivalent links.

## Files Changed

- `docs/dev-log/check-log.md` - benchmark evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-nongaussian-gllvmtmb-smoke-refresh.md`
  - this audit report.

## Tests Added

No tests were added. This is a benchmark evidence refresh only.

## Benchmark Numbers

Cold smoke command:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --reps=1 --warmups=0 --out=/tmp/non-gaussian-gllvmtmb-smoke-2026-06-01.csv
```

Cold result: completed, but first-call Julia compilation dominated several
rows, so this is not the speed table to quote.

Warm smoke command:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --reps=1 --warmups=1 --out=/tmp/non-gaussian-gllvmtmb-smoke-warm-2026-06-01.csv
```

Warm smoke summary:

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement status |
| --- | ---: | ---: | ---: | --- |
| Gaussian | 0.0002 | 0.4440 | 1921.85x | same data logLik comparable |
| Binomial | 0.0059 | 0.4450 | 75.67x | same data logLik comparable |
| Poisson | 0.0111 | 0.4400 | 39.56x | same data logLik comparable |
| NegBin | 0.0264 | 0.5780 | 21.90x | parameterization audit needed |
| Beta | 0.0768 | 0.5600 | 7.29x | parameterization audit needed |
| Gamma | 0.0165 | 0.4750 | 28.84x | parameterization audit needed |
| Ordinal | 0.0408 | 0.4960 | 12.17x | non-equivalent link |

## R-Parity Verdict

Parity: partial smoke evidence only. Gaussian, Binomial, and Poisson are
same-data log-likelihood comparable in the harness output. NegBin, Beta, and
Gamma require parameterization audit before strict likelihood claims. Ordinal is
not parity because the links differ.

## JET / Allocs / Aqua Verdicts

- JET: N/A - no source code changed after the previous full suite.
- Allocs: N/A - this benchmark records elapsed wall time, not allocations.
- Aqua: N/A - no source code changed after the previous full suite.

## CI And Bootstrap Status

No confidence-interval, bootstrap, public CI configuration, or source code was
edited. No branch CI was run because this branch was not pushed.

## Checks Run

```sh
which R
Rscript -e 'cat(as.character(utils::packageVersion("gllvmTMB")), "\n")'
```

Environment result: `/usr/local/bin/R`; `gllvmTMB` 0.2.0.

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --reps=1 --warmups=0 --out=/tmp/non-gaussian-gllvmtmb-smoke-2026-06-01.csv
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --reps=1 --warmups=1 --out=/tmp/non-gaussian-gllvmtmb-smoke-warm-2026-06-01.csv
```

Benchmark result: both commands completed and wrote CSV files under `/tmp`.

## Consistency Audit

Commands run:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-nongaussian-gllvmtmb-smoke-refresh.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean after finalizing this report.
- Performance-claim scan: expected existing Gaussian/gllvmTMB and internal
  benchmark-log hits only. This report records a smoke benchmark with caveats,
  not a full-grid or public 100x claim.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## GitHub Issue Maintenance

No issue action was taken. This is a local benchmark evidence refresh.

## What Did Not Go Smoothly

The cold smoke table is not useful for speed claims because it includes Julia
first-call compilation. The warmed smoke table is the evidence to carry forward.

## Team Learning

Hopper: the harness is usable locally with R `gllvmTMB` 0.2.0. Fisher: keep
same-data comparable likelihood claims separate from parameterization-audit and
non-equivalent-link rows.

## Remaining Risks

- This is a smoke cell only, not the small/medium/large benchmark grid.
- Several families still need parameterization parity audit before strict
  likelihood claims.
- This evidence should not be promoted as a full-grid speed claim.

## Known Limitations

No source-code change, no full-grid R benchmark, no new public speed claim.

## Next Command

```sh
git status --short --branch
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - smoke comparison evidence is refreshed, but only Gaussian/Binomial/Poisson are same-data log-likelihood comparable and this is not a full-grid benchmark.
