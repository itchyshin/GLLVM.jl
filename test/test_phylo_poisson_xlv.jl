using GLLVM, Test, Random, LinearAlgebra
using Distributions: Poisson

function _dense_leaf_phylo_poisson_xlv_loglik(Y, beta, Lambda, alpha_lv, sigma2_phy,
        phy, X_lv; maxiter = 120, tol = 1e-10)
    p, n = size(Y)
    K = size(Lambda, 2)
    keep = filter(i -> i != phy.root_index, 1:phy.n_total)
    Qc = Matrix(phy.Q_topology[keep, keep])
    leaf_pos = [(lp = phy.leaf_indices[t]; phy.root_index < lp ? lp - 1 : lp) for t in 1:p]
    Sigma_a = sigma2_phy .* (inv(Qc)[leaf_pos, leaf_pos])
    Pa = inv(Sigma_a)
    mean_eta = GLLVM._lv_mean_eta(Lambda, X_lv, alpha_lv)

    eps = zeros(n, K)
    a = zeros(p)
    n_z = n * K
    local H
    for _ in 1:maxiter
        grad = zeros(n_z + p)
        H = zeros(n_z + p, n_z + p)
        @inbounds for s in 1:n
            for k in 1:K
                idx = (s - 1) * K + k
                grad[idx] -= eps[s, k]
                H[idx, idx] += 1.0
            end
        end
        @views begin
            grad[(n_z + 1):end] .-= Pa * a
            H[(n_z + 1):end, (n_z + 1):end] .+= Pa
        end

        @inbounds for s in 1:n, t in 1:p
            eta_ts = beta[t] + mean_eta[t, s] + a[t]
            for k in 1:K
                eta_ts += Lambda[t, k] * eps[s, k]
            end
            mu_ts = exp(GLLVM._clamp_eta(eta_ts))
            score_ts = Y[t, s] - mu_ts
            weight_ts = mu_ts
            aidx = n_z + t
            grad[aidx] += score_ts
            H[aidx, aidx] += weight_ts
            for k in 1:K
                zidx_k = (s - 1) * K + k
                ltk = Lambda[t, k]
                grad[zidx_k] += ltk * score_ts
                cross = weight_ts * ltk
                H[zidx_k, aidx] += cross
                H[aidx, zidx_k] += cross
                for j in 1:K
                    zidx_j = (s - 1) * K + j
                    H[zidx_k, zidx_j] += weight_ts * ltk * Lambda[t, j]
                end
            end
        end
        delta = cholesky(Symmetric(H)) \ grad
        @inbounds for s in 1:n, k in 1:K
            eps[s, k] += delta[(s - 1) * K + k]
        end
        @inbounds for t in 1:p
            a[t] += delta[n_z + t]
        end
        maximum(abs, delta) < tol && break
    end

    q = -0.5 * sum(abs2, eps) - 0.5 * dot(a, Pa * a)
    @inbounds for s in 1:n, t in 1:p
        eta_ts = beta[t] + mean_eta[t, s] + a[t]
        for k in 1:K
            eta_ts += Lambda[t, k] * eps[s, k]
        end
        mu_ts = exp(GLLVM._clamp_eta(eta_ts))
        q += GLLVM._glm_logpdf(Poisson(), mu_ts, 1, Y[t, s])
    end
    return q + 0.5 * logdet(cholesky(Symmetric(Pa))) -
           0.5 * logdet(cholesky(Symmetric(H)))
end

@testset "Phylo x Poisson predictor-informed LV S1 likelihood" begin
    Random.seed!(724)
    phy = GLLVM.augmented_phy("(((A:0.3,B:0.3):0.2,(C:0.3,D:0.3):0.2):0.2,(E:0.4,F:0.4):0.2);")
    p = phy.n_leaves
    n = 7
    K = 1
    q_lv = 1
    beta = 0.15 .* randn(p)
    Lambda = reshape(range(0.15, 0.55; length = p), p, K)
    alpha_lv = reshape([0.35], q_lv, K)
    X_lv = reshape(collect(range(-1.2, 1.2; length = n)), n, q_lv)
    Y = rand(0:5, p, n)

    ll_joint0 = GLLVM._phylo_poisson_xlv_marginal_loglik(
        Y, beta, Lambda, alpha_lv, 1e-8, phy, X_lv;
        maxiter = 120, tol = 1e-10)
    theta_plain = vcat(beta, vec(alpha_lv), GLLVM.pack_lambda(Lambda))
    ll_plain = -GLLVM.poisson_lv_nll_packed(
        theta_plain, Y, p, K, LogLink(); X_lv = X_lv, q_lv = q_lv,
        maxiter = 120, tol = 1e-10)
    @test isapprox(ll_joint0, ll_plain; atol = 2e-3)

    sigma2 = 0.45
    Lambda0 = zeros(p, K)
    ll_phylo_only = GLLVM._phylo_poisson_xlv_marginal_loglik(
        Y, beta, Lambda0, alpha_lv, sigma2, phy, X_lv;
        maxiter = 120, tol = 1e-10)
    ll_phylo_glm = phylo_glm_marginal_loglik(
        Poisson(), Y, ones(Int, p, n), beta, sigma2, phy;
        link = LogLink(), maxiter = 120, tol = 1e-10)
    @test isapprox(ll_phylo_only, ll_phylo_glm; atol = 1e-7)

    ll_sparse_aug = GLLVM._phylo_poisson_xlv_marginal_loglik(
        Y, beta, Lambda, alpha_lv, sigma2, phy, X_lv;
        maxiter = 120, tol = 1e-10)
    ll_dense_leaf = _dense_leaf_phylo_poisson_xlv_loglik(
        Y, beta, Lambda, alpha_lv, sigma2, phy, X_lv)
    @test isapprox(ll_sparse_aug, ll_dense_leaf; atol = 1e-6)
    @test isfinite(ll_sparse_aug)

    @test GLLVM._phylo_poisson_xlv_marginal_loglik(
        Y, beta, Lambda, alpha_lv, 0.0, phy, X_lv) == -Inf
    @test_throws ArgumentError GLLVM._phylo_poisson_xlv_marginal_loglik(
        Y[1:5, :], beta, Lambda, alpha_lv, sigma2, phy, X_lv)
    @test_throws ArgumentError GLLVM._phylo_poisson_xlv_marginal_loglik(
        Y, beta, Lambda, alpha_lv, sigma2, phy, X_lv[1:(end - 1), :])
    @test_throws ArgumentError GLLVM._phylo_poisson_xlv_marginal_loglik(
        Y, beta, Lambda, ones(2, K), sigma2, phy, X_lv)
    @test_throws ArgumentError GLLVM._phylo_poisson_xlv_marginal_loglik(
        Y, beta, Lambda, alpha_lv, sigma2, phy, X_lv; link = IdentityLink())
