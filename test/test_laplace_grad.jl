using GLLVM, Test, Random, LinearAlgebra

# The exact (ForwardDiff + implicit-step) Poisson Laplace gradient must match a
# central finite-difference gradient of the marginal — the FD-vs-analytic check that
# gates issue #65's analytic-gradient lever.

@testset "Poisson Laplace analytic gradient (issue #65)" begin
    Random.seed!(909)
    p, K, n = 5, 2, 24
    β = randn(p) .* 0.3
    Λ = randn(p, K) .* 0.4
    Y = rand(0:6, p, n)

    rr = GLLVM.rr_theta_len(p, K)
    θ = vcat(β, GLLVM.pack_lambda(Λ))

    # Marginal as a function of the packed θ (for the finite-difference reference).
    f = function (θv)
        b = θv[1:p]
        L = GLLVM.unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        return GLLVM.poisson_marginal_loglik_laplace(Y, L, b, LogLink();
                                                     maxiter = 200, tol = 1e-12)
    end

    # Central finite differences.
    m = length(θ)
    g_fd = similar(θ)
    h = 1e-5
    for i in 1:m
        θp = copy(θ); θp[i] += h
        θm = copy(θ); θm[i] -= h
        g_fd[i] = (f(θp) - f(θm)) / (2h)
    end

    g_an = poisson_laplace_grad(Y, Λ, β)

    @test length(g_an) == m
    @test all(isfinite, g_an)
    # Agreement to finite-difference accuracy (the analytic gradient is exact; the
    # tolerance is set by the central-difference truncation error).
    @test isapprox(g_an, g_fd; rtol = 1e-4, atol = 1e-4)

    # ---- Binomial (logit) — same technique, second family -----------------
    @testset "Binomial" begin
        Nb = fill(8, p, n)
        Yb = [rand(0:Nb[t, s]) for t in 1:p, s in 1:n]
        θb = vcat(β, GLLVM.pack_lambda(Λ))
        fb = function (θv)
            b = θv[1:p]
            L = GLLVM.unpack_lambda(θv[(p + 1):(p + rr)], p, K)
            return GLLVM.binomial_marginal_loglik_laplace(Yb, Nb, L, b, LogitLink();
                                                          maxiter = 200, tol = 1e-12)
        end
        gfd = similar(θb)
        for i in 1:length(θb)
            θp = copy(θb); θp[i] += h
            θm = copy(θb); θm[i] -= h
            gfd[i] = (fb(θp) - fb(θm)) / (2h)
        end
        gan = binomial_laplace_grad(Yb, Nb, Λ, β)
        @test all(isfinite, gan)
        @test isapprox(gan, gfd; rtol = 1e-4, atol = 1e-4)
    end

    # ---- Negative binomial (log) — dispersion family; r in θ as log r ------
    @testset "Negative binomial (with dispersion)" begin
        rdisp = 4.0
        Yn = rand(0:8, p, n)
        θn = vcat(β, GLLVM.pack_lambda(Λ), log(rdisp))      # last entry = log r
        fn = function (θv)
            b = θv[1:p]
            L = GLLVM.unpack_lambda(θv[(p + 1):(p + rr)], p, K)
            rr_ = exp(θv[p + rr + 1])
            return GLLVM.nb_marginal_loglik_laplace(Yn, L, b, rr_;
                                                    maxiter = 200, tol = 1e-12)
        end
        gfd = similar(θn)
        for i in 1:length(θn)
            θp = copy(θn); θp[i] += h
            θm = copy(θn); θm[i] -= h
            gfd[i] = (fn(θp) - fn(θm)) / (2h)
        end
        gan = nb_laplace_grad(Yn, Λ, β, rdisp)
        @test length(gan) == length(θn)                      # includes the log r direction
        @test all(isfinite, gan)
        @test isapprox(gan, gfd; rtol = 1e-4, atol = 1e-4)
    end

    # ---- Gamma (log link) — dispersion family, non-canonical --------------
    @testset "Gamma (with shape α)" begin
        αsh = 3.0
        Yg = 0.5 .+ 2 .* rand(p, n)                  # positive responses
        θg = vcat(β, GLLVM.pack_lambda(Λ), log(αsh))
        fg = function (θv)
            b = θv[1:p]
            L = GLLVM.unpack_lambda(θv[(p + 1):(p + rr)], p, K)
            a = exp(θv[p + rr + 1])
            return GLLVM.gamma_marginal_loglik_laplace(Yg, L, b, a; maxiter = 200, tol = 1e-12)
        end
        gfd = similar(θg)
        for i in 1:length(θg)
            θp = copy(θg); θp[i] += h
            θm = copy(θg); θm[i] -= h
            gfd[i] = (fg(θp) - fg(θm)) / (2h)
        end
        gan = gamma_laplace_grad(Yg, Λ, β, αsh)
        @test length(gan) == length(θg)
        @test all(isfinite, gan)
        @test isapprox(gan, gfd; rtol = 1e-4, atol = 1e-4)
    end

    # ---- Beta (logit link) — non-canonical; observed weight via AD ---------
    @testset "Beta (with precision φ)" begin
        φp = 7.0
        Yb2 = clamp.(rand(p, n), 0.02, 0.98)             # responses in (0,1)
        θb2 = vcat(β, GLLVM.pack_lambda(Λ), log(φp))
        fb2 = function (θv)
            b = θv[1:p]
            L = GLLVM.unpack_lambda(θv[(p + 1):(p + rr)], p, K)
            ph = exp(θv[p + rr + 1])
            return GLLVM.beta_marginal_loglik_laplace(Yb2, L, b, ph; maxiter = 200, tol = 1e-12)
        end
        gfd = similar(θb2)
        for i in 1:length(θb2)
            θp = copy(θb2); θp[i] += h
            θm = copy(θb2); θm[i] -= h
            gfd[i] = (fb2(θp) - fb2(θm)) / (2h)
        end
        gan = beta_laplace_grad(Yb2, Λ, β, φp)
        @test length(gan) == length(θb2)
        @test all(isfinite, gan)
        @test isapprox(gan, gfd; rtol = 1e-4, atol = 1e-4)
    end

    # ---- Opt-in analytic-gradient fit matches the finite-difference fit ----
    # Same objective + warm start, only the gradient differs, so both converge to
    # the same optimum (loglik + identifiable intercepts agree).
    @testset "fit_poisson_gllvm gradient=:analytic" begin
        Random.seed!(77)
        pp, KK, nn = 4, 1, 40
        Yf = rand(0:5, pp, nn)
        f_fd = fit_poisson_gllvm(Yf; K = KK, gradient = :finite, iterations = 300)
        f_an = fit_poisson_gllvm(Yf; K = KK, gradient = :analytic, iterations = 300)
        f_default = fit_poisson_gllvm(Yf; K = KK, iterations = 300)
        @test isfinite(f_an.loglik)
        @test isapprox(f_fd.loglik, f_an.loglik; atol = 1e-3)
        @test isapprox(f_default.loglik, f_an.loglik; atol = 1e-8)
        @test isapprox(f_fd.β, f_an.β; atol = 5e-2)
    end

    # ---- gradient=:analytic matches :finite across the other GLM fitters ----
    @testset "analytic-gradient fits (Binomial/NB/Gamma/Beta)" begin
        Random.seed!(2468)
        pp, KK, nn = 4, 1, 40

        Nb = fill(6, pp, nn)
        Yb = [rand(0:6) for t in 1:pp, s in 1:nn]
        b_fd = fit_binomial_gllvm(Yb; K = KK, N = Nb, gradient = :finite, iterations = 300)
        b_an = fit_binomial_gllvm(Yb; K = KK, N = Nb, gradient = :analytic, iterations = 300)
        b_default = fit_binomial_gllvm(Yb; K = KK, N = Nb, iterations = 300)
        @test isapprox(b_fd.loglik, b_an.loglik; atol = 1e-3)
        @test isapprox(b_default.loglik, b_an.loglik; atol = 1e-8)

        Yn = rand(0:8, pp, nn)
        n_fd = fit_nb_gllvm(Yn; K = KK, gradient = :finite, iterations = 300)
        n_an = fit_nb_gllvm(Yn; K = KK, gradient = :analytic, iterations = 300)
        n_default = fit_nb_gllvm(Yn; K = KK, iterations = 300)
        @test isapprox(n_fd.loglik, n_an.loglik; atol = 2e-2)
        @test isapprox(n_default.loglik, n_an.loglik; atol = 1e-8)

        Yg = 0.5 .+ 2 .* rand(pp, nn)
        g_fd = fit_gamma_gllvm(Yg; K = KK, gradient = :finite, iterations = 300)
        g_an = fit_gamma_gllvm(Yg; K = KK, gradient = :analytic, iterations = 300)
        g_default = fit_gamma_gllvm(Yg; K = KK, iterations = 300)
        @test isapprox(g_fd.loglik, g_an.loglik; atol = 2e-2)
        @test isapprox(g_default.loglik, g_an.loglik; atol = 1e-8)

        Ybe = clamp.(rand(pp, nn), 0.02, 0.98)
        be_fd = fit_beta_gllvm(Ybe; K = KK, gradient = :finite, iterations = 300)
        be_an = fit_beta_gllvm(Ybe; K = KK, gradient = :analytic, iterations = 300)
        be_default = fit_beta_gllvm(Ybe; K = KK, iterations = 300)
        @test isapprox(be_fd.loglik, be_an.loglik; atol = 2e-2)
        @test isapprox(be_default.loglik, be_an.loglik; atol = 1e-8)
    end
