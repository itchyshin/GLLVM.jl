# Missing-RESPONSE (NA in Y) keystone for the non-Gaussian dense-Laplace path
# (full-capability track T1). An optional per-observation mask drops the masked
# (unobserved) cells of Y from the per-site likelihood, gradient, and marginal —
# so the marginal is exactly the marginal over the OBSERVED cells.
#
# This file is the independent contract test for that mask:
#   (1) masked marginal == hand-computed marginal that DROPS the masked entries,
#       built by an INDEPENDENT route (row-subsetting Λ/β/y per site, no mask);
#   (2) a non-Gaussian GLLVM (Poisson AND Binomial) fits on data with a handful
#       of Y entries missing and recovers parameters close to the complete-data
#       fit / true values;
#   (3) the masked Laplace objective's gradient matches a central finite
#       difference to ≤ 1e-6 (the CLAUDE.md Planned-next gradient bar).

using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

# Build the marginal that physically DROPS the masked rows per site, by passing
# only the OBSERVED sub-rows of (Λ, β, y, n) to the unmasked per-site Laplace.
# This is a different code path from the `mask=` keyword (which keeps full-length
# vectors and zeros the masked score/weight/logpdf), so it is an independent
# oracle for the masking semantics.
function _marginal_dropmissing(family, Y, N, Λ, β, link, mask)
    p, n = size(Y)
    acc = 0.0
    for s in 1:n
        obs = findall(view(mask, :, s))
        isempty(obs) && continue                     # fully-masked site ⇒ 0
        acc += GLLVM.laplace_loglik_site(family, Y[obs, s], N[obs, s],
                                         Λ[obs, :], β[obs], link)
    end
    return acc
end

