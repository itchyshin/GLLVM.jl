using Test, JSON3
include(joinpath(@__DIR__, "..", "tools", "destination_b", "compare_tree_gaussian_reference.jl"))

@testset "Frozen tree fitted-reference checker" begin
    root = joinpath(@__DIR__, "..", "docs", "dev-log", "core070", "destination-b-tree")
    r = JSON3.read(read(joinpath(root,"r-fit-attempt-01.json"),String),Dict{String,Any})
    precision = JSON3.read(read(joinpath(root,"precision-reference.json"),String),Dict{String,Any})
    checked = _db_check_tree_gaussian(r,precision)
    @test checked.r_convergence == 1 # unsuccessful optimizer remains unsuccessful
    @test checked.comparisons["matched"]["absolute_difference"] <= 1e-6
    @test checked.comparisons["fitted"]["absolute_difference"] <= 1e-6
    for corrupt in (
        d -> d["status"] = "error",
        d -> d["data_sha256"] = "wrong",
        d -> d["precision_reference_sha256"] = "wrong",
        d -> d["precision"]["scale"] = 1,
        d -> d["precision"]["log_det_Q"] += 1,
        d -> d["engine_augmented_id_zero_based"][1] = 0,
        d -> d["engine_to_original_long_row_one_based"][1] = 2,
        d -> d["engine_fixed_design"][1][1] += 1,
        d -> d["active_parameter_names"][1] = "bad",
        d -> d["matched"]["marginal_nll"] += .01,
        d -> d["fitted"]["gradient_norm"] = Inf,
        d -> d["rank"] = 2)
        bad = deepcopy(r)
        corrupt(bad)
        @test_throws ArgumentError _db_check_tree_gaussian(bad,precision)
    end
end

@testset "Retained tree fitted policies and interval diagnostics" begin
    root = joinpath(@__DIR__, "..", "docs", "dev-log", "core070", "destination-b-tree")
    load(name) = JSON3.read(read(joinpath(root,name),String),Dict{String,Any})
    baseline = load("r-fit-attempt-01.json")
    r = load("r-bfgs-attempt-01.json")
    j = load("independent-attempt-01.json")
    @test _db_check_tree_gaussian(r,load("precision-reference.json")).r_convergence == 0
    @test baseline["fitted"]["convergence"] == 1
    @test r["data_sha256"] == baseline["data_sha256"] == j["data_sha256"]
    @test r["precision"] == baseline["precision"]
    @test r["fitted"]["gradient_norm"] <= 1e-4
    @test j["fit"]["converged"] && j["fit"]["gradient_norm"] <= 1e-5
    @test isapprox(r["fitted"]["marginal_nll"],j["fit"]["marginal_nll"];rtol=1e-6,atol=0)
    @test all(isapprox.(Float64.(r["fitted"]["values"][5:7]),
        [row[1] for row in j["fit"]["loading"]];rtol=1e-4,atol=0))
    @test j["r_convergence"] == 1 # original comparison remains immutable
    @test !j["qualification"]["qualified"]
    intervals = j["interval_diagnostics"]["intervals"]
    @test length(intervals) == 12
    @test all(x["status"] == "available" && all(isfinite, [x["lower"],x["estimate"],x["upper"]]) &&
        x["lower"] <= x["estimate"] <= x["upper"] for x in intervals)
end
