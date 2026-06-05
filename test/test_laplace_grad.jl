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
end
