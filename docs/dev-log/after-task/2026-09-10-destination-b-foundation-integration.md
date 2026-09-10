# After Task: Destination B foundation integration candidate

## Goal

Replay the authorised Destination B implementation onto current GLLVM.jl while
preserving the published landing mark, and remove the S4 formula-receipt merge
barrier without treating a scaffold as R--Julia evidence.

## Implemented

Local-only candidate commits `154bc848`, `84801781`, `5f1e50f1`, and
`f422412c` bring in the shared grouping engine, multivariate precision
consumer, bounded bridge materials, and corrected S4 formula contract. The
previous SVG hero declaration was removed so the published Image 2.5 PNG mark
remains the only landing hero. The S4 receipt test is now part of
`test/runtests.jl`.

Fresh review then corrected two candidate defects. Synthetic in-memory
attestations can now be used only with `allow_synthetic = true` and return a
synthetic status; the default validator rejects them. A non-synthetic
structural receipt must name an explicit kind and retained artifact, and the
validator never labels a structural dictionary fresh. The grouped unpacker now
uses a concrete unique-variance vector rather than `Any[]`.

## Mathematical Contract

The grouped Gaussian route retains the documented marginal model
\(\eta = X\beta + \sum_q Z_q b_q\), with each `Z_q` an incidence matrix and
each selected term contributing its own trait covariance. The precision route
retains the frozen-R transport convention, including the dense-`vcv`
ridged-once canonical precision; it does not reinvert in Julia. See
`docs/dev-log/decisions/destination-b-grouped-fit.md` and
`docs/dev-log/decisions/destination-b-transport-conventions.md`.

## Files Changed

- `src/`: grouped Gaussian/Laplace/profile implementation, multivariate
  precision consumer, formula and public dispatch wiring from the foundation;
  `src/grouped_fit.jl` additionally makes unique variances concrete.
- `test/`: grouped, precision, interval, bridge and S4 contract coverage;
  `test/runtests.jl` includes the S4 validator; the new concrete-container
  assertion is in `test/test_grouped_gaussian.jl`; the joint-identification
  test now checks the structural nonidentifiability diagnostic rather than a
  platform-sensitive finite-difference sign. The A4/S4 public dense-precision
  bridge regression and the receipt-backed frozen-R B1 same-data paired
  unit-fit regression are now registered in the normal test runner.
- `docs/`: Destination B contracts, retained non-promotional evidence,
  grouping/precision guides, check log, and this report. `README.md` now
  repeats the experimental partial R-to-Julia, not-0.7-parity boundary.
- `tools/destination_b/b1_unit_gaussian_reference.R`: the frozen-R runner now
  retains the actual long response and named fitted coordinates required by
  the paired receipt; it neither changes nor rebuilds the R engine source.

## Tests Added

- S4 synthetic-fixture and retagging rejection: failed before the repair
  because the default validator accepted missing/changed provenance tags; now
  passes and exercises the explicit failure paths.
- Grouped concrete-unique container: failed before the repair with
  `Any === Union{Nothing,Vector{Float64}}`; now passes.
- Joint-identification sign gate: the prior fixed Hessian-sign expectations
  failed under the same structurally redundant four-coordinate/two-trait
  model. The replacement preserves finite curvature output but requires the
  actual invariant, `:nonidentifiable` intervals and unavailable component
  intervals. No optimizer or tolerance was changed.
- Public dense-precision bridge: a retained R-canonical dense payload is fed
  through public `bridge_fit` at fixed Julia coordinates. A symmetric
  twice-ridged counterfactual must change the likelihood, while both paths
  retain the closed `R phylo_rr` admission fence.
- B1 paired Gaussian `unit`: a machine-readable fresh frozen-R receipt binds
  source, archive, shared library, runner, data, mapping, and named fit
  quantities. The normal test reconstructs its exact response, validates those
  locks, checks a fixed-R-coordinate Julia objective and an independent Julia
  refit, and rejects a changed unit membership.
- Existing grouped dense-oracle and precision sparse-vs-dense tests remain the
  independent-calculation safeguards for the imported numerical kernels.

## Benchmark Numbers

N/A — this integration repairs a container type and evidence boundary; no
speed claim or benchmark comparison was made.

## R-Parity Verdict

