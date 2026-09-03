# Frozen data-control contract: ordering, masks and offsets

56 source-helper cases pass on frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86.
The exact calls and hand-declared outputs/errors are in
`test/parity/fixtures/core070_data_controls.R`. This extends DATA-01/DATA-02 with
finite shape and policy cases; it does not complete their fitted-model obligations.

## Source boundary

Run actual `normalise_weights`, offset helpers and `miss_control` from the frozen
source in a disposable R environment. Evaluate only the selected miss_control
function from the public entry file. No installed package, model fit, TMB object,
latent score or postfit prediction runs. All source hashes match the saved oracle
inventory; process/log hashes and exact output vectors are retained. Constructor
acceptance and helper return values are not complete public model admission.

## Weight order is part of the model contract

For2 units and3 traits, site weights10/20 give:

| Input route | Long vector | Retained masked cells |
|---|---|---|
| R wide matrix (units × traits) |10,20,10,20,10,20|Masked entries zeroed when drop_masked=FALSE|
| R traits() data frame |10,10,10,20,20,20|Site weights retained at masked entries when drop_masked=FALSE|
| R long |Exactly supplied order|Length must equal the helper's n_obs; scalar not broadcast|

Matrix input accepts a scalar, one weight per unit, or a matching units×traits
matrix; it rejects a flattened per-cell vector and a transposed matrix. Matrix
weights' NAs must match response-mask cells exactly. traits() input requires one
weight per unit and rejects scalar and matrix forms. Both routes drop masked
entries in their respective order when requested. Negative/non-finite observed
weights reject; zero and fractional weights pass this helper. Fractional acceptance
does not prove a valid binomial trial count: family-specific validation comes later.
Do not confuse trial counts with likelihood weights or weighting-based inference.

Julia native binomial N is traits×units. For the example above it is
`[10 20; 10 20; 10 20]`, whose column-major vector equals the R traits() order, not
R matrix order. A matrix adapter must transpose the R units×traits matrix; a
long adapter must map explicit unit/trait keys. These are required adapter contracts,
not tested Julia/RCall/JuliaCall fit equivalence in this slice. B4/B5 still owe
response/trial/offset/mask alignment and exact fitted model comparisons.

## Missingness controls and offsets

miss_control defaults to response='drop', predictor='fail', engine='laplace'.
'include' and predictor='model' are accepted controls, but they do not admit all
families/structures. Reserved engines em/profile and unknown engines reject.
`estimator='REML'` produces R's unused-argument error before the body's intended
custom guard can run; do not promise the unreachable custom diagnostic.

Training offsets accept NULL/zero, a scalar or a row vector; nonzero ordinary
offsets admit count family IDs2/5/10/11/15 only. Mixed rows permit zeros on other
families. Non-numeric, wrong-length, missing-variable and non-finite training
offsets reject. The ISDM cloglog exception is covered separately by its existing
contract and is not generalized here.

Stored training offsets preserve row alignment, with zero fallback for old fits.
The new-data helper re-evaluates the expression and rejects absent variables, but
returns -Inf for log(0) in this probe. This differs from training validation;
it is a source-helper observation, not proof of full prediction behavior or a
reason to silently reproduce unsafe arithmetic. Any stronger Julia diagnostic or
semantic difference must be explicit and tested at the public interface.

## Tests of the tests and remaining work

Changing only the declared matrix-unit expected vector to traits() order makes
that case fail:55pass/1fail, exit1. Eight metadata controls reject stale source,
reference/count/case changes, corrupt receipts and false installed/native claims.
Final positive run56pass; no production or frozen-source edit.

Each rejected-input case is a source compatibility/rejection requirement; admitted
value cases are required data-information obligations. Exact calls, expected
outcomes and stable IDs live in the fixture. Owner B4 (data), coordinating with
B2(formula) and B5(bridge). All native/formula/bridge numerical statuses remain
UNQUALIFIED. Next freeze complete long/wide/categorical/missing/trial fixtures,
family-conditioned counts, actual fit preparation and postfit row recovery. Full
manifest DRAFT, M1 PARTIAL; no numeric parity or release claim.
