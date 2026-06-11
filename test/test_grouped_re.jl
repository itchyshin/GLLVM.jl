using GLLVM, Test, Random, LinearAlgebra, Statistics, ForwardDiff
using Distributions: MvNormal, logpdf

# SP1.2 engine: grouped Gaussian random intercept (1|g). A shared u_g ~ N(0,σ_u²) for
# every site in a group ⇒ cross-site correlation WITHIN a group. Marginal covariance
# Σ = kron(I_n, A) + kron(G, B), A = ΛΛ'+σ_eps²I, B = σ_u²·11', G[i,j]=1{g(i)=g(j)}.
# Verified against the dense MvNormal. (Engine is syntax-agnostic; the public API naming
# — latent/indep/dep + specific — is still under design, so nothing is exported here.)

@testset "Grouped Gaussian random intercept (SP1.2 engine)" begin

    @testset "matches dense kron(I,A)+kron(G,B) (rtol 1e-9)" begin
        Random.seed!(33001)
        p, K, n = 4, 1, 24
        Λ = 0.6 .* randn(p, K); σ_eps = 0.5; σ_u = 0.7
        grouping = repeat(1:6, inner = 4)                 # 6 groups of 4
        y = randn(p, n)
        A = Λ * Λ' + σ_eps^2 * I
        B = σ_u^2 .* ones(p, p)
        G = [grouping[i] == grouping[j] ? 1.0 : 0.0 for i in 1:n, j in 1:n]
        Σ = kron(I(n), A) + kron(G, B)
        ll_dense = logpdf(MvNormal(zeros(p * n), Symmetric(Matrix(Σ))), vec(y))
        ll_ours = GLLVM.gaussian_grouped_intercept_loglik(y, grouping, Λ, σ_eps, σ_u)
        @test isapprox(ll_ours, ll_dense; rtol = 1e-9)
    end

    @testset "singleton groups reduce to the per-site row effect (rtol 1e-9)" begin
        Random.seed!(33002)
        p, K, n = 5, 2, 30
        Λ = 0.5 .* randn(p, K); σ_eps = 0.6; σ_u = 0.4
        y = randn(p, n)
        ll_grouped = GLLVM.gaussian_grouped_intercept_loglik(y, collect(1:n), Λ, σ_eps, σ_u)
        ll_rowre = GLLVM.gaussian_marginal_loglik(y, hcat(Λ, σ_u .* ones(p)), σ_eps)
        @test isapprox(ll_grouped, ll_rowre; rtol = 1e-9)
    end

    @testset "recovery (σ_u, σ_eps, ΛΛ')" begin
        Random.seed!(33003)
        p, K, ng, sz = 6, 1, 40, 5
        Λt = 0.6 .* randn(p, K); σ_eps = 0.5; σ_u = 0.8
        n = ng * sz
        grouping = repeat(1:ng, inner = sz)
        y = Matrix{Float64}(undef, p, n)
        for g in 1:ng
            u = σ_u * randn()
            for s in ((g - 1) * sz + 1):(g * sz)
                y[:, s] = Λt * randn(K) .+ u .+ σ_eps .* randn(p)
            end
        end
        fit = GLLVM.fit_gaussian_grouped_re(y, grouping; K = K)
        @test fit.converged
        @test isapprox(fit.σ_u, σ_u; atol = 0.25)
        @test isapprox(fit.σ_eps, σ_eps; atol = 0.1)
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λt * Λt')) > 0.8
    end

    @testset "FD-gradient ≤ 1e-6" begin
        Random.seed!(33004)
        p, K, n = 4, 1, 20
        Λ0 = 0.5 .* randn(p, K); σ_eps = 0.6; σ_u = 0.5
        grouping = repeat(1:5, inner = 4)
        y = randn(p, n)
        rr = GLLVM.rr_theta_len(p, K)
        f = θ -> -GLLVM.gaussian_grouped_intercept_loglik(y, grouping,
            GLLVM.unpack_lambda(θ[1:rr], p, K), exp(θ[rr + 1]), exp(θ[rr + 2]))
        θ = vcat(GLLVM.pack_lambda(Λ0), log(σ_eps), log(σ_u))
        gad = ForwardDiff.gradient(f, θ); h = 1e-6; gfd = similar(θ)
        for i in eachindex(θ)
            s = h * max(1.0, abs(θ[i])); tp = copy(θ); tp[i] += s; tm = copy(θ); tm[i] -= s
            gfd[i] = (f(tp) - f(tm)) / (2s)
        end
        @test all(isfinite, gad)
        @test maximum(abs.(gad .- gfd)) ≤ 1e-6
    end
end
