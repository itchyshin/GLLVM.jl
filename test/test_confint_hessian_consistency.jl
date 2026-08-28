# Confint-layer curvature consistency (2026-08-28).
#
# THE CLASS THIS KILLS (found by the arc2 adversarial audit, two instances):
# `confint`/bootstrap rebuilt the family objective with the DEFAULT curvature,
# ignoring the `hessian` the fit was actually made with. After the 2026-08-27
# flips the defaults happen to agree for default fits — but a user who fit
# with the `hessian = :fisher` escape hatch got observed-curvature CIs
# silently, making the CHANGELOG's ":fisher restores the previous behaviour"
# claim true at fit time only.
#
# THE STRUCTURAL FIX: every one-part fit struct records the curvature its
# objective used (`fit.hessian`, positional-compat constructor defaults it to
# the family default), and every `_family_ci` adapter threads `fit.hessian`
# into BOTH the rebuilt marginal and the bootstrap refit.
#
# THE CONTRACT, per family × selector: the adapter's rebuilt nll, evaluated at
# the fit's own packed θ̂, equals −fit.loglik — the CI machinery differentiates
# THE SAME objective the fit maximised, whichever curvature that was.

using GLLVM, Test, Random, Distributions

@testset "confint rebuilds the fit's own objective (hessian consistency)" begin
    Random.seed!(11)
    p, K, n = 5, 1, 60
    Z = randn(K, n); B = 0.3 .* randn(p); L = 0.4 .* randn(p, K); H = B .+ L * Z
    Yg = [rand(Gamma(2.0, exp(H[t, s]) / 2.0)) for t in 1:p, s in 1:n]
    Ynb = [rand(NegativeBinomial(3.0, 3.0 / (3.0 + exp(H[t, s])))) for t in 1:p, s in 1:n]
    Yex = [rand(Exponential(exp(H[t, s]))) for t in 1:p, s in 1:n]

    @testset "the fit records its selector" begin
        @test GLLVM.fit_gamma_gllvm(Yg; K = K).hessian === :observed
        @test GLLVM.fit_gamma_gllvm(Yg; K = K, hessian = :fisher).hessian === :fisher
        @test GLLVM.fit_nb_gllvm(Ynb; K = K).hessian === :observed
        @test GLLVM.fit_exponential_gllvm(Yex; K = K).hessian === :observed
        @test GLLVM.fit_exponential_gllvm(Yex; K = K, hessian = :fisher).hessian === :fisher
    end

    # The objective-identity contract. `_family_ci` exposes the rebuilt nll;
    # at the fit's own θ̂ it must reproduce −loglik to solver tolerance for
    # BOTH selectors — the :fisher case is exactly what the old code failed.
    function nll_at_thetahat(fit, Y)
        ad = GLLVM._family_ci(fit, Y)
        return ad.nll(ad.θ)
    end
    @testset "rebuilt nll(θ̂) == −loglik under both selectors" begin
        for h in (:observed, :fisher)
            fg = GLLVM.fit_gamma_gllvm(Yg; K = K, hessian = h)
            @test isapprox(nll_at_thetahat(fg, Yg), -fg.loglik; atol = 1e-8)
            fn = GLLVM.fit_nb_gllvm(Ynb; K = K, hessian = h)
            @test isapprox(nll_at_thetahat(fn, Ynb), -fn.loglik; atol = 1e-8)
            fe = GLLVM.fit_exponential_gllvm(Yex; K = K, hessian = h)
            @test isapprox(nll_at_thetahat(fe, Yex), -fe.loglik; atol = 1e-8)
        end
    end

    # And the two selectors genuinely build different CI objectives where the
    # curvatures differ (Gamma/log is non-canonical): same data, the :fisher
    # fit's rebuilt objective must NOT equal the :observed fit's at a common
    # point — otherwise the threading is decorative.
    @testset "the selector reaches the CI objective" begin
        fo = GLLVM.fit_gamma_gllvm(Yg; K = K, hessian = :observed)
        ff = GLLVM.fit_gamma_gllvm(Yg; K = K, hessian = :fisher)
        ao = GLLVM._family_ci(fo, Yg); af = GLLVM._family_ci(ff, Yg)
        @test !isapprox(ao.nll(ao.θ), af.nll(ao.θ); atol = 1e-6)
    end
end
