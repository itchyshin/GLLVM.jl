using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# Reporting harness (NOT a pass/fail gate). For each family that has BOTH a
# Laplace and a variational (VA) fitter, simulate a GLLVM with a KNOWN
# dispersion/shape and log, side by side, what each estimator recovers. The
# numbers surface ONLY through these @info lines in the CI log — every message
# is prefixed "VA-vs-LA" so they are greppable. The ONLY assertions are
# `@test isfinite(fit.loglik)`; there are NO recovery/threshold checks here.

# Rotation/sign-invariant loadings recovery: correlation of the Gram matrices ΛΛ'.
gram_cor(fit, Λtrue) = cor(vec(fit.Λ * fit.Λ'), vec(Λtrue * Λtrue'))

@testset "VA vs Laplace comparison" begin
    p, K, n = 6, 2, 120   # modest n — VA fits are slow

    # --- Poisson (no dispersion; compare loglik vs ELBO + loadings recovery) ---
    @testset "Poisson" begin
        Random.seed!(91001)
        βtrue = 0.3 .* randn(p) .+ 1.0
        Λtrue = 0.4 .* randn(p, K)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                Y[t, s] = rand(Poisson(exp(βtrue[t] + dot(Λtrue[t, :], z))))
            end
        end
        fitLA = GLLVM.fit_poisson_gllvm(Y; K = K)
        fitVA = GLLVM.fit_poisson_gllvm_va(Y; K = K)

        @info "VA-vs-LA [Poisson] fit quality (no dispersion param)" laplace_loglik=fitLA.loglik va_elbo=fitVA.loglik
        @info "VA-vs-LA [Poisson] loadings gram cor" laplace=gram_cor(fitLA, Λtrue) va=gram_cor(fitVA, Λtrue)

        @test isfinite(fitLA.loglik)
        @test isfinite(fitVA.loglik)
    end

    # --- Negative binomial (headline: dispersion r recovery) ---
    @testset "Negative Binomial" begin
        Random.seed!(91002)
        r_true = 4.0
        βtrue = 0.3 .* randn(p) .+ 1.0
        Λtrue = 0.4 .* randn(p, K)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                μ = exp(βtrue[t] + dot(Λtrue[t, :], z))
                Y[t, s] = rand(NegativeBinomial(r_true, r_true / (r_true + μ)))
            end
        end
        fitLA = GLLVM.fit_nb_gllvm(Y; K = K)
        fitVA = GLLVM.fit_nb_gllvm_va(Y; K = K)

        @info "VA-vs-LA [NB] dispersion r" r_true=r_true laplace_r=fitLA.r va_r=fitVA.r laplace_loglik=fitLA.loglik va_elbo=fitVA.loglik
        @info "VA-vs-LA [NB] loadings gram cor" laplace=gram_cor(fitLA, Λtrue) va=gram_cor(fitVA, Λtrue)

        @test isfinite(fitLA.loglik)
        @test isfinite(fitVA.loglik)
    end

    # --- Gamma (headline: shape α recovery) ---
    @testset "Gamma" begin
        Random.seed!(91003)
        α_true = 4.0
        βtrue = 0.3 .* randn(p) .+ 1.0
        Λtrue = 0.4 .* randn(p, K)
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                μ = exp(βtrue[t] + dot(Λtrue[t, :], z))
                Y[t, s] = rand(Gamma(α_true, μ / α_true))
            end
        end
        fitLA = GLLVM.fit_gamma_gllvm(Y; K = K)
        fitVA = GLLVM.fit_gamma_gllvm_va(Y; K = K)

        @info "VA-vs-LA [Gamma] shape α" α_true=α_true laplace_α=fitLA.α va_α=fitVA.α laplace_loglik=fitLA.loglik va_elbo=fitVA.loglik
        @info "VA-vs-LA [Gamma] loadings gram cor" laplace=gram_cor(fitLA, Λtrue) va=gram_cor(fitVA, Λtrue)

        @test isfinite(fitLA.loglik)
        @test isfinite(fitVA.loglik)
    end
end
