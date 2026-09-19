using Test

if Base.find_package("StableRNGs") === nothing
    @testset "joint phylo grouped postfit (StableRNGs unavailable)" begin
        @test_skip false
    end
else
    using GLLVModels
    using LinearAlgebra
    using SparseArrays
    using StableRNGs

    function _jpgp_fixture()
        rng = StableRNG(84_121)
        qbase = [3.0 -0.8 -0.5 0.0;
                 -0.8 3.2 0.0 -0.6;
                 -0.5 0.0 2.7 0.0;
                 0.0 -0.6 0.0 2.9]
        Q = sparse(1.4 .* qbase)
        ii, jj, xx = findnz(Q)
        phy = PrecisionPhy(ii, jj, xx, 4, 2, ["a1", "a2", "tip1", "tip2"],
            logdet(cholesky(Symmetric(Matrix(Q)))), 1.4, [3, 4])
        species_id = repeat([1, 2], 6)
        n, p = length(species_id), 2
        cluster = [1, 2, 1, 3, 2, 3, 1, 2, 3, 1, 3, 2]
        incidence = GLLVModels._grouped_incidence(cluster, n)
        loading = reshape([0.55, 0.30], p, 1)
        psi = [0.35, 0.48]
        grouped_variance = [0.16, 0.11]
        selection = zeros(n, phy.n_aug)
        for i in 1:n
            selection[i, phy.species_aug_id[species_id[i]]] = 1.0
        end
        covariance = Matrix(kron(selection * (Matrix(phy.Q) \ selection'), loading * loading') +
            kron(Matrix(incidence * incidence'), Diagonal(grouped_variance)) +
            kron(Matrix(I, n, n), Diagonal(psi)))
        D = GLLVModels._trait_mean_design(p, n)
        beta = [0.10, -0.18]
        response = reshape(D * beta + cholesky(Symmetric(covariance)).L * randn(rng, p * n), p, n)
        return (; phy, species_id, cluster, response)
    end

    @testset "joint phylo grouped Gaussian postfit" begin
        fixture = _jpgp_fixture()
        terms = [GroupingTerm(:cluster; mode = :indep, common = false)]
        loose = GLLVModels.fit_joint_phylo_grouped_gaussian(fixture.response, fixture.phy;
            rank = 1, phylo_mode = :barelowrank, terms = terms,
            cluster = fixture.cluster, species_id = fixture.species_id,
            iterations = 160, g_tol = 2e-4)
        fit = GLLVModels.fit_joint_phylo_grouped_gaussian(fixture.response, fixture.phy;
            rank = 1, phylo_mode = :barelowrank, terms = terms,
            cluster = fixture.cluster, species_id = fixture.species_id,
            start = loose.parameters, iterations = 160, g_tol = 1e-5)
        @test fit.converged

        expected = reshape(fit.mean_design * fit.beta, fit.response_shape)
        @test GLLVModels.joint_phylo_grouped_population_predict(fit) ≈ expected
        @test GLLVModels.predict(fit) ≈ expected
        @test GLLVModels.fitted(fit) ≈ expected
        @test GLLVModels.residuals(fit) ≈ fit.response .- expected
        new_design = [1.0 0.0; 0.0 1.0; 2.0 0.0; 0.0 2.0]
        @test GLLVModels.predict(fit, new_design) ≈ reshape(new_design * fit.beta, 2, 2)
        @test_throws DimensionMismatch GLLVModels.predict(fit, ones(3, length(fit.beta)))
        @test_throws ArgumentError GLLVModels.predict(fit; type = :conditional)
        @test_throws ArgumentError GLLVModels.predict(fit; random_effects = :mode)

        phylo = GLLVModels.extract_Sigma(fit; level = :phylo, part = :total)
        ordinary = GLLVModels.extract_Sigma(fit; level = :cluster, part = :total)
        residual = GLLVModels.extract_Sigma(fit; level = :residual, part = :total)
        @test phylo.Sigma ≈ fit.phylo_covariance
        @test ordinary.Sigma ≈ only(fit.ordinary_covariances)
        @test residual.Sigma ≈ Diagonal(fit.residual_variance)
        @test phylo.source === :phylogenetic
        @test ordinary.source === :ordinary
        @test residual.source === :observation_residual
        @test_throws ArgumentError GLLVModels.extract_Sigma(fit; level = :not_a_source)

        covariance = GLLVModels.vcov(fit)
        @test size(covariance) == (length(fit.beta), length(fit.beta))
        @test covariance ≈ covariance'
        @test all(isfinite, covariance)
        @test GLLVModels.stderror(fit) ≈ sqrt.(diag(covariance))
        report = summary(fit, fit.response)
        @test report.inference_status === :available
        @test isfinite(report.inference_gradient_norm)
        @test report.gradient_norm == fit.gradient_norm
        @test all(row -> row.status === :available && isfinite(row.se), report.fixed_effects)
        @test_throws ArgumentError summary(fit, fit.response .+ 1.0)

        stalled = GLLVModels.fit_joint_phylo_grouped_gaussian(fixture.response, fixture.phy;
            rank = 1, phylo_mode = :barelowrank, terms = terms,
            cluster = fixture.cluster, species_id = fixture.species_id,
            iterations = 0, g_tol = 1e-5)
        @test !stalled.converged
        @test_throws ArgumentError GLLVModels.vcov(stalled)
        unavailable = summary(stalled, stalled.response)
        @test unavailable.inference_status === :not_converged
        @test all(row -> row.status === :not_converged && isnan(row.se), unavailable.fixed_effects)
    end
end
