using Test
using GLLVM
using LinearAlgebra
using Random
using Distributions

# Regression guard for the observed-information finite-difference Hessian that
# backs every non-Gaussian Wald confidence interval (`_family_wald`). The
# historical bug wrote `2f0` — which Julia lexes as the Float32 literal `2.0f0`,
# NOT `2 * f0` — so the diagonal second difference became
# `(f(x+h) - 2.0 + f(x-h)) / h²`, dropping the cached centre value. With any
# large constant offset in the objective (every log-likelihood has one) the
# diagonal blew up by ~`2·f0 / h²`, collapsing `inv(H)` and yielding standard
# errors ~1e-6. Existing CI tests only checked structure / `pd_hessian`, so it
# went unnoticed. These tests pin the Hessian to a KNOWN value.
@testset "_fd_hessian observed-information correctness" begin
    @testset "diagonal quadratic with large offset (the exact trigger)" begin
        c = [2.0, 5.0, 0.5, 3.0]
        f = x -> 0.5 * sum(c .* x .^ 2) + 1.0e4   # Hessian = diag(c)
        H = GLLVM._fd_hessian(f, [0.3, -0.7, 1.1, 0.2])
        @test isapprox(diag(H), c; rtol = 1e-4)
        @test maximum(abs, H - Diagonal(c)) < 1e-3
    end

    @testset "general symmetric quadratic recovers A" begin
        A = [2.0 0.5 -0.3; 0.5 1.5 0.2; -0.3 0.2 3.0]
        f = x -> 0.5 * dot(x, A * x) + 50.0
        H = GLLVM._fd_hessian(f, [0.4, -0.2, 0.9])
        @test isapprox(H, A; rtol = 1e-3, atol = 1e-3)
    end

    @testset "Wald SEs are sane end-to-end (the user-facing symptom)" begin
        Random.seed!(2026)
        p, n = 4, 150
        Λ = reshape([0.7, -0.5, 0.4, 0.3], p, 1); β = log.([5.0, 4.0, 6.0, 5.0])
        Y = [rand(Poisson(exp(β[t] + (Λ * randn(1))[t]))) for t in 1:p, s in 1:n]
        fit = fit_poisson_gllvm(Y; K = 1, iterations = 300)
        ci = confint(fit, Y; method = :wald)
        @test ci.pd_hessian
        @test all(0.005 .< ci.se .< 2.0)   # the bug produced ~1e-6
    end
end
