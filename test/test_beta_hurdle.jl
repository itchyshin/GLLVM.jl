using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# ============================================================================
# Beta-hurdle GLLVM — deterministic anchor tests
#
# Two-part model on [0,1):
#   y = 0   →  log(1 − π),           π = logistic(β^z)
#   y > 0   →  log(π) + logpdf(Beta(μφ, (1−μ)φ), y),  μ = logistic(β^c)
#
# Key anchor: with Λ = 0 the Laplace approximation is exact (the mode-finder
# converges in one step to z = 0 because the gradient is zero and the Hessian
# is I — no species share latent structure), so the marginal must equal the
# sum of independent per-cell two-part log-likelihoods to machine precision.
# ============================================================================

@testset "beta-hurdle GLLVM" begin

    # -----------------------------------------------------------------------
    # 1. Λ = 0 ⇒ exact independent two-part loglik  (machine-precision anchor)
    # -----------------------------------------------------------------------
    @testset "Λ = 0 reduces to independent two-part loglik (exact)" begin
        Random.seed!(210)
        p, K, n = 6, 2, 60
        βz = 0.4 .* randn(p)          # occurrence logits
        βc = 0.5 .* randn(p)          # positive logit-mean (logit link)
        φ  = 5.0                       # shared Beta precision

        # Simulate data from the model.
        π_true = inv.(1 .+ exp.(-βz))
        μ_true = inv.(1 .+ exp.(-βc))
        Y = zeros(Float64, p, n)
        for t in 1:p, s in 1:n
            if rand() < π_true[t]
                Y[t, s] = rand(Beta(μ_true[t] * φ, (1 - μ_true[t]) * φ))
            end
        end

        # Laplace marginal with Λ = 0 (zero loadings → exact marginalisation).
        ll = GLLVM.beta_hurdle_marginal_loglik_laplace(Y, zeros(p, K), βz, βc, φ)

        # Direct (independent) two-part log-likelihood — the reference value.
        ref = 0.0
        for t in 1:p, s in 1:n
            πt = inv(1 + exp(-βz[t]))
            μt = inv(1 + exp(-βc[t]))
            if Y[t, s] > 0
                yc  = clamp(Y[t, s], 1e-6, 1 - 1e-6)
                ref += log(πt) + logpdf(Beta(μt * φ, (1 - μt) * φ), yc)
            else
                ref += log(1 - πt)
            end
        end

        # Machine-precision equality (atol ≈ 1e-8 to allow Float64 rounding).
        @test ll ≈ ref atol = 1e-8
    end

    # -----------------------------------------------------------------------
    # 2. Separation anchor — all-zeros column: no positive values for species t
    #    ⇒ the Beta part contributes nothing; loglik equals n·log(1−π[t]).
    # -----------------------------------------------------------------------
    @testset "all-zeros column is pure Bernoulli" begin
        Random.seed!(211)
        p, K, n = 4, 1, 30
        βz = 0.3 .* randn(p)
        βc = 0.2 .* randn(p)
        φ  = 4.0

        Y = zeros(Float64, p, n)          # all absences (all columns zero)

        ll  = GLLVM.beta_hurdle_marginal_loglik_laplace(Y, zeros(p, K), βz, βc, φ)
        ref = sum(t -> n * log(1 - inv(1 + exp(-βz[t]))), 1:p)

        @test ll ≈ ref atol = 1e-8
    end

    # -----------------------------------------------------------------------
    # 3. All-positive column: when π ≈ 1 the zero-part contribution ≈ 0.
    #    With exact π = 1 (β^z → ∞) every observation enters the Beta part;
    #    we approximate with a very large βz value and check ll ≈ Beta loglik.
    # -----------------------------------------------------------------------
    @testset "all-positive column approaches pure Beta loglik" begin
        Random.seed!(212)
        p, K, n = 4, 1, 40
        βz_large = fill(20.0, p)          # logistic(20) ≈ 1 − 2e-9
        βc       = 0.3 .* randn(p)
        φ        = 6.0
        μ_true   = inv.(1 .+ exp.(-βc))

        Y = zeros(Float64, p, n)
        for t in 1:p, s in 1:n
            Y[t, s] = rand(Beta(μ_true[t] * φ, (1 - μ_true[t]) * φ))
        end
        @assert all(>(0), Y)              # sanity: no zeros generated

        ll = GLLVM.beta_hurdle_marginal_loglik_laplace(Y, zeros(p, K), βz_large, βc, φ)

        # Reference: pure Beta loglik + n·log(π) ≈ pure Beta loglik since π≈1.
        ref_beta = 0.0
        for t in 1:p, s in 1:n
            μt  = inv(1 + exp(-βc[t]))
            yc  = clamp(Y[t, s], 1e-6, 1 - 1e-6)
            ref_beta += logpdf(Beta(μt * φ, (1 - μt) * φ), yc)
        end
        # Bernoulli part contributes n·log(π) ≈ n·log(1) = 0 for large βz.
        bern_part = sum(t -> n * log(inv(1 + exp(-βz_large[t]))), 1:p)
        ref = ref_beta + bern_part

        # Tolerance is loose because logistic(20) is not literally 1.
        @test ll ≈ ref atol = 1e-4
    end

    # -----------------------------------------------------------------------
    # 4. _tp_pieces: check score / weight signs and magnitudes deterministically.
    #    For y > 0 the Fisher weight W^c must be ≥ 0 and s^c must be finite.
    #    For y = 0 the weight must be 0 and s^c must be 0.
    # -----------------------------------------------------------------------
    @testset "_tp_pieces: score/weight sanity" begin
        φ = 8.0
        fam = GLLVM.BetaHurdle(φ)
        # Interior point: y in (0,1), logistic-scale predictor η^c = 0 (μ=0.5)
        y_pos = 0.3
        ηz = 0.5; ηc = 0.0
        sz, sc, Wz, Wc, logf = GLLVM._tp_pieces(fam, y_pos, ηz, ηc)
        @test Wc ≥ 0
        @test Wz ≥ 0
        @test isfinite(sc)
        @test isfinite(logf)

        # Absence: y = 0
        sz0, sc0, Wz0, Wc0, logf0 = GLLVM._tp_pieces(fam, 0.0, ηz, ηc)
        @test sc0 == 0.0
        @test Wc0 == 0.0
        @test isfinite(logf0)
        @test logf0 < 0   # log(1−π) < 0 for π ∈ (0,1)
    end

    # -----------------------------------------------------------------------
    # 5. K = 1 quadrature check: Laplace marginal ≈ numerical integral.
    #    The Beta positive part is not Gaussian in η^c, so Laplace carries an
    #    O(curvature) error. Loose tolerance (< 0.5 nats) is acceptable here.
    # -----------------------------------------------------------------------
    @testset "K = 1 single site ≈ quadrature" begin
        Random.seed!(213)
        p, K = 5, 1
        βz   = 0.3 .* randn(p)
        βc   = 0.4 .* randn(p)
        φ    = 5.0
        Λc   = reshape(0.3 .* randn(p), p, 1)
        π    = inv.(1 .+ exp.(-βz))
        y    = zeros(p)
        for t in 1:p
            rand() < π[t] && (y[t] = rand(Beta(inv(1 + exp(-βc[t])) * φ,
                                               (1 - inv(1 + exp(-βc[t]))) * φ)))
        end
        Y = reshape(y, p, 1)
        ll_lap = GLLVM.beta_hurdle_marginal_loglik_laplace(Y, Λc, βz, βc, φ)

        # Numerical integral over z ~ N(0,1) on a fine grid.
        zs = range(-10, 10; length = 8001); dz = step(zs)
        marg = 0.0
        for z in zs
            lp = 0.0
            for t in 1:p
                πt = inv(1 + exp(-βz[t]))
                if y[t] > 0
                    ηct = βc[t] + Λc[t, 1] * z
                    μt  = inv(1 + exp(-ηct))
                    μt  = clamp(μt, 1e-6, 1 - 1e-6)
                    yc  = clamp(y[t], 1e-6, 1 - 1e-6)
                    lp += log(πt) + logpdf(Beta(μt * φ, (1 - μt) * φ), yc)
                else
                    lp += log(1 - πt)
                end
            end
            marg += exp(lp) * pdf(Normal(), z) * dz
        end
        ll_quad = log(marg)
        # Laplace error on a Beta positive part is bounded but not machine-precision.
        @test ll_lap ≈ ll_quad atol = 0.5
    end

    # -----------------------------------------------------------------------
    # 6. Fit smoke test: runs, returns BetaHurdleFit, loglik is finite, φ > 0,
    #    shapes are correct. No correctness claims on parameter recovery
    #    (small n; just checks structural sanity of the fit driver).
    # -----------------------------------------------------------------------
    @testset "fit_beta_hurdle_gllvm smoke test" begin
        Random.seed!(214)
        p, K, n = 6, 1, 150
        βz_true = 0.4 .* randn(p) .+ 0.5
        βc_true = 0.3 .* randn(p)
        φ_true  = 5.0
        Z = randn(K, n)
        Λc_true = 0.4 .* randn(p, K)
        ηc = βc_true .+ Λc_true * Z
        π_true  = inv.(1 .+ exp.(-βz_true))
        μ_true  = inv.(1 .+ exp.(-ηc))
        Y = zeros(Float64, p, n)
        for t in 1:p, s in 1:n
            if rand() < π_true[t]
                Y[t, s] = rand(Beta(μ_true[t, s] * φ_true,
                                    (1 - μ_true[t, s]) * φ_true))
            end
        end

        fit = fit_beta_hurdle_gllvm(Y; K = K)

        @test fit isa BetaHurdleFit
        @test isfinite(fit.loglik)
        @test fit.φ > 0
        @test size(fit.Λc) == (p, K)
        @test length(fit.βz) == p
        @test length(fit.βc) == p

        # _nparams, aic, bic
        k = 2p + (p * K - div(K * (K - 1), 2)) + 1
        @test GLLVM._nparams(fit) == k
        @test GLLVM.aic(fit) ≈ 2k - 2 * fit.loglik

        # show methods (text/plain and compact)
        s_plain   = sprint(show, MIME("text/plain"), fit)
        s_compact = sprint(show, fit)
        @test occursin("Beta-hurdle", s_plain)
        @test occursin("BetaHurdleFit", s_compact)
        @test occursin(string(p), s_plain)

        # getLV
        LV = GLLVM.getLV(fit, Y; rotate = false)
        @test size(LV) == (n, K)
        @test all(isfinite, LV)

        # predict
        Ppred = GLLVM.predict(fit, Y; type = :response)
        @test size(Ppred) == (p, n)
        @test all(Ppred .>= 0)
        @test all(Ppred .<= 1)

        occ = GLLVM.predict(fit, Y; type = :occurrence)
        @test all(0 .< occ .< 1)

        pos = GLLVM.predict(fit, Y; type = :positive)
        @test all(0 .< pos .< 1)

        # residuals
        R = GLLVM.residuals(fit, Y; rng = MersenneTwister(5))
        @test size(R) == (p, n)
        @test all(isfinite, R)
    end

    # -----------------------------------------------------------------------
    # 7. Wald confidence intervals + coef_table (confint_family dispatch).
    # -----------------------------------------------------------------------
    @testset "Wald CIs + coef_table" begin
        Random.seed!(321)
        p, K, n = 5, 1, 200
        βz = 0.4 .* randn(p) .+ 0.5
        βc = 0.3 .* randn(p)
        φ  = 6.0
        Z  = randn(K, n); Λc = 0.4 .* randn(p, K)
        ηc = βc .+ Λc * Z
        π  = inv.(1 .+ exp.(-βz)); μ = inv.(1 .+ exp.(-ηc))
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            rand() < π[t] && (Y[t, s] = rand(Beta(μ[t, s] * φ, (1 - μ[t, s]) * φ)))
        end
        fit = fit_beta_hurdle_gllvm(Y; K = K)

        ci = confint(fit, Y; method = :wald)
        nparam = 2p + (p * K - div(K * (K - 1), 2)) + 1     # βz + βc + Λc + φ
        @test length(ci.term) == nparam
        @test ci.method == :wald

        # Each finite-SE interval brackets its point estimate.
        for i in eachindex(ci.term)
            if isfinite(ci.lower[i]) && isfinite(ci.upper[i])
                @test ci.lower[i] ≤ ci.estimate[i] ≤ ci.upper[i]
            end
        end

        # The dispersion term is present and positive (reported on the raw scale).
        iφ = findfirst(==("phi"), ci.term)
        @test iφ !== nothing
        @test ci.estimate[iφ] > 0

        # coef_table builds a tidy table from the same machinery.
        ct = coef_table(fit, Y)
        @test ct isa GllvmCoefTable
    end

end  # @testset "beta-hurdle GLLVM"
