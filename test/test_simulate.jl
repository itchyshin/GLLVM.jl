# Tests for the family-dispatched data-generating process (src/simulate.jl).
#
# Three groups:
#   (1) SELF-CONSISTENCY — simulate under known (β, Λ, dispersion) with a fixed
#       seed, fit with the matching fitter, and assert recovery of Λ's loading
#       structure (cor(ΛΛ', Λ_trueΛ_true')) and β within a generous Monte-Carlo
#       tolerance. Covers Poisson, NegativeBinomial, Beta, Binomial, Gamma, and a
#       MIXED [Normal, Poisson, Binomial] case. (Gamma's α-recovery is fragile —
#       see the note in that block — so its inverse is also checked directly via
#       empirical moments, which is fitter-independent.)
#   (2) REPRODUCIBILITY — the same seed yields an identical Y (params-in and
#       from-fit); a fresh MersenneTwister(seed) matches the `seed` kwarg.
#   (3) SHAPE / VALIDATION — p×n Float64 output; argument errors on mismatched
#       families/links/β/Λ/dispersion/N lengths and the un-wired `X` hook.
#
# Self-runnable: `julia --project=. test/test_simulate.jl`.

using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

# Rotation-invariant loading-structure similarity (loadings are identified only
# up to rotation ⇒ compare ΛΛ', as the single-family fit tests do).
_loading_struct_cor(Λ̂, Λ_true) = cor(vec(Λ̂ * Λ̂'), vec(Λ_true * Λ_true'))

