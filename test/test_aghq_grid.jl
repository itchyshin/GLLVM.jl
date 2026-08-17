using GLLVM, Test, Random, Distributions, LinearAlgebra

@testset "AGHQ Stage-1a live-pin grid" begin

    @testset "k=1 is the Laplace point rule" begin
        nodes, w = GLLVM._aghq_gh_normal(1)
        @test nodes == [0.0]
        @test w == [1.0]
        for d in (1, 2, 3)
            g = GLLVM.aghq_grid(d, 1)
            @test size(g.nodes) == (1, d)
            @test g.nodes ≈ zeros(1, d) atol = 0
            @test length(g.logw) == 1
            @test g.logw[1] ≈ (d / 2) * log(2π) atol = 1e-15
            @test GLLVM.aghq_grid_ok(g)
        end
    end

    @testset "normalising identity Σ exp(logw) φ_d(u) = 1" begin
        for d in (1, 2, 3), k in (1, 3, 5)
            g = GLLVM.aghq_grid(d, k)
            @test size(g.nodes) == (k^d, d)
            @test GLLVM.aghq_grid_ok(g)
            log_phi = -0.5 .* sum(abs2, g.nodes; dims = 2) .- (d / 2) * log(2π)
            @test sum(exp.(g.logw .+ vec(log_phi))) ≈ 1 atol = 1e-12
            if k > 1
                w = exp.(g.logw .+ vec(log_phi))
                M = zeros(d, d)
                for j in axes(g.nodes, 1)
                    u = view(g.nodes, j, :)
                    M .+= w[j] .* (u * u')
                end
                @test M ≈ Matrix{Float64}(I, d, d) atol = 1e-6
            end
        end
    end

    @testset "probabilists' rule is not VA _gauss_hermite" begin
        # Physicists' (VA) vs probabilists' (live pin): different measure.
        x_phys, w_phys = GLLVM._gauss_hermite(3)
        x_prob, w_prob = GLLVM._aghq_gh_normal(3)
        @test !isapprox(x_phys, x_prob; atol = 1e-8)
        @test !isapprox(w_phys, w_prob; atol = 1e-8)
        @test sum(w_phys) ≈ sqrt(π) atol = 1e-12
        @test sum(w_prob) ≈ 1 atol = 1e-12
        # The two node sets are related by u = x √2, but the live pin must
        # not obtain that by calling _gauss_hermite.
        @test sort(x_prob) ≈ sort(x_phys .* sqrt(2)) atol = 1e-10
    end

    @testset "k=1 site loglik matches dense Laplace" begin
        Random.seed!(1708)
        p, K = 4, 2
        β = randn(p) .* 0.4 .+ 0.8
        Λ = 0.5 .* randn(p, K)
        y = [rand(Poisson(exp(β[t]))) for t in 1:p]
        n = ones(Int, p)
        link = GLLVM.LogLink()
        fam = Poisson()
        lap = GLLVM.laplace_loglik_site(fam, y, n, Λ, β, link)
        aghq = GLLVM.aghq_stage1a_loglik_site(fam, y, n, Λ, β, link; k = 1)
        @test isfinite(lap) && isfinite(aghq)
        @test aghq ≈ lap atol = 1e-12
    end

    @testset "k=1 marginal matches poisson Laplace" begin
        Random.seed!(1709)
        p, n, K = 4, 20, 2
        β = randn(p) .* 0.4 .+ 0.8
        Λ = 0.5 .* randn(p, K)
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, _ in 1:n]
        N = ones(Int, p, n)
        lap = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        aghq = GLLVM.aghq_stage1a_marginal_loglik(Poisson(), Y, N, Λ, β, GLLVM.LogLink(); k = 1)
        @test isfinite(lap) && isfinite(aghq)
        @test aghq ≈ lap atol = 1e-12
    end

    @testset "fail-loud: k≠1 and extra random structure" begin
        p, K = 3, 1
        β = zeros(p)
        Λ = ones(p, K)
        y = ones(Int, p)
        n = ones(Int, p)
        link = GLLVM.LogLink()
        fam = Poisson()
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 3)
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 1, row_effects = true)
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 1, phylo = true)
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 1, mi = true)
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 1, unique_latent = true)
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 1, s_B = ones(K))
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 1, use_lv_B = true)
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 1, multinomial = true)
        @test_throws ArgumentError GLLVM.aghq_grid(0, 3)
        @test_throws ArgumentError GLLVM.aghq_grid(1, 0)
    end
end
