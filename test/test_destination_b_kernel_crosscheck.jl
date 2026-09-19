using Test, LinearAlgebra, SparseArrays, GLLVModels

isdefined(@__MODULE__, :destination_b_grouping_fixture) || include(joinpath(@__DIR__, "fixtures", "destination_b_reference.jl"))

function _db_crosscheck_incidence(labels)
    levels = unique(labels); level_of = Dict(level => k for (k, level) in enumerate(levels))
    sparse(collect(eachindex(labels)), [level_of[x] for x in labels], ones(Float64, length(labels)), length(labels), length(levels))
end

function _db_crosscheck_precision(f; q = inv(f.scale .* f.node_covariance),
                                  log_det = logdet(cholesky(Symmetric(Matrix(q)))),
                                  map = sort(unique(f.observation_nodes)))
    ii, jj, vv = findnz(sparse(q))
    GLLVModels.PrecisionPhy(ii, jj, vv, size(q, 1), length(map),
        ["augmented_node_$i" for i in axes(q, 1)], log_det, f.scale, map)
end

@testset "Destination B builder cross-check against independent model oracle" begin
    @testset "four joint grouped sources" begin
        f = destination_b_grouping_fixture(); c, labels = f.source_covariance, f.labels
        # Fixture and kernel both use traits × observations, so vec has trait-within-observation order.
        Y, beta = Float64.(f.response .- f.mean), zeros(2)
        incidences = [_db_crosscheck_incidence(labels.unit),
                      _db_crosscheck_incidence([(labels.unit[i], labels.observation[i]) for i in 1:8]),
                      _db_crosscheck_incidence(labels.crossed),
                      _db_crosscheck_incidence(labels.cluster2)]
        # cluster2 gets only natural diagonal trait variance through `uniques`.
        loadings = [Matrix(cholesky(Symmetric(c.unit)).L), Matrix(cholesky(Symmetric(c.nested)).L),
                    Matrix(cholesky(Symmetric(c.crossed)).L), zeros(2, 1)]
        nll = GLLVModels._grouped_gaussian_factor_nll(Y, beta, incidences, loadings,
            sqrt(c.residual[1]); uniques = [nothing, nothing, nothing, c.cluster2])
        @test isapprox(nll, f.exact_nll; atol = 1e-10, rtol = 1e-10)

        wrong_unit = copy(labels.unit); wrong_unit[3] = "g4"
        wrong_nll = GLLVModels._grouped_gaussian_factor_nll(Y, beta,
            [_db_crosscheck_incidence(wrong_unit), incidences[2], incidences[3], incidences[4]],
            loadings, sqrt(c.residual[1]); uniques = [nothing, nothing, nothing, c.cluster2])
        @test !isapprox(wrong_nll, f.exact_nll; atol = 1e-7, rtol = 1e-7)
    end

    @testset "retained unused ancestor precision consumer" begin
        f = destination_b_precision_fixture()
        y = Float64.(f.response .- f.mean)
        pp = _db_crosscheck_precision(f)
        @test pp.n_aug == 5 && pp.n_leaves == 4 && 5 ∉ f.observation_nodes
        got = GLLVModels.multivariate_phylo_precision_loglik(y, pp, f.trait_loadings,
            f.residual_sd .^ 2; sigma2_phy = 1.0, species_id = f.observation_nodes)
        @test isapprox(-got, f.exact_nll; atol = 1e-10, rtol = 1e-10)

        double_scaled = _db_crosscheck_precision(f; q = f.scale .* pp.Q)
        wrong_scale = GLLVModels.multivariate_phylo_precision_loglik(y, double_scaled, f.trait_loadings,
            f.residual_sd .^ 2; sigma2_phy = 1.0, species_id = f.observation_nodes)
        @test !isapprox(wrong_scale, got; atol = 1e-7, rtol = 1e-7)

        wrong_det = _db_crosscheck_precision(f; q = pp.Q, log_det = pp.log_det + log(1.7))
        @test !isapprox(GLLVModels.multivariate_phylo_precision_loglik(y, wrong_det, f.trait_loadings,
            f.residual_sd .^ 2; sigma2_phy = 1.0, species_id = f.observation_nodes), got;
            atol = 1e-7, rtol = 1e-7)

        # Nodes 1 and 2 are deliberately covariance-symmetric; swap node 1
        # with node 4 instead so this is an actually discriminating map control.
        swapped = _db_crosscheck_precision(f; q = pp.Q, map = [4, 2, 3, 1])
        @test !isapprox(GLLVModels.multivariate_phylo_precision_loglik(y, swapped, f.trait_loadings,
            f.residual_sd .^ 2; sigma2_phy = 1.0, species_id = f.observation_nodes), got;
            atol = 1e-7, rtol = 1e-7)
    end
end

println("destination-b-kernel-crosscheck-ok")
