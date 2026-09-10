using Test, JSON3
include(joinpath(@__DIR__,"..","tools","destination_b","compare_dense_uncertainty.jl"))
@testset "Dense uncertainty retained reference checks" begin
    root=joinpath(@__DIR__,"..","docs","dev-log","core070")
    dir=joinpath(root,"destination-b-uncertainty")
    r=joinpath(dir,"dense-bfgs-03.json")
    s=joinpath(dir,"dense-bfgs-sidecar-03.json")
    old=joinpath(root,"destination-b-s3b-pilot","r-attempt-02.json")
    j=joinpath(root,"destination-b-s3b-pilot","independent-fit-attempt-02.json")
    side=JSON3.read(read(s,String),Dict{String,Any})
    doc=JSON3.read(read(r,String),Dict{String,Any})
    @test doc["fitted_r"]["convergence"]==0
    @test maximum(abs,side["gradient"])<=1e-4
    @test side["reference_sha256"]==bytes2hex(sha256(read(r)))
    dll=doc["provenance"]["dll_path"]
    if isfile(dll)
        mktempdir() do tmp
            output=joinpath(tmp,"pass.json")
            @test compare_dense_uncertainty(r,s,old,j,dll,output)["status"]=="pass"
            @test_throws ArgumentError compare_dense_uncertainty(r,s,old,j,dll,output)
            for (i,mutate) in enumerate((
                x -> x["reference_sha256"]="wrong",
                x -> x["optimizer_policy"]="unknown",
                x -> x["gradient"][1]=1.,
                x -> x["uncertainty"]["covariance"][1][1]*=2))
                bad=deepcopy(side);mutate(bad)
                input=joinpath(tmp,"bad$i.json")
                open(io -> JSON3.write(io,bad),input,"w")
                receipt=joinpath(tmp,"error$i.json")
                @test_throws Exception compare_dense_uncertainty(r,input,old,j,dll,receipt)
                @test JSON3.read(read(receipt,String))["status"]=="error"
            end
        end
    else
        @test_skip false # actual private frozen DLL required; never a pairing pass
    end
end
