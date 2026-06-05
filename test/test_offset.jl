using GLLVM, Test, Random, Distributions

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

    # ---- Same absorption across the NB / Binomial / Beta / Gamma fitters ----
    # A constant per-species offset shifts β by −c, leaving the dispersion and the
    # maximised loglik unchanged (the warm start subtracts the offset, so the
    # optimisation traces the identical path up to the β-shift).
    @testset "offset absorption across GLM fitters" begin
        Random.seed!(7)
        pp, nn = 4, 12
        cc = randn(pp) .* 0.4
        O2 = repeat(cc, 1, nn)

        Yn = rand(0:6, pp, nn)
        a0 = fit_nb_gllvm(Yn; K = 1, iterations = 60)
        aO = fit_nb_gllvm(Yn; K = 1, offset = O2, iterations = 60)
        @test isapprox(a0.loglik, aO.loglik; atol = 1e-4)
        @test isapprox(a0.β, aO.β .+ cc; atol = 2e-2)
        @test isapprox(a0.r, aO.r; rtol = 1e-3)

        Ntr = fill(6, pp, nn); Yb = rand(0:6, pp, nn)
        b0 = fit_binomial_gllvm(Yb; K = 1, N = Ntr, iterations = 60)
        bO = fit_binomial_gllvm(Yb; K = 1, N = Ntr, offset = O2, iterations = 60)
        @test isapprox(b0.loglik, bO.loglik; atol = 1e-4)
        @test isapprox(b0.β, bO.β .+ cc; atol = 2e-2)

        Ybeta = clamp.(rand(pp, nn), 0.02, 0.98)
        c0 = fit_beta_gllvm(Ybeta; K = 1, iterations = 60)
        cO = fit_beta_gllvm(Ybeta; K = 1, offset = O2, iterations = 60)
        @test isapprox(c0.loglik, cO.loglik; atol = 1e-4)
        @test isapprox(c0.β, cO.β .+ cc; atol = 2e-2)
        @test isapprox(c0.φ, cO.φ; rtol = 1e-3)

        Yg = 0.5 .+ 2 .* rand(pp, nn)
        g0 = fit_gamma_gllvm(Yg; K = 1, iterations = 60)
        gO = fit_gamma_gllvm(Yg; K = 1, offset = O2, iterations = 60)
        @test isapprox(g0.loglik, gO.loglik; atol = 1e-4)
        @test isapprox(g0.β, gO.β .+ cc; atol = 2e-2)
        @test isapprox(g0.α, gO.α; rtol = 1e-3)
    end

    # ---- Two-part substrate: offset on the positive part (offsetc) ---------
    # η^c = β^c + offsetc + Λ^c z. offsetc = 0 ≡ no offset; a constant per-species
    # offsetc ≡ shifting β^c (the absorption identity), both machine precision.
    @testset "two-part offsetc absorption (Delta-Gamma marginal)" begin
        Random.seed!(515)
        pp, K, nn = 4, 1, 30
        βz = 0.3 .* randn(pp); βc = 0.2 .* randn(pp); α = 3.0
        Λc = 0.3 .* randn(pp, K)
        Y = zeros(pp, nn)
        for s in 1:nn
            ηc = βc .+ Λc * randn(K)
            for t in 1:pp
                rand() < inv(1 + exp(-βz[t])) && (Y[t, s] = rand(Gamma(α, exp(ηc[t]) / α)))
            end
        end

        ℓ0 = GLLVM.delta_gamma_marginal_loglik_laplace(Y, Λc, βz, βc, α)
        ℓz = GLLVM.delta_gamma_marginal_loglik_laplace(Y, Λc, βz, βc, α; offsetc = zeros(pp, nn))
        @test isapprox(ℓ0, ℓz; atol = 1e-9)

        cc = 0.5 .* randn(pp); O = repeat(cc, 1, nn)
        ℓ_off = GLLVM.delta_gamma_marginal_loglik_laplace(Y, Λc, βz, βc, α; offsetc = O)
        ℓ_sh  = GLLVM.delta_gamma_marginal_loglik_laplace(Y, Λc, βz, βc .+ cc, α)
        @test isapprox(ℓ_off, ℓ_sh; atol = 1e-8)

        # A non-constant offsetc changes the marginal.
        ℓ_v = GLLVM.delta_gamma_marginal_loglik_laplace(Y, Λc, βz, βc, α; offsetc = 0.3 .* randn(pp, nn))
        @test isfinite(ℓ_v) && ℓ_v != ℓ0
    end
end
