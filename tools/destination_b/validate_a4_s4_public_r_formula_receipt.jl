"""
Validate the S4 public-R-formula paired-receipt structure without loading R,
gllvmTMB, or GLLVM.  This is a fail-closed artifact check only: a valid receipt
is deliberately *not* a public parity promotion.
"""

const _S4_PUBLIC_R_FORMULA_SCHEMA = "destination-b-a4-s4-public-r-formula-receipt-2"
const _S4_PUBLIC_R_FORMULA_TARGETS = [
    "beta[1]", "beta[2]", "phylo_cov[1,1]", "phylo_cov[2,1]",
    "phylo_cov[2,2]", "residual_var_shared[1]", "residual_var_shared[2]",
]
const _S4_PUBLIC_R_FORMULA_ATOL = 1e-4

_s4_receipt_fail(message) = throw(ArgumentError("S4 public R-formula receipt: " * message))

function _s4_receipt_dict(value, where)
    (value isa AbstractDict || hasmethod(haskey, Tuple{typeof(value), Any})) ||
        _s4_receipt_fail("$(where) is not an object")
    return value
end

function _s4_receipt_get(object, key, where)
    haskey(object, key) || _s4_receipt_fail("missing $(where).$(key)")
    return object[key]
end

function _s4_receipt_string(object, key, where)
    value = _s4_receipt_get(object, key, where)
    value isa AbstractString && !isempty(value) ||
        _s4_receipt_fail("$(where).$(key) is not a nonempty string")
    return String(value)
end

function _s4_receipt_bool(object, key, where)
    value = _s4_receipt_get(object, key, where)
    value isa Bool || _s4_receipt_fail("$(where).$(key) is not Boolean")
    return value
end

function _s4_receipt_number(object, key, where)
    value = _s4_receipt_get(object, key, where)
    value isa Real && !(value isa Bool) && isfinite(value) ||
        _s4_receipt_fail("$(where).$(key) is not finite")
    return Float64(value)
end

function _s4_receipt_integer(object, key, where)
    value = _s4_receipt_get(object, key, where)
    value isa Integer && !(value isa Bool) ||
        _s4_receipt_fail("$(where).$(key) is not an integer")
    return Int(value)
end

function _s4_receipt_sha(value, where, n)
    value isa AbstractString && occursin(Regex("^[0-9a-f]{" * string(n) * "}" * string(Char(36))), value) &&
        !all(==('0'), value) || _s4_receipt_fail("$(where) is not a nonzero lowercase digest")
    return String(value)
end

function _s4_receipt_endpoints(rows, where)
    rows isa AbstractVector || _s4_receipt_fail("$(where) is not an array")
    length(rows) == length(_S4_PUBLIC_R_FORMULA_TARGETS) ||
        _s4_receipt_fail("$(where) does not have seven endpoint targets")
    by_target = Dict{String, Tuple{Float64, Float64}}()
    for (i, row) in pairs(rows)
        row = _s4_receipt_dict(row, "$(where)[$(i)]")
        target = _s4_receipt_string(row, "target", "$(where)[$(i)]")
        target in _S4_PUBLIC_R_FORMULA_TARGETS ||
            _s4_receipt_fail("$(where) has an unknown target $(target)")
        !haskey(by_target, target) || _s4_receipt_fail("$(where) repeats $(target)")
        _s4_receipt_string(row, "method", "$(where)[$(i)]") == "transformed_wald" ||
            _s4_receipt_fail("$(where) target $(target) is not transformed-Wald")
        lower = _s4_receipt_number(row, "lower", "$(where)[$(i)]")
        upper = _s4_receipt_number(row, "upper", "$(where)[$(i)]")
        lower < upper || _s4_receipt_fail("$(where) target $(target) has unordered endpoints")
        by_target[target] = (lower, upper)
    end
    Set(keys(by_target)) == Set(_S4_PUBLIC_R_FORMULA_TARGETS) ||
        _s4_receipt_fail("$(where) does not contain the canonical seven targets")
    return by_target
