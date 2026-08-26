using GLLVM, Test, Random, Distributions, Statistics

@testset "Exponential family" begin
    @testset "Λ=0 reduces to independent Exponential loglik (exact)" begin
        Random.seed!(190)
        p, K, n = 5, 2, 60
        β = 0.3 .* randn(p)
        Y = [rand(Exponential(exp(β[t]))) for t in 1:p, s in 1:n]
        ll = GLLVM.exponential_marginal_loglik_laplace(Y, zeros(p, K), β)
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += logpdf(Exponential(exp(β[t])), Y[t, s])
        end
        @test ll ≈ ref atol = 1e-8
    end

    # NOTE on recovery: the Exponential law has CV = 1, so the log-data the SVD
    # warm start sees is noise-dominated (Var[log Exp] = π²/6 ≈ 1.64) and the
    # per-site loadings are only weakly identified at moderate n — unlike Poisson/
    # NB/Gamma, fitted-loading recovery here is unreliable and improving it needs a
    # better (non-SVD) init. See ROADMAP.md ("Exponential LV recovery"). The exact
    # Λ=0 reduction above already verifies the likelihood itself; this set verifies
    # the fit/predict/residuals/CI machinery runs and stays numerically sane.
    @testset "fit machinery: dispatch + post-fit + CI (finite, well-formed)" begin
        Random.seed!(191)
        p, K, n = 8, 2, 300
        β_true = 0.3 .* randn(p)
        Λ_true = 0.4 .* randn(p, K)
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        Y = [rand(Exponential(exp(η[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_exponential_gllvm(Y; K = K)
        @test fit isa ExponentialFit
        # EXPOSED 2026-08-26 by `_fit_verdict`; ROOT CAUSE FOUND 2026-08-26 (different
        # shape from the CMP / OrderedBeta cases, and NOT fixed — see below).
        #
        # The default `hessian=:observed` route goes through
        # `gamma_grouped_marginal_loglik_laplace` at α≡1 (exponential.jl:60), whose
        # per-site Newton mode-solve (`_gamma_grouped_loglik_site`,
        # grouped_dispersion.jl:786) has NO step-size damping or line search — plain
        # undamped Newton, `maxiter=100`. For an ORDINARY site in this fixture (site 284;
        # Y in [0.2, 5.3], nothing extreme), the iteration genuinely DIVERGES: step size
        # grows geometrically (|Δ|: 0.54, 0.60, 0.73, 0.96, 1.23, 1.67, 2.18, 3.22, 4.67,
        # 10.45, 67.08, then 1.8e11 and oscillating at that magnitude for the rest of the
        # 100 iterations) rather than converging. The loop has no divergence check, so it
        # runs to `maxiter` regardless and evaluates the log-density at a garbage `z`.
        #
        # Confirmed causal, not incidental: capping the SAME site at `maxiter=8` (before
        # divergence sets in) gives a sane per-site loglik of -31.67; the full `maxiter=100`
        # run gives -1.41e22. The `:fisher` route through the ORIGINAL generic core (not
        # this grouped kernel) gives a sane total marginal of -2288.58 at the identical
        # (Y, Λ, β) — confirming the mode itself is fine in principle and the bug is
        # specific to this kernel's unguarded Newton loop, exactly the gap its own comment
        # at grouped_dispersion.jl:797-806 already names relative to the generic core's
        # `_laplace_mode_should_backtrack` safety.
        #
        # NOT FIXED. This is a structural change to a shared mode-solver (used by every
        # grouped-dispersion family, not just Exponential/Gamma), not a local numerical
        # stabilization like the CMP/OrderedBeta fixes — needs a step-size cap or
        # backtracking line search, and needs its own verification that doing so does not
        # change the CONVERGED mode for the families that currently work. Diagnosis:
        # docs/dev-log/pending/exponential-diverging-newton-diagnosis.jl.
        @test_broken isfinite(fit.loglik)

        # unified dispatch
        @test fit_gllvm(Y; family = Exponential(), K = K) isa ExponentialFit

        # post-fit surface stays finite and well-formed (η is clamped before exp,
        # so μ never under/overflows even for an extreme conditional mode)
        @test size(getLV(fit, Y)) == (n, K)
        P = predict(fit, Y; type = :response)
        @test size(P) == (p, n) && all(>(0), P) && all(isfinite, P)
        R = residuals(fit, Y)
        @test size(R) == (p, n) && all(isfinite, R)
        @test_broken isfinite(aic(fit)) && isfinite(bic(fit, n))   # same cause as :35

        # CI
        ci = confint(fit, Y; method = :wald)
        @test length(ci.term) == p + (p * K - div(K * (K - 1), 2))   # β + packed Λ
        @test ci.estimate[1] ≈ fit.β[1] atol = 1e-8
    end

    @testset "observed Laplace curvature (2026-08-24 fix)" begin
        # The shipped weight was the EXPECTED information: at the log link
        # `_glm_weight(::Exponential) = me^2/mu^2` is the CONSTANT 1, independent of y.
        # TMB uses the OBSERVED joint Hessian, which for Exponential/log is y/mu.
        # E[y] = mu recovers 1, so the old value was exactly the expectation of the
        # correct one -- the signature of this fault class (see check-log 2026-08-24).
        Random.seed!(61)
        p, K, n = 5, 1, 80
        beta = log.([2.0, 3.0, 1.5, 2.5, 2.2])
        Lam = 0.25 .* randn(p, K)
        Z = randn(K, n)
        eta = beta .+ Lam * Z
        Y = [(-log(rand())) * exp(eta[t, s]) for t in 1:p, s in 1:n]
        @test all(>(0), Y)

        # 1. The two curvatures are genuinely different objectives.
        lf = exponential_marginal_loglik_laplace(Y, Lam, beta; hessian = :fisher)
        lo = exponential_marginal_loglik_laplace(Y, Lam, beta; hessian = :observed)
        @test isfinite(lf) && isfinite(lo)
        @test !isapprox(lo, lf; rtol = 1e-8)

        # 2. `:fisher` must reproduce the pre-fix generic-core path BIT-FOR-BIT.
        #    This is what makes the change a corrected default rather than an altered
        #    capability -- and it is not automatic: routing Fisher through the Gamma
        #    grouped kernel instead gives the same value HERE but a different mode
        #    solver under optimisation (it let |Lambda| run away to ~960 vs a true
        #    0.38). So this assertion guards a real, already-observed failure.
        #    RE-ARMED 2026-08-25. This previously called the core with NO
        #    `hessian` kwarg, i.e. it relied on the default. If that default is
        #    flipped to `:observed`, BOTH sides would compute observed curvature
        #    and `lf == old` would keep passing while the property it documents
        #    -- "reproduces the pre-2026-08-24 path" -- had become false. A test
        #    that silently stops testing is worse than one that fails.
        old = GLLVM.marginal_loglik_laplace(GLLVM.Exponential(1.0), Y,
                                            ones(Int, size(Y)), Lam, beta, GLLVM.LogLink();
                                            hessian = :fisher)
        @test lf == old

        #    NOT pinned to a recorded literal. A literal WAS added here on
        #    2026-08-25 and reverted the same day: the fixture comes from
        #    `Random.seed!(61)` + `randn`, and that stream differs between Julia
        #    1.10 and 1.12, so the value is version-specific. CI proved it —
        #    ubuntu/1.10 passed while macOS and Windows on 1.12 both evaluated
        #    -721.1485447143208 against the 1.10 literal -721.33208612614351.
        #    A local machine running one Julia version cannot catch that.
        #
        #    The vacuity concern the literal was meant to address is already
        #    covered portably: BOTH sides now request `hessian = :fisher`
        #    explicitly (so a default flip cannot make them agree by accident),
        #    and assertion 1 above independently pins that `:fisher` and
        #    `:observed` are genuinely different objectives on this fixture.

        # 3. The observed weight equals -d2l/deta2 = y/mu (AD-verified to 1.9e-16
        #    separately); check the algebraic identity against the Gamma alpha=1 route,
        #    which is where the implementation actually comes from.
        for (mu, y) in ((0.5, 9.0), (2.0, 0.1), (7.0, 2.0))
            @test GLLVM._gamma_grouped_laplace_weight(:observed, GLLVM.Gamma(1.0, 1.0),
                                                      mu, mu, y, GLLVM.LogLink()) ≈ y / mu
        end

        # 4. Fits: both converge, differ, and neither degenerates.
        fo = fit_exponential_gllvm(Y; K = K)
        ff = fit_exponential_gllvm(Y; K = K, hessian = :fisher)
        @test fo.converged && ff.converged
        @test !isapprox(fo.loglik, ff.loglik; rtol = 1e-8)
        @test all(isfinite, fo.Λ) && all(isfinite, ff.Λ)
    end

    @testset "invalid hessian symbol is rejected up front" begin
        # The objective wraps its body in a try/catch that converts any throw into a
        # large penalty, so an unvalidated typo would return a converged-looking
        # garbage fit instead of an error.
        Random.seed!(62)
        Y = [(-log(rand())) * 2.0 for _ in 1:4, _ in 1:20]
        @test_throws ArgumentError fit_exponential_gllvm(Y; K = 1, hessian = :bogus)
        @test_throws ArgumentError exponential_marginal_loglik_laplace(
            Y, zeros(4, 1), zeros(4); hessian = :bogus)
    end

end
