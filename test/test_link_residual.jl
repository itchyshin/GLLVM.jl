# Tests for the cross-family link-implicit residual table (src/link_residual.jl)
# and the latent-scale non-Gaussian extractors (additive methods in
# src/confint_derived.jl): sigma_y_site / communality / correlation for
# PoissonFit, BinomialFit, NBFit, BetaFit, GammaFit, OrdinalFit.
#
# Three blocks:
#   (a) σ²_d values match the gllvmTMB link_residual_per_trait formulas for each
#       family (the numbers, not just the shape);
#   (b) the assembled latent-scale Σ = ΛΛᵀ + diag(σ²_d) is PSD, its correlation
#       is symmetric / unit-diagonal / in [-1, 1], and communality ∈ [0, 1];
#   (c) GAUSSIAN REDUCTION: the latent-scale construction with the per-trait
#       residual set to σ_eps² (link-residual → 0) reproduces the existing
#       correlation(::GllvmFit) on a Gaussian fit — confirming the two paths
#       share one convention (Σ = ΛΛᵀ + diag(residual)).
#
# Self-runnable: `julia --project=. test/test_link_residual.jl`.

using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions
using SpecialFunctions: trigamma

if !isdefined(GLLVM, :link_residual)
    include(joinpath(@__DIR__, "..", "src", "link_residual.jl"))
end

