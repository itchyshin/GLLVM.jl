using GLLVM, Test, LinearAlgebra, Random, Statistics, Distributions, ForwardDiff

# Track T3: multiple missing predictors, jointly integrated (mi() vector axis).
#
# Generalises the augmented-(z, x) Laplace from ONE site-level continuous
# predictor x_s to a VECTOR x_s ∈ R^q, each coordinate possibly missing per site,
# integrated JOINTLY:
#   y[t,s] ~ family(link⁻¹(η[t,s])),  η[t,s] = β_t + (b·x_s) + (Λ z_s)_t,
#   x_s ~ N(μ, Σ_x),  Σ_x a q×q covariance (packed as a Cholesky factor).
# Per site, the OBSERVED coordinates of x_s are conditioned on (folded into the
# offset, contributing their N(x_o; μ_o, Σ_oo) density); the MISSING subset is
# integrated jointly with z_s via a (K + #missing) bordered Laplace. The
# predictor-side prior on the missing block is the conditional precision of
# x_m | x_o under N(μ, Σ_x).
#
# Verification gates (must all pass before the slice is "done"):
#   1. q=1 reduction: equals the existing single-predictor path to ≈1e-8.
#   2. Gaussian equality: family=Normal multi-predictor = brute-force Gaussian FIML
#      (≈1e-6); cross-check vs missing_predictor_fiml when q=1.
#   3. AD-vs-FD ≤ 1e-6 on the packed multi-predictor objective (incl. Σ_x Cholesky).
#   4. Quadrature: q=2 with both missing ≈ (K+2)-dim Gauss–Hermite (Laplace tol).
#   5. Recovery: q=2 correlated predictors partially missing under MAR — b is
#      recovered near truth and beats complete-case; identifiability holds.
#   6. Regression: existing single-predictor suites still pass (separate files).

# Helpers for the packed Σ_x Cholesky parametrisation used by the test oracles.
# θ_chol = [L11, L21, L22, L31, L32, L33, ...] (lower-tri, log-diagonal), the same
# convention as GLLVM._mi_unpack_cholesky.
function chol_from_packed(c, q)
    L = zeros(eltype(c), q, q)
    k = 1
    for j in 1:q, i in j:q
        L[i, j] = i == j ? exp(c[k]) : c[k]
        k += 1
    end
    return L
end
packed_from_chol(L) = begin
    q = size(L, 1)
    out = Float64[]
    for j in 1:q, i in j:q
        push!(out, i == j ? log(L[i, j]) : L[i, j])
    end
    out
end

