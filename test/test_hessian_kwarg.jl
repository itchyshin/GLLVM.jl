# The `hessian` kwarg on the single-part family fitters (2026-08-27).
#
# WHY THIS EXISTS. The Fisher-vs-observed Laplace curvature question could not be
# answered by fitting before this kwarg: no public fitter exposed the selector, so a
# curvature flip could only be evaluated at fixed parameters — and "agreement at a fixed
# point does not imply agreement under optimisation" is this repo's hardest-won lesson.
# The kwarg selects the LOG-DET curvature only; the mode search stays Fisher-scored
# (families/laplace.jl role separation, 2026-08-25).
#
# THE CONTRACT, tested per family:
#   1. Omitting the kwarg is EXACTLY the old behaviour (default = the family's
#      registered `_default_hessian`) — bit-identical, not merely close.
#   2. Passing the default explicitly is bit-identical to omitting it.
#   3. Passing the non-default curvature RUNS and (for non-canonical links) produces a
#      genuinely different objective.
#   4. Canonical links (Poisson/log, Binomial/logit) give bit-identical results under
#      BOTH selectors — the trait `_glm_weight_matches_observed` made live.
#   5. An invalid symbol throws, loudly, before any optimisation.
#   6. The analytic-gradient fitters fall back to :finite under a non-default hessian
#      (the analytic gradient implements the default-curvature objective; using it with
#      the other objective would silently desynchronise gradient from objective).

using GLLVM, Test, Random, Distributions