# Generic structural checks on a latent-scale (Σ, R, c²) triple for a p-trait fit.
function _check_latent_triple(Σ, R, c2, p)
    @test size(Σ) == (p, p)
    @test size(R) == (p, p)
    @test length(c2) == p
    # Σ symmetric and PSD
    @test maximum(abs.(Σ - Σ')) < 1e-10
    @test minimum(eigvals(Symmetric(Σ))) > -1e-8
    # R symmetric, unit-diagonal, off-diagonals in [-1, 1]
    @test maximum(abs.(R - R')) < 1e-10
    for t in 1:p
        @test isapprox(R[t, t], 1.0; atol = 1e-12)
    end
    for j in 1:p, i in 1:p
        @test -1 - 1e-10 ≤ R[i, j] ≤ 1 + 1e-10
    end
    # communality in [0, 1]
    @test all(-1e-12 .≤ c2 .≤ 1 + 1e-12)
end

@testset "link-residual table + latent-scale non-Gaussian extractors" begin

    # -----------------------------------------------------------------------
    # (a) σ²_d formula values match gllvmTMB link_residual_per_trait.
    # -----------------------------------------------------------------------
    @testset "(a) σ²_d formulas match gllvmTMB" begin

        # Binomial: μ̂-free constants per link (extract-sigma.R 156–162).
        @test GLLVM.link_residual(Binomial(), LogitLink(),   0.3, nothing) ≈ π^2 / 3
        @test GLLVM.link_residual(Binomial(), ProbitLink(),  0.3, nothing) ≈ 1.0
        @test GLLVM.link_residual(Binomial(), CLogLogLink(), 0.3, nothing) ≈ π^2 / 6

        # Poisson-log: log(1 + 1/μ̂) (extract-sigma.R 171–172).
        for μ̂ in (0.5, 2.0, 7.3)
            @test GLLVM.link_residual(Poisson(), LogLink(), μ̂, nothing) ≈ log1p(1 / μ̂)
        end

        # NB2-log: trigamma(r), r the Var = μ + μ²/r dispersion (extract-sigma.R 188–191).
        for r in (1.5, 10.0, 50.0)
            @test GLLVM.link_residual(NegativeBinomial(r, 0.5), LogLink(), 3.0, r) ≈ trigamma(r)
        end

        # Gamma-log: trigamma(shape α) (extract-sigma.R 182–183; α == 1/σ²).
        for α in (0.8, 2.0, 5.0)
            @test GLLVM.link_residual(Gamma(α, 1.0), LogLink(), 4.0, α) ≈ trigamma(α)
        end

        # Beta-logit: trigamma(μ̂φ) + trigamma((1−μ̂)φ) (extract-sigma.R 216–233).
        for (μ̂, φ) in ((0.4, 5.0), (0.7, 12.0), (0.2, 3.0))
            expected = trigamma(μ̂ * φ) + trigamma((1 - μ̂) * φ)
            @test GLLVM.link_residual(Beta(φ, 1.0), LogitLink(), μ̂, φ) ≈ expected
        end
        # Beta μ̂-clamp: a saturated μ̂ → 1 stays finite (mirrors the R clamp to 1e-6).
        @test isfinite(GLLVM.link_residual(Beta(8.0, 1.0), LogitLink(), 1.0, 8.0))
        @test GLLVM.link_residual(Beta(8.0, 1.0), LogitLink(), 1.0, 8.0) ≈
              trigamma((1 - 1e-6) * 8.0) + trigamma(1e-6 * 8.0)

        # Ordinal cumulative-logit: π²/3 (standard-logistic latent residual).
        @test GLLVM.link_residual(GLLVM.Ordinal(), LogitLink(), 0.0, nothing) ≈ π^2 / 3
    end

    # -----------------------------------------------------------------------
    # (b) per-family fits: vector form matches the formula; Σ/R/c² well-formed.
    # -----------------------------------------------------------------------
    @testset "(b) Poisson latent-scale extractors" begin
        Random.seed!(101)
        p, K, n = 4, 1, 150
        β_true = log.([4.0, 6.0, 3.0, 5.0])
        Λ_true = reshape(0.5 .* randn(p), p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        fit = fit_poisson_gllvm(Y; K = K)
        @test fit.converged

        d = link_residual(fit, Y)
        @test length(d) == p
        μ̂ = vec(mean(predict(fit, Y; type = :response); dims = 2))
        @test d ≈ [log1p(1 / μ̂[t]) for t in 1:p]
        @test all(d .> 0)

        Σ = GLLVM.sigma_y_site(fit, Y)
        @test Σ ≈ fit.Λ * fit.Λ' + Diagonal(d)
        R  = GLLVM.correlation(fit, Y)
        c2 = GLLVM.communality(fit, Y)
        _check_latent_triple(Σ, R, c2, p)
    end

    @testset "(b) Binomial latent-scale extractors" begin
        Random.seed!(102)
        p, K, n = 4, 1, 250
        β_true = [0.3, -0.2, 0.6, -0.5]
        Λ_true = reshape(0.5 .* randn(p), p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Y = [rand(Bernoulli(1 / (1 + exp(-η[t, s])))) ? 1 : 0 for t in 1:p, s in 1:n]
        fit = fit_binomial_gllvm(Y; K = K)
        @test fit.converged

        d = link_residual(fit, Y)
        @test d ≈ fill(π^2 / 3, p)              # logit default

        Σ = GLLVM.sigma_y_site(fit, Y)
        @test Σ ≈ fit.Λ * fit.Λ' + Diagonal(fill(π^2 / 3, p))
        R  = GLLVM.correlation(fit, Y)
        c2 = GLLVM.communality(fit, Y)
        _check_latent_triple(Σ, R, c2, p)
    end

    @testset "(b) Negative-binomial latent-scale extractors" begin
        Random.seed!(103)
        p, K, n = 4, 1, 200
        r_true = 8.0
        β_true = log.([5.0, 8.0, 4.0, 6.0])
        Λ_true = reshape(0.4 .* randn(p), p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Y = [rand(NegativeBinomial(r_true, r_true / (r_true + exp(η[t, s])))) for t in 1:p, s in 1:n]
        fit = fit_nb_gllvm(Y; K = K)
        @test fit.converged

        d = link_residual(fit, Y)
        @test d ≈ fill(trigamma(fit.r), p)      # μ̂-free under NB2 trigamma form

        Σ = GLLVM.sigma_y_site(fit, Y)
        R  = GLLVM.correlation(fit, Y)
        c2 = GLLVM.communality(fit, Y)
        _check_latent_triple(Σ, R, c2, p)
    end

    @testset "(b) Beta latent-scale extractors" begin
        Random.seed!(104)
        p, K, n = 4, 1, 200
        φ_true = 12.0
        β_true = [0.2, -0.3, 0.5, -0.1]
        Λ_true = reshape(0.4 .* randn(p), p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Y = [rand(Beta((1 / (1 + exp(-η[t, s]))) * φ_true,
                       (1 - 1 / (1 + exp(-η[t, s]))) * φ_true)) for t in 1:p, s in 1:n]
        fit = fit_beta_gllvm(Y; K = K)
        @test fit.converged

        d = link_residual(fit, Y)
        μ̂ = vec(mean(predict(fit, Y; type = :response); dims = 2))
        @test d ≈ [trigamma(GLLVM._clamp_mu_prop(μ̂[t]) * fit.φ) +
                   trigamma((1 - GLLVM._clamp_mu_prop(μ̂[t])) * fit.φ) for t in 1:p]

        Σ = GLLVM.sigma_y_site(fit, Y)
        R  = GLLVM.correlation(fit, Y)
        c2 = GLLVM.communality(fit, Y)
        _check_latent_triple(Σ, R, c2, p)
    end

    @testset "(b) Gamma latent-scale extractors" begin
        Random.seed!(105)
        p, K, n = 4, 1, 200
        α_true = 4.0
        β_true = log.([2.0, 3.0, 1.5, 2.5])
        Λ_true = reshape(0.3 .* randn(p), p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Y = [rand(Gamma(α_true, exp(η[t, s]) / α_true)) for t in 1:p, s in 1:n]
        fit = fit_gamma_gllvm(Y; K = K)
        @test fit.converged

        d = link_residual(fit, Y)
        @test d ≈ fill(trigamma(fit.α), p)      # μ̂-free under Gamma trigamma(shape)

        Σ = GLLVM.sigma_y_site(fit, Y)
        R  = GLLVM.correlation(fit, Y)
        c2 = GLLVM.communality(fit, Y)
        _check_latent_triple(Σ, R, c2, p)
    end

    @testset "(b) Ordinal latent-scale extractors" begin
        Random.seed!(106)
        p, K, n, C = 4, 1, 250, 4
        Λ_true = reshape(0.6 .* randn(p), p, K)
        τ_true = [-1.0, 0.0, 1.0]
        η = Λ_true * randn(K, n)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n, t in 1:p
            u = 1 / (1 + exp(-(η[t, s])))   # placeholder; build a category from cumulative logits
            # draw category from the cumulative-logit probabilities
            probs = [GLLVM._ord_prob(c, η[t, s], τ_true) for c in 1:C]
            Y[t, s] = rand(Categorical(probs ./ sum(probs)))
        end
        fit = fit_ordinal_gllvm(Y; K = K)
        @test fit.converged

        d = link_residual(fit, Y)
        @test d ≈ fill(π^2 / 3, p)

        Σ = GLLVM.sigma_y_site(fit, Y)
        @test Σ ≈ fit.Λ * fit.Λ' + Diagonal(fill(π^2 / 3, p))
        R  = GLLVM.correlation(fit, Y)
        c2 = GLLVM.communality(fit, Y)
        _check_latent_triple(Σ, R, c2, p)
    end

    # -----------------------------------------------------------------------
    # (c) Gaussian-reduction: the latent-scale construction with the per-trait
    #     residual set to σ_eps² (link-residual → 0) reproduces the existing
    #     correlation(::GllvmFit). Confirms the single shared convention
    #     Σ = ΛΛᵀ + diag(residual).
    # -----------------------------------------------------------------------
    @testset "(c) Gaussian reduction reproduces correlation(::GllvmFit)" begin
        Random.seed!(107)
        p, K, n = 4, 1, 300
        Λ_true = reshape([0.7, 0.5, 0.4, -0.3], p, K)
        y = Λ_true * randn(K, n) + 0.5 * randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        # Reference: the existing Gaussian extractors (UNCHANGED).
        Σ_ref = GLLVM.sigma_y_site(fit)
        R_ref = GLLVM.correlation(fit)

        # Reconstruct via the latent-scale helpers with σ²_d = σ_eps² and a zero
        # link-residual (a Gaussian fit's link-implicit residual is 0; its
        # latent residual is the Gaussian σ_eps²). For J1 (no W, no diag) the
        # Gaussian Σ is exactly ΛΛᵀ + diag(σ_eps²).
        σ²_d_gauss = fill(fit.pars.σ_eps^2, p)
        @test all(GLLVM.link_residual(Normal(), IdentityLink(), 0.0, nothing) == 0 for _ in 1:1)

        Σ_latent = GLLVM._latent_sigma(fit.pars.Λ, σ²_d_gauss)
        R_latent = GLLVM._latent_correlation(Σ_latent)

        @test Σ_latent ≈ Σ_ref rtol = 1e-12
        @test R_latent ≈ R_ref rtol = 1e-12
    end
end
