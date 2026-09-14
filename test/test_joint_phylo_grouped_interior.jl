using Test

if Base.find_package("StableRNGs") === nothing
    @testset "joint phylo grouped interior (StableRNGs unavailable)" begin
        @test_skip false
    end
else
    using GLLVM
    using LinearAlgebra
    using SparseArrays
    using StableRNGs

    # ADEMP feasibility cell, R=1: vec(Y) ~ N(D*beta,
    # (S*Q^-1*S')⊗(L*L') + (Z*Z')⊗Diag(v) + I⊗Diag(psi)).
    const _JPG_INTERIOR_SEED = 84_064

    function _joint_phylo_grouped_interior_fixture()
        rng = StableRNG(_JPG_INTERIOR_SEED)
        p, n_tips, replication = 2, 64, 2
        phy = PrecisionPhy(random_balanced_tree(n_tips; branch_length = 0.8))
        species_id = repeat(collect(1:n_tips), inner = replication)
        n = length(species_id)
        cluster = [mod(7 * observation + 2 * ((observation - 1) ÷ replication), 17) + 1
                   for observation in 1:n]
        incidence = GLLVM._grouped_incidence(cluster, n)
        selection = sparse(collect(1:n), phy.species_aug_id[species_id], ones(n), n, phy.n_aug)
        beta = [0.20, -0.15]
        loading = reshape([0.50, 0.28], p, 1)
        psi = [0.32, 0.46]
        ordinary_variance = [0.14, 0.10]
        covariance = Matrix(kron(selection * (phy.Q \ Matrix(selection')),
            loading * loading') + kron(Matrix(incidence * incidence'),
            Diagonal(ordinary_variance)) + kron(Matrix(I, n, n), Diagonal(psi)))
        D = GLLVM._trait_mean_design(p, n)
        response = reshape(D * beta + cholesky(Symmetric(covariance)).L * randn(rng, p * n), p, n)
        return (; response, phy, species_id, cluster, incidence, beta, loading,
            psi, ordinary_variance, covariance)
    end

    function _joint_phylo_grouped_interval_available(interval, name)
        row = only(filter(item -> item.name == name, interval.intervals))
        return row.status === :available && isfinite(row.estimate) &&
            isfinite(row.lower) && isfinite(row.upper) &&
            row.lower < row.upper && row.lower <= row.estimate <= row.upper
    end

    @testset "joint phylo grouped interior feasibility" begin
        fixture = _joint_phylo_grouped_interior_fixture()
        terms = [GroupingTerm(:cluster; mode = :indep, common = false)]
        @test size(fixture.response) == (2, 128)
        @test fixture.phy.n_leaves == 64
        @test length(unique(fixture.cluster)) == 17
        @test all(isfinite, fixture.response)

        fit = GLLVM.fit_joint_phylo_grouped_gaussian(fixture.response, fixture.phy;
            rank = 1, phylo_mode = :barelowrank, terms = terms,
            cluster = fixture.cluster, species_id = fixture.species_id,
            iterations = 200, g_tol = 2e-4)
        @test fit.converged
        @test isfinite(fit.loglik)
        @test fit.hessian_positive_definite
        @test fit.gradient_norm <= 2e-4

        interval = GLLVM.joint_phylo_grouped_intervals(fit)
        @info "Joint phylo grouped interior interval receipt" fit_gradient_norm = fit.gradient_norm interval_status = interval.status interval_gradient_norm = interval.gradient_norm interval_condition_number = interval.condition_number
        # Retained original receipt at the intentionally loose fit tolerance.
        # It is a diagnostic, not a substitute for the refined availability gate.
        @test interval.status === :not_stationary
        @test interval.gradient_norm > 1e-4
        @test all(row -> row.status === :not_stationary && isnan(row.lower) && isnan(row.upper),
            interval.intervals)

        refined = fit_gllvm(fixture.response; phylo = fixture.phy,
            phylo_rank = 1, phylo_mode = :barelowrank, grouping = terms,
            cluster = fixture.cluster, species_id = fixture.species_id,
            start = fit.parameters, iterations = 200, g_tol = 1e-5)
        @test refined.converged
        @test refined.gradient_norm <= 1e-5
        refined_interval = GLLVM.joint_phylo_grouped_intervals(refined)
        @info "Joint phylo grouped refined interval receipt" gradient_norm = refined.gradient_norm interval_status = refined_interval.status interval_gradient_norm = refined_interval.gradient_norm interval_condition_number = refined_interval.condition_number
        @test refined_interval.status === :available
        @test _joint_phylo_grouped_interval_available(refined_interval, "beta[1]")
        @test _joint_phylo_grouped_interval_available(refined_interval, "phylo_cov[1,1]")
        @test _joint_phylo_grouped_interval_available(refined_interval, "residual_var[1]")
        @test _joint_phylo_grouped_interval_available(refined_interval, "cluster_var[1]")
    end
end
