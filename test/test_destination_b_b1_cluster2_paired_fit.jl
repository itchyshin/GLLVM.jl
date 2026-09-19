using Test
using GLLVModels
using JSON3

@testset "Destination B B1 frozen-R paired Gaussian cluster2 fit" begin
    receipt_path = joinpath(@__DIR__, "..", "docs", "dev-log", "core070", "destination-b-b1", "frozen-r070-cluster2-gaussian-paired-receipt-20260910.json")
    @test isfile(receipt_path)
    receipt = JSON3.read(read(receipt_path, String))
    r_beta = Float64.(receipt.fit.b_fix)
    r_loglik = Float64(receipt.fit.logLik)
    r_sigma_eps = Float64(receipt.fit.sigma_eps)
    r_sigma_cluster2 = [Float64(receipt.fit.Sigma_cluster2[i][j]) for i in 1:2, j in 1:2]
    raw_names = String.(receipt.fit.raw_opt_par.names)
    raw_values = Float64.(receipt.fit.raw_opt_par.values)
    r_theta_in_julia_order = [r_beta; Float64.(receipt.fit.theta_diag_cluster2); Float64(receipt.fit.log_sigma_eps)]
    Y = reshape(Float64.(receipt.response_long.value), 2, :)
    unit = Symbol.(receipt.response_long.unit[1:2:end])
    cluster2 = Symbol.(receipt.response_long.cluster2_id[1:2:end])
    changed_cluster2 = copy(cluster2)
    alternate = something(findfirst(x -> x != cluster2[1], cluster2))
    changed_cluster2[1] = cluster2[alternate]
    terms = [GroupingTerm(:cluster2; mode = :indep)]

    @test String(receipt.receipt_kind) == "frozen_R_to_Julia_paired_gaussian_cluster2_fit"
    @test String(receipt.source.git_sha) == "b4d5fee64def88bc768dda1f1f77c29b295edd86"
    @test String(receipt.source.description_version) == "0.7.0"
    @test String(receipt.installed.loaded_version) == "0.7.0"
    @test String(receipt.source.archive_sha256) == "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
    @test String(receipt.installed.shared_library_sha256) == "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30"
    @test String(receipt.specification.data_md5) == "aca6428101f182510e885645a3ddd761"
    @test String(receipt.r_runner.sha256) == "9ba69dd9016336b9ada9798824b232011f18368d9c58f99fabf9051d64687138"
    @test String(receipt.specification.formula) == "value ~ 0 + trait + indep(0 + trait | cluster2_id)"
    @test receipt.specification.REML === false
    @test receipt.fit.convergence == 0
    @test String.(receipt.mapping.trait_levels) == ["trait_1", "trait_2"]
    @test String.(receipt.mapping.x_fix_names) == ["traittrait_1", "traittrait_2"]
    @test raw_names == ["b_fix", "b_fix", "log_sigma_eps", "theta_diag_cluster2", "theta_diag_cluster2"]
    @test raw_values[1:2] ≈ r_beta atol = 1e-12 rtol = 0
    @test raw_values[3] ≈ Float64(receipt.fit.log_sigma_eps) atol = 1e-12 rtol = 0
    @test raw_values[4:5] ≈ Float64.(receipt.fit.theta_diag_cluster2) atol = 1e-12 rtol = 0
    @test size(Y) == (2, 48)
    @test cluster2[alternate] != cluster2[1]
    @test length(unique(unit)) == 4
    @test length(unique(cluster2)) == 6
    @test all(length(unique(unit[cluster2 .== group])) == 4 for group in unique(cluster2))
    @test all(length(unique(cluster2[unit .== group])) == 6 for group in unique(unit))

    at_r_coordinates = fit_gllvm(Y; family = GLLVModels.Normal(), grouping = terms, cluster2 = cluster2, start = r_theta_in_julia_order, iterations = 0)
    refit = fit_gllvm(Y; family = GLLVModels.Normal(), grouping = terms, cluster2 = cluster2, iterations = 100)
    changed_membership = fit_gllvm(Y; family = GLLVModels.Normal(), grouping = terms, cluster2 = changed_cluster2, start = r_theta_in_julia_order, iterations = 0)

    @test at_r_coordinates.loglik ≈ r_loglik atol = 1e-8 rtol = 0
    @test refit.converged
    @test refit.loglik ≈ r_loglik atol = 1e-6 rtol = 0
    @test refit.parameters[1:2] ≈ r_beta atol = 1e-6 rtol = 0
    @test refit.term_covariances[1] ≈ r_sigma_cluster2 atol = 1e-5 rtol = 0
    @test refit.sigma_eps ≈ r_sigma_eps atol = 1e-6 rtol = 0
    @test !isapprox(changed_membership.loglik, r_loglik; atol = 1e-4, rtol = 0)
end
