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
