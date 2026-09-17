using Test
using GLLVModels
using JSON3

@testset "Destination B B1 frozen-R paired Gaussian unit fit" begin
    receipt_path = joinpath(@__DIR__, "..", "docs", "dev-log", "core070",
        "destination-b-b1", "frozen-r070-unit-gaussian-paired-receipt-20260910.json")
    receipt = JSON3.read(read(receipt_path, String))
    r_source = String(receipt.source.git_sha)
    r_loglik = Float64(receipt.fit.logLik)
    r_beta = Float64.(receipt.fit.b_fix)
    r_sigma_eps = Float64(receipt.fit.sigma_eps)
    r_sigma_unit = [Float64(receipt.fit.Sigma_B[i][j]) for i in 1:2, j in 1:2]
    r_theta_in_julia_order = [r_beta; Float64.(receipt.fit.theta_rr_B);
        Float64(receipt.fit.log_sigma_eps)]
    Y = reshape(Float64.(receipt.response_long.value), 2, :)
    unit = Symbol.(receipt.response_long.site[1:2:end])
    changed_unit = [:site_a, :site_a, :site_a, :site_b,
                    :site_c, :site_c, :site_d, :site_d]
    terms = [GroupingTerm(:unit; mode = :latent, rank = 1, unique = false)]

    @test r_source == "b4d5fee64def88bc768dda1f1f77c29b295edd86"
    @test String(receipt.source.description_version) == "0.7.0"
    @test String(receipt.installed.loaded_version) == "0.7.0"
    @test String(receipt.source.archive_sha256) ==
        "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
    @test String(receipt.installed.shared_library_sha256) ==
        "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30"
    @test String(receipt.specification.data_md5) == "06f33d506aa317ba2a8002d2232f0a94"
    @test String(receipt.r_runner.sha256) ==
        "ba9d9d12d43223ca99900443ffea880be3d3c92323221c713dccddd31954e304"
    @test String(receipt.specification.formula) ==
        "value ~ 0 + trait + latent(0 + trait | site, d = 1, unique = FALSE)"
    @test receipt.specification.REML === false
    @test receipt.fit.convergence == 0
    @test vec(String.(receipt.response_long.trait)) == repeat(["trait_1", "trait_2"], 8)
    @test size(Y) == (2, 8)
    at_r_coordinates = fit_gllvm(Y; family = GLLVModels.Normal(), grouping = terms,
        unit = unit, start = r_theta_in_julia_order, iterations = 0)
    refit = fit_gllvm(Y; family = GLLVModels.Normal(), grouping = terms,
        unit = unit, iterations = 100)
    changed_membership = fit_gllvm(Y; family = GLLVModels.Normal(), grouping = terms,
        unit = changed_unit, start = r_theta_in_julia_order, iterations = 0)

    @test at_r_coordinates.loglik ≈ r_loglik atol = 1e-8 rtol = 0
    @test refit.converged
    @test refit.loglik ≈ r_loglik atol = 1e-6 rtol = 0
    @test refit.parameters[1:2] ≈ r_beta atol = 1e-6 rtol = 0
    @test refit.term_covariances[1] ≈ r_sigma_unit atol = 1e-5 rtol = 0
    @test refit.sigma_eps ≈ r_sigma_eps atol = 1e-6 rtol = 0
    @test !isapprox(changed_membership.loglik, r_loglik; atol = 1e-4, rtol = 0)
end
