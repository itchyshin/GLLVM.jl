using Test
using GLLVModels
using LinearAlgebra
using SparseArrays

function _jci_precision(Q::AbstractMatrix)
    sparseQ = sparse(Float64.(Q))
    leaves = size(sparseQ, 1)
    return PrecisionPhy(findnz(sparseQ)..., leaves, leaves,
        ["tip_$i" for i in 1:leaves],
        logdet(cholesky(Symmetric(Matrix(sparseQ)))), 1.0, collect(1:leaves))
end

function _jci_nonidentity_phylo()
    return _jci_precision([2.0 -0.5; -0.5 2.0])
end

@testset "joint covariance-component identification" begin
    @test isdefined(GLLVModels, :_joint_covariance_identification)
    isdefined(GLLVModels, :_joint_covariance_identification) || return

    # p=3 rank-one factor plus diagonal residual at Kphy=I is locally
    # identifiable. An unrestricted p-by-p phylo covariance basis would
    # incorrectly reject this actual reduced-rank tangent model.
    phy_identity = _jci_precision(Matrix{Float64}(I, 4, 4))
    identified = GLLVModels._joint_covariance_identification(phy_identity, collect(1:4),
        GroupingTerm[], SparseMatrixCSC{Float64,Int}[], reshape([0.6, 0.45, 0.3], 3, 1))
    @test identified.reason === :identified
    @test identified.rank == length(identified.labels) == 6
    @test isempty(identified.aliases)

    # The optional phylogenetic diagonal is represented by its own actual
    # tangents; with a non-identity phylogenetic kernel it remains distinct
    # from observation residual diagonal variance.
    phy = _jci_nonidentity_phylo()
    repeated_tips = [1, 2, 1, 2]
    identified_unique = GLLVModels._joint_covariance_identification(phy, repeated_tips,
        GroupingTerm[], SparseMatrixCSC{Float64,Int}[], reshape([0.6, 0.45, 0.3], 3, 1);
        phylo_unique_variance = [0.15, 0.12, 0.09])
    @test identified_unique.reason === :identified
    @test identified_unique.rank == length(identified_unique.labels) == 9

    # With Kphy=I at p=1, the actual loading tangent, an identity ordinary
    # incidence, and the residual all have the same covariance derivative.
    one_trait_terms = [GroupingTerm(:unit; mode = :indep, common = false)]
    identity_incidence = [GLLVModels._grouped_incidence(collect(1:4), 4)]
    phy_ordinary = GLLVModels._joint_covariance_identification(phy_identity, collect(1:4),
        one_trait_terms, identity_incidence, reshape([0.7], 1, 1))
    @test phy_ordinary.reason === :nonidentifiable
    @test phy_ordinary.rank < length(phy_ordinary.labels)
    @test any(alias -> alias.kind === :phylo_vs_ordinary, phy_ordinary.aliases)
    @test any(alias -> alias.kind === :ordinary_vs_residual, phy_ordinary.aliases)

    # An ordinary one-level-per-observation source is exactly confounded with
    # each trait residual, independently of the phylogenetic kernel.
    residual_alias = GLLVModels._joint_covariance_identification(phy, repeated_tips,
        one_trait_terms, identity_incidence, reshape([0.55, 0.25], 2, 1))
    @test residual_alias.reason === :nonidentifiable
    @test any(alias -> alias.kind === :ordinary_vs_residual, residual_alias.aliases)

    # Equal group kernels, including separately named sources, identify only
    # their sum. This must not be mistaken for two independent components.
    duplicated_terms = [GroupingTerm(:unit; mode = :indep, common = false),
        GroupingTerm(:cluster; mode = :indep, common = false)]
    duplicate_incidence = GLLVModels._grouped_incidence([1, 1, 2, 2], 4)
    duplicate_alias = GLLVModels._joint_covariance_identification(phy, repeated_tips,
        duplicated_terms, [duplicate_incidence, copy(duplicate_incidence)],
        reshape([0.6], 1, 1))
    @test duplicate_alias.reason === :nonidentifiable
    @test any(alias -> alias.kind === :duplicate_ordinary, duplicate_alias.aliases)

    # A zero loading gives a zero covariance tangent and must not be normalized
    # into a spurious full-rank diagnostic.
    zero_tangent = GLLVModels._joint_covariance_identification(phy_identity, collect(1:4),
        GroupingTerm[], SparseMatrixCSC{Float64,Int}[], zeros(1, 1))
    @test zero_tangent.reason === :invalid
    @test "phylo.loading[1]" in zero_tangent.zero_tangent_labels

    nonfinite_tangent = GLLVModels._joint_covariance_identification(phy_identity, collect(1:4),
        GroupingTerm[], SparseMatrixCSC{Float64,Int}[], fill(NaN, 1, 1))
    @test nonfinite_tangent.reason === :invalid
    @test "phylo.loading[1]" in nonfinite_tangent.nonfinite_tangent_labels
end
