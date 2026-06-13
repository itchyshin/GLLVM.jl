using GLLVM, Test, LinearAlgebra, Random, Statistics, ForwardDiff

# Phylogenetic missing-predictor FIML (the mi() axis, design Phase 3 — the
# high-value evolutionary feature). A species-level continuous predictor x
# (length p, one value per species/row, may be `missing`) with a phylogenetic
# prior x ~ N(α 1, σ_x² A) enters the response with a global intercept and slope:
#   y[t,s] = a + b_x x_t + Λ η_s + ε_s
# (A *global* intercept — a per-species one would confound with x_t.) Missing
# x_t are integrated out in CLOSED FORM (marginal reduces to the engine's
# I_n⊗Σ_R + J_n⊗(b_x² Ṽ) form plus the x_obs prior). Borrows phylo information
# across related species — NOT impute-then-analyse.
@testset "fit_gaussian_mi_phylo (phylo missing-predictor FIML)" begin
    decay(p, d) = [exp(-d * abs(i - j)) for i in 1:p, j in 1:p]

    function simulate(; p = 6, n = 80, K = 1, a, b_x, α, σ_x, σ_eps, Λ, A, seed = 1)
        Random.seed!(seed)
        x = α .+ σ_x .* (cholesky(Symmetric(A)).L * randn(p))
        η = randn(K, n)
        y = a .+ b_x .* x .+ Λ * η .+ σ_eps .* randn(p, n)
        return collect(y), collect(x)
    end

    @testset "complete-data equivalence with fit_gaussian_gllvm" begin
        p, n, K = 6, 120, 1
        A = decay(p, 0.4)
        b_x = 0.8
        Λ = reshape([0.7, 0.5, -0.4, 0.3, 0.2, -0.3], p, K)
        y, x = simulate(; p, n, K, a = 0.5, b_x, α = 0.4, σ_x = 0.7, σ_eps = 0.3, Λ, A, seed = 7)

        # ordinary fit: global intercept (ones) + per-species x covariate (X[t,s]=x_t)
        Xfull = zeros(p, n, 2)
        Xfull[:, :, 1] .= 1.0
        for t in 1:p
            Xfull[t, :, 2] .= x[t]
        end
        fit_g = fit_gaussian_gllvm(y; K = K, X = Xfull)
        a_g, b_x_g = fit_g.pars.β[1], fit_g.pars.β[2]

        res = fit_gaussian_mi_phylo(y, x, A; K = K)
        @test res.converged
        @test res.b_x ≈ b_x_g atol = 1e-2
        @test res.a ≈ a_g atol = 1e-2
    end

    @testset "recovers b_x on complete data (smoke)" begin
        p, n, K = 8, 200, 1
        A = decay(p, 0.4)
        b_x = 1.0
        Λ = reshape([0.6, 0.5, -0.4, 0.3, 0.2, -0.3, 0.35, -0.25], p, K)
        y, x = simulate(; p, n, K, a = 0.0, b_x, α = 0.3, σ_x = 0.8, σ_eps = 0.3, Λ, A, seed = 3)
        res = fit_gaussian_mi_phylo(y, x, A; K = K)
        @test abs(res.b_x - b_x) < 0.2
    end

    @testset "fits with missing species-x and EBLUP borrows phylo info" begin
        p, n, K = 8, 160, 1
        A = decay(p, 0.5)
        b_x = 0.9
        Λ = reshape([0.6, 0.5, -0.4, 0.3, 0.2, -0.3, 0.4, -0.2], p, K)
        y, x = simulate(; p, n, K, a = 0.0, b_x, α = 0.3, σ_x = 0.9, σ_eps = 0.3, Λ, A, seed = 5)
        miss = [2, 5, 7]
        xtrue = x[miss]
        xm = Vector{Union{Missing,Float64}}(x)
        xm[miss] .= missing
        res = fit_gaussian_mi_phylo(y, xm, A; K = K)
        @test res.converged
        @test length(res.eblup_x) == p
        @test res.eblup_x[setdiff(1:p, miss)] ≈ x[setdiff(1:p, miss)]   # observed unchanged
        @test cor(res.eblup_x[miss], xtrue) > 0.4                        # EBLUPs track truth
    end

    @testset "packed NLL is AD-clean (ForwardDiff vs central FD ≤ 1e-6)" begin
        p, n, K = 6, 40, 1
        A = decay(p, 0.4)
        Λ = reshape([0.6, 0.5, -0.4, 0.3, 0.2, -0.3], p, K)
        y, x = simulate(; p, n, K, a = 0.2, b_x = 0.8, α = 0.3, σ_x = 0.7, σ_eps = 0.3, Λ, A, seed = 2)
        obs = [1, 2, 4, 6]
        mis = [3, 5]
        xo = x[obs]
        pc = GLLVM._mi_phylo_precompute(A, obs, mis)
        f(θ) = GLLVM._mi_phylo_nll(θ, y, xo, obs, mis, pc, p, n, K)
        θ = vcat(0.2, 0.8, 0.3, log(0.7), log(0.3), vec(Λ))
        g_ad = ForwardDiff.gradient(f, θ)
        h = 1e-6
        g_fd = similar(θ)
        for i in eachindex(θ)
            θp = copy(θ); θm = copy(θ)
            θp[i] += h; θm[i] -= h
            g_fd[i] = (f(θp) - f(θm)) / (2h)
        end
        @test maximum(abs, g_ad .- g_fd) < 1e-6
    end
end
