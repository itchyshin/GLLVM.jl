using Test
using GLLVModels
using JSON3

@testset "Destination B B1 frozen-R paired Gaussian cluster fit" begin
    receipt_path = joinpath(@__DIR__, "..", "docs", "dev-log", "core070", "destination-b-b1", "frozen-r070-cluster-gaussian-paired-receipt-20260910.json")
    receipt = JSON3.read(read(receipt_path, String))
    r_beta = Float64.(receipt.fit.b_fix)
    r_loglik = Float64(receipt.fit.logLik)
    r_sigma_eps = Float64(receipt.fit.sigma_eps)
    r_sigma_cluster = [Float64(receipt.fit.Sigma_cluster[i][j]) for i in 1:2, j in 1:2]
    r_theta_in_julia_order = [r_beta; Float64.(receipt.fit.theta_diag_species); Float64(receipt.fit.log_sigma_eps)]
    Y = reshape(Float64.(receipt.response_long.value), 2, :)
    cluster = Symbol.(receipt.response_long.cluster_id[1:2:end])
    changed_cluster = copy(cluster)
    alternate = something(findfirst(x -> x != cluster[1], cluster))
    changed_cluster[1] = cluster[alternate]
    terms = [GroupingTerm(:cluster; mode = :indep)]

    @test String(receipt.source.git_sha) == "b4d5fee64def88bc768dda1f1f77c29b295edd86"
    @test String(receipt.source.description_version) == "0.7.0"
    @test String(receipt.installed.loaded_version) == "0.7.0"
    @test String(receipt.source.archive_sha256) == "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
    @test String(receipt.installed.shared_library_sha256) == "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30"
    @test String(receipt.specification.data_md5) == "d878dafc50c094539ab1aba0c77c999f"
    @test String(receipt.r_runner.sha256) == "f0ea06d0cdbb110491fece62144b4d094344cf5456a1af953604939427b27d48"
    @test String(receipt.specification.formula) == "value ~ 0 + trait + indep(0 + trait | cluster_id)"
    @test receipt.specification.REML === false
    @test receipt.fit.convergence == 0
    @test size(Y) == (2, 48)
    @test cluster[alternate] != cluster[1]

    at_r_coordinates = fit_gllvm(Y; family = GLLVModels.Normal(), grouping = terms, cluster = cluster, start = r_theta_in_julia_order, iterations = 0)
    refit = fit_gllvm(Y; family = GLLVModels.Normal(), grouping = terms, cluster = cluster, iterations = 100)
    changed_membership = fit_gllvm(Y; family = GLLVModels.Normal(), grouping = terms, cluster = changed_cluster, start = r_theta_in_julia_order, iterations = 0)

    @test at_r_coordinates.loglik ≈ r_loglik atol = 1e-8 rtol = 0
    @test refit.converged
    @test refit.loglik ≈ r_loglik atol = 1e-6 rtol = 0
    @test refit.parameters[1:2] ≈ r_beta atol = 1e-6 rtol = 0
    @test refit.term_covariances[1] ≈ r_sigma_cluster atol = 1e-5 rtol = 0
    @test refit.sigma_eps ≈ r_sigma_eps atol = 1e-6 rtol = 0
    @test !isapprox(changed_membership.loglik, r_loglik; atol = 1e-4, rtol = 0)
end
