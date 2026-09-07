using JSON3, SHA
include(joinpath(@__DIR__,"compare_phylo_uncertainty.jl"))

function compare_dense_uncertainty(reference_path,sidecar_path,old_path,julia_path,dll_path,output)
    ispath(output) && throw(ArgumentError("refusing existing receipt"))
    result=Dict{String,Any}("status"=>"error","qualified"=>false)
    try
        hash(p)=bytes2hex(sha256(read(p)))
        hash(old_path)=="5166bd887d8e85a962d551fd8670bc6f095d7b7cfff22d927b04cba34f3b981f" || error("wrong original reference")
        hash(julia_path)=="712498737bd4f15998ffe294dacfde5a97fee1afb1b23160d7c1a6a204cc9b5e" || error("wrong retained Julia fit")
        load(p)=JSON3.read(read(p,String),Dict{String,Any})
        r,side,old,j=load.((reference_path,sidecar_path,old_path,julia_path))
        side["schema_version"]=="destination-b-dense-uncertainty-1" || error("wrong sidecar schema")
        side["reference_sha256"]==hash(reference_path) || error("unbound uncertainty sidecar")
        side["data_sha256"]==r["response"]["data_sha256"] || error("sidecar data mismatch")
        side["dll_sha256"]==_DB_TREE_DLL_SHA || error("sidecar DLL mismatch")
        r["response"]==old["response"] && r["precision"]==old["precision"] &&
            r["source_covariance"]==old["source_covariance"] &&
            r["fitted_r"]["values"]==old["fitted_r"]["values"] || error("replay changed data/model/fitted coordinates")
        compare_phylo_gaussian_reference(reference_path;dll_path=dll_path,
            expected_dll_sha256=_DB_TREE_DLL_SHA)
        fixture,precision=r["fixture"],r["precision"]
        Y=_dbmatrix(r["response"],"Y_traits_by_observations")
        mapping=_db_validate_long_mapping(fixture,precision,3,16)
        accepted=_db_validate_precision(precision,mapping,8,16)
        gradient=Float64.(side["gradient"])
        length(gradient)==7 && all(isfinite,gradient) || error("invalid marginal gradient")
        normalized=Dict("fitted"=>r["fitted_r"],"data_sha256"=>side["data_sha256"],
            "active_parameter_names"=>r["fitted_r"]["active_parameter_names"],
            "uncertainty"=>side["uncertainty"])
        checked=(;Y,phy=accepted.phy,r_gradient_norm=maximum(abs,gradient))
        merge!(result,_db_compare_checked_uncertainty(normalized,j,checked))
        result["input_sha256"]=[hash(p) for p in (reference_path,sidecar_path,old_path,julia_path,dll_path)]
        result["checker_sha256"]=hash(@__FILE__)
        result["shared_checker_sha256"]=hash(joinpath(@__DIR__,"compare_phylo_uncertainty.jl"))
        _db_write_receipt(output,result)
        return result
    catch err
        result["status"]="error";result["error"]=sprint(showerror,err)
        _db_write_receipt(output,result)
        rethrow()
    end
end
if abspath(PROGRAM_FILE)==abspath(@__FILE__)
    length(ARGS)==6 || error("usage: compare_dense_uncertainty.jl NEW_R SIDECAR OLD_R JULIA DLL OUTPUT")
    JSON3.write(stdout,compare_dense_uncertainty(ARGS...));println()
end
