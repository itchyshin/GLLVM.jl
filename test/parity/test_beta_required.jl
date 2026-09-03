using Test
isdefined(@__MODULE__, :core070_poisson_beta_required) || include(joinpath(@__DIR__, "poisson_beta_health.jl"))
@testset "Original beta model: complete required health" begin
    report=core070_poisson_beta_required(:beta)
    for (name,passed) in sort!(collect(report["checks"]))
        @testset "$name" begin
            @test passed
        end
    end
end