@testset "Missing responses (NA in Y) — dense-Laplace mask" begin

    # ----------------------------------------------------------------------
    # (1) masked marginal == hand-computed drop-the-missing marginal
    # ----------------------------------------------------------------------
    @testset "masked marginal == hand-dropped marginal" begin
        Random.seed!(7)
        p, n, K = 6, 12, 2
        β = randn(p) .* 0.3
        Λ = randn(p, K) .* 0.4

        # --- Poisson ---
        Yp = rand(0:6, p, n)
        Np = ones(Int, p, n)
        mask = trues(p, n)
        for (t, s) in [(1, 2), (3, 5), (4, 8), (2, 1), (5, 3), (6, 11), (1, 12)]
            mask[t, s] = false
        end
        ℓ_mask = GLLVM.marginal_loglik_laplace(Poisson(), Yp, Np, Λ, β, LogLink();
                                               mask = mask)
        ℓ_drop = _marginal_dropmissing(Poisson(), Yp, Np, Λ, β, LogLink(), mask)
        @test isapprox(ℓ_mask, ℓ_drop; atol = 1e-9, rtol = 0)

        # --- Binomial ---
        Yb = rand(0:5, p, n)
        Nb = fill(5, p, n)
        ℓ_mask_b = GLLVM.marginal_loglik_laplace(Binomial(), Yb, Nb, Λ, β, LogitLink();
                                                 mask = mask)
        ℓ_drop_b = _marginal_dropmissing(Binomial(), Yb, Nb, Λ, β, LogitLink(), mask)
        @test isapprox(ℓ_mask_b, ℓ_drop_b; atol = 1e-9, rtol = 0)

        # backward-compat: all-observed mask == no mask, byte-for-byte path
        @test GLLVM.marginal_loglik_laplace(Poisson(), Yp, Np, Λ, β, LogLink();
                                            mask = trues(p, n)) ==
              GLLVM.marginal_loglik_laplace(Poisson(), Yp, Np, Λ, β, LogLink())
        @test GLLVM.marginal_loglik_laplace(Binomial(), Yb, Nb, Λ, β, LogitLink();
                                            mask = trues(p, n)) ==
              GLLVM.marginal_loglik_laplace(Binomial(), Yb, Nb, Λ, β, LogitLink())
    end

    # ----------------------------------------------------------------------
    # (2) FIT with NA recovers parameters close to the complete-data fit
    #     and the truth — for Poisson AND Binomial.
    # ----------------------------------------------------------------------
    @testset "Poisson fit with NA recovers ≈ complete-data / truth" begin
        Random.seed!(40)
        p, K, n = 6, 2, 400
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.5 .* randn(p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Yfull = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

        # knock out ~3% of cells at random
        mask = trues(p, n)
        nmiss = round(Int, 0.03 * p * n)
        idx = randperm(p * n)[1:nmiss]
        for I in idx
            mask[I] = false
        end
        Ym = Matrix{Union{Missing, Int}}(Yfull)
        for I in idx
            Ym[I] = missing
        end

        fit_full = fit_poisson_gllvm(Yfull; K = K)
        fit_na   = fit_poisson_gllvm(Ym;    K = K)

        @test fit_na.converged
        @test isfinite(fit_na.loglik)
        # intercepts close to complete-data fit and to truth
        @test maximum(abs.(fit_na.β .- fit_full.β)) < 0.15
        @test maximum(abs.(fit_na.β .- β_true)) < 0.4
        # rotation-invariant loading structure ΛΛ' close to complete-data + truth
        @test cor(vec(fit_na.Λ * fit_na.Λ'), vec(fit_full.Λ * fit_full.Λ')) > 0.9
        @test cor(vec(fit_na.Λ * fit_na.Λ'), vec(Λ_true * Λ_true')) > 0.7

        # explicit mask path == missing-in-Y path (same observed cells)
        fit_mask = fit_poisson_gllvm(Yfull; K = K, mask = mask)
        @test isapprox(fit_mask.loglik, fit_na.loglik; atol = 1e-6)
        @test isapprox(fit_mask.β, fit_na.β; atol = 1e-6)
    end

    @testset "Binomial fit with NA recovers ≈ complete-data / truth" begin
        Random.seed!(20)
        p, n, K = 6, 400, 1
        link = LogitLink()
        Λtrue = 1.2 .* randn(p, K)
        βtrue = 0.4 .* randn(p)
        Z = randn(K, n)
        η = βtrue .+ Λtrue * Z
        P = 1 ./ (1 .+ exp.(-η))
        Yfull = Int.(rand(p, n) .< P)

        mask = trues(p, n)
        nmiss = round(Int, 0.03 * p * n)
        idx = randperm(p * n)[1:nmiss]
        for I in idx
            mask[I] = false
        end
        Ym = Matrix{Union{Missing, Int}}(Yfull)
        for I in idx
            Ym[I] = missing
        end

        fit_full = fit_binomial_gllvm(Yfull; K = K, link = link)
        fit_na   = fit_binomial_gllvm(Ym;    K = K, link = link)

        @test fit_na.converged
        @test isfinite(fit_na.loglik)
        @test maximum(abs.(fit_na.β .- fit_full.β)) < 0.25
        @test cor(fit_na.β, βtrue) > 0.7
        @test cor(vec(fit_na.Λ * fit_na.Λ'), vec(Λtrue * Λtrue')) > 0.7

        fit_mask = fit_binomial_gllvm(Yfull; K = K, link = link, mask = mask)
        @test isapprox(fit_mask.loglik, fit_na.loglik; atol = 1e-6)
        @test isapprox(fit_mask.β, fit_na.β; atol = 1e-6)
    end

    # ----------------------------------------------------------------------
    # (3) masked objective gradient: analytic (ForwardDiff + implicit-step) vs
    #     central finite difference of the masked marginal, to ≤ 1e-6.
    #     The analytic gradient (poisson/binomial_laplace_grad) now carries the
    #     same mask as the core marginal; the FD reference is taken on the
    #     marginal_loglik_laplace(...; mask) objective the fitter actually uses.
    # ----------------------------------------------------------------------
    @testset "masked-objective gradient: analytic vs central FD ≤ 1e-6" begin
        Random.seed!(123)
        p, n, K = 5, 14, 2
        rr = GLLVM.rr_theta_len(p, K)
        β0 = randn(p) .* 0.3
        Λ0 = randn(p, K) .* 0.4

        mask = trues(p, n)
        for (t, s) in [(1, 2), (3, 5), (4, 8), (2, 1), (5, 3), (2, 13)]
            mask[t, s] = false
        end

        θ = vcat(β0, GLLVM.pack_lambda(Λ0))

        # central finite difference of the (negative-of-irrelevant: use +marginal)
        # masked marginal — the verification oracle.
        function central_fd(f, θ; h = 1e-6)
            g = similar(θ)
            for i in eachindex(θ)
                θp = copy(θ); θp[i] += h
                θm = copy(θ); θm[i] -= h
                g[i] = (f(θp) - f(θm)) / (2h)
            end
            return g
        end

        # --- Poisson ---
        Yp = rand(0:6, p, n)
        Np = ones(Int, p, n)
        fpois = θ -> begin
            β = θ[1:p]
            Λ = GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K)
            GLLVM.marginal_loglik_laplace(Poisson(), Yp, Np, Λ, β, LogLink();
                                          mask = mask, maxiter = 200, tol = 1e-12)
        end
        g_an_p = GLLVM.poisson_laplace_grad(Yp, Λ0, β0; mask = mask)
        g_fd_p = central_fd(fpois, θ)
        maxdiff_p = maximum(abs.(g_an_p .- g_fd_p))
        @test maxdiff_p ≤ 1e-6

        # --- Binomial ---
        Yb = rand(0:5, p, n)
        Nb = fill(5, p, n)
        fbin = θ -> begin
            β = θ[1:p]
            Λ = GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K)
            GLLVM.marginal_loglik_laplace(Binomial(), Yb, Nb, Λ, β, LogitLink();
                                          mask = mask, maxiter = 200, tol = 1e-12)
        end
        g_an_b = GLLVM.binomial_laplace_grad(Yb, Nb, Λ0, β0; mask = mask)
        g_fd_b = central_fd(fbin, θ)
        maxdiff_b = maximum(abs.(g_an_b .- g_fd_b))
        @test maxdiff_b ≤ 1e-6

        # backward-compat: an all-true mask == no-mask analytic gradient (the
        # masked code path reduces exactly to the legacy gradient).
        @test isapprox(GLLVM.poisson_laplace_grad(Yp, Λ0, β0; mask = trues(p, n)),
                       GLLVM.poisson_laplace_grad(Yp, Λ0, β0); atol = 0, rtol = 0)
        @test isapprox(GLLVM.binomial_laplace_grad(Yb, Nb, Λ0, β0; mask = trues(p, n)),
                       GLLVM.binomial_laplace_grad(Yb, Nb, Λ0, β0); atol = 0, rtol = 0)

        @info "masked-objective analytic vs FD" maxdiff_poisson=maxdiff_p maxdiff_binomial=maxdiff_b
    end
end
