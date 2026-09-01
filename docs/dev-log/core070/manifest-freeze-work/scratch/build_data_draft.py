import json

ANNEX = "docs/dev-log/core070/data-required-case-plan.json"
FIXTURE = "test/parity/fixtures/core070_data_controls.R"

def row(source_id, case_id, r_call, julia_surface, comparands, evidence_kind, rationale):
    return {
        "source_id": f"data/{source_id}",
        "planned_case_ids": [case_id],
        "case_plan_annex": ANNEX,
        "case_specs": [{
            "case_id": case_id,
            "r_call": r_call,
            "julia_surface": julia_surface,
            "comparands": comparands,
            "evidence_kind": evidence_kind,
        }],
        "rationale": rationale,
        "reclassify": None,
        "uncertain": False,
    }

rows = []

# --- miss_control default/override behavior ------------------------------
rows.append(row(
    "DATA-MISS-DEFAULT", "CORE070-DATA-MISS-DEFAULT-CONTROL",
    f"miss_control() from frozen R source ({FIXTURE}#DATA-MISS-DEFAULT); "
    "expected list(response='drop', predictor='fail', engine='laplace').",
    "Julia missing-data control constructor (planned: e.g. MissingDataControl() "
    "or the fit()-level miss= keyword default) must expose the same three "
    "defaults: response drop, predictor fail, engine laplace.",
    ["R miss_control() defaults", "Julia missing-data control defaults"],
    "control",
    "Pure default-value contract with no Julia counterpart yet; a public "
    "fit()-facing control object or keyword set must reproduce these three "
    "defaults before the family/data-handling manifest can close.",
))

rows.append(row(
    "DATA-MISS-INCLUDE", "CORE070-DATA-MISS-INCLUDE-CONTROL",
    f"miss_control(response='include') ({FIXTURE}#DATA-MISS-INCLUDE); "
    "expected response='include' with predictor/engine defaults unchanged.",
    "Julia control constructor must accept an independent response="
    "override (e.g. :include) leaving predictor/engine defaults untouched.",
    ["R miss_control(response='include')", "Julia control with response override"],
    "control",
    "Single-argument override case for the same control object; verifies "
    "argument independence, not just the all-defaults case.",
))

rows.append(row(
    "DATA-MISS-MODEL", "CORE070-DATA-MISS-MODEL-CONTROL",
    f"miss_control(predictor='model') ({FIXTURE}#DATA-MISS-MODEL); "
    "expected predictor='model' with response/engine defaults unchanged.",
    "Julia control constructor must accept an independent predictor="
    "override (e.g. :model) leaving response/engine defaults untouched.",
    ["R miss_control(predictor='model')", "Julia control with predictor override"],
    "control",
    "Single-argument override case complementary to DATA-MISS-INCLUDE; "
    "together they pin that the two axes are independently settable.",
))

rows.append(row(
    "DATA-MISS-BOTH", "CORE070-DATA-MISS-BOTH-CONTROL",
    f"miss_control('include','model') ({FIXTURE}#DATA-MISS-BOTH); "
    "expected response='include', predictor='model', engine='laplace'.",
    "Julia control constructor must accept both response and predictor "
    "overrides simultaneously while leaving engine at its default.",
    ["R miss_control('include','model')", "Julia control with both overrides"],
    "control",
    "Joint-override case closing out the miss_control() default/override "
    "family alongside DATA-MISS-DEFAULT/INCLUDE/MODEL.",
))

# --- offset preparation (gll_prepare_offset) ------------------------------
rows.append(row(
    "DATA-OFF-NONE", "CORE070-DATA-OFF-NONE-NATIVE",
    f"gll_prepare_offset(NULL, ...) via off(NULL) ({FIXTURE}#DATA-OFF-NONE); "
    "expected rep(0,3) -- absent offset defaults to zero per row.",
    "Julia offset-preparation surface (planned: prepare_offset()/offset "
    "handling inside the family fit driver) must default an absent offset "
    "expression to a zero vector of length n_obs.",
    ["R gll_prepare_offset(NULL,...)", "Julia offset default (no offset given)"],
    "native",
    "Baseline no-offset case anchoring the offset-preparation contract; "
    "every other DATA-OFF-* row is a variant of this same helper.",
))

