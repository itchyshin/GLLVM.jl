using Test
using GLLVM

@testset "smoke" begin
    @test 1 + 1 == 2
end

include("test_likelihood.jl")
include("test_packing.jl")
include("test_fit.jl")
include("test_fixed_effects.jl")
include("test_W_and_diag.jl")
include("test_phy.jl")
include("test_sparse_phy.jl")
include("test_ppca_init.jl")
