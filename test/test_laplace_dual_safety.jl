# Dual-safety census for the generic Laplace curvature fallback.
#
# WHY THIS FILE EXISTS. `_glm_obs_weight` is a NESTED ForwardDiff derivative of
# a family's coded log-density. That only works if the density is twice
# differentiable *by ForwardDiff* — which is a property of the implementation,
# not of the mathematics. It was assumed universal. It is not:
# `CensoredPoisson`'s censored branch is `logcdf(Gamma(C,1), μ)`, and
# `_gammalogcdf` has no method for `ForwardDiff.Dual` — it fails at the FIRST
# derivative with a MethodError.
#
# That family is safe today only because it is declared trait-true and never
# reaches the fallback. This file locks the whole census so that:
#   * adding a family whose density is not dual-safe is caught HERE, at the
#     point the property is introduced, rather than when someone flips a
#     default months later; and
#   * the one known exception cannot silently become two.
#
# It also records, as executable fact, which (family, link) pairs genuinely
# have observed ≠ Fisher — i.e. which are real instances of the curvature
# fault class through this kernel.

using GLLVModels, Test, Distributions

@testset "Laplace fallback dual-safety census" begin

    η = 0.35

    # (name, family, link, n, y, observed==Fisher?)
    CASES = [
        ("Poisson/log",        Poisson(),                      GLLVModels.LogLink(),      1, 3.0, true),
        ("Binomial/logit",     Binomial(),                     GLLVModels.LogitLink(),    6, 2.0, true),
        ("Binomial/probit",    Binomial(),                     GLLVModels.ProbitLink(),   6, 2.0, false),
        ("Binomial/cloglog",   Binomial(),                     GLLVModels.CLogLogLink(),  6, 2.0, false),
        ("NegBin2/log",        NegativeBinomial(4.0, 0.5),     GLLVModels.LogLink(),      1, 3.0, false),
        ("NB1/log",            GLLVModels.NB1(1.5),                 GLLVModels.LogLink(),      1, 3.0, false),
        ("Beta/logit",         Beta(12.0, 1.0),                GLLVModels.LogitLink(),    1, 0.4, false),
        ("Gamma/log",          Gamma(3.0, 1.0),                GLLVModels.LogLink(),      1, 2.0, false),
        ("Exponential/log",    Exponential(1.0),               GLLVModels.LogLink(),      1, 2.0, false),
        ("TruncatedPoisson",   GLLVModels.TruncatedPoisson(),       GLLVModels.LogLink(),      1, 3.0, true),
        ("GP1/log",            GLLVModels.GeneralizedPoisson1(0.3), GLLVModels.LogLink(),      1, 3.0, false),
        ("Student-t/identity", GLLVModels.StudentTFamily(4.0, 1.0), GLLVModels.IdentityLink(), 1, 0.7, false),
        ("Tweedie/log",        GLLVModels.TweedieED(1.5, 1.5),      GLLVModels.LogLink(),      1, 2.0, false),
    ]

    @testset "every family reaching the generic core is dual-safe" begin
        for (name, f, link, n, y, _) in CASES
            μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
            me = GLLVModels.mu_eta(link, η)
            w  = GLLVModels._glm_obs_weight(f, μ, n, me, y, link, η)   # must not throw
            @test isfinite(w)
        end
    end

    # Tweedie's density is an infinite series, which was flagged as a likely AD
    # hazard during design. It is NOT one: `_tweedie_logA` receives only primals
    # (y is the response; φ and p are struct fields), so the series never sees a
    # Dual. Asserted here so the refutation stays refuted.
    @testset "Tweedie's infinite series is not an AD hazard" begin
        f, link = GLLVModels.TweedieED(1.5, 1.5), GLLVModels.LogLink()
        μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
        me = GLLVModels.mu_eta(link, η)
        @test isfinite(GLLVModels._glm_obs_weight(f, μ, 1, me, 2.0, link, η))
    end

    # The known exception, pinned. If this ever starts passing, the upstream
    # gap has been fixed and CensoredPoisson could join the fallback; if a
    # SECOND family starts throwing, the census above catches it.
    @testset "CensoredPoisson is the ONLY non-dual-safe family (pinned)" begin
        f, link = GLLVModels.CensoredPoisson(), GLLVModels.LogLink()
        μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
        me = GLLVModels.mu_eta(link, η)
        @test_throws MethodError GLLVModels._glm_obs_weight(f, μ, 3, me, 3.0, link, η)
        @test GLLVModels._glm_weight_matches_observed(f, link)   # …and the trait keeps it off that path
    end

    # Which pairs are genuinely instances of the fault class through this
    # kernel. Recorded as executable fact so the census cannot drift from the
    # prose. NOTE the link specificity: Binomial is clean at logit and is an
    # INSTANCE at probit and cloglog — a family-level census would miss both.
    @testset "observed ≠ Fisher exactly where claimed" begin
        for (name, f, link, n, y, same) in CASES
            μ  = GLLVModels._clamp_mu(f, GLLVModels.linkinv(link, η))
            me = GLLVModels.mu_eta(link, η)
            wo = GLLVModels._glm_obs_weight(f, μ, n, me, y, link, η)
            wf = GLLVModels._glm_weight(f, μ, n, me)
            if same
                @test wo ≈ wf rtol = 1e-10
            else
                @test !isapprox(wo, wf; rtol = 1e-6)
            end
        end
    end

    # ---- The PD guard: measured, and honestly bounded ----------------------
    #
    # Beta's observed curvature IS negative pointwise (locked in the oracle
    # file: φ=12, η=−1.2, y=0.87 → −1.218). The obvious inference is that
    # flipping the default would drive Beta fits into the PD guard and return
    # `-Inf`, which with the repo-wide `isfinite(v) ? v : 1e12` sentinel would
    # be a *declared convergence* rather than an error.
    #
    # MEASURED, and the inference does NOT hold: at the Fisher mode the weights
    # are positive. Across p ∈ {4,8,20} × ‖Λ‖ ∈ {1,3,10,30} with adversarial
    # data (y = 0.985, β = −1.5), the minimum observed weight AT THE MODE was
    # +1.18 and no cell was negative — 0/12. The mode-finder moves η to where
    # the data support it, and the observed curvature is positive there.
    #
    # So: pointwise negativity is common; negativity AT THE MODE is not. That
    # is the distinction that matters, and it is why this guard is cheap
    # insurance rather than a routine code path.
    @testset "Beta observed weights are positive AT THE MODE (guard stays quiet)" begin
        link = GLLVModels.LogitLink(); f = Beta(12.0, 1.0)
        for p in (4, 8), scale in (1.0, 10.0)
            β  = fill(-1.5, p); yv = fill(0.985, p)
            Λ  = fill(scale, p, 1); n1 = ones(Int, p)
            z  = GLLVModels._laplace_mode(f, yv, n1, Λ, β, link)
            ηm = GLLVModels._clamp_eta.(β .+ Λ * z)
            μm = GLLVModels._clamp_mu.(Ref(f), GLLVModels.linkinv.(Ref(link), ηm))
            mem = GLLVModels.mu_eta.(Ref(link), ηm)
            W  = [GLLVModels._glm_obs_weight(f, μm[t], 1, mem[t], yv[t], link, ηm[t]) for t in 1:p]
            @test all(>(0), W)
            # …and the marginal is finite, i.e. the guard did not fire.
            Y = reshape(yv, p, 1); N = ones(Int, p, 1)
            @test isfinite(GLLVModels.marginal_loglik_laplace(f, Y, N, Λ, β, link; hessian = :observed))
        end
    end

    # KNOWN RESIDUAL, stated rather than papered over: the guard's `-Inf`
    # RETURN BRANCH is not exercised by any test here, because no natural
    # fixture was found that reaches it (see the 0/12 measurement above). The
    # predicate and the surrounding path are covered; the failure return is
    # not. If a future change makes it reachable, the assertions above flip
    # first and say so.

end