rows.append(row(
    "DATA-OFF-SCALAR", "CORE070-DATA-OFF-SCALAR-NATIVE",
    f"gll_prepare_offset(quote(log(2)), ...) ({FIXTURE}#DATA-OFF-SCALAR); "
    "expected rep(log(2),3) -- a constant expression broadcasts to all rows.",
    "Julia offset-preparation surface must broadcast a constant offset "
    "expression/value to a per-row vector of the training length.",
    ["R constant offset broadcast", "Julia constant offset broadcast"],
    "native",
    "Confirms scalar-expression broadcasting, distinct from the per-row "
    "exposure case (DATA-OFF-EXPOSURE).",
))

rows.append(row(
    "DATA-OFF-EXPOSURE", "CORE070-DATA-OFF-EXPOSURE-NATIVE",
    f"gll_prepare_offset(quote(log(e)), ...) ({FIXTURE}#DATA-OFF-EXPOSURE); "
    "expected log(c(1,2,4)) -- log-exposure offset evaluated per row from data.",
    "Julia offset-preparation surface must evaluate a data-column offset "
    "expression (log-exposure) row-wise against the training data frame.",
    ["R per-row log(e) offset", "Julia per-row log-exposure offset"],
    "native",
    "The canonical count-model exposure-offset case (formula `offset(log(e))`); "
    "required before any Poisson/NB exposure workflow can be claimed.",
))

rows.append(row(
    "DATA-OFF-ALL-COUNT", "CORE070-DATA-OFF-ALL-COUNT-NATIVE",
    f"gll_prepare_offset(quote(e), c(5L,10L,11L), ...) ({FIXTURE}#DATA-OFF-ALL-COUNT); "
    "expected c(1,2,4) -- nonzero offset admitted for count family ids 5/10/11.",
    "Julia offset-preparation surface must admit a nonzero offset for every "
    "count-family id in its family registry (the ids paired to 5/10/11 in "
    "R's internal family table), rejecting others per DATA-OFF-NONCOUNT-REJECT.",
    ["R count-family id admission set {5,10,11}", "Julia count-family offset admission set"],
    "native",
    "Family-id admission-set case; the Julia family registry's numeric ids "
    "differ from R's, so the comparand is the *set of families admitted* "
    "(count families), not the literal integer ids -- flagged uncertain "
    "only insofar as the id-to-family mapping needs to be pinned once at "
    "case-authoring time, not deferred as a separate obligation.",
))

rows.append(row(
    "DATA-OFF-NB1", "CORE070-DATA-OFF-NB1-NATIVE",
    f"gll_prepare_offset(quote(e), rep(15L,3), ...) ({FIXTURE}#DATA-OFF-NB1); "
    "expected c(1,2,4) -- NB1 (family id 15) also admits a nonzero offset.",
    "Julia offset-preparation surface must admit a nonzero offset for the "
    "NB1 family specifically (a count family outside the {5,10,11} block "
    "tested in DATA-OFF-ALL-COUNT).",
    ["R NB1 (id 15) offset admission", "Julia NB1 offset admission"],
    "native",
    "Regression-style case isolating NB1 from the other count-family ids; "
    "keeps the admission set from silently narrowing to {5,10,11}.",
))

rows.append(row(
    "DATA-OFF-NONCOUNT-ZERO", "CORE070-DATA-OFF-NONCOUNT-ZERO-NATIVE",
    f"gll_prepare_offset(quote(0), rep(0L,3), ...) ({FIXTURE}#DATA-OFF-NONCOUNT-ZERO); "
    "expected rep(0,3) -- an explicit all-zero offset is accepted for a "
    "non-count family (offset ids all 0).",
    "Julia offset-preparation surface must accept an explicit zero offset "
    "for non-count families rather than rejecting the offset() term outright.",
    ["R zero offset on non-count family", "Julia zero offset on non-count family"],
    "native",
    "Pairs with DATA-OFF-NONCOUNT-REJECT (non-zero offset on non-count "
    "family rejects); this row is the accepted boundary at zero.",
))

