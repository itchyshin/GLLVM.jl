# test_species_x_parity.jl — species-specific XB light logLik vs gllvmTMB
#
# Included by runparity.jl AFTER shared site-X cells. NEVER by runtests.jl.
# Arc 0: Poisson q=1 per-trait slopes — R `(0 + trait):x` vs Julia
# `fit_gllvm_speciescov` (B is p×1). Fence: multi-family XB; X_lv; ADEMP;
# full family parity.

using GLLVM, RCall, Test, Random, LinearAlgebra, Statistics

# Knuth sampler — matches test_x_covariate_parity.jl (no Distributions dep).
function _rand_poisson_species_x(λ::Float64)
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

@testset "Species-specific XB light logLik vs gllvmTMB" begin

    @testset "Poisson + species-XB (q=1)" begin
        # Per-trait slopes B[:,1] + site covariate x — twin `(0 + trait):x`.
        # Mild loadings / K=1 to avoid Heywood; never widen rtol.
        Random.seed!(48)
        p, K, n = 5, 1, 80
        β = log.([2.5, 4.0, 2.0, 3.5, 3.0])
        B = reshape([0.45, 0.25, -0.20, 0.35, 0.15], p, 1)
        Λ = 0.30 .* parity_loadings_p5k2()[:, 1:K]
        x = randn(n)
        X = parity_site_design(x, p)
        Z = randn(K, n)
        η = β .+ B[:, 1] .* x' .+ Λ * Z
        Y = [_rand_poisson_species_x(exp(clamp(η[t, s], -8.0, 8.0))) for t in 1:p, s in 1:n]

        jl_fit = fit_gllvm_speciescov(Y; family = GLLVM.Poisson(), X = X, K = K)
        @test jl_fit isa GllvmSpeciesCovFit
        @test jl_fit.converged
        @test isfinite(jl_fit.loglik)
        @test size(jl_fit.B) == (p, 1)
        jl_logL = jl_fit.loglik

        r = fit_gllvmtmb_parity_loglik_species_x(Y, x, K; family = :poisson)
        @test r.converged
        @test isfinite(r.logLik)

        print_parity_loglik(
            "Poisson species-XB logLik oracle (seed=48, p=$p, K=$K, n=$n, q=1 per-trait B)";
            jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
        )

        @testset "log-likelihood agreement (rtol=1e-6)" begin
            @test jl_logL ≈ r.logLik rtol = 1e-6
            @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
        end
    end

end
