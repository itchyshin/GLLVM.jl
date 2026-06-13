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

@testset "Binomial (Bernoulli) Wald CIs" begin
    Random.seed!(20260614)
    p, K, n = 6, 2, 250
    Λ_true = randn(p, K) .* 0.6
    for i in 1:K, k in 1:K
        i < k && (Λ_true[i, k] = 0.0)
    end
    β_true = randn(p) .* 0.4
    ηs = randn(K, n)
    M  = Λ_true * ηs .+ β_true
    Pr = 1.0 ./ (1.0 .+ exp.(-clamp.(M, -30, 30)))
    Y  = [rand() < Pr[t, s] ? 1 : 0 for t in 1:p, s in 1:n]

    fit = GLLVM.fit_binomial_gllvm(Y; K = K)
    @test fit.converged

    rr = GLLVM.rr_theta_len(p, K)
    ci = GLLVM.confint(fit; y = Y)
    @test length(ci.term) == p + rr
    @test ci.pd_hessian
    @test all(isfinite, ci.se)
    @test all(ci.lower .< ci.estimate .< ci.upper)

    Nm = fill(1, size(Y))
    nll(θ) = -GLLVM.binomial_marginal_loglik_laplace(
        Y, Nm, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], fit.link)
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
    @test maximum(abs.(ci.se .- se_fd)) < 2e-3
end

