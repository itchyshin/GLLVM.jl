# Missing-RESPONSE (NA in Y) coverage for the entry points the keystone left for
# later (full-capability track). The shared dense-Laplace path and the core
# one-part families already carry an optional per-observation `mask`
# (test/test_missing_response.jl); this file extends that contract to:
#
#   (c) COM-Poisson — its OWN per-site loop (compoisson_*),
#   (b) Tweedie + the bespoke-loop dispersion families (ordered-beta,
#       beta-binomial) + the offset-Laplace covariate wrappers (fit_gllvm_cov,
#       fit_gllvm_speciescov, fit_fourthcorner_gllvm, fit_roweffect_gllvm).
#
# Verification gates, mirroring test_missing_response.jl:
#   (1) masked marginal == hand-dropped-missing marginal (independent oracle that
#       physically row-subsets Λ/β/y/N per site, no mask);
#   (2) all-observed mask == no-mask (byte-identical);
#   (3) a fully-masked site contributes exactly 0;
#   (4) FIT with NA == explicit-mask fit on the same observed cells.

using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

# --- Independent drop-missing oracles (one per bespoke marginal). Each physically
#     subsets the OBSERVED sub-rows of (Λ, β, [N], y) per site and calls the
#     unmasked per-site marginal — a different code path from the `mask=` keyword. ---

function _compoisson_dropmissing(Y, Λ, β, ν, mask)
    n = size(Y, 2); acc = 0.0
    for s in 1:n
        obs = findall(view(mask, :, s)); isempty(obs) && continue
        acc += GLLVM.compoisson_marginal_loglik_laplace(reshape(Y[obs, s], :, 1),
                                                        Λ[obs, :], β[obs], ν)
    end
    return acc
end

function _ordered_beta_dropmissing(Y, Λ, β, c0, c1, φ, mask)
    n = size(Y, 2); acc = 0.0
    for s in 1:n
        obs = findall(view(mask, :, s)); isempty(obs) && continue
        acc += GLLVM.ordered_beta_marginal_loglik_laplace(reshape(Y[obs, s], :, 1),
                                                          Λ[obs, :], β[obs], c0, c1, φ)
    end
    return acc
end

function _betabinomial_dropmissing(Y, N, Λ, β, φ, mask)
    n = size(Y, 2); acc = 0.0
    for s in 1:n
        obs = findall(view(mask, :, s)); isempty(obs) && continue
        acc += GLLVM.betabinomial_marginal_loglik_laplace(reshape(Y[obs, s], :, 1),
                                                          reshape(N[obs, s], :, 1),
                                                          Λ[obs, :], β[obs], φ)
    end
    return acc
end

function _tweedie_dropmissing(Y, Λ, β, φ, p, mask)
    n = size(Y, 2); acc = 0.0
    for s in 1:n
        obs = findall(view(mask, :, s)); isempty(obs) && continue
        acc += GLLVM.tweedie_marginal_loglik_laplace(reshape(Y[obs, s], :, 1),
                                                     Λ[obs, :], β[obs], φ, p)
    end
    return acc
end

