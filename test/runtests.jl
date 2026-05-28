using Test
using gllvmTMB

@testset "smoke" begin
    @test 1 + 1 == 2
end

include("test_likelihood.jl")
include("test_packing.jl")
include("test_fit.jl")
include("test_fixed_effects.jl")