@testset "Negative Binomial Wald CIs (dispersion on log scale)" begin
    Random.seed!(20260615)
    p, K, n = 5, 2, 300
    Λ_true = randn(p, K) .* 0.4
    for i in 1:K, k in 1:K
        i < k && (Λ_true[i, k] = 0.0)
    end
    β_true = randn(p) .* 0.3 .+ 1.0
    r_true = 5.0
    ηs = randn(K, n)
    μ  = exp.(clamp.(Λ_true * ηs .+ β_true, -30, 30))
    Y  = [rand(NegativeBinomial(r_true, r_true / (r_true + μ[t, s]))) for t in 1:p, s in 1:n]

    fit = GLLVM.fit_nb_gllvm(Y; K = K)
    @test fit.converged

    rr = GLLVM.rr_theta_len(p, K)
    ci = GLLVM.confint(fit; y = Y)
    @test length(ci.term) == p + rr + 1
    @test ci.term[end] == "r"
    @test ci.pd_hessian
    @test all(isfinite, ci.se)
    @test all(ci.lower .< ci.estimate .< ci.upper)
    @test ci.estimate[end] ≈ fit.r            # dispersion reported on the natural scale
    @test ci.lower[end] > 0                    # positive CI for r (log-scale Wald)

    nll(θ) = -GLLVM.nb_marginal_loglik_laplace(
        Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        exp(θ[p + rr + 1]); link = fit.link)
    θ̂ = vcat(fit.β, GLLVM.pack_lambda(fit.Λ), log(fit.r))
    np = length(θ̂); h = 1e-4; H = zeros(np, np)
    for i in 1:np, j in i:np
        a = copy(θ̂); a[i] += h; a[j] += h
        b = copy(θ̂); b[i] += h; b[j] -= h
        c = copy(θ̂); c[i] -= h; c[j] += h
        d = copy(θ̂); d[i] -= h; d[j] -= h
        H[i, j] = (nll(a) - nll(b) - nll(c) + nll(d)) / (4h * h); H[j, i] = H[i, j]
    end
    se_fd = sqrt.(diag(inv(Symmetric((H .+ H') ./ 2))))
    @test maximum(abs.(ci.se .- se_fd)) < 5e-3
end

@testset "Beta Wald CIs (precision on log scale)" begin
    Random.seed!(20260616)
    p, K, n = 5, 2, 300
    Λ_true = randn(p, K) .* 0.4
    for i in 1:K, k in 1:K
        i < k && (Λ_true[i, k] = 0.0)
    end
    β_true = randn(p) .* 0.3
    φ_true = 12.0
    ηs = randn(K, n)
    μ  = 1.0 ./ (1.0 .+ exp.(-clamp.(Λ_true * ηs .+ β_true, -30, 30)))
    Y  = [rand(Beta(μ[t, s] * φ_true, (1 - μ[t, s]) * φ_true)) for t in 1:p, s in 1:n]

    fit = GLLVM.fit_beta_gllvm(Y; K = K)
    @test fit.converged
    rr = GLLVM.rr_theta_len(p, K)
    ci = GLLVM.confint(fit; y = Y)
    @test length(ci.term) == p + rr + 1
    @test ci.term[end] == "phi"
    @test ci.pd_hessian
    @test all(ci.lower .< ci.estimate .< ci.upper)
    @test ci.estimate[end] ≈ fit.φ
    @test ci.lower[end] > 0

    nll(θ) = -GLLVM.beta_marginal_loglik_laplace(
        Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        exp(θ[p + rr + 1]); link = fit.link)
    θ̂ = vcat(fit.β, GLLVM.pack_lambda(fit.Λ), log(fit.φ))
    np = length(θ̂); h = 1e-4; H = zeros(np, np)
    for i in 1:np, j in i:np
        a = copy(θ̂); a[i]+=h; a[j]+=h; b = copy(θ̂); b[i]+=h; b[j]-=h
        c = copy(θ̂); c[i]-=h; c[j]+=h; d = copy(θ̂); d[i]-=h; d[j]-=h
        H[i, j] = (nll(a)-nll(b)-nll(c)+nll(d))/(4h*h); H[j, i] = H[i, j]
    end
    se_fd = sqrt.(diag(inv(Symmetric((H .+ H') ./ 2))))
    @test maximum(abs.(ci.se .- se_fd)) < 5e-3
end

@testset "Ordinal Wald CIs (cumulative-logit cutpoints)" begin
    Random.seed!(20260618)
    p, K, n = 6, 2, 400
    C = 4                                   # 3 ordered cutpoints, no intercept
    Λ_true = randn(p, K) .* 0.4
    for i in 1:K, k in 1:K
        i < k && (Λ_true[i, k] = 0.0)
    end
    τ_true = [-1.3, 0.0, 1.3]
    Z = randn(K, n)
    M = Λ_true * Z                          # η_{t,s} = (Λ z_s)_t
    _ordF(x) = 1.0 / (1.0 + exp(-x))
    function _draw(η, τ, u)                 # inverse-CDF ordinal sample
        for c in 1:length(τ)
            u <= _ordF(τ[c] - η) && return c
        end
        return length(τ) + 1
    end
    Y = [_draw(M[t, s], τ_true, rand()) for t in 1:p, s in 1:n]

    fit = GLLVM.fit_ordinal_gllvm(Y; K = K)
    @test fit.converged
    @test fit.C == C

    rr = GLLVM.rr_theta_len(p, K)
    ci = GLLVM.confint(fit; y = Y)

    # --- structure: lambdas then the C-1 cutpoints, no beta ---
    @test length(ci.term) == rr + (C - 1)
    @test ci.term[rr + 1] == "tau[1]"
    @test ci.term[end] == "tau[$(C - 1)]"
    @test ci.pd_hessian
    @test all(isfinite, ci.se)
    @test all(ci.lower .< ci.estimate .< ci.upper)
    @test ci.estimate[(rr + 1):end] ≈ fit.τ          # cutpoints on the natural scale

    # --- the Wald SEs must match a central-FD Hessian of the same NLL (oracle) ---
    nll(θ) = -GLLVM.ordinal_marginal_loglik_laplace(
        Y, GLLVM.unpack_lambda(θ[1:rr], p, K), θ[(rr + 1):(rr + C - 1)])
    θ̂ = vcat(GLLVM.pack_lambda(fit.Λ), fit.τ)
    np = length(θ̂); h = 1e-4; H = zeros(np, np)
    for i in 1:np, j in i:np
        a = copy(θ̂); a[i]+=h; a[j]+=h; b = copy(θ̂); b[i]+=h; b[j]-=h
        c = copy(θ̂); c[i]-=h; c[j]+=h; d = copy(θ̂); d[i]-=h; d[j]-=h
        H[i, j] = (nll(a)-nll(b)-nll(c)+nll(d))/(4h*h); H[j, i] = H[i, j]
    end
    se_fd = sqrt.(diag(inv(Symmetric((H .+ H') ./ 2))))
    @test maximum(abs.(ci.se .- se_fd)) < 5e-3

    # --- intercept-free: cutpoint Wald CIs cover the truth at roughly nominal rate ---
    cover = count(ci.lower[(rr + 1):end] .<= τ_true .<= ci.upper[(rr + 1):end])
    @test cover >= (C - 1) - 1

    # --- parm selection: just the cutpoints ---
    ci_t = GLLVM.confint(fit; y = Y, parm = "tau")
    @test length(ci_t.term) == C - 1
    @test all(startswith.(ci_t.term, "tau"))
end

@testset "Gamma Wald CIs (shape on log scale)" begin
    Random.seed!(20260617)
    p, K, n = 5, 2, 300
    Λ_true = randn(p, K) .* 0.3
    for i in 1:K, k in 1:K
        i < k && (Λ_true[i, k] = 0.0)
    end
    β_true = randn(p) .* 0.2 .+ 0.5
    α_true = 8.0
    ηs = randn(K, n)
    μ  = exp.(clamp.(Λ_true * ηs .+ β_true, -30, 30))
    Y  = [rand(Gamma(α_true, μ[t, s] / α_true)) for t in 1:p, s in 1:n]   # mean μ

    fit = GLLVM.fit_gamma_gllvm(Y; K = K)
    @test fit.converged
    rr = GLLVM.rr_theta_len(p, K)
    ci = GLLVM.confint(fit; y = Y)
    @test length(ci.term) == p + rr + 1
    @test ci.term[end] == "alpha"
    @test ci.pd_hessian
    @test all(ci.lower .< ci.estimate .< ci.upper)
    @test ci.estimate[end] ≈ fit.α
    @test ci.lower[end] > 0

    nll(θ) = -GLLVM.gamma_marginal_loglik_laplace(
        Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        exp(θ[p + rr + 1]); link = fit.link)
    θ̂ = vcat(fit.β, GLLVM.pack_lambda(fit.Λ), log(fit.α))
    np = length(θ̂); h = 1e-4; H = zeros(np, np)
    for i in 1:np, j in i:np
        a = copy(θ̂); a[i]+=h; a[j]+=h; b = copy(θ̂); b[i]+=h; b[j]-=h
        c = copy(θ̂); c[i]-=h; c[j]+=h; d = copy(θ̂); d[i]-=h; d[j]-=h
        H[i, j] = (nll(a)-nll(b)-nll(c)+nll(d))/(4h*h); H[j, i] = H[i, j]
    end
    se_fd = sqrt.(diag(inv(Symmetric((H .+ H') ./ 2))))
    @test maximum(abs.(ci.se .- se_fd)) < 5e-3
end
