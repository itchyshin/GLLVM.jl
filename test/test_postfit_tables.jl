using GLLVM, Test, Random, LinearAlgebra, Statistics

# src/postfit_tables.jl — final missing-surface cluster (core070 spec §1),
# smallest-first per docs/dev-log/core070/final-surface-spec.md.

@testset "postfit_tables.jl — final missing-surface cluster" begin

    @testset "1.1 deviance — -2*loglikelihood, exact R contract" begin
        Random.seed!(1)
        p, K, n = 4, 2, 200
        Λ_true = 0.6 .* randn(p, K)
        y = Λ_true * randn(K, n) + 0.4 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        @test deviance(fit) ≈ -2 * loglikelihood(fit)
        @test deviance(fit) ≈ -2 * fit.logLik
    end

    @testset "1.2 profile_cross_rho_ci — grid interpolation, independent oracle" begin
        # Hand-built quadratic delta_deviance grid, a*(rho - r0)^2, with a
        # known best point r0 and analytically-known bracketing grid points.
        a, r0 = 10.0, 0.13
        r = collect(-1.0:0.1:1.0)
        dd = a .* (r .- r0) .^ 2
        level = 0.95
        thresh = quantile(GLLVM.Chisq(1), level)

        out = profile_cross_rho_ci(r, dd; level = level)
        @test out.threshold ≈ thresh
        @test out.estimate ≈ r[argmin(dd)]
        @test out.level == level

        # Independent oracle: brute-force the same "walk outward, interpolate
        # at the bracketing pair" rule directly on the sorted grid.
        perm = sortperm(r)
        rs, dds = r[perm], dd[perm]
        best_i = argmin(dds)
        lo = nothing
        for j in (best_i - 1):-1:1
            if dds[j] >= thresh
                x1, y1, x2, y2 = rs[j], dds[j], rs[j + 1], dds[j + 1]
                lo = (x1 + (thresh - y1) * (x2 - x1) / (y2 - y1), true)
                break
            end
        end
        lo === nothing && (lo = (rs[1], false))
        hi = nothing
        for j in (best_i + 1):length(rs)
            if dds[j] >= thresh
                x1, y1, x2, y2 = rs[j - 1], dds[j - 1], rs[j], dds[j]
                hi = (x1 + (thresh - y1) * (x2 - x1) / (y2 - y1), true)
                break
            end
        end
        hi === nothing && (hi = (rs[end], false))

        @test out.lower ≈ clamp(lo[1], -1, 1) atol = 1e-10
        @test out.upper ≈ clamp(hi[1], -1, 1) atol = 1e-10
        @test out.lower_bounded == lo[2]
        @test out.upper_bounded == hi[2]
        @test out.lower_bounded == true
        @test out.upper_bounded == true

        # Truncated grid: drop everything below the lower crossing so that
        # side never crosses the threshold within the retained points.
        keep = r .>= -0.3
        out_trunc = profile_cross_rho_ci(r[keep], dd[keep]; level = level)
        @test out_trunc.lower_bounded == false
        @test out_trunc.lower == minimum(r[keep])
        @test out_trunc.upper_bounded == true

        # Errors: too few finite points, bad level.
        @test_throws ArgumentError profile_cross_rho_ci([0.0], [0.0])
        @test_throws ArgumentError profile_cross_rho_ci(r, dd; level = 1.5)
        @test_throws ArgumentError profile_cross_rho_ci([NaN, 0.0], [NaN, 1.0])
    end

end
