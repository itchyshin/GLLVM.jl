# test_beta_parity.jl — Beta GLLVM logLik vs gllvmTMB
#
# Included by runparity.jl. NEVER included by test/runtests.jl.
# Same-model bar: per-trait intercepts + per-trait precision φ + latent unique=FALSE.
# Inventory #148: R packs log_phi_beta[p]; Julia grouped route (group = 1:p).
# docs/dev-log/plans/scratch/2026-08-01-correctness-inventory.md

using GLLVM, RCall, Test, Random, LinearAlgebra

# parity_helpers.jl is included once by runparity.jl

# Johnk's algorithm — Beta(a,b) for a,b > 0 (no Distributions dep in parity project).
function _rand_beta(a::Float64, b::Float64)
    a = max(a, 1e-12)
    b = max(b, 1e-12)
    while true
        u = rand()
        v = rand()
        x = u^(1 / a)
        y = v^(1 / b)
        s = x + y
        if s <= 1.0 && s > 0.0
            return x / s
        end
    end
end

@testset "Beta GLLVM parity: GLLVM.jl vs gllvmTMB" begin
    Random.seed!(45)
    p, K, n = 5, 1, 60
    β = [0.30, -0.20, 0.25, -0.15, 0.05]
    # Shared true φ (both engines estimate per-trait precision; #148 route).
    φ_true = 12.0
    # Mild K=1 loadings — smaller Fisher-vs-TMB Laplace gap than K=2.
    Λ = 0.15 .* parity_loadings_p5k2()[:, 1:K]
    Z = randn(K, n)
    η = β .+ Λ * Z
    Y = [
        begin
            μ = 1 / (1 + exp(-η[t, s]))
            μ = clamp(μ, 1e-4, 1 - 1e-4)
            _rand_beta(μ * φ_true, (1 - μ) * φ_true)
        end
        for t in 1:p, s in 1:n
    ]

    # Twin-aligned per-trait φ (group = 1:p ≡ disp_group = :species; not shared-φ default).
    jl_fit = fit_beta_gllvm_grouped(Y; K = K, group = collect(1:p),
                                    g_tol = 1e-7, iterations = 800)
    @test jl_fit isa BetaGroupedFit
    @test jl_fit.converged
    @test isfinite(jl_fit.loglik)
    @test length(jl_fit.φ) == p
    jl_logL = jl_fit.loglik

    r = fit_gllvmtmb_parity_loglik(Y, K; family = :beta)
    @test r.converged
    @test isfinite(r.logLik)

    print_parity_loglik(
        "Beta logLik oracle (seed=45, p=$p, K=$K, n=$n, per-trait φ via group=1:p)";
        jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
    )

    @testset "gllvmTMB extractor consistency" begin
        @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
    end

    # Model identity (#148) is aligned via grouped/disp_group; the grouped
    # fitter's observed Beta/logit Laplace Hessian matches TMB's AD Laplace.
    @testset "log-likelihood agreement (rtol=1e-6)" begin
        @test jl_logL ≈ r.logLik rtol = 1e-6
    end
end
