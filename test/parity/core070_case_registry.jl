module Core070CaseRegistry
export COVARIANCE_FORMULA_IDS, COVARIANCE_FIXED_FORMULA_IDS, COVARIANCE_MODE_FORMULA_IDS, COVARIANCE_IDS, COVARIANCE_FIXED_IDS, COVARIANCE_MODE_IDS, FAMILY_IDS, MODEL_IDS, GAUSSIAN_IDS, INTERFACE_IDS, REGISTERED_IDS, FIXTURES, requested_ids, validate_manifest
const FAMILY_IDS = [
    "NATIVE-01-GAUSSIAN", "NATIVE-02-BINOMIAL", "NATIVE-03-POISSON",
    "NATIVE-04-LOGNORMAL", "NATIVE-05-GAMMA", "NATIVE-06-NB2",
    "NATIVE-07-TWEEDIE", "NATIVE-08-BETA", "NATIVE-09-BETABINOMIAL",
    "NATIVE-10-STUDENT", "NATIVE-11-TRUNCATED-POISSON",
    "NATIVE-12-TRUNCATED-NB2", "NATIVE-13-DELTA-LOGNORMAL",
    "NATIVE-14-DELTA-GAMMA", "NATIVE-15-ORDINAL-PROBIT", "NATIVE-16-NB1",
    "NATIVE-17-MULTINOMIAL-FIXED",
]
const MODEL_IDS = ["CORE070-FAMILY-00-IDENTITY-NATIVE-MODEL"]
const INTERFACE_IDS = ["CORE070-FAMILY-05-LOG-FORMULA-INTERFACE", "CORE070-FAMILY-00-IDENTITY-FORMULA-INTERFACE", "CORE070-FAMILY-02-LOG-FORMULA-INTERFACE", "CORE070-FAMILY-07-LOGIT-FORMULA-INTERFACE", "CORE070-FAMILY-11-LOG-FORMULA-INTERFACE"]
const GAUSSIAN_IDS = [only(MODEL_IDS), "CORE070-FAMILY-00-IDENTITY-FORMULA-INTERFACE"]
const COVARIANCE_FIXED_IDS = ["MODE-ORD-INDEP", "MODE-ORD-COMMON"]
const COVARIANCE_MODE_IDS = ["FIT-MODE-ORD-DEP";
    ["FIT-MODE-$source-$mode" for source in ("ANIMAL", "KERNEL") for mode in ("INDEP", "COMMON", "DEP")]]
const COVARIANCE_IDS = vcat(COVARIANCE_FIXED_IDS, COVARIANCE_MODE_IDS)
const COVARIANCE_FIXED_FORMULA_IDS = COVARIANCE_FIXED_IDS .* "-FORMULA-INTERFACE"
const COVARIANCE_MODE_FORMULA_IDS = COVARIANCE_MODE_IDS .* "-FORMULA-INTERFACE"
const COVARIANCE_FORMULA_IDS = vcat(COVARIANCE_FIXED_FORMULA_IDS,COVARIANCE_MODE_FORMULA_IDS)
const REGISTERED_IDS = vcat(FAMILY_IDS, MODEL_IDS, INTERFACE_IDS, COVARIANCE_IDS, COVARIANCE_FORMULA_IDS)
const FIXTURES = Dict(
    "NATIVE-01-GAUSSIAN" => "test/parity/test_gaussian_parity.jl",
    "NATIVE-02-BINOMIAL" => "test/parity/test_binomial_parity.jl",
    "NATIVE-03-POISSON" => "test/parity/test_poisson_required.jl",
    "NATIVE-04-LOGNORMAL" => "test/parity/test_lognormal_parity.jl",
    "NATIVE-05-GAMMA" => "test/parity/test_nox_dispersion_parity.jl",
    "NATIVE-06-NB2" => "test/parity/test_negbin_parity.jl",
    "NATIVE-07-TWEEDIE" => "test/parity/test_tweedie_parity.jl",
    "NATIVE-08-BETA" => "test/parity/test_beta_required.jl",
    "NATIVE-09-BETABINOMIAL" => "test/parity/test_nox_dispersion_parity.jl",
    "NATIVE-10-STUDENT" => "test/parity/test_studentt_parity.jl",
    "NATIVE-11-TRUNCATED-POISSON" => "test/parity/test_truncated_poisson_parity.jl",
    "NATIVE-12-TRUNCATED-NB2" => "test/parity/test_truncated_nbinom2_parity.jl",
    "NATIVE-13-DELTA-LOGNORMAL" => "test/parity/test_delta_lognormal_required.jl",
    "NATIVE-14-DELTA-GAMMA" => "test/parity/test_delta_gamma_required.jl",
    "NATIVE-15-ORDINAL-PROBIT" => "test/parity/test_ordinal_probit_parity.jl",
    "NATIVE-16-NB1" => "test/parity/test_nox_dispersion_parity.jl",
    "NATIVE-17-MULTINOMIAL-FIXED" => "test/parity/test_multinomial_parity.jl",
)
FIXTURES[first(INTERFACE_IDS)] = "test/parity/test_nb2_formula_parity.jl"

