using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

# Missing-data (NA-aware FIML) on the generic dense-Laplace path. A missing response
# cell drops from its site's likelihood product (Rubin 1976 ignorable likelihood):
# 0 score, 0 working weight, skipped in the per-site loglik sum; the site's latent
# mode uses its observed cells only. Nothing is imputed in the likelihood (issue #27).
# MVP: Poisson via the generic Laplace path; Y as Matrix{Union{Missing,Int}}.

@testset "Missing data (NA-aware FIML, Laplace)" begin

    # ---------------------------------------------------------------------
    # Complete-data equivalence: a missing-typed Y with NO actual missings must
    # reproduce the dense path to ~machine precision (the key regression gate —
    # proves the ismissing guards do not perturb complete-data behaviour).
    # ---------------------------------------------------------------------
    @testset "complete-data equivalence (no NAs ≡ dense path)" begin
        Random.seed!(7001)
        p, K, n = 5, 1, 200
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(Poisson(), β, Λ, n; seed = 70011))
        Ym = Matrix{Union{Missing, Int}}(Y)           # same data, missing-typed, no NAs

        ll_dense = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        ll_na    = GLLVM.poisson_marginal_loglik_laplace(Ym, Λ, β)
        @test ll_na ≈ ll_dense atol = 1e-8            # byte-equivalent marginal value

        fit_dense = fit_poisson_gllvm(Y;  K = K)
        fit_na    = fit_poisson_gllvm(Ym; K = K)
        @test fit_na.loglik ≈ fit_dense.loglik atol = 1e-6
        @test maximum(abs.(fit_na.β .- fit_dense.β)) < 1e-5
        @test maximum(abs.(fit_na.Λ .- fit_dense.Λ)) < 1e-5
    end

    # ---------------------------------------------------------------------
    # NA recovery: knock out ~15% of cells at random; the FIML fit recovers the
    # complete-data fit within a generous band (some information is genuinely lost).
    # ---------------------------------------------------------------------
    @testset "NA recovery (~15% missing)" begin
        # Mild, well-conditioned rates (≈3–4) so the complete-data Poisson fit is
        # stable — the point here is NA-recovery vs the complete-data fit, not Poisson
        # fit robustness at extreme rates (a separate, pre-existing concern).
        Random.seed!(7102)
        p, K, n = 6, 2, 800
        β = log.([3.0, 4.0, 3.0, 4.0, 3.0, 4.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(Poisson(), β, Λ, n; seed = 71021))
        fit_full = fit_poisson_gllvm(Y; K = K)

        rng = MersenneTwister(71022)
        Ym = Matrix{Union{Missing, Int}}(Y)
        @inbounds for t in 1:p, s in 1:n
            rand(rng) < 0.15 && (Ym[t, s] = missing)
        end
        @test count(ismissing, Ym) > 0

        fit_na = fit_poisson_gllvm(Ym; K = K)
        @test maximum(abs.(fit_na.β .- fit_full.β)) < 0.3
        @test cor(vec(fit_na.Λ * fit_na.Λ'), vec(fit_full.Λ * fit_full.Λ')) > 0.8
    end

    # ---------------------------------------------------------------------
    # Edge cases must not crash: a fully-missing site (its marginal = ∫N(z;0,I) = 1,
    # mode = 0, A = I) and a fully-missing trait (its β/Λ row is unidentified — it must
    # not crash; the observed traits stay finite).
    # ---------------------------------------------------------------------
    @testset "edge cases (all-missing site / trait) do not crash" begin
        Random.seed!(7003)
        p, K, n = 5, 1, 120
        β = log.([4.0, 5.0, 3.0, 4.0, 5.0]); Λ = 0.3 .* randn(p, K)
        Y = round.(Int, simulate(Poisson(), β, Λ, n; seed = 70031))
        Ym = Matrix{Union{Missing, Int}}(Y)
        Ym[:, 1] .= missing                           # site 1 fully missing
        Ym[2, :] .= missing                           # trait 2 fully missing
        fit_na = fit_poisson_gllvm(Ym; K = K)         # must not throw
        @test isfinite(fit_na.loglik)
        @test all(isfinite, fit_na.β[[1, 3, 4, 5]])   # observed traits' intercepts finite
        @test size(fit_na.Λ) == (p, K)
    end
end
