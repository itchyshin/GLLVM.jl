using Test, GLLVModels, LinearAlgebra, Random

@testset "private Gaussian named grouping fitter" begin
    @test GLLVModels._grouped_stopping_reason(true,true,10,10,0.0,1e-5) == :converged
    @test GLLVModels._grouped_stopping_reason(false,true,2,10,0.0,1e-5) == :optimizer_not_converged
    @test GLLVModels._grouped_stopping_reason(false,true,2,10,0.1,1e-5) == :gradient_not_converged
    @test isdefined(GLLVModels, :GroupingTerm)
    @test isdefined(GLLVModels, :fit_grouped_gaussian)
    @test isdefined(GLLVModels, :grouped_gaussian_intervals)
    if isdefined(GLLVModels, :GroupingTerm) && isdefined(GLLVModels, :fit_grouped_gaussian) &&
            isdefined(GLLVModels, :grouped_gaussian_intervals)
        term = GLLVModels.GroupingTerm
        fitfun = GLLVModels.fit_grouped_gaussian
        Y = [0.2 -0.4 0.8 0.1 0.5 -0.2;
             1.1  0.3 -0.2 0.5 0.4  0.7]
        unit = [:a, :a, :b, :b, :c, :c]
        unit_obs = [:a1, :a2, :b1, :b2, :c1, :c2]
        cluster = [:x, :y, :x, :y, :x, :y]
        cluster2 = [:m, :n, :m, :n, :m, :n]

        @test_throws ArgumentError term(:unknown)
        @test_throws ArgumentError term(:cluster2; mode = :latent)
        @test_throws ArgumentError fitfun(Y; terms = GLLVModels.GroupingTerm[], unit = unit)
        @test_throws ArgumentError fitfun(Y; terms = [term(:unit; mode = :indep)], unit = unit,
                                          cluster = cluster)
        @test_throws ArgumentError fitfun(Y; terms = [term(:unit_obs; mode = :indep)],
                                          unit = unit, unit_obs = [:a1, :b1, :b1, :b2, :c1, :c2])

        theta_hessian = [0.3, -0.7]
        base_objective = theta -> sum(abs2, theta)
        failed_neighbours = theta -> all(iszero, theta) ? 0.0 : GLLVModels._NLL_SENTINEL
        @test all(isnan, GLLVModels._grouped_fd_gradient(failed_neighbours, zeros(2)))
        @test all(isnan, GLLVModels._grouped_fd_hessian(failed_neighbours, zeros(2)))
        @test GLLVModels._grouped_fd_hessian(base_objective, theta_hessian; step = 1e-2) ≈
              GLLVModels._grouped_fd_hessian(theta -> base_objective(theta) + 100.0, theta_hessian;
                                         step = 1e-2) atol = 1e-8
        @test GLLVModels._grouped_fd_hessian(base_objective, theta_hessian; step = 1e-2) ≈ 2.0I atol = 1e-8

        terms = [term(:unit; mode = :latent, rank = 1, unique = true),
                 term(:unit_obs; mode = :indep, common = true),
                 term(:cluster; mode = :dep),
                 term(:cluster2; mode = :indep)]
        fit = fitfun(Y; terms = terms, unit = unit, unit_obs = unit_obs,
                     cluster = cluster, cluster2 = cluster2, iterations = 2)
        @test fit.terms == terms
        @test length(fit.term_covariances) == 4
        @test all(B -> size(B) == (2, 2) && all(isfinite, B), fit.term_covariances)
        @test length(fit.beta) == 2 && size(fit.mean_design) == (12, 2)
        @test length(fit.parameter_labels) == length(fit.parameters)
        @test last(fit.parameter_labels) == "log_sigma_eps"
        @test isfinite(fit.loglik) || fit.loglik == -Inf
        @test fit.stopping_reason in (:converged, :invalid_hessian, :gradient_not_converged,
                                      :iteration_limit, :invalid_final)

        # Sharing label values across independently selected sources is allowed:
        # cluster is crossed/nested by design, not constrained like unit_obs.
        shared = fitfun(Y; terms = [term(:unit; mode = :indep), term(:cluster; mode = :indep)],
                        unit = unit, cluster = unit, iterations = 1)
        @test length(shared.term_covariances) == 2

        # Fixed-seed, replicated interior model: one group variance plus
        # residual variance, with enough groups/replicates for local curvature.
        rng = MersenneTwister(20260907)
        groups = repeat(1:12; inner = 5)
        random_intercept = 0.65 .* randn(rng, 12)
        Yi = reshape([1.1 + random_intercept[g] + 0.35 * randn(rng)
                      for g in groups], 1, :)
        interior = fitfun(Yi; terms = [term(:unit; mode = :indep, common = true)],
                          unit = groups, iterations = 100)
        @test interior.converged && interior.hessian_positive_definite
        ci = GLLVModels.grouped_gaussian_intervals(Yi, interior; unit = groups)
        @test ci.status == :available
        @test all(x -> x.status == :available && x.lower < x.estimate < x.upper,
                  ci.intervals)
        altered_Yi = copy(Yi); altered_Yi[1] += 0.01
        @test_throws ArgumentError GLLVModels.grouped_gaussian_intervals(altered_Yi, interior;
                                                                     unit = groups)
        altered_groups = copy(groups); altered_groups[1] = maximum(groups) + 1
        @test_throws ArgumentError GLLVModels.grouped_gaussian_intervals(Yi, interior;
                                                                     unit = altered_groups)

        # Fixed-seed p=2 replicated interior fixtures.  Independent terms
        # have a structural zero trait covariance, which must not be offered
        # as an estimated interval; a bare rank-one factor does estimate its
        # off-diagonal covariance.
        multi_rng = MersenneTwister(992)
        multi_groups = repeat(1:16; inner = 6)
        independent_1 = 0.70 .* randn(multi_rng, 16)
        independent_2 = 0.45 .* randn(multi_rng, 16)
        Yindependent = vcat(
            reshape([1.0 + independent_1[g] + 0.32 * randn(multi_rng)
                     for g in multi_groups], 1, :),
            reshape([-0.4 + independent_2[g] + 0.32 * randn(multi_rng)
                     for g in multi_groups], 1, :))
        independent_fit = fitfun(Yindependent;
            terms = [term(:unit; mode = :indep)], unit = multi_groups, iterations = 100)
        @test independent_fit.converged && independent_fit.hessian_positive_definite
        independent_ci = GLLVModels.grouped_gaussian_intervals(Yindependent, independent_fit;
                                                           unit = multi_groups)
        @test independent_ci.status == :available
        @test !any(x -> occursin("covariance", String(x.name)), independent_ci.intervals)
        @test all(x -> x.status == :available && x.lower < x.estimate < x.upper,
                  independent_ci.intervals)

        latent_loading = [0.60, 0.38]
        latent_effect = randn(multi_rng, 16)
        Ylatent = vcat(
            reshape([0.8 + latent_loading[1] * latent_effect[g] + 0.25 * randn(multi_rng)
                     for g in multi_groups], 1, :),
            reshape([-0.3 + latent_loading[2] * latent_effect[g] + 0.25 * randn(multi_rng)
                     for g in multi_groups], 1, :))
        latent_fit = fitfun(Ylatent;
            terms = [term(:unit; mode = :latent, rank = 1)], unit = multi_groups,
            iterations = 100)
        @test latent_fit.converged && latent_fit.hessian_positive_definite
        latent_ci = GLLVModels.grouped_gaussian_intervals(Ylatent, latent_fit; unit = multi_groups)
        @test latent_ci.status == :available
        @test any(x -> x.name == "unit.covariance[1,2]" && x.status == :available,
                  latent_ci.intervals)
        @test all(x -> x.status == :available && x.lower < x.estimate < x.upper,
                  latent_ci.intervals)

        # Identical independently selected incidences confound two variance
        # components. The adapter must report no manufactured interval.
        singular = fitfun(Yi; terms = [term(:unit; mode = :indep, common = true),
                                       term(:cluster; mode = :indep, common = true)],
                         unit = groups, cluster = groups, iterations = 30)
        unavailable = GLLVModels.grouped_gaussian_intervals(Yi, singular;
                                                        unit = groups, cluster = groups)
        @test unavailable.status != :available
        @test any(x -> x.method == :unavailable, unavailable.intervals)
    end
end
