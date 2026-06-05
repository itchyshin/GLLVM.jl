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
end
