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
end