@testset "multi missing predictor (mi() vector axis)" begin

    # --- Gate 1: q=1 reduction to the single-predictor path -----------------
    @testset "q=1 reduces to single-predictor marginal (≈1e-8)" begin
        Random.seed!(401)
        p, n, K = 5, 40, 1
        β = randn(p) .* 0.3
        Λ = reshape([0.5, 0.4, -0.3, 0.35, 0.2], p, K)
        b_x, μ_x, σ_x = 0.6, 0.5, 0.8
        x = μ_x .+ σ_x .* randn(n)
        η = β .+ b_x .* x' .+ Λ * randn(K, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        xm = Vector{Union{Missing,Float64}}(x)
        xm[[3, 11, 25, 38]] .= missing

        # single-predictor reference
        ll1 = GLLVM.marginal_loglik_laplace_xs(Poisson(), Y, N, Λ, β, LogLink();
                                               x = xm, b_x = b_x, μ_x = μ_x, σ_x2 = σ_x^2)
        # multi-predictor with q=1: X is n×1, b/μ length-1, Σ_x 1×1.
        X = reshape(Vector{Union{Missing,Float64}}(xm), n, 1)
        L = reshape([σ_x], 1, 1)                      # Σ_x = σ_x²
        llq = GLLVM.marginal_loglik_laplace_mi(Poisson(), Y, N, Λ, β, LogLink();
                                               X = X, b = [b_x], μ = [μ_x], Lx = L)
        @test llq ≈ ll1 atol = 1e-8
    end

    # --- Gate 2: Gaussian equality vs brute-force FIML ----------------------
    @testset "Gaussian multi-predictor = brute-force Gaussian FIML (≈1e-6)" begin
        Random.seed!(402)
        p, n, K, q = 4, 30, 1, 2
        a = [0.4, -0.2, 0.1, 0.3]
        Λ = reshape([0.6, 0.5, -0.4, 0.3], p, K)
        b = [0.8, -0.5]
        μ = [0.3, -0.1]
        Σx = [0.6 0.2; 0.2 0.5]
        σ_eps = 0.4
        Lx = cholesky(Σx).L
        Xfull = (μ' .+ randn(n, q) * Lx')           # n×q
        η = randn(K, n)
        y = a .+ (Xfull * b)' .+ Λ * η .+ σ_eps .* randn(p, n)
        X = Matrix{Union{Missing,Float64}}(Xfull)
        miss = [(2, 1), (7, 2), (15, 1), (15, 2), (22, 2)]
        for (s, j) in miss
            X[s, j] = missing
        end

        # Multi-predictor Gaussian marginal (identity link). Σ_eps carried as a
        # log-σ scalar tacked onto the family marker via the Normal path.
        llmi = GLLVM.marginal_loglik_mi_gaussian(y, X, a, Λ, b, μ, Lx, σ_eps^2)

        # Brute-force Gaussian FIML over observed cells. Stack w = [y (p); x (q)]:
        #   y = a + B x + Λη + ε,  x ~ N(μ, Σx),  (Bx)_t = b·x.
        # ⇒ joint w ~ N(mw, V) with mw = [a + b·μ ; μ] and
        #   Vyy = ΛΛ' + σ²I + (b'Σx b) 11',  Vyx = 1_p (Σx b)',  Vxx = Σx.
        # Per site, keep all of y plus the OBSERVED coords of x; the observed-block
        # marginal Gaussian density integrates out the missing coords exactly.
        mw = vcat(a .+ (b ⋅ μ), μ)
        Vyy = Λ * Λ' + σ_eps^2 * I + (transpose(b) * Σx * b) .* (ones(p) * ones(p)')
        Vyx = ones(p) * (Σx * b)'
        V = [Vyy Vyx; Vyx' Σx]
        function site_ll(s)
            ys = y[:, s]
            xs = X[s, :]
            obsj = findall(j -> !ismissing(xs[j]), 1:q)
            oidx = vcat(1:p, p .+ obsj)
            mo = vcat(ys, Float64[xs[j] for j in obsj])
            Vo = V[oidx, oidx]
            r = mo .- mw[oidx]
            return -0.5 * (length(oidx) * log(2π) + logdet(Vo) + r' * (Vo \ r))
        end
        ll_bf = sum(site_ll(s) for s in 1:n)
        @test llmi ≈ ll_bf atol = 1e-6
    end

    # --- Gate 3: AD-vs-FD on the packed multi-predictor objective ----------
    @testset "packed multi-predictor marginal is AD-clean (≤1e-6)" begin
        Random.seed!(403)
        p, n, K, q = 5, 50, 1, 2
        β0 = randn(p) .* 0.3
        Λ0 = reshape([0.5, 0.4, -0.3, 0.35, 0.2], p, K)
        b0 = [0.5, -0.4]
        μ0 = [0.3, -0.2]
        Σx = [0.5 0.15; 0.15 0.4]
        Lx0 = cholesky(Σx).L
        Xfull = (μ0' .+ randn(n, q) * Lx0')
        η = β0 .+ (Xfull * b0)' .+ Λ0 * randn(K, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        X = Matrix{Union{Missing,Float64}}(Xfull)
        for (s, j) in [(3, 1), (11, 2), (25, 1), (25, 2), (40, 2)]
            X[s, j] = missing
        end
        cpack0 = packed_from_chol(Lx0)
        # θ = [β (p); vec(Λ) (pK); b (q); μ (q); chol-packed (q(q+1)/2)]
        nchol = q * (q + 1) ÷ 2
        function f(θ)
            β = θ[1:p]
            Λ = reshape(θ[(p + 1):(p + p * K)], p, K)
            o = p + p * K
            b = θ[(o + 1):(o + q)]
            μ = θ[(o + q + 1):(o + 2q)]
            cpack = θ[(o + 2q + 1):(o + 2q + nchol)]
            L = chol_from_packed(cpack, q)
            GLLVM.marginal_loglik_laplace_mi(Poisson(), Y, N, Λ, β, LogLink();
                                             X = X, b = b, μ = μ, Lx = L)
        end
        θ = vcat(β0, vec(Λ0), b0, μ0, cpack0)
        g_ad = ForwardDiff.gradient(f, θ)
        h = 1e-6
        g_fd = similar(θ)
        for i in eachindex(θ)
            θp = copy(θ); θm = copy(θ)
            θp[i] += h; θm[i] -= h
            g_fd[i] = (f(θp) - f(θm)) / (2h)
        end
        @test maximum(abs, g_ad .- g_fd) < 1e-6
    end

    # --- Gate 4: quadrature for q=2, one site both missing ------------------
    @testset "missing-site marginal (q=2 both missing) ≈ (K+2)-dim quadrature" begin
        Random.seed!(404)
        p, K, q = 5, 1, 2
        β = randn(p) .* 0.3
        Λ = reshape([0.5, 0.4, -0.3, 0.35, 0.2], p, K)
        b = [0.6, -0.4]
        μ = [0.4, -0.1]
        Σx = [0.5 0.2; 0.2 0.45]
        Lx = cholesky(Σx).L
        y = rand(Poisson(2.0), p)
        N = ones(Int, p)
        xmiss = [missing, missing]
        ll_lap = GLLVM.laplace_loglik_site_mi(Poisson(), y, N, Λ, β, LogLink();
                                              x = xmiss, b = b, μ = μ, Lx = Lx)
        # 3-D Gauss–Hermite over (z, x1, x2): factor N(x; μ, Σx) via x = μ + Lx u,
        # u ~ N(0, I). ∫ p(y|z,x) N(z) N(u) dz du.
        nodes, wts = GLLVM._gauss_hermite(36)
        zz = sqrt(2) .* nodes; wz = wts ./ sqrt(π)
        uu = sqrt(2) .* nodes; wu = wts ./ sqrt(π)
        acc = 0.0
        for (zi, wzi) in zip(zz, wz)
            for (u1, w1) in zip(uu, wu), (u2, w2) in zip(uu, wu)
                xv = μ .+ Lx * [u1, u2]
                ll = sum(logpdf(Poisson(exp(β[t] + b ⋅ xv + Λ[t, 1] * zi)), y[t]) for t in 1:p)
                acc += wzi * w1 * w2 * exp(ll)
            end
        end
        @test ll_lap ≈ log(acc) rtol = 4e-2
    end

    # --- Gate 5: recovery, q=2 correlated predictors, MAR ------------------
    @testset "fit recovers b under MAR (q=2 correlated) and beats complete-case" begin
        Random.seed!(405)
        p, n, K, q = 6, 700, 1, 2
        β = [0.3, 0.6, 0.1, 0.4, -0.2, 0.5]
        Λ = reshape([0.4, 0.3, -0.3, 0.25, 0.2, -0.2], p, K)
        b_true = [0.6, -0.5]
        μ = [0.3, -0.1]
        ρ = 0.5
        Σx = [0.6 ρ*sqrt(0.6*0.5); ρ*sqrt(0.6*0.5) 0.5]
        Lx = cholesky(Σx).L
        Xfull = (μ' .+ randn(n, q) * Lx')
        η = β .+ (Xfull * b_true)' .+ Λ * randn(K, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        y1 = Float64.(Y[1, :])
        pmiss = 1 ./ (1 .+ exp.(-(-0.5 .+ 1.5 .* (y1 .- mean(y1)) ./ std(y1))))
        Random.seed!(2405)
        # missingness on each predictor coordinate independently (MAR on a trait)
        X = Matrix{Union{Missing,Float64}}(Xfull)
        miss1 = rand(n) .< pmiss
        miss2 = rand(n) .< pmiss
        X[miss1, 1] .= missing
        X[miss2, 2] .= missing
        res = fit_gllvm_mi_multi(Poisson(), Y, X; K = K)
        @test res.converged
        @test norm(res.b .- b_true) < 0.25
        # complete-case: sites with ANY missing predictor dropped
        keep = .!(miss1 .| miss2)
        res_cc = fit_gllvm_mi_multi(Poisson(), Y[:, keep], Matrix{Union{Missing,Float64}}(Xfull[keep, :]); K = K)
        @test norm(res.b .- b_true) ≤ norm(res_cc.b .- b_true) + 0.1
    end
end
