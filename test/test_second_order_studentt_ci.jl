# StudentTFit fixed-ν Wald / profile wiring (second-order holdout clearance).
# Free / estimated ν stays OUT (contract §6). Bridge untouched.

using Test
using Random
using Distributions: TDist
using GLLVM

@testset "StudentTFit second-order Wald CI (fixed ν, shared σ)" begin
    Random.seed!(801)
    p, K, n = 5, 1, 160
    ν = 4.0
    β = 0.2 .* randn(p)
    Λ = 0.4 .* ones(p, K)
    σ = 0.55
    Y = Matrix{Float64}(undef, p, n)
    for s in 1:n
        η = β .+ Λ * randn(K)
        for t in 1:p
            Y[t, s] = η[t] + σ * rand(TDist(ν))
        end
    end
    fit = fit_studentt_gllvm(Y; K = K, nu = ν)
    @test fit isa StudentTFit
    @test fit.converged
    @test fit.estimated_nu === false
    @test fit.disp_group === :shared

    ci = confint(fit, Y; method = :wald)
    @test ci.method === :wald
    @test "sigma" in ci.term
    @test "beta[1]" in ci.term
    @test !any(startswith.(ci.term, "nu"))
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

    pr = confint(fit, Y; method = :profile, parm = "sigma")
    @test pr.method === :profile
    @test pr.term == ["sigma"]
    @test isfinite(pr.estimate[1])
end

@testset "StudentTFit second-order Wald CI (fixed ν, species σ)" begin
    Random.seed!(802)
    p, K, n = 4, 1, 140
    ν = 5.0
    β = 0.15 .* randn(p)
    Λ = 0.35 .* ones(p, K)
    σ = 0.4 .+ 0.1 .* rand(p)
    Y = Matrix{Float64}(undef, p, n)
    for s in 1:n
        η = β .+ Λ * randn(K)
        for t in 1:p
            Y[t, s] = η[t] + σ[t] * rand(TDist(ν))
        end
    end
    fit = fit_studentt_gllvm(Y; K = K, nu = ν, disp_group = :species)
    @test fit isa StudentTFit
    @test fit.disp_group === :species
    @test fit.estimated_nu === false

    ci = confint(fit, Y; method = :wald)
    @test ci.method === :wald
    @test "sigma[1]" in ci.term
    @test "sigma[$p]" in ci.term
    s1 = findfirst(==("sigma[1]"), ci.term)
    @test s1 !== nothing
    @test ci.estimate[s1] ≈ fit.σ[1] atol = 1e-8
    @test isfinite(ci.se[s1]) && ci.se[s1] > 0
end

@testset "StudentTFit free-ν Wald remains held out" begin
    Random.seed!(803)
    p, K, n = 4, 1, 80
    ν = 4.0
    β = 0.1 .* randn(p)
    Λ = 0.3 .* ones(p, K)
    σ = 0.5
    Y = Matrix{Float64}(undef, p, n)
    for s in 1:n
        η = β .+ Λ * randn(K)
        for t in 1:p
            Y[t, s] = η[t] + σ * rand(TDist(ν))
        end
    end
    fit = fit_studentt_gllvm(Y; K = K, nu = nothing, iterations = 80)
    @test fit.estimated_nu === true
    @test_throws ArgumentError confint(fit, Y; method = :wald)
end

@testset "R paired studentt_fixed_nu cell (live Δ, beta[] block)" begin
    if get(ENV, "GLLVM_PARITY_TESTS", "0") != "1"
        @test_skip "set GLLVM_PARITY_TESTS=1 with R + gllvmTMB for live second-order Δ"
    else
        using RCall
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "common.jl"))
        include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "cells.jl"))
        d = run_one_cell("studentt_fixed_nu")
        @test get(d, "skip_reason", nothing) === nothing
        @test get(d, "parameterisation_gap", true) == false
        se_rel = d["se_max_relative_delta"]
        @test se_rel !== nothing && isfinite(se_rel)
    end
end
