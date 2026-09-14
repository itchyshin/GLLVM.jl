# After Task: U3 phylogenetic-uncertainty CLI rejection seal

## 1. Goal

Exercise the existing U3 bad-file rejection requirement through the actual
Julia command-line interface while preserving the separate source-integrity
guard and all unqualified evidence boundaries.

## 2. Implemented

Added one standalone CLI test and registered it immediately after the existing
uncertainty test. It copies a sealed tree R input into a temporary directory,
appends one newline so JSON remains parseable but its SHA-256 seal changes,
and invokes compare_phylo_uncertainty.jl in the Pkg test environment. The test
requires a nonzero process, a fresh error receipt, status error, qualified
false, and the unsealed-input diagnostic. Repeating with the now-existing
receipt must also fail and leave the receipt byte-identical. No production,
bridge, adapter, or R code changed.

## 3a. Decisions and Rejected Alternatives

The existing in-memory uncertainty test must remain hash-bound to its retained
Julia sources. It currently stops before its assertions because a foreign
dirty reference file changed that retained hash. Rejected alternatives were
weakening/skipping that guard, editing the foreign file, or claiming the
negative route validates a successful paired uncertainty comparison. The new
test is therefore separate and uses Pkg.test's transient merged project, where
both GLLVM and JSON3 are available.

### Mathematical and CLI Contract

For a fresh output path, the checker hashes its three input files before JSON
parsing and accepts only an exact sealed tuple. The mutated input must fail the
tuple check; its catch path writes an error receipt with qualified false and
then returns a nonzero process. A pre-existing output path is rejected before
that catch path and must not be overwritten. No likelihood, covariance, or
interval value is asserted by U3.

## 4. Files Touched

- test/test_destination_b_phylo_uncertainty_cli.jl — black-box unsealed-input
  and no-clobber regression.
- test/runtests.jl — one adjacent shard registration line.
- docs/dev-log/check-log.md — exact U3 evidence and scope boundary.
- docs/dev-log/after-task/2026-09-08-phylo-uncertainty-cli-seal.md — this
  scoped checkpoint.

## 5. Checks Run

- GLLVM_TEST_SHARD=164/292 julia --startup-file=no --history-file=no
  --warn-overwrite=no --project=. -e using Pkg; Pkg.test(...) passed 9/9.
- The dedicated Unlazy leaf ledger
  .unlazy/destination-b-u3-cli/GATES.md passed U3 after approved execution:
  9/9 in 8.3 s, then clean re-verification: 9/9 in 6.8 s, and a final
  post-ledger-audit re-verification: 9/9 in 7.3 s.
- Full Pkg.test() was not run. The repository-wide after-task executable also
  remains blocked by four older unreadable Unlazy ledgers; this checkpoint does
  not claim the parent programme ledger is green.

### Benchmark Numbers

Benchmarks: N/A — no model, sparse-linear-algebra, or package hot path
changed. The narrow regression shard was measured at 6.8–8.3 s, with a final
post-ledger-audit re-verification at 7.3 s, in its
ledger, below the 30-minute compute gate.

### R-Parity Verdict

Parity: N/A — no R fit, frozen-R objective, or R--Julia comparison was run.

### JET / Allocs / Aqua Verdicts

- JET: N/A — no Julia src hot path changed.
- Allocs: N/A — no Julia inner loop changed.
- Aqua: N/A — no exports, dependencies, or project metadata changed.

## 6. Tests of the Tests

The test mutates a previously sealed, valid JSON fixture rather than relying
on a missing path. It observes the real child process and receipt bytes,
including the distinct fresh-error and pre-existing-output branches. It is a
negative-only seal: it intentionally does not prove the positive comparison
route because that route remains separately hash-bound to foreign in-flight
source state.

## 7a. Issue Ledger

No issue action needed. This is a local existing-row regression test; the user
did not authorise a push, issue, merge, release, or public capability claim.

## 8. Consistency Audit

Ran rg "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md
docs CLAUDE.md and rg "340.?x|machine precision|closed.?form" README.md
docs/src docs/PERF-plus-design.md during the adjacent U3 closure work. No
public model wording changed. The check-log and this report explicitly retain
the private-checker and nonqualification boundary.

## 9. What Did Not Go Smoothly

The original uncertainty test could not serve as the external CLI runner
because its retained source-hash assertion correctly detects a foreign dirty
reference file. A bare root-project CLI also lacked JSON3 because JSON3 is a
test dependency. The isolated Pkg.test test project resolves both facts
without changing either guard or dependency scope.

## 10. Known Residuals

The test proves only malformed-input rejection and output preservation. It
does not make the existing source-integrity test green, repair the foreign
file, validate a successful comparator result, or add any statistical
evidence.

## 11. Team Learning

When a hash-bound test is blocked by another lane's legitimate in-flight
change, preserve it. Put an independent black-box safety check in its own
test file and use the real Pkg test environment rather than widening the
package's root dependencies.

## 12. Cross-Product Coverage

U3 covers one tree JSON fixture crossed with one unsealed-input mutation and
the fresh-output/no-clobber branches. It does NOT cover a successful
tree/pedigree/dense comparison, covariance or coordinate mutation beyond the
existing in-memory tests, R parity, intervals, recovery, public admission,
S3b/S4, grouping B1, FRK, or real-data workflows.

## Rose Verdict

Rose verdict: PASS WITH NOTES — the isolated U3 negative regression is
independently reviewed and reverified, while the parent programme and legacy
Unlazy parser state remain explicitly open.
