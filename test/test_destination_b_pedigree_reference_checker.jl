using Test, JSON3
include(joinpath(@__DIR__,"..","tools","destination_b","compare_pedigree_gaussian_reference.jl"))

@testset "Frozen pedigree fitted-reference checker" begin
    root = joinpath(@__DIR__,"..","docs","dev-log","core070")
    doc = JSON3.read(read(joinpath(root,"destination-b-pedigree-fit","r-attempt-02.json"),String),Dict{String,Any})
    reference = JSON3.read(read(joinpath(root,"destination-b-pedigree","precision-reference.json"),String),Dict{String,Any})
    result = _db_check_pedigree_gaussian(doc,reference)
    @test result.r_convergence == 1 # retained singular-convergence attempt, not passed fitting
    @test result.comparisons["matched"]["absolute_difference"] <= 1e-6
    @test result.comparisons["fitted"]["absolute_difference"] <= 1e-6
    for mutate in (
        x->(x["status"]="error"),
        x->(x["data_sha256"]="0"^64),
        x->(x["dll_sha256"]="0"^64),
        x->(x["residual_mode"]="trait"),
        x->(x["precision"]["scale"]=2),
        x->(x["precision"]["log_det_Q"]+=0.1),
        x->(x["engine_augmented_id_zero_based"][1]=0),
        x->(x["engine_to_original_long_row_one_based"][1]=x["engine_to_original_long_row_one_based"][2]),
        x->(x["engine_fixed_design"][1][1]+=0.1),
        x->(x["matched"]["marginal_nll"]+=0.01),
        x->(x["fitted"]["marginal_nll"]+=0.01),
        x->(x["fitted"]["gradient_norm"]+=1.0))
        wrong = deepcopy(doc)
        mutate(wrong)
        @test_throws ArgumentError _db_check_pedigree_gaussian(wrong,reference)
    end
end

# Same-data optimizer-policy assessment uses the predeclared point classes
# from phylo-transport-design.md section3. It is not interval coverage or an
# R-public-admission verdict. The original failed policy must remain false.
function _pedigree_point_policy_ok(r, j)
    r["data_sha256"] == j["data_sha256"] || return false
    r["fitted"]["convergence"] == 0 && j["fit"]["converged"] === true || return false
    rg, jg = r["fitted"]["gradient_norm"], j["fit"]["gradient_norm"]
    isfinite(rg) && isfinite(jg) && rg <= 1e-4 && jg <= 1e-5 || return false
    rn, jn = r["fitted"]["marginal_nll"], j["fit"]["marginal_nll"]
    isfinite(rn) && isfinite(jn) && abs(rn-jn) <= 1e-6 * max(1,abs(rn),abs(jn)) || return false
    rl = Float64.(r["fitted"]["values"][5:7])
    jl = vec(_dbmatrix(j["fit"],"loading"))
    return length(jl)==3 && all(isfinite,jl) && all(isfinite,rl) &&
        all(isapprox.(jl,rl;rtol=1e-4,atol=0))
end

@testset "Retained pedigree optimizer policies stay distinct" begin
    root = joinpath(@__DIR__,"..","docs","dev-log","core070")
    loadrecord(name) = JSON3.read(read(joinpath(root,"destination-b-pedigree-fit",name),String),Dict{String,Any})
    baseline = loadrecord("r-attempt-02.json")
    bfgs = loadrecord("r-bfgs-attempt-01.json")
    j = loadrecord("independent-attempt-01.json")
    reference = JSON3.read(read(joinpath(root,"destination-b-pedigree","precision-reference.json"),String),Dict{String,Any})
    checked = _db_check_pedigree_gaussian(bfgs,reference)
    @test checked.r_convergence == 0
    @test !_pedigree_point_policy_ok(baseline,j)
    @test _pedigree_point_policy_ok(bfgs,j)
    @test baseline["data_sha256"] == bfgs["data_sha256"] == j["data_sha256"]
    for mutate in (x->(x["fitted"]["convergence"]=1),
        x->(x["fitted"]["gradient_norm"]=Inf),
        x->(x["data_sha256"]="0"^64),
        x->(x["fitted"]["values"][5]+=0.01))
        wrong = deepcopy(bfgs)
        mutate(wrong)
        @test !_pedigree_point_policy_ok(wrong,j)
    end
end
