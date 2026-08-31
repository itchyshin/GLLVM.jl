import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "docs/dev-log/core070/latent-bare-model-contract.json"
RUNNER_R = ROOT / "tools/core070_latent_bare_model.R"
RUNNER_JL = ROOT / "tools/core070_latent_bare_model.jl"
VERIFIER = ROOT / "tools/core070_verify_latent_bare_model.py"


def need(ok, message):
    if not ok:
        raise AssertionError(message)


def main():
    need(CONTRACT.is_file(), "missing frozen latent-bare contract")
    contract = json.loads(CONTRACT.read_text())
    need(contract["reference_commit"] ==
         "b4d5fee64def88bc768dda1f1f77c29b295edd86", "wrong reference")
    need(contract["source_fact_id"] == "covariance/COV-ORD-LATENT-BARE",
         "wrong source fact")
    need(contract["input_id"] == "INPUT-GAUSS-LOADINGS", "wrong input")
    need(contract["case_id"] == "CORE070-COV-COV-ORD-LATENT-BARE-MODEL",
         "wrong case")
    need(contract["dimensions"] == {"traits": 3, "units": 18, "rank": 1,
                                     "free_coordinates": 7}, "wrong dimensions")
    need(contract["model"]["unique"] is False and
         contract["model"]["source_covariance"] == "I_18" and
         contract["model"]["residual_sd"] == "free_common",
         "wrong covariance model")
    need(contract["comparands"] ==
         ["normalized_loglik", "beta", "loading_crossproduct", "residual_variance"],
         "raw loadings must not be a comparand")
    need(contract["tolerances"] == {
        "fixed_point_abs_loglik": 1e-8,
        "fit_abs_loglik": 1e-5,
        "beta_max_abs": 1e-4,
        "loading_crossproduct_max_abs": 1e-4,
        "residual_variance_abs": 1e-4,
        "gradient_max": 1e-4,
    }, "changed tolerances")
    need(contract["roles"] == ["native_julia", "julia_formula", "public_r_bridge"],
         "all three roles are required")
    need(set(contract["negative_controls"]) == {
        "unique_true_is_distinct", "rank_exceeds_traits", "asymmetric_source",
        "nonpositive_source", "group_projection_mismatch", "missing_long_cell",
        "duplicate_long_cell", "raw_loading_sign_not_compared",
    }, "missing negative control")
    for path in (RUNNER_R, RUNNER_JL, VERIFIER):
        need(path.is_file(), f"missing executable: {path.relative_to(ROOT)}")
    print("CORE070_LATENT_BARE_CONTRACT_PASS")


if __name__ == "__main__":
    main()
