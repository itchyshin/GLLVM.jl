# Safety net for the Laplace curvature role-separation contract
# (src/families/laplace.jl, 2026-08-25).
#
# This file exists to be written BEFORE the log-det default is ever flipped from
# :fisher to :observed. Its job is to prove that families which are already
# correct do not move — that is the property the flip must not break.
#
# See docs/dev-log/plans/2026-08-25-laplace-structural-design.md for the design
# and the adversarial verdict (PROCEED WITH MODIFICATIONS).

using GLLVM, Test, Random, Distributions, ForwardDiff

@testset "Laplace curvature contract" begin

    Random.seed!(20260825)
    p, n, K = 5, 12, 2
    Λ = reshape(0.4 .* randn(p * K), p, K)

    @testset "default is :fisher — shipped behaviour preserved" begin
        # The contract must not change any default. This is the guard against a
        # flip landing by accident rather than by decision.
        @test GLLVM._default_hessian(Poisson(), GLLVM.LogLink()) === :fisher
        @test GLLVM._default_hessian(Gamma(3.0, 1.0), GLLVM.LogLink()) === :fisher
        @test GLLVM._default_hessian(NegativeBinomial(4.0, 0.5), GLLVM.LogLink()) === :fisher
    end

    @testset "invalid selector fails loud" begin
        Y = rand(1:6, p, n); N = ones(Int, p, n); β = fill(0.8, p)
        @test_throws ArgumentError GLLVM.marginal_loglik_laplace(
            Poisson(), Y, N, Λ, β, GLLVM.LogLink(); hessian = :bogus)
    end

    # ---- The invariance set -------------------------------------------------
    # Families whose existing weight slot is already the correct log-det
    # curvature. For these, :fisher and :observed must agree EXACTLY (===), not
    # merely to a tolerance: they take the identical code path by construction,
    # so any difference at all means the trait or the branch is wrong.
    @testset "invariance set is bit-for-bit unchanged" begin
        β = fill(0.7, p)
        N = ones(Int, p, n)

        @testset "Poisson / log" begin
            Y = rand(1:9, p, n)
            a = GLLVM.marginal_loglik_laplace(Poisson(), Y, N, Λ, β, GLLVM.LogLink(); hessian = :fisher)
            b = GLLVM.marginal_loglik_laplace(Poisson(), Y, N, Λ, β, GLLVM.LogLink(); hessian = :observed)
            @test a === b
            @test GLLVM._glm_weight_matches_observed(Poisson(), GLLVM.LogLink())
        end

        @testset "Binomial / logit" begin
            Nb = fill(6, p, n)
            Y  = [rand(0:6) for _ in 1:p, _ in 1:n]
            a = GLLVM.marginal_loglik_laplace(Binomial(), Y, Nb, Λ, β, GLLVM.LogitLink(); hessian = :fisher)
            b = GLLVM.marginal_loglik_laplace(Binomial(), Y, Nb, Λ, β, GLLVM.LogitLink(); hessian = :observed)
            @test a === b
            @test GLLVM._glm_weight_matches_observed(Binomial(), GLLVM.LogitLink())
        end

        @testset "TruncatedPoisson / log" begin
            Y = rand(1:9, p, n)   # y ≥ 1 required
            a = GLLVM.marginal_loglik_laplace(GLLVM.TruncatedPoisson(), Y, N, Λ, β, GLLVM.LogLink(); hessian = :fisher)
            b = GLLVM.marginal_loglik_laplace(GLLVM.TruncatedPoisson(), Y, N, Λ, β, GLLVM.LogLink(); hessian = :observed)
            @test a === b
        end

        # The link specificity is load-bearing: Binomial is trait-true ONLY at
        # the logit link. If probit ever silently acquired the trait, a genuinely
        # wrong weight would be declared safe.
        @testset "trait is link-specific, not family-wide" begin
            @test !GLLVM._glm_weight_matches_observed(Binomial(), GLLVM.ProbitLink())
            @test !GLLVM._glm_weight_matches_observed(Binomial(), GLLVM.CLogLogLink())
        end
    end

    # ---- The machinery must actually do something ---------------------------
    # A contract that changed nothing anywhere would pass every test above while
    # being useless. These assert the selector genuinely reaches the log-det.
    @testset "selector changes the value where it should" begin
        β = fill(0.5, p)
        N = ones(Int, p, n)

        @testset "Gamma / log differs" begin
            Y = 0.5 .+ rand(p, n)
            f = Gamma(3.0, 1.0)
            a = GLLVM.marginal_loglik_laplace(f, Y, N, Λ, β, GLLVM.LogLink(); hessian = :fisher)
            b = GLLVM.marginal_loglik_laplace(f, Y, N, Λ, β, GLLVM.LogLink(); hessian = :observed)
            @test isfinite(a) && isfinite(b)
            @test a != b
            @test !GLLVM._glm_weight_matches_observed(f, GLLVM.LogLink())
        end
    end

    # ---- The fallback must equal the hand-derived formula -------------------
    # Gamma/log has a known observed curvature, α·y/μ, already implemented in
    # grouped_dispersion.jl. If the generic ForwardDiff fallback does not
    # reproduce it, the fallback is wrong and nothing built on it can be trusted.
    # Interior cells only — see the CONVENTION NOTE on _glm_obs_weight: at the
    # μ-clamp the fallback and an analytic formula are deliberately different
    # objects.
    @testset "ForwardDiff fallback ≡ analytic α·y/μ (Gamma/log, interior)" begin
        link = GLLVM.LogLink()
        for α in (0.7, 3.0, 12.0), η in (-1.5, 0.0, 2.0), y in (0.05, 1.0, 7.5)
            f  = Gamma(α, 1.0)
            μ  = GLLVM._clamp_mu(f, GLLVM.linkinv(link, η))
            me = GLLVM.mu_eta(link, η)
            W  = GLLVM._glm_obs_weight(f, μ, 1, me, y, link, η)
            @test W ≈ α * y / μ rtol = 1e-10
        end
    end

    # And the Fisher weight must be the EXPECTATION of the observed one — the
    # signature of this whole fault class. Substituting y = E[y] = μ collapses
    # α·y/μ to α, which is exactly _glm_weight at the log link.
    @testset "Fisher weight is E[observed] — the fault-class signature" begin
        link = GLLVM.LogLink()
        for α in (0.7, 3.0), η in (-0.5, 1.2)
            f  = Gamma(α, 1.0)
            μ  = GLLVM._clamp_mu(f, GLLVM.linkinv(link, η))
            me = GLLVM.mu_eta(link, η)
            @test GLLVM._glm_obs_weight(f, μ, 1, me, μ, link, η) ≈ GLLVM._glm_weight(f, μ, 1, me) rtol = 1e-10
        end
    end
end
