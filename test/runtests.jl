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
include("test_signed_sigma_phy.jl")
include("test_sparse_phy.jl")
include("test_ppca_init.jl")
include("test_em_fa.jl")
include("test_lowrank_cholesky.jl")
include("test_confint.jl")
include("test_confint_profile.jl")
include("test_confint_bootstrap.jl")
include("test_confint_derived.jl")
include("test_profile_derived_fix.jl")
include("test_takahashi_selinv.jl")
include("test_em_louis.jl")
