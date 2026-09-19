using GLLVModels, Test, LinearAlgebra, Optim, Random

# Independent dense oracle for the first scalar grouped-variance profile.
# It never calls a production likelihood or nuisance refitter: at fixed v it
# builds V = v*Z*Z' + sigma_eps^2*I and analytically profiles the intercept,
# then uses a scalar dense optimisation only for sigma_eps^2.

function _gpdo_fixture()
    rng = MersenneTwister(20_260_907)
    group = repeat(1:12; inner=5)
    intercept = 0.65 .* randn(rng, 12)
    Y = reshape([1.1 + intercept[level] + 0.35 * randn(rng)
                 for level in group], 1, :)
    Z = zeros(Float64, length(group), 12)
    for observation in eachindex(group)
        Z[observation, group[observation]] = 1.0
    end
    return (; Y, y=vec(Y), group, Z,
        terms=[GroupingTerm(:unit; mode=:indep, common=false)])
end

function _gpdo_dense_fixed_variance(y::AbstractVector, Z::AbstractMatrix,
        group_variance::Real)
    v = Float64(group_variance)
    isfinite(v) && v >= 0 || throw(ArgumentError("group variance must be finite and nonnegative"))
    response = Float64.(y)
    n = length(response)
    ones_n = ones(Float64, n)
    ZZt = Matrix{Float64}(Z * Z')
    function profiled_nll(log_sigma_eps::Real)
        sigma2 = exp(2 * Float64(log_sigma_eps))
        covariance = v .* ZZt .+ sigma2 .* Matrix(I, n, n)
        factor = cholesky(Symmetric(covariance))
        vinv_one = factor \ ones_n
        vinv_y = factor \ response
        mean = dot(ones_n, vinv_y) / dot(ones_n, vinv_one)
        residual = response .- mean
        return 0.5 * (n * log(2pi) + 2sum(log, diag(factor.L)) +
                      dot(residual, factor \ residual))
    end
    result = Optim.optimize(profiled_nll, -8.0, 4.0, Optim.Brent();
        abs_tol=1e-12, rel_tol=1e-12)
    Optim.converged(result) || error("independent dense scalar optimisation did not converge")
    log_sigma = Optim.minimizer(result)
    sigma2 = exp(2 * log_sigma)
    covariance = v .* ZZt .+ sigma2 .* Matrix(I, n, n)
    factor = cholesky(Symmetric(covariance))
    mean = dot(ones_n, factor \ response) / dot(ones_n, factor \ ones_n)
    return (nll=Optim.minimum(result), mean=mean,
        residual_variance=sigma2, covariance=covariance)
end

@testset "grouped variance profile matches independent dense oracle" begin
    fixture = _gpdo_fixture()
    fit = GLLVModels.fit_grouped_gaussian(fixture.Y; terms=fixture.terms,
        unit=fixture.group, iterations=100, g_tol=1e-5)
    @test fit.converged && fit.gradient_norm <= 1e-5

    profile = GLLVModels._grouped_gaussian_variance_profile(fit, fixture.Y;
        selected=(1, 1), iterations=100, gradient_tolerance=1e-5,
        max_expand=8, maxiter=24)
    @test profile.status === :available
    @test profile.lower.status === :root_verified
    @test profile.upper.status === :root_verified

    # Exact-zero overlay: the independent dense likelihood agrees with the
    # fixed-variance reduced production objective at its separately optimised
    # mean and residual variance. This does not fit or compare a model.
    zero_dense = _gpdo_dense_fixed_variance(fixture.y, fixture.Z, 0.0)
    zero_adapter = GLLVModels._grouped_indep_variance_profile_objective(
        fixture.Y, fit.mean_design, fit.terms, fit.incidences;
        selected=(1, 1), fixed_variance=0.0)
    zero_theta = [zero_dense.mean, log(sqrt(zero_dense.residual_variance))]
    @test zero_adapter.selected_covariance(zero_theta) == 0.0
    @test ismissing(zero_adapter.selected_coordinate(zero_theta))
    @test isapprox(zero_adapter.objective(zero_theta), zero_dense.nll;
        atol=1e-10, rtol=1e-10)

    dense_center = _gpdo_dense_fixed_variance(
        fixture.y, fixture.Z, profile.center.fixed_variance)
    @test isfinite(dense_center.nll) && dense_center.residual_variance > 0
    for side in (profile.lower, profile.upper)
        dense = _gpdo_dense_fixed_variance(fixture.y, fixture.Z, side.endpoint)
        dense_lr = 2 * (dense.nll - dense_center.nll)
        @test isfinite(dense.mean) && dense.residual_variance > 0
        @test abs(side.endpoint_check.lr - profile.cutoff) <= 1e-4
        @test abs(dense_lr - profile.cutoff) <= 1e-4
    end
end
