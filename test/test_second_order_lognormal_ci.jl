# One-part LognormalFit Wald / profile wiring (second-order holdout clearance).
# Bridge CI guard lift waits on #357 (foreign bridge logLik receipts).

using Test
using Random
using GLLVM

@testset "LognormalFit second-order Wald CI" begin
    Random.seed!(71)
    p, K, n = 5, 1, 160
    β = 0.25 .* randn(p)
    Λ = 0.45 .* ones(p, K)
    σ = 0.4
    Y = Matrix{Float64}(undef, p, n)
    for s in 1:n
        η = β .+ Λ * randn(K)
        for t in 1:p
            Y[t, s] = exp(η[t] + σ * randn())
        end
    end
    fit = fit_lognormal_gllvm(Y; K = K)
    @test fit isa LognormalFit
    @test fit.converged

    ci = confint(fit, Y; method = :wald)
    @test ci.method === :wald
    @test "sigma" in ci.term
    @test "beta[1]" in ci.term
    σ_row = findfirst(==("sigma"), ci.term)
    @test σ_row !== nothing
    @test ci.estimate[σ_row] ≈ fit.σ atol = 1e-8
    @test isfinite(ci.se[σ_row]) && ci.se[σ_row] > 0
    if isfinite(ci.lower[σ_row]) && isfinite(ci.upper[σ_row])
        @test 0 < ci.lower[σ_row] < ci.estimate[σ_row] < ci.upper[σ_row]
    end

    w = confint(fit, Y; method = :wald, parm = "beta[1]")
    @test w.term == ["beta[1]"]
    @test w.estimate[1] ≈ fit.β[1] atol = 1e-8
    @test isfinite(w.se[1])

    # Profile path exercises the same packed NLL (smoke; may be one-sided).
    pr = confint(fit, Y; method = :profile, parm = "sigma")
    @test pr.method === :profile
    @test pr.term == ["sigma"]
    @test isfinite(pr.estimate[1])
end

@testset "R paired lognormal cell (live Δ, beta[] block)" begin
    if get(ENV, "GLLVM_PARITY_TESTS", "0") != "1"
        @test_skip "set GLLVM_PARITY_TESTS=1 with R + gllvmTMB for live second-order Δ"
    else
        using RCall
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "common.jl"))
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "cells.jl"))
        d = run_one_cell("lognormal")
        @test get(d, "skip_reason", nothing) === nothing
        @test get(d, "parameterisation_gap", true) == false
        se_rel = d["se_max_relative_delta"]
        @test se_rel !== nothing && isfinite(se_rel)
    end
end
