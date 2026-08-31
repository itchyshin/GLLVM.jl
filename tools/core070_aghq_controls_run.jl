# Exact helper calls only. This runner makes no fitted-model or interface claim.
using GLLVM, TOML, SHA, Test
fixture="test/parity/core070_aghq_controls.toml"
spec=TOML.parsefile(fixture)
@test spec["reference_commit"]=="b4d5fee64def88bc768dda1f1f77c29b295edd86"
ids=String[];results=Dict{String,Any}[]
@testset "Core070 paired AGHQ normalization" begin
    for row in spec["cases"]
        id=row["id"];push!(ids,id)
        actual=try
            string(Core.eval(Main,Meta.parse(row["julia_call"])))
        catch err
            err isa ArgumentError ? "ArgumentError" : rethrow()
        end
        @test actual==row["expected"]
        push!(results,Dict("id"=>id,"actual"=>actual,"expected"=>row["expected"],
            "pass"=>actual==row["expected"]))
    end
end
@test length(ids)==length(unique(ids))==16
dialect=Dict{String,Bool}()
@testset "Julia AGHQ input dialect" begin
    for (name,value) in [("whole_float_rejected",9.0),("auto_string_rejected","auto")]
        rejected=try GLLVM._aghq_request(value);false catch err;err isa ArgumentError end
        @test rejected
        dialect[name]=rejected
    end
end
open(ENV["CORE070_CONTROL_OUTPUT"],"w") do io
    TOML.print(io,Dict("schema"=>1,"scope"=>spec["scope"],"cases"=>results,
        "fixture_sha256"=>bytes2hex(sha256(read(fixture))),
        "julia_version"=>string(VERSION),"threads"=>Threads.nthreads(),
        "package_root"=>realpath(dirname(dirname(pathof(GLLVM)))),"dialect_checks"=>dialect))
end
println("CORE070_JULIA_AGHQ_NORMALIZATION_PASS 16 controls; zero fits")
println("CONTROL_RECEIPT_SHA256 ",bytes2hex(sha256(read(ENV["CORE070_CONTROL_OUTPUT"]))))
