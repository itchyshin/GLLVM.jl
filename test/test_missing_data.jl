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
    # ZIP via the GENERIC IMPLICIT path (verifies the implicit-path NA guard, not just
    # the canonical Poisson path): complete-data equivalence + NA-recovery.
    # ---------------------------------------------------------------------
    @testset "ZIP (implicit path): equivalence + NA-recovery" begin
        Random.seed!(7201)
        p, K, n = 5, 1, 500
        β = log.([4.0, 5.0, 3.0, 4.0, 5.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(GLLVM.ZIP(0.3), β, Λ, n; dispersion = 0.3, seed = 72011))
        Ym0 = Matrix{Union{Missing, Int}}(Y)            # missing-typed, no NAs

        @test GLLVM.zip_marginal_loglik_laplace(Ym0, Λ, β, 0.3) ≈
              GLLVM.zip_marginal_loglik_laplace(Y, Λ, β, 0.3) atol = 1e-8
        fit_d = fit_zip_gllvm(Y;   K = K)
        fit_m = fit_zip_gllvm(Ym0; K = K)
        @test fit_m.loglik ≈ fit_d.loglik atol = 1e-6
        @test fit_m.π ≈ fit_d.π atol = 1e-6
        @test maximum(abs.(fit_m.β .- fit_d.β)) < 1e-5

        rng = MersenneTwister(72012)
        Ym = Matrix{Union{Missing, Int}}(Y)
        @inbounds for t in 1:p, s in 1:n
            rand(rng) < 0.15 && (Ym[t, s] = missing)
        end
        @test count(ismissing, Ym) > 0
        fit_na = fit_zip_gllvm(Ym; K = K)
        @test maximum(abs.(fit_na.β .- fit_d.β)) < 0.4
        @test 0 < fit_na.π < 1
    end

    # ---------------------------------------------------------------------
    # NB2 via the SCALAR-AUX path (verifies the aux-path NA guard): complete-data
    # equivalence + NA-recovery.
    # ---------------------------------------------------------------------
    @testset "NB2 (scalar-aux path): equivalence + NA-recovery" begin
        Random.seed!(7301)
        p, K, n = 5, 1, 500
        β = log.([4.0, 5.0, 3.0, 4.0, 5.0]); Λ = 0.4 .* randn(p, K); r = 8.0
        Y = round.(Int, simulate(NegativeBinomial(r, 0.5), β, Λ, n; dispersion = r, seed = 73011))
        Ym0 = Matrix{Union{Missing, Int}}(Y)            # missing-typed, no NAs

        @test GLLVM.nb_marginal_loglik_laplace(Ym0, Λ, β, r) ≈
              GLLVM.nb_marginal_loglik_laplace(Y, Λ, β, r) atol = 1e-8
        fit_d = fit_nb_gllvm(Y;   K = K)
        fit_m = fit_nb_gllvm(Ym0; K = K)
        @test fit_m.loglik ≈ fit_d.loglik atol = 1e-6
        @test fit_m.r ≈ fit_d.r rtol = 1e-4
        @test maximum(abs.(fit_m.β .- fit_d.β)) < 1e-5

        rng = MersenneTwister(73012)
        Ym = Matrix{Union{Missing, Int}}(Y)
        @inbounds for t in 1:p, s in 1:n
            rand(rng) < 0.15 && (Ym[t, s] = missing)
        end
        @test count(ismissing, Ym) > 0
        fit_na = fit_nb_gllvm(Ym; K = K)
        @test maximum(abs.(fit_na.β .- fit_d.β)) < 0.4
        @test isfinite(fit_na.r) && fit_na.r > 0
    end

    # ---------------------------------------------------------------------
    # Binomial (canonical path + N-threading), Beta + Gamma (scalar-aux path):
    # complete-data equivalence + NA-recovery, confirming the widened fitters.
    # ---------------------------------------------------------------------
    @testset "Binomial (canonical, N-threading): equivalence + NA-recovery" begin
        Random.seed!(7401)
        p, K, n = 5, 1, 500; Ntr = 8
        β = [-0.3, 0.5, 0.0, 0.4, -0.2]; Λ = 0.4 .* randn(p, K); Nm = fill(Ntr, p, n)
        Y = round.(Int, simulate(Binomial(), β, Λ, n; N = Nm, link = LogitLink(), seed = 74011))
        Ym0 = Matrix{Union{Missing, Int}}(Y)
        @test GLLVM.binomial_marginal_loglik_laplace(Ym0, Nm, Λ, β, LogitLink()) ≈
              GLLVM.binomial_marginal_loglik_laplace(Y, Nm, Λ, β, LogitLink()) atol = 1e-8
        fit_d = fit_binomial_gllvm(Y;   K = K, N = Nm)
        fit_m = fit_binomial_gllvm(Ym0; K = K, N = Nm)
        @test fit_m.loglik ≈ fit_d.loglik atol = 1e-6
        @test maximum(abs.(fit_m.β .- fit_d.β)) < 1e-5
        rng = MersenneTwister(74012); Ym = Matrix{Union{Missing, Int}}(Y)
        @inbounds for t in 1:p, s in 1:n
            rand(rng) < 0.15 && (Ym[t, s] = missing)
        end
        @test count(ismissing, Ym) > 0
        fit_na = fit_binomial_gllvm(Ym; K = K, N = Nm)
        @test maximum(abs.(fit_na.β .- fit_d.β)) < 0.5
    end

    @testset "Beta (aux): equivalence + NA-recovery" begin
        Random.seed!(7402)
        p, K, n = 5, 1, 500; φ = 10.0
        β = [-0.3, 0.5, 0.0, 0.4, -0.2]; Λ = 0.3 .* randn(p, K)
        Y = simulate(Beta(φ, 1.0), β, Λ, n; dispersion = φ, seed = 74021)
        Ym0 = Matrix{Union{Missing, Float64}}(Y)
        @test GLLVM.beta_marginal_loglik_laplace(Ym0, Λ, β, φ) ≈
              GLLVM.beta_marginal_loglik_laplace(Y, Λ, β, φ) atol = 1e-8
        fit_d = fit_beta_gllvm(Y;   K = K)
        fit_m = fit_beta_gllvm(Ym0; K = K)
        @test fit_m.loglik ≈ fit_d.loglik atol = 1e-6
        @test maximum(abs.(fit_m.β .- fit_d.β)) < 1e-5
        rng = MersenneTwister(74022); Ym = Matrix{Union{Missing, Float64}}(Y)
        @inbounds for t in 1:p, s in 1:n
            rand(rng) < 0.15 && (Ym[t, s] = missing)
        end
        @test count(ismissing, Ym) > 0
        fit_na = fit_beta_gllvm(Ym; K = K)
        @test maximum(abs.(fit_na.β .- fit_d.β)) < 0.5
    end

    @testset "Gamma (aux): equivalence + NA-recovery" begin
        Random.seed!(7403)
        p, K, n = 5, 1, 500; α = 3.0
        β = log.([2.0, 3.0, 2.0, 3.0, 2.0]); Λ = 0.3 .* randn(p, K)
        Y = simulate(Gamma(α, 1.0), β, Λ, n; dispersion = α, seed = 74031)
        Ym0 = Matrix{Union{Missing, Float64}}(Y)
        @test GLLVM.gamma_marginal_loglik_laplace(Ym0, Λ, β, α) ≈
              GLLVM.gamma_marginal_loglik_laplace(Y, Λ, β, α) atol = 1e-8
        fit_d = fit_gamma_gllvm(Y;   K = K)
        fit_m = fit_gamma_gllvm(Ym0; K = K)
        @test fit_m.loglik ≈ fit_d.loglik atol = 1e-5
        rng = MersenneTwister(74032); Ym = Matrix{Union{Missing, Float64}}(Y)
        @inbounds for t in 1:p, s in 1:n
            rand(rng) < 0.15 && (Ym[t, s] = missing)
        end
        @test count(ismissing, Ym) > 0
        fit_na = fit_gamma_gllvm(Ym; K = K)
        @test isfinite(fit_na.loglik) && maximum(abs.(fit_na.β .- fit_d.β)) < 0.5
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