@testset "Missing responses (NA in Y) — extra entry points" begin

    # ----------------------------------------------------------------------
    # (1)+(2)+(3) marginal-level contract for the four bespoke marginals.
    # ----------------------------------------------------------------------
    @testset "masked marginal == hand-dropped marginal" begin
        Random.seed!(11)
        p, n, K = 6, 12, 2
        β = randn(p) .* 0.3
        Λ = randn(p, K) .* 0.4
        mask = trues(p, n)
        for (t, s) in [(1, 2), (3, 5), (4, 8), (2, 1), (5, 3), (6, 11), (1, 12)]
            mask[t, s] = false
        end

        # --- COM-Poisson ---
        Yc = rand(0:6, p, n)
        ℓm = GLLVM.compoisson_marginal_loglik_laplace(Yc, Λ, β, 1.2; mask = mask)
        ℓd = _compoisson_dropmissing(Yc, Λ, β, 1.2, mask)
        @test isapprox(ℓm, ℓd; atol = 1e-9, rtol = 0)
        @test GLLVM.compoisson_marginal_loglik_laplace(Yc, Λ, β, 1.2; mask = trues(p, n)) ==
              GLLVM.compoisson_marginal_loglik_laplace(Yc, Λ, β, 1.2)

        # --- ordered-beta ---
        Yo = clamp.(rand(p, n), 0.0, 1.0)
        Yo[1, 1] = 0.0; Yo[2, 2] = 1.0           # exercise both point masses
        ℓm_o = GLLVM.ordered_beta_marginal_loglik_laplace(Yo, Λ, β, -1.0, 1.0, 8.0; mask = mask)
        ℓd_o = _ordered_beta_dropmissing(Yo, Λ, β, -1.0, 1.0, 8.0, mask)
        @test isapprox(ℓm_o, ℓd_o; atol = 1e-9, rtol = 0)
        @test GLLVM.ordered_beta_marginal_loglik_laplace(Yo, Λ, β, -1.0, 1.0, 8.0; mask = trues(p, n)) ==
              GLLVM.ordered_beta_marginal_loglik_laplace(Yo, Λ, β, -1.0, 1.0, 8.0)

        # --- beta-binomial ---
        Nbb = fill(5, p, n)
        Ybb = rand(0:5, p, n)
        ℓm_b = GLLVM.betabinomial_marginal_loglik_laplace(Ybb, Nbb, Λ, β, 8.0; mask = mask)
        ℓd_b = _betabinomial_dropmissing(Ybb, Nbb, Λ, β, 8.0, mask)
        @test isapprox(ℓm_b, ℓd_b; atol = 1e-9, rtol = 0)
        @test GLLVM.betabinomial_marginal_loglik_laplace(Ybb, Nbb, Λ, β, 8.0; mask = trues(p, n)) ==
              GLLVM.betabinomial_marginal_loglik_laplace(Ybb, Nbb, Λ, β, 8.0)

        # --- Tweedie ---
        Yt = abs.(randn(p, n)); Yt[1, 1] = 0.0; Yt[3, 3] = 0.0   # exact zeros (atom)
        ℓm_t = GLLVM.tweedie_marginal_loglik_laplace(Yt, Λ, β, 1.0, 1.5; mask = mask)
        ℓd_t = _tweedie_dropmissing(Yt, Λ, β, 1.0, 1.5, mask)
        @test isapprox(ℓm_t, ℓd_t; atol = 1e-9, rtol = 0)
        @test GLLVM.tweedie_marginal_loglik_laplace(Yt, Λ, β, 1.0, 1.5; mask = trues(p, n)) ==
              GLLVM.tweedie_marginal_loglik_laplace(Yt, Λ, β, 1.0, 1.5)
    end

    @testset "fully-masked site contributes exactly 0" begin
        Random.seed!(12)
        p, K = 5, 2
        β = randn(p) .* 0.3; Λ = randn(p, K) .* 0.4
        # one site fully observed, one site fully masked
        mask = hcat(trues(p), falses(p))

        Yc = hcat(rand(0:6, p), rand(0:6, p))
        full = GLLVM.compoisson_marginal_loglik_laplace(Yc[:, 1:1], Λ, β, 1.1)
        both = GLLVM.compoisson_marginal_loglik_laplace(Yc, Λ, β, 1.1; mask = mask)
        @test isapprox(both, full; atol = 1e-12, rtol = 0)

        Yt = hcat(abs.(randn(p)), abs.(randn(p)))
        full_t = GLLVM.tweedie_marginal_loglik_laplace(Yt[:, 1:1], Λ, β, 1.0, 1.6)
        both_t = GLLVM.tweedie_marginal_loglik_laplace(Yt, Λ, β, 1.0, 1.6; mask = mask)
        @test isapprox(both_t, full_t; atol = 1e-12, rtol = 0)
    end

    # ----------------------------------------------------------------------
    # (4) FIT with NA == explicit-mask fit on the same observed cells, for every
    #     wired entry point.
    # ----------------------------------------------------------------------
    @testset "COM-Poisson fit: NA == explicit mask" begin
        Random.seed!(40)
        p, K, n = 5, 1, 120
        β = log.([3.0, 4.0, 2.5, 5.0, 3.5])
        Λ = 0.4 .* randn(p, K)
        η = β .+ Λ * randn(K, n)
        Yfull = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        mask = trues(p, n)
        for I in randperm(p * n)[1:round(Int, 0.03 * p * n)]
            mask[I] = false
        end
        Ym = Matrix{Union{Missing, Int}}(Yfull)
        for I in findall(.!mask); Ym[I] = missing; end

        fit_na   = fit_compoisson_gllvm(Ym;    K = K)
        fit_mask = fit_compoisson_gllvm(Yfull; K = K, mask = mask)
        @test fit_na.converged
        @test isapprox(fit_mask.loglik, fit_na.loglik; atol = 1e-6)
        @test isapprox(fit_mask.β, fit_na.β; atol = 1e-6)
    end

    @testset "Tweedie fit: NA == explicit mask" begin
        Random.seed!(41)
        p, K, n = 5, 1, 120
        β = log.([2.0, 3.0, 1.5, 2.5, 2.0])
        Λ = 0.3 .* randn(p, K)
        η = β .+ Λ * randn(K, n)
        # compound Poisson–Gamma draws (true zeros + positive continuous)
        Yfull = Matrix{Float64}(undef, p, n)
        for t in 1:p, s in 1:n
            nev = rand(Poisson(exp(η[t, s])))
            Yfull[t, s] = nev == 0 ? 0.0 : sum(rand(Gamma(2.0, 0.5)) for _ in 1:nev)
        end
        mask = trues(p, n)
        for I in randperm(p * n)[1:round(Int, 0.03 * p * n)]
            mask[I] = false
        end
        Ym = Matrix{Union{Missing, Float64}}(Yfull)
        for I in findall(.!mask); Ym[I] = missing; end

        fit_na   = fit_tweedie_gllvm(Ym;    K = K)
        fit_mask = fit_tweedie_gllvm(Yfull; K = K, mask = mask)
        @test fit_na.converged
        @test isapprox(fit_mask.loglik, fit_na.loglik; atol = 1e-6)
        @test isapprox(fit_mask.β, fit_na.β; atol = 1e-6)
    end

    @testset "ordered-beta fit: NA == explicit mask" begin
        Random.seed!(42)
        p, K, n = 5, 1, 120
        β = 0.2 .* randn(p); Λ = 0.4 .* randn(p, K)
        η = β .+ Λ * randn(K, n)
        Yfull = Matrix{Float64}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = 1 / (1 + exp(-η[t, s]))
            r = rand()
            Yfull[t, s] = r < 0.1 ? 0.0 : r > 0.9 ? 1.0 :
                          clamp(rand(Beta(μ * 8, (1 - μ) * 8)), 1e-4, 1 - 1e-4)
        end
        mask = trues(p, n)
        for I in randperm(p * n)[1:round(Int, 0.03 * p * n)]
            mask[I] = false
        end
        Ym = Matrix{Union{Missing, Float64}}(Yfull)
        for I in findall(.!mask); Ym[I] = missing; end

        fit_na   = fit_ordered_beta_gllvm(Ym;    K = K)
        fit_mask = fit_ordered_beta_gllvm(Yfull; K = K, mask = mask)
        @test fit_na.converged
        @test isapprox(fit_mask.loglik, fit_na.loglik; atol = 1e-6)
        @test isapprox(fit_mask.β, fit_na.β; atol = 1e-6)
    end

    @testset "beta-binomial fit: NA == explicit mask" begin
        Random.seed!(43)
        p, K, n = 5, 1, 120
        β = 0.2 .* randn(p); Λ = 0.4 .* randn(p, K)
        η = β .+ Λ * randn(K, n)
        Nbb = fill(8, p, n)
        Yfull = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = 1 / (1 + exp(-η[t, s]))
            pp = clamp(rand(Beta(μ * 6, (1 - μ) * 6)), 1e-6, 1 - 1e-6)
            Yfull[t, s] = rand(Binomial(Nbb[t, s], pp))
        end
        mask = trues(p, n)
        for I in randperm(p * n)[1:round(Int, 0.03 * p * n)]
            mask[I] = false
        end
        Ym = Matrix{Union{Missing, Int}}(Yfull)
        for I in findall(.!mask); Ym[I] = missing; end

        fit_na   = fit_beta_binomial_gllvm(Ym;    K = K, N = Nbb)
        fit_mask = fit_beta_binomial_gllvm(Yfull; K = K, N = Nbb, mask = mask)
        @test fit_na.converged
        @test isapprox(fit_mask.loglik, fit_na.loglik; atol = 1e-6)
        @test isapprox(fit_mask.β, fit_na.β; atol = 1e-6)
    end

    # ----------------------------------------------------------------------
    # (4) offset-Laplace covariate wrappers: NA == explicit mask.
    # ----------------------------------------------------------------------
    @testset "covariate wrappers: NA == explicit mask" begin
        Random.seed!(44)
        p, K, n, q = 5, 1, 100, 1
        β = log.([3.0, 4.0, 2.5, 5.0, 3.5]); Λ = 0.3 .* randn(p, K)
        γ = [0.5]
        Xenv = randn(n, q)
        X = reshape(repeat(reshape(Xenv, 1, n, q), p), p, n, q)   # X[t,s,k] = Xenv[s,k]
        O = dropdims(sum(X .* reshape(γ, 1, 1, q); dims = 3); dims = 3)
        η = β .+ O .+ Λ * randn(K, n)
        Yfull = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        mask = trues(p, n)
        for I in randperm(p * n)[1:round(Int, 0.03 * p * n)]
            mask[I] = false
        end
        Ym = Matrix{Union{Missing, Int}}(Yfull)
        for I in findall(.!mask); Ym[I] = missing; end

        # --- shared-γ covariates ---
        fc_na   = fit_gllvm_cov(Ym;    family = Poisson(), X = X, K = K)
        fc_mask = fit_gllvm_cov(Yfull; family = Poisson(), X = X, K = K, mask = mask)
        @test fc_na.converged
        @test isapprox(fc_mask.loglik, fc_na.loglik; atol = 1e-6)
        @test isapprox(fc_mask.β, fc_na.β; atol = 1e-6)
        @test isapprox(fc_mask.γ, fc_na.γ; atol = 1e-6)

        # --- species-specific covariates ---
        fs_na   = fit_gllvm_speciescov(Ym;    family = Poisson(), X = X, K = K)
        fs_mask = fit_gllvm_speciescov(Yfull; family = Poisson(), X = X, K = K, mask = mask)
        @test fs_na.converged
        @test isapprox(fs_mask.loglik, fs_na.loglik; atol = 1e-6)
        @test isapprox(fs_mask.β, fs_na.β; atol = 1e-6)

        # --- fourth-corner ---
        TR = randn(p, 1)
        ff_na   = fit_fourthcorner_gllvm(Ym;    family = Poisson(), Xenv = Xenv, TR = TR, K = K)
        ff_mask = fit_fourthcorner_gllvm(Yfull; family = Poisson(), Xenv = Xenv, TR = TR, K = K, mask = mask)
        @test ff_na.converged
        @test isapprox(ff_mask.loglik, ff_na.loglik; atol = 1e-6)
        @test isapprox(ff_mask.β, ff_na.β; atol = 1e-6)

        # --- row effects ---
        fr_na   = fit_roweffect_gllvm(Ym;    family = Poisson(), K = K)
        fr_mask = fit_roweffect_gllvm(Yfull; family = Poisson(), K = K, mask = mask)
        @test fr_na.converged
        @test isapprox(fr_mask.loglik, fr_na.loglik; atol = 1e-6)
        @test isapprox(fr_mask.β, fr_na.β; atol = 1e-6)
    end
end