end

function _s4_retained_invalid_cbind_diagnostic(receipt)
    rows = _s4_receipt_get(receipt, "retained_pre_run_diagnostics", "receipt")
    rows isa AbstractVector && length(rows) == 2 ||
        _s4_receipt_fail("receipt does not retain both pre-run diagnostics")
    row = _s4_receipt_dict(rows[1], "receipt.retained_pre_run_diagnostics[1]")
    _s4_receipt_string(row, "kind", "receipt.retained_pre_run_diagnostics[1]") ==
        "invalid_cbind_formula_rejection" || _s4_receipt_fail("wrong retained pre-run kind")
    _s4_receipt_string(row, "formula", "receipt.retained_pre_run_diagnostics[1]") ==
        "cbind(trait_1, trait_2) ~ 1" || _s4_receipt_fail("wrong retained invalid formula")
    _s4_receipt_integer(row, "exit_status", "receipt.retained_pre_run_diagnostics[1]") == 1 ||
        _s4_receipt_fail("retained invalid formula did not fail")
    _s4_receipt_number(row, "elapsed_seconds", "receipt.retained_pre_run_diagnostics[1]") == 0.62 ||
        _s4_receipt_fail("retained invalid formula timing drifted")
    _s4_receipt_bool(row, "not_a_receipt", "receipt.retained_pre_run_diagnostics[1]") ||
        _s4_receipt_fail("invalid formula diagnostic is mislabeled as a receipt")
    tree_row = _s4_receipt_dict(rows[2], "receipt.retained_pre_run_diagnostics[2]")
    _s4_receipt_string(tree_row, "kind", "receipt.retained_pre_run_diagnostics[2]") ==
        "nonultrametric_tree_rejection" || _s4_receipt_fail("wrong retained tree diagnostic")
    _s4_receipt_string(tree_row, "formula", "receipt.retained_pre_run_diagnostics[2]") ==
        "traits(trait_1, trait_2) ~ 1 + phylo_dep(1 | species, tree = tree)" ||
        _s4_receipt_fail("wrong retained tree diagnostic formula")
    _s4_receipt_integer(tree_row, "exit_status", "receipt.retained_pre_run_diagnostics[2]") == 1 ||
        _s4_receipt_fail("retained tree probe did not fail")
    _s4_receipt_number(tree_row, "elapsed_seconds", "receipt.retained_pre_run_diagnostics[2]") == 1.25 ||
        _s4_receipt_fail("retained tree probe timing drifted")
    _s4_receipt_bool(tree_row, "not_a_receipt", "receipt.retained_pre_run_diagnostics[2]") ||
        _s4_receipt_fail("tree diagnostic is mislabeled as a receipt")
    return nothing
end

