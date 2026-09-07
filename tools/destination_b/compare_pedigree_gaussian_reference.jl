using JSON3, SHA, LinearAlgebra, SparseArrays, GLLVM
include(joinpath(@__DIR__, "compare_phylo_gaussian_reference.jl"))

const _DB_PEDIGREE_PRECISION_SHA = "c428e369e6fb554cc4b9bb03f250418d0d51474ba86e01d1be9c7c7301e615ee"
const _DB_PEDIGREE_DLL_SHA = "91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb"

"""Pure validation and cross-evaluation, not optimizer/admission qualification."""
function _db_check_pedigree_gaussian(doc, reference)
    require(ok, message) = ok || throw(ArgumentError(message))
    require(doc["schema_version"] == "destination-b-pedigree-gaussian-marginal-1", "wrong schema")
    require(doc["status"] == "recorded", "R attempt did not return a checked record")
    require(doc["source_pin"] == _DB_PHYLO_SOURCE_PIN && doc["package_version"] == "0.7.0", "wrong frozen source")
    require(doc["dll_sha256"] == _DB_PEDIGREE_DLL_SHA, "wrong frozen DLL")
    require(doc["precision_reference_sha256"] == _DB_PEDIGREE_PRECISION_SHA, "wrong precision reference hash")
    require(doc["precision"] == reference, "embedded precision differs from retained reference")
    require(doc["input_route"] == "pedigree" && doc["residual_mode"] == "shared" &&
        doc["rank"] == 1 && doc["unique"] === false, "different model")
    require(doc["formula"] == "value ~ 0 + trait + animal_latent(species, d=1, pedigree=ped, unique=FALSE)", "different formula")
    require(doc["engine_Q_matches_reference"] === true, "engine precision not verified")
    require(doc["seed"] == 20260907 && doc["reps"] == 2 && doc["trait_names"] == ["a", "b", "c"], "different fixture")
    require(doc["data_hash_encoding"] == "Float64 little-endian column-major", "wrong hash encoding")
    Y = _dbmatrix(doc, "Y_traits_by_observations")
    require(size(Y) == (3,16) && _db_y_hash(Y) == doc["data_sha256"], "response shape/hash mismatch")
    Q = _dbmatrix(reference, "Q_canonical")
    observed = Int.(reference["observed_node_one_based"])
    labels = String.(reference["pedigree"]["node_labels"])
    require(size(Q) == (12,12) && observed == [12,5,9,7,10,6,11,8], "wrong pedigree dimensions/map")
    require(reference["scale"] == 1 && reference["ridge_applied"] === false, "wrong pedigree scale/ridge")
    ii,jj,vv = findnz(sparse(Q))
    phy = GLLVM._validate_precision_fit_input(PrecisionPhy(ii,jj,vv,12,8,labels,
        Float64(reference["log_det_Q"]),1.0,observed))
    original = doc["original_long"]
    require(length(original)==48, "wrong long-data length")
    for species in 1:8, trait in 1:3, replicate in 1:2
        row = original[((species-1)*3 + trait-1)*2 + replicate]
        require(row["species_id"]==species && row["trait_id"]==trait &&
            row["replicate"]==replicate && row["value"]==Y[trait,(species-1)*2+replicate], "long response mapping mismatch")
    end
    permutation = Int.(doc["engine_to_original_long_row_one_based"])
    require(sort(permutation)==collect(1:48), "engine permutation not bijective")
    sid = Int.(doc["engine_species_id_zero_based"])
    tid = Int.(doc["engine_trait_id_zero_based"])
    aug = Int.(doc["engine_augmented_id_zero_based"])
    X = _dbmatrix(doc,"engine_fixed_design")
    require(length(sid)==length(tid)==length(aug)==48 && size(X)==(48,3), "engine design shape mismatch")
    for i in 1:48
        row = original[permutation[i]]
        require(sid[i]==row["species_id"]-1 && tid[i]==row["trait_id"]-1 &&
            aug[i]==observed[sid[i]+1]-1, "engine/ancestor map mismatch")
        require(X[i,:]==[j==tid[i]+1 ? 1.0 : 0.0 for j in 1:3], "fixed design mismatch")
    end
    require(doc["active_parameter_names"] == ["b_fix","b_fix","b_fix","log_sigma_eps",
        "theta_rr_phy","theta_rr_phy","theta_rr_phy"], "wrong active blocks")
    comparisons = Dict{String,Any}()
    for key in ("matched","fitted")
        section = doc[key]
        theta = Float64.(section["values"])
        gradient = Float64.(section["gradient"])
        require(length(theta)==length(gradient)==7 && all(isfinite,theta) &&
            all(isfinite,gradient), "invalid parameters/gradient")
        require(isapprox(maximum(abs,gradient),section["gradient_norm"];atol=1e-12,rtol=1e-12), "gradient norm mismatch")
        native_theta = vcat(theta[1:3],GLLVM.pack_lambda(reshape(theta[5:7],3,1)),theta[4])
        native = GLLVM._precision_multivariate_nll(Y,phy,native_theta;
            rank=1,mode=:barelowrank,residual_mode=:shared,species_id=repeat(1:8;inner=2))
        target = Float64(section["marginal_nll"])
        require(isfinite(target) && GLLVM._pmv_valid_objective(native) && abs(native-target)<=1e-6,
            "$key marginal likelihood mismatch")
        comparisons[key] = Dict("r_nll"=>target,"julia_nll"=>native,"absolute_difference"=>abs(native-target))
    end
    require(doc["fitted"]["convergence"] isa Integer, "missing optimizer status")
    return (; Y, phy, comparisons, r_convergence=doc["fitted"]["convergence"],
        r_gradient_norm=doc["fitted"]["gradient_norm"])
