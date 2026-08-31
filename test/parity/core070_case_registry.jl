module Core070CaseRegistry
export FAMILY_IDS, MODEL_IDS, GAUSSIAN_IDS, INTERFACE_IDS, REGISTERED_IDS, FIXTURES, requested_ids, validate_manifest
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
const INTERFACE_IDS = ["CORE070-FAMILY-05-LOG-FORMULA-INTERFACE", "CORE070-FAMILY-00-IDENTITY-FORMULA-INTERFACE"]
const GAUSSIAN_IDS = [only(MODEL_IDS), last(INTERFACE_IDS)]
const REGISTERED_IDS = vcat(FAMILY_IDS, MODEL_IDS, INTERFACE_IDS)
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

for id in GAUSSIAN_IDS
    FIXTURES[id] = "test/parity/test_gaussian_original_required.jl"
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
    return ids
end

"""Bind the runner's separate family and interface registries to the draft contract."""
function validate_manifest(manifest)
    for (key, rows, expected) in (("family_smoke_case_ids", "families", FAMILY_IDS),
                                  ("interface_case_ids", "interfaces", INTERFACE_IDS),
                                  ("model_case_ids", "models", MODEL_IDS))
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
