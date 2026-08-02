# test_poisson_parity.jl — Poisson GLLVM logLik vs gllvmTMB
#
# Included by runparity.jl. NEVER included by test/runtests.jl.
# Same-model bar: per-trait intercepts + latent unique=FALSE (no Ψ).
# Inventory: docs/dev-log/plans/scratch/2026-08-01-correctness-inventory.md

using GLLVM, RCall, Test, Random, LinearAlgebra

# parity_helpers.jl is included once by runparity.jl

# Knuth sampler — avoids requiring Distributions in the parity project.
function _rand_poisson(λ::Float64)
    λ = clamp(λ, 0.0, 1e6)
    L = exp(-λ)
    k = 0
    prod = 1.0
    while true
        k += 1
        prod *= rand()
        prod <= L && return k - 1
    end
end

@testset "Poisson GLLVM parity: GLLVM.jl vs gllvmTMB" begin
    Random.seed!(44)
    p, K, n = 5, 2, 60
    β = log.([3.0, 5.0, 2.0, 4.0, 3.5])
    # Milder loadings than the Gaussian fixture — keeps Laplace modes stable.
    Λ = 0.45 .* parity_loadings_p5k2()
    Z = randn(K, n)
    η = β .+ Λ * Z
    Y = [_rand_poisson(exp(clamp(η[t, s], -8.0, 8.0))) for t in 1:p, s in 1:n]

    jl_fit = fit_poisson_gllvm(Y; K = K)
    @test jl_fit.converged
    @test isfinite(jl_fit.loglik)
    jl_logL = jl_fit.loglik

    r = fit_gllvmtmb_parity_loglik(Y, K; family = :poisson)
    @test r.converged
    @test isfinite(r.logLik)

    print_parity_loglik(
        "Poisson logLik oracle (seed=44, p=$p, K=$K, n=$n)";
        jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
    )

    @testset "log-likelihood agreement (rtol=1e-6)" begin
        @test jl_logL ≈ r.logLik rtol = 1e-6
        @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
    end
end
