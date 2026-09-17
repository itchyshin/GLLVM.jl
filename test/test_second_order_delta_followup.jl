# Second-order follow-up batch: Delta-lognormal / Delta-Gamma shared-η Wald wiring.
# R↔Julia SE receipts run only when GLLVM_PARITY_TESTS=1 (needs RCall + gllvmTMB).

using GLLVModels, Test, Random, Distributions

function _sim_delta_lognormal(p, K, n; seed = 171)
    Random.seed!(seed)
    β = 0.3 .* randn(p)
    Λ = 0.4 .* randn(p, K)
    σ = 0.45
    Z = randn(K, n)
    η = β .+ Λ * Z
    Y = zeros(p, n)
    for t in 1:p, s in 1:n
        π = 1 / (1 + exp(-η[t, s]))
        rand() < π && (Y[t, s] = exp(η[t, s] + σ * randn()))
    end
    return Y
end

@testset "second-order delta follow-up (shared predictor Wald)" begin
    @testset "Delta-lognormal: shared θ packing + public Wald" begin
        Y = _sim_delta_lognormal(5, 1, 100; seed = 171)
        fit = fit_delta_lognormal_gllvm(Y; K = 1, predictor = :shared, iterations = 400)
        @test fit.predictor === :shared
        ad = GLLVModels._family_ci(fit, Y)
        @test length(ad.θ) == 5 + GLLVModels.rr_theta_len(5, 1) + 1
        @test count(startswith("beta["), ad.names) == 5
        ci = confint(fit, Y; method = :wald, parm = "beta")
        @test length(ci.term) == 5
        fin = isfinite.(ci.se)
        @test count(fin) ≥ 3
        @test all(ci.lower[fin] .< ci.estimate[fin] .< ci.upper[fin])
    end

    @testset "Delta-Gamma: shared θ packing + public Wald" begin
        Random.seed!(172)
        p, K, n = 5, 1, 100
        β = 0.3 .* randn(p)
        Λ = 0.4 .* randn(p, K)
        α = 3.5
        Z = randn(K, n)
        η = β .+ Λ * Z
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            π = 1 / (1 + exp(-η[t, s]))
            if rand() < π
                μ = exp(η[t, s])
                Y[t, s] = rand(Gamma(α, μ / α))
            end
        end
        fit = fit_delta_gamma_gllvm(Y; K = K, predictor = :shared, iterations = 400)
        ad = GLLVModels._family_ci(fit, Y)
        @test count(startswith("beta["), ad.names) == 5
        ci = confint(fit, Y; method = :wald, parm = "beta[1]")
        @test ci.term == ["beta[1]"]
        @test isfinite(ci.se[1])
    end

    @testset "R paired each-own-optimum cells (live Δ)" begin
        if get(ENV, "GLLVM_PARITY_TESTS", "0") != "1"
            @test_skip "set GLLVM_PARITY_TESTS=1 with R + gllvmTMB for live second-order Δ"
        else
            using RCall
            using Distributions: Gamma
            include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "common.jl"))
            include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "cells.jl"))
            include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "eoo_assess.jl"))
            for cell_id in ("delta_lognormal", "delta_gamma")
                d = run_one_cell(cell_id)
                @test get(d, "skip_reason", nothing) === nothing
                @test get(d, "parameterisation_gap", false) == true
                se_rel = d["se_max_relative_delta"]
                @test se_rel !== nothing && isfinite(se_rel)
                # Contract §4 D1 not asserted: shared Julia dispersion vs R per-trait
                # (logLik Δ ≈ 1.9 / 2.6 on parity seeds) moves both optima.
            end
        end
    end
end
