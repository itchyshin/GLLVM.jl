# Lognormal bridge, NO-X arm (twin fid 3).
#
# Engine (`fit_lognormal_gllvm` / `LognormalFit`) is already on main. This file
# pins the bridge admit: `bridge_fit(; family = "lognormal")` matches the native
# fitter at 1e-8, and X / X_lv / mask / CI stay loud rejects.
#
# Twin fence: light RCall Δ is still OWED. Do not invent a number here. Skip any
# live Δ unless `ENV["GLLVM_PARITY_TESTS"] == "1"` and a real paired cell runs.

using Test
using Random
using LinearAlgebra
using GLLVM

function _bln_sim(p, n, K; seed = 1)
    Random.seed!(seed)
    β = 0.4 .* randn(p) .+ 0.3
    Λ = 0.35 .* randn(p, K)
    σ = 0.25
    Z = randn(K, n)
    ΛZ = Λ * Z
    Y = Matrix{Float64}(undef, p, n)
    for t in 1:p, s in 1:n
        Y[t, s] = exp(β[t] + ΛZ[t, s] + σ * randn())
    end
    return Y
end

@testset "lognormal bridge (no-X, twin fid 3)" begin

    Y = _bln_sim(3, 40, 1; seed = 318)

    @testset "family key and list membership" begin
        @test GLLVM._bridge_family_key("lognormal") == "lognormal"
        @test GLLVM._bridge_family_key("Lognormal") == "lognormal"
        @test "lognormal" in GLLVM._BRIDGE_ONEPART_FAMILIES
        pois = findfirst(==("poisson"), collect(GLLVM._BRIDGE_ONEPART_FAMILIES))
        binom = findfirst(==("binomial"), collect(GLLVM._BRIDGE_ONEPART_FAMILIES))
        ln = findfirst(==("lognormal"), collect(GLLVM._BRIDGE_ONEPART_FAMILIES))
        @test ln == pois + 1
        @test ln == binom - 1
        @test !("lognormal" in GLLVM._BRIDGE_X_FAMILIES)
        @test !("lognormal" in GLLVM._BRIDGE_XLV_FAMILIES)
        @test !("lognormal" in GLLVM._BRIDGE_MASK_FAMILIES)
        @test "lognormal" in GLLVM._BRIDGE_NO_CI_FAMILIES
        @test "lognormal" in GLLVM._BRIDGE_NO_SCALAR_POSTFIT_FAMILIES
    end

    @testset "no-X point route matches fit_lognormal_gllvm" begin
        oracle = fit_lognormal_gllvm(Y; K = 1)
        br = bridge_fit(; y = Y, family = "lognormal", d = 1)

        @test br.family == "lognormal"
        @test br.model == "lognormal_rr"
        @test br.families == fill("lognormal", 3)
        @test br.d == 1
        @test br.n_traits == 3
        @test br.n_units == 40
        @test br.alpha ≈ oracle.β atol = 1e-8
        L = oracle.Λ * GLLVM._svd_rotation(oracle.Λ)
        @test br.loadings ≈ L atol = 1e-8
        @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
        @test br.df == 3 + GLLVM._bridge_rr_df(3, 1) + 1
        @test br.dispersion ≈ fill(oracle.σ, 3) atol = 1e-8
        @test isnan(br.sigma_eps)
        @test br.link == fill("LogLink", 3)
        @test size(br.Sigma) == (3, 3)
        @test size(br.correlation) == (3, 3)
        @test br.correlation ≈ br.correlation' atol = 1e-10
        @test all(isapprox(1.0), diag(br.correlation))
        @test br.communality == ones(3)
        @test size(br.scores) == (0, 0)
        @test br.converged isa Bool
        @test br.nobs == 120
        @test occursin("twin fid 3", br.note)
        @test occursin("light RCall Δ still OWED", br.note)
        @test occursin("not invented", br.note)
        @test !occursin("parity", lowercase(br.note))

        br_alias = bridge_fit(; y = Y, family = "Lognormal", d = 1)
        @test br_alias.family == "lognormal"
        @test br_alias.loglik == br.loglik
    end

    @testset "no-X fences reject loudly" begin
        mask = trues(3, 40); mask[1, 1] = false
        X = ones(3, 40, 1)
        X_lv = randn(40, 1)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "lognormal", d = 1,
                                              mask = mask)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "lognormal", d = 1,
                                              X = X)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "lognormal", d = 1,
                                              X_lv = X_lv)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "lognormal", d = 1,
                                              options = Dict("ci_method" => "wald"))
        Ybad = copy(Y); Ybad[1, 1] = 0.0
        @test_throws ArgumentError bridge_fit(; y = Ybad, family = "lognormal", d = 1)
        @test_throws ArgumentError bridge_fit(; y = Y, family = fill("lognormal", 3),
                                              d = 1)
    end
end
