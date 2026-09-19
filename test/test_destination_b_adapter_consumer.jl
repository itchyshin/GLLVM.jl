using Test, JSON3, SHA, GLLVModels

@testset "Actual R adapter multivariate bridge consumer" begin
    root=joinpath(@__DIR__,"..","docs","dev-log","core070")
    path=joinpath(root,"destination-b-adapter","fixtures-01.json")
    @test bytes2hex(sha256(read(path)))=="089f87d0dcf3c1014fc99646953d8696a0d5aa747287561dd815b5b8bf097549"
    doc=JSON3.read(read(path,String),Dict{String,Any})
    load(p)=JSON3.read(read(joinpath(root,p),String),Dict{String,Any})
    for kind in ("tree","pedigree","dense")
        if kind=="tree"
            r=load("destination-b-tree/r-fit-attempt-01.json")
            j=load("destination-b-tree/independent-attempt-01.json")
            rows=r["Y_traits_by_observations"]
        elseif kind=="pedigree"
            r=load("destination-b-pedigree-fit/r-attempt-02.json")
            j=load("destination-b-pedigree-fit/independent-attempt-01.json")
            rows=r["Y_traits_by_observations"]
        else
            r=load("destination-b-s3b-pilot/r-attempt-02.json")
            j=load("destination-b-s3b-pilot/independent-fit-attempt-02.json")
            rows=r["response"]["Y_traits_by_observations"]
        end
        bundle=doc["bundles"][kind]
        Y=reduce(vcat,permutedims.(Float64.(row) for row in rows))
        output=get(ENV,"GLLVM_DESTINATION_B_BRIDGE_RECEIPT","")
        outfile=isempty(output) ? nothing : joinpath(output,"$kind-result.json")
        outfile===nothing || !ispath(outfile) || error("refusing existing bridge receipt")
        fit=bridge_fit(;y=Y,family="gaussian",d=1,phylo=bundle["precision"],
            options=Dict("phylo_model"=>"multivariate","mode"=>"barelowrank",
                "residual_mode"=>"shared","species_id"=>Int.(bundle["species_id"]),
                "ci_method"=>"wald","g_tol"=>1e-5,"iterations"=>400))
        if outfile!==nothing
            open(io -> JSON3.write(io,Dict("qualified"=>false,"result"=>fit,
                "adapter_fixture_sha256"=>bytes2hex(sha256(read(path))),
                "bridge_source_sha256"=>bytes2hex(sha256(read(joinpath(@__DIR__,"..","src","bridge_precision_multivariate.jl")))))),outfile,"w")
        end
        @test fit.converged && fit.gradient_max<=1e-5
        @test fit.admission_status=="closed"
        @test fit.loglik ≈ j["fit"]["loglik"] atol=1e-8 rtol=1e-8
        @test fit.coefficients ≈ Float64.(j["fit"]["beta"]) atol=1e-6 rtol=1e-6
        @test fit.n_aug==bundle["precision"]["n_aug"]
        @test fit.species_aug_id==Int.(bundle["precision"]["species_aug_id"]) .+ 1
        @test fit.scale==bundle["precision"]["scale"]
        @test length(fit.ci_target_names)==12
        intervals=j["interval_diagnostics"]["intervals"]
        for (i,name) in enumerate(fit.ci_target_names)
            target=only(filter(x -> x["name"]==name,intervals))
            @test fit.ci_lower[i] ≈ target["lower"] atol=1e-5 rtol=1e-5
            @test fit.ci_upper[i] ≈ target["upper"] atol=1e-5 rtol=1e-5
        end
    end
end
