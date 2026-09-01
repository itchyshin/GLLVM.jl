# nobs(fit) p·n cell-count convention for the struct-count-carrying fits
# (no response matrix stored on the struct) — TwoLevelFit, GaussianRandomSlopeFit,
# PoissonRandomSlopeFit, RowEffectFit, SPDELatentFit, and SPDEGaussianFit (p = 1,
# unchanged).
#
# docs/dev-log/decisions/2026-09-01-maintainer-decisions-round1.md #1: adopt
# R's p·n observed-cell nobs convention (matching gllvmTMB_multi's is_y_observed
# count), not the number of sites/individuals/groups alone. These fits store
# only the unit count (nindiv/nlevels/nodes/ρ), so `nobs(fit)` must multiply
# that stored count by `p` (the number of rows of the fit's loadings matrix)
# to match the same convention used by `nobs(fit, Y)`.
#
# Structs are built directly (not via a real optimizer fit) — only the field
# values `nobs` reads are exercised, so this is a fast, deterministic check of
# the formula, independent of optimizer convergence.

using GLLVM, Test, Distributions, LinearAlgebra
using GLLVM: StatsAPI

@testset "nobs(fit) — p·n cell-count convention (struct-count fits)" begin
    @testset "TwoLevelFit" begin
        p, K_B, K_W, nindiv = 5, 2, 1, 37
        fit = GLLVM.TwoLevelFit(
            randn(p, K_B), rand(p) .+ 0.1, randn(p, K_W), rand(p) .+ 0.1,
            Matrix{Float64}(I, p, p), Matrix{Float64}(I, p, p),
            nindiv, -123.4, true, 10)
        @test StatsAPI.nobs(fit) == p * nindiv
        @test StatsAPI.nobs(fit) != nindiv   # the old (pre-decision) convention
    end

    @testset "GaussianRandomSlopeFit" begin
        p, K, q, nlevels = 4, 1, 2, 21
        fit = GLLVM.GaussianRandomSlopeFit(
            randn(p, K), 0.5, Matrix{Float64}(I, q, q), nlevels, q,
            -50.0, true, 5)
        @test StatsAPI.nobs(fit) == p * nlevels
        @test StatsAPI.nobs(fit) != nlevels
    end

    @testset "PoissonRandomSlopeFit" begin
        p, K, q, nlevels = 3, 1, 2, 15
        fit = GLLVM.PoissonRandomSlopeFit(
            zeros(p), randn(p, K), Matrix{Float64}(I, q, q), nlevels, q,
            GLLVM.LogLink(), -80.0, true, 5)
        @test StatsAPI.nobs(fit) == p * nlevels
        @test StatsAPI.nobs(fit) != nlevels
    end

    @testset "RowEffectFit" begin
        p, K, nsite = 6, 1, 40
        fit = GLLVM.RowEffectFit(
            Poisson(), zeros(p), zeros(nsite), randn(p, K), NaN,
            GLLVM.LogLink(), -200.0, true, 5)
        @test StatsAPI.nobs(fit) == p * nsite
        @test StatsAPI.nobs(fit) != nsite
    end

    @testset "SPDELatentFit" begin
        p, K, nnodes = 3, 1, 25
        fit = GLLVM.SPDELatentFit(
            zeros(p), randn(p, K), 1.0, 1.0, NaN, GLLVM.LogLink(), Poisson(),
            -90.0, true, 5, zeros(nnodes, 2), zeros(Int, 1, 3))
        @test StatsAPI.nobs(fit) == p * nnodes
        @test StatsAPI.nobs(fit) != nnodes
    end

    @testset "SPDEGaussianFit — univariate (p = 1), unchanged" begin
        nnodes = 12
        fit = GLLVM.SPDEGaussianFit(
            1.0, 1.0, 0.5, 0.0, -30.0, true, 5, zeros(nnodes, 2), zeros(Int, 1, 3))
        @test StatsAPI.nobs(fit) == nnodes   # p = 1, so unchanged from before
    end
end
