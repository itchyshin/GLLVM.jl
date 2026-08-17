using GLLVM, Test, Random, Distributions, LinearAlgebra

# Independent Hopper A4(2) reconstruction (no √2):
#   z_ij = ẑᵢ + Lᵢ^{-T} uⱼ
#   log Lᵢ = −½ logdet Aᵢ + logsumexpⱼ(logwⱼ + inner_ll(i,j))
# inner_ll = ℓ − ½ z′z − (d/2) log(2π). Not a public aghq= surface.
function _liu_pierce_site_golden(family, y, n, Λ, β, link; k::Integer,
        scale::Float64 = 1.0)
    d = size(Λ, 2)
    p = size(Λ, 1)
    grid = GLLVM.aghq_grid(d, k)
    z = GLLVM._laplace_mode(family, y, n, Λ, β, link)
    Λz = Λ * z
    η = GLLVM._clamp_eta.(β .+ Λz)
    μ = GLLVM._clamp_mu.(Ref(family), GLLVM.linkinv.(Ref(link), η))
    me = GLLVM.mu_eta.(Ref(link), η)
    W = GLLVM._glm_weight.(Ref(family), μ, n, me)
    Amat = Λ' * (W .* Λ)
    @inbounds for i in 1:d
        Amat[i, i] += 1.0
    end
    A = Symmetric(Amat)
    logdet_i = -0.5 * logdet(A)
    R = cholesky(A).U
    half_log2π = (d / 2) * log(2π)
    ngrid = size(grid.nodes, 1)
    terms = Vector{Float64}(undef, ngrid)
    @inbounds for j in 1:ngrid
        zj = z + scale .* (R \ view(grid.nodes, j, :))
        Λzj = Λ * zj
        ηj = GLLVM._clamp_eta.(β .+ Λzj)
        μj = GLLVM._clamp_mu.(Ref(family), GLLVM.linkinv.(Ref(link), ηj))
        ℓj = 0.0
        for t in 1:p
            ℓj += GLLVM._glm_logpdf(family, μj[t], n[t], y[t])
        end
        inner_ll = ℓj - 0.5 * dot(zj, zj) - half_log2π
        terms[j] = grid.logw[j] + inner_ll
    end
    m = maximum(terms)
    return logdet_i + (m + log(sum(exp.(terms .- m))))
end

@testset "AGHQ Stage-1b Liu–Pierce adaptation" begin

    @testset "k=1 template still matches dense Laplace" begin
        Random.seed!(1711)
        p, K = 4, 2
        β = randn(p) .* 0.4 .+ 0.8
        Λ = 0.5 .* randn(p, K)
        y = [rand(Poisson(exp(β[t]))) for t in 1:p]
        n = ones(Int, p)
        link = GLLVM.LogLink()
        fam = Poisson()
        lap = GLLVM.laplace_loglik_site(fam, y, n, Λ, β, link)
        aghq = GLLVM.aghq_stage1a_loglik_site(fam, y, n, Λ, β, link; k = 1)
        gold = _liu_pierce_site_golden(fam, y, n, Λ, β, link; k = 1)
        @test isfinite(lap) && isfinite(aghq) && isfinite(gold)
        @test aghq ≈ lap atol = 1e-12
        @test aghq ≈ gold atol = 1e-12
    end

    @testset "k>1 matches independent Liu–Pierce golden (no √2)" begin
        Random.seed!(1712)
        p, K = 4, 2
        β = randn(p) .* 0.4 .+ 0.8
        Λ = 0.5 .* randn(p, K)
        y = [rand(Poisson(exp(β[t]))) for t in 1:p]
        n = ones(Int, p)
        link = GLLVM.LogLink()
        fam = Poisson()
        ll1 = GLLVM.aghq_stage1a_loglik_site(fam, y, n, Λ, β, link; k = 1)
        ll3 = GLLVM.aghq_stage1a_loglik_site(fam, y, n, Λ, β, link; k = 3)
        gold = _liu_pierce_site_golden(fam, y, n, Λ, β, link; k = 3)
        wrong = _liu_pierce_site_golden(fam, y, n, Λ, β, link; k = 3,
                                        scale = sqrt(2))
        @test isfinite(ll3) && isfinite(gold)
        @test ll3 ≈ gold atol = 1e-12
        @test !isapprox(ll3, ll1; atol = 1e-10)
        @test !isapprox(ll3, wrong; atol = 1e-8)
        g = GLLVM.aghq_grid(K, 3)
        @test size(g.nodes, 1) == 3^K
    end

    @testset "k=1 marginal still matches poisson Laplace" begin
        Random.seed!(1713)
        p, n, K = 4, 12, 2
        β = randn(p) .* 0.4 .+ 0.8
        Λ = 0.5 .* randn(p, K)
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, _ in 1:n]
        N = ones(Int, p, n)
        lap = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        aghq = GLLVM.aghq_stage1a_marginal_loglik(Poisson(), Y, N, Λ, β,
                                                  GLLVM.LogLink(); k = 1)
        @test isfinite(lap) && isfinite(aghq)
        @test aghq ≈ lap atol = 1e-12
    end

    @testset "fail-loud: non loadings-only z_B" begin
        p, K = 3, 1
        β = zeros(p)
        Λ = ones(p, K)
        y = ones(Int, p)
        n = ones(Int, p)
        link = GLLVM.LogLink()
        fam = Poisson()
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 3, row_effects = true)
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 3, phylo = true)
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 3, mi = true)
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 3, unique_latent = true)
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 3, s_B = ones(K))
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 3, use_lv_B = true)
        @test_throws ArgumentError GLLVM.aghq_stage1a_loglik_site(
            fam, y, n, Λ, β, link; k = 3, multinomial = true)
    end
end
