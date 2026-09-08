# Destination B A4/S4 paired-evidence acceptance boundary

## Scope and route

This is a closed, private candidate-evidence harness for exactly three Gaussian
rows.  It is not a public R formula admission and it does not change a public
capability claim.  The only candidate call permitted in the runner is
`GLLVM.bridge_fit(..., phylo = ..., options = list(phylo_model = "multivariate", ...))`.
The intended Julia route is `_bridge_fit_precision_multivariate`; a public
formula call is neither a substitute nor evidence for this matrix.

Every terminal record must retain `qualified = false` and
`r_public_admission = "closed"`.  A raw bridge return is an input to later
review, not a passing paired-evidence result.

Raw bridge transport uses the distinct schema
`destination-b-a4-s4-private-bridge-raw-1` with status
`raw_bridge_returns_recorded_unqualified`.  The verifier recognizes that schema, checks
its provenance, canonical precision, repeated observation map, closed bridge
admission, and CI-request boundary, then returns an explicitly unqualified
raw-candidate verdict.  It cannot be passed off as the full
`destination-b-a4-s4-paired-matrix-1` paired-evidence schema, which also
requires matched-point and own-optimum evidence.

## Prescribed rows

| Row id | Fixed fixture fact | Canonical precision fact | Interval state |
| --- | --- | --- | --- |
| `tree_height4_nonunit_ultrametric` | height 4; nonunit ultrametric | inherited `Q` scale 4 | retained 12-target transformed-Wald contract |
| `pedigree_12_nodes_8_observed_4_unobserved` | 12 nodes: 8 observed, 4 unobserved ancestors | inherited `Q` scale 1 | retained 12-target transformed-Wald contract |
| `dense_vcv_ridged_once` | dense VCV source | form `A + 1e-8 I`, invert once, then consume that canonical `Q`; inherited scale 1 | unavailable; do not synthesize 12 intervals |

The frozen R source pin is `b4d5fee64def88bc768dda1f1f77c29b295edd86`.
The frozen DLL SHA-256 is
`91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb`.
The verifier rejects a substituted frozen source, DLL, response hash, precision
log determinant, inherited scale, map, or dense ridge rule.  The Julia source
hash is dynamic runner metadata: it is checked for same-document consistency
only and is explicitly `runner_recorded_unverified`, not immutable source
proof.
The `species_id` passed to the private bridge is the fixture's repeated
16-observation, one-based tip map; `species_aug_id` is separately retained as
the eight-tip-to-augmented-node map.  The tree has 14 augmented nodes, the
pedigree 12, and the dense VCV 8.  A runner may not replace either map with an
eight-row observation map.

## Coordinate alignment

The fitted R coordinate order is

`[b_fix[1], b_fix[2], b_fix[3], log_sigma_eps, theta_rr_phy[1:3]]`.

The paired Julia parameter order is

`[beta; pack_lambda(Lambda); log_sd_residual_shared]`.

Thus `b_fix[3]` is `beta[3]`, `log_sigma_eps` is the shared residual log
standard deviation, and `theta_rr_phy[3]` is the third element of the packed
rank-one loading.  The comparison must preserve that order; it must not move
the residual coordinate after the loading block simply because Julia displays
its parameter vector that way.

For rank one, the sign of `theta_rr_phy` / `Lambda` is not identified: a
simultaneous sign flip produces the same `Lambda * Lambda'`.  Signed loading
comparisons are therefore diagnostic only after an explicit shared sign
convention; the invariant covariance comparison is `Lambda * Lambda'`.

`sigma2_phy` is fixed at 1 for all three rows.  The only precision scaling is
the one inherited from the respective frozen input above.  Do not introduce a
second rescale while transporting a `Q`, and do not silently normalize the
tree's scale-4 precision to scale 1.

## Two gates, kept separate

1. **Matched point.** Evaluate both marginal objectives at the same declared
   coordinate point and require the declared objective difference to agree
   numerically.  This is a target/transport gate, not an optimizer claim.
2. **Own optimum.** Each engine's independently obtained point needs a
   converged optimizer, finite gradient norm at most `1e-5`, and a positive
   Hessian with positive minimum eigenvalue.  This is an optimizer diagnostic,
   not interval coverage and not public admission.

The matrix verifier requires a declared interval target.  Tree and pedigree
retain their 12 target names; dense explicitly records `status = "unavailable"`
and `method = "not_run"`.  Dense uncertainty is incomplete, hence remains
unqualified even if point-objective diagnostics later agree.

## TDD receipt (this slice)

- RED: `julia --project=. test/test_destination_b_a4_s4_receipts.jl` failed
  because `tools/destination_b/verify_a4_s4_paired_matrix.jl` did not yet
  exist.
- GREEN: the same command passed `16/16` after the verifier was implemented,
  including mutations for source, DLL, Julia/data hashes, log determinant,
  inherited scale, map, dense ridge, optimizer, gradient, Hessian, interval
  target, and an attempted qualification.
- No candidate fit or successful paired-evidence receipt was run or written in
  this slice.

## Repair TDD receipt (bridge contract)

- RED: after adding a runner-shaped raw document, the focused test failed
  because the first verifier incorrectly required the old one-to-one
  eight-item map (`missing ... map.n_observed`).
- GREEN: the focused command passed `25/25` after validation was changed to
  the real 16-observation `species_id` map, fixed tree/pedigree/dense node
  counts, and the locked finite signed `log_det` values.  The test also rejects
  a changed finite log determinant, sign reversal, malformed repeated map,
  wrong tree node count, and a dense Wald request.
- The runner now passes `options$species_id = bundle$species_id`, uses the
  flat payload's `log_det`, and requests `ci_method = "none"` for dense.  No
  live fit batch was run.

