using GLLVM, Test, Random

@testset "Offsets in the linear predictor" begin
    Random.seed!(4242)
    p, n, K = 4, 9, 2
    β = randn(p) .* 0.3
    Λ = randn(p, K) .* 0.4
    Y = rand(0:6, p, n)

    # ---- Anchor 1: offset = 0 ≡ no offset (machine precision) --------------
    ℓ0 = GLLVM.marginal_loglik_laplace(Poisson(), Y, ones(Int, p, n), Λ, β, LogLink())
    ℓz = GLLVM.marginal_loglik_laplace(Poisson(), Y, ones(Int, p, n), Λ, β, LogLink();
                                       offset = zeros(p, n))
    @test isapprox(ℓ0, ℓz; atol = 1e-10)

    # ---- Anchor 2: offset-absorption identity (machine precision) ----------
    # A constant per-species offset c_t shifts that species' intercept:
    #   η = β + offset + Λz  with offset[t,s] = c_t  ==  η = (β + c) + Λz.
    c = randn(p) .* 0.5
    O = repeat(c, 1, n)                       # p×n, constant within each species row
    ℓ_off  = GLLVM.marginal_loglik_laplace(Poisson(), Y, ones(Int, p, n), Λ, β,     LogLink(); offset = O)
    ℓ_shift = GLLVM.marginal_loglik_laplace(Poisson(), Y, ones(Int, p, n), Λ, β .+ c, LogLink())
    @test isapprox(ℓ_off, ℓ_shift; atol = 1e-9)

    # ---- Anchor 3: a general (non-constant) offset changes the marginal ----
    Ovar = randn(p, n) .* 0.3
    ℓ_var = GLLVM.marginal_loglik_laplace(Poisson(), Y, ones(Int, p, n), Λ, β, LogLink(); offset = Ovar)
    @test isfinite(ℓ_var)
    @test ℓ_var != ℓ0

    # ---- Fit-level absorption: fitting with a constant offset c recovers the
    # no-offset intercepts shifted by −c (same loglik), since the model is
    # reparameterised. -------------------------------------------------------
    Random.seed!(11)
    Yf = rand(0:5, p, n)
    f0 = fit_poisson_gllvm(Yf; K = K, iterations = 60)
    fO = fit_poisson_gllvm(Yf; K = K, offset = O, iterations = 60)
    @test isapprox(f0.loglik, fO.loglik; atol = 1e-4)         # same maximised likelihood
    @test isapprox(f0.β, fO.β .+ c; atol = 1e-2)              # intercepts shifted by −c
end
