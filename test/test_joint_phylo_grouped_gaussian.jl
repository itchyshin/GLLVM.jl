using Test
using GLLVM
using LinearAlgebra
using SparseArrays

include(joinpath(@__DIR__, "fixtures", "destination_b_joint_phylo_grouping.jl"))

function _jpg_precision(fixture; Q = sparse(fixture.Q), scale = fixture.applied_scale,
        map = fixture.species_aug_id, log_det = fixture.precision_logdet)
    ii, jj, xx = findnz(Q)
    return PrecisionPhy(ii, jj, xx, fixture.n_aug, fixture.n_tip, fixture.node_labels,
        log_det, scale, map)
end

function _jpg_loglik(fixture, phy; ordinary_incidences = [fixture.crossed_incidence],
        ordinary_trait_variances = [fixture.grouped_variance],
        phylo_unique_variance = fixture.phylo_unique_variance, psi = fixture.psi)
    residualized = fixture.response .- reshape(fixture.mean, size(fixture.response))
    return GLLVM.joint_phylo_grouped_gaussian_loglik(residualized, phy,
        fixture.loading, psi; phylo_unique_variance = phylo_unique_variance,
        species_id = fixture.species_id, ordinary_incidences = ordinary_incidences,
        ordinary_trait_variances = ordinary_trait_variances)
end

@testset "Destination B joint phylo plus grouped Gaussian kernel" begin
    fixture = destination_b_joint_phylo_grouping_fixture()
    phy = _jpg_precision(fixture)
    expected = -fixture.expected_nll

    @testset "sparse joint precision equals the independent dense oracle" begin
        @test isapprox(fixture.expected_nll, 8.59559088480814; atol = 1e-12, rtol = 0)
        @test isapprox(_jpg_loglik(fixture, phy), expected; atol = 1e-10, rtol = 1e-10)
    end

    @testset "scale, map, and stored determinant transport remain explicit" begin
        double_Q = phy.scale .* phy.Q
        double_scaled = _jpg_precision(fixture; Q = double_Q,
            log_det = logdet(cholesky(Symmetric(Matrix(double_Q)))))
        @test !isapprox(_jpg_loglik(fixture, double_scaled), expected; atol = 1e-6, rtol = 1e-6)
        swapped = _jpg_precision(fixture; map = reverse(fixture.species_aug_id))
        @test !isapprox(_jpg_loglik(fixture, swapped), expected; atol = 1e-6, rtol = 1e-6)
        delta = 0.37
        shifted = _jpg_precision(fixture; log_det = phy.log_det + delta)
        nfields = size(fixture.loading, 2) + count(>(0), fixture.phylo_unique_variance)
        @test isapprox(_jpg_loglik(fixture, shifted) - expected, nfields * delta / 2;
            atol = 1e-10, rtol = 1e-10)
        @test_throws ArgumentError _jpg_loglik(fixture,
            _jpg_precision(fixture; map = [3, 3]))
    end

    @testset "no ordinary sources reduces to the existing phylogenetic evaluator" begin
        residualized = fixture.response .- reshape(fixture.mean, size(fixture.response))
        joint = _jpg_loglik(fixture, phy; ordinary_incidences = SparseMatrixCSC{Float64,Int}[],
            ordinary_trait_variances = Vector{Float64}[])
        phylo = GLLVM.multivariate_phylo_precision_loglik(residualized', phy,
            fixture.loading, fixture.psi; phylo_unique_variance = fixture.phylo_unique_variance,
            species_id = fixture.species_id)
        @test isapprox(joint, phylo; atol = 1e-10, rtol = 1e-10)
    end

    @testset "two independent ordinary sources share one joint precision" begin
        second_incidence = sparse(collect(1:5), [1, 1, 2, 2, 1], ones(5), 5, 2)
        second_variance = [0.07, 0.05]
        two_source_covariance = fixture.covariance + Matrix(kron(
            Matrix(second_incidence * second_incidence'), Diagonal(second_variance)))
        expected_two_source = -destination_b_joint_phylo_grouping_dense_nll(
            fixture.vectorized_response, fixture.mean, two_source_covariance)
        got_two_source = _jpg_loglik(fixture, phy;
            ordinary_incidences = [fixture.crossed_incidence, second_incidence],
            ordinary_trait_variances = [fixture.grouped_variance, second_variance])
        @test isapprox(got_two_source, expected_two_source; atol = 1e-10, rtol = 1e-10)
    end

    @testset "zero U adds no field and ordinary effects share their crossed labels" begin
        zero_U = zeros(length(fixture.psi))
        zero_joint = _jpg_loglik(fixture, phy; ordinary_incidences = SparseMatrixCSC{Float64,Int}[],
            ordinary_trait_variances = Vector{Float64}[], phylo_unique_variance = zero_U)
        no_U = _jpg_loglik(fixture, phy; ordinary_incidences = SparseMatrixCSC{Float64,Int}[],
            ordinary_trait_variances = Vector{Float64}[], phylo_unique_variance = nothing)
        @test isapprox(zero_joint, no_U; atol = 1e-10, rtol = 1e-10)
        delta = 0.23
        shifted = _jpg_precision(fixture; log_det = phy.log_det + delta)
        zero_shifted = _jpg_loglik(fixture, shifted;
            ordinary_incidences = SparseMatrixCSC{Float64,Int}[],
            ordinary_trait_variances = Vector{Float64}[], phylo_unique_variance = zero_U)
        @test isapprox(zero_shifted - zero_joint, size(fixture.loading, 2) * delta / 2;
            atol = 1e-10, rtol = 1e-10)
        identity_incidence = sparse(collect(1:5), collect(1:5), ones(5), 5, 5)
        @test !isapprox(_jpg_loglik(fixture, phy; ordinary_incidences = [identity_incidence]),
            expected; atol = 1e-6, rtol = 1e-6)
    end

    @testset "partially active U indexes only its positive field" begin
        partial_U = [fixture.phylo_unique_variance[1], 0.0]
        phylo_trait_covariance = fixture.loading * fixture.loading' + Diagonal(partial_U)
        partial_covariance = Matrix(kron(fixture.selection *
            (fixture.Q \ fixture.selection'), phylo_trait_covariance) +
            fixture.grouped_covariance + fixture.residual_covariance)
        expected_partial = -destination_b_joint_phylo_grouping_dense_nll(
            fixture.vectorized_response, fixture.mean, partial_covariance)
        @test isapprox(_jpg_loglik(fixture, phy;
            phylo_unique_variance = partial_U), expected_partial; atol = 1e-10, rtol = 1e-10)
    end

    @testset "invalid residual and ordinary inputs fail closed" begin
        @test_throws ArgumentError _jpg_loglik(fixture, phy; psi = [fixture.psi[1], 0.0])
        @test_throws ArgumentError _jpg_loglik(fixture,
            _jpg_precision(fixture; map = [3, 5]))
        @test_throws ArgumentError _jpg_loglik(fixture, phy;
            ordinary_trait_variances = [[fixture.grouped_variance[1], 0.0]])
        @test_throws DimensionMismatch _jpg_loglik(fixture, phy;
            ordinary_incidences = [fixture.crossed_incidence[1:4, :]])
        @test_throws ArgumentError _jpg_loglik(fixture, phy;
            psi = BigFloat[BigFloat("1e-10000"), BigFloat(fixture.psi[2])])
        @test_throws ArgumentError _jpg_loglik(fixture, phy;
            ordinary_trait_variances = [[BigFloat("1e10000"), BigFloat(fixture.grouped_variance[2])]])
    end
end
