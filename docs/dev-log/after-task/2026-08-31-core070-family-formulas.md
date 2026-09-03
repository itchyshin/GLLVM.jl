# Required Poisson, Beta and truncated-NB2 formula checkpoint

## 1. Goal
Register and exercise the original Poisson, Beta and truncated-NB2 models through
wide and reordered complete long Julia formulas, retaining native/R health.

## 2. Implemented
Three stable formula IDs, executable contracts, source-map links and prerequisite
checks. Formula cases require their matching native case in the same invocation.
Shared formula fixture preserves original data, controls and all coordinates.
No src/ or original native fixture changes in this slice.

## 3a. Decisions and Rejected Alternatives
Keep formula/native/bridge roles separate. Do not count a successful formula fit
with historical native health. Explicit observed curvature on truncated NB2 is a
requested control: its fitted object does not store that field. Do not fabricate
fitted metadata or new gradients. Preserve original failed R fits and declared
public start_from/BFGS continuation policies.

## 4. Files Touched
Required registry, test helpers/wrappers, registry tests, executable contracts,
source mapping and generated family plan; current subset verifier and metadata
expectations; evidence and developer-log/checkpoint records. Foreign lanes and
R reference source remain untouched.

## 5. Checks Run
Totoro baseline registry failed the missing three registrations in7.08s. Final
registry40assertions/5.08s; ten-case required native/R/formula replay187assertions
across9executions in109.78s; frozen oracle checks before/after PASS. Each formula
case contributes22assertions, including malformed row/missing/duplicate inputs.
All native/R final absolute gradients<=1e-4 under their recorded policies.
Local metadata42tests and evidence self-test PASS. Exact source/fixture/runtime,
raw R values/maps, numeric report hashes and formula/native equality verified by
python3 tools/core070_verify_family_formulas.py --self-test.

## 6. Tests of the Tests
Twenty-one formula corruptions plus22 registered-case negative controls reject
changed data, control policy, missing native binding, failed convergence,
changed parameters/likelihood, missing cases and malformed-input false success.
The unchanged registry regression fails before and passes after registration.
Full-family guards still reject all five linked models without public R bridge.
Unlazy3/4 gates reverified; full-programme gate remains unpaid.

## 7a. Issue Ledger
Ten executable links now cover five source family facts partially.710other
nonexcluded source facts remain unmapped; these are source facts, not model counts.
Next qualify public R bridge for these same models and bind remaining native
family/AGHQ/covariance/data/postfit cases. Broader formula grammar remains unproved.

## 8. Consistency Audit
Required registry has17family IDs,1extra native model ID and5formula IDs,23total.
The ten-case replay is a subset, not all17 or complete family coverage. Shared
Gaussian assertions count once. Source classifications unchanged. Generated
family plan remains97planned cases, with5native+5formula+16boundary bindings.
Earlier seven-case receipts are historical after changed execution inputs.

## 9. What Did Not Go Smoothly
Metadata checks caught missing obligation rows and stale expected counts; fixed
those records without weakening the checker. First ten-case replay passed
Poisson/Beta but failed when the new report accessed nonexistent truncated-NB2
hessian metadata. Source review confirmed the explicit fitter keyword and
observed default; corrected the report/provenance and reran the entire subset.
Both failed baseline and first replay remain retained.

## 10. Known Residuals
Full suites and specific external numerical review still await existing approval.
JET/Aqua/Allocs/full package suites NOT RUN in this slice. No new documentation
render needed for developer-only case records; previous site evidence remains
scoped to its unchanged public docs/source. Rose verdict NOT REQUESTED for this
interim checkpoint; no independent completion sign-off. No revised hours claim.

## 11. Team Learning
Ada parent performed this bounded harness integration. No child model, effort or
agent-hour receipt invented. Read actual fitted-object fields before reporting
controls; a requested estimator option and retained fit metadata are distinct.

## 12. Cross-Product Coverage
This checkpoint does NOT cover public R bridge, all family variants, site
covariates/general formula grammar, full Stage1a AGHQ, covariance/modifiers,
missing-data/postfit/inference contracts, recovery/coverage, performance or final
Documenter polish. No push, merge, release, destructive cleanup or DRAC allocation.
All Totoro child processes ended. Original R0.7.0 pin and R0.7.1/article separation
are unchanged. Continue from the public bridge/runtime and remaining contract gaps.
