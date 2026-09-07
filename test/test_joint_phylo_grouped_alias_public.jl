using Test
using GLLVM
using LinearAlgebra
using SparseArrays

function _jpg_alias_public_fixture()
    Q = sparse(Matrix{Float64}(I, 4, 4))
    phy = PrecisionPhy(findnz(Q)..., 4, 4, ["tip_$i" for i in 1:4],
        0.0, 1.0, collect(1:4))
    return (; Y=reshape([0.20, -0.15, 0.31, -0.24], 1, :), phy,
        species_id=collect(1:4), unit=collect(1:4),
        terms=[GroupingTerm(:unit; mode=:indep, common=false)])
end

function _jpg_alias_as_stationary(fit::GLLVM.JointPhyloGroupedGaussianFit)
    return GLLVM.JointPhyloGroupedGaussianFit(fit.beta, fit.loading,
        fit.phylo_unique_variance, fit.phylo_covariance, fit.residual_variance,
        fit.ordinary_covariances, fit.terms, fit.phy, fit.species_id,
        fit.parameters, fit.parameter_labels, fit.loglik, true, 0.0,
        fit.hessian_min_eigenvalue, fit.hessian_positive_definite,
        fit.hessian_condition_number, fit.iterations, fit.stopping_reason,
        fit.response, fit.mean_design, fit.response_shape, fit.coefficient_names,
        fit.incidences, fit.phylo_mode, fit.rank)
end

@testset "public joint phylo grouped covariance aliases" begin
    fixture = _jpg_alias_public_fixture()
    fit = fit_gllvm(fixture.Y; phylo=fixture.phy, phylo_rank=1,
        phylo_mode=:barelowrank, species_id=fixture.species_id,
        grouping=fixture.terms, unit=fixture.unit, iterations=0, g_tol=1e-4)
    @test fit isa GLLVM.JointPhyloGroupedGaussianFit
    @test isfinite(fit.loglik)
    diagnostic = GLLVM._joint_covariance_identification(fit.phy, fit.species_id,
        fit.terms, fit.incidences, fit.loading;
        phylo_unique_variance=fit.phylo_unique_variance)
    @test diagnostic.reason === :nonidentifiable
    @test any(alias -> alias.kind === :phylo_vs_ordinary, diagnostic.aliases)
    @test any(alias -> alias.kind === :ordinary_vs_residual, diagnostic.aliases)

    # The point is deliberately zero-iteration, but the exact algebraic alias
    # must take priority over ordinary stationarity/curvature inference gates.
    stationary = _jpg_alias_as_stationary(fit)
    @test GLLVM.joint_phylo_grouped_intervals(fit).status === :nonidentifiable
    @test summary(fit, fixture.Y).inference_status === :nonidentifiable
    intervals = GLLVM.joint_phylo_grouped_intervals(stationary)
    @test intervals.status === :nonidentifiable
    @test all(row -> row.status === :nonidentifiable, intervals.intervals)
    @test_throws ArgumentError GLLVM.joint_phylo_grouped_intervals(stationary; level=1.0)
    @test_throws ArgumentError GLLVM.joint_phylo_grouped_intervals(stationary;
        gradient_tolerance=0.0)
    covariance_error = @test_throws ArgumentError GLLVM.StatsAPI.vcov(stationary)
    @test occursin("nonidentifiable", covariance_error.value.msg)
    report = summary(stationary, fixture.Y)
    @test report.inference_status === :nonidentifiable
    @test all(row -> row.status === :nonidentifiable, report.fixed_effects)
end
