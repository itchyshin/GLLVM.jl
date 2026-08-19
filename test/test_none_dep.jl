using GLLVM
using Test
using Random
using LinearAlgebra
using Distributions

using GLLVM: rr_theta_len, pack_lambda, unpack_lambda, init_theta_rr
const ForwardDiff = GLLVM.ForwardDiff

@testset "none × dep matrix fitter" begin
    @testset "free count is p(p+1)/2 at K = p" begin
        for p in (2, 3, 4, 7)
            @test rr_theta_len(p, p) == p * (p + 1) ÷ 2
            θ = init_theta_rr(p, p)
            @test length(θ) == p * (p + 1) ÷ 2
            Λ = unpack_lambda(θ, p, p)
            @test size(Λ) == (p, p)
            @test istril(Λ)
            @test pack_lambda(Λ) ≈ θ atol = 1e-14
        end
    end

    @testset "packed L FD ≤ 1e-6 at K = p" begin
        Random.seed!(18)
        p, n = 3, 24
        K = p
        θ = init_theta_rr(p, K)
        θ[1:K] .+= 0.15
        θ[(K + 1):end] .= 0.05 .* randn(length(θ) - K)
        y = randn(p, n)
        params = [log(0.6); θ]
        nll = prm -> GLLVM.gaussian_nll_packed(prm, y, p, K)
        g_ad = ForwardDiff.gradient(nll, params)
        ε = 1e-5
        g_fd = similar(params)
        for i in eachindex(params)
            pp = copy(params); pm = copy(params)
            pp[i] += ε; pm[i] -= ε
            g_fd[i] = (nll(pp) - nll(pm)) / (2ε)
        end
        @test maximum(abs.(g_ad .- g_fd)) ≤ 1e-6
    end

    @testset "fit_dep_gllvm matches latent K = p to 1e-8" begin
        Random.seed!(19)
        p, n = 3, 40
        Λ = unpack_lambda(init_theta_rr(p, p), p, p)
        η = randn(p, n)
        y = Λ * η + 0.4 .* randn(p, n)

        fit_dep = fit_dep_gllvm(y; family = Normal())
        fit_lat = fit_gaussian_gllvm(y; K = p)
        @test fit_dep isa GllvmFit
        @test fit_dep.model.K == p
        @test size(fit_dep.pars.Λ) == (p, p)
        @test length(pack_lambda(fit_dep.pars.Λ)) == p * (p + 1) ÷ 2
        @test isfinite(fit_dep.logLik)
        @test fit_dep.logLik ≈ fit_lat.logLik atol = 1e-8
        @test pack_lambda(fit_dep.pars.Λ) ≈ pack_lambda(fit_lat.pars.Λ) atol = 1e-8
        Σ = fit_dep.pars.Λ * fit_dep.pars.Λ'
        @test issymmetric(Σ)
        @test minimum(eigvals(Symmetric(Σ))) ≥ -1e-10
    end

    @testset "fail-loud on K, num_lv, W-tier, has_diag, phylo" begin
        Random.seed!(20)
        y = randn(3, 20)
        @test_throws ArgumentError fit_dep_gllvm(y; K = 3)
        @test_throws ArgumentError fit_dep_gllvm(y; K = 1)
        @test_throws ArgumentError fit_dep_gllvm(y; num_lv = 3)
        @test_throws ArgumentError fit_dep_gllvm(y; K_W = 1)
        @test_throws ArgumentError fit_dep_gllvm(y; has_diag = true)
        @test_throws ArgumentError fit_dep_gllvm(y; K_phy = 1)
        @test_throws ArgumentError fit_dep_gllvm(y; has_phy_unique = true)
        @test_throws ArgumentError fit_dep_gllvm(y; Σ_phy = Matrix{Float64}(I, 3, 3))
        @test_throws ArgumentError fit_dep_gllvm(y; family = Poisson())
    end
end
