using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# Procrustes correlation between two n×K score sets: centre both, best orthogonal
# alignment of A onto B, then correlation of the aligned coordinates. Used here to
# score how well an ordination recovers the true latent configuration (invariant
# to the K×K rotation/reflection that loadings/scores are identified only up to).
function _procrustes_cor(A::AbstractMatrix, B::AbstractMatrix)
    Ac = A .- mean(A; dims = 1)
    Bc = B .- mean(B; dims = 1)
    F = svd(Bc' * Ac)
    R = F.V * F.U'
    return cor(vec(Ac * R), vec(Bc))
end

@testset "ordination types: run + recover structure" begin
    # (A) Each ordination variant must (i) return a finite, converged fit and
    #     (ii) recover the true latent configuration up to rotation (procrustes
    #     correlation high). One simulation per variant.

    @testset "unconstrained (Poisson)" begin
        Random.seed!(101)
        p, K, n = 8, 2, 150
        β = log.(fill(5.0, p)); Λt = 0.5 .* randn(p, K); Zt = randn(n, K)
        η = β .+ Λt * Zt'
        Y = [rand(Poisson(exp(clamp(η[t, s], -10, 10)))) for t in 1:p, s in 1:n]
        fit = fit_poisson_gllvm(Y; K = K)
        @test fit.converged
        @test isfinite(fit.loglik)
        S = getLV(fit, Y; rotate = false)
        @test all(isfinite, S)
        @test _procrustes_cor(S, Zt) > 0.9
    end

    @testset "constrained RRR (Poisson, deterministic z = B'x)" begin
        Random.seed!(102)
        p, n, q, K = 8, 120, 2, 2
        β = log.(fill(5.0, p)); Λt = 0.7 .* randn(p, K); Bt = 0.8 .* randn(q, K)
        X = randn(n, q)
        Zt = (Bt' * X')'                          # deterministic latent axes
        η = β .+ Λt * Zt'
        Y = [rand(Poisson(exp(clamp(η[t, s], -10, 10)))) for t in 1:p, s in 1:n]
        fit = fit_rrr_gllvm(Y; family = Poisson(), X = X, K = K)
        @test fit.converged
        @test isfinite(fit.loglik)
        S = getLV(fit, X; rotate = false)
        @test all(isfinite, S)
        @test _procrustes_cor(S, Zt) > 0.85
    end

    @testset "concurrent (Poisson, z = B'x + residual)" begin
        Random.seed!(103)
        p, n, q, K = 8, 120, 2, 2
        β = log.(fill(5.0, p)); Λt = 0.7 .* randn(p, K); Bt = 0.8 .* randn(q, K)
        X = randn(n, q)
        Ztrue = Matrix{Float64}(undef, n, K)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = Bt' * X[s, :] .+ randn(K)
            Ztrue[s, :] = z
            ηs = β .+ Λt * z
            for t in 1:p
                Y[t, s] = rand(Poisson(exp(clamp(ηs[t], -10, 10))))
            end
        end
        fit = fit_concurrent_gllvm(Y; family = Poisson(), X = X, K = K)
        @test fit.converged
        @test isfinite(fit.loglik)
        S = getLV(fit, Y, X; rotate = false)
        @test all(isfinite, S)
        @test _procrustes_cor(S, Ztrue) > 0.85
    end

    @testset "quadratic-response (Poisson, K=1 optima/tolerances)" begin
        Random.seed!(104)
        p, K, n = 8, 1, 120
        β = log.(fill(6.0, p)); Λt = 0.6 .* randn(p, K)
        Dt = reshape(-0.12 .* (0.5 .+ rand(p)), p, K)
        Ztrue = randn(n, K)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n, t in 1:p
            ηts = β[t] + Λt[t, 1] * Ztrue[s, 1] + Dt[t, 1] * Ztrue[s, 1]^2
            Y[t, s] = rand(Poisson(exp(clamp(ηts, -10, 10))))
        end
        fit = fit_quadratic_gllvm(Y; family = Poisson(), K = K, iterations = 300)
        @test fit.converged
        @test isfinite(fit.loglik)
        S = getLV(fit, Y; rotate = false)
        @test all(isfinite, S)
        @test _procrustes_cor(S, Ztrue) > 0.85
    end
end

@testset "ordination_uncertainty: per-site score intervals" begin
    # (B) The score-uncertainty function returns finite per-site intervals on a
    #     fitted model, ordered lower ≤ scores ≤ upper, with statistically
    #     sensible behaviour (SE shrinks as more species sharpen the per-site mode).

    @testset "Poisson fit: shapes, finiteness, ordering" begin
        Random.seed!(201)
        p, K, n = 6, 2, 80
        β = log.(fill(5.0, p)); Λt = 0.5 .* randn(p, K); Zt = randn(n, K)
        η = β .+ Λt * Zt'
        Y = [rand(Poisson(exp(clamp(η[t, s], -10, 10)))) for t in 1:p, s in 1:n]
        fit = fit_poisson_gllvm(Y; K = K)
        u = ordination_uncertainty(fit, Y; n_boot = 80, rng = MersenneTwister(7))

        @test size(u.scores) == (n, K)
        @test size(u.se) == (n, K)
        @test size(u.lower) == (n, K)
        @test size(u.upper) == (n, K)
        @test all(isfinite, u.scores)
        @test all(isfinite, u.se)
        @test all(isfinite, u.lower)
        @test all(isfinite, u.upper)
        @test all(u.se .>= 0)
        @test all(u.lower .<= u.upper)
        @test u.level == 0.95
        @test u.n_boot == 80
        # reference scores are the rotate=true getLV (the canonical point cloud)
        @test u.scores ≈ getLV(fit, Y; rotate = true) atol = 1e-10
    end

    @testset "interval width tracks coverage level" begin
        Random.seed!(202)
        p, K, n = 6, 2, 60
        β = log.(fill(5.0, p)); Λt = 0.6 .* randn(p, K); Zt = randn(n, K)
        η = β .+ Λt * Zt'
        Y = [rand(Poisson(exp(clamp(η[t, s], -10, 10)))) for t in 1:p, s in 1:n]
        fit = fit_poisson_gllvm(Y; K = K)
        u90 = ordination_uncertainty(fit, Y; n_boot = 80, level = 0.90,
                                     rng = MersenneTwister(5))
        u99 = ordination_uncertainty(fit, Y; n_boot = 80, level = 0.99,
                                     rng = MersenneTwister(5))
        @test mean(u99.upper .- u99.lower) > mean(u90.upper .- u90.lower)
    end

    @testset "SE shrinks as p (number of species) grows" begin
        function mean_se(p; K = 2, n = 60, seed = 11)
            Random.seed!(seed)
            β = log.(fill(5.0, p)); Λt = 0.6 .* randn(p, K); Zt = randn(n, K)
            η = β .+ Λt * Zt'
            Y = [rand(Poisson(exp(clamp(η[t, s], -10, 10)))) for t in 1:p, s in 1:n]
            fit = fit_poisson_gllvm(Y; K = K)
            u = ordination_uncertainty(fit, Y; n_boot = 60, rng = MersenneTwister(3))
            return mean(u.se)
        end
        @test mean_se(20) < mean_se(5)
    end

    @testset "Binomial fit with trial counts" begin
        Random.seed!(203)
        p, K, n = 6, 2, 70
        β = fill(0.0, p); Λt = 0.8 .* randn(p, K); Zt = randn(n, K)
        η = β .+ Λt * Zt'
        Ntr = fill(8, p, n)
        Y = [rand(Binomial(Ntr[t, s], 1 / (1 + exp(-clamp(η[t, s], -10, 10)))))
             for t in 1:p, s in 1:n]
        fit = fit_binomial_gllvm(Y; K = K, N = Ntr)
        u = ordination_uncertainty(fit, Y; n_boot = 60, N = Ntr,
                                   rng = MersenneTwister(9))
        @test size(u.scores) == (n, K)
        @test all(isfinite, u.se)
        @test all(u.lower .<= u.upper)
    end

    @testset "argument validation" begin
        Random.seed!(204)
        p, K, n = 5, 2, 40
        β = log.(fill(5.0, p)); Λt = 0.5 .* randn(p, K)
        η = β .+ Λt * randn(K, n)
        Y = [rand(Poisson(exp(clamp(η[t, s], -10, 10)))) for t in 1:p, s in 1:n]
        fit = fit_poisson_gllvm(Y; K = K)
        @test_throws ArgumentError ordination_uncertainty(fit, Y; level = 1.5)
        @test_throws ArgumentError ordination_uncertainty(fit, Y; n_boot = 1)
    end
end