## Repair TDD receipt (raw interval truthfulness)

- RED: a raw tree/pedigree record with bridge `ci_status = "unavailable"` or
  `"partial"` still claimed an available transformed-Wald target; the focused
  verifier did not compare the target to the bridge result.
- GREEN: the runner now derives the raw target names, status, and method from
  the returned bridge CI fields.  The verifier requires equality with those
  fields: only an all-target available transformed-Wald result can be recorded
  as available; other returned statuses use `bridge_reported`.  Dense is
  separately fixed to `ci_method = "none"`, bridge `not_requested`, and an
  unavailable/no-target record.
- The verifier also now locks the exact eight-species-to-augmented-node maps:
  tree `[13,6,11,8,12,7,10,9]`, pedigree `[11,4,8,6,9,5,10,7]`, and dense
  `[0,1,2,3,4,5,6,7]`.  No live fit batch was run.

## Evidence-integrity boundary

Each row now binds to its retained response hash and immutable reference-file
hash.  The canonical precision payload is bound by the immutable
`fixtures-01.json` SHA-256, with the tree/pedigree precision-reference SHA or
dense retained-reference SHA recorded separately.  This prevents a coordinated
change to a row's self-reported data/Q hashes from becoming evidence.  Dense
also binds its one-ridge claim to the retained operation
`A_ridged = A_original + 1e-8 * I; Q_canonical = solve(A_ridged)` and the
retained source hash.

The fixed 12-target order is enforced for tree and pedigree, not merely a
length-12 string vector.  Boolean values are rejected where finite numbers are
required, and a gradient norm must lie in `[0, 1e-5]`.

There are no grounded A4/S4 matched-point or independent-own-optimum artifact
identifiers yet.  Consequently the paired schema is now explicitly
`paired_evidence_unavailable`: it documents the required R/Julia coordinate
orders and `sigma2_phy = 1`, but rejects any ungrounded matched/own-optimum
payload instead of treating arbitrary SHA-shaped strings as evidence.  Raw
private transport remains schema-validatable and unqualified.

## Evidence-integrity TDD receipt

- RED: the new adversarial cases showed that a row could substitute its own
  data/reference/Q hashes, use an arbitrary 12-name target vector, supply a
  boolean or negative gradient norm, or attach SHA-shaped but ungrounded paired
  artifacts.
- GREEN: `julia --project=. test/test_destination_b_a4_s4_receipts.jl` passed
  `35/35` after static retained-source bindings, the exact coordinate/target
  contracts, numeric checks, and the fail-closed unavailable paired state were
  added.  `Rscript -e 'parse(file="tools/destination_b/run_a4_s4_paired_matrix.R")'`
  also parsed successfully.
- No live fit, simulation, or candidate-success receipt was run or written.

## Raw-provenance and CI TDD receipt

- RED: the focused receipt test failed (`42` passed, `9` failed) when it
  required every raw RDS and CI payload to say
  `runner_recorded_unverified`, rejected any claimed authenticated/bound/
  verified artifact, and removed `verified` from the verifier's raw verdict.
  The pre-repair verifier accepted those stronger claims.
- GREEN: `julia --project=. test/test_destination_b_a4_s4_receipts.jl` passed
  `51/51`.  Raw execution provenance now records the Julia executable and
  Project/Manifest hashes plus Git commit and dirty state as
  `runner_recorded_unverified`; it is intentionally not authenticated engine
  evidence.  Each terminal-row RDS SHA and CI payload is likewise only a
  runner-recorded field: this schema verifier does not open or recompute an
  RDS, and therefore makes no artifact-binding claim.
- Tree/pedigree CI records permit only statuses defined by the private bridge
  code (`available`, `partial`, `not_converged`, `nonidentifiable`,
  `invalid_objective`, `not_stationary`, or `invalid_curvature`) with their
  corresponding per-target status/method schema.  This is semantic validation,
  not source authentication. Dense alone remains `not_requested` with no
  targets. No live fit was run.

## Dynamic-source and map-type TDD receipt

- RED: the focused test failed (`54` passed, `6` failed) when a Julia source
  hash claimed `authenticated`, `bound`, or `verified`, and when dense map
  vectors carried Boolean indices.  The first Boolean fixture assigned into an
  integer vector was corrected to an `Any` vector so the verifier actually saw
  Boolean payloads rather than coerced `0`/`1` values.
- GREEN: `julia --project=. test/test_destination_b_a4_s4_receipts.jl` passed
  `60/60`.  `julia_source_sha256` is now explicitly
  `runner_recorded_unverified` dynamic metadata; the verifier preserves only
  same-document equality between the row and provenance fields.  All three map
  vectors reject both `true` and `false` before their range/map checks.
- No live fit, RDS readback, public formula admission, or paired-evidence
  qualification was attempted.

## JSON response-decoding TDD receipt

- RED: `Rscript test/test_destination_b_a4_s4_runner.R` failed because the
  required reusable decoder did not exist.  The retained-reference diagnostic
  confirmed the cause: with `simplifyVector = FALSE`, each response is three
  trait rows represented as lists of 16 numeric scalars, not an R matrix.
- GREEN: the same test prints `A4_S4_JSON_MATRIX_OK` after decoding tree,
  pedigree, and dense retained responses as finite numeric `3 x 16` matrices,
  checking their first entries, and rejecting malformed, ragged, and
  non-numeric payloads.  The pre-existing focused Julia receipt test remains
  `60/60` and both R sources parse.
- The runner now sources this decoder and rejects any response not exactly a
  finite `3 x 16` matrix before species-map validation or JuliaCall.  No Julia
  setup, bridge call, fit, RDS readback, or public admission was run.
