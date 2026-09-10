using Test

# This test is deliberately independent of R and gllvmTMB. It supplies an
# explicitly synthetic validator fixture; it is neither an R execution nor
# paired evidence. A real receipt must be validated without the synthetic
# opt-in after its source/DLL and Julia-transport evidence exists.
include(joinpath(@__DIR__, "..", "tools", "destination_b",
    "validate_a4_s4_public_r_formula_receipt.jl"))

const _S4_R_FORMULA_PIN = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
const _S4_R_FORMULA_DLL = "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"
const _S4_R_FORMULA_TARGETS = [
    "beta[1]", "beta[2]", "phylo_cov[1,1]", "phylo_cov[2,1]",
    "phylo_cov[2,2]", "residual_var_shared[1]", "residual_var_shared[2]",
]

function _s4_endpoint(target, offset = 0.0)
    Dict("target" => target, "method" => "transformed_wald",
        "lower" => -0.2 + offset, "upper" => 0.3 + offset)
end

function _s4_synthetic_public_r_formula_receipt()
    r_endpoints = [_s4_endpoint(target) for target in _S4_R_FORMULA_TARGETS]
    julia_endpoints = [_s4_endpoint(target, 5e-5) for target in _S4_R_FORMULA_TARGETS]
    Dict(
        "schema_version" => "destination-b-a4-s4-public-r-formula-receipt-2",
        "fixture_kind" => "synthetic_validator_fixture",
        "status" => "r_formula_paired_endpoints_recorded",
        "claim_status" => "receipt_valid_not_publicly_promoted",
        "public_r_formula" => Dict(
            "constructor" => "gllvmTMB::gllvmTMB",
            "formula" => "traits(trait_1, trait_2) ~ 1 + phylo_dep(1 | species, tree = tree)",
            "resolved_long_formula" => "value ~ 0 + trait + phylo_dep(0 + trait | species, tree = tree)",
            "data_layout" => "wide_traits",
            "unit" => "individual",
            "cluster" => "species",
            "family" => "gaussian",
            "observed_marginal" => true,
            "phylo_covariance" => "full_unstructured",
            "n_traits" => 2,
            "tree" => Dict("n_tips" => 3, "ultrametric" => true, "unit_ultrametric" => false),
        ),
        "target_mapping" => Dict(
            "beta" => "0 + trait intercepts in trait_1, trait_2 order",
            "phylo_cov" => "extract_Sigma(level = 'phy', part = 'total', link_residual = 'none')\$Sigma lower triangle",
            "residual_var_shared" => "sigma_eps^2 replicated for both trait labels",
            "shared_across_traits" => true,
        ),
        "retained_pre_run_diagnostics" => [Dict(
            "kind" => "invalid_cbind_formula_rejection",
            "formula" => "cbind(trait_1, trait_2) ~ 1",
            "exit_status" => 1,
            "elapsed_seconds" => 0.62,
            "not_a_receipt" => true,
        ), Dict(
            "kind" => "nonultrametric_tree_rejection",
            "formula" => "traits(trait_1, trait_2) ~ 1 + phylo_dep(1 | species, tree = tree)",
            "exit_status" => 1,
            "elapsed_seconds" => 1.25,
            "not_a_receipt" => true,
        )],
        "r_attestation" => Dict(
            "status" => "fresh_source_and_dll_attested",
            "source_pin" => _S4_R_FORMULA_PIN,
            "dll_sha256" => _S4_R_FORMULA_DLL,
            "source_tree_dirty" => false,
            "formula_evaluated" => true,
            "captured_at_utc" => "2026-09-09T12:00:00Z",
        ),
        "julia_attestation" => Dict(
            "bridge_status" => "structured_transport_evaluated",
            "source_commit" => "9f8378aa9fb9bf73f2501c65f9e91ffc6ddc1243",
            "formula_adapter_evaluated" => true,
        ),
        "r_endpoints" => r_endpoints,
        "julia_endpoints" => julia_endpoints,
        "endpoint_atol" => 1e-4,
    )
end

@testset "S4 public R-formula paired-receipt contract" begin
    receipt = _s4_synthetic_public_r_formula_receipt()
    @test_throws ArgumentError validate_a4_s4_public_r_formula_receipt(receipt)
    checked = validate_a4_s4_public_r_formula_receipt(receipt; allow_synthetic = true)
    @test checked["status"] == "valid_synthetic_r_formula_receipt_fixture"
    @test checked["claim_status"] == "receipt_valid_not_publicly_promoted"
    @test checked["endpoint_atol"] == 1e-4
    @test checked["n_targets"] == 7

    tagless = deepcopy(receipt)
    pop!(tagless, "fixture_kind")
    @test_throws ArgumentError validate_a4_s4_public_r_formula_receipt(tagless;
        allow_synthetic = true)
    retagged = deepcopy(receipt)
    retagged["fixture_kind"] = "recorded_receipt"
    @test_throws ArgumentError validate_a4_s4_public_r_formula_receipt(retagged;
        allow_synthetic = true)

    for tamper in (
        x -> x["r_attestation"]["source_pin"] = "0" ^ 40,
        x -> x["r_attestation"]["dll_sha256"] = "0" ^ 64,
        x -> x["r_attestation"]["status"] = "attested",
        x -> x["r_attestation"]["formula_evaluated"] = false,
        x -> x["public_r_formula"]["formula"] = "cbind(trait_1, trait_2) ~ 1",
        x -> x["public_r_formula"]["resolved_long_formula"] = "value ~ 1",
        x -> x["public_r_formula"]["n_traits"] = 3,
        x -> x["public_r_formula"]["tree"]["n_tips"] = 4,
        x -> x["public_r_formula"]["tree"]["ultrametric"] = false,
        x -> x["public_r_formula"]["tree"]["unit_ultrametric"] = true,
        x -> x["public_r_formula"]["observed_marginal"] = false,
        x -> x["target_mapping"]["shared_across_traits"] = false,
        x -> x["retained_pre_run_diagnostics"][1]["not_a_receipt"] = false,
        x -> x["retained_pre_run_diagnostics"][2]["not_a_receipt"] = false,
        x -> x["julia_attestation"]["bridge_status"] = "GJL-GATE-STRUCTURED-TERMS",
        x -> x["r_endpoints"][1]["method"] = "profile",
        x -> x["r_endpoints"][1]["upper"] = x["r_endpoints"][1]["lower"],
        x -> x["julia_endpoints"][1]["lower"] += 2e-4,
        x -> pop!(x["julia_endpoints"]),
        x -> x["julia_endpoints"][2]["target"] = x["julia_endpoints"][1]["target"],
        x -> x["endpoint_atol"] = 1e-3,
        x -> x["claim_status"] = "public_parity_claimed",
    )
        tampered = deepcopy(receipt)
        tamper(tampered)
        @test_throws ArgumentError validate_a4_s4_public_r_formula_receipt(tampered;
            allow_synthetic = true)
    end
end