"""
    validate_a4_s4_public_r_formula_receipt(receipt; allow_synthetic = false)

Fail closed unless `receipt` records the directly evaluated public
`traits()` plus `phylo_dep()` two-trait Gaussian formula on a non-unit
ultrametric three-tip tree, retains both failed pre-run diagnostics, and has all seven
observed-marginal transformed-Wald endpoints agreeing with a separately
implemented structured Julia transport within `1e-4`.

The returned value only says that the receipt has this structure.  It never
authorizes a public parity claim, release, or change to gllvmTMB.

`allow_synthetic` exists solely for the in-memory validator fixture in the
Julia test suite. A fixture tagged `synthetic_validator_fixture` is rejected
by default, so its invented attestations can never be read as paired evidence.
"""
function validate_a4_s4_public_r_formula_receipt(receipt; allow_synthetic::Bool = false)
    receipt = _s4_receipt_dict(receipt, "receipt")
    fixture_kind = get(receipt, "fixture_kind", "recorded_receipt")
    fixture_kind isa AbstractString || _s4_receipt_fail("receipt.fixture_kind is not a string")
    fixture_kind in ("recorded_receipt", "synthetic_validator_fixture") ||
        _s4_receipt_fail("receipt.fixture_kind is unknown")
    synthetic = fixture_kind == "synthetic_validator_fixture"
    synthetic && !allow_synthetic &&
        _s4_receipt_fail("synthetic validator fixtures are not evidence receipts")
    _s4_receipt_string(receipt, "schema_version", "receipt") == _S4_PUBLIC_R_FORMULA_SCHEMA ||
        _s4_receipt_fail("unexpected schema version")
    _s4_receipt_string(receipt, "status", "receipt") == "r_formula_paired_endpoints_recorded" ||
        _s4_receipt_fail("receipt has not recorded paired R-formula endpoints")
    _s4_receipt_string(receipt, "claim_status", "receipt") == "receipt_valid_not_publicly_promoted" ||
        _s4_receipt_fail("receipt attempts a public parity claim")

    formula = _s4_receipt_dict(_s4_receipt_get(receipt, "public_r_formula", "receipt"),
        "receipt.public_r_formula")
    _s4_receipt_string(formula, "constructor", "receipt.public_r_formula") == "gllvmTMB::gllvmTMB" ||
        _s4_receipt_fail("receipt does not use the public gllvmTMB constructor")
    _s4_receipt_string(formula, "formula", "receipt.public_r_formula") ==
        "traits(trait_1, trait_2) ~ 1 + phylo_dep(1 | species, tree = tree)" ||
        _s4_receipt_fail("unexpected public R formula")
    _s4_receipt_string(formula, "resolved_long_formula", "receipt.public_r_formula") ==
        "value ~ 0 + trait + phylo_dep(0 + trait | species, tree = tree)" ||
        _s4_receipt_fail("unexpected resolved long R formula")
    _s4_receipt_string(formula, "data_layout", "receipt.public_r_formula") == "wide_traits" ||
        _s4_receipt_fail("receipt does not use wide traits data")
    _s4_receipt_string(formula, "unit", "receipt.public_r_formula") == "individual" ||
        _s4_receipt_fail("receipt does not use individual rows")
    _s4_receipt_string(formula, "cluster", "receipt.public_r_formula") == "species" ||
        _s4_receipt_fail("receipt does not cluster on species")
    _s4_receipt_string(formula, "family", "receipt.public_r_formula") == "gaussian" ||
        _s4_receipt_fail("receipt is not Gaussian")
    _s4_receipt_bool(formula, "observed_marginal", "receipt.public_r_formula") ||
        _s4_receipt_fail("receipt is not observed-marginal")
    _s4_receipt_string(formula, "phylo_covariance", "receipt.public_r_formula") ==
        "full_unstructured" || _s4_receipt_fail("receipt lacks full phylogenetic covariance")
    _s4_receipt_integer(formula, "n_traits", "receipt.public_r_formula") == 2 ||
        _s4_receipt_fail("receipt does not have two traits")
    tree = _s4_receipt_dict(_s4_receipt_get(formula, "tree", "receipt.public_r_formula"),
        "receipt.public_r_formula.tree")
    _s4_receipt_integer(tree, "n_tips", "receipt.public_r_formula.tree") == 3 ||
        _s4_receipt_fail("receipt does not have a three-tip tree")
    _s4_receipt_bool(tree, "ultrametric", "receipt.public_r_formula.tree") ||
        _s4_receipt_fail("receipt tree is not ultrametric")
    !_s4_receipt_bool(tree, "unit_ultrametric", "receipt.public_r_formula.tree") ||
        _s4_receipt_fail("receipt tree is unit-ultrametric")
    target_mapping = _s4_receipt_dict(_s4_receipt_get(receipt, "target_mapping", "receipt"),
        "receipt.target_mapping")
    _s4_receipt_string(target_mapping, "beta", "receipt.target_mapping") ==
        "0 + trait intercepts in trait_1, trait_2 order" || _s4_receipt_fail("wrong beta mapping")
    _s4_receipt_string(target_mapping, "phylo_cov", "receipt.target_mapping") ==
        "extract_Sigma(level = 'phy', part = 'total', link_residual = 'none')\$Sigma lower triangle" ||
        _s4_receipt_fail("wrong phylogenetic covariance mapping")
    _s4_receipt_string(target_mapping, "residual_var_shared", "receipt.target_mapping") ==
        "sigma_eps^2 replicated for both trait labels" || _s4_receipt_fail("wrong residual mapping")
    _s4_receipt_bool(target_mapping, "shared_across_traits", "receipt.target_mapping") ||
        _s4_receipt_fail("residual variance must be shared across traits")
    _s4_retained_invalid_cbind_diagnostic(receipt)

    r_attestation = _s4_receipt_dict(_s4_receipt_get(receipt, "r_attestation", "receipt"),
        "receipt.r_attestation")
    _s4_receipt_string(r_attestation, "status", "receipt.r_attestation") ==
        "fresh_source_and_dll_attested" || _s4_receipt_fail("R source/DLL attestation is not fresh")
    _s4_receipt_sha(_s4_receipt_get(r_attestation, "source_pin", "receipt.r_attestation"),
        "receipt.r_attestation.source_pin", 40)
    _s4_receipt_sha(_s4_receipt_get(r_attestation, "dll_sha256", "receipt.r_attestation"),
        "receipt.r_attestation.dll_sha256", 64)
    !_s4_receipt_bool(r_attestation, "source_tree_dirty", "receipt.r_attestation") ||
        _s4_receipt_fail("R source tree is dirty")
    _s4_receipt_bool(r_attestation, "formula_evaluated", "receipt.r_attestation") ||
        _s4_receipt_fail("public R formula was not evaluated")
    occursin(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$",
        _s4_receipt_string(r_attestation, "captured_at_utc", "receipt.r_attestation")) ||
        _s4_receipt_fail("R receipt capture time is not UTC ISO-8601")

    julia_attestation = _s4_receipt_dict(
        _s4_receipt_get(receipt, "julia_attestation", "receipt"), "receipt.julia_attestation")
    _s4_receipt_string(julia_attestation, "bridge_status", "receipt.julia_attestation") ==
        "structured_transport_evaluated" ||
        _s4_receipt_fail("Julia structured transport remains gated")
    _s4_receipt_sha(_s4_receipt_get(julia_attestation, "source_commit", "receipt.julia_attestation"),
        "receipt.julia_attestation.source_commit", 40)
    _s4_receipt_bool(julia_attestation, "formula_adapter_evaluated", "receipt.julia_attestation") ||
        _s4_receipt_fail("Julia formula adapter was not evaluated")

    atol = _s4_receipt_number(receipt, "endpoint_atol", "receipt")
    atol == _S4_PUBLIC_R_FORMULA_ATOL ||
        _s4_receipt_fail("endpoint tolerance must remain 1e-4")
    r_endpoints = _s4_receipt_endpoints(_s4_receipt_get(receipt, "r_endpoints", "receipt"),
        "receipt.r_endpoints")
    julia_endpoints = _s4_receipt_endpoints(
        _s4_receipt_get(receipt, "julia_endpoints", "receipt"), "receipt.julia_endpoints")
    for target in _S4_PUBLIC_R_FORMULA_TARGETS
        r_lower, r_upper = r_endpoints[target]
        j_lower, j_upper = julia_endpoints[target]
        abs(r_lower - j_lower) <= atol && abs(r_upper - j_upper) <= atol ||
            _s4_receipt_fail("$(target) endpoints differ by more than 1e-4")
    end

    return Dict(
        "status" => synthetic ? "valid_synthetic_r_formula_receipt_fixture" :
            "valid_fresh_r_formula_receipt",
        "claim_status" => "receipt_valid_not_publicly_promoted",
        "endpoint_atol" => _S4_PUBLIC_R_FORMULA_ATOL,
        "n_targets" => length(_S4_PUBLIC_R_FORMULA_TARGETS),
    )
end
