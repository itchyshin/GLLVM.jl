using Test
using GLLVM
using JSON3

@testset "Destination B B1 frozen-R joint Gaussian grouping optimizer diagnostic" begin
    receipt_path = joinpath(@__DIR__, "..", "docs", "dev-log", "core070", "destination-b-b1", "frozen-r070-joint-gaussian-paired-receipt-20260910-03.json")
    probe_receipt_path = joinpath(@__DIR__, "..", "docs", "dev-log", "core070", "destination-b-b1", "frozen-r070-joint-gaussian-optimizer-probes-20260910-03.json")
    @test isfile(receipt_path)
    @test isfile(probe_receipt_path)
    rscript = Sys.which("Rscript")
    if isempty(rscript)
        @test_skip "Rscript unavailable: B1 receipt I/O gate skipped"
    else
        io_test = joinpath(@__DIR__, "test_destination_b_b1_joint_receipt_io.R")
        @test success(run(ignorestatus(`$rscript --vanilla $io_test`)))
    end
    receipt = JSON3.read(read(receipt_path, String))
    r_beta = Float64.(receipt.fit.b_fix)
    r_loglik = Float64(receipt.fit.logLik)
    r_gradient_max_abs = Float64(receipt.fit.gradient_max_abs)
    r_tight = receipt.fit.nlminb_tight_same_start
    r_bfgs = receipt.fit.optim_bfgs_same_start
    r_multistart = receipt.fit.nlminb_multistart_5
    raw_names = String.(receipt.fit.raw_opt_par.names)
    raw_values = Float64.(receipt.fit.raw_opt_par.values)
    r_theta_in_julia_order = [r_beta; Float64.(receipt.fit.theta_rr_B);
        Float64.(receipt.fit.theta_diag_W); Float64.(receipt.fit.theta_diag_species);
        Float64.(receipt.fit.theta_diag_cluster2); Float64(receipt.fit.log_sigma_eps)]
    Y = reshape(Float64.(receipt.response_long.value), 2, :)
    unit = Symbol.(receipt.response_long.unit[1:2:end])
    unit_obs = Symbol.(receipt.response_long.obs[1:2:end])
    cluster = Symbol.(receipt.response_long.cluster_id[1:2:end])
    cluster2 = Symbol.(receipt.response_long.cluster2_id[1:2:end])
    changed_cluster2 = copy(cluster2)
    alternate_cluster2 = something(findfirst(x -> x != cluster2[1], cluster2))
    changed_cluster2[1] = cluster2[alternate_cluster2]
    changed_unit_obs = copy(unit_obs)
    same_unit_alternate = something(findfirst(i -> unit[i] == unit[1] && unit_obs[i] != unit_obs[1], eachindex(unit_obs)))
    changed_unit_obs[1] = unit_obs[same_unit_alternate]
    terms = [
        GroupingTerm(:unit; mode = :latent, rank = 1, unique = false),
        GroupingTerm(:unit_obs; mode = :indep),
        GroupingTerm(:cluster; mode = :indep),
        GroupingTerm(:cluster2; mode = :indep),
    ]

    @test String(receipt.receipt_kind) == "frozen_R_to_Julia_joint_gaussian_optimizer_diagnostic"
    @test String(receipt.source.git_sha) == "b4d5fee64def88bc768dda1f1f77c29b295edd86"
    @test String(receipt.source.description_version) == "0.7.0"
    @test String(receipt.installed.loaded_version) == "0.7.0"
    @test String(receipt.source.archive_sha256) == "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
    @test String(receipt.installed.shared_library_sha256) == "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30"
    @test String(receipt.specification.data_md5) == "cb7cb72ff26acbe6782f8731b40ce680"
    @test String(receipt.r_runner.sha256) == "34b5a3b18a3475f260958883b5e52b25961b840bf810e3e8a3b8b2fc9c620aea"
    @test String(receipt.r_runner.fixture_attestation_module) == "tools/destination_b/b1_joint_gaussian_common.R"
    @test String(receipt.r_runner.fixture_attestation_module_sha256) == "61009033b613bd1eb8f97b42c073e180ad71418d758d9da97aa8f8cd5a793924"
    @test receipt.specification.REML === false
    @test receipt.acceptance.matched_parameter === false
    @test Float64(receipt.acceptance.source_gradient_threshold) == 1e-6
    @test r_gradient_max_abs > Float64(receipt.acceptance.source_gradient_threshold)
    @test r_tight.convergence == 1
    @test Float64(r_tight.logLik) ≈ r_loglik atol = 1e-12 rtol = 0
    @test Float64(r_tight.gradient_max_abs) ≈ r_gradient_max_abs atol = 1e-12 rtol = 0
    @test String.(r_tight.raw_opt_par.names) == raw_names
    @test Float64.(r_tight.raw_opt_par.values) ≈ raw_values atol = 1e-12 rtol = 0
    @test Float64(r_bfgs.logLik) < r_loglik - 1e-9
    @test Float64(r_bfgs.gradient_max_abs) > r_gradient_max_abs
    @test r_multistart.convergence == 0
    @test Float64(r_multistart.logLik) ≈ -32.847374868303177 atol = 1e-12 rtol = 0
    @test Float64(r_multistart.gradient_max_abs) ≈ 1.8152100309904722e-5 atol = 1e-14 rtol = 0
    @test Float64(r_multistart.logLik) > r_loglik + 1e-10
    @test Float64(r_multistart.gradient_max_abs) < r_gradient_max_abs
    @test Float64(r_multistart.gradient_max_abs) > Float64(receipt.acceptance.source_gradient_threshold)
    @test size(Y) == (2, 36)
    @test String.(receipt.mapping.trait_levels) == ["trait_1", "trait_2"]
    @test String.(receipt.mapping.x_fix_names) == ["traittrait_1", "traittrait_2"]
    @test raw_names == ["b_fix", "b_fix", "log_sigma_eps", "theta_rr_B", "theta_rr_B",
        "theta_diag_W", "theta_diag_W", "theta_diag_species", "theta_diag_species",
        "theta_diag_cluster2", "theta_diag_cluster2"]
    @test raw_values[1:2] ≈ r_beta atol = 1e-12 rtol = 0
    @test raw_values[3] ≈ Float64(receipt.fit.log_sigma_eps) atol = 1e-12 rtol = 0
    @test raw_values[4:5] ≈ Float64.(receipt.fit.theta_rr_B) atol = 1e-12 rtol = 0
    @test raw_values[6:7] ≈ Float64.(receipt.fit.theta_diag_W) atol = 1e-12 rtol = 0
    @test raw_values[8:9] ≈ Float64.(receipt.fit.theta_diag_species) atol = 1e-12 rtol = 0
    @test raw_values[10:11] ≈ Float64.(receipt.fit.theta_diag_cluster2) atol = 1e-12 rtol = 0
    @test all(length(unique(unit[unit_obs .== group])) == 1 for group in unique(unit_obs))
    @test all(length(unique(unit_obs[unit .== group])) == 2 for group in unique(unit))
    @test all(length(unique(unit[cluster .== group])) == 6 for group in unique(cluster))
    @test all(length(unique(unit[cluster2 .== group])) == 6 for group in unique(cluster2))

    at_r_coordinates = fit_gllvm(Y; family = GLLVM.Normal(), grouping = terms,
        unit = unit, unit_obs = unit_obs, cluster = cluster, cluster2 = cluster2,
        start = r_theta_in_julia_order, iterations = 0)
    refit = fit_gllvm(Y; family = GLLVM.Normal(), grouping = terms,
        unit = unit, unit_obs = unit_obs, cluster = cluster, cluster2 = cluster2,
        iterations = 800, g_tol = 1e-8)
    changed_cluster2_fit = fit_gllvm(Y; family = GLLVM.Normal(), grouping = terms,
        unit = unit, unit_obs = unit_obs, cluster = cluster, cluster2 = changed_cluster2,
        start = r_theta_in_julia_order, iterations = 0)
    changed_unit_obs_fit = fit_gllvm(Y; family = GLLVM.Normal(), grouping = terms,
        unit = unit, unit_obs = changed_unit_obs, cluster = cluster, cluster2 = cluster2,
        start = r_theta_in_julia_order, iterations = 0)

    @info "Destination B B1 joint independent-Julia-fit diagnostic (not acceptance)" r_loglik r_gradient_max_abs refit_loglik = refit.loglik gradient_norm = refit.gradient_norm beta_difference = refit.parameters[1:2] .- r_beta covariance_differences_from_nonstationary_R = [maximum(abs.(refit.term_covariances[i] .- [Float64(receipt.fit[Symbol("Sigma_", name)][row][column]) for row in 1:2, column in 1:2])) for (i, name) in enumerate(("unit", "unit_obs", "cluster", "cluster2"))] sigma_eps_difference_from_nonstationary_R = refit.sigma_eps - Float64(receipt.fit.sigma_eps)

    @test at_r_coordinates.loglik ≈ r_loglik atol = 1e-8 rtol = 0
    @test refit.converged
    @test refit.gradient_norm < 1e-7
    @test isfinite(refit.loglik)
    @test !isapprox(changed_cluster2_fit.loglik, at_r_coordinates.loglik; atol = 1e-4, rtol = 0)
    @test !isapprox(changed_unit_obs_fit.loglik, at_r_coordinates.loglik; atol = 1e-4, rtol = 0)

    if isfile(probe_receipt_path)
        probe_receipt = JSON3.read(read(probe_receipt_path, String))
        @test String(probe_receipt.receipt_kind) == "frozen_R_joint_gaussian_optimizer_probe"
        @test String(probe_receipt.source.git_sha) == "b4d5fee64def88bc768dda1f1f77c29b295edd86"
        @test String(probe_receipt.source.archive_sha256) == "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
        @test String(probe_receipt.installed.shared_library_sha256) == "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30"
        @test String(probe_receipt.r_runner.path) == "tools/destination_b/b1_joint_gaussian_optimizer_probes.R"
        @test String(probe_receipt.r_runner.sha256) == "192a9846b319a6d033c3dfbe4da8c7a2344676755191dac18d0d1daca995c9c7"
        @test String(probe_receipt.r_runner.fixture_attestation_module) == "tools/destination_b/b1_joint_gaussian_common.R"
        @test String(probe_receipt.r_runner.fixture_attestation_module_sha256) == "61009033b613bd1eb8f97b42c073e180ad71418d758d9da97aa8f8cd5a793924"
        @test Float64(probe_receipt.acceptance.source_gradient_threshold) == 1e-6
        @test probe_receipt.acceptance.matched_parameter === false
        @test isempty(probe_receipt.acceptance.eligible_stationary_attempts)
        expected_attempts = (
            "nlminb_multistart_10",
            "optim_bfgs_multistart_5",
            "nlminb_indep_multistart_5",
            "optim_bfgs_indep_multistart_5",
        )
        expected_results = Dict(
            "nlminb_multistart_10" => (-32.847374868293784, 1.1624432576135015e-5, 10, 7, "default"),
            "optim_bfgs_multistart_5" => (-32.847374868279616, 1.8505189364190403e-6, 5, 5, "default"),
            "nlminb_indep_multistart_5" => (-32.847374868303177, 1.8152100309904722e-5, 5, 4, "indep"),
            "optim_bfgs_indep_multistart_5" => (-32.847374868279616, 1.8505189364190403e-6, 5, 5, "indep"),
        )
        @test Tuple(String.(keys(probe_receipt.attempts))) == expected_attempts
        for name in expected_attempts
            attempt = probe_receipt.attempts[Symbol(name)]
            @test !isnothing(attempt)
            @test haskey(attempt, :status)
            @test haskey(attempt, :control)
            @test haskey(attempt, :warnings)
            @test haskey(attempt, :warm_start_applied)
            if String(attempt.status) == "success"
                expected_loglik, expected_gradient, expected_restarts, expected_selected, expected_start = expected_results[name]
                @test Float64(attempt.logLik) ≈ expected_loglik atol = 1e-12 rtol = 0
                @test Float64(attempt.gradient_max_abs) ≈ expected_gradient atol = 1e-14 rtol = 0
                @test Float64(attempt.gradient_max_abs) > Float64(probe_receipt.acceptance.source_gradient_threshold)
                @test haskey(attempt, :raw_opt_par)
                @test haskey(attempt, :restart_history)
                @test haskey(attempt, :start_provenance)
                @test length(attempt.restart_history) == expected_restarts
                @test Int(attempt.start_provenance.selected_restart) == expected_selected
                @test String(attempt.start_provenance.start_method) == expected_start
            else
                @test String(attempt.status) == "failure"
                @test haskey(attempt, :failure)
                @test !isempty(String(attempt.failure.message))
            end
        end
        for name in ("nlminb_indep_multistart_5", "optim_bfgs_indep_multistart_5")
            attempt = probe_receipt.attempts[Symbol(name)]
            if haskey(attempt, :warm_start_applied)
                @test !Bool(attempt.warm_start_applied)
            end
            if haskey(attempt, :warnings)
                @test occursin("Unsupported grouping \"cluster2_id\"", String(attempt.warnings))
            end
            @test String(attempt.control.start_method) == "indep"
            @test String(attempt.start_provenance.start_method) == "indep"
            @test attempt.start_provenance.auto_indep_fit === false
        end
    end
