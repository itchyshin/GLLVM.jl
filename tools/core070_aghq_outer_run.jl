using GLLVM,Test
@testset "AGHQ outer driver and numerical prerequisites" begin
    include(joinpath(@__DIR__,"../test/test_aghq_outer.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_frozen.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_grid.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_adapt.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_gate.jl"))
    include(joinpath(@__DIR__,"../test/test_aghq_kd_bound.jl"))
end
