# MultinomialFit FE softmax Wald / profile wiring (second-order holdout clearance).
# v1 has no LV; packing [β₂…β_K; γ…]. Bridge untouched.

using Test
using Random
using GLLVM

@testset "MultinomialFit second-order Wald CI (no-X)" begin
    Random.seed!(711)
    n, ncat = 900, 3
    β_true = [0.7, -0.35]
    η = [0.0, β_true[1], β_true[2]]
    π = exp.(η) ./ sum(exp.(η))
    y = [findfirst(rand() .≤ cumsum(π)) for _ in 1:n]
    Y = reshape(Int.(y), 1, n)
    fit = fit_multinomial_gllvm(Y)
    @test fit isa MultinomialFit
    @test fit.converged
    @test size(fit.γ, 2) == 0

    ci = confint(fit, Y; method = :wald)
    @test ci.method === :wald
    @test "beta[2]" in ci.term
    @test "beta[3]" in ci.term
    @test length(ci.term) == 2
    r2 = findfirst(==("beta[2]"), ci.term)
    @test r2 !== nothing
    @test ci.estimate[r2] ≈ fit.β[1] atol = 1e-8
    @test isfinite(ci.se[r2]) && ci.se[r2] > 0
    if isfinite(ci.lower[r2]) && isfinite(ci.upper[r2])
        @test ci.lower[r2] < ci.estimate[r2] < ci.upper[r2]
    end

    w = confint(fit, Y; method = :wald, parm = "beta[2]")
    @test w.term == ["beta[2]"]
    @test w.estimate[1] ≈ fit.β[1] atol = 1e-8

    pr = confint(fit, Y; method = :profile, parm = "beta[3]")
    @test pr.method === :profile
    @test pr.term == ["beta[3]"]
    @test isfinite(pr.estimate[1])

    @test_throws ArgumentError confint(fit, Y; method = :wald, X = randn(n, 1))
end

@testset "MultinomialFit second-order Wald CI (+X)" begin
    Random.seed!(712)
    n, ncat, p_cov = 700, 3, 1
    β_true = [0.45, -0.25]
    γ_true = reshape([0.75, -0.55], 2, 1)
    X = randn(n, p_cov)
    y = Vector{Int}(undef, n)
    for i in 1:n
        η = GLLVM.multinomial_eta(β_true, γ_true, vec(X[i, :]))
        π = exp.(η) ./ sum(exp.(η))
        y[i] = findfirst(rand() .≤ cumsum(π))
    end
    Y = reshape(y, 1, n)
    fit = fit_multinomial_gllvm(Y; X = X)
    @test fit isa MultinomialFit
    @test size(fit.γ) == (ncat - 1, p_cov)

    @test_throws ArgumentError confint(fit, Y; method = :wald)

    ci = confint(fit, Y; method = :wald, X = X)
    @test ci.method === :wald
    @test "beta[2]" in ci.term
    @test "gamma[2,1]" in ci.term
    @test "gamma[3,1]" in ci.term
    g21 = findfirst(==("gamma[2,1]"), ci.term)
    @test g21 !== nothing
    @test ci.estimate[g21] ≈ fit.γ[1, 1] atol = 1e-8
    @test isfinite(ci.se[g21]) && ci.se[g21] > 0
end

@testset "R paired multinomial_fe cell (live Δ)" begin
    if get(ENV, "GLLVM_PARITY_TESTS", "0") != "1"
        @test_skip "set GLLVM_PARITY_TESTS=1 with R + gllvmTMB for live second-order Δ"
    else
        using RCall
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "common.jl"))
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "cells.jl"))
        d = run_one_cell("multinomial_fe")
        @test get(d, "skip_reason", nothing) === nothing
        @test get(d, "parameterisation_gap", true) == false
        se_rel = d["se_max_relative_delta"]
        @test se_rel !== nothing && isfinite(se_rel)
    end
end
