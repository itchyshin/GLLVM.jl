using Test
using GLLVM
using Random
using LinearAlgebra
using Distributions
using Statistics

# Model A: predictor-informed latent scores (lv = ~ x) composed with a trait-axis
# phylogenetic trait-covariance block — orthogonal axes (X_lv mean on the site
# axis, Σ_phy on the trait axis), estimand B_lv = Λ_B · α'. Gaussian, v1.
@testset "phylo × X_lv (Model A)" begin

    @testset "brute-force correctness pin (J3 rotation trick survives the X_lv mean)" begin
        # The threaded objective on the X_lv residual must equal a dense
        # vec(y) ~ N(μ, I_n⊗A + J_n⊗B) Gaussian, μ the X_lv mean.
        Random.seed!(123)
        p, n, K, q_lv, K_phy = 4, 6, 1, 1, 1
        X_lv   = randn(n, q_lv)
        θ_rr_B = randn(GLLVM.rr_theta_len(p, K));     Λ_B   = GLLVM.unpack_lambda(θ_rr_B, p, K)
        θ_rr_p = randn(GLLVM.rr_theta_len(p, K_phy)); Λ_phy = GLLVM.unpack_lambda(θ_rr_p, p, K_phy)
        alpha_lv = randn(q_lv, K)
        log_σ    = -0.3
        M = randn(p, p + 2); S = M * M'; Σ_phy = S ./ sqrt.(diag(S) * diag(S)')
        y = randn(p, n)

        params = vcat(vec(alpha_lv), log_σ, θ_rr_B, θ_rr_p)
        nll = GLLVM.gaussian_lv_nll_packed(params, y, p, K;
                X_lv = X_lv, q_lv = q_lv, K_phy = K_phy, has_phy_unique = false, Σ_phy = Σ_phy)

        σ = exp(log_σ)
        A = Λ_B * Λ_B' + σ^2 * Matrix(I, p, p)
        B = (Λ_phy * Λ_phy') .* Σ_phy
        V = kron(Matrix(I, n, n), A) + kron(ones(n, n), B)
        μ = vec(Λ_B * (X_lv * alpha_lv)')
        ll_dense = logpdf(MvNormal(μ, Symmetric(Matrix(V))), vec(y))
        @test abs(-nll - ll_dense) < 1e-8        # machine precision

        # α = 0 reduces to the plain phylo marginal (no mean shift).
        params0 = vcat(zeros(q_lv * K), log_σ, θ_rr_B, θ_rr_p)
        nll0 = GLLVM.gaussian_lv_nll_packed(params0, y, p, K;
                X_lv = X_lv, q_lv = q_lv, K_phy = K_phy, has_phy_unique = false, Σ_phy = Σ_phy)
        @test abs(-nll0 - logpdf(MvNormal(zeros(p * n), Symmetric(Matrix(V))), vec(y))) < 1e-8
    end

    @testset "fit recovers B_lv under phylogenetic structure + Wald CI" begin
        Random.seed!(2024)
        p, n, K, q_lv, K_phy = 5, 300, 1, 1, 1
        X_lv  = reshape(collect(range(-1.5, 1.5; length = n)), n, q_lv)
        Λ_B   = reshape([0.8, -0.5, 0.4, 0.3, -0.6], p, K)
        alpha = reshape([0.7], q_lv, K)
        B_true = vec(Λ_B * alpha')
        Λ_phy = reshape([0.5, 0.4, -0.3, 0.35, 0.45], p, K_phy)
        M = randn(p, p + 2); S = M * M'; Σ_phy = S ./ sqrt.(diag(S) * diag(S)')
        Bphy = (Λ_phy * Λ_phy') .* Σ_phy
        σ = 0.4
        φ = cholesky(Symmetric(Bphy + 1e-6 * I)).L * randn(p)
        Y = zeros(p, n)
        for s in 1:n
            z = X_lv[s, 1] * alpha[1, 1] + randn()
            Y[:, s] = Λ_B[:, 1] * z .+ φ .+ σ .* randn(p)
        end

        fit = fit_gaussian_gllvm(Y; K = K, X_lv = X_lv, K_phy = K_phy, Σ_phy = Σ_phy,
                                 iterations = 500)
        @test fit.converged
        @test fit.pars.Λ_phy !== nothing                      # phylo block populated
        Blv_hat = vec(extract_lv_effects(fit))
        @test cor(Blv_hat, B_true) > 0.95                     # recovers the rotation-stable truth

        ci = confint_lv_effects(fit, Y, X_lv)                 # Wald extends to the augmented vector
        @test ci.method == :wald
        @test all(isfinite, ci.se)
        @test all(ci.lower .< ci.estimate .< ci.upper)
    end
end
