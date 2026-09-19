using Test
using GLLVModels
using LinearAlgebra
using SparseArrays
using StableRNGs


# ADEMP smoke: one predeclared StableRNG draw from the joint covariance, with
# no recovery or coverage claim.  Y = D*beta + A_phy*f + W_group*b + e.
function _jpgf_fixture()
    rng = StableRNG(84031)
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
    unit = [1, 2, 1, 3, 2, 3, 1, 2, 3, 1, 3, 2]
    incidence = sparse(collect(1:n), unit, ones(n), n, 3)
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
    beta = [0.15, -0.20]
    response = reshape(D * beta + cholesky(Symmetric(covariance)).L * randn(rng, p * n), p, n)
    return (; phy, species_id, unit, incidence, loading, psi, grouped_variance,
        covariance, D, beta, response)
end

@testset "private joint phylo plus grouped Gaussian fit" begin
    fixture = _jpgf_fixture()
    terms = [GroupingTerm(:unit; mode = :indep, common = false)]
    fit = GLLVModels.fit_joint_phylo_grouped_gaussian(fixture.response, fixture.phy;
        rank = 1, phylo_mode = :barelowrank, terms = terms, unit = fixture.unit,
        species_id = fixture.species_id, iterations = 120, g_tol = 2e-4)
    @test fit.converged
    @test isfinite(fit.loglik)
    @test fit.stopping_reason === :converged
    @test length(fit.parameters) == 8
    @test length(fit.ordinary_covariances) == 1
    @test fit.phylo_covariance ≈ fit.loading * fit.loading'
    @test all(isfinite, fit.residual_variance)
    @test all(isfinite, diag(only(fit.ordinary_covariances)))

    objective = GLLVModels._joint_phylo_grouped_nll(fit.response, fit.phy, fit.terms,
        fit.incidences; rank = fit.rank, phylo_mode = fit.phylo_mode,
        species_id = fit.species_id, mean_design = fit.mean_design)
    @test isapprox(-objective(fit.parameters), fit.loglik; atol = 1e-8, rtol = 1e-8)
    alternate_unit = reverse(fixture.unit)
    alternate_incidence = GLLVModels._grouped_incidence(alternate_unit, length(alternate_unit))
    alternate_objective = GLLVModels._joint_phylo_grouped_nll(fit.response, fit.phy, fit.terms,
        [alternate_incidence]; rank = fit.rank, phylo_mode = fit.phylo_mode,
        species_id = fit.species_id, mean_design = fit.mean_design)
    @test !isapprox(objective(fit.parameters), alternate_objective(fit.parameters);
        atol = 1e-8, rtol = 1e-8)
    invalid_stencil_theta = fill(1e6, length(fit.parameters))
    @test GLLVModels._fd_failed(objective(invalid_stencil_theta))
    @test !all(isfinite, GLLVModels._fd_hessian(objective, invalid_stencil_theta))
    @test !GLLVModels._pmv_hessian_diagnostics(objective, invalid_stencil_theta).positive_definite

    interval = GLLVModels.joint_phylo_grouped_intervals(fit)
    @test interval.status in (:available, :partial, :not_stationary, :invalid_curvature)
    interval_names = String[row.name for row in interval.intervals]
    @test "beta[1]" in interval_names
    @test "phylo_cov[1,1]" in interval_names
    @test "residual_var[1]" in interval_names
    @test "unit_var[1]" in interval_names
    stalled = GLLVModels.fit_joint_phylo_grouped_gaussian(fixture.response, fixture.phy;
        rank = 1, phylo_mode = :barelowrank, terms = terms, unit = fixture.unit,
        species_id = fixture.species_id, iterations = 0, g_tol = 2e-4)
    @test !stalled.converged
    @test GLLVModels.joint_phylo_grouped_intervals(stalled).status === :not_converged
    @test_throws ArgumentError GLLVModels.fit_joint_phylo_grouped_gaussian(fixture.response,
        fixture.phy; rank = 1, phylo_mode = :barelowrank, terms = terms,
        unit = fixture.unit, species_id = fixture.species_id,
        X = zeros(size(fixture.response, 1) * size(fixture.response, 2), 1), iterations = 0)
    @test_throws ArgumentError GLLVModels.fit_joint_phylo_grouped_gaussian(fixture.response,
        fixture.phy; rank = 1, phylo_mode = :explicitunique, terms = terms,
        unit = fixture.unit, species_id = fixture.species_id, iterations = 0)

    source_fixture = _jpgf_fixture()
    source_terms = [GroupingTerm(:unit; mode = :indep, common = false)]
    source_fit = GLLVModels.fit_joint_phylo_grouped_gaussian(source_fixture.response,
        source_fixture.phy; rank = 1, phylo_mode = :barelowrank, terms = source_terms,
        unit = source_fixture.unit, species_id = source_fixture.species_id,
        iterations = 120, g_tol = 2e-4)
    source_objective = GLLVModels._joint_phylo_grouped_nll(source_fit.response, source_fit.phy,
        source_fit.terms, source_fit.incidences; rank = source_fit.rank,
        phylo_mode = source_fit.phylo_mode, species_id = source_fit.species_id,
        mean_design = source_fit.mean_design)
    baseline = source_objective(source_fit.parameters)
    source_fixture.phy.Q.nzval[1] *= 2.0
    source_fixture.species_id[1] = 2
    source_terms[1] = GroupingTerm(:cluster; mode = :indep, common = false)
    @test source_fit.phy.Q.nzval[1] != source_fixture.phy.Q.nzval[1]
    @test source_fit.species_id[1] != source_fixture.species_id[1]
    @test source_fit.terms[1].name === :unit
    @test isapprox(source_objective(source_fit.parameters), baseline; atol = 1e-10, rtol = 1e-10)
end
