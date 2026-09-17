using Test, GLLVModels

@testset "Grouped structural identification diagnostics" begin
    redundant = [GroupingTerm(:unit; mode=:latent, rank=1, unique=true)]
    notes = GLLVModels._grouped_identification_diagnostics(redundant, 2)
    @test length(notes) == 1
    @test only(notes).source == :unit
    @test only(notes).parameter_count == 4
    @test only(notes).covariance_dimension == 3
    @test isempty(GLLVModels._grouped_identification_diagnostics(redundant, 3))
    @test isempty(GLLVModels._grouped_identification_diagnostics(
        [GroupingTerm(:unit; mode=:dep)], 2))
    @test isempty(GLLVModels._grouped_identification_diagnostics(
        [GroupingTerm(:unit; mode=:latent, rank=1)], 2))
    @test_logs (:warn, r"structurally non-identifiable") GLLVModels._grouped_warn_identification(redundant, 2)
    @test_logs (:warn, r"structurally non-identifiable") GLLVModels._warn_covariance_redundancy(:phylo, 4, 3)
    @test_logs GLLVModels._warn_covariance_redundancy(:phylo, 6, 6)
end
