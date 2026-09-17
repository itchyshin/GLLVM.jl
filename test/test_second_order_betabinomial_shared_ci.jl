# Second-order holdout clearance: shared-phi BetaBinomialFit is ALREADY in _CIFit
# (src/confint_family.jl). This file adds the missing paired-cell test evidence,
# not new _CIFit wiring. ≠ programme §7. Bridge untouched.

using GLLVModels, Test, Random, Distributions

@testset "BetaBinomialFit (shared phi) second-order Wald wiring" begin
    @testset "θ packing + public Wald on beta[] (no-X)" begin
        Random.seed!(571)
        p, K, n = 5, 1, 80
        β = [0.3, -0.2, 0.25, -0.15, 0.05]
        φ = 8.0
        Λ = 0.2 .* randn(p, K)
        N = fill(8, p, n)
        Z = randn(K, n)
        η = β .+ Λ * Z
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = clamp(1 / (1 + exp(-η[t, s])), 1e-4, 1 - 1e-4)
            psucc = clamp(rand(Beta(μ * φ, (1 - μ) * φ)), 1e-6, 1 - 1e-6)
            Y[t, s] = rand(Binomial(N[t, s], psucc))
        end
        fit = fit_beta_binomial_gllvm(Y; K = K, N = N)
        @test fit isa BetaBinomialFit
        ad = GLLVModels._family_ci(fit, Float64.(Y); N = N)
        @test length(ad.θ) == p + GLLVModels.rr_theta_len(p, K) + 1
        @test count(startswith("beta["), ad.names) == p
        @test ad.names[end] == "phi"
        @test ad.kinds[end] === :log

        ci = confint(fit, Float64.(Y); method = :wald, N = N, parm = "beta")
        @test length(ci.term) == p
        fin = isfinite.(ci.se)
        @test count(fin) ≥ 3
        @test all(ci.lower[fin] .< ci.estimate[fin] .< ci.upper[fin])

        ciphi = confint(fit, Float64.(Y); method = :wald, N = N, parm = "phi")
        @test ciphi.term == ["phi"]
        @test isfinite(ciphi.se[1]) && ciphi.se[1] > 0
    end

    @testset "R paired betabinomial_shared cell (live Δ, beta[] block only)" begin
        if get(ENV, "GLLVM_PARITY_TESTS", "0") != "1"
            @test_skip "set GLLVM_PARITY_TESTS=1 with R + gllvmTMB for live second-order Δ"
        else
            using RCall
            include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "common.jl"))
            include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "cells.jl"))
            d = run_one_cell("betabinomial_shared")
            @test get(d, "skip_reason", nothing) === nothing
            @test get(d, "parameterisation_gap", true) == false
            se_rel = d["se_max_relative_delta"]
            @test se_rel !== nothing && isfinite(se_rel)
        end
    end
end
