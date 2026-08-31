using GLLVM,Test
include(joinpath(@__DIR__,"../test/test_aghq_public_gaussian.jl"))
include(joinpath(@__DIR__,"../test/test_aghq_gaussian.jl"))
include(joinpath(@__DIR__,"../test/test_aghq_public_binomial.jl"))
include(joinpath(@__DIR__,"../test/test_aghq_public_poisson.jl"))
include(joinpath(@__DIR__,"../test/test_gaussian_empty_design.jl"))
include(joinpath(@__DIR__,"../test/test_profile_failure_bounds.jl"))
include(joinpath(@__DIR__,"../test/test_profile_rootfind.jl"))
