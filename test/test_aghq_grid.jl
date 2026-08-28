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

    @testset "k>1 site evaluator exercises Liu–Pierce nodes" begin
        Random.seed!(1710)
        p, K = 4, 2
        β = randn(p) .* 0.4 .+ 0.8
        Λ = 0.5 .* randn(p, K)
        y = [rand(Poisson(exp(β[t]))) for t in 1:p]
        n = ones(Int, p)
        link = GLLVM.LogLink()
        fam = Poisson()
        ll1 = GLLVM.aghq_stage1a_loglik_site(fam, y, n, Λ, β, link; k = 1)
        ll3 = GLLVM.aghq_stage1a_loglik_site(fam, y, n, Λ, β, link; k = 3)
        @test isfinite(ll1) && isfinite(ll3)
        # Stage-1b: k>1 is the live node loop, not a Stage-1a throw.
        @test !isapprox(ll3, ll1; atol = 1e-10)
    end

    @testset "k=1 site loglik matches dense Laplace under each family's DEFAULT hessian" begin
        # Unpark Slice 0/1 (2026-08-28, docs/dev-log/decisions/2026-08-28-arc-decision-batch.md
        # gate 5): `aghq_stage1a_loglik_site` now threads `hessian::Symbol =
        # _default_hessian(family, link)` through the SAME role-separation contract
        # as `laplace_loglik_site` (Fisher-scored mode search; selectable adaptation
        # curvature). This is the required cross-check: for every family whose OWN
        # default Laplace fitter is `:observed` (the curvature-correction campaign,
        # 2026-08-25 through 2026-08-28 — Gamma, NegativeBinomial, Beta, NB1,
        # StudentTFamily, Exponential, TruncatedNegBin2, TweedieED, Binomial/probit),
        # the AGHQ k=1 template must equal that family's default dense Laplace
        # marginal, not silently diverge onto the previously-hardcoded Fisher weight.
        Random.seed!(20260828)
        p, K = 5, 1
        β = randn(p) .* 0.3 .+ 0.5
        Λ = 0.4 .* randn(p, K)

        cases = (
            (fam = Gamma(3.0, 1.0), link = GLLVM.LogLink(),
             y = 0.4 .+ rand(p), n = ones(Int, p)),
            (fam = NegativeBinomial(4.0, 0.5), link = GLLVM.LogLink(),
             y = Float64.(rand(0:8, p)), n = ones(Int, p)),
            (fam = Beta(8.0, 1.0), link = GLLVM.LogitLink(),
             y = clamp.(rand(p), 0.02, 0.98), n = ones(Int, p)),
            (fam = GLLVM.NB1(1.5), link = GLLVM.LogLink(),
             y = Float64.(rand(0:8, p)), n = ones(Int, p)),
            (fam = GLLVM.StudentTFamily(4.0, 1.0), link = GLLVM.IdentityLink(),
             y = randn(p), n = ones(Int, p)),
            (fam = Exponential(1.0), link = GLLVM.LogLink(),
             y = 0.3 .+ rand(p), n = ones(Int, p)),
            (fam = GLLVM.TruncatedNegBin2(), link = GLLVM.LogLink(),
             y = Float64.(rand(1:8, p)), n = ones(Int, p)),
            (fam = GLLVM.TweedieED(1.2, 1.5), link = GLLVM.LogLink(),
             y = [rand() < 0.3 ? 0.0 : 0.2 + 2 * rand() for _ in 1:p], n = ones(Int, p)),
            (fam = Binomial(), link = GLLVM.ProbitLink(),
             y = Float64.(rand(0:6, p)), n = fill(6, p)),
        )

        for c in cases
            @test GLLVM._default_hessian(c.fam, c.link) === :observed
            lap  = GLLVM.laplace_loglik_site(c.fam, c.y, c.n, Λ, β, c.link)
            aghq = GLLVM.aghq_stage1a_loglik_site(c.fam, c.y, c.n, Λ, β, c.link; k = 1)
            @test isfinite(lap) && isfinite(aghq)
            @test aghq ≈ lap atol = 1e-10
        end
    end

    @testset "fail-loud: extra random structure (loadings-only z_B)" begin
        p, K = 3, 1
        β = zeros(p)
        Λ = ones(p, K)
        y = ones(Int, p)
        n = ones(Int, p)
        link = GLLVM.LogLink()
        fam = Poisson()
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