rows.append(row(
    "DATA-OFF-MIXED", "CORE070-DATA-OFF-MIXED-NATIVE",
    f"gll_prepare_offset(quote(c(1,0,4)), c(2L,0L,5L), ...) ({FIXTURE}#DATA-OFF-MIXED); "
    "expected c(1,0,4) -- a multi-family fit with mixed family ids per row "
    "permits zero offset on non-count rows alongside nonzero on count rows.",
    "Julia offset-preparation surface must apply the per-row family-id "
    "admission rule row-wise within a single multi-family/multi-response fit, "
    "not just at the whole-model level.",
    ["R row-wise mixed-family offset admission", "Julia row-wise mixed-family offset admission"],
    "native",
    "Row-wise variant of the family-conditioned offset rule; required for "
    "any multi-response/multi-family model where offsets and family ids "
    "vary by column.",
))

# --- offset extraction from a stored fit / prediction --------------------
rows.append(row(
    "DATA-OFF-TRAIN-LEGACY", "CORE070-DATA-OFF-TRAIN-LEGACY-POSTFIT-READBACK",
    f".gllvmTMB_offset_vec(fit) with no stored offset_vec ({FIXTURE}#DATA-OFF-TRAIN-LEGACY); "
    "expected rep(0,3) -- fits from before offset_vec was cached fall back to zero.",
    "Julia's stored-fit offset accessor (planned: offset(fit) or an internal "
    "training-offset getter) must return an all-zero vector when the fit "
    "object predates offset caching, matching R's legacy fallback.",
    ["R legacy-fit offset fallback (zero)", "Julia legacy-fit offset fallback"],
    "postfit-readback",
    "Back-compatibility fallback for fit objects saved before offset "
    "caching existed; a Julia serialization/versioning story must define "
    "the equivalent fallback before this can close.",
))

rows.append(row(
    "DATA-OFF-TRAIN-STORED", "CORE070-DATA-OFF-TRAIN-STORED-POSTFIT-READBACK",
    f".gllvmTMB_offset_vec(fit) with tmb_data$offset_vec set ({FIXTURE}#DATA-OFF-TRAIN-STORED); "
    "expected the stored vector c(1,2,3) verbatim.",
    "Julia's stored-fit offset accessor must return the cached training "
    "offset vector unchanged when the fit object carries one.",
    ["R stored offset_vec readback", "Julia stored training-offset readback"],
    "postfit-readback",
    "Positive counterpart to DATA-OFF-TRAIN-LEGACY; together they pin the "
    "stored-vs-fallback offset contract on a fitted model object.",
))

rows.append(row(
    "DATA-OFF-PREDICT", "CORE070-DATA-OFF-PREDICT-POSTFIT-READBACK",
    f".gllvmTMB_offset_newdata(fit, d) ({FIXTURE}#DATA-OFF-PREDICT); "
    "expected log(c(1,2,4)) -- the stored offset expression (log(e)) is "
    "re-evaluated against new data at predict time.",
    "Julia predict()-time offset handling must re-evaluate the fit's stored "
    "offset expression against the supplied newdata rather than reusing the "
    "training offset vector.",
    ["R newdata offset re-evaluation", "Julia predict-time offset re-evaluation"],
    "postfit-readback",
    "Core predict-time offset contract; required before any offset-bearing "
    "count-family predict() workflow can be claimed against R.",
))

rows.append(row(
    "DATA-OFF-PREDICT-NONFINITE-HELPER", "CORE070-DATA-OFF-PREDICT-NONFINITE-HELPER-POSTFIT-READBACK",
    f".gllvmTMB_offset_newdata(fit, data.frame(e=c(0,1,2))) "
    f"({FIXTURE}#DATA-OFF-PREDICT-NONFINITE-HELPER); expected c(-Inf,0,log(2)) -- "
    "log(0) passes through as -Inf at this helper (no guard at newdata-offset level).",
    "Julia predict-time offset evaluator must reproduce the same "
    "unguarded arithmetic (log(0) = -Inf propagates rather than erroring) "
    "at this specific helper, matching R's documented non-guard here -- "
    "any stronger Julia diagnostic must be an explicit, separately tested "
    "design choice, not an accidental behavioral divergence.",
    ["R newdata-offset -Inf passthrough for log(0)", "Julia newdata-offset passthrough/guard behavior"],
    "postfit-readback",
    "Deliberately documents a permissive R behavior (source comment: "
    "'this differs from training validation'); Julia may choose to guard "
    "here, but the divergence must be an explicit tested decision, so this "
    "row is required to make that choice visible rather than silent.",
))

