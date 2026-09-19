using Test, GLLVModels, Random

# Private interval wrapper, not exported and not a public inference claim:
#
# _grouped_gaussian_variance_profile(fit, Y; selected=(1,1), level=.95,
#     iterations=100, gradient_tolerance=1e-5, max_expand=8, maxiter=24)
#   -> (; status, lower, upper, cutoff, baseline_nll, center, receipts)

function _profile_interval_fixture()
    # Predeclared one-cell Gaussian optimizer check; no recovery/coverage claim.
    rng = MersenneTwister(20_260_907)
    group = repeat(1:12; inner=5)
    random_intercept = 0.65 .* randn(rng, 12)
    Y = reshape([1.1 + random_intercept[level] + 0.35 * randn(rng)
                 for level in group], 1, :)
    return (; Y, group, terms=[GroupingTerm(:unit; mode=:indep, common=false)])
end

@testset "private grouped Gaussian variance profile wrapper" begin
    fixture = _profile_interval_fixture()
    fit = GLLVModels.fit_grouped_gaussian(fixture.Y; terms=fixture.terms,
        unit=fixture.group, iterations=100, g_tol=1e-5)
    @test fit.converged && fit.gradient_norm <= 1e-5

    profile = GLLVModels._grouped_gaussian_variance_profile(fit, fixture.Y;
        selected=(1, 1), iterations=100, gradient_tolerance=1e-5,
        max_expand=8, maxiter=24)
    @test profile.status === :available
    @test profile.lower.status in (:root_verified, :boundary_inside, :boundary_crossing)
    @test profile.upper.status === :root_verified
    @test 0.0 <= profile.lower.endpoint < profile.center.fixed_variance < profile.upper.endpoint
    @test isfinite(profile.baseline_nll) && isfinite(profile.cutoff)
    @test all(point -> hasproperty(point, :refit_receipt) &&
        point.refit_receipt isa NamedTuple, profile.receipts)
    @test any(point -> point.fixed_variance == 0.0, profile.lower.points)
    zero_point = only(filter(point -> point.fixed_variance == 0.0, profile.lower.points))
    @test ismissing(zero_point.refit_receipt.selected_coordinate)
    @test profile.lower.endpoint_check.refit_receipt.accepted
    @test profile.upper.endpoint_check.refit_receipt.accepted
    @test all(attempt -> hasproperty(attempt, :gradient) && hasproperty(attempt, :start),
        profile.lower.endpoint_check.refit_receipt.attempts)
    @test all(attempt -> hasproperty(attempt, :gradient) && hasproperty(attempt, :start),
        profile.upper.endpoint_check.refit_receipt.attempts)
    @test all(point -> point.refit_receipt.provenance.response == fit.response,
        profile.receipts)

    # No profile endpoint is manufactured when constrained refits have no
    # optimizer iterations; failed receipts are explicit diagnostics.
    stalled = GLLVModels._grouped_gaussian_variance_profile(fit, fixture.Y;
        selected=(1, 1), iterations=0, gradient_tolerance=1e-5,
        max_expand=4, maxiter=8)
    @test stalled.status === :unavailable
    @test isnan(stalled.lower.endpoint) && isnan(stalled.upper.endpoint)
    @test stalled.reason in (:invalid_refit, :baseline_not_maximized)
    @test any(!point.refit_accepted for point in stalled.receipts)

    @test_throws ArgumentError GLLVModels._grouped_gaussian_variance_profile(
        fit, fixture.Y; selected=(2, 1))
    unconverged = GLLVModels.fit_grouped_gaussian(fixture.Y; terms=fixture.terms,
        unit=fixture.group, iterations=0, g_tol=1e-5)
    @test !unconverged.converged
    @test_throws ArgumentError GLLVModels._grouped_gaussian_variance_profile(
        unconverged, fixture.Y; selected=(1, 1))
end