end

@testset "Destination B B1 stationary four-source frozen-R Gaussian candidate is retained when it fails" begin
    receipt_path = joinpath(@__DIR__, "..", "docs", "dev-log", "core070", "destination-b-b1",
        "frozen-r070-joint-gaussian-stationary-paired-receipt-20260910.json")
    @test isfile(receipt_path)

    receipt = JSON3.read(read(receipt_path, String))
    raw_names = String.(receipt.fit.raw_opt_par.names)

    @test String(receipt.receipt_kind) == "frozen_R_to_Julia_joint_gaussian_stationary_reference"
    @test String(receipt.source.git_sha) == "b4d5fee64def88bc768dda1f1f77c29b295edd86"
    @test String(receipt.source.archive_sha256) == "0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc"
    @test String(receipt.installed.shared_library_sha256) == "3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30"
    @test String(receipt.r_runner.path) == "tools/destination_b/b1_joint_gaussian_stationary_reference.R"
    @test String(receipt.r_runner.sha256) == "9d1f1fa95655bd8887d7e04d2c2d10c0311fac094205a4d47dd7ee6ebb9ca585"
    @test String(receipt.r_runner.fixture_attestation_module_sha256) == "61009033b613bd1eb8f97b42c073e180ad71418d758d9da97aa8f8cd5a793924"
    @test receipt.failure.present === false
    @test receipt.acceptance.matched_parameter === false
    @test Float64(receipt.acceptance.source_gradient_threshold) == 1e-6
    @test receipt.fit.convergence == 1
    @test Float64(receipt.fit.gradient_max_abs) ≈ 9.9329370235209566e-5 atol = 1e-16 rtol = 0
    @test Float64(receipt.fit.gradient_max_abs) > Float64(receipt.acceptance.source_gradient_threshold)
    @test String(receipt.fit.optimizer_message) == "singular convergence (7)"
    @test Int(receipt.specification.n_trait) == 2
    @test Int(receipt.specification.n_unit) == 12
    @test Int(receipt.specification.n_unit_obs_per_unit) == 3
    @test Int(receipt.specification.n_replicate) == 5
    @test Int(receipt.specification.n_cluster) == 8
    @test Int(receipt.specification.n_cluster2) == 7
    @test Int(receipt.specification.n_observation) == 180
    @test Int(receipt.specification.seed) == 20260914
    @test String(receipt.specification.data_md5) == "8d61143f2ce6102bb8460fb1575cc249"
    @test raw_names == ["b_fix", "b_fix", "log_sigma_eps", "theta_rr_B", "theta_rr_B",
        "theta_diag_W", "theta_diag_W", "theta_diag_species", "theta_diag_species",
        "theta_diag_cluster2", "theta_diag_cluster2"]
end