# --- weight normalisation (normalise_weights) -----------------------------
rows.append(row(
    "DATA-W-NULL", "CORE070-DATA-W-NULL-NATIVE",
    f"normalise_weights(NULL, ...) via w(NULL) ({FIXTURE}#DATA-W-NULL); expected NULL.",
    "Julia weight-normalisation surface (planned: normalise_weights()/the "
    "weights= handling inside fit()) must pass NULL/absent weights through "
    "unchanged (equivalent to `nothing` or unweighted fit).",
    ["R normalise_weights(NULL)", "Julia absent-weights passthrough"],
    "native",
    "Baseline no-weights case anchoring the weight-normalisation contract; "
    "every other DATA-W-* row is a variant of this same helper.",
))

rows.append(row(
    "DATA-W-LONG", "CORE070-DATA-W-LONG-NATIVE",
    f"normalise_weights(1:6, shape='long') via w(1:6) ({FIXTURE}#DATA-W-LONG); "
    "expected as.numeric(1:6) -- an exact-length long vector passes through unchanged.",
    "Julia weight-normalisation surface must accept an exact-length long "
    "weight vector and return it unchanged (no reordering).",
    ["R long-format weight passthrough", "Julia long-format weight passthrough"],
    "native",
    "Identity case for the long-vector input route.",
))

rows.append(row(
    "DATA-W-ZERO", "CORE070-DATA-W-ZERO-NATIVE",
    f"normalise_weights(rep(0,6), ...) via w(rep(0,6)) ({FIXTURE}#DATA-W-ZERO); "
    "expected rep(0,6) -- all-zero weights are accepted at this helper "
    "(not validated as a degenerate fit here).",
    "Julia weight-normalisation surface must accept an all-zero weight "
    "vector without erroring; any degenerate-fit rejection belongs at a "
    "later fit-time validation stage, not this shape/policy helper.",
    ["R zero-weight acceptance", "Julia zero-weight acceptance"],
    "native",
    "Pins that weight-value validation (zero, fractional) is deliberately "
    "permissive at this layer, matching R's documented separation of "
    "concerns from family-specific validation.",
))

rows.append(row(
    "DATA-W-FRACTIONAL", "CORE070-DATA-W-FRACTIONAL-NATIVE",
    f"normalise_weights(rep(0.5,6), ...) via w(rep(0.5,6)) ({FIXTURE}#DATA-W-FRACTIONAL); "
    "expected rep(0.5,6) -- fractional weights are accepted at this helper.",
    "Julia weight-normalisation surface must accept fractional weight "
    "values without erroring; family-specific trial-count validation "
    "(e.g. binomial N must be integer) happens elsewhere.",
    ["R fractional-weight acceptance", "Julia fractional-weight acceptance"],
    "native",
    "Companion to DATA-W-ZERO; both pin the same deliberate-permissiveness "
    "contract for weight values at this layer.",
))

rows.append(row(
    "DATA-W-MATRIX-SCALAR", "CORE070-DATA-W-MATRIX-SCALAR-NATIVE",
    f"normalise_weights(2, shape='wide_matrix') via w(2,'wide_matrix') "
    f"({FIXTURE}#DATA-W-MATRIX-SCALAR); expected rep(2,6) -- a scalar "
    "broadcasts to every units*traits cell.",
    "Julia wide-matrix weight-normalisation surface must broadcast a "
    "scalar weight to every cell of the units*traits response matrix, "
    "flattened in the same order as the unmasked case.",
    ["R scalar-to-matrix weight broadcast", "Julia scalar-to-matrix weight broadcast"],
    "native",
    "Scalar-broadcast case for the wide-matrix input route.",
))

rows.append(row(
    "DATA-W-MATRIX-UNIT", "CORE070-DATA-W-MATRIX-UNIT-NATIVE",
    f"normalise_weights(c(10,20), shape='wide_matrix') via w(c(10,20),'wide_matrix') "
    f"({FIXTURE}#DATA-W-MATRIX-UNIT); expected c(10,20,10,20,10,20) -- R "
    "units x traits matrix order (site-major).",
    "Julia's wide-matrix weight adapter must reproduce R's units x traits "
    "(site-major) flattening order for a per-unit weight vector; per the "
    "data-controls contract, Julia's own native binomial N is traits x "
    "units (trait-major, matching DATA-W-DF-UNIT order), so a wide-matrix "
    "*adapter* into that native layout must transpose -- this case pins "
    "the R-side order the adapter must read from.",
    ["R wide-matrix per-unit weight order (10,20,10,20,10,20)",
     "Julia wide-matrix-adapter input order before transpose to native trait-major layout"],
    "bridge",
    "This is the ordering-contract row called out explicitly in "
    "data-controls-contract.md ('Julia native binomial N is traits x "
    "units ... A matrix adapter must transpose the R units x traits "
    "matrix'); evidence_kind is bridge because the comparand is an R->"
    "Julia adapter transform, not a same-order native reproduction.",
))

