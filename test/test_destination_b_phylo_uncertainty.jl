using Test, JSON3
include(joinpath(@__DIR__,"..","tools","destination_b","compare_phylo_uncertainty.jl"))

@testset "Frozen marginal phylogenetic uncertainty" begin
    root=joinpath(@__DIR__,"..","docs","dev-log","core070")
    load(path)=JSON3.read(read(joinpath(root,path),String),Dict{String,Any})
    for kind in ("tree","pedigree")
        r=load("destination-b-uncertainty/$kind-r-attempt-01.json")
        p=load("destination-b-$kind/precision-reference.json")
        j=load(kind=="tree" ? "destination-b-tree/independent-attempt-01.json" :
            "destination-b-pedigree-fit/independent-attempt-01.json")
        result=compare_phylo_uncertainty(r,p,j)
        @test result["status"]=="pass" && result["qualified"]===false
        for corrupt in (
            d -> d["uncertainty"]["covariance"][1][1] *= 2,
            d -> d["uncertainty"]["parameter_names"][1] = "wrong",
            d -> d["uncertainty"]["parameter_values"][1] += .1,
            d -> d["uncertainty"]["public_beta_vcov"][1][1] += .1,
            d -> d["uncertainty"]["pd_hessian"] = false,
            d -> d["fitted"]["convergence"] = 1,
            d -> d["data_sha256"] = "wrong")
            bad=deepcopy(r);corrupt(bad)
            @test_throws ArgumentError compare_phylo_uncertainty(bad,p,j)
        end
        for corrupt in (
            d -> d["interval_diagnostics"]["intervals"][1]["lower"] = Inf,
            d -> d["interval_diagnostics"]["intervals"][1]["upper"] += 1,
            d -> d["interval_diagnostics"]["intervals"][2]["name"] = "beta[1]",
            d -> d["initialization"]["r_fitted_coordinates_used"] = true)
            bad=deepcopy(j);corrupt(bad)
            @test_throws ArgumentError compare_phylo_uncertainty(r,p,bad)
        end
    end
end
