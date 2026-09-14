using Test

# StableRNGs is a direct dependency of the isolated numerical-quality test
# environment, not of GLLVM's lean core project. A bare-core skip is visible
# and never counts as evidence that this fitted identification gate passed.
if Base.find_package("StableRNGs") === nothing
    @testset "Destination B joint identification (StableRNGs unavailable)" begin
        @test_skip false
    end
else
    using GLLVM
    using LinearAlgebra
    using Random
    using StableRNGs

# ADEMP (one fixed smoke cell): A = joint four-term identifiability; D = the
# symbolic model documented in destination-b-joint-identification.md; E = four
# fitted trait covariances and interval feasibility; M = public fit_gllvm;
# P = convergence, curvature, non-boundary fitted components, and usable CIs.
# This is not a recovery or coverage campaign (R = 1; StableRNG seed 20260907).
const _DESTINATION_B_IDENTIFICATION_SEED = 20_260_907

function _destination_b_joint_identification_fixture()
    rng = StableRNG(_DESTINATION_B_IDENTIFICATION_SEED)
    p = 2
    unit = repeat(collect(1:6), inner = 6)
    unit_obs = repeat(collect(1:12), inner = 3)
    cluster = repeat(collect(1:4), 9)
    cluster2 = repeat([1, 1, 2, 2, 3, 3], 6)
    n = length(unit)

    Sigma_unit = [0.85 0.30; 0.30 0.65]
    Sigma_unit_obs = [0.45 0.15; 0.15 0.35]
    Sigma_cluster = [0.70 -0.25; -0.25 0.50]
    Sigma_cluster2 = Diagonal([0.25, 0.18])
    mu = [0.40, -0.20]

    draw(Sigma, nlevels) = cholesky(Symmetric(Matrix(Sigma))).L * randn(rng, p, nlevels)
    U = draw(Sigma_unit, 6)
    O = draw(Sigma_unit_obs, 12)
    C = draw(Sigma_cluster, 4)
    D = draw(Sigma_cluster2, 3)
    epsilon = 0.35 .* randn(rng, p, n)
    Y = hcat((mu .+ U[:, unit[i]] .+ O[:, unit_obs[i]] .+
              C[:, cluster[i]] .+ D[:, cluster2[i]] .+ epsilon[:, i] for i in 1:n)...)

    terms = [
        GroupingTerm(:unit; mode = :latent, rank = 1, unique = true),
        GroupingTerm(:unit_obs; mode = :latent, rank = 1, unique = true),
        GroupingTerm(:cluster; mode = :dep),
        GroupingTerm(:cluster2; mode = :indep),
    ]
    return (; Y, terms, unit, unit_obs, cluster, cluster2,
        truth = (; unit = Sigma_unit, unit_obs = Sigma_unit_obs,
            cluster = Sigma_cluster, cluster2 = Matrix(Sigma_cluster2)))
end