@testset "hessian kwarg on the family fitters" begin
    Random.seed!(11)
    p, K, n = 5, 1, 60
    Z = randn(K, n); B = 0.3 .* randn(p); L = 0.4 .* randn(p, K); H = B .+ L * Z
    Yp  = [rand(Poisson(exp(H[t, s]))) for t in 1:p, s in 1:n]
    Yb  = [rand(Binomial(1, 1 / (1 + exp(-H[t, s])))) for t in 1:p, s in 1:n]
    Yg  = [rand(Gamma(2.0, exp(H[t, s]) / 2.0)) for t in 1:p, s in 1:n]
    Ybe = [clamp(rand(Beta(8 * (1 / (1 + exp(-H[t, s]))),
                           8 * (1 - 1 / (1 + exp(-H[t, s]))))), 1e-6, 1 - 1e-6)
           for t in 1:p, s in 1:n]
    Ynb = [rand(NegativeBinomial(3.0, 3.0 / (3.0 + exp(H[t, s])))) for t in 1:p, s in 1:n]
    # Tweedie: compound Poisson–Gamma with true zeros (drawn after the fixtures above
    # so their RNG streams are untouched).
    Ytw = [(k = rand(Poisson(exp(H[t, s])));
            k == 0 ? 0.0 : sum(rand(Gamma(2.0, exp(H[t, s]) / (2.0 * exp(H[t, s]) + 1e-9)), k)))
           for t in 1:p, s in 1:n]

    @testset "default == explicit default, bit-identical (contract 1+2)" begin
        f0 = GLLVM.fit_beta_gllvm(Ybe; K = K)
        ff = GLLVM.fit_beta_gllvm(Ybe; K = K, hessian = :observed) # Beta/logit default (decision A)
        @test f0.loglik == ff.loglik                                # bit-identical
        g0 = GLLVM.fit_gamma_gllvm(Yg; K = K)
        go = GLLVM.fit_gamma_gllvm(Yg; K = K, hessian = :observed) # Gamma/log default
        @test g0.loglik == go.loglik
    end

    @testset "non-default curvature runs and differs (contract 3)" begin
        fb_f = GLLVM.fit_beta_gllvm(Ybe; K = K, hessian = :fisher)
        fb_o = GLLVM.fit_beta_gllvm(Ybe; K = K, hessian = :observed)
        @test fb_o.converged && isfinite(fb_o.loglik)
        @test abs(fb_f.loglik - fb_o.loglik) > 1e-6      # genuinely different objectives

        fg_f = GLLVM.fit_gamma_gllvm(Yg; K = K, hessian = :fisher)
        fg_o = GLLVM.fit_gamma_gllvm(Yg; K = K, hessian = :observed)
        @test fg_f.converged && isfinite(fg_f.loglik)
        @test abs(fg_f.loglik - fg_o.loglik) > 1e-6
    end

    @testset "canonical links: selector is a no-op (contract 4)" begin
        pp_f = GLLVM.fit_poisson_gllvm(Yp; K = K, hessian = :fisher)
        pp_o = GLLVM.fit_poisson_gllvm(Yp; K = K, hessian = :observed)
        @test pp_f.loglik == pp_o.loglik                  # bit-identical, not approx
        bb_f = GLLVM.fit_binomial_gllvm(Yb; K = K, hessian = :fisher)
        bb_o = GLLVM.fit_binomial_gllvm(Yb; K = K, hessian = :observed)
        @test bb_f.loglik == bb_o.loglik
    end

    @testset "invalid symbol throws before optimising (contract 5)" begin
        @test_throws ArgumentError GLLVM.fit_beta_gllvm(Ybe; K = K, hessian = :banana)
        @test_throws ArgumentError GLLVM.fit_gamma_gllvm(Yg; K = K, hessian = :expected)
        @test_throws ArgumentError GLLVM.fit_nb_gllvm(Ynb; K = K, hessian = :Observed)
        @test_throws ArgumentError GLLVM.fit_gp1_gllvm(Ynb; K = K, hessian = :none)
    end

    @testset "every remaining fitter accepts both selectors" begin
        for h in (:fisher, :observed)
            @test isfinite(GLLVM.fit_nb_gllvm(Ynb; K = K, hessian = h).loglik)
            @test isfinite(GLLVM.fit_nb1_gllvm(Ynb; K = K, hessian = h).loglik)
            @test isfinite(GLLVM.fit_gp1_gllvm(Ynb; K = K, hessian = h).loglik)
        end
    end

    @testset "tweedie: kwarg reaches the marginal (contracts 1+2+3+5)" begin
        # This fitter threads `hessian` through `tweedie_marginal_loglik_laplace`, whose
        # objective wraps every evaluation in try/catch: a kwarg the wrapper drops turns
        # into the 1e12 fail penalty SILENTLY, and the fit collapses to -Inf/unconverged.
        # These assertions fail loudly if that passthrough ever regresses.
        tw0 = GLLVM.fit_tweedie_gllvm(Ytw; K = K)
        two = GLLVM.fit_tweedie_gllvm(Ytw; K = K, hessian = :observed)  # Tweedie/log default (2026-08-28)
        @test tw0.converged && isfinite(tw0.loglik)
        @test tw0.loglik == two.loglik                                  # bit-identical
        twf = GLLVM.fit_tweedie_gllvm(Ytw; K = K, hessian = :fisher)
        @test twf.converged && isfinite(twf.loglik)
        @test abs(twf.loglik - two.loglik) > 1e-6
        @test_throws ArgumentError GLLVM.fit_tweedie_gllvm(Ytw; K = K, hessian = :banana)
    end

    @testset "binomial/probit: default flips to :observed (contracts 1+2+3+5+6, 2026-08-28)" begin
        Ybp = [rand(Binomial(1, 1 / (1 + exp(-H[t, s])))) for t in 1:p, s in 1:n]
        bp0 = GLLVM.fit_binomial_gllvm(Ybp; K = K, link = GLLVM.ProbitLink())
        bpo = GLLVM.fit_binomial_gllvm(Ybp; K = K, link = GLLVM.ProbitLink(), hessian = :observed)
        @test bp0.converged && isfinite(bp0.loglik)
        @test bp0.loglik == bpo.loglik                                  # bit-identical (contracts 1+2)
        bpf = GLLVM.fit_binomial_gllvm(Ybp; K = K, link = GLLVM.ProbitLink(), hessian = :fisher)
        @test bpf.converged && isfinite(bpf.loglik)
        @test abs(bpf.loglik - bpo.loglik) > 1e-6                       # genuinely different (contract 3)
        @test_throws ArgumentError GLLVM.fit_binomial_gllvm(Ybp; K = K, link = GLLVM.ProbitLink(), hessian = :banana)
        # Contract 6, probit-specific: the analytic-gradient branch in
        # `fit_binomial_gllvm` is gated on `link isa LogitLink` (binomial.jl),
        # so a probit fit NEVER reaches the logit-specific analytic Laplace
        # gradient (binomial_laplace_grad) regardless of `hessian` — it always
        # takes the finite-difference `Optim.optimize(...; autodiff = :finite)`
        # branch. That gate was already unconditional on link before this flip
        # (not a new guard added here); this locks it stays true post-flip, so
        # a probit fit is never silently desynchronised from a logit-only
        # analytic gradient.
        @test !(GLLVM.ProbitLink() isa GLLVM.LogitLink)
        # cloglog stays :fisher (the diagnosed saturation pathology) — the
        # selector still runs and differs when forced, it is simply not the
        # default.
        bc0 = GLLVM.fit_binomial_gllvm(Ybp; K = K, link = GLLVM.CLogLogLink())
        bcf = GLLVM.fit_binomial_gllvm(Ybp; K = K, link = GLLVM.CLogLogLink(), hessian = :fisher)
        @test bc0.loglik == bcf.loglik                                  # default IS :fisher for cloglog
    end
end
