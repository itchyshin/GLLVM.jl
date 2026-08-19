# Truncated Poisson bridge, NO-X arm (twin fid 10).
#
# Engine (`fit_truncated_poisson_gllvm` / `TruncatedPoissonFit`) is already on
# main. This file pins the bridge admit: `bridge_fit(; family = "truncated_poisson")`
# matches the native fitter at 1e-8, and X / X_lv / mask / CI stay loud rejects.
# Support is y ≥ 1 strictly — zeros fail loud (no silent skip).
#
# Twin fence: light RCall Δ is still OWED. Do not invent a number here. Do not
# add a skipped "parity" test that looks like a live Δ.

using Test
using Random
using LinearAlgebra
using Distributions
using GLLVM

function _rtruncpois(μ)
    while true
        y = rand(Poisson(μ))
        y ≥ 1 && return y
    end
end

function _btp_sim(p, n, K; seed = 1)
    Random.seed!(seed)
    β = 0.3 .* randn(p) .+ 0.9
    Λ = 0.35 .* randn(p, K)
    Y = Matrix{Int}(undef, p, n)
    for s in 1:n
        z = randn(K)
        Λz = Λ * z
        for t in 1:p
            Y[t, s] = _rtruncpois(exp(β[t] + Λz[t]))
        end
    end
    return Y
end

@testset "truncated_poisson bridge (no-X, twin fid 10)" begin

    Y = _btp_sim(3, 40, 1; seed = 419)

    @testset "family key and list membership" begin
        @test GLLVM._bridge_family_key("truncated_poisson") == "truncated_poisson"
        @test GLLVM._bridge_family_key("Truncated_Poisson") == "truncated_poisson"
        @test GLLVM._bridge_family_key("TruncPois") == "truncated_poisson"
        @test "truncated_poisson" in GLLVM._BRIDGE_ONEPART_FAMILIES
        zib = findfirst(==("zib"), collect(GLLVM._BRIDGE_ONEPART_FAMILIES))
        tp = findfirst(==("truncated_poisson"), collect(GLLVM._BRIDGE_ONEPART_FAMILIES))
        @test tp == zib + 1
        @test tp == length(GLLVM._BRIDGE_ONEPART_FAMILIES)
        @test !("truncated_poisson" in GLLVM._BRIDGE_X_FAMILIES)
        @test !("truncated_poisson" in GLLVM._BRIDGE_XLV_FAMILIES)
        @test !("truncated_poisson" in GLLVM._BRIDGE_MASK_FAMILIES)
        @test "truncated_poisson" in GLLVM._BRIDGE_NO_CI_FAMILIES
        @test "truncated_poisson" in GLLVM._BRIDGE_NO_SCALAR_POSTFIT_FAMILIES
    end

    @testset "no-X point route matches fit_truncated_poisson_gllvm" begin
        oracle = fit_truncated_poisson_gllvm(Y; K = 1)
        br = bridge_fit(; y = Y, family = "truncated_poisson", d = 1)

        @test br.family == "truncated_poisson"
        @test br.model == "truncated_poisson_rr"
        @test br.families == fill("truncated_poisson", 3)
        @test br.d == 1
        @test br.n_traits == 3
        @test br.n_units == 40
        @test br.alpha ≈ oracle.β atol = 1e-8
        L = oracle.Λ * GLLVM._svd_rotation(oracle.Λ)
        @test br.loadings ≈ L atol = 1e-8
        @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
        @test br.df == 3 + GLLVM._bridge_rr_df(3, 1)
        @test all(isnan, br.dispersion)
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
        @test occursin("twin fid 10", br.note)
        @test occursin("light RCall Δ still OWED", br.note)
        @test occursin("not invented", br.note)
        @test !occursin("parity", lowercase(br.note))

        br_alias = bridge_fit(; y = Y, family = "TruncPois", d = 1)
        @test br_alias.family == "truncated_poisson"
        @test br_alias.loglik == br.loglik
    end

    @testset "no-X fences reject loudly" begin
        mask = trues(3, 40); mask[1, 1] = false
        X = ones(3, 40, 1)
        X_lv = randn(40, 1)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "truncated_poisson", d = 1,
                                              mask = mask)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "truncated_poisson", d = 1,
                                              X = X)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "truncated_poisson", d = 1,
                                              X_lv = X_lv)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "truncated_poisson", d = 1,
                                              options = Dict("ci_method" => "wald"))
        Yzero = copy(Y); Yzero[1, 1] = 0
        @test_throws ArgumentError bridge_fit(; y = Yzero, family = "truncated_poisson",
                                              d = 1)
        Yfrac = Float64.(Y); Yfrac[1, 1] = 0.4
        @test_throws ArgumentError bridge_fit(; y = Yfrac, family = "truncated_poisson",
                                              d = 1)
        @test_throws ArgumentError bridge_fit(; y = Y, family = fill("truncated_poisson", 3),
                                              d = 1)
    end
end
