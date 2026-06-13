using GLLVM, Test, Random, LinearAlgebra, Distributions

@testset "Poisson Wald CIs (observed information)" begin
    Random.seed!(20260613)
    p, K, n = 6, 2, 200
    Λ_true = randn(p, K) .* 0.5
    for i in 1:K, k in 1:K
        i < k && (Λ_true[i, k] = 0.0)
    end
    β_true = randn(p) .* 0.3 .- 0.4
    ηs = randn(K, n)
    M  = Λ_true * ηs .+ β_true
    Y  = [rand(Poisson(exp(clamp(M[t, s], -30, 30)))) for t in 1:p, s in 1:n]

    fit = GLLVM.fit_poisson_gllvm(Y; K = K)
    @test fit.converged

    rr = GLLVM.rr_theta_len(p, K)
    ci = GLLVM.confint(fit; y = Y)

    # --- structure ---
    @test length(ci.term) == p + rr
    @test ci.pd_hessian
    @test all(isfinite, ci.se)
    @test all(isfinite, ci.lower) && all(isfinite, ci.upper)
    @test all(ci.lower .< ci.estimate .< ci.upper)

    # --- the Wald SEs must match a central-FD Hessian of the same NLL (oracle) ---
    nll(θ) = -GLLVM.poisson_marginal_loglik_laplace(
        Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], GLLVM.LogLink())
    θ̂ = vcat(fit.β, GLLVM.pack_lambda(fit.Λ))
    np = length(θ̂); h = 1e-4; H = zeros(np, np)
    for i in 1:np, j in i:np
        a = copy(θ̂); a[i] += h; a[j] += h
        b = copy(θ̂); b[i] += h; b[j] -= h
        c = copy(θ̂); c[i] -= h; c[j] += h
        d = copy(θ̂); d[i] -= h; d[j] -= h
        H[i, j] = (nll(a) - nll(b) - nll(c) + nll(d)) / (4h * h); H[j, i] = H[i, j]
    end
    se_fd = sqrt.(diag(inv(Symmetric((H .+ H') ./ 2))))
    @test maximum(abs.(ci.se .- se_fd)) < 1e-3

    # --- intercept Wald CIs cover the truth at roughly nominal rate ---
    cover = count(ci.lower[1:p] .<= β_true .<= ci.upper[1:p])
    @test cover >= p - 2

    # --- parm selection works ---
    ci_b = GLLVM.confint(fit; y = Y, parm = "beta")
    @test length(ci_b.term) == p
    @test all(startswith.(ci_b.term, "beta"))
end
