using JSON3, SHA, GLLVM
using Distributions: Normal
include(joinpath(@__DIR__,"fit_phylo_gaussian_reference.jl"))
include(joinpath(@__DIR__,"compare_tree_gaussian_reference.jl"))

const _DB_TREE_FIT_REFERENCE_SHA = "f702a7859980e29f59b19bee8878171df385ef9bd581dc338520055f0f140223"

"""
Record one public independent Julia tree fit and all interval diagnostics.
The R optimizer's status is retained separately and never upgraded by Julia.
"""
function fit_tree_gaussian_reference(path,precision_path,dll_path,receipt_path)
    _dbfit_require_unused_path(receipt_path,path,dll_path)
    input_path = receipt_path * ".input.json"
    _dbfit_require_unused_path(input_path,path,dll_path)
    receipt = _dbfit_new_receipt(path,dll_path,_DB_TREE_DLL_SHA)
    receipt["expected_reference_file_sha256"] = _DB_TREE_FIT_REFERENCE_SHA
    receipt["runner_source_sha256"] = bytes2hex(sha256(read(@__FILE__)))
    receipt["shared_receipt_helper_sha256"] = bytes2hex(sha256(read(joinpath(@__DIR__,"fit_phylo_gaussian_reference.jl"))))
    receipt["checker_source_sha256"] = bytes2hex(sha256(read(joinpath(@__DIR__,"compare_tree_gaussian_reference.jl"))))
    try
        receipt["reference_file_sha256"] = bytes2hex(sha256(read(path)))
        receipt["reference_file_sha256"] == _DB_TREE_FIT_REFERENCE_SHA || throw(ArgumentError("wrong immutable R reference"))
        input = compare_tree_gaussian_reference(path,precision_path,dll_path,input_path)
        receipt["input_comparison"] = input
        push!(receipt["attempt_stages"],"strict_input_comparison_passed")
        doc = JSON3.read(read(path,String),Dict{String,Any})
        precision = JSON3.read(read(precision_path,String),Dict{String,Any})
        checked = _db_check_tree_gaussian(doc,precision)
        receipt["source_pin"] = _DB_PHYLO_SOURCE_PIN
        receipt["schema_version"] = doc["schema_version"]
        receipt["data_sha256"] = _db_y_hash(checked.Y)
        receipt["r_convergence"] = checked.r_convergence
        receipt["r_gradient_norm"] = checked.r_gradient_norm
        receipt["route"] = Dict("entrypoint"=>"GLLVM.fit_gllvm","family"=>"Normal",
            "rank"=>1,"mode"=>"barelowrank","residual_mode"=>"shared",
            "n_aug"=>14,"n_observed"=>8,"retained_unobserved_internal_nodes"=>6)
        receipt["initialization"] = Dict("kind"=>"Julia_default_from_Y",
            "start_keyword_supplied"=>false,"r_matched_coordinates_used"=>false,
            "r_fitted_coordinates_used"=>false,"rng_used"=>false)
        receipt["invoked_source_sha256"] = Dict(name=>_dbfit_source_hash(name) for name in
            ("families/fit_gllvm.jl","precision_multivariate_fit.jl","precision_multivariate.jl",
             "precision_fit_admission.jl","marginal_target_intervals.jl","confint_family.jl",
             "packing.jl","source_fit.jl","fit_verdict.jl","phylo_precision.jl"))
        started = time_ns()
        fit = fit_gllvm(checked.Y;family=Normal(),phylo=checked.phy,phylo_rank=1,
            phylo_mode=:barelowrank,residual_mode=:shared,
            species_id=repeat(1:8;inner=2),iterations=400,g_tol=1e-5)
        receipt["fit_elapsed_seconds"] = (time_ns()-started)/1e9
        receipt["fit"] = _dbfit_fit_receipt(fit)
        push!(receipt["attempt_stages"],"public_native_fit_returned")
        started = time_ns()
        intervals = precision_multivariate_intervals(fit;level=.95)
        receipt["interval_elapsed_seconds"] = (time_ns()-started)/1e9
        receipt["interval_diagnostics"] = _dbfit_interval_receipt(intervals,_dbfit_expected_primary_targets(3))
        push!(receipt["attempt_stages"],"interval_diagnostic_returned")
        rtheta = doc["fitted"]["values"]
        rfit = Dict("blocks"=>Dict("b_fix"=>rtheta[1:3],"log_sigma_eps"=>rtheta[4],
            "theta_rr_phy"=>rtheta[5:7]),"marginal_nll"=>doc["fitted"]["marginal_nll"])
        receipt["independent_vs_r_fitted"] = _dbfit_r_fitted_comparison(fit,rfit)
        receipt["status"] = "recorded"
        _dbfit_validate_receipt(receipt)
        _dbfit_write_receipt(receipt_path,receipt)
        return receipt
    catch err
        receipt["status"] = "error"
        receipt["error_type"] = string(typeof(err))
        receipt["error"] = sprint(showerror,err)
        _dbfit_validate_receipt(receipt)
        _dbfit_write_receipt(receipt_path,receipt)
        rethrow()
    end
end

if abspath(PROGRAM_FILE)==abspath(@__FILE__)
    length(ARGS)==4 || error("usage: fit_tree_gaussian_reference.jl R_JSON PRECISION_JSON DLL RECEIPT")
    JSON3.write(stdout,fit_tree_gaussian_reference(ARGS...))
    println()
end