Not qualified. One fresh source-attested B1 `unit` Gaussian paired fit now
exists: frozen R 0.7.0 at `b4d5fee64def88bc768dda1f1f77c29b295edd86` and the
Julia public grouped route share the same retained 2-trait × 8-observation
response, unit partition, marginal log likelihood, trait intercepts,
rotation-invariant unit covariance, and residual SD. It is a single tiny
Gaussian interior fit, with no interval or recovery evidence. S3b/S4 public
admission remains closed because `phylo_dep()` structured Julia transport and
its interval mapping are not admitted.

## JET / Allocs / Aqua Verdicts

- JET: not separately run for the new grouped unpacker in this slice; the
  concrete-container regression test addresses the reviewed hot-path finding.
- Allocs: not measured; no allocation or speed claim is made.
- Aqua: not reached in the retained full-suite run, which stopped earlier on a
  missing `Optim` declaration in `test/Project.toml`; a repaired full-suite
  receipt is still required.

## Checks Run

- `test/test_destination_b_a4_s4_public_r_formula_receipt.jl`: 29 passed,
  0 failed, 0 errored (0.8 s).
- `test/test_grouped_gaussian.jl`: 26 passed, 0 failed, 0 errored (3.3 s).
- `OPENBLAS_NUM_THREADS=1 GLLVM_TEST_SHARD=89/293 Pkg.test()`: 64 passed,
  0 failed, 0 errored (14.1 s); expected warnings identify the redundant
  `unit` and `unit_obs` sources.
- `OPENBLAS_NUM_THREADS=1 GLLVM_TEST_SHARD=48/293 Pkg.test()`: 31 passed,
  0 failed, 0 errored (4.1 s). This isolates the EM-Louis file reported in
  the interrupted aggregate run; its current candidate gate is reproducibly
  green, with no tolerance change.
- `OPENBLAS_NUM_THREADS=1 GLLVM_TEST_SHARD=163/294 Pkg.test()`: 12 passed,
  0 failed, 0 errored (7.5 s), exercising the public canonical-dense bridge
  plus its twice-ridged negative control. Fresh review found no P0/P1/P2
  issue in the registered test.
- Fresh frozen-R B1 rebuild: detached `b4d5fee64def88bc768dda1f1f77c29b295edd86`
  source, archive SHA-256 `0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc`,
  and a new isolated shared library SHA-256
  `3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30`.
  The R fit converged in 0.46 s with log likelihood `-6.6816691133163673`.
  `docs/dev-log/core070/destination-b-b1/frozen-r070-unit-gaussian-paired-receipt-20260910.json`
  retains the exact source/build/input/fit fields. `OPENBLAS_NUM_THREADS=1
  GLLVM_TEST_SHARD=154/295 Pkg.test()` then passed 20/20 in 5.6 s, including
  the same-data Julia refit and changed-membership negative control.
- Earlier integrated focused cohort: 292 passed assertions across grouped
  Gaussian/fitter/public/fixed-coordinate, four-level interval, and
  multivariate precision tests.
- `julia --project=. test/runtests.jl`: unsharded driver listed 294 files and
  returned cleanly; the environment did not preserve a per-assertion tally.
- Retained `Pkg.test()` receipt: 776 passed, 0 failed, 1 errored, 3 broken;
  the error was `Package Optim not found` at
  `test_grouped_profile_dense_oracle.jl`. The missing test dependency was
  added, then the CI-style `GLLVM_TEST_SHARD=23/294 Pkg.test()` passed
  15/15 in 8.3 s. The repaired unsharded run passed that point but showed an
  an apparent EM-Louis tolerance miss and a sign-sensitive
  joint-identification assertion defect. The exact EM-Louis (31/31) and joint
  (64/64) shards now pass; the latter has the test-only invariant repair. The
  aggregate run was stopped after 18 minutes of CPU activity, beyond the
  measured estimate. A fresh full-suite receipt remains pending.

## Consistency Audit

Searched `README.md`, `docs/src`, and `docs/PERF-plus-design.md` for
`Gaussian only|not yet implemented|planned next|TODO|FIXME|340.?x|machine precision|closed.?form|gllvmTMB|R reference|read.?only reference`.
The landing and README retain partial-bridge wording. Historical documents
remain as records rather than being rewritten.

## GitHub Issue Maintenance

No issue action: this is a local candidate; no push, merge to `main`, release,
registry action, or FRK action was authorised. FRK remains parked at
gllvmTMB#1275.

