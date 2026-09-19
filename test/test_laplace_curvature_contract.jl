# Safety net for the Laplace curvature role-separation contract
# (src/families/laplace.jl, 2026-08-25).
#
# This file exists to be written BEFORE the log-det default is ever flipped from
# :fisher to :observed. Its job is to prove that families which are already
# correct do not move — that is the property the flip must not break.
#
# See docs/dev-log/plans/2026-08-25-laplace-structural-design.md for the design
# and the adversarial verdict (PROCEED WITH MODIFICATIONS).

using GLLVModels, Test, Random, Distributions, ForwardDiff

@testset "Laplace curvature contract" begin

    Random.seed!(20260825)
    p, n, K = 5, 12, 2
    Λ = reshape(0.4 .* randn(p * K), p, K)

    @testset "default is :fisher — shipped behaviour preserved" begin
        # The contract must not change any default. This is the guard against a
        # flip landing by accident rather than by decision.
        @test GLLVModels._default_hessian(Poisson(), GLLVModels.LogLink()) === :fisher
        # Gamma/log is the ONE deliberate exception (2026-08-25): instance 8 of
        # the curvature fault class, on the public default path, flipped on
        # family-specific measured evidence (observed is closer to quadrature
        # 12/12, by 20-60×). Pinned so the exception stays deliberate and
        # visible rather than spreading by accident.
        @test GLLVModels._default_hessian(Gamma(3.0, 1.0), GLLVModels.LogLink()) === :observed
        # NB2/log joined the deliberate exceptions 2026-08-27: flipped on the
        # 900-cell curvature-adjudication campaign, where NB2 preferred the
        # observed curvature on BOTH the estimator-quality and the
        # approximation-accuracy metrics (campaigns/curvature_adjudication/).
        @test GLLVModels._default_hessian(NegativeBinomial(4.0, 0.5), GLLVModels.LogLink()) === :observed
        # Decision A (2026-08-27): Beta, NB1 and Student-t flipped on the
        # campaign's estimator-quality metric with the reported-loglik cost
        # accepted; Exponential's long-shipped fitter default is now DECLARED
        # at the registry level (adversarial-audit fix). All dated, deliberate.
        @test GLLVModels._default_hessian(Beta(12.0, 1.0), GLLVModels.LogitLink()) === :observed
        @test GLLVModels._default_hessian(GLLVModels.NB1(1.5), GLLVModels.LogLink()) === :observed
        @test GLLVModels._default_hessian(GLLVModels.StudentTFamily(4.0, 1.0), GLLVModels.IdentityLink()) === :observed
        @test GLLVModels._default_hessian(Exponential(1.0), GLLVModels.LogLink()) === :observed
        # Maintainer decision batch (2026-08-28,
        # docs/dev-log/decisions/2026-08-28-arc-decision-batch.md): TweedieED/log
        # and Binomial/probit both flip to :observed — TMB/gllvmTMB structural
        # parity (TMB differentiates the joint nll, so its log-det is observed
        # for every family it ships).
        @test GLLVModels._default_hessian(GLLVModels.TweedieED(1.2, 1.5), GLLVModels.LogLink()) === :observed
        @test GLLVModels._default_hessian(Binomial(), GLLVModels.ProbitLink()) === :observed
        # Binomial/cloglog flips to :observed too (2026-09-01, maintainer
        # decisions round 1 item 2): at R's fitted coordinates on the retained
        # seed-81012 fixture, Julia's :fisher marginal disagreed with
        # R/gllvmTMB by 2.0988510... nats, and exact quadrature confirms
        # :observed is the correct curvature (matches R to 7.4e-12; see
        # docs/dev-log/core070/cloglog-leaf-notes.md). The 2026-08-28
        # optimizer-runaway pathology (check-log same date) was measured under
        # BOTH curvature selectors, so it does not bear on this default.
        @test GLLVModels._default_hessian(Binomial(), GLLVModels.CLogLogLink()) === :observed
    end

    @testset "invalid selector fails loud" begin
        Y = rand(1:6, p, n); N = ones(Int, p, n); β = fill(0.8, p)
        @test_throws ArgumentError GLLVModels.marginal_loglik_laplace(
            Poisson(), Y, N, Λ, β, GLLVModels.LogLink(); hessian = :bogus)
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
            a = GLLVModels.marginal_loglik_laplace(Poisson(), Y, N, Λ, β, GLLVModels.LogLink(); hessian = :fisher)
            b = GLLVModels.marginal_loglik_laplace(Poisson(), Y, N, Λ, β, GLLVModels.LogLink(); hessian = :observed)
            @test a === b
            @test GLLVModels._glm_weight_matches_observed(Poisson(), GLLVModels.LogLink())
        end

        @testset "Binomial / logit" begin
            Nb = fill(6, p, n)
            Y  = [rand(0:6) for _ in 1:p, _ in 1:n]
            a = GLLVModels.marginal_loglik_laplace(Binomial(), Y, Nb, Λ, β, GLLVModels.LogitLink(); hessian = :fisher)
            b = GLLVModels.marginal_loglik_laplace(Binomial(), Y, Nb, Λ, β, GLLVModels.LogitLink(); hessian = :observed)
            @test a === b
            @test GLLVModels._glm_weight_matches_observed(Binomial(), GLLVModels.LogitLink())
        end

        @testset "TruncatedPoisson / log" begin
            Y = rand(1:9, p, n)   # y ≥ 1 required
            a = GLLVModels.marginal_loglik_laplace(GLLVModels.TruncatedPoisson(), Y, N, Λ, β, GLLVModels.LogLink(); hessian = :fisher)
            b = GLLVModels.marginal_loglik_laplace(GLLVModels.TruncatedPoisson(), Y, N, Λ, β, GLLVModels.LogLink(); hessian = :observed)
            @test a === b
        end

        # The link specificity is load-bearing: Binomial is trait-true ONLY at
        # the logit link. If probit ever silently acquired the trait, a genuinely
        # wrong weight would be declared safe.
        @testset "trait is link-specific, not family-wide" begin
            @test !GLLVModels._glm_weight_matches_observed(Binomial(), GLLVModels.ProbitLink())
            @test !GLLVModels._glm_weight_matches_observed(Binomial(), GLLVModels.CLogLogLink())
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
            a = GLLVModels.marginal_loglik_laplace(f, Y, N, Λ, β, GLLVModels.LogLink(); hessian = :fisher)
            b = GLLVModels.marginal_loglik_laplace(f, Y, N, Λ, β, GLLVModels.LogLink(); hessian = :observed)
            @test isfinite(a) && isfinite(b)
            @test a != b
            @test !GLLVModels._glm_weight_matches_observed(f, GLLVModels.LogLink())
        end

        @testset "TweedieED / log differs" begin
            Y = [rand() < 0.3 ? 0.0 : 0.1 + 2 * rand() for _ in 1:p, _ in 1:n]
            f = GLLVModels.TweedieED(1.3, 1.5)
            a = GLLVModels.marginal_loglik_laplace(f, Y, N, Λ, β, GLLVModels.LogLink(); hessian = :fisher)
            b = GLLVModels.marginal_loglik_laplace(f, Y, N, Λ, β, GLLVModels.LogLink(); hessian = :observed)
            @test isfinite(a) && isfinite(b)
            @test a != b
            @test !GLLVModels._glm_weight_matches_observed(f, GLLVModels.LogLink())
        end

        @testset "Binomial / probit differs" begin
            Nb = fill(6, p, n)
            Yb = [rand(0:6) for _ in 1:p, _ in 1:n]
            a = GLLVModels.marginal_loglik_laplace(Binomial(), Yb, Nb, Λ, β, GLLVModels.ProbitLink(); hessian = :fisher)
            b = GLLVModels.marginal_loglik_laplace(Binomial(), Yb, Nb, Λ, β, GLLVModels.ProbitLink(); hessian = :observed)
            @test isfinite(a) && isfinite(b)
            @test a != b
            @test !GLLVModels._glm_weight_matches_observed(Binomial(), GLLVModels.ProbitLink())
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
        link = GLLVModels.LogLink()
        for α in (0.7, 3.0, 12.0), η in (-1.5, 0.0, 2.0), y in (0.05, 1.0, 7.5)
            f  = Gamma(α, 1.0)
            μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
            me = GLLVModels.mu_eta(link, η)
            W  = GLLVModels._glm_obs_weight(f, μ, 1, me, y, link, η)
            @test W ≈ α * y / μ rtol = 1e-10
        end
    end

    # And the Fisher weight must be the EXPECTATION of the observed one — the
    # signature of this whole fault class. Substituting y = E[y] = μ collapses
    # α·y/μ to α, which is exactly _glm_weight at the log link.
    @testset "Fisher weight is E[observed] — the fault-class signature" begin
        link = GLLVModels.LogLink()
        for α in (0.7, 3.0), η in (-0.5, 1.2)
            f  = Gamma(α, 1.0)
            μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
            me = GLLVModels.mu_eta(link, η)
            @test GLLVModels._glm_obs_weight(f, μ, 1, me, μ, link, η) ≈ GLLVModels._glm_weight(f, μ, 1, me) rtol = 1e-10
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
            f, link = Poisson(), GLLVModels.LogLink()
            for η in (-1.0, 0.0, 1.7), y in (0, 1, 4, 19)
                μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
                me = GLLVModels.mu_eta(link, η)
                @test GLLVModels._glm_obs_weight(f, μ, 1, me, y, link, η) ≈
                      GLLVModels._glm_weight(f, μ, 1, me) rtol = 1e-10
            end
        end

        @testset "Binomial / logit" begin
            f, link = Binomial(), GLLVModels.LogitLink()
            for η in (-1.3, 0.0, 0.8), nt in (1, 6), y in 0:min(nt, 3)
                μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
                me = GLLVModels.mu_eta(link, η)
                @test GLLVModels._glm_obs_weight(f, μ, nt, me, y, link, η) ≈
                      GLLVModels._glm_weight(f, μ, nt, me) rtol = 1e-10
            end
        end

        @testset "TruncatedPoisson / log" begin
            f, link = GLLVModels.TruncatedPoisson(), GLLVModels.LogLink()
            for η in (-0.5, 0.4, 1.6), y in (1, 2, 7, 15)
                μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
                me = GLLVModels.mu_eta(link, η)
                @test GLLVModels._glm_obs_weight(f, μ, 1, me, y, link, η) ≈
                      GLLVModels._glm_weight(f, μ, 1, me) rtol = 1e-10
            end
        end

        # D2 FIX: CensoredPoisson had ZERO coverage, and is the one declaration
        # carrying an explicit UNVERIFIED caveat (its slot applies max(W, 0)).
        # `n` carries the censoring limit C: n = 0 means uncensored.
        @testset "CensoredPoisson / log" begin
            f, link = GLLVModels.CensoredPoisson(), GLLVModels.LogLink()
            @testset "uncensored branch (C = 0) — reduces to Poisson" begin
                for η in (-0.7, 0.3, 1.4), y in (0, 2, 9)
                    μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
                    me = GLLVModels.mu_eta(link, η)
                    @test GLLVModels._glm_obs_weight(f, μ, 0, me, y, link, η) ≈
                          GLLVModels._glm_weight(f, μ, 0, me) rtol = 1e-10
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
                    μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
                    me = GLLVModels.mu_eta(link, η)
                    @test_throws MethodError GLLVModels._glm_obs_weight(f, μ, C, me, C, link, η)
                end
                # …and the trait keeps it off that path.
                @test GLLVModels._glm_weight_matches_observed(f, link)
            end

            @testset "censored branch (C ≥ 1) — hand-derived G(G+μ−C) vs numerical 2nd derivative" begin
                # Checks the hand derivation at censored_poisson.jl:73 using
                # central finite differences (no Duals), and simultaneously
                # probes whether the max(W, 0) clamp can bind: if it did, the
                # slot and the true curvature would diverge and this fails —
                # converting the recorded UNVERIFIED caveat into a measurement.
                ℓ(ηv, C) = GLLVModels._glm_logpdf(f, GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, ηv)), C, C)
                for η in (-0.7, 0.3, 1.4, 2.2), C in (1, 3, 8)
                    μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
                    me = GLLVModels.mu_eta(link, η)
                    h  = 1e-4
                    d2 = (ℓ(η + h, C) - 2ℓ(η, C) + ℓ(η - h, C)) / h^2
                    @test GLLVModels._glm_weight(f, μ, C, me) ≈ -d2 rtol = 1e-4
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
        N2 = ones(Int, p2, n2)
        # GeneralizedPoisson1, the trait-false exemplar still on the :fisher
        # default: ADJUDICATED 2026-08-28 and Fisher RETAINED on the 150-cell
        # campaign (a minority of cells derail badly under the observed weight
        # — DEFERRED_BY_DECISION in test_curvature_census.jl). TweedieED, the
        # PREVIOUS exemplar here, flipped to :observed 2026-08-28 (maintainer
        # decision batch) and moved to the mirror block below alongside Gamma —
        # restructuring this pin rather than deleting its coverage, per the
        # same "exemplar moves as the census shrinks" pattern noted historically.
        f  = GLLVModels.GeneralizedPoisson1(0.3)
        Y2 = rand(0:6, p2, n2)
        bare = GLLVModels.marginal_loglik_laplace(f, Y2, N2, Λ2, β2, GLLVModels.LogLink())
        fish = GLLVModels.marginal_loglik_laplace(f, Y2, N2, Λ2, β2, GLLVModels.LogLink(); hessian = :fisher)
        obs  = GLLVModels.marginal_loglik_laplace(f, Y2, N2, Λ2, β2, GLLVModels.LogLink(); hessian = :observed)
        @test bare === fish        # the default IS :fisher, at the value level
        @test bare != obs          # and the two are genuinely different here

        # …and the mirror image for Gamma, whose default is now :observed.
        fg = Gamma(2.5, 1.0)
        Yg = 0.4 .+ rand(p2, n2)
        bg = GLLVModels.marginal_loglik_laplace(fg, Yg, N2, Λ2, β2, GLLVModels.LogLink())
        og = GLLVModels.marginal_loglik_laplace(fg, Yg, N2, Λ2, β2, GLLVModels.LogLink(); hessian = :observed)
        fgv = GLLVModels.marginal_loglik_laplace(fg, Yg, N2, Λ2, β2, GLLVModels.LogLink(); hessian = :fisher)
        @test bg === og            # Gamma's default IS :observed, at the value level
        @test bg != fgv

        # TweedieED (2026-08-28 maintainer decision): default IS :observed now,
        # the same shape as Gamma above — restructured from a :fisher-default
        # pin (this file's original exemplar for this testset) into an explicit
        # :fisher-kwarg call, per the maintainer's own guidance for handling a
        # flipped exemplar.
        ft = GLLVModels.TweedieED(1.2, 1.5)
        Yt = [rand() < 0.3 ? 0.0 : rand() * 3.0 + 0.1 for _ in 1:p2, _ in 1:n2]
        bt = GLLVModels.marginal_loglik_laplace(ft, Yt, N2, Λ2, β2, GLLVModels.LogLink())
        ot = GLLVModels.marginal_loglik_laplace(ft, Yt, N2, Λ2, β2, GLLVModels.LogLink(); hessian = :observed)
        ftv = GLLVModels.marginal_loglik_laplace(ft, Yt, N2, Λ2, β2, GLLVModels.LogLink(); hessian = :fisher)
        @test bt === ot            # TweedieED's default IS :observed, at the value level
        @test bt != ftv

        # …and Binomial/probit (same decision batch): default IS :observed.
        Nb2 = fill(5, p2, n2)
        Yb2 = rand(0:5, p2, n2)
        bb = GLLVModels.marginal_loglik_laplace(Binomial(), Yb2, Nb2, Λ2, β2, GLLVModels.ProbitLink())
        ob = GLLVModels.marginal_loglik_laplace(Binomial(), Yb2, Nb2, Λ2, β2, GLLVModels.ProbitLink(); hessian = :observed)
        fbv = GLLVModels.marginal_loglik_laplace(Binomial(), Yb2, Nb2, Λ2, β2, GLLVModels.ProbitLink(); hessian = :fisher)
        @test bb === ob            # Binomial/probit's default IS :observed, at the value level
        @test bb != fbv
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
        obj = b -> GLLVModels.marginal_loglik_laplace(f, Y3, N3, Λ3, fill(b, p3),
                                                 GLLVModels.LogLink(); hessian = :observed)
        g_ad = ForwardDiff.derivative(obj, 0.5)
        h    = 1e-6
        g_fd = (obj(0.5 + h) - obj(0.5 - h)) / (2h)
        @test isfinite(g_ad)
        @test g_ad ≈ g_fd rtol = 1e-5
    end

end
