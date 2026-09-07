using Test, GLLVM, Random

# Private refit interface, intentionally separate from any LR/root layer:
#
# _grouped_profile_refitter(fit::GroupedGaussianFit, Y;
#     selected=(source_index, trait_index), iterations=100,
#     gradient_tolerance=1e-5)
#   -> (; refit, vhat, selected_full_index, selected_label, full_gradient,
#       provenance)
#
# `refit(v, stage::Symbol)` returns
# `(; accepted, objective_nll, status, provenance, attempts, reduced_minimizer,
#    evaluator_vector, selected_coordinate)`.

function _profile_refit_fixture()
    # Predeclared, one-cell Gaussian optimizer check—not recovery evidence.
    rng = MersenneTwister(20_260_907)
    group = repeat(1:12; inner=5)
    random_intercept = 0.65 .* randn(rng, 12)
    Y = reshape([1.1 + random_intercept[level] + 0.35 * randn(rng)
                 for level in group], 1, :)
    terms = [GroupingTerm(:unit; mode=:indep, common=false)]
    return (; Y, group, terms)
end

function _unconverged_copy(fit::GroupedGaussianFit)
    return GroupedGaussianFit(fit.beta, fit.sigma_eps, fit.term_covariances,
        fit.terms, fit.parameters, fit.loglik, false, fit.gradient_norm,
        fit.hessian_min_eigenvalue, fit.hessian_positive_definite,
        fit.iterations, :iteration_limit, fit.mean_design, fit.coefficient_names,
        fit.parameter_labels, fit.response_shape, fit.response, fit.incidences)
end

function _wrong_loglik_copy(fit::GroupedGaussianFit)
    return GroupedGaussianFit(fit.beta, fit.sigma_eps, fit.term_covariances,
        fit.terms, fit.parameters, fit.loglik + 0.1, fit.converged, fit.gradient_norm,
        fit.hessian_min_eigenvalue, fit.hessian_positive_definite,
        fit.iterations, fit.stopping_reason, fit.mean_design, fit.coefficient_names,
        fit.parameter_labels, fit.response_shape, fit.response, fit.incidences)
end

@testset "private grouped Gaussian profile nuisance refits" begin
    fixture = _profile_refit_fixture()
    fit = GLLVM.fit_grouped_gaussian(fixture.Y; terms=fixture.terms,
        unit=fixture.group, iterations=100, g_tol=1e-5)
    @test fit.converged
    @test fit.gradient_norm <= 1e-5

    refitter = GLLVM._grouped_profile_refitter(fit, fixture.Y;
        selected=(1, 1), iterations=100, gradient_tolerance=1e-5)
    @test refitter isa NamedTuple && refitter.refit isa Function
    @test refitter.selected_label == "unit.log_sd[1]"
    @test refitter.vhat ≈ fit.term_covariances[1][1, 1] atol=1e-12
    @test refitter.baseline_nll ≈ -fit.loglik atol=1e-12
    @test refitter.full_gradient.maximum <= 1e-5
    @test refitter.provenance.response == fit.response
    @test refitter.provenance.incidences == fit.incidences
    baseline = refitter.refit(refitter.vhat, :baseline)
    @test baseline.accepted
    @test baseline.provenance.stage === :baseline && baseline.provenance.side === :center
    @test baseline.provenance.response == refitter.provenance.response
    @test baseline.provenance.mean_design == refitter.provenance.mean_design
    @test baseline.provenance.incidences == refitter.provenance.incidences
    @test baseline.objective_nll <= refitter.baseline_nll + 1e-10

    # First point records unavailable same-side warm start, then deterministic
    # full-projection and cold starts. Its accepted fit must refit nuisance
    # coordinates rather than reusing the projected unconstrained solution.
    constrained_v = 1.35 * refitter.vhat
    first = refitter.refit(constrained_v, :upper_probe)
    @test first.provenance.stage === :upper_probe
    @test first.provenance.fixed_variance == constrained_v
    @test first.provenance.side === :upper
    @test length(first.attempts) == 3
    @test first.attempts[1].kind === :warm && !first.attempts[1].attempted
    @test first.attempts[1].status === :warm_unavailable
    @test first.accepted
    @test isfinite(first.objective_nll)
    @test first.selected_coordinate ≈ log(constrained_v) / 2 atol=1e-12
    @test first.fixed_variance == constrained_v
    @test first.selected_attempt_kind in (:projection, :cold, :warm)
    @test first.evaluator_placeholder == first.evaluator_vector[first.selected_full_index]
    @test all(isfinite, first.reduced_minimizer)
    @test any(attempt -> attempt.accepted, first.attempts)
    @test maximum(abs.(first.reduced_minimizer .- refitter.full_projection)) > 1e-7

    # A later point on the same side attempts the retained warm start first.
    second = refitter.refit(1.55 * refitter.vhat, :upper_probe)
    @test second.attempts[1].kind === :warm && second.attempts[1].attempted
    @test second.accepted

    # Exact zero uses the dedicated overlay and never fabricates a selected
    # log-SD coordinate, while retaining a separately named evaluator vector.
    zero = refitter.refit(0.0, :lower_boundary)
    @test zero.provenance.fixed_variance == 0.0
    @test zero.accepted && isfinite(zero.objective_nll)
    @test ismissing(zero.selected_coordinate)
    @test zero.evaluator_vector === nothing || all(isfinite, zero.evaluator_vector)
    @test all(attempt -> attempt.selected_coordinate === missing, zero.attempts)

    zero_budget = GLLVM._grouped_profile_refitter(fit, fixture.Y;
        selected=(1, 1), iterations=0, gradient_tolerance=1e-5).refit(0.0, :lower_boundary)
    @test !zero_budget.accepted
    @test zero_budget.status === :no_accepted_attempt
    @test all(attempt -> !attempt.accepted, zero_budget.attempts)
    @test all(attempt -> attempt.status in (:warm_unavailable, :iteration_limit),
        zero_budget.attempts)

    @test_throws ArgumentError GLLVM._grouped_profile_refitter(
        _unconverged_copy(fit), fixture.Y; selected=(1, 1))
    @test_throws ArgumentError GLLVM._grouped_profile_refitter(
        _wrong_loglik_copy(fit), fixture.Y; selected=(1, 1))
    @test_throws ArgumentError GLLVM._grouped_profile_refitter(
        fit, fixture.Y; selected=(1, 1), gradient_tolerance=2e-5)
    @test_throws ArgumentError refitter.refit(BigFloat("1e-10000"), :underflow)
    changed = copy(fixture.Y); changed[1] += 0.01
    @test_throws ArgumentError GLLVM._grouped_profile_refitter(
        fit, changed; selected=(1, 1))
end
