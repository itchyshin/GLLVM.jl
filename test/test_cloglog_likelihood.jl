# Regression test for the confirmed Binomial/cloglog Laplace likelihood
# defect (2026-09-01, maintainer decisions round 1, item 2 —
# docs/dev-log/decisions/2026-09-01-maintainer-decisions-round1.md).
#
# ROOT CAUSE: `_default_hessian(::Binomial, ::CLogLogLink)` fell through to
# the generic `:fisher` default (src/families/laplace.jl). CLogLogLink is
# non-canonical for Binomial (unlike LogitLink), so the Fisher/expected
# information and the observed Hessian of the Laplace integrand differ
# pointwise — and R/gllvmTMB's TMB engine differentiates its coded joint
# negative log-density via AD, which is definitionally the OBSERVED Hessian,
# never a Fisher-information substitute. Using `:fisher` by default therefore
# computed a different (wrong, relative to R) Laplace marginal for every
# cloglog fit. Fixed by adding `_default_hessian(::Binomial, ::CLogLogLink) =
# :observed`, src/families/binomial.jl, matching the existing ProbitLink
# treatment (2026-08-28).
#
# Full diagnosis (per-site gap decomposition, quadrature ground truth,
# probe scripts): docs/dev-log/core070/cloglog-leaf-notes.md.

using GLLVM, Test, Distributions

@testset "Binomial/cloglog Laplace likelihood defect (fixed)" begin

    @testset "default is :observed" begin
        @test GLLVM._default_hessian(Binomial(), CLogLogLink()) === :observed
    end

    @testset "R-oracle regression: seed-81012 retained fixture (p=4, n=120, K=1)" begin
        # Frozen R/gllvmTMB oracle values, embedded verbatim from
        # .unlazy/core070-aghq/wave4-batches/wave4-famlinks2/r-oracle.json
        # ("cloglog" block) so this test does not depend on scratch state.
        p, n, K = 4, 120, 1
        y_flat = [1,1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,0,0,1,1,1,1,0,0,1,0,0,1,0,1,1,0,1,1,1,1,0,1,1,1,
                  0,1,1,1,0,0,1,1,0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,0,1,1,0,0,1,0,1,0,1,0,0,
                  1,1,0,1,1,1,0,0,0,0,1,1,1,1,0,0,1,1,1,0,1,1,0,0,1,1,1,1,0,1,1,1,1,0,1,1,1,1,1,1,
                  0,1,0,0,1,0,1,1,1,1,0,1,1,1,0,0,1,1,0,1,1,0,1,1,1,0,0,1,1,1,0,0,1,1,1,1,1,0,1,1,
                  1,0,1,1,1,1,1,1,0,1,0,1,1,1,1,0,1,1,0,1,1,0,1,1,1,1,0,0,1,0,0,1,1,0,0,0,1,0,0,1,
                  1,0,1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,0,1,1,0,1,0,0,0,0,1,0,1,1,1,1,1,0,1,0,1,0,0,1,
                  0,1,1,1,0,1,0,1,1,1,1,1,1,0,1,1,1,1,0,0,0,0,1,0,1,0,1,1,1,0,1,1,1,0,1,0,1,0,1,1,
                  0,1,0,0,0,1,0,1,1,1,1,0,1,0,0,1,0,1,1,0,0,0,0,1,1,0,0,1,1,1,1,1,1,0,0,1,1,1,1,1,
                  0,0,1,0,0,1,1,1,0,0,1,1,1,0,1,0,1,0,1,1,1,0,1,1,1,1,1,0,1,0,1,0,1,0,0,1,0,1,1,1,
                  1,1,1,0,0,1,1,1,1,0,0,1,1,1,1,1,0,1,1,1,0,0,1,1,0,1,0,0,0,1,1,1,0,1,1,0,1,0,1,1,
                  0,0,0,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1,0,0,1,0,1,1,1,0,1,1,0,1,1,1,1,0,1,1,1,1,1,1,
                  1,0,1,1,1,1,1,1,1,0,1,0,1,0,0,1,0,0,1,1,1,1,1,1,0,1,1,1,0,1,1,1,0,0,1,0,0,1,0,0]
        @test length(y_flat) == p * n
        Y = reshape(Float64.(y_flat), p, n)
        β = [0.05633183058923141, -0.17547638504625393, 0.07521068251340196, 0.13527942824484349]
        Λ = reshape([0.45665002489451634, -0.6844232065542527, 0.32704745505926985, 0.49747821000365394],
                    p, K)
        r_loglik = -307.8958232820915

        obj = GLLVM.binomial_marginal_loglik_laplace(Y, ones(p, n), Λ, β, CLogLogLink())
        @test obj ≈ r_loglik atol = 1e-8            # ~1e-9 in practice, per the probe

        # The stale :fisher value should no longer be the default and should
        # still be off by the confirmed ~2.1 nats when forced explicitly.
        obj_fisher = GLLVM.binomial_marginal_loglik_laplace(Y, ones(p, n), Λ, β, CLogLogLink();
                                                             hessian = :fisher)
        @test abs(obj_fisher - r_loglik) > 2.0
    end

    @testset "site-level quadrature ground truth (K=1, single trait vector)" begin
        # Fine trapezoidal quadrature over z (mirrors the reference pattern in
        # test_binomial_laplace.jl's `_quad_marginal_k1`), applied to one
        # y-vector at fixed non-degenerate cloglog coordinates. `:observed`
        # must land far closer to the quadrature value than `:fisher`.
        Random_seed = 81012
        p = 5
        β = [0.2, -0.3, 0.1, 0.4, -0.1]
        Λ = reshape([0.6, -0.5, 0.4, 0.55, -0.35], p, 1)
        y = [1.0, 0.0, 1.0, 1.0, 0.0]
        link = CLogLogLink()

        function quad_marginal_k1(y, Λ, β, link; lo = -12.0, hi = 12.0, m = 20001)
            zs = range(lo, hi; length = m); dz = step(zs)
            f(z) = exp(sum(
                logpdf(Binomial(1, clamp(GLLVM.linkinv(link, β[t] + Λ[t, 1] * z), 1e-12, 1 - 1e-12)),
                       Int(y[t]))
                for t in eachindex(y))) * pdf(Normal(), z)
            return log(sum(f, zs) * dz)
        end

        q = quad_marginal_k1(y, Λ, β, link)
        lap_fisher   = GLLVM.laplace_loglik_site(y, ones(p), Λ, β, link; hessian = :fisher)
        lap_observed = GLLVM.laplace_loglik_site(y, ones(p), Λ, β, link; hessian = :observed)

        @test abs(lap_observed - q) < abs(lap_fisher - q)   # observed strictly closer to truth
        @test abs(lap_observed - q) < 0.05                  # Laplace approximation error only
    end
end
