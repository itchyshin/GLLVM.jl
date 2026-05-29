using GLLVM, Test, Random, LinearAlgebra, Distributions

@testset "likelihood" begin
    @testset "matches direct MvNormal log-pdf" begin
        Random.seed!(123)
        p, K, n = 4, 2, 30
        Λ = randn(p, K)
        # Enforce lower-triangular structure on the top K rows (canonical RR form)
        for i in 1:K, k in 1:K
            if i < k
                Λ[i, k] = 0
            end
        end
        σ = 0.7
        Σ_y = Λ * Λ' + σ^2 * I
        d   = MvNormal(zeros(p), Symmetric(Σ_y))
        y   = rand(d, n)                 # p × n
        # direct:
        ll_direct = sum(logpdf(d, y[:, s]) for s in 1:n)
        # ours:
        ll_ours   = GLLVM.gaussian_marginal_loglik(y, Λ, σ)
        @test ll_ours ≈ ll_direct rtol=1e-10
    end

    @testset "scales correctly with σ → large" begin
        # As σ grows, Σ_y ≈ σ² I and loglik should approach Gaussian iid noise
        Random.seed!(2)
        p, K, n = 3, 1, 10
        Λ = reshape([0.1, 0.0, 0.0], p, K)
        y = randn(p, n)
        ll_big = GLLVM.gaussian_marginal_loglik(y, Λ, 100.0)
        ll_iid = sum(logpdf(Normal(0.0, 100.0), y[i, s]) for i in 1:p, s in 1:n)
        @test ll_big ≈ ll_iid rtol=1e-3
    end

    @testset "AD-friendly" begin
        using ForwardDiff
        Random.seed!(3)
        p_local, K_local, n = 5, 2, 20
        Λ = randn(p_local, K_local)
        for i in 1:K_local, k in 1:K_local
            if i < k
                Λ[i, k] = 0
            end
        end
        σ = 0.5
        y = randn(p_local, n)
        params = [log(σ); GLLVM.pack_lambda(Λ)]
        g = ForwardDiff.gradient(prm -> GLLVM.gaussian_nll_packed(prm, y, p_local, K_local), params)
        @test all(isfinite, g)
        @test length(g) == 1 + GLLVM.rr_theta_len(p_local, K_local)
    end
end
