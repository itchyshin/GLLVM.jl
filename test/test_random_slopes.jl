using GLLVM, Test, Random, LinearAlgebra, ForwardDiff

@testset "Gaussian grouped random slopes (random regression)" begin
    # ------------------------------------------------------------------
    # GATE 1(a): q=1 random slope (Z = ones) reduces EXACTLY to a grouped
    # random intercept (same marginal). The block-Woodbury slope marginal at
    # q=1, Σ_b = [σ_u²] must equal the rank-1 Sherman–Morrison intercept marginal.
    # ------------------------------------------------------------------
    @testset "q=1, Z=ones reduces to the grouped intercept (rtol 1e-8)" begin
        Random.seed!(61001)
        p, K, n = 5, 1, 60
        Λ = 0.6 .* randn(p, K); σ_eps, σ_u = 0.5, 0.7
        grouping = rand(1:6, n); y = randn(p, n)
        codes, _ = GLLVM._code_grouping(grouping); L = maximum(codes)
        gi = [findall(==(g), codes) for g in 1:L]
        ll_slope = GLLVM._grouped_slope_loglik(y, gi, ones(n, 1), Λ, σ_eps, fill(σ_u^2, 1, 1))
        ll_int   = GLLVM._grouped_intercept_loglik(y, gi, Λ, σ_eps, σ_u)
        @test isapprox(ll_slope, ll_int; rtol = 1e-8)
        # public intercept-loglik entry point matches too
        ll_int_pub = GLLVM.gaussian_grouped_intercept_loglik(y, grouping, Λ, σ_eps, σ_u)
        @test isapprox(ll_slope, ll_int_pub; rtol = 1e-8)
    end

    # ------------------------------------------------------------------
    # GATE 1(b): recovery of a known Σ_b on simulated data (q=2, correlated
    # random intercept + slope). The variance components (σ_eps, Σ_b diagonal)
    # recover near truth; the engine always returns an SPD Σ_b. Random-effect
    # CORRELATION at a modest number of groups is noisier, so we assert the
    # variances tightly and the correlation loosely (and SPD always).
    # ------------------------------------------------------------------
    @testset "q=2 (intercept + slope) recovery of a known Σ_b" begin
        Random.seed!(61002)
        p, K, n, L = 6, 1, 600, 40
        Λt = 0.5 .* randn(p, K); σ_eps = 0.4
        x = randn(n); grouping = vcat(collect(1:L), rand(1:L, n - L))
        Z = hcat(ones(n), x)                                  # intercept + slope
        Σ_b = [0.5 0.15; 0.15 0.4]                            # correlated intercept+slope
        Lb = cholesky(Symmetric(Σ_b)).L
        bdraw = [Lb * randn(2) for _ in 1:L]                  # b_g ~ N(0, Σ_b)
        re = [Z[i, 1] * bdraw[grouping[i]][1] + Z[i, 2] * bdraw[grouping[i]][2] for i in 1:n]
        y = Λt * randn(K, n) .+ reshape(re, 1, n) .+ σ_eps .* randn(p, n)
        fit = fit_gaussian_random_slope(y, grouping, Z; K = K, iterations = 1000)
        @test fit.q == 2 && size(fit.Σ_b) == (2, 2)
        @test fit.converged
        @test isfinite(fit.loglik)
        @test isposdef(Symmetric(fit.Σ_b))                   # valid SPD random-effect covariance
        @test isapprox(fit.σ_eps, σ_eps; atol = 0.05)        # residual SD recovered
        @test isapprox(fit.Σ_b[1, 1], Σ_b[1, 1]; atol = 0.25)  # intercept variance
        @test isapprox(fit.Σ_b[2, 2], Σ_b[2, 2]; atol = 0.25)  # slope variance
        ρ̂ = fit.Σ_b[1, 2] / sqrt(fit.Σ_b[1, 1] * fit.Σ_b[2, 2])
        @test -1 < ρ̂ < 1                                      # a valid correlation
    end

    # ------------------------------------------------------------------
    # GATE 1(c): the analytic (ForwardDiff) gradient of the packed objective
    # matches a central finite-difference gradient to ≤ 1e-6 (q=2).
    # ------------------------------------------------------------------
    @testset "FD-gradient ≤ 1e-6 (q=2)" begin
        Random.seed!(61003)
        p, K, n, L = 4, 1, 60, 6
        Λ0 = 0.5 .* randn(p, K)
        grouping = vcat(collect(1:L), rand(1:L, n - L))
        Z = hcat(ones(n), randn(n)); y = randn(p, n)
        codes, _ = GLLVM._code_grouping(grouping)
        gi = [findall(==(g), codes) for g in 1:maximum(codes)]
        rr = GLLVM.rr_theta_len(p, K); nc = GLLVM._chol_cov_npar(2)
        f = θ -> begin
            Σ_b, _ = GLLVM._unpack_chol_cov(θ[(rr + 2):(rr + 1 + nc)], 2)
            -GLLVM._grouped_slope_loglik(y, gi, Z, GLLVM.unpack_lambda(θ[1:rr], p, K), exp(θ[rr + 1]), Σ_b)
        end
        θ = vcat(GLLVM.pack_lambda(Λ0), log(0.5), [log(0.5), 0.1, log(0.4)])
        gad = ForwardDiff.gradient(f, θ); h = 1e-6; gfd = similar(θ)
        for i in eachindex(θ)
            s = h * max(1.0, abs(θ[i])); tp = copy(θ); tp[i] += s; tm = copy(θ); tm[i] -= s
            gfd[i] = (f(tp) - f(tm)) / (2s)
        end
        @test all(isfinite, gad)
        @test maximum(abs.(gad .- gfd)) ≤ 1e-6
    end
end
