# Grouped-dispersion curvature consistency (2026-08-28).
#
# Closes the residual recorded in the one-part confint-consistency arc
# (`feat: confint rebuilds the fit's own objective — fit structs record
# their curvature`, PR #271, 2026-08-28): "the GROUPED fit structs do not
# yet record the selector (their explicit-:fisher confint path keeps the
# old behaviour)". This mirrors test/test_confint_hessian_consistency.jl for
# the grouped-dispersion family structs (NBGroupedFit, BetaGroupedFit,
# GammaGroupedFit, NB1GroupedFit): each now carries a `hessian::Symbol`
# field (positional-compat constructor defaults it to the fitter's own
# default, `:observed`), and every grouped `_family_ci` adapter threads
# `fit.hessian` into BOTH the rebuilt marginal and the bootstrap refit.
#
# TweedieGroupedFit and BetaBinomialGroupedFit/BetaBinomialGroupedCovFit are
# EXCLUDED from the selector-varies checks below: their underlying per-site
# Laplace kernels have no `hessian` selector at all (unconditional Fisher
# weight), so their `hessian` field is fixed at `:fisher` by construction —
# there is nothing for `_family_ci` to thread. BetaBinomialGroupedFit is
# still checked for the fixed-`:fisher` field and the nll(θ̂) identity.
#
# THE CONTRACT, per family × selector: the adapter's rebuilt nll, evaluated
# at the fit's own packed θ̂, equals −fit.loglik — the CI machinery
# differentiates THE SAME objective the fit maximised, whichever curvature
# that was.

using GLLVM, Test, Random, Distributions

@testset "confint rebuilds the GROUPED fit's own objective (hessian consistency)" begin
    Random.seed!(37)
    p, K, n = 5, 1, 60
    group = ones(Int, p)   # G = 1: single shared dispersion group (cheap + reduces
                            # exactly to the one-part path for a sanity cross-check)
    Z = randn(K, n); B = 0.3 .* randn(p); L = 0.4 .* randn(p, K); H = B .+ L * Z

    # NB2 / Gamma use LogLink (η = log μ); Beta uses LogitLink (η = logit μ).
    Ynb = [rand(NegativeBinomial(3.0, 3.0 / (3.0 + exp(H[t, s])))) for t in 1:p, s in 1:n]
    Yg  = [rand(Gamma(2.0, exp(H[t, s]) / 2.0)) for t in 1:p, s in 1:n]
    μβ  = 1.0 ./ (1.0 .+ exp.(-H))
    Ybe = [clamp(rand(Beta(8.0 * μβ[t, s], 8.0 * (1 - μβ[t, s]))), 1e-6, 1 - 1e-6) for t in 1:p, s in 1:n]
    Yn1 = [rand(NegativeBinomial(exp(H[t, s]) / 1.5, 1 / (1 + 1.5))) for t in 1:p, s in 1:n]

    function nll_at_thetahat(fit, Y; kwargs...)
        ad = GLLVM._family_ci(fit, Y; kwargs...)
        return ad.nll(ad.θ)
    end

    @testset "the fit records its selector (default and explicit :fisher)" begin
        @test GLLVM.fit_nb_gllvm_grouped(Ynb; K = K, group = group).hessian === :observed
        @test GLLVM.fit_nb_gllvm_grouped(Ynb; K = K, group = group, hessian = :fisher).hessian === :fisher
        @test GLLVM.fit_beta_gllvm_grouped(Ybe; K = K, group = group).hessian === :observed
        @test GLLVM.fit_beta_gllvm_grouped(Ybe; K = K, group = group, hessian = :fisher).hessian === :fisher
        @test GLLVM.fit_gamma_gllvm_grouped(Yg; K = K, group = group).hessian === :observed
        @test GLLVM.fit_gamma_gllvm_grouped(Yg; K = K, group = group, hessian = :fisher).hessian === :fisher
        @test GLLVM.fit_nb1_gllvm_grouped(Yn1; K = K, group = group).hessian === :observed
        @test GLLVM.fit_nb1_gllvm_grouped(Yn1; K = K, group = group, hessian = :fisher).hessian === :fisher
    end

    @testset "rebuilt nll(θ̂) == −loglik under both selectors (NB2/Beta/Gamma grouped)" begin
        for h in (:observed, :fisher)
            fn = GLLVM.fit_nb_gllvm_grouped(Ynb; K = K, group = group, hessian = h)
            @test isapprox(nll_at_thetahat(fn, Ynb), -fn.loglik; atol = 1e-8)
            fb = GLLVM.fit_beta_gllvm_grouped(Ybe; K = K, group = group, hessian = h)
            @test isapprox(nll_at_thetahat(fb, Ybe), -fb.loglik; atol = 1e-8)
            fg = GLLVM.fit_gamma_gllvm_grouped(Yg; K = K, group = group, hessian = h)
            @test isapprox(nll_at_thetahat(fg, Yg), -fg.loglik; atol = 1e-8)
        end
    end

    @testset "rebuilt nll(θ̂) == −loglik under both selectors (NB1 grouped, cheap add)" begin
        for h in (:observed, :fisher)
            fn1 = GLLVM.fit_nb1_gllvm_grouped(Yn1; K = K, group = group, hessian = h)
            @test isapprox(nll_at_thetahat(fn1, Yn1), -fn1.loglik; atol = 1e-8)
        end
    end

    # And the two selectors genuinely build different CI objectives where the
    # curvatures differ (NB2/log and Beta/logit are non-canonical): same
    # data, the :fisher fit's rebuilt objective must NOT equal the
    # :observed fit's at a common point — otherwise the threading is
    # decorative (exactly the class the one-part arc's test caught).
    @testset "the selector reaches the grouped CI objective" begin
        fo = GLLVM.fit_nb_gllvm_grouped(Ynb; K = K, group = group, hessian = :observed)
        ff = GLLVM.fit_nb_gllvm_grouped(Ynb; K = K, group = group, hessian = :fisher)
        ao = GLLVM._family_ci(fo, Ynb); af = GLLVM._family_ci(ff, Ynb)
        @test !isapprox(ao.nll(ao.θ), af.nll(ao.θ); atol = 1e-6)
    end

    # TweedieGroupedFit / BetaBinomialGroupedFit: no `hessian` selector exists
    # on these routes (unconditional Fisher weight) — the field is fixed at
    # `:fisher`, and there is nothing for `_family_ci` to thread. Still check
    # the field and the nll(θ̂) identity for BetaBinomialGroupedFit (cheap).
    @testset "no-selector grouped routes: field fixed at :fisher, nll(θ̂) identity holds" begin
        Nb = fill(5, p, n)
        Ybb = [rand(Binomial(5, clamp(rand(Beta(6.0 * μβ[t, s], 6.0 * (1 - μβ[t, s]))), 1e-6, 1 - 1e-6)))
               for t in 1:p, s in 1:n]
        fbb = GLLVM.fit_beta_binomial_gllvm_grouped(Ybb; K = K, N = Nb, group = group)
        @test fbb.hessian === :fisher
        @test isapprox(nll_at_thetahat(fbb, Ybb; N = Nb), -fbb.loglik; atol = 1e-8)

        Ytw = max.(Yg, 1e-6)   # reuse Gamma-shaped positive data as a Tweedie fixture
        ftw = GLLVM.fit_tweedie_gllvm_grouped(Ytw; K = K, group = group, iterations = 60)
        @test ftw.hessian === :fisher
    end
end
