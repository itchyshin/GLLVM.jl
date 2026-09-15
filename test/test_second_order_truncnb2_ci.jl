# TruncatedNegBin2Fit Wald wiring (second-order holdout clearance).

using Test
using Random
using GLLVM
using Distributions: NegativeBinomial

@testset "TruncatedNegBin2Fit second-order Wald CI" begin
    Random.seed!(73)
    p, K, n = 5, 1, 120
    β = 1.0 .+ 0.15 .* randn(p)
    Λ = 0.3 .* ones(p, K)
    r = 4.0
    Y = Matrix{Int}(undef, p, n)
    for s in 1:n
        η = β .+ Λ * randn(K)
        for t in 1:p
            μ = max(exp(η[t]), 1e-12)
            # reject-sample zeros from NB2
            y = 0
            while y < 1
                y = rand(NegativeBinomial(r, r / (r + μ)))
            end
            Y[t, s] = y
        end
    end
    fit = fit_truncated_nbinom2_gllvm(Y; K = K)
    @test fit isa TruncatedNegBin2Fit
    @test fit.converged

    ci = confint(fit, Y; method = :wald)
    @test ci.method === :wald
    @test "r" in ci.term
    @test "beta[1]" in ci.term
    r_row = findfirst(==("r"), ci.term)
    @test r_row !== nothing
    @test ci.estimate[r_row] ≈ fit.r atol = 1e-8
    @test isfinite(ci.se[r_row]) && ci.se[r_row] > 0
    if isfinite(ci.lower[r_row]) && isfinite(ci.upper[r_row])
        @test 0 < ci.lower[r_row] < ci.estimate[r_row] < ci.upper[r_row]
    end

    w = confint(fit, Y; method = :wald, parm = "beta[1]")
    @test w.term == ["beta[1]"]
    @test w.estimate[1] ≈ fit.β[1] atol = 1e-8
    @test isfinite(w.se[1])
end

@testset "R paired truncated_nbinom2 cell (live Δ, beta[] block)" begin
    if get(ENV, "GLLVM_PARITY_TESTS", "0") != "1"
        @test_skip "set GLLVM_PARITY_TESTS=1 with R + gllvmTMB for live second-order Δ"
    else
        using RCall
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "common.jl"))
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "cells.jl"))
        d = run_one_cell("truncated_nbinom2")
        @test get(d, "skip_reason", nothing) === nothing
        @test get(d, "parameterisation_gap", true) == false
        se_rel = d["se_max_relative_delta"]
        @test se_rel !== nothing && isfinite(se_rel)
    end
end
