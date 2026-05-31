using GLLVM, Test, Distributions, Random, LinearAlgebra

# exact independent-binomial loglik (no latent variation)
_indep_binom_loglik(y, n, β, link) = sum(
    logpdf(Binomial(Int(n[t]), clamp(GLLVM.linkinv(link, β[t]), 1e-12, 1 - 1e-12)), Int(y[t]))
    for t in eachindex(y))

# brute-force 1-D marginal (K=1) via a fine trapezoidal grid — the reference the
# Laplace approximation must come close to.
function _quad_marginal_k1(y, n, Λ, β, link; lo = -12.0, hi = 12.0, m = 6001)
    zs = range(lo, hi; length = m); dz = step(zs)
    f(z) = exp(sum(
        logpdf(Binomial(Int(n[t]), clamp(GLLVM.linkinv(link, β[t] + Λ[t, 1] * z), 1e-12, 1 - 1e-12)), Int(y[t]))
        for t in eachindex(y))) * pdf(Normal(), z)
    return log(sum(f, zs) * dz)
end

@testset "Binomial Laplace marginal" begin
    Random.seed!(5)
    p = 6
    β = randn(p) .* 0.5
    n = fill(1, p)            # Bernoulli
    y = rand(0:1, p)

    @testset "Λ=0 ⇒ Laplace is exact (independent binomial)" begin
        Λ0 = zeros(p, 2)
        for link in (LogitLink(), ProbitLink(), CLogLogLink())
            lap = GLLVM.laplace_loglik_site(y, n, Λ0, β, link)
            @test lap ≈ _indep_binom_loglik(y, n, β, link) rtol = 1e-9
        end
    end

    @testset "K=1: Laplace ≈ exact marginal (quadrature)" begin
        Λ = reshape(0.8 .* randn(p), p, 1)
        for link in (LogitLink(), ProbitLink())
            lap = GLLVM.laplace_loglik_site(y, n, Λ, β, link)
            q = _quad_marginal_k1(y, n, Λ, β, link)
            @test lap ≈ q atol = 0.06      # Laplace is approximate
        end
    end

    @testset "binomial trials n>1 + multi-site additivity" begin
        Λ = reshape(0.5 .* randn(p), p, 1)
        Y = hcat(rand(0:3, p), rand(0:3, p)); N = fill(3, p, 2)
        tot = GLLVM.binomial_marginal_loglik_laplace(Y, N, Λ, β, LogitLink())
        s1 = GLLVM.laplace_loglik_site(view(Y, :, 1), view(N, :, 1), Λ, β, LogitLink())
        s2 = GLLVM.laplace_loglik_site(view(Y, :, 2), view(N, :, 2), Λ, β, LogitLink())
        @test tot ≈ s1 + s2 rtol = 1e-10
        @test isfinite(tot)
    end

    @testset "separated data does not blow up" begin
        Λ = reshape(0.5 .* randn(p), p, 1)
        @test isfinite(GLLVM.laplace_loglik_site(fill(1, p), fill(1, p), Λ, fill(10.0, p), LogitLink()))
        @test isfinite(GLLVM.laplace_loglik_site(fill(0, p), fill(1, p), Λ, fill(-10.0, p), LogitLink()))
    end
end
