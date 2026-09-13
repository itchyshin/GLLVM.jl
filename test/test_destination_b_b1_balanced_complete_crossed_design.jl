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
    @test bytes2hex(sha256(reinterpret(UInt8, vec(fixture.response_wide)))) == "14061fdbe261df1a779ddaf0ded4cd6027efe0350a1fc531a52a7e3facc8c7ec"
    @test destination_b_b1_balanced_complete_crossed_design().response_wide == fixture.response_wide
    @test length(unique(fixture.unit)) == 12
    @test length(unique(fixture.obs)) == 36
    @test length(unique(fixture.cluster)) == 10
    @test length(unique(fixture.cluster2)) == 10
    @test all(count(==(pair), zip(fixture.cluster, fixture.cluster2)) == 36 for pair in unique(zip(fixture.cluster, fixture.cluster2)))
    @test all(count(==(pair), zip(fixture.unit, fixture.obs)) == 100 for pair in unique(zip(fixture.unit, fixture.obs)))
    @test fixture.wide_formula[1] == (unit = "u_01", obs = "u_01_w_01", cluster_id = "c_01", cluster2_id = "d_01")
    @test fixture.wide_formula[end] == (unit = "u_12", obs = "u_12_w_03", cluster_id = "c_10", cluster2_id = "d_10")
    @test [row.trait for row in fixture.long[1:2]] == ["trait_1", "trait_2"]
    @test all(fixture.long[(2i - 1)].unit == fixture.long[2i].unit && fixture.long[(2i - 1)].obs == fixture.long[2i].obs && fixture.long[(2i - 1)].cluster_id == fixture.long[2i].cluster_id && fixture.long[(2i - 1)].cluster2_id == fixture.long[2i].cluster2_id for i in 1:fixture.nwide)
    @test fixture.tensor.rank == 10
    @test fixture.tensor.minimum_eigenvalue >= 0.30

    # The long table must expose the exact formula names.  The grouping tuple
    # is unique per wide row; its trait-qualified long-row version is unique.
    @test all(name in propertynames(first(fixture.long)) for name in (:unit, :obs, :cluster_id, :cluster2_id))
    wide_tuples = [(row.unit, row.obs, row.cluster_id, row.cluster2_id) for row in fixture.wide_formula]
    long_tuples = [(row.unit, row.obs, row.cluster_id, row.cluster2_id) for row in fixture.long]
    trait_qualified_long_tuples = [(row.unit, row.obs, row.cluster_id, row.cluster2_id, row.trait) for row in fixture.long]
    @test length(unique(wide_tuples)) == fixture.nwide
    @test all(count(==(key), long_tuples) == 2 for key in unique(long_tuples))
    @test length(unique(trait_qualified_long_tuples)) == fixture.nlong

    @test fixture.frozen_r.git_sha == "b4d5fee64def88bc768dda1f1f77c29b295edd86"
    @test fixture.frozen_r.archive_sha256 == "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
    @test fixture.frozen_r.shared_library_sha256 == "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30"
    @test fixture.frozen_r.runner_sha256 == "9d1f1fa95655bd8887d7e04d2c2d10c0311fac094205a4d47dd7ee6ebb9ca585"
    repository_root = normpath(joinpath(@__DIR__, ".."))
    preflight_path = joinpath(repository_root, fixture.frozen_r.preflight_path)
    @test isfile(preflight_path)
    @test bytes2hex(sha256(read(joinpath(repository_root, fixture.frozen_r.reference_runner_path)))) == fixture.frozen_r.runner_sha256
    preflight_source = read(preflight_path, String)
    @test occursin(fixture.frozen_r.git_sha, preflight_source)
    @test occursin(fixture.frozen_r.archive_sha256, preflight_source)
    @test occursin(fixture.frozen_r.shared_library_sha256, preflight_source)
    @test occursin(fixture.frozen_r.runner_sha256, preflight_source)
    @test all(occursin(field, preflight_source) for field in ("source_sha", "source_version", "source_archive_sha256", "installed_shared_library_sha256"))
    @test !occursin("gllvmTMB::gllvmTMB", preflight_source)
end
