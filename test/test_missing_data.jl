using GLLVM, Test, LinearAlgebra, Random

@testset "Missing data (NA) handling" begin
    Random.seed!(2024)
    p, n, K = 5, 8, 2
    β = randn(p) .* 0.3
    Λ = randn(p, K) .* 0.4
    Y = rand(0:6, p, n)

    mask = trues(p, n)
    missing_cells = [(1, 2), (3, 5), (4, 8), (2, 1), (5, 3)]
    for (t, s) in missing_cells
        mask[t, s] = false
    end

    # ---- Anchor 1: all-observed mask == no mask (backward compat) ----------
    ℓ_full = GLLVM.marginal_loglik_laplace(Poisson(), Y, ones(Int, p, n), Λ, β, LogLink())
    ℓ_truemask = GLLVM.marginal_loglik_laplace(Poisson(), Y, ones(Int, p, n), Λ, β,
                                               LogLink(); mask = trues(p, n))
    @test isapprox(ℓ_full, ℓ_truemask; atol = 1e-10)

    # ---- Anchor 2: marginal is invariant to the values in masked cells -----
    # The defining property of NA handling: garbage in the unobserved cells must
    # not change the log-likelihood.
    Yg = copy(Y)
    for (t, s) in missing_cells
        Yg[t, s] = 9999
    end
    ℓ_a = GLLVM.marginal_loglik_laplace(Poisson(), Y,  ones(Int, p, n), Λ, β, LogLink(); mask = mask)
    ℓ_b = GLLVM.marginal_loglik_laplace(Poisson(), Yg, ones(Int, p, n), Λ, β, LogLink(); mask = mask)
    @test isapprox(ℓ_a, ℓ_b; atol = 1e-10)
    @test ℓ_a != ℓ_full             # masking changes the marginal (sanity: mask is active)

    # ---- Anchor 3: a fully-masked site contributes exactly 0 ---------------
    maskcol = trues(p, 2)
    maskcol[:, 2] .= false          # second site entirely unobserved
    Y2 = Y[:, 1:2]
    ℓ_2 = GLLVM.marginal_loglik_laplace(Poisson(), Y2, ones(Int, p, 2), Λ, β,
                                        LogLink(); mask = maskcol)
    ℓ_1 = GLLVM.laplace_loglik_site(Poisson(), view(Y2, :, 1), ones(Int, p), Λ, β, LogLink())
    @test isapprox(ℓ_2, ℓ_1; atol = 1e-10)   # masked site adds 0 ⇒ equals the lone observed site

    # ---- observed_mask derives the mask from `missing` ---------------------
    Ym = Matrix{Union{Missing, Int}}(Y)
    for (t, s) in missing_cells
        Ym[t, s] = missing
    end
    @test GLLVM.observed_mask(Ym) == mask

    # ---- Anchor 4: the FIT is invariant to masked-cell values --------------
    fitA = fit_poisson_gllvm(Y;  K = K, mask = mask, iterations = 40)
    fitB = fit_poisson_gllvm(Yg; K = K, mask = mask, iterations = 40)
    @test isapprox(fitA.loglik, fitB.loglik; atol = 1e-8)
    @test isapprox(fitA.β, fitB.β; atol = 1e-7)
    @test isapprox(vec(fitA.Λ), vec(fitB.Λ); atol = 1e-7)

    # ---- Fit straight from a matrix containing `missing` -------------------
    fitM = fit_poisson_gllvm(Ym; K = K, iterations = 40)
    @test isfinite(fitM.loglik)
    @test isapprox(fitM.loglik, fitA.loglik; atol = 1e-8)

    # ---- NB fitter: same NA invariance (the masked cells are ignored) ------
    nbA = fit_nb_gllvm(Y;  K = K, mask = mask, iterations = 40)
    nbB = fit_nb_gllvm(Yg; K = K, mask = mask, iterations = 40)
    @test isapprox(nbA.loglik, nbB.loglik; atol = 1e-8)
    @test isapprox(nbA.r, nbB.r; atol = 1e-6)

    # ---- Beta / Gamma / Binomial fitters honour NA ------------------------
    # Fitting with an explicit mask (original values in the masked cells) must
    # equal fitting the same data with those cells set to `missing` — both ignore
    # the masked cells (objective + mask-respecting warm start), so identical fit.
    @testset "continuous & binomial fitters honour the mask" begin
        Random.seed!(99)
        pp, nn = 4, 10
        msk2 = trues(pp, nn)
        for (t, s) in [(1, 3), (2, 7), (4, 1), (3, 9)]
            msk2[t, s] = false
        end
        miss = findall(.!msk2)

        # Beta (proportions in (0,1))
        Yb  = clamp.(rand(pp, nn), 0.02, 0.98)
        Ybm = Matrix{Union{Missing, Float64}}(Yb); for I in miss; Ybm[I] = missing; end
        fb1 = fit_beta_gllvm(Yb;  K = 1, mask = msk2, iterations = 30)
        fb2 = fit_beta_gllvm(Ybm; K = 1, iterations = 30)
        @test isapprox(fb1.loglik, fb2.loglik; atol = 1e-7)

        # Gamma (positive)
        Yg2 = 0.5 .+ 2 .* rand(pp, nn)
        Ygm = Matrix{Union{Missing, Float64}}(Yg2); for I in miss; Ygm[I] = missing; end
        fg1 = fit_gamma_gllvm(Yg2; K = 1, mask = msk2, iterations = 30)
        fg2 = fit_gamma_gllvm(Ygm; K = 1, iterations = 30)
        @test isapprox(fg1.loglik, fg2.loglik; atol = 1e-7)

        # Binomial (counts out of N trials)
        Ntr = fill(5, pp, nn)
        Yco = rand(0:5, pp, nn)
        Ycm = Matrix{Union{Missing, Int}}(Yco); for I in miss; Ycm[I] = missing; end
        fc1 = fit_binomial_gllvm(Yco; K = 1, N = Ntr, mask = msk2, iterations = 30)
        fc2 = fit_binomial_gllvm(Ycm; K = 1, N = Ntr, iterations = 30)
        @test isapprox(fc1.loglik, fc2.loglik; atol = 1e-7)
    end
end
