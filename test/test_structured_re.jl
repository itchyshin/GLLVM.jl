using GLLVM, Test, Random, LinearAlgebra, Statistics, ForwardDiff

# Structured grouped random intercept (SP1.2/SP3): a level effect u ~ N(0, σ_u²·C) on a
# grouping factor, C = the L×L group covariance (iid / animal / phylo / spatial). Marginal
# is a rank-L Woodbury that reduces to the iid grouped intercept when C = I.

@testset "Structured grouped RE (animal/phylo/spatial)" begin

    @testset "C = I reduces to the iid grouped intercept (rtol 1e-8)" begin
        Random.seed!(60001)
        p, K, n = 5, 1, 60
        Λ = 0.6 .* randn(p, K); σ_eps, σ_u = 0.5, 0.7
        grouping = rand(1:6, n)
        y = randn(p, n)
        codes, _ = GLLVM._code_grouping(grouping); L = maximum(codes)
        gi = [findall(==(g), codes) for g in 1:L]
        ll_struct = GLLVM._structured_grouped_loglik(y, gi, Λ, σ_eps, σ_u^2 .* Matrix{Float64}(I, L, L))
        ll_iid = GLLVM._grouped_intercept_loglik(y, gi, Λ, σ_eps, σ_u)
        @test isapprox(ll_struct, ll_iid; rtol = 1e-8)   # the Woodbury reduces to the per-group method
    end

    @testset "structured recovery (AR1 correlation among groups)" begin
        Random.seed!(60002)
        p, K, n, L = 6, 2, 500, 10
        Λt = 0.6 .* randn(p, K); σ_eps, σ_u = 0.5, 0.8
        C = [0.6^abs(a - b) for a in 1:L, b in 1:L]                 # AR1 among groups (SPD)
        u = σ_u .* (cholesky(Symmetric(C)).L * randn(L))           # u ~ N(0, σ_u²·C)
        grouping = vcat(collect(1:L), rand(1:L, n - L))            # ⇒ codes = identity, C aligned
        y = Λt * randn(K, n) .+ [u[grouping[i]] for t in 1:p, i in 1:n] .+ σ_eps .* randn(p, n)
        fit = fit_gaussian_structured_re(y, grouping, C; K = K)
        @test fit.converged
        @test isapprox(fit.σ_eps, σ_eps; atol = 0.15)
        @test fit.σ_u > 0.3 && fit.σ_u < 1.6                       # recovers a non-trivial group SD
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λt * Λt')) > 0.8
    end

    @testset "FD-gradient of the structured nll ≤ 1e-6" begin
        Random.seed!(60003)
        p, K, n, L = 4, 1, 50, 5
        Λ0 = 0.5 .* randn(p, K)
        C = [0.5^abs(a - b) for a in 1:L, b in 1:L]
        grouping = vcat(collect(1:L), rand(1:L, n - L)); y = randn(p, n)
        codes, _ = GLLVM._code_grouping(grouping)
        gi = [findall(==(g), codes) for g in 1:maximum(codes)]
        rr = GLLVM.rr_theta_len(p, K)
        f = θ -> -GLLVM._structured_grouped_loglik(y, gi, GLLVM.unpack_lambda(θ[1:rr], p, K),
            exp(θ[rr + 1]), (exp(θ[rr + 2])^2) .* C)
        θ = vcat(GLLVM.pack_lambda(Λ0), log(0.5), log(0.7))
        gad = ForwardDiff.gradient(f, θ); h = 1e-6; gfd = similar(θ)
        for i in eachindex(θ)
            s = h * max(1.0, abs(θ[i])); tp = copy(θ); tp[i] += s; tm = copy(θ); tm[i] -= s
            gfd[i] = (f(tp) - f(tm)) / (2s)
        end
        @test all(isfinite, gad)
        @test maximum(abs.(gad .- gfd)) ≤ 1e-6
    end
end