end

function compare_pedigree_gaussian_reference(path, precision_path, dll_path, receipt_path)
    ispath(receipt_path) && throw(ArgumentError("refusing existing receipt path"))
    receipt = Dict{String,Any}("status"=>"error", "qualified"=>false,
        "independent_julia_fit"=>false,"comparison_kind"=>"matched_and_r_fitted_cross_evaluation")
    try
        bytes2hex(sha256(read(precision_path))) == _DB_PEDIGREE_PRECISION_SHA || throw(ArgumentError("wrong precision file"))
        bytes2hex(sha256(read(dll_path))) == _DB_PEDIGREE_DLL_SHA || throw(ArgumentError("wrong DLL file"))
        doc = JSON3.read(read(path,String),Dict{String,Any})
        reference = JSON3.read(read(precision_path,String),Dict{String,Any})
        abspath(doc["dll_path"]) == abspath(dll_path) || throw(ArgumentError("DLL path mismatch"))
        checked = _db_check_pedigree_gaussian(doc,reference)
        merge!(receipt,Dict("status"=>"pass","comparisons"=>checked.comparisons,
            "r_convergence"=>checked.r_convergence,"r_gradient_norm"=>checked.r_gradient_norm,
            "data_sha256"=>_db_y_hash(checked.Y),"reference_file_sha256"=>bytes2hex(sha256(read(path))),
            "precision_file_sha256"=>_DB_PEDIGREE_PRECISION_SHA,"dll_sha256"=>_DB_PEDIGREE_DLL_SHA,
            "checker_sha256"=>bytes2hex(sha256(read(@__FILE__))),"julia_version"=>string(VERSION),
            "source_pin"=>_DB_PHYLO_SOURCE_PIN,
            "precision_fit_sha256"=>_db_gllvm_source_hash("precision_multivariate_fit.jl"),
            "precision_kernel_sha256"=>_db_gllvm_source_hash("precision_multivariate.jl")))
        _db_write_receipt(receipt_path,receipt)
        return receipt
    catch err
        receipt["status"] = "error"
        receipt["error"] = sprint(showerror,err)
        _db_write_receipt(receipt_path,receipt)
        rethrow()
    end
end

if abspath(PROGRAM_FILE)==abspath(@__FILE__)
    length(ARGS)==4 || error("usage: compare_pedigree_gaussian_reference.jl R_JSON PRECISION_JSON DLL RECEIPT")
    JSON3.write(stdout,compare_pedigree_gaussian_reference(ARGS...))
    println()
end
