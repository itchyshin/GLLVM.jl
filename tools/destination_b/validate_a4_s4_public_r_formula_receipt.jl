"""
Validate the S4 public-R-formula paired-receipt structure without loading R,
gllvmTMB, or GLLVM.  This is a fail-closed artifact check only: a valid receipt
is deliberately *not* a public parity promotion.
"""

const _S4_PUBLIC_R_FORMULA_SCHEMA = "destination-b-a4-s4-public-r-formula-receipt-1"
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

"""
    validate_a4_s4_public_r_formula_receipt(receipt)

Fail closed unless `receipt` records a directly evaluated public
`gllvmTMB::gllvmTMB` two-trait Gaussian formula on a non-unit three-tip tree,
with fresh R source/DLL attestation and all seven observed-marginal
transformed-Wald endpoints agreeing with Julia within `1e-4`.

The returned value only says that the receipt has this structure.  It never
authorizes a public parity claim, release, or change to gllvmTMB.
"""
function validate_a4_s4_public_r_formula_receipt(receipt)
    receipt = _s4_receipt_dict(receipt, "receipt")
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
        "cbind(trait_1, trait_2) ~ 1" || _s4_receipt_fail("unexpected public R formula")
    _s4_receipt_string(formula, "family", "receipt.public_r_formula") == "gaussian" ||
        _s4_receipt_fail("receipt is not Gaussian")
    _s4_receipt_bool(formula, "observed_marginal", "receipt.public_r_formula") ||
        _s4_receipt_fail("receipt is not observed-marginal")
    _s4_receipt_integer(formula, "n_traits", "receipt.public_r_formula") == 2 ||
        _s4_receipt_fail("receipt does not have two traits")
    tree = _s4_receipt_dict(_s4_receipt_get(formula, "tree", "receipt.public_r_formula"),
        "receipt.public_r_formula.tree")
    _s4_receipt_integer(tree, "n_tips", "receipt.public_r_formula.tree") == 3 ||
        _s4_receipt_fail("receipt does not have a three-tip tree")
    !_s4_receipt_bool(tree, "unit_ultrametric", "receipt.public_r_formula.tree") ||
        _s4_receipt_fail("receipt tree is unit-ultrametric")

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
        "status" => "valid_fresh_r_formula_receipt",
        "claim_status" => "receipt_valid_not_publicly_promoted",
        "endpoint_atol" => _S4_PUBLIC_R_FORMULA_ATOL,
        "n_targets" => length(_S4_PUBLIC_R_FORMULA_TARGETS),
    )
end
