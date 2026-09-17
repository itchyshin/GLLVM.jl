# Second-order follow-up: TweedieGroupedFit Wald `_family_ci` + fixed-power SO cell.
# Clears the holdout `_CIFit` gap; wires `r_fit_se_tweedie` + `tweedie_fixed` cell.
# R↔Julia live Δ only when GLLVM_PARITY_TESTS=1. ≠ programme §7.

using GLLVModels, Test, Random

@testset "second-order TweedieGroupedFit Wald wiring" begin
    @testset "fixed power: θ packing + public Wald on beta" begin
        Random.seed!(182)
        p, K, n = 5, 1, 80
        β = [0.4, -0.1, 0.2, -0.3, 0.05]
        Λ = 0.35 .* ones(p, K)
        Λ[2, 1] = 0.15
        φ = [0.7, 0.9, 1.1, 0.8, 1.0]
        pw = 1.5
        Z = randn(K, n)
        μ = exp.(β .+ Λ * Z)
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = GLLVModels._tweedie_sample(μ[t, s], φ[t], pw, Random.default_rng())
        end
        fit = fit_tweedie_gllvm_grouped(Y; K = K, power = pw, iterations = 250)
        @test fit isa GLLVModels.TweedieGroupedFit
        @test fit.power_fixed
        ad = GLLVModels._family_ci(fit, Y)
        @test length(ad.θ) == p + GLLVModels.rr_theta_len(p, K) + p
        @test count(startswith("beta["), ad.names) == p
        @test count(startswith("phi["), ad.names) == p
        ci = confint(fit, Y; method = :wald, parm = "beta")
        @test length(ci.term) == p
        fin = isfinite.(ci.se)
        @test count(fin) ≥ 3
        @test all(ci.lower[fin] .< ci.estimate[fin] .< ci.upper[fin])
    end

    @testset "shared estimated power: power plug-in; φ still in θ" begin
        Random.seed!(183)
        p, K, n = 4, 1, 60
        β = 0.2 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        φ = fill(0.9, p)
        pw = 1.45
        Z = randn(K, n)
        μ = exp.(β .+ Λ * Z)
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = GLLVModels._tweedie_sample(μ[t, s], φ[t], pw, Random.default_rng())
        end
        fit = fit_tweedie_gllvm_grouped(Y; K = K, power_group = :shared, iterations = 200)
        @test fit isa GLLVModels.TweedieGroupedFit
        @test !fit.power_fixed
        ad = GLLVModels._family_ci(fit, Y)
        @test length(ad.θ) == p + GLLVModels.rr_theta_len(p, K) + length(fit.φ)
        ci = confint(fit, Y; method = :wald, parm = "beta[1]")
        @test ci.term == ["beta[1]"]
        @test length(ad.θ) == GLLVModels._nparams(fit) - 1  # minus free power coordinate
    end

    @testset "species estimated power: plug-in θ length + beta Wald" begin
        Random.seed!(184)
        p, K, n = 5, 1, 70
        β = 0.15 .* randn(p)
        Λ = 0.25 .* randn(p, K)
        φ = [0.75, 0.85, 0.95, 1.05, 1.15]
        pw = 1.4 .+ 0.05 .* collect(1:p)
        Z = randn(K, n)
        μ = exp.(β .+ Λ * Z)
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = GLLVModels._tweedie_sample(μ[t, s], φ[t], pw[t], Random.default_rng())
        end
        fit = fit_tweedie_gllvm_grouped(Y; K = K, power_group = :species, iterations = 250)
        @test fit isa GLLVModels.TweediePerTraitPowerFit
        ad = GLLVModels._family_ci(fit, Y)
        @test length(ad.θ) == p + GLLVModels.rr_theta_len(p, K) + length(fit.φ)
        @test length(ad.θ) == GLLVModels._nparams(fit) - p
        ci = confint(fit, Y; method = :wald, parm = "beta")
        @test length(ci.term) == p
        fin = isfinite.(ci.se)
        @test count(fin) ≥ 3
    end

    @testset "R paired tweedie_fixed / tweedie_shared / tweedie_species cells (live Δ)" begin
        if get(ENV, "GLLVM_PARITY_TESTS", "0") != "1"
            @test_skip "set GLLVM_PARITY_TESTS=1 with R + gllvmTMB for live second-order Δ"
        else
            using RCall
            include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "common.jl"))
            include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "cells.jl"))
            for cell_id in ("tweedie_fixed", "tweedie_shared", "tweedie_species")
                d = run_one_cell(cell_id)
                @test get(d, "skip_reason", nothing) === nothing
                @test get(d, "parameterisation_gap", true) == false
                se_rel = d["se_max_relative_delta"]
                @test se_rel !== nothing && isfinite(se_rel)
                if cell_id == "tweedie_shared"
                    @test d["reference_constraint_adapter"] === true
                    @test d["n_power_free"] == 1
                end
            end
            # Do not assert contract §4 D1 here — record live Δ; promote only after smoke receipt.
        end
    end
end