const FORMULA_NATIVE_DEPENDENCIES = Dict(
    "CORE070-FAMILY-02-LOG-FORMULA-INTERFACE" => "NATIVE-03-POISSON",
    "CORE070-FAMILY-07-LOGIT-FORMULA-INTERFACE" => "NATIVE-08-BETA",
    "CORE070-FAMILY-11-LOG-FORMULA-INTERFACE" => "NATIVE-12-TRUNCATED-NB2",
)
FIXTURES["CORE070-FAMILY-02-LOG-FORMULA-INTERFACE"] = "test/parity/test_poisson_formula_parity.jl"
FIXTURES["CORE070-FAMILY-07-LOGIT-FORMULA-INTERFACE"] = "test/parity/test_beta_formula_parity.jl"
FIXTURES["CORE070-FAMILY-11-LOG-FORMULA-INTERFACE"] = "test/parity/test_truncnb2_formula_parity.jl"

for id in GAUSSIAN_IDS
    FIXTURES[id] = "test/parity/test_gaussian_original_required.jl"
end

for id in COVARIANCE_FIXED_IDS
    FIXTURES[id] = "test/parity/test_covariance_fixed_required.jl"
end
for id in COVARIANCE_MODE_IDS
    FIXTURES[id] = "test/parity/test_covariance_modes_required.jl"
end

for id in COVARIANCE_FIXED_FORMULA_IDS
    FIXTURES[id] = "test/parity/test_covariance_fixed_formula_required.jl"
end
for id in COVARIANCE_MODE_FORMULA_IDS
    FIXTURES[id] = "test/parity/test_covariance_modes_formula_required.jl"
end

function requested_ids(raw::AbstractString = "")
    raw = strip(raw)
    ids = isempty(raw) ? copy(REGISTERED_IDS) : strip.(split(raw, ','))
    any(isempty, ids) && throw(ArgumentError("CORE070_PARITY_CASE_IDS contains an empty case ID"))
    length(ids) == length(unique(ids)) || throw(ArgumentError("CORE070_PARITY_CASE_IDS contains duplicate IDs"))
    all(id -> id in REGISTERED_IDS, ids) ||
        throw(ArgumentError("CORE070_PARITY_CASE_IDS contains an unknown registered case ID"))
    grouped = ("NATIVE-05-GAMMA", "NATIVE-09-BETABINOMIAL", "NATIVE-16-NB1")
    selected_grouped = [id for id in ids if id in grouped]
    isempty(selected_grouped) || length(selected_grouped) == length(grouped) ||
        throw(ArgumentError("the grouped Gamma/NB1/BetaBinomial fixture must be requested as its exact three-case scope"))
    selected_gaussian = [id for id in ids if id in GAUSSIAN_IDS]
    isempty(selected_gaussian) || length(selected_gaussian) == length(GAUSSIAN_IDS) ||
        throw(ArgumentError("the original Gaussian native/formula fixture must be requested as its exact two-case scope"))
    for group in (COVARIANCE_FIXED_IDS,COVARIANCE_MODE_IDS,COVARIANCE_FIXED_FORMULA_IDS,COVARIANCE_MODE_FORMULA_IDS)
        selected = count(id -> id in group, ids)
        selected in (0,length(group)) || throw(ArgumentError(
            "a Gaussian covariance fixture must be requested as its complete group"))
    end
    for (formula,native) in zip(COVARIANCE_FORMULA_IDS,COVARIANCE_IDS)
        formula in ids && !(native in ids) && throw(ArgumentError(
            "covariance formula $formula requires native case $native in the same run"))
    end
    for (formula, native) in FORMULA_NATIVE_DEPENDENCIES
        formula in ids && !(native in ids) && throw(ArgumentError(
            "formula case $formula requires native case $native in the same run"))
    end
    return ids
end

"""Bind the runner's separate family and interface registries to the draft contract."""
function validate_manifest(manifest)
    for (key, rows, expected) in (("family_smoke_case_ids", "families", FAMILY_IDS),
                                  ("interface_case_ids", "interfaces", INTERFACE_IDS),
                                  ("model_case_ids", "models", MODEL_IDS),
                                  ("covariance_case_ids", "covariance_models", COVARIANCE_IDS),
                                  ("covariance_formula_case_ids", "covariance_interfaces", COVARIANCE_FORMULA_IDS))
        ids = get(manifest, key, String[])
        length(ids) == length(expected) && Set(ids) == Set(expected) ||
            throw(ArgumentError("contract $key differs from runner registry"))
        entries = get(manifest, rows, [])
        length(entries) == length(expected) && Set(row["id"] for row in entries) == Set(expected) ||
            throw(ArgumentError("contract $rows rows differ from runner registry"))
        all(row["fixture"] == FIXTURES[row["id"]] for row in entries) ||
            throw(ArgumentError("contract $rows fixture differs from runner registry"))
    end
    return true
end
end
