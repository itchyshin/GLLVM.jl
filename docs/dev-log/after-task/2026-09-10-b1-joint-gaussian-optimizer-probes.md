# After Task: B1 joint Gaussian frozen-R optimizer probes

## 1. Goal

Test the remaining frozen-R, model-preserving optimizer and initialization
controls for the first joint four-group Gaussian B1 fixture, without changing
its likelihood, data, seed, source reference, or acceptance tolerance.

## 2. Implemented

Added a shared fixture/attestation module, thin no-clobber receipt
runners, and a receipt contract to retain four
predeclared controls: ten-start nlminb, five-start BFGS, and each with the
frozen source's `indep` start request.  The runner captures every selected
coordinate, restart history, warning, and actual warm-start application state.
It never relabels a fallback as an independent-model warm start.

## 3. Model and optimizer contract

The target remains the existing ML Gaussian model

\[
Y_{ti}=\beta_t+\lambda_t z_{u(i)}+a_{t,w(i)}+q_{t,c(i)}+
r_{t,c_2(i)}+\epsilon_{ti},
\]

with rank-one `unit` covariance and diagonal `unit_obs`, `cluster`, and
`cluster2` covariances.  Only the outer optimization trajectory varies.  A
source point is eligible for a new Julia paired comparison only when it is
finite, reports convergence zero, and has maximum outer score at most `1e-6`.

## 3a. Decisions and Rejected Alternatives

The four controls were declared before running and all results are retained.
Rejected alternatives are a looser gradient gate, a changed response seed,
`unique = TRUE` (which changes the p=2 covariance identification), ridge
controls that change the objective, and calling a requested but failed
independent warm start successful.

## 4. Files Touched

- `tools/destination_b/b1_joint_gaussian_optimizer_probes.R`: focused,
  frozen-source-attested probe runner.
- `tools/destination_b/b1_joint_gaussian_common.R`: shared frozen source/DLL
  attestation and deterministic fixture constructor. It uses only temporary
  archive/CSV files while preparing a fit, never alters the source/build or a
  retained receipt; its publisher uses atomic no-clobber hard-link publication.
- `tools/destination_b/b1_joint_gaussian_reference.R`: thin base-receipt
  runner using the same attested fixture.
- `test/test_destination_b_b1_joint_receipt_io.R`: pure no-clobber publisher
  regression test, including an occupied output and dangling symlink.
- `test/test_destination_b_b1_joint_gaussian_paired_fit.jl`: verifies the new
  receipt's source, controls, gradients, histories, warnings, and warm-start
  status.
- `docs/dev-log/core070/destination-b-b1/frozen-r070-joint-gaussian-*-03.json`:
  fresh, immutable reference and probe results; the prior files remain history.
- `docs/dev-log/check-log.md`: command and result ledger.
- This report.

## 5. Checks Run

```sh
Rscript --vanilla tools/destination_b/b1_joint_gaussian_optimizer_probes.R \
  --source /private/tmp/destination-b-b1-r070-rebuild \
  --library /private/tmp/gllvmTMB-frozen-r070-b1-library-20260910 \
  --output docs/dev-log/core070/destination-b-b1/frozen-r070-joint-gaussian-optimizer-probes-20260910-03.json
# exit 0; 7.3 s

GLLVM_TEST_SHARD=158/294 julia --project=. -e 'using Pkg; Pkg.test()'
# 129 passed, 0 failed, 0 errored; 7.3 s

Rscript --vanilla test/test_destination_b_b1_joint_receipt_io.R
# exit 0; occupied output and dangling symlink rejected

git diff --check
# exit 0
```

## 6. Tests of the Tests

The B1 receipt test gained provenance, acceptance-boundary, control, and
success/failure-union assertions. It was first
run through the correct `Pkg.test()` environment and failed because the
artifact did not exist; it then failed again before warning/warm-start fields
were implemented. The final test checks exact runner/module identities, the
empty eligibility/matched-parameter boundary, and the fact that the two
requested `indep` starts fell back with the named `cluster2` warning. A pure R
I/O test proves no-clobber publication and dangling-symlink rejection without
fitting.

### Benchmark numbers

N/A — no Julia hot path changed.  The R probe replay took 7.3 s wall time;
the four added controls individually took 0.12--0.18 s.

### R-parity verdict

Parity: not assessed as a matched-parameter row.  This is frozen R-only
optimizer evidence.  Its best result, five-start BFGS at
`1.8505189364e-6`, exceeds the signed `1e-6` source-gradient gate, so no Julia
parameter comparison was run or claimed.

### JET / Allocs / Aqua verdicts

- JET: N/A — no Julia engine source changed.
- Allocs: N/A — no Julia hot path changed.
- Aqua: N/A — no exports, dependencies, or Julia package structure changed.

## 7a. Issue Ledger

No issue action is needed: this is approved local Destination B evidence work.
FRK remains parked at `gllvmTMB#1275`; there was no push, merge, release, or
registry action.

## 8. Consistency Audit

Ran:

```sh
rg -n 'Destination B|joint Gaussian|stationary reference|optimizer diagnostic' \
  README.md CLAUDE.md docs/src docs/dev-log/core070/destination-b-b1 docs/dev-log/after-task
rg -n 'Gaussian only|not yet implemented|planned next|TODO|FIXME' README.md docs/src CLAUDE.md
```

The public documentation retains partial-parity wording.  No user-facing API
or documentation claim changed; the new record is internal evidence only.

## 9. What Did Not Go Smoothly

The source's `start_method = list(method = "indep")` preliminary model does
not admit `cluster2`; it warns and uses default starts.  The ten-start nlminb
and five-start BFGS controls improve the objective/score but neither crosses
the predeclared stationarity boundary.  The current fixture has no proven
continuous covariance alias, so this is retained as finite-sample optimizer
conditioning rather than rewritten as an identification explanation.

## 10. Known Residuals

- No stationary frozen-R joint reference exists for this exact fixture.
- The B1 joint row lacks independently fitted R--Julia parameter evidence,
  intervals, recovery, and public bridge admission.
- The frozen source cannot apply its automatic independent warm start to a
  four-slot model containing `cluster2`.

## 11. Team Learning

Use source restart histories and actual warm-start provenance, not requested
control labels or convergence codes, when deciding whether a frozen reference
can serve as a numerical comparator.

## 12. Cross-Product Coverage

This result does not qualify B1, any non-Gaussian grouped model, S3b/S4,
dense `vcv`, `engine = "julia"`, 0.7/0.7.1 parity, coverage, FRK, release, or
registry eligibility.

It does NOT cover a stationary R--Julia paired fit, interval feasibility,
recovery, public formula admission, other covariance structures, other
families, or any coverage campaign.

### Next command

Do not widen the tolerance.  Before another fit, write and review a separate
`start_from` ladder whose preliminary model and copied blocks are explicitly
proved compatible with `cluster2`, or construct a new predeclared stationary
joint reference design without selecting a seed after observing results.

### Rose verdict

Rose verdict: PASS WITH NOTES — the optimizer-probe evidence is complete and
honest, but the B1 joint capability row remains blocked by the retained
non-stationary frozen-R reference.
