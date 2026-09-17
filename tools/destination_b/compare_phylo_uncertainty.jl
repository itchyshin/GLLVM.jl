using JSON3, SHA, LinearAlgebra, GLLVModels
include(joinpath(@__DIR__, "compare_tree_gaussian_reference.jl"))
include(joinpath(@__DIR__, "compare_pedigree_gaussian_reference.jl"))

"""Compare full marginal uncertainty; never substitute conditional curvature."""
function compare_phylo_uncertainty(r, reference, j)
    require(ok,msg) = ok || throw(ArgumentError(msg))
    checked = r["input_route"] == "tree" ? _db_check_tree_gaussian(r,reference) :
        _db_check_pedigree_gaussian(r,reference)
    return _db_compare_checked_uncertainty(r,j,checked)
end

function _db_compare_checked_uncertainty(r,j,checked)
    require(ok,msg) = ok || throw(ArgumentError(msg))
    require(r["fitted"]["convergence"] == 0 && j["fit"]["converged"] === true,
        "both independently fitted models must converge")
    require(checked.r_gradient_norm <= 1e-4 && j["fit"]["gradient_norm"] <= 1e-5,
        "fit gradients exceed predeclared thresholds")
    require(r["data_sha256"] == j["data_sha256"] && j["initialization"]["r_fitted_coordinates_used"] === false,
        "data or independent initialization mismatch")
    for name in ("precision_multivariate_fit.jl", "precision_multivariate.jl", "marginal_target_intervals.jl")
        require(j["invoked_source_sha256"][name] == _db_gllvm_source_hash(name), "retained Julia source changed")
    end
    u = r["uncertainty"]
    require(u["method"] == "frozen production sdreport cov.fixed" && u["pd_hessian"] === true,
        "missing production marginal covariance")
    require(u["parameter_names"] == r["active_parameter_names"] &&
        u["parameter_values"] == r["fitted"]["values"], "covariance coordinates not bound to fit")
    rawV = _dbmatrix(u,"covariance")
    require(size(rawV)==(7,7) && isposdef(Symmetric(rawV)) &&
        isapprox(rawV,rawV';atol=1e-12,rtol=1e-12), "invalid R covariance")
    require(_dbmatrix(u,"public_beta_vcov") == rawV[1:3,1:3], "public vcov differs")
    permutation = [1,2,3,5,6,7,4]
    V = rawV[permutation,permutation]
    theta = Float64.(r["fitted"]["values"])[permutation]
    require(theta[4] > 0, "rank-one sign alignment not satisfied")
    objective = t -> GLLVModels._precision_multivariate_nll(checked.Y,checked.phy,t;
        rank=1,mode=:barelowrank,residual_mode=:shared,species_id=repeat(1:8;inner=2))
    H = GLLVModels._fd_hessian(objective,theta)
    require(isposdef(Symmetric(H)), "matched Julia marginal Hessian not positive definite")
    matchedV = cholesky(Symmetric(H)) \ Matrix{Float64}(I,7,7)
    ownV = _dbmatrix(j["interval_diagnostics"],"covariance")
    require(size(ownV)==(7,7) && isposdef(Symmetric(ownV)), "invalid retained Julia covariance")
    condition = cond(rawV)
    require(isapprox(condition,u["condition_number"];rtol=1e-10), "wrong R conditioning")
    scaling = max(1.,condition/1000)
    rel(A,B) = norm(A-B)/norm(B)
    matched_error = rel(matchedV,V)
    own_error = rel(ownV,V)
    require(matched_error <= 1e-4, "matched marginal covariance mismatch")
    require(own_error <= .01scaling, "own-optimum marginal covariance mismatch")
    rse = sqrt.(diag(V)); mse = sqrt.(diag(matchedV)); jse = sqrt.(diag(ownV))
    require(all(abs.(mse-rse) .<= max.(1e-4rse,ifelse.(rse .<= .01,1e-6,0.))), "matched SE mismatch")
    require(all(abs.(jse-rse) .<= .01scaling*rse), "own-optimum SE mismatch")
    # Analytic gradients of rotation-invariant LL' summaries in native order.
    targets = []
    for a in 1:3
        g=zeros(7);g[a]=1
        push!(targets,("beta[$a]",theta[a],g,"identity"))
    end
    for a in 1:3, b in a:3
        g=zeros(7)
        if a==b
            g[3+a]=2/theta[3+a]
            push!(targets,("phylo_cov[$b,$a]",log(theta[3+a]^2),g,"log"))
        else
            g[3+a]=theta[3+b];g[3+b]=theta[3+a]
            push!(targets,("phylo_cov[$b,$a]",theta[3+a]*theta[3+b],g,"identity"))
        end
    end
    for a in 1:3
        g=zeros(7);g[7]=2
        push!(targets,("residual_var_shared[$a]",2theta[7],g,"log"))
    end
    intervals = j["interval_diagnostics"]["intervals"]
    require(length(intervals)==12 && length(unique(x["name"] for x in intervals))==12,
        "missing or duplicated interval targets")
    endpoint_errors = Dict{String,Float64}()
    z = 1.959963984540054
    for (name,center,g,transform) in targets
        k=findfirst(x -> x["name"]==name,intervals)
        require(k !== nothing, "missing target $name")
        ci=intervals[k]
        require(ci["status"]=="available" && ci["transform"]==transform &&
            ci["method"]=="transformed_wald", "unsupported target interval")
        lo,est,hi = Float64.([ci["lower"],ci["estimate"],ci["upper"]])
        require(all(isfinite,(lo,est,hi)) && lo < est < hi, "invalid target endpoints")
        transform=="log" && require(lo>0, "log target endpoint not positive")
        lower,upper = transform=="log" ? (log(lo),log(hi)) : (lo,hi)
        halfwidth=z*sqrt(dot(g,V*g))
        error=max(abs(lower-(center-halfwidth)),abs(upper-(center+halfwidth)))/halfwidth
        require(isfinite(error) && error<=.05, "own-optimum link endpoint mismatch for $name")
        endpoint_errors[name]=error
    end
    return Dict("status"=>"pass", "qualified"=>false,
        "scope"=>"one fitted Gaussian fixture; production R covariance and analytic derived Wald diagnostics",
        "matched_covariance_relative_error"=>matched_error,"own_covariance_relative_error"=>own_error,
        "r_condition_number"=>condition,"julia_condition_number"=>cond(ownV),
        "maximum_link_endpoint_halfwidth_relative_error"=>maximum(values(endpoint_errors)),
        "endpoint_errors"=>endpoint_errors,"data_sha256"=>r["data_sha256"])
end

if abspath(PROGRAM_FILE)==abspath(@__FILE__)
    length(ARGS)==4 || error("usage: compare_phylo_uncertainty.jl R_JSON PRECISION_JSON JULIA_JSON RECEIPT")
    ispath(ARGS[4]) && error("refusing existing receipt")
    result=Dict{String,Any}("status"=>"error","qualified"=>false)
    try
        hashes=[bytes2hex(sha256(read(p))) for p in ARGS[1:3]]
        allowed = Dict(
            "c8fcb957ba4e90f9fa2c15718409b6169c6355f265b3911564a3ae8a88209a0b" =>
                ["ab01ee47206565eb1af7da391af313953b8a97c6bb11d9b6160655aaa0429170",
                 "681a751f1298fc729218b37c999572e001bc5aba9bcf9e0a37877de40b5294dc"],
            "ebbe46e9f620f89b60bd6c3e44544d0c7abe5da40f39a2bbca9b4a0629f15e77" =>
                ["c428e369e6fb554cc4b9bb03f250418d0d51474ba86e01d1be9c7c7301e615ee",
                 "3e7dc59a5f5a5c2437cceca8c6409a14451113a0efd1de69e0dbf127959012f1"])
        get(allowed,hashes[1],nothing)==hashes[2:3] || error("unsealed uncertainty input files")
        docs=[JSON3.read(read(p,String),Dict{String,Any}) for p in ARGS[1:3]]
        merge!(result,compare_phylo_uncertainty(docs...))
        result["input_sha256"]=[bytes2hex(sha256(read(p))) for p in ARGS[1:3]]
        result["checker_sha256"]=bytes2hex(sha256(read(@__FILE__)))
        _db_write_receipt(ARGS[4],result)
        JSON3.write(stdout,result);println()
    catch err
        result["status"]="error";result["error"]=sprint(showerror,err)
        _db_write_receipt(ARGS[4],result)
        rethrow()
    end
end
