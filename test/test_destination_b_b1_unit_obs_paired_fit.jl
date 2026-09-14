using Test
using GLLVM
using JSON3

@testset "Destination B B1 frozen-R paired Gaussian unit_obs fit" begin
    receipt_path = joinpath(@__DIR__, "..", "docs", "dev-log", "core070",
        "destination-b-b1", "frozen-r070-unit-obs-gaussian-paired-receipt-20260910.json")
    receipt = JSON3.read(read(receipt_path, String))
    r_loglik = Float64(receipt.fit.logLik)
    r_beta = Float64.(receipt.fit.b_fix)
    r_sigma_eps = Float64(receipt.fit.sigma_eps)
    r_sigma_unit_obs = [Float64(receipt.fit.Sigma_W[i][j]) for i in 1:2, j in 1:2]
    r_theta_in_julia_order = [r_beta; Float64.(receipt.fit.log_sd_W);
        Float64(receipt.fit.log_sigma_eps)]
    Y = reshape(Float64.(receipt.response_long.value), 2, :)
    unit = Symbol.(receipt.response_long.unit[1:2:end])
    unit_obs = Symbol.(receipt.response_long.obs[1:2:end])
    changed_unit_obs = copy(unit_obs)
    alternate_within_unit = findfirst(x -> x != unit_obs[1], unit_obs)
    @assert !isnothing(alternate_within_unit)
    @assert unit[alternate_within_unit] == unit[1]
    changed_unit_obs[1] = unit_obs[alternate_within_unit]
    terms = [GroupingTerm(:unit_obs; mode = :indep)]

    @test String(receipt.source.git_sha) == "b4d5fee64def88bc768dda1f1f77c29b295edd86"
    @test String(receipt.source.description_version) == "0.7.0"
    @test String(receipt.installed.loaded_version) == "0.7.0"
    @test String(receipt.source.archive_sha256) ==
        "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
    @test String(receipt.installed.shared_library_sha256) ==
        "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30"
    @test String(receipt.specification.data_md5) == "28b622a0eae39f21b9badab619507687"
    @test String(receipt.r_runner.sha256) ==
        "0d05a63a8bd14c31aacfccb6abf589abed1d8bde061e43d43ecbb7825afb7022"
    @test String(receipt.specification.formula) ==
        "value ~ 0 + trait + indep(0 + trait | obs)"
    @test receipt.specification.REML === false
    @test receipt.fit.convergence == 0
    @test size(Y) == (2, 48)
    @test all(unit_obs[i] == unit_obs[i + 1] for i in 1:2:length(unit_obs) - 1)
    @test all(unit[i] == unit[i + 1] for i in 1:2:length(unit) - 1)
    @test unit_obs[alternate_within_unit] != unit_obs[1]
    @test unit[alternate_within_unit] == unit[1]

    at_r_coordinates = fit_gllvm(Y; family = GLLVM.Normal(), grouping = terms,
        unit = unit, unit_obs = unit_obs, start = r_theta_in_julia_order, iterations = 0)
    refit = fit_gllvm(Y; family = GLLVM.Normal(), grouping = terms,
        unit = unit, unit_obs = unit_obs, iterations = 100)
    changed_membership = fit_gllvm(Y; family = GLLVM.Normal(), grouping = terms,
        unit = unit, unit_obs = changed_unit_obs, start = r_theta_in_julia_order,
        iterations = 0)

    @test at_r_coordinates.loglik ≈ r_loglik atol = 1e-8 rtol = 0
    @test refit.converged
    @test refit.loglik ≈ r_loglik atol = 1e-6 rtol = 0
    @test refit.parameters[1:2] ≈ r_beta atol = 1e-6 rtol = 0
    @test refit.term_covariances[1] ≈ r_sigma_unit_obs atol = 1e-5 rtol = 0
    @test refit.sigma_eps ≈ r_sigma_eps atol = 1e-6 rtol = 0
    @test !isapprox(changed_membership.loglik, r_loglik; atol = 1e-4, rtol = 0)
end
