# After Task: source-attested tree BFGS diagnostic contract

## 1. Goal

Create a separate, source-attested R-only BFGS diagnostic for the frozen-tree
own optimum without relabelling the retained failed nlminb route as a pass.

## 2. Implemented

The tree own-optimum R driver now has a distinct BFGS request and receipt
schema: native data-derived initialisation, n_init = 1, optim/BFGS,
REML = FALSE, engine = tmb, se = FALSE, and reltol = 1e-12. A five-iteration
probe and a maxit = 400 final diagnostic have separate labels, budgets,
persisted RDS receipts, and strict validators. The old nlminb failure remains
a retained failure. This is a private R diagnostic, not a new public interface
or a parity result.

## 3a. Decisions and Rejected Alternatives

The BFGS route is intentionally a separate private diagnostic schema, not a
replacement for the failed nlminb record. Rejected alternatives were relaxing
the nlminb convergence requirement, reusing a Julia or historic fitted
coordinate, or calling an R-only successful optimisation a parity result.

### Mathematical Contract

The diagnostic minimises the frozen R gllvmTMB TMB Gaussian tree marginal
negative log likelihood at its own data-derived coordinate. The tree
precision, mapping, scale, determinant convention, and seven-coordinate R
packing are attested before the run; the BFGS controls are part of the request
identity. At live execution the diagnostic calls the TMB objective and gradient
and constructs an observed Hessian at the final coordinate. At persisted-record
validation it checks the stored direct/reported objective identity and
recomputes gradient-norm and curvature-summary consistency from the stored
gradient and Hessian arrays; it does not rerun TMB from the serialized record.
It deliberately does not import a Julia coordinate or compare the two engines.
See docs/dev-log/decisions/destination-b-tree-own-optimum-alignment.md.

## 4. Files Touched

- tools/destination_b/run_a4_s4_tree_r_own_optimum.R — separate BFGS request,
  execution, persisted-receipt, and source-attestation logic.
- test/test_destination_b_a4_s4_tree_r_own_optimum.R — contract and
  malformed-receipt tests for the R-only route.
- docs/dev-log/decisions/destination-b-tree-own-optimum-alignment.md —
  bounded model/receipt alignment.
- docs/dev-log/check-log.md — process and RDS hashes plus diagnostics.

## 6. Tests of the Tests

The focused R test adds BFGS control, receipt-identity, stale-gradient,
stale-curvature, and direct-objective mutation checks. It satisfies the
test-of-tests malformed-input clause: deliberately inconsistent persisted
receipts are rejected rather than accepted as evidence.

## Benchmark Numbers

Benchmarks: N/A — no Julia hot-path or package engine source changed. The
five-step probe took 0.456 s; the final R diagnostic used 68 function and 25
gradient evaluations. These are diagnostic execution counts, not performance
claims.

## R-Parity Verdict

Parity: N/A — this deliberately measures only the frozen R engine's own
optimum. It has no predeclared R-Julia coordinate or optimum comparison.

## JET / Allocs / Aqua Verdicts

- JET: N/A — no Julia src hot path changed.
- Allocs: N/A — no Julia inner loop changed.
- Aqua: N/A — no exports, dependencies, or project metadata changed.

## 5. Checks Run

- Rscript --vanilla test/test_destination_b_a4_s4_tree_r_own_optimum.R exited
  0 and emitted A4_S4_TREE_R_OWN_OPTIMUM_UNIT_OK.
- python3 tools/core070_targeted_run.py --self-test emitted
  CORE070_TARGETED_SUPERVISOR_SELFTEST_PASS.
- The source-attested BFGS probe process passed with SHA-256
  37971f0564c8a5ce319cba3414b1ac3af27b6478ddbff8de2ac4e628386f063a and
  RDS SHA-256 5cf21032faca8dfeb50ca5e9184d5fe64acaaed5f0018009f15b4318c245b262.
- The final process passed with SHA-256
  b02e63bb14449ac8f509188ebe2d3f8e13567787c8f43e8fecacde653ca65f75 and
  RDS SHA-256 227ea7852f7a6aa602f2678ccdc4e883af2da14daf506895a65e8c3074eb912c:
  convergence 0, NLL 12.7509239715045, maximum gradient
  6.5851062902577e-7, and a positive observed Hessian.
- The repository-wide after-task executable is not green: it scans the whole
  active Unlazy program, whose parent Destination B ledger remains open and
  whose pre-existing destination-b-adapter, destination-b-tree,
  destination-b-uncertainty, and totoro-t4-p6-grid ledgers are unreadable.
  This report is a scoped checkpoint, not a closure of that parent ledger.

## 8. Consistency Audit

Ran rg "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md
docs CLAUDE.md and rg "340.?x|machine precision|closed.?form" README.md
docs/src docs/PERF-plus-design.md. The task changes no package performance or
public model claim. Matching historical/route-specific wording was left
intact; the current evidence wording in check-log.md calls this R-only,
unqualified, and admission-closed.

## 7a. Issue Ledger

No issue action needed: this is a local, private diagnostic receipt and the
user did not authorise a push, issue, merge, release, or public claim.

## 9. What Did Not Go Smoothly

The original nlminb diagnostic still reports singular convergence. An
independent reviewer also found that the first BFGS validators trusted cached
objective-derived fields; direct recomputation and negative tests were added
before retaining either process receipt.

## 11. Team Learning

When a receipt is meant to prove an optimiser result, source hashes alone are
not enough: recompute objective, gradient, and curvature quantities from the
saved fit and test the checker with deliberately stale values.

## Remaining Risks

- This is not an R-Julia own-optimum comparison or a signed paired result.
- It supplies no interval, recovery, coverage, pedigree, dense-vcv, S3b, or
  S4 evidence.
- It does not qualify a public formula route, a Destination B row, 0.7.1
  parity, FRK, a release, or registration.

## 10. Known Residuals

The R-only BFGS result has a valid local convergence diagnostic, but that is
not enough to establish model parity or statistical adequacy beyond its
attested tree fixture.

## Next Command

none for this sub-slice — the parent Destination B ledger remains open; select
a separately signed paired-evidence or recovery row before widening any claim.

## 12. Cross-Product Coverage

This diagnostic covers one tree representation crossed with one R optimiser
contract and a source-attested frozen build. It does NOT cover the
R--Julia-pairing axis; alternate phylogenetic representations (pedigree and
dense vcv); formula/public-admission axes; interval, recovery, or coverage
axes; or the grouping-family product.

## Rose Verdict

Rose verdict: PASS WITH NOTES — the bounded R-only diagnostic and its negative
validators are evidenced, while every broader parity and capability claim
remains explicitly open.
