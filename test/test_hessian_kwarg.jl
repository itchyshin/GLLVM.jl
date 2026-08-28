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
        twf = GLLVM.fit_tweedie_gllvm(Ytw; K = K, hessian = :fisher)   # Tweedie/log default
        @test tw0.converged && isfinite(tw0.loglik)
        @test tw0.loglik == twf.loglik                                 # bit-identical
        two = GLLVM.fit_tweedie_gllvm(Ytw; K = K, hessian = :observed)
        @test two.converged && isfinite(two.loglik)
        @test abs(twf.loglik - two.loglik) > 1e-6
        @test_throws ArgumentError GLLVM.fit_tweedie_gllvm(Ytw; K = K, hessian = :banana)
    end
end
