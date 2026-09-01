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

    @testset "1.3 predict_cross_covariance — positional, hand-loop oracle" begin
        Random.seed!(3)
        n_H, n_P = 2, 2
        p = n_H + n_P
        A_H = [1.0 0.3; 0.3 1.0]
        A_P = [1.0 0.2; 0.2 1.0]
        W = [1.0 0.0; 0.5 1.0]
        K_star = Matrix(make_cross_kernel(A_H, A_P, W; rho = 0.4))

        L_phy_true = cholesky(Symmetric(K_star)).L
        n = 400
        Λ_unit = 0.5 .* randn(p, 1)
        y = Λ_unit * randn(1, n) .+ (L_phy_true * randn(p, n)) .+ 0.3 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = 1, K_phy = 1, Σ_phy = K_star)
        @test fit.converged

        row_traits = 1:n_H
        col_traits = (n_H + 1):p
        Γ = extract_Gamma(fit; row_traits = row_traits, col_traits = col_traits)

        # Level kernel is a separate small artificial matrix (e.g. site-level
        # replication kernel) — independent axis from the trait axis.
        Klvl = [1.0 0.3 0.1; 0.3 1.0 0.2; 0.1 0.2 1.0]
        row_levels = [1, 2]
        col_levels = [2, 3]

        out = predict_cross_covariance(fit, Klvl; row_levels = row_levels,
                                       col_levels = col_levels,
                                       row_traits = collect(row_traits),
                                       col_traits = collect(col_traits))

        @test length(out.covariance) == length(row_levels) * length(col_levels) *
                                        length(row_traits) * length(col_traits)
        idx = 0
        for rl in row_levels, cl in col_levels, (ti, rt) in enumerate(row_traits), (tj, ct) in enumerate(col_traits)
            idx += 1
            @test out.row_level[idx] == rl
            @test out.col_level[idx] == cl
            @test out.row_trait[idx] == rt
            @test out.col_trait[idx] == ct
            @test out.kernel_value[idx] == Klvl[rl, cl]
            @test out.gamma_shape[idx] == Γ[ti, tj]
            @test out.covariance[idx] ≈ Γ[ti, tj] * Klvl[rl, cl]
        end

        @test_throws ArgumentError predict_cross_covariance(fit, Klvl;
            row_levels = [0], col_levels = col_levels,
            row_traits = collect(row_traits), col_traits = collect(col_traits))
        @test_throws ArgumentError predict_cross_covariance(fit, Klvl;
            row_levels = row_levels, col_levels = [99],
            row_traits = collect(row_traits), col_traits = collect(col_traits))
    end

    @testset "1.4 predict_missing — masked-cell table" begin
        Random.seed!(4)
        p, K, n = 5, 2, 300
        Λ_true = 0.6 .* randn(p, K)
        Y = Λ_true * randn(K, n) + 0.4 .* randn(p, n)

        mask = trues(p, n)
        cells = [(2, 3), (4, 10), (1, 200)]
        for (r, c) in cells
            mask[r, c] = false
        end

        fit = fit_gaussian_gllvm(Y; K = K, mask = mask)
        @test fit.converged

        out = predict_missing(fit, Y; mask = mask, type = :link)
        @test length(out.row) == length(cells)
        got = Set(zip(out.row, out.col))
        @test got == Set(cells)

        full_pred = predict(fit, Y; type = :link, mask = mask)
        for i in eachindex(out.row)
            @test out.est[i] == full_pred[out.row[i], out.col[i]]
        end

        # complete data (mask === nothing) ⇒ zero-row result.
        out_full = predict_missing(fit, Y)
        @test length(out_full.row) == 0
        @test length(out_full.col) == 0
        @test length(out_full.est) == 0

        @test_throws ArgumentError predict_missing(fit, Y; mask = trues(p + 1, n))
    end

    @testset "1.5 simulate_unit_trait — ADEMP recovery + seed reproducibility" begin
        rng = Random.MersenneTwister(55)
        n_traits, K_B, K_W = 3, 1, 1
        ΛB_true = reshape([0.9, 0.7, 0.5], n_traits, K_B)
        ΛW_true = reshape([0.6, 0.4, 0.3], n_traits, K_W)
        ψ_B = fill(0.3, n_traits)
        ψ_W = fill(0.2, n_traits)
        σ2eps = 0.4

        sim = simulate_unit_trait(rng; n_units = 400, n_obs_per_unit = 4,
                                  n_traits = n_traits, K_B = K_B, K_W = K_W,
                                  Lambda_B = ΛB_true, Lambda_W = ΛW_true,
                                  psi_B = ψ_B, psi_W = ψ_W, sigma2_eps = σ2eps)
        @test size(sim.Y) == (n_traits, 400 * 4)
        @test length(sim.individual) == 400 * 4
        @test sim.truth.Sigma_B ≈ ΛB_true * ΛB_true' + Diagonal(ψ_B) atol = 1e-10
        @test sim.truth.Sigma_W ≈ ΛW_true * ΛW_true' + Diagonal(ψ_W .+ σ2eps) atol = 1e-10

        fitted = fit_twolevel_gaussian(sim.Y, sim.individual; K_B = K_B, K_W = K_W)
        @test fitted.converged
        @test cor(vec(fitted.Σ_B), vec(sim.truth.Sigma_B)) > 0.85
        @test cor(vec(fitted.Σ_W), vec(sim.truth.Sigma_W)) > 0.85
        @test maximum(abs.(diag(fitted.Σ_W) .- diag(sim.truth.Sigma_W))) < 0.15

        # Seed reproducibility: same rng state ⇒ identical draws.
        sim_a = simulate_unit_trait(Random.MersenneTwister(9); n_units = 10,
                                    n_obs_per_unit = 2, n_traits = 3)
        sim_b = simulate_unit_trait(Random.MersenneTwister(9); n_units = 10,
                                    n_obs_per_unit = 2, n_traits = 3)
        @test sim_a.Y == sim_b.Y
        @test sim_a.individual == sim_b.individual

        @test_throws ArgumentError simulate_unit_trait(; n_units = 0)
        @test_throws ArgumentError simulate_unit_trait(; alpha = [1.0, 2.0])
    end

    @testset "1.6 profile_cross_rho — duck-typed grid driver" begin
        A_H = [1.0 0.3; 0.3 1.0]
        A_P = [1.0 0.2; 0.2 1.0]
        W = [1.0 0.0; 0.5 1.0]

        # stub refit: known logLik = -(rho - 0.2)^2, mirrors R's stats::lm example.
        stub_refit(K, rho) = (logLik = -(rho - 0.2)^2, converged = true)
        rho_grid = collect(-0.8:0.2:0.8)
        out = profile_cross_rho(A_H, A_P, W, stub_refit; rho_grid = rho_grid)

        @test Set(propertynames(out.table)) ⊇ Set((:rho, :logLik, :relative_logLik,
            :delta_deviance, :is_best, :convergence, :pd_hessian, :status, :error))
        best_idx = argmin(abs.(rho_grid .- 0.2))
        @test out.table.is_best[best_idx]
        @test out.best_rho == rho_grid[best_idx]
        @test out.table.relative_logLik ≈ out.table.logLik .- maximum(out.table.logLik)
        @test out.table.delta_deviance ≈ 2 .* (maximum(out.table.logLik) .- out.table.logLik)
        @test all(out.table.status .== :ok)
        @test out.fits === nothing

        # error capture: a refit that always throws ⇒ every row errors, and
        # since no finite logLik survives the sweep throws (nothing to rank).
        throwing_refit(K, rho) = error("boom")
        @test_throws ArgumentError profile_cross_rho(A_H, A_P, W, throwing_refit;
            rho_grid = [0.1, 0.2])

        # partial failure — some rho values throw, best is picked from survivors.
        mixed_refit(K, rho) = rho < 0 ? error("bad rho") : (logLik = -(rho - 0.5)^2, converged = true)
        out_mixed = profile_cross_rho(A_H, A_P, W, mixed_refit; rho_grid = [-0.5, 0.3, 0.5],
                                      keep_fits = true)
        @test out_mixed.table.status == [:error, :ok, :ok]
        @test out_mixed.best_rho == 0.5
        @test out_mixed.fits !== nothing
        @test out_mixed.fits[1] === nothing

        @test_throws ArgumentError profile_cross_rho(A_H, A_P, W, stub_refit; rho_grid = [1.5])

        # integration case through fit_coevolution_gaussian: K_star is the
        # n×n column (SPECIES) covariance of the T×n matrix-normal Y, T being
        # the stacked-TRAIT axis — independent of A_H/A_P/W's own dimension.
        Random.seed!(6)
        rho_true = 0.35
        n_species = size(A_H, 1) + size(A_P, 1)   # 4
        K_true = Matrix(make_cross_kernel(A_H, A_P, W; rho = rho_true))
        L_true = cholesky(Symmetric(K_true)).L    # n_species × n_species
        T_traits, d = 3, 1
        Λtrait = 0.6 .* randn(T_traits, d)
        Ystack = Λtrait * (randn(d, n_species) * L_true') .+
                 0.4 .* (randn(T_traits, n_species) * L_true')
        function real_refit(K, rho)
            r = fit_coevolution_gaussian(Ystack, K; d = 1)
            return r
        end
        out_real = profile_cross_rho(A_H, A_P, W, real_refit;
                                     rho_grid = [0.0, 0.2, 0.35, 0.5, 0.7])
        @test any(out_real.table.status .== :ok)
        @test isfinite(out_real.best_rho)
    end

    @testset "1.8 rotate_loadings — varimax/promax invariants" begin
        Random.seed!(8)
        p, K, n = 8, 2, 500
        Λ_true = zeros(p, K)
        Λ_true[1:4, 1] .= 0.8 .* abs.(randn(4))
        Λ_true[5:8, 2] .= 0.8 .* abs.(randn(4))
        y = Λ_true * randn(K, n) + 0.4 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        out_v = rotate_loadings(fit, y; method = :varimax)
        @test out_v.Lambda ≈ fit.pars.Λ * out_v.T atol = 1e-8
        @test out_v.T' * out_v.T ≈ Matrix(I, K, K) atol = 1e-8   # orthogonal
        @test out_v.method === :varimax
        @test issorted(out_v.axis_variance; rev = true)          # order_axes monotone
        for k in 1:K
            @test out_v.Lambda[out_v.anchor_traits[k], k] >= 0    # anchor loads positive
        end

        out_p = rotate_loadings(fit, y; method = :promax)
        @test out_p.Lambda ≈ fit.pars.Λ * out_p.T atol = 1e-8
        @test out_p.scores ≈ getLV(fit, y; rotate = false) * inv(out_p.T)' atol = 1e-6
        @test out_p.method === :promax

        # method = :none / d = 1 identity short-circuit on the ROTATION step
        # (order_axes/sign_anchor postprocessing still applies, as in R).
        out_none = rotate_loadings(fit, y; method = :none, order_axes = false,
                                   sign_anchor = :none)
        @test out_none.Lambda ≈ fit.pars.Λ
        @test out_none.T ≈ Matrix(I, K, K)
        @test out_none.axis_order == 1:K

        fit1 = fit_gaussian_gllvm(y; K = 1)
        out1 = rotate_loadings(fit1, y; method = :varimax, sign_anchor = :none)
        @test out1.Lambda ≈ fit1.pars.Λ
        @test out1.T ≈ Matrix(I, 1, 1)

        # sign_anchor = :none skips the flip.
        out_nosign = rotate_loadings(fit, y; method = :varimax, sign_anchor = :none)
        @test out_nosign.anchor_traits === nothing

        @test_throws ArgumentError rotate_loadings(fit, y; method = :bogus)
        @test_throws ArgumentError rotate_loadings(fit, y; level = :unit_obs)
    end

    @testset "1.9 extract_rotated_loadings_table — tidy wrapper" begin
        Random.seed!(9)
        p, K, n = 6, 2, 500
        Λ_true = zeros(p, K)
        Λ_true[1:3, 1] .= 0.7 .* abs.(randn(3))
        Λ_true[4:6, 2] .= 0.7 .* abs.(randn(3))
        y = Λ_true * randn(K, n) + 0.5 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        rot = rotate_loadings(fit, y; method = :varimax)
        tab = extract_rotated_loadings_table(fit, y; method = :varimax, loading_scale = :raw)

        @test length(tab.trait) == p * K
        idx = 0
        for k in 1:K, t in 1:p
            idx += 1
            @test tab.trait[idx] == t
            @test tab.axis[idx] == k
            @test tab.loading[idx] ≈ rot.Lambda[t, k]
            @test tab.abs_loading[idx] ≈ abs(rot.Lambda[t, k])
            @test tab.axis_variance[idx] ≈ rot.axis_variance[k]
        end
        # axis_share sums to 1 across unique axes.
        share_per_axis = [tab.axis_share[findfirst(==(k), tab.axis)] for k in 1:K]
        @test sum(share_per_axis) ≈ 1.0 atol = 1e-10

        tab_std = extract_rotated_loadings_table(fit, y; method = :varimax, loading_scale = :standardized)
        total_var = diag(extract_Sigma(fit; level = :unit, part = :total).Sigma)
        for k in 1:K, t in 1:p
            i = (k - 1) * p + t
            @test tab_std.loading[i] ≈ rot.Lambda[t, k] / sqrt(total_var[t]) atol = 1e-10
        end
        # axis_variance/axis_share unaffected by standardization (raw-Λ based).
        @test tab_std.axis_variance == tab.axis_variance

        @test_throws ArgumentError extract_rotated_loadings_table(fit, y; loading_scale = :bogus)
    end

    @testset "1.11 extract_coevolution_modules — known low-rank Γ, hand SVD" begin
        Random.seed!(11)
        row_traits = 1:3
        col_traits = 4:6
        Σ_row = Diagonal(fill(2.0, 3))    # block-diagonal Σ ⇒ inv-sqrt is diagonal
        Σ_col = Diagonal(fill(3.0, 3))
        U0 = randn(3, 2)
        V0 = randn(3, 2)
        Γ = 0.5 .* (Σ_row^0.5) * U0 * V0' * (Σ_col^0.5)   # known cross block

        Σ_shared = zeros(6, 6)
        Σ_shared[1:3, 1:3] = Σ_row
        Σ_shared[4:6, 4:6] = Σ_col
        Σ_shared[1:3, 4:6] = Γ
        Σ_shared[4:6, 1:3] = Γ'

        out = extract_coevolution_modules(Σ_shared; row_traits = collect(row_traits),
                                          col_traits = collect(col_traits))

        R_expected = (1 / sqrt(2)) .* Γ .* (1 / sqrt(3))
        @test out.R ≈ R_expected atol = 1e-8

        F = svd(R_expected)
        @test out.modules.singular_value ≈ F.S atol = 1e-8
        @test sum(out.modules.squared_share) ≈ 1.0 atol = 1e-10
        @test out.modules.squared_share ≈ (F.S .^ 2) ./ sum(abs2, F.S) atol = 1e-8

        @test length(out.row_axes.trait) == 3 * length(F.S)
        @test length(out.col_axes.trait) == 3 * length(F.S)
        # spot-check one entry against the hand SVD (up to sign ambiguity).
        i1 = findfirst(i -> out.row_axes.trait[i] == 1 && out.row_axes.component[i] == 1, eachindex(out.row_axes.trait))
        @test abs(out.row_axes.loading[i1]) ≈ abs(F.U[1, 1]) atol = 1e-8

        # abort on a numerically-zero Σ block.
        Σ_shared_bad = copy(Σ_shared)
        Σ_shared_bad[1:3, 1:3] .= 0.0
        @test_throws ArgumentError extract_coevolution_modules(Σ_shared_bad;
            row_traits = collect(row_traits), col_traits = collect(col_traits))
    end

end