rows.append(row(
    "DATA-W-MATRIX-CELLS", "CORE070-DATA-W-MATRIX-CELLS-NATIVE",
    f"normalise_weights(matrix(1:6,2,3), shape='wide_matrix') via "
    f"w(matrix(1:6,2,3),'wide_matrix') ({FIXTURE}#DATA-W-MATRIX-CELLS); "
    "expected as.numeric(1:6) -- a full units x traits weight matrix "
    "flattens column-major (R's native matrix storage order).",
    "Julia wide-matrix weight adapter must accept a full per-cell weight "
    "matrix and flatten/transpose it to Julia's native trait-major storage, "
    "matching the general per-cell case of the DATA-W-MATRIX-UNIT ordering "
    "contract.",
    ["R full per-cell weight matrix (column-major flatten)",
     "Julia native per-cell weight layout after adapter transpose"],
    "bridge",
    "General per-cell case of the same ordering contract as "
    "DATA-W-MATRIX-UNIT; required so the adapter is verified beyond the "
    "constant-per-unit special case.",
))

rows.append(row(
    "DATA-W-MATRIX-MASK-DROP", "CORE070-DATA-W-MATRIX-MASK-DROP-NATIVE",
    f"normalise_weights(wm,'wide_matrix',4L,mask) via "
    f"w(wm,'wide_matrix',4L,mask) ({FIXTURE}#DATA-W-MATRIX-MASK-DROP); "
    "expected c(1,2,4,5) -- masked (NA-response) cells are dropped, "
    "shrinking the returned vector to n_obs actually retained.",
    "Julia wide-matrix weight adapter must drop weights at cells masked "
    "out by a missing/NA response (drop_masked=true default), returning a "
    "vector of length equal to the retained-observation count, in the "
    "adapter's native flatten order.",
    ["R masked-drop weight vector (length 4)", "Julia masked-drop weight vector (native order)"],
    "bridge",
    "Mask-drop variant of the wide-matrix ordering contract; required for "
    "any model with response missingness under the response='drop' default "
    "(DATA-MISS-DEFAULT).",
))

rows.append(row(
    "DATA-W-MATRIX-MASK-INCLUDE", "CORE070-DATA-W-MATRIX-MASK-INCLUDE-NATIVE",
    f"normalise_weights(wm,'wide_matrix',6L,mask,FALSE) via "
    f"w(wm,'wide_matrix',6L,mask,FALSE) ({FIXTURE}#DATA-W-MATRIX-MASK-INCLUDE); "
    "expected c(1,2,0,4,5,0) -- with drop_masked=FALSE, masked cells are "
    "retained in place and zeroed rather than dropped.",
    "Julia wide-matrix weight adapter must support a masked-include mode "
    "(drop_masked=false, paired with miss_control(response='include') from "
    "DATA-MISS-INCLUDE) that zeros masked cells in place instead of "
    "shrinking the vector.",
    ["R masked-include weight vector (zero-filled, full length 6)",
     "Julia masked-include weight vector (native order)"],
    "bridge",
    "Companion to DATA-W-MATRIX-MASK-DROP for the response='include' path; "
    "both modes must be supported since miss_control's response policy is "
    "user-selectable (DATA-MISS-INCLUDE/BOTH).",
))