end

@testset "Phylo x Poisson B_eta_realized selected-entry canary" begin
    Random.seed!(725)
    phy = GLLVM.augmented_phy("(((A:0.3,B:0.3):0.2,(C:0.3,D:0.3):0.2):0.2,(E:0.4,F:0.4):0.2);")
    p = phy.n_leaves
    n = 28
    K = 1
    q_lv = 1
    X_lv = reshape(collect(range(-1.0, 1.0; length = n)), n, q_lv)
    beta = log.([8.0, 7.5, 7.0, 6.5, 7.2, 6.8])
    Lambda = reshape([0.22, -0.18, 0.20, -0.16, 0.14, -0.12], p, K)
    alpha_lv = reshape([0.45], q_lv, K)
    sigma2 = 0.35
    epsilon = 0.08 .* randn(n, K)
    Z_truth = X_lv * alpha_lv + epsilon
    eta = beta .+ Lambda * transpose(Z_truth)
    Y = max.(0, round.(Int, exp.(eta)))

    # Deterministic positive-control counts keep the canary focused on
    # selected-entry LR routing. This is not a source-variance recovery test.
    fit = GLLVM._fit_phylo_poisson_xlv(
        Y, phy; K = K, X_lv = X_lv,
        beta_init = beta, Lambda_init = Lambda, alpha_lv_init = alpha_lv,
        sigma2_phy_init = sigma2,
        iterations = 250, g_tol = 1e-5,
        newton_maxiter = 120, newton_tol = 1e-10)
    @test fit.converged
    @test isfinite(fit.loglik)
    @test fit.sigma2_phy > 0

    eta_target = vec(GLLVM._eta_realized_lv_effects(X_lv, Z_truth, Lambda))
    prof = GLLVM._phylo_poisson_xlv_profile_eta_realized(
        fit, Y, phy, X_lv, [1], eta_target;
        level = 0.95, profile_iterations = 700,
        newton_maxiter = 120, newton_tol = 1e-10)
    @test prof.method == :profile_eta_realized
    @test prof.term == ["B_eta_realized[1,1]"]
    @test all(isnan, prof.se)
    @test prof.endpoint_status == [:profile]
    @test all(isfinite, prof.lower)
    @test all(isfinite, prof.upper)
    @test prof.lower[1] < prof.estimate[1] < prof.upper[1]
    @test prof.lower[1] <= prof.target[1] <= prof.upper[1]
    @test isfinite(prof.lr_deviance[1])
    @test prof.lr_deviance[1] <= prof.lr_cutoff[1]
    @test prof.constrained_error[1] < 1e-3
    @test prof.covered == [true]
    @test prof.pd_hessian

    @test_throws ArgumentError GLLVM._phylo_poisson_xlv_profile_eta_realized(
        fit, Y, phy, X_lv, Int[], eta_target)
    @test_throws ArgumentError GLLVM._phylo_poisson_xlv_profile_eta_realized(
        fit, Y, phy, X_lv, [1, 1], eta_target)
    @test_throws ArgumentError GLLVM._phylo_poisson_xlv_profile_eta_realized(
        fit, Y, phy, X_lv, [p + 1], eta_target)
    @test_throws ArgumentError GLLVM._phylo_poisson_xlv_profile_eta_realized(
        fit, Y, phy, X_lv, [1], eta_target[1:(end - 1)])
    @test_throws ArgumentError GLLVM._phylo_poisson_xlv_profile_eta_realized(
        fit, Y, phy, X_lv, [1], eta_target; profile_iterations = 0)
    @test_throws ArgumentError GLLVM._phylo_poisson_xlv_profile_eta_realized(
        fit, Y, phy, X_lv, [1], eta_target; endpoint_step = -0.1)
end
