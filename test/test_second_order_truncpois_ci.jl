# TruncatedPoissonFit Wald wiring (second-order holdout clearance).
# Bridge CI guard lift waits on #357 (foreign bridge logLik receipts).

using Test
using Random
using GLLVM
using Distributions: Poisson

@testset "TruncatedPoissonFit second-order Wald CI" begin
    Random.seed!(72)
    p, K, n = 5, 1, 140
    β = 0.8 .+ 0.2 .* randn(p)   # keep μ away from zero so trunc is mild
    Λ = 0.35 .* ones(p, K)
    Y = Matrix{Int}(undef, p, n)
    for s in 1:n
        η = β .+ Λ * randn(K)
        for t in 1:p
            μ = exp(η[t])
            y = 0
            while y < 1
                y = rand(Poisson(μ))
            end
            Y[t, s] = y
        end
    end
    fit = fit_truncated_poisson_gllvm(Y; K = K)
    @test fit isa TruncatedPoissonFit
    @test fit.converged

    ci = confint(fit, Y; method = :wald)
    @test ci.method === :wald
    @test "beta[1]" in ci.term
    @test length(ci.term) == p + (p * K)   # β + free Λ (lower-tri pack for K=1 is p)
    w = confint(fit, Y; method = :wald, parm = "beta[1]")
    @test w.term == ["beta[1]"]
    @test w.estimate[1] ≈ fit.β[1] atol = 1e-8
    @test isfinite(w.se[1]) && w.se[1] > 0
end

@testset "R paired truncated_poisson cell (live Δ)" begin
    if get(ENV, "GLLVM_PARITY_TESTS", "0") != "1"
        @test_skip "set GLLVM_PARITY_TESTS=1 with R + gllvmTMB for live second-order Δ"
    else
        using RCall
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "common.jl"))
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "cells.jl"))
        d = run_one_cell("truncated_poisson")
        @test get(d, "skip_reason", nothing) === nothing
        @test get(d, "parameterisation_gap", true) == false
        se_rel = d["se_max_relative_delta"]
        @test se_rel !== nothing && isfinite(se_rel)
    end
end