rows.append(row(
    "DATA-W-MATRIX-MASK-SCALAR", "CORE070-DATA-W-MATRIX-MASK-SCALAR-NATIVE",
    f"normalise_weights(2,'wide_matrix',4L,mask) via "
    f"w(2,'wide_matrix',4L,mask) ({FIXTURE}#DATA-W-MATRIX-MASK-SCALAR); "
    "expected rep(2,4) -- a scalar weight broadcasts only to the "
    "retained (unmasked) cells under drop_masked=TRUE.",
    "Julia wide-matrix weight adapter must broadcast a scalar weight to "
    "exactly the retained-observation count when combined with masking, "
    "not to the full unmasked cell count.",
    ["R scalar broadcast restricted to unmasked cells (length 4)",
     "Julia scalar broadcast restricted to unmasked cells"],
    "native",
    "Interaction case between scalar broadcast (DATA-W-MATRIX-SCALAR) and "
    "masking (DATA-W-MATRIX-MASK-DROP); confirms the two rules compose "
    "correctly rather than being tested only in isolation.",
))

rows.append(row(
    "DATA-W-DF-UNIT", "CORE070-DATA-W-DF-UNIT-NATIVE",
    f"normalise_weights(c(10,20), shape='wide_df') via w(c(10,20),'wide_df') "
    f"({FIXTURE}#DATA-W-DF-UNIT); expected c(10,10,10,20,20,20) -- the "
    "traits()-route per-unit weight broadcasts in trait-major order.",
    "Julia's native traits()-style weight input (trait-major, matching "
    "Julia's own binomial-N storage order per the data-controls contract) "
    "must broadcast a per-unit weight vector to c(10,10,10,20,20,20) -- "
    "the SAME order as Julia's native layout, unlike the wide-matrix route.",
    ["R traits() per-unit weight order (10,10,10,20,20,20)",
     "Julia native trait-major weight/N order"],
    "native",
    "This is the order that already matches Julia's native trait-major "
    "layout (per data-controls-contract.md); evidence_kind is native "
    "(direct reproduction), contrasting with the wide-matrix rows which "
    "are bridge/adapter cases.",
))

rows.append(row(
    "DATA-W-DF-MASK-DROP", "CORE070-DATA-W-DF-MASK-DROP-NATIVE",
    f"normalise_weights(c(10,20),'wide_df',4L,mask) via "
    f"w(c(10,20),'wide_df',4L,mask) ({FIXTURE}#DATA-W-DF-MASK-DROP); "
    "expected c(10,10,20,20) -- traits()-route masked cells dropped, "
    "trait-major retained order.",
    "Julia native trait-major weight input must drop masked cells under "
    "drop_masked=true, matching R's traits()-route retained order.",
    ["R traits()-route masked-drop weight vector (length 4)",
     "Julia native trait-major masked-drop weight vector"],
    "native",
    "Mask-drop variant of DATA-W-DF-UNIT; direct native reproduction, no "
    "adapter transpose needed since this route already matches Julia's "
    "trait-major storage.",
))

rows.append(row(
    "DATA-W-DF-MASK-INCLUDE", "CORE070-DATA-W-DF-MASK-INCLUDE-NATIVE",
    f"normalise_weights(c(10,20),'wide_df',6L,mask,FALSE) via "
    f"w(c(10,20),'wide_df',6L,mask,FALSE) ({FIXTURE}#DATA-W-DF-MASK-INCLUDE); "
    "expected c(10,10,10,20,20,20) -- with drop_masked=FALSE the traits()-"
    "route weight at a masked cell is RETAINED (not zeroed), unlike the "
    "wide-matrix masked-include case.",
    "Julia native trait-major weight input in masked-include mode must "
    "retain the per-unit weight value at masked cells rather than zeroing "
    "it -- this differs from the wide-matrix masked-include contract "
    "(DATA-W-MATRIX-MASK-INCLUDE zeros; this route does not) and both "
    "behaviors must be reproduced distinctly, not collapsed to one rule.",
    ["R traits()-route masked-include weight vector (retained, not zeroed)",
     "Julia native trait-major masked-include weight vector (retained)"],
    "native",
    "Contract explicitly distinguishes this from the wide-matrix masked-"
    "include row per data-controls-contract.md ('Site weights retained at "
    "masked entries' for traits() vs 'Masked entries zeroed' for the "
    "matrix route) -- a real behavioral asymmetry, not a documentation "
    "artifact, so both must be separately verified.",
))

data = {"area": "data", "rows": rows}
out_path = "/private/tmp/GLLVM.jl-core070-aghq-20260830/docs/dev-log/core070/manifest-freeze-work/drafts/data.json"
with open(out_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("rows written:", len(rows))