end

# ---- Masked fits use the analytic gradient and match the finite-difference fit ----
# The Poisson/Binomial analytic gradients accept a response mask (masked-cell score
# and Fisher weight zeroed; FD-verified to 1e-6 in test_missing_response.jl). The
# fitter now passes the mask through and uses the analytic gradient by default for
# masked fits (offset still forces the FD path). This testset gates that the masked
# analytic fit equals the masked finite-difference fit, and that the default masked
# fit is the analytic one.
@testset "Masked analytic-gradient fits (issue #65)" begin
    Random.seed!(1234)
    pp, KK, nn = 4, 1, 40

    # Poisson, masked
    Yp = rand(0:5, pp, nn)
    maskp = trues(pp, nn)
    maskp[1, 1] = false; maskp[2, 5] = false; maskp[3, 10] = false; maskp[pp, nn] = false
    p_fd = fit_poisson_gllvm(Yp; K = KK, mask = maskp, gradient = :finite, iterations = 300)
    p_an = fit_poisson_gllvm(Yp; K = KK, mask = maskp, gradient = :analytic, iterations = 300)
    p_default = fit_poisson_gllvm(Yp; K = KK, mask = maskp, iterations = 300)
    @test isfinite(p_an.loglik)
    @test isapprox(p_fd.loglik, p_an.loglik; atol = 1e-3)
    @test isapprox(p_default.loglik, p_an.loglik; atol = 1e-8)   # default is analytic for masked

    # Binomial, masked
    Nb = fill(6, pp, nn)
    Yb = [rand(0:6) for t in 1:pp, s in 1:nn]
    maskb = trues(pp, nn)
    maskb[1, 2] = false; maskb[3, 7] = false; maskb[pp, nn - 1] = false
    b_fd = fit_binomial_gllvm(Yb; K = KK, N = Nb, mask = maskb, gradient = :finite, iterations = 300)
    b_an = fit_binomial_gllvm(Yb; K = KK, N = Nb, mask = maskb, gradient = :analytic, iterations = 300)
    b_default = fit_binomial_gllvm(Yb; K = KK, N = Nb, mask = maskb, iterations = 300)
    @test isfinite(b_an.loglik)
    @test isapprox(b_fd.loglik, b_an.loglik; atol = 1e-3)
    @test isapprox(b_default.loglik, b_an.loglik; atol = 1e-8)
end
