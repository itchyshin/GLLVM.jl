# After-task — B1 fixed-coordinate curvature pre-run protocol

## 1. Goal

Pre-register, but do not execute, the B1 fixed-coordinate curvature audit from the retained n=180 negative stationary-candidate receipt.

## 2. Implemented

Added a human-readable protocol, machine-readable TOML pins, and a stdlib-only Julia verifier. The verifier locks the receipt bytes, source/data/formula identities, raw-coordinate packing, six blocks (fixed, residual, plus all four fitted groups), call counts, interpretation bounds, and authorization state.

## 3a. Decisions and Rejected Alternatives

Used a static verifier rather than an R evaluator: an evaluator would construct or call the forbidden objective/gradient/Hessian. Rejected JSON3 because it is test-only and unavailable to standalone package-project tools; byte-hash locking plus explicit schema sentinels provides a dependency-free fail-closed check.

## 4. Files Touched

- `docs/dev-log/protocols/b1-fixed-coordinate-curvature-audit.md`
- `docs/dev-log/protocols/b1-fixed-coordinate-curvature-audit.toml`
- `tools/verify_b1_fixed_coordinate_curvature_protocol.jl`
- `test/test_b1_fixed_coordinate_curvature_protocol.jl`
- `test/runtests.jl`
- `docs/dev-log/check-log.md`
- `.unlazy/GATES.md` (ignored local acceptance ledger)

## 5. Checks Run

Focused Julia static test: 4/4 pass. Standalone static verifier: PASS. `git diff --check`: pass. No full suite was run because this slice must not trigger model-fit tests.

## 6. Tests of the Tests

The focused test writes three temporary protocol variants and confirms that source-hash, coordinate-order, and n=180 dimension drift each raise `ArgumentError`.

## 7a. Issue Ledger

Fixed one portability issue: standalone `--project=.` did not have JSON3. No model or receipt issue was found.

## 8. Consistency Audit

Checked the retained receipt, frozen runner, shared fixture module, existing balanced-control preflight, and B1 test registration. The verifier pins all four grouping blocks and refuses receipt, source, data-shape, formula, coordinate, or execution-contract drift.

## 9. What Did Not Go Smoothly

The first standalone implementation assumed JSON3 was a package dependency. Replacing it with SHA/TOML plus byte-locked schema sentinels kept the tool executable in the package environment.

## 10. Known Residuals

No observed Hessian or eigenpair exists yet. The retained coordinate is non-stationary, so any future result remains conditional and needs fresh authorization before even one evaluation.

## 11. Team Learning

For a forbidden-compute pre-run slice, a byte-pinned receipt plus a static schema test is a useful executable boundary: it catches drift without quietly consuming a model evaluation.

## 12. Cross-Product Coverage

Does cover ✓ the retained frozen R source identities, n=180 data digest/shape, formula, raw coordinate order, all four grouping blocks, and pre-registered curvature interpretation. It does NOT cover ✗ an objective value, gradient recomputation, observed Hessian, Julia parity, convergence repair, standard errors, interval validation, recovery, or B1 qualification.
