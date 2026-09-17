using Test
using GLLVModels
using LinearAlgebra
using SparseArrays


function _dfe_manual_grouped_gaussian(; converged = false)
    Y = reshape([1.0, 2.0, 1.5, 2.5], 1, :); D = ones(4, 1)
    term = GroupingTerm(:unit; mode = :indep, common = true)
    return GroupedGaussianFit([1.75], 0.5, [reshape([0.25], 1, 1)], [term],
        [1.75, log(0.5), log(0.5)], -5.0, converged, converged ? 1e-8 : Inf,
        0.1, converged, 4, converged ? :converged : :not_converged, D,
        Union{String,Symbol}["trait1"], ["trait1", "unit.log_sd_common", "log_sigma_eps"],
        size(Y), Y, [sparse(collect(1:4), [1, 1, 2, 2], ones(4), 4, 2)])
end

function _dfe_manual_precision(; converged = false)
    Y = [1.0 2.0; 3.0 4.0]
    D = [1.0 0.0; 0.0 1.0; 1.0 0.0; 0.0 1.0]
    phy = GLLVModels.PrecisionPhy(GLLVModels.random_balanced_tree(2; branch_length = 0.5))
    return GLLVModels.PrecisionMultivariateFit([1.0, 2.0], reshape([0.4, 0.2], 2, 1),
        [0.1, 0.2], [0.3, 0.4], :explicitunique, 1, phy, [1, 2], zeros(7),
        -6.0, converged, converged ? 1e-8 : Inf, 0.1, converged, 3.0, 4,
        converged ? :converged : :not_converged, Y, D, size(Y),
        Union{String,Symbol}["trait1", "trait2"])
end

@testset "Destination B fixed-effect covariance" begin
    H = [4.0 1.0 0.8; 1.0 3.0 0.5; 0.8 0.5 2.0]
    objective = theta -> 0.5 * dot(theta, H * theta)
    result = GLLVModels._destination_b_fixed_effect_information(objective, zeros(3), 2;
        converged = true, structural_redundancy = false)
    expected = inv(H)[1:2, 1:2]
    fixed_only = inv(H[1:2, 1:2])
    @test result.status === :available
    @test result.covariance ≈ expected atol = 1e-6
    @test !isapprox(result.covariance, fixed_only; atol = 1e-6, rtol = 1e-6)
    @test abs(result.covariance[1, 2]) > 1e-6
    redundant = GLLVModels._destination_b_fixed_effect_information(objective, zeros(3), 2;
        converged = true, structural_redundancy = true)
    @test redundant.status === :nonidentifiable
    @test redundant.covariance === nothing

    unit = repeat(1:4; inner = 2)
    term = [GroupingTerm(:unit; mode = :indep, common = true)]
    gaussian_y = reshape([1.0, 1.2, 0.9, 1.1, 3.0, 2.8, 3.1, 2.9], 1, :)
    gaussian = GLLVModels.fit_grouped_gaussian(gaussian_y; terms = term, unit = unit, iterations = 80)
    @test gaussian.converged
    gaussian_vcov = GLLVModels.vcov(gaussian)
    @test all(isfinite, gaussian_vcov)
    @test GLLVModels.stderror(gaussian) ≈ sqrt.(diag(gaussian_vcov))
    gaussian_report = summary(gaussian, gaussian.response)
    @test gaussian_report.inference_status === :available
    @test isfinite(gaussian_report.inference_gradient_norm)
    @test gaussian_report.gradient_norm == gaussian.gradient_norm
    @test all(row -> row.status === :available && isfinite(row.se),
        gaussian_report.fixed_effects)

    poisson_y = reshape([1, 2, 1, 1, 8, 9, 9, 7], 1, :)
    poisson = GLLVModels.fit_grouped_nongaussian(poisson_y; family = GLLVModels.Poisson(),
        terms = term, unit = unit, iterations = 60)
    @test poisson.converged
    poisson_vcov = GLLVModels.vcov(poisson)
    @test all(isfinite, poisson_vcov)
    @test GLLVModels.stderror(poisson) ≈ sqrt.(diag(poisson_vcov))

    unavailable = _dfe_manual_grouped_gaussian()
    @test_throws ArgumentError GLLVModels.vcov(unavailable)
    @test_throws ArgumentError GLLVModels.stderror(unavailable)
    report = summary(unavailable, unavailable.response)
    @test report.inference_status === :not_converged
    @test all(row -> row.status === :not_converged && isnan(row.se), report.fixed_effects)
    @test_throws ArgumentError summary(unavailable, unavailable.response .+ 1.0)
    @test summary(unavailable) isa String

    precision = _dfe_manual_precision()
    @test_throws ArgumentError GLLVModels.vcov(precision)
    precision_report = summary(precision, precision.response)
    @test precision_report.inference_status === :not_converged
    @test length(precision_report.fixed_effects) == length(GLLVModels.coef(precision))
end
