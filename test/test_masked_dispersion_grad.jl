using GLLVM, Test, Random

# Masked analytic-gradient fits for the dispersion families (NB2 / Gamma / Beta).
# Their *_laplace_grad now accept a response mask (masked-cell score + observed and
# Fisher weights zeroed, masked log-pmf skipped), and the fitters use the analytic
# gradient by default for masked fits (offset still forces the FD path). This gates
# that the masked analytic fit equals the masked finite-difference fit, and that
# the default masked fit is the analytic one.
@testset "Masked analytic-gradient fits — NB / Gamma / Beta (issue #65)" begin
    Random.seed!(20260620)
    pp, KK, nn = 4, 1, 40

    mask = trues(pp, nn)
    mask[1, 1] = false; mask[2, 6] = false; mask[3, 11] = false; mask[pp, nn] = false

    # NB2 (counts)
    Yn = rand(0:8, pp, nn)
    n_fd = fit_nb_gllvm(Yn; K = KK, mask = mask, gradient = :finite, iterations = 300)
    n_an = fit_nb_gllvm(Yn; K = KK, mask = mask, gradient = :analytic, iterations = 300)
    n_default = fit_nb_gllvm(Yn; K = KK, mask = mask, iterations = 300)
    @test isfinite(n_an.loglik)
    @test isapprox(n_fd.loglik, n_an.loglik; atol = 2e-2)
    @test isapprox(n_default.loglik, n_an.loglik; atol = 1e-8)

    # Gamma (strictly positive)
    Yg = 0.5 .+ 2 .* rand(pp, nn)
    g_fd = fit_gamma_gllvm(Yg; K = KK, mask = mask, gradient = :finite, iterations = 300)
    g_an = fit_gamma_gllvm(Yg; K = KK, mask = mask, gradient = :analytic, iterations = 300)
    g_default = fit_gamma_gllvm(Yg; K = KK, mask = mask, iterations = 300)
    @test isfinite(g_an.loglik)
    @test isapprox(g_fd.loglik, g_an.loglik; atol = 2e-2)
    @test isapprox(g_default.loglik, g_an.loglik; atol = 1e-8)

    # Beta (open unit interval)
    Ybe = clamp.(rand(pp, nn), 0.02, 0.98)
    be_fd = fit_beta_gllvm(Ybe; K = KK, mask = mask, gradient = :finite, iterations = 300)
    be_an = fit_beta_gllvm(Ybe; K = KK, mask = mask, gradient = :analytic, iterations = 300)
    be_default = fit_beta_gllvm(Ybe; K = KK, mask = mask, iterations = 300)
    @test isfinite(be_an.loglik)
    @test isapprox(be_fd.loglik, be_an.loglik; atol = 2e-2)
    @test isapprox(be_default.loglik, be_an.loglik; atol = 1e-8)
end
