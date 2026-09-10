using Test
using LinearAlgebra
using SHA

include("fixtures/destination_b_b1_balanced_complete_crossed_design.jl")

@testset "Destination B B1 balanced complete-crossed pre-run design" begin
    fixture = destination_b_b1_balanced_complete_crossed_design()

    @test fixture.specification.seed == 20_260_915
    @test fixture.specification.reml === false
    @test fixture.specification.formula == "value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) + indep(0 + trait | obs) + indep(0 + trait | cluster_id) + indep(0 + trait | cluster2_id)"
    @test fixture.specification.fixed_coefficients == [-0.20, 0.27]
    @test fixture.specification.loading == [0.72, -0.51]
    @test fixture.specification.sd_obs == [0.36, 0.27]
    @test fixture.specification.sd_cluster == [0.43, 0.32]
    @test fixture.specification.sd_cluster2 == [0.38, 0.29]
    @test fixture.specification.sd_residual == 0.17
    @test fixture.nwide == 3_600
    @test fixture.nlong == 7_200
    @test size(fixture.response_wide) == (2, 3_600)
    @test all(isfinite, fixture.response_wide)
    @test bytes2hex(sha256(reinterpret(UInt8, vec(fixture.response_wide)))) == "0fa63f69d7256b3c4e900cc91db1bf67c1ba41c56d0e0fde64de2c6a11ad738a"
    @test destination_b_b1_balanced_complete_crossed_design().response_wide == fixture.response_wide
    @test length(unique(fixture.unit)) == 12
    @test length(unique(fixture.obs)) == 36
    @test length(unique(fixture.cluster)) == 10
    @test length(unique(fixture.cluster2)) == 10
    @test all(count(==(pair), zip(fixture.cluster, fixture.cluster2)) == 36 for pair in unique(zip(fixture.cluster, fixture.cluster2)))
    @test all(count(==(pair), zip(fixture.unit, fixture.obs)) == 100 for pair in unique(zip(fixture.unit, fixture.obs)))
    @test fixture.wide_labels[1] == (unit = "u_01", obs = "u_01_w_01", cluster = "c_01", cluster2 = "d_01")
    @test fixture.wide_labels[end] == (unit = "u_12", obs = "u_12_w_03", cluster = "c_10", cluster2 = "d_10")
    @test [row.trait for row in fixture.long[1:2]] == ["trait_1", "trait_2"]
    @test all(fixture.long[(2i - 1)].unit == fixture.long[2i].unit && fixture.long[(2i - 1)].obs == fixture.long[2i].obs && fixture.long[(2i - 1)].cluster == fixture.long[2i].cluster && fixture.long[(2i - 1)].cluster2 == fixture.long[2i].cluster2 for i in 1:fixture.nwide)
    @test fixture.tensor.rank == 10
    @test fixture.tensor.minimum_eigenvalue >= 0.30
end