@testset "Destination B joint four-term Gaussian identification" begin
    fixture = _destination_b_joint_identification_fixture()
    @test size(fixture.Y) == (2, 36)
    @test all(isfinite, fixture.Y)
    @test GLLVM._grouping_term_nparams(fixture.terms[1], 2) == 4
    @test GLLVM._grouping_term_nparams(fixture.terms[2], 2) == 4
    @test all(fixture.unit_obs[3j - 2:3j] == fill(j, 3) for j in 1:12)
    @test length(unique(fixture.cluster)) == 4
    @test length(unique(fixture.cluster2)) == 3

    # Immutable first receipt: a deliberately modest iteration budget that
    # exposed budget exhaustion. Keep its nonconvergence diagnostic visible.
    budget_fit = fit_gllvm(fixture.Y; family = GLLVM.Normal(), grouping = fixture.terms,
        unit = fixture.unit, unit_obs = fixture.unit_obs,
        cluster = fixture.cluster, cluster2 = fixture.cluster2,
        iterations = 100, g_tol = 1e-5)

    @test !budget_fit.converged
    @test budget_fit.stopping_reason === :iteration_limit
    @test isfinite(budget_fit.gradient_norm)
    @test budget_fit.gradient_norm > 1e-5
    # The finite-difference curvature has a near-null direction from a
    # four-coordinate covariance parameterization of a three-coordinate
    # symmetric covariance.  Its computed sign is not portable.
    @test budget_fit.hessian_positive_definite isa Bool

    budget_objective = GLLVM._grouped_gaussian_objective(
        budget_fit.response, budget_fit.mean_design, budget_fit.terms, budget_fit.incidences)
    budget_hessian = GLLVM._grouped_fd_hessian(budget_objective, budget_fit.parameters)
    budget_spectrum = eigen(Symmetric(budget_hessian))
    budget_minimum = argmin(budget_spectrum.values)
    dominant_coordinate = argmax(abs.(budget_spectrum.vectors[:, budget_minimum]))
    @info "Destination B four-term 100-iteration diagnostic" gradient_norm = budget_fit.gradient_norm smallest_hessian_eigenvalue = budget_spectrum.values[budget_minimum] dominant_eigenvector_coordinate = budget_fit.parameter_labels[dominant_coordinate] dominant_eigenvector_loading = budget_spectrum.vectors[dominant_coordinate, budget_minimum] fitted_variances = [diag(Sigma) for Sigma in budget_fit.term_covariances]
    @test isfinite(budget_spectrum.values[budget_minimum])
    @test all(isfinite, budget_spectrum.vectors[:, budget_minimum])

    # Predeclared repair diagnostic: same DGP and default start, only a larger
    # optimiser budget, to separate budget exhaustion from identification.
    fit = fit_gllvm(fixture.Y; family = GLLVM.Normal(), grouping = fixture.terms,
        unit = fixture.unit, unit_obs = fixture.unit_obs,
        cluster = fixture.cluster, cluster2 = fixture.cluster2,
        iterations = 400, g_tol = 1e-5)

    @test fit isa GroupedGaussianFit
    @test fit.converged
    @test isfinite(fit.loglik)
    @test isfinite(fit.gradient_norm)
    @test fit.gradient_norm <= 1e-5
    @test fit.hessian_positive_definite isa Bool
    @test fit.stopping_reason === :converged
    @test getfield.(fit.terms, :name) == [:unit, :unit_obs, :cluster, :cluster2]

    fitted_covariances = [GLLVM.extract_Sigma(fit; level = term.name).Sigma for term in fit.terms]
    fitted_unit_obs_unique2 = GLLVM.extract_Sigma(fit; level = :unit_obs, part = :unique).s[2]
    @info "Destination B rank-one-plus-unique identification diagnostic" fitted_unit_obs_unique_variance2 = fitted_unit_obs_unique2 simulated_unit_obs_total_variance2 = fixture.truth.unit_obs[2, 2] simulated_unit_obs_unique_variance2 = :not_defined
    @test fitted_covariances == fit.term_covariances
    @test all(Sigma -> all(isfinite, Sigma) && all(diag(Sigma) .> 0.01), fitted_covariances)
    @test fitted_covariances[4] ≈ Diagonal(diag(fitted_covariances[4])) atol = 1e-12
    @test all(norm(fitted_covariances[i] - fitted_covariances[j]) > 1e-4
        for i in 1:3 for j in (i + 1):4)

    intervals = grouped_gaussian_intervals(fixture.Y, fit;
        unit = fixture.unit, unit_obs = fixture.unit_obs,
        cluster = fixture.cluster, cluster2 = fixture.cluster2)
    # This is a separately retained interval failure, not an interval pass.
    # The fit-time and interval finite-difference stencils can assign opposite
    # signs to the same near-null redundant direction; neither sign is an
    # identification criterion.
    interval_objective = GLLVM._grouped_gaussian_objective(
        fit.response, fit.mean_design, fit.terms, fit.incidences)
    interval_hessian = GLLVM._fd_hessian(interval_objective, fit.parameters)
    interval_spectrum = eigen(Symmetric(interval_hessian))
    interval_minimum = argmin(interval_spectrum.values)
    interval_coordinate = argmax(abs.(interval_spectrum.vectors[:, interval_minimum]))
    @info "Destination B four-term interval-curvature diagnostic" smallest_hessian_eigenvalue = interval_spectrum.values[interval_minimum] dominant_eigenvector_coordinate = fit.parameter_labels[interval_coordinate] dominant_eigenvector_loading = interval_spectrum.vectors[interval_coordinate, interval_minimum]
    @test intervals.status === :nonidentifiable
    @test intervals.covariance === nothing
    @test isfinite(interval_spectrum.values[interval_minimum])
    for name in ("unit.variance[1]", "unit_obs.variance[1]",
                 "cluster.variance[1]", "cluster2.variance[1]")
        interval = only(filter(x -> x.name == name, intervals.intervals))
        @test interval.status === :nonidentifiable
        @test isnan(interval.lower) && isnan(interval.upper)
    end

    # Separately predeclared identifiable total-covariance diagnostic: preserve
    # the realized data and all fitter controls, replacing only the redundant
    # p=2 rank-one-plus-unique layouts with full three-coordinate covariances.
    dep_terms = [
        GroupingTerm(:unit; mode = :dep),
        GroupingTerm(:unit_obs; mode = :dep),
        GroupingTerm(:cluster; mode = :dep),
        GroupingTerm(:cluster2; mode = :indep),
    ]
    @test GLLVM._grouping_term_nparams(dep_terms[1], 2) == 3
    @test GLLVM._grouping_term_nparams(dep_terms[2], 2) == 3
    dep_fit = fit_gllvm(fixture.Y; family = GLLVM.Normal(), grouping = dep_terms,
        unit = fixture.unit, unit_obs = fixture.unit_obs,
        cluster = fixture.cluster, cluster2 = fixture.cluster2,
        iterations = 400, g_tol = 1e-5)
    @test dep_fit.converged
    @test dep_fit.hessian_positive_definite
    @test dep_fit.gradient_norm <= 1e-5
    @test abs(dep_fit.loglik - fit.loglik) <= 1e-3
    @info "Destination B identifiable total-covariance diagnostic" rank_one_plus_unique_loglik = fit.loglik dep_loglik = dep_fit.loglik absolute_loglik_difference = abs(dep_fit.loglik - fit.loglik)
    dep_covariances = [GLLVM.extract_Sigma(dep_fit; level = term.name).Sigma for term in dep_fit.terms]
    @test all(Sigma -> all(isfinite, Sigma) && all(diag(Sigma) .> 0.01), dep_covariances)
    @test dep_covariances[4] ≈ Diagonal(diag(dep_covariances[4])) atol = 1e-12

    dep_intervals = grouped_gaussian_intervals(fixture.Y, dep_fit;
        unit = fixture.unit, unit_obs = fixture.unit_obs,
        cluster = fixture.cluster, cluster2 = fixture.cluster2)
    @test dep_intervals.status === :available
    @test dep_intervals.covariance !== nothing
    for name in ("unit.variance[1]", "unit_obs.variance[1]",
                 "cluster.variance[1]", "cluster2.variance[1]")
        interval = only(filter(x -> x.name == name, dep_intervals.intervals))
        @test interval.status === :available
        @test isfinite(interval.lower) && isfinite(interval.upper)
        @test interval.lower < interval.upper
        @test interval.lower <= interval.estimate <= interval.upper
    end
end

end # StableRNGs available
