using GLLVM, Test, Random, LinearAlgebra
using Distributions: Poisson

@testset "Poisson grouped random slopes (non-Gaussian random regression)" begin
    # ------------------------------------------------------------------
    # GATE 2: q=1 reduces to a Poisson random INTERCEPT.
    # (a) logLik MATCH: the per-group slope marginal at q=1, Z=ones, with
    #     singleton groups (each group = one site) equals the per-site random-row
    #     marginal `row_random_marginal_loglik_laplace` (σ_row = √Σ_b[1,1]) to
    #     machine zero — the random intercept IS a per-site/per-group offset.
    # (b) RECOVERY: a fitted q=1 model on simulated grouped random-intercept
    #     Poisson data recovers the intercept SD.
    # ------------------------------------------------------------------
    @testset "q=1 logLik match vs the random-intercept marginal (≈0)" begin
        Random.seed!(71001)
        p, K, n = 5, 1, 30
        Λ = 0.4 .* randn(p, K); β = 0.3 .* randn(p)
        σ_u = 0.6
        Y = float.(rand(0:4, p, n)); N = ones(Int, p, n)
        Z = ones(n, 1)
        gi_singleton = [[i] for i in 1:n]                 # each group = one site
        Lb = fill(σ_u, 1, 1)                              # Σ_b = [σ_u²]
        ll_group = GLLVM.random_slope_marginal_loglik_laplace(
            Poisson(), Y, N, Z, Λ, β, Lb, gi_singleton; link = GLLVM.LogLink())
        ll_row = GLLVM.row_random_marginal_loglik_laplace(
            Poisson(), Y, N, Λ, β, σ_u; link = GLLVM.LogLink())
        @test isapprox(ll_group, ll_row; atol = 1e-9)
    end

    @testset "q=1 recovery of a grouped random-intercept SD" begin
        Random.seed!(72002)
        p, K, n, L = 6, 1, 600, 60
        Λt = 0.4 .* randn(p, K); βt = log.(2 .+ rand(p))
        grouping = vcat(collect(1:L), rand(1:L, n - L))
        Z = ones(n, 1)
        σ_u = 0.6
        bdraw = [σ_u * randn() for _ in 1:L]
        re = [bdraw[grouping[i]] for i in 1:n]
        η = βt .+ Λt * randn(K, n) .+ reshape(re, 1, n)
        Y = float.([rand(Poisson(exp(clamp(η[t, i], -20, 20)))) for t in 1:p, i in 1:n])
        fit = fit_poisson_random_slope(Y, grouping, Z; K = K, iterations = 600)
        @test fit.q == 1 && size(fit.Σ_b) == (1, 1)
        @test fit.converged
        @test isfinite(fit.loglik)
        @test fit.Σ_b[1, 1] > 0                              # valid variance
        @test isapprox(sqrt(fit.Σ_b[1, 1]), σ_u; atol = 0.15)  # intercept SD recovered
    end

    # ------------------------------------------------------------------
    # GATE 1: recovery of a known Σ_b on simulated Poisson random intercept+slope
    # data (q=2, correlated). The variance components recover near truth within
    # Monte-Carlo error; the engine always returns an SPD Σ_b. The random-effect
    # CORRELATION at a modest number of groups is noisier — assert variances within
    # a tolerance and the correlation as a valid in-range value (SPD always).
    # ------------------------------------------------------------------
    @testset "q=2 (intercept + slope) recovery of a known Σ_b" begin
        Random.seed!(72003)
        p, K, n, L = 6, 1, 1500, 150
        Λt = 0.4 .* randn(p, K); βt = log.(2 .+ rand(p))
        x = randn(n); grouping = vcat(collect(1:L), rand(1:L, n - L))
        Z = hcat(ones(n), x)                                  # intercept + slope
        Σ_b = [0.5 0.15; 0.15 0.4]                            # correlated intercept+slope
        Lb = cholesky(Symmetric(Σ_b)).L
        bdraw = [Lb * randn(2) for _ in 1:L]                  # b_g ~ N(0, Σ_b)
        re = [Z[i, 1] * bdraw[grouping[i]][1] + Z[i, 2] * bdraw[grouping[i]][2] for i in 1:n]
        η = βt .+ Λt * randn(K, n) .+ reshape(re, 1, n)
        Y = float.([rand(Poisson(exp(clamp(η[t, i], -20, 20)))) for t in 1:p, i in 1:n])
        fit = fit_poisson_random_slope(Y, grouping, Z; K = K, iterations = 800)
        @test fit.q == 2 && size(fit.Σ_b) == (2, 2)
        @test fit.converged
        @test isfinite(fit.loglik)
        @test isposdef(Symmetric(fit.Σ_b))                   # valid SPD random-effect covariance
        @test isapprox(fit.Σ_b[1, 1], Σ_b[1, 1]; atol = 0.2)   # intercept variance
        @test isapprox(fit.Σ_b[2, 2], Σ_b[2, 2]; atol = 0.2)   # slope variance
        ρ̂ = fit.Σ_b[1, 2] / sqrt(fit.Σ_b[1, 1] * fit.Σ_b[2, 2])
        @test -1 < ρ̂ < 1                                      # a valid correlation
        @test isapprox(ρ̂, Σ_b[1, 2] / sqrt(Σ_b[1, 1] * Σ_b[2, 2]); atol = 0.2)  # ρ near truth
    end

    # ------------------------------------------------------------------
    # GATE 3: the finite-difference gradient of the packed Laplace objective is
    # finite and well-defined (the inner mode-finder is not forward-AD-friendly,
    # like all the non-Gaussian fitters — they use FD gradients). We verify it by
    # an INDEPENDENT 4th-order (5-point) FD reference: the central (2nd-order) FD
    # gradient the fitter consumes agrees with the 5-point gradient to ≤ 1e-6.
    # ------------------------------------------------------------------
    @testset "FD-gradient ≤ 1e-6 (q=2; central vs 5-point reference)" begin
        Random.seed!(71003)
        p, K, n, L = 4, 1, 50, 6
        Λt = 0.4 .* randn(p, K); βt = 0.2 .* randn(p)
        x = randn(n); grouping = vcat(collect(1:L), rand(1:L, n - L))
        Z = hcat(ones(n), x)
        codes, _ = GLLVM._code_grouping(grouping)
        gi = [findall(==(g), codes) for g in 1:maximum(codes)]
        Y = float.(rand(0:5, p, n)); N = ones(Int, p, n)
        rr = GLLVM.rr_theta_len(p, K); nc = GLLVM._chol_cov_npar(2)
        f = θ -> begin
            β = θ[1:p]
            Λ = GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K)
            _, Lb = GLLVM._unpack_chol_cov(θ[(p + rr + 1):(p + rr + nc)], 2)
            -GLLVM.random_slope_marginal_loglik_laplace(
                Poisson(), Y, N, Z, Λ, β, Lb, gi; link = GLLVM.LogLink())
        end
        θ = vcat(βt, GLLVM.pack_lambda(Λt), [log(0.5), 0.1, log(0.4)])
        # central (2nd-order) FD — what the fitter's autodiff=:finite consumes
        gc = similar(θ); hc = 1e-6
        for i in eachindex(θ)
            s = hc * max(1.0, abs(θ[i])); tp = copy(θ); tp[i] += s; tm = copy(θ); tm[i] -= s
            gc[i] = (f(tp) - f(tm)) / (2s)
        end
        # 4th-order 5-point FD reference
        g5 = similar(θ); h5 = 1e-4
        for i in eachindex(θ)
            s = h5 * max(1.0, abs(θ[i]))
            t1 = copy(θ); t1[i] += 2s; t2 = copy(θ); t2[i] += s
            t3 = copy(θ); t3[i] -= s;  t4 = copy(θ); t4[i] -= 2s
            g5[i] = (-f(t1) + 8f(t2) - 8f(t3) + f(t4)) / (12s)
        end
        @test all(isfinite, gc)
        @test maximum(abs.(gc .- g5)) ≤ 1e-6
    end
end