## What Did Not Go Smoothly

The initial merged S4 test could be misread as evidence because its fabricated
receipt used fresh-attestation labels. Independent review caught it before
promotion. The retained full `Pkg.test()` receipt then exposed a missing
`Optim` declaration for an imported dense-oracle test. The exact CI-style
shard passes after the minimal dependency repair. The full rerun also revealed
an EM-Louis tolerance miss and sign-sensitive Destination-B
joint-identification expectations. The latter now have a passing 64/64
focused receipt against the stable nonidentifiability invariant. The EM-Louis
file also passes its exact package-test shard, 31/31; neither repair changed a
tolerance. The aggregate rerun was stopped after its measured runtime overrun.
The retained A4/S4 evaluator was deliberately not normal-suite-safe because it
launches CLI subprocesses; its public dense bridge coverage now lives in a
small separate registered test rather than making routine CI depend on those
subprocesses. The earlier B1 source-attested R library had been purged from
`/private/tmp`; it was rebuilt only from the exact frozen Git object into a
new isolated temporary library, never from the dirty 0.7.1 working checkout.

## Remaining Risks and Next Command

This candidate is not a Destination B qualification. Required next work is a
paired Gaussian `cluster2` B1 fit and joint-grouping evidence; a reviewed
structured `phylo_dep()` Julia transport/interval route; independent recovery;
and a retained full-suite quality receipt. If a fresh controlled full run
reproduces its earlier EM message, it must be investigated as a
load-order/environment effect rather than repaired by a tolerance change.
Resume with:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Rose verdict: FAIL — local integration is coherent, but full quality receipt,
live S3b/S4 pairing, and recovery evidence are still absent; no completion or
parity claim is permitted.

## Addendum — B1 nested `unit_obs` paired receipt

The candidate now retains a second, distinct B1 Gaussian pair at
`docs/dev-log/core070/destination-b-b1/frozen-r070-unit-obs-gaussian-paired-receipt-20260910.json`.
It is frozen-R 0.7.0 source/build attested and uses a deterministic nested,
replicated diagonal W-tier design: two traits, 12 units, two `unit_obs` groups
per unit, and two measurements per group--trait cell. The R fit converged at
`-50.296108604526843`; the normal Julia package test locks source, archive,
shared-library, data, runner, formula and convergence provenance, matches its
fixed coordinates and independent Julia refit, and detects a changed valid
within-unit incidence. `OPENBLAS_NUM_THREADS=1 GLLVM_TEST_SHARD=155/296
Pkg.test()` passes 23/23 in 6.1 s.

Independent numerical review found no P0/P2 issue. Its two P1 evidence
findings (missing provenance locks and stale future-tense alignment wording)
were repaired and rerun. Rose's programme verdict remains **FAIL**: this
addendum records the nested diagonal Gaussian `unit_obs` fit. The subsequent
crossed diagonal `cluster` pair is recorded below; latent W, intervals,
recovery, coverage, `cluster2`, S3b/S4, dense-`vcv`, generic Julia-engine,
broad 0.7 parity, and Destination B completion remain absent.

## Addendum — B1 crossed `cluster` paired receipt

The candidate now retains a third distinct B1 Gaussian pair at
`docs/dev-log/core070/destination-b-b1/frozen-r070-cluster-gaussian-paired-receipt-20260910.json`.
It is frozen-R 0.7.0 source/build attested and uses a deterministic crossed,
replicated diagonal cluster-tier design: two traits, six clusters, the same
four unit labels recurring in every cluster, and two measurements per
unit--cluster cell. No unit covariance is selected. The R fit converged at
`-9.3696900475934175`; the normal Julia package test locks source, archive,
shared-library, data, runner, formula and convergence provenance, matches its
fixed coordinates and independent Julia refit, and detects a changed cluster
incidence. `OPENBLAS_NUM_THREADS=1 GLLVM_TEST_SHARD=156/297 Pkg.test()` passes
20/20 in 5.8 s.

Independent re-review found no P0/P1/P2 issue after the fixture was corrected
from an accidentally nested first draft. Rose's programme verdict remains
**FAIL**: these are three individual B1 Gaussian source-alignment pairs, not
joint grouping, `cluster2`, interval/recovery/coverage, S3b/S4, dense-`vcv`,
generic Julia-engine, broad 0.7 parity, or Destination B completion evidence.
