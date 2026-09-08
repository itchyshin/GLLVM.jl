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
`raw_bridge_returns_recorded`.  The verifier recognizes that schema, checks
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
The verifier rejects a substituted source, DLL, Julia source hash, response
hash, precision log determinant, inherited scale, map, or dense ridge rule.
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