@testset "simulate — family-dispatched DGP" begin

    # =======================================================================
    # (1) SELF-CONSISTENCY: simulate → fit → recover (β, ΛΛ' structure).
    # =======================================================================
    @testset "(1) self-consistency: simulate → fit recovers structure" begin

        @testset "Poisson" begin
            Random.seed!(2026)
            p, K, n = 6, 2, 500
            β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
            Λ_true = 0.5 .* randn(p, K)
            Y = simulate(Poisson(), β_true, Λ_true, n; seed = 777)
            @test size(Y) == (p, n)
            @test all(Y .== round.(Y))                       # integer counts
            fit = fit_poisson_gllvm(Int.(Y); K = K)
            @test fit.converged
            @test _loading_struct_cor(fit.Λ, Λ_true) > 0.9
            @test maximum(abs.(fit.β .- β_true)) < 0.25
        end

        @testset "NegativeBinomial" begin
            Random.seed!(303)
            p, K, n = 6, 2, 600
            β_true = log.([5.0, 4.0, 6.0, 3.0, 5.0, 4.0])
            Λ_true = 0.5 .* randn(p, K)
            r_true = 8.0
            Y = simulate(NegativeBinomial(), β_true, Λ_true, n;
                         dispersion = r_true, seed = 111)
            @test size(Y) == (p, n)
            @test all(Y .== round.(Y))
            fit = fit_nb_gllvm(Int.(Y); K = K)
            @test fit.converged
            @test _loading_struct_cor(fit.Λ, Λ_true) > 0.9
            @test maximum(abs.(fit.β .- β_true)) < 0.25
            @test 0.5 * r_true < fit.r < 2.0 * r_true        # dispersion recovered
        end

        @testset "Beta" begin
            Random.seed!(404)
            p, K, n = 6, 2, 800
            β_true = [0.0, 0.5, -0.3, 0.8, -0.5, 0.2]
            Λ_true = 0.5 .* randn(p, K)
            φ_true = 12.0
            Y = simulate(Beta(), β_true, Λ_true, n; dispersion = φ_true, seed = 222)
            @test size(Y) == (p, n)
            @test all(0 .< Y .< 1)                           # proportions in (0,1)
            fit = fit_beta_gllvm(Y; K = K)
            @test fit.converged
            @test _loading_struct_cor(fit.Λ, Λ_true) > 0.9
            @test maximum(abs.(fit.β .- β_true)) < 0.25
            @test 0.5 * φ_true < fit.φ < 2.0 * φ_true
        end

        @testset "Binomial" begin
            Random.seed!(606)
            p, K, n = 6, 2, 600
            β_true = [0.0, 0.5, -0.5, 1.0, -1.0, 0.3]
            Λ_true = 0.5 .* randn(p, K)
            ntrials = 10
            Y = simulate(Binomial(), β_true, Λ_true, n; N = ntrials, seed = 444)
            @test size(Y) == (p, n)
            @test all(0 .≤ Y .≤ ntrials)                     # within trial count
            fit = fit_binomial_gllvm(Int.(Y); K = K, N = fill(ntrials, p, n))
            @test fit.converged
            @test _loading_struct_cor(fit.Λ, Λ_true) > 0.9
            @test maximum(abs.(fit.β .- β_true)) < 0.25
        end

        @testset "Gamma" begin
            # NOTE: the Gamma fitter's shape α frequently sticks at its init on
            # rank-1 latent structure (a documented fragility — CLAUDE.md: "Gamma
            # currently stays on direct ForwardDiff until its inner mode
            # convergence is hardened"). The simulator's draw is nonetheless the
            # exact inverse of `_glm_logpdf(::Gamma)` = Gamma(shape α, scale μ/α).
            #
            # (a) DGP correctness via empirical moments (fitter-independent): at a
            #     null latent (Λ = 0 ⇒ η = β, μ = exp(β)), a large-n sample has
            #     Ê[y] → μ and V̂ → μ²/α, i.e. μ²/V̂ → α.
            Random.seed!(0)
            p, n_big = 4, 50_000
            β_m = log.([2.0, 5.0, 1.0, 8.0])
            α_true = 4.0
            Y_m = simulate(Gamma(), β_m, zeros(p, 1), n_big;
                           dispersion = α_true, seed = 12345)
            @test all(Y_m .> 0)
            μ_m = exp.(β_m)
            for t in 1:p
                @test isapprox(mean(Y_m[t, :]), μ_m[t]; rtol = 0.05)
                @test isapprox(μ_m[t]^2 / var(Y_m[t, :]), α_true; rtol = 0.1)
            end

            # (b) simulate → fit loading-structure recovery on a configuration
            #     where the Gamma fitter cooperates (seed 7 / moderate loadings).
            Random.seed!(7)
            p, K, n = 6, 1, 1000
            β_true = log.(3.0 .+ 2.0 .* randn(p) .^ 2)
            Λ_true = reshape(0.6 .* randn(p), p, 1)
            Y = simulate(Gamma(), β_true, Λ_true, n; dispersion = α_true, seed = 70)
            @test all(Y .> 0)
            fit = fit_gamma_gllvm(Y; K = K)
            @test fit.converged
            @test _loading_struct_cor(fit.Λ, Λ_true) > 0.9
            @test maximum(abs.(fit.β .- β_true)) < 0.25
            @test 0.5 * α_true < fit.α < 2.0 * α_true
        end

        @testset "Mixed [Normal, Poisson, Binomial]" begin
            Random.seed!(707)
            p, K, n = 3, 1, 800
            families = [Normal(), Poisson(), Binomial()]
            links = [IdentityLink(), LogLink(), LogitLink()]
            β_true = [0.5, log(3.0), 0.2]
            Λ_true = reshape([0.9, 0.6, 1.0], p, 1)
            dispersion = [0.5, NaN, NaN]                      # Normal σ; others none
            ntrials = 8
            Y = simulate(families, links, β_true, Λ_true, n;
                         dispersion = dispersion, N = ntrials, seed = 555)
            @test size(Y) == (p, n)
            @test all(Y[2, :] .== round.(Y[2, :]))           # Poisson row integer
            @test all(0 .≤ Y[3, :] .≤ ntrials)               # Binomial row in range
            fit = fit_mixed_gllvm(Y; families = families, K = K, N = fill(ntrials, p, n))
            @test fit.converged
            @test _loading_struct_cor(fit.Λ, Λ_true) > 0.9
            @test maximum(abs.(fit.β .- β_true)) < 0.25
            # Cross-family latent correlation is well-formed and, with all loadings
            # the same sign, positive. (The true latent R is the degenerate value 1
            # at K=1; differing per-family link residuals attenuate the recovered R
            # below 1, so we assert sign/well-formedness, not the boundary value.)
            R = correlation(fit, Y; N = fill(ntrials, p, n))
            @test maximum(abs.(R - R')) < 1e-10
            for t in 1:p
                @test isapprox(R[t, t], 1.0; atol = 1e-12)
            end
            @test all(R[i, j] > 0 for i in 1:p, j in 1:p)
        end
    end

    # =======================================================================
    # (2) REPRODUCIBILITY: same seed ⇒ identical Y.
    # =======================================================================
    @testset "(2) reproducibility: same seed ⇒ identical Y" begin
        β = [1.0, 1.5, 0.8]
        Λ = reshape([0.5, 0.5, 0.5], 3, 1)

        @testset "params-in seed kwarg" begin
            Y1 = simulate(Poisson(), β, Λ, 40; seed = 99)
            Y2 = simulate(Poisson(), β, Λ, 40; seed = 99)
            @test Y1 == Y2
            Y3 = simulate(Poisson(), β, Λ, 40; seed = 100)
            @test Y1 != Y3                                    # different seed differs
        end

        @testset "seed kwarg == fresh MersenneTwister(seed)" begin
            Yk = simulate(Poisson(), β, Λ, 40; seed = 2024)
            Yr = simulate(Poisson(), β, Λ, 40; rng = MersenneTwister(2024))
            @test Yk == Yr
        end

        @testset "explicit rng advances (two draws differ, are reproducible)" begin
            rng = MersenneTwister(7)
            Ya = simulate(Poisson(), β, Λ, 30; rng = rng)
            Yb = simulate(Poisson(), β, Λ, 30; rng = rng)
            @test Ya != Yb                                    # rng state advanced
            rng2 = MersenneTwister(7)
            Ya2 = simulate(Poisson(), β, Λ, 30; rng = rng2)
            Yb2 = simulate(Poisson(), β, Λ, 30; rng = rng2)
            @test Ya == Ya2 && Yb == Yb2                      # full sequence reproducible
        end

        @testset "mixed + ordinal + from-fit reproducibility" begin
            fams = [Normal(), Poisson(), Binomial()]
            links = [IdentityLink(), LogLink(), LogitLink()]
            Ym1 = simulate(fams, links, [0.5, 1.0, 0.0], Λ, 25;
                           dispersion = [0.4, NaN, NaN], seed = 11)
            Ym2 = simulate(fams, links, [0.5, 1.0, 0.0], Λ, 25;
                           dispersion = [0.4, NaN, NaN], seed = 11)
            @test Ym1 == Ym2

            τ = [-1.0, 0.0, 1.0]
            Yo1 = simulate(Ordinal(), τ, Λ, 30; seed = 5)
            Yo2 = simulate(Ordinal(), τ, Λ, 30; seed = 5)
            @test Yo1 == Yo2

            # From a fitted model: identical seed ⇒ identical fresh draw.
            Yp = simulate(Poisson(), [1.0, 1.2, 0.9], Λ, 200; seed = 1)
            fp = fit_poisson_gllvm(Int.(Yp); K = 1)
            @test simulate(fp, 20; seed = 3) == simulate(fp, 20; seed = 3)
        end
    end

    # =======================================================================
    # (3) SHAPE / VALIDATION.
    # =======================================================================
    @testset "(3) shape & argument validation" begin
        β = [0.0, 0.5, 1.0]
        Λ = reshape([0.5, 0.3, 0.7], 3, 1)
        fams = [Poisson(), Poisson(), Poisson()]
        links = [LogLink(), LogLink(), LogLink()]

        @testset "output shape & type" begin
            Y = simulate(fams, links, β, Λ, 17; seed = 1)
            @test Y isa Matrix{Float64}
            @test size(Y) == (3, 17)

            # single-family convenience reads p from length(β)
            Y2 = simulate(Poisson(), β, Λ, 9; seed = 1)
            @test size(Y2) == (3, 9)

            # ordinal reads p from size(Λ, 1)
            Yo = simulate(Ordinal(), [-0.5, 0.5], Λ, 12; seed = 1)
            @test size(Yo) == (3, 12)
            @test all(1 .≤ Yo .≤ 3)                          # C = length(τ)+1 = 3
        end

        @testset "length-mismatch errors" begin
            # links length ≠ p
            @test_throws DimensionMismatch simulate(
                fams, links[1:2], β, Λ, 5; seed = 1)
            # β length ≠ p
            @test_throws DimensionMismatch simulate(
                fams, links, β[1:2], Λ, 5; seed = 1)
            # Λ rows ≠ p
            @test_throws DimensionMismatch simulate(
                fams, links, β, reshape([0.5, 0.3], 2, 1), 5; seed = 1)
            # dispersion length ≠ p
            @test_throws DimensionMismatch simulate(
                fams, links, β, Λ, 5; dispersion = [1.0, 2.0], seed = 1)
            # N matrix wrong size
            @test_throws DimensionMismatch simulate(
                fams, links, β, Λ, 5; N = fill(2, 3, 4), seed = 1)
        end

        @testset "other argument errors" begin
            # n < 1
            @test_throws ArgumentError simulate(fams, links, β, Λ, 0; seed = 1)
            # un-wired covariate hook
            @test_throws ArgumentError simulate(
                fams, links, β, Λ, 5; X = zeros(3, 5), seed = 1)
            # ordinal: unsorted cutpoints
            @test_throws ArgumentError simulate(Ordinal(), [1.0, -1.0], Λ, 5; seed = 1)
            # ordinal: too few cutpoints (need ≥ 1 ⇒ ≥ 2 categories)
            @test_throws ArgumentError simulate(Ordinal(), Float64[], Λ, 5; seed = 1)
        end

        @testset "N normalisation (nothing / scalar / matrix)" begin
            bfam = [Binomial(), Binomial()]
            blink = [LogitLink(), LogitLink()]
            bβ = [0.0, 0.5]
            bΛ = reshape([0.4, 0.6], 2, 1)
            # nothing ⇒ Bernoulli (all in {0,1})
            Yb0 = simulate(bfam, blink, bβ, bΛ, 50; seed = 1)
            @test all((Yb0 .== 0) .| (Yb0 .== 1))
            # scalar ⇒ filled
            Yb5 = simulate(bfam, blink, bβ, bΛ, 50; N = 5, seed = 1)
            @test all(0 .≤ Yb5 .≤ 5)
            # matrix ⇒ per-cell
            Nm = fill(3, 2, 50)
            Yb3 = simulate(bfam, blink, bβ, bΛ, 50; N = Nm, seed = 1)
            @test all(0 .≤ Yb3 .≤ 3)
        end
    end
end
