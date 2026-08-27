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
        @test GLLVM._default_hessian(Beta(12.0, 1.0), GLLVM.LogitLink()) === :fisher
        # Gamma/log is the ONE deliberate exception (2026-08-25): instance 8 of
        # the curvature fault class, on the public default path, flipped on
        # family-specific measured evidence (observed is closer to quadrature
        # 12/12, by 20-60×). Pinned so the exception stays deliberate and
        # visible rather than spreading by accident.
        @test GLLVM._default_hessian(Gamma(3.0, 1.0), GLLVM.LogLink()) === :observed
        # NB2/log joined the deliberate exceptions 2026-08-27: flipped on the
        # 900-cell curvature-adjudication campaign, where NB2 preferred the
        # observed curvature on BOTH the estimator-quality and the
        # approximation-accuracy metrics (campaigns/curvature_adjudication/).
        @test GLLVM._default_hessian(NegativeBinomial(4.0, 0.5), GLLVM.LogLink()) === :observed
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

    # ---- D1 FIX: a FALSIFIABLE test of each trait claim ---------------------
    #
    # The `a === b` assertions below are true BY CONSTRUCTION: the selector in
    # laplace_loglik_site short-circuits on the trait, so a trait-true family
    # takes the identical branch under either setting and never evaluates
    # _glm_obs_weight. They therefore cannot fail for a WRONG declaration —
    # which is the failure mode this file exists to catch.
    #
    # This testset can fail. `_glm_weight` is y-free; the observed curvature is
    # y-dependent in general. So if a trait declaration is mathematically wrong,
    # varying y at fixed η moves the observed weight away from the Fisher one
    # and this fails. It tests the CLAIM, not the branch.
    @testset "trait claims are falsifiable: observed ≡ Fisher across distinct y" begin

        @testset "Poisson / log" begin
            f, link = Poisson(), GLLVM.LogLink()
            for η in (-1.0, 0.0, 1.7), y in (0, 1, 4, 19)
                μ  = GLLVM._clamp_mu(f, GLLVM.linkinv(link, η))
                me = GLLVM.mu_eta(link, η)
                @test GLLVM._glm_obs_weight(f, μ, 1, me, y, link, η) ≈
                      GLLVM._glm_weight(f, μ, 1, me) rtol = 1e-10
            end
        end

        @testset "Binomial / logit" begin
            f, link = Binomial(), GLLVM.LogitLink()
            for η in (-1.3, 0.0, 0.8), nt in (1, 6), y in 0:min(nt, 3)
                μ  = GLLVM._clamp_mu(f, GLLVM.linkinv(link, η))
                me = GLLVM.mu_eta(link, η)
                @test GLLVM._glm_obs_weight(f, μ, nt, me, y, link, η) ≈
                      GLLVM._glm_weight(f, μ, nt, me) rtol = 1e-10
            end
        end

        @testset "TruncatedPoisson / log" begin
            f, link = GLLVM.TruncatedPoisson(), GLLVM.LogLink()
            for η in (-0.5, 0.4, 1.6), y in (1, 2, 7, 15)
                μ  = GLLVM._clamp_mu(f, GLLVM.linkinv(link, η))
                me = GLLVM.mu_eta(link, η)
                @test GLLVM._glm_obs_weight(f, μ, 1, me, y, link, η) ≈
                      GLLVM._glm_weight(f, μ, 1, me) rtol = 1e-10
            end
        end

        # D2 FIX: CensoredPoisson had ZERO coverage, and is the one declaration
        # carrying an explicit UNVERIFIED caveat (its slot applies max(W, 0)).
        # `n` carries the censoring limit C: n = 0 means uncensored.
        @testset "CensoredPoisson / log" begin
            f, link = GLLVM.CensoredPoisson(), GLLVM.LogLink()
            @testset "uncensored branch (C = 0) — reduces to Poisson" begin
                for η in (-0.7, 0.3, 1.4), y in (0, 2, 9)
                    μ  = GLLVM._clamp_mu(f, GLLVM.linkinv(link, η))
                    me = GLLVM.mu_eta(link, η)
                    @test GLLVM._glm_obs_weight(f, μ, 0, me, y, link, η) ≈
                          GLLVM._glm_weight(f, μ, 0, me) rtol = 1e-10
                end
            end
            # MEASURED 2026-08-25: the generic ForwardDiff fallback CANNOT be
            # used here. `_glm_logpdf(::CensoredPoisson, …)` on the censored
            # branch is `logcdf(Gamma(C,1), μ)`, and `_gammalogcdf` has no
            # method for `ForwardDiff.Dual` — it fails at the FIRST derivative,
            # with a MethodError.
            #
            # That is a load-bearing fact, not a nuisance: this family is safe
            # ONLY because it is declared trait-true and therefore never reaches
            # the fallback. If a future change routed it there, it would ERROR
            # rather than silently return a wrong number. Both properties are
            # locked below so neither can regress unnoticed.
            @testset "fallback is NOT dual-safe here — locked, because the trait depends on it" begin
                for C in (1, 3)
                    η = 0.3
                    μ  = GLLVM._clamp_mu(f, GLLVM.linkinv(link, η))
                    me = GLLVM.mu_eta(link, η)
                    @test_throws MethodError GLLVM._glm_obs_weight(f, μ, C, me, C, link, η)
                end
                # …and the trait keeps it off that path.
                @test GLLVM._glm_weight_matches_observed(f, link)
            end

            @testset "censored branch (C ≥ 1) — hand-derived G(G+μ−C) vs numerical 2nd derivative" begin
                # Checks the hand derivation at censored_poisson.jl:73 using
                # central finite differences (no Duals), and simultaneously
                # probes whether the max(W, 0) clamp can bind: if it did, the
                # slot and the true curvature would diverge and this fails —
                # converting the recorded UNVERIFIED caveat into a measurement.
                ℓ(ηv, C) = GLLVM._glm_logpdf(f, GLLVM._clamp_mu(f, GLLVM.linkinv(link, ηv)), C, C)
                for η in (-0.7, 0.3, 1.4, 2.2), C in (1, 3, 8)
                    μ  = GLLVM._clamp_mu(f, GLLVM.linkinv(link, η))
                    me = GLLVM.mu_eta(link, η)
                    h  = 1e-4
                    d2 = (ℓ(η + h, C) - 2ℓ(η, C) + ℓ(η - h, C)) / h^2
                    @test GLLVM._glm_weight(f, μ, C, me) ≈ -d2 rtol = 1e-4
                end
            end
        end
    end

    # ---- D3 FIX: pin the DEFAULT WIRING, not just the trait function --------
    # Asserting `_default_hessian(...) === :fisher` tests a function in
    # isolation; an inverted condition in the selector leaves it green. This
    # pins the value actually produced, and does it on a trait-FALSE family
    # (Gamma), where the two settings genuinely differ — so it fails if the
    # default ever silently moves.
    @testset "default wiring produces the :fisher value (trait-false family)" begin
        Random.seed!(7)
        p2, n2 = 4, 8
        Λ2 = reshape(0.35 .* randn(p2), p2, 1)
        β2 = fill(0.6, p2)
        Y2 = 0.4 .+ rand(p2, n2)
        N2 = ones(Int, p2, n2)
        # Beta/logit, not Gamma or NB2: those defaults are now deliberately
        # :observed (2026-08-25 / 2026-08-27), so neither can serve as the
        # "default is :fisher" pin. Beta remains Fisher pending the maintainer's
        # estimator-vs-reporting call (campaign 2026-08-27).
        f  = Beta(12.0, 1.0)
        Y2 = clamp.(rand(p2, n2), 1e-3, 1 - 1e-3)
        bare = GLLVM.marginal_loglik_laplace(f, Y2, N2, Λ2, β2, GLLVM.LogitLink())
        fish = GLLVM.marginal_loglik_laplace(f, Y2, N2, Λ2, β2, GLLVM.LogitLink(); hessian = :fisher)
        obs  = GLLVM.marginal_loglik_laplace(f, Y2, N2, Λ2, β2, GLLVM.LogitLink(); hessian = :observed)
        @test bare === fish        # the default IS :fisher, at the value level
        @test bare != obs          # and the two are genuinely different here

        # …and the mirror image for Gamma, whose default is now :observed.
        fg = Gamma(2.5, 1.0)
        Yg = 0.4 .+ rand(p2, n2)
        bg = GLLVM.marginal_loglik_laplace(fg, Yg, N2, Λ2, β2, GLLVM.LogLink())
        og = GLLVM.marginal_loglik_laplace(fg, Yg, N2, Λ2, β2, GLLVM.LogLink(); hessian = :observed)
        fgv = GLLVM.marginal_loglik_laplace(fg, Yg, N2, Λ2, β2, GLLVM.LogLink(); hessian = :fisher)
        @test bg === og            # Gamma's default IS :observed, at the value level
        @test bg != fgv
    end

    # ---- D4 FIX: the nested-AD arm must survive OUTER differentiation -------
    # `_glm_obs_weight` is itself a nested ForwardDiff derivative. Fitters run
    # ForwardDiff OVER this objective, so the composition must work. That was
    # asserted by static reasoning and never measured; measure it.
    @testset "outer AD differentiates through the :observed arm" begin
        Random.seed!(11)
        p3, n3 = 4, 6
        Λ3 = reshape(0.3 .* randn(p3), p3, 1)
        Y3 = 0.5 .+ rand(p3, n3)
        N3 = ones(Int, p3, n3)
        f  = Gamma(3.0, 1.0)
        obj = b -> GLLVM.marginal_loglik_laplace(f, Y3, N3, Λ3, fill(b, p3),
                                                 GLLVM.LogLink(); hessian = :observed)
        g_ad = ForwardDiff.derivative(obj, 0.5)
        h    = 1e-6
        g_fd = (obj(0.5 + h) - obj(0.5 - h)) / (2h)
        @test isfinite(g_ad)
        @test g_ad ≈ g_fd rtol = 1e-5
    end

end
