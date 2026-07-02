# Internal S1 proof for the phylo x Poisson x predictor-informed LV target.
#
# Model:
#   epsilon_s ~ N(0, I_K)
#   u         ~ N(0, sigma_phy^2 * Q_cond^{-1})
#   eta[t,s] = beta[t] + Lambda[t,:]' * (X_lv[s,:] * alpha_lv + epsilon_s) +
#              u[leaf_pos[t]]
#   Y[t,s]   ~ Poisson(exp(eta[t,s]))
#
# This is deliberately not exported. It is a reduction-tested likelihood surface
# for the first structural-source non-Gaussian LV canary, not R grammar support.

function _phylo_poisson_xlv_validate(Y::AbstractMatrix, beta::AbstractVector,
        Lambda::AbstractMatrix, alpha_lv::AbstractMatrix, phy::AugmentedPhy,
        X_lv::AbstractMatrix, link::Link)
    link isa LogLink ||
        throw(ArgumentError("phylo Poisson X_lv S1 is currently log-link only"))
    p, n = size(Y)
    p == phy.n_leaves ||
        throw(ArgumentError("size(Y,1)=$p must equal phy.n_leaves=$(phy.n_leaves)"))
    length(beta) == p ||
        throw(ArgumentError("length(beta)=$(length(beta)) must equal size(Y,1)=$p"))
    size(Lambda, 1) == p ||
        throw(ArgumentError("Lambda rows ($(size(Lambda, 1))) must equal size(Y,1)=$p"))
    K = size(Lambda, 2)
    K > 0 || throw(ArgumentError("Lambda must have at least one latent column"))
    size(X_lv, 1) == n ||
        throw(ArgumentError("X_lv rows ($(size(X_lv, 1))) must equal size(Y,2)=$n"))
    size(X_lv, 2) == size(alpha_lv, 1) ||
        throw(ArgumentError(
            "X_lv columns ($(size(X_lv, 2))) must equal alpha_lv rows ($(size(alpha_lv, 1)))"))
    size(alpha_lv, 2) == K ||
        throw(ArgumentError("alpha_lv columns ($(size(alpha_lv, 2))) must equal Lambda columns ($K)"))
    return p, n, K
end

function _phylo_poisson_xlv_logpost(Y, beta, Lambda, mean_eta, Q, leaf_pos, eps, u)
    p, n = size(Y)
    K = size(Lambda, 2)
    q = -0.5 * sum(abs2, eps) - 0.5 * dot(u, Q * u)
    @inbounds for s in 1:n, t in 1:p
        eta_ts = beta[t] + mean_eta[t, s] + u[leaf_pos[t]]
        for k in 1:K
            eta_ts += Lambda[t, k] * eps[s, k]
        end
        mu_ts = exp(_clamp_eta(eta_ts))
        q += _glm_logpdf(Poisson(), mu_ts, 1, Y[t, s])
    end
    return q
end

function _phylo_poisson_xlv_grad_hessian(Y, beta, Lambda, mean_eta, Q, leaf_pos, eps, u)
    p, n = size(Y)
    K = size(Lambda, 2)
    n_z = n * K
    n_block = length(u)
    m = n_z + n_block
    grad = zeros(Float64, m)
    H = zeros(Float64, m, m)

    @inbounds for s in 1:n
        for k in 1:K
            idx = (s - 1) * K + k
            grad[idx] -= eps[s, k]
            H[idx, idx] += 1.0
        end
    end
    @views begin
        grad[(n_z + 1):m] .-= Q * u
        H[(n_z + 1):m, (n_z + 1):m] .+= Q
    end

    @inbounds for s in 1:n, t in 1:p
        eta_ts = beta[t] + mean_eta[t, s] + u[leaf_pos[t]]
        for k in 1:K
            eta_ts += Lambda[t, k] * eps[s, k]
        end
        mu_ts = exp(_clamp_eta(eta_ts))
        score_ts = Y[t, s] - mu_ts
        weight_ts = mu_ts
        uidx = n_z + leaf_pos[t]

        grad[uidx] += score_ts
        H[uidx, uidx] += weight_ts
        for k in 1:K
            zidx_k = (s - 1) * K + k
            ltk = Lambda[t, k]
            grad[zidx_k] += ltk * score_ts
            cross = weight_ts * ltk
            H[zidx_k, uidx] += cross
            H[uidx, zidx_k] += cross
            for j in 1:K
                zidx_j = (s - 1) * K + j
                H[zidx_k, zidx_j] += weight_ts * ltk * Lambda[t, j]
            end
        end
    end
    return grad, H
end

function _phylo_poisson_xlv_mode(Y, beta, Lambda, mean_eta, Q, leaf_pos;
        maxiter::Integer = 80, tol::Real = 1e-9)
    n = size(Y, 2)
    K = size(Lambda, 2)
    eps = zeros(Float64, n, K)
    u = zeros(Float64, size(Q, 1))
    local H

    for _ in 1:maxiter
        grad, H = _phylo_poisson_xlv_grad_hessian(Y, beta, Lambda, mean_eta, Q,
                                                  leaf_pos, eps, u)
        cholH = try
            cholesky(Symmetric(H))
        catch
            return nothing, nothing, nothing
        end
        delta = cholH \ grad
        all(isfinite, delta) || return nothing, nothing, nothing

        q0 = _phylo_poisson_xlv_logpost(Y, beta, Lambda, mean_eta, Q, leaf_pos,
                                        eps, u)
        accepted = false
        step = 1.0
        n_z = n * K
        max_delta = maximum(abs, delta)
        for _half in 1:30
            eps_trial = copy(eps)
            u_trial = copy(u)
            @inbounds for s in 1:n, k in 1:K
                eps_trial[s, k] += step * delta[(s - 1) * K + k]
            end
            @inbounds for j in eachindex(u_trial)
                u_trial[j] += step * delta[n_z + j]
            end
            q1 = _phylo_poisson_xlv_logpost(Y, beta, Lambda, mean_eta, Q,
                                            leaf_pos, eps_trial, u_trial)
            if isfinite(q1) && q1 >= q0
                eps = eps_trial
                u = u_trial
                accepted = true
                break
            end
            step *= 0.5
        end
        accepted || return nothing, nothing, nothing
        step * max_delta < tol && break
    end

    _, H = _phylo_poisson_xlv_grad_hessian(Y, beta, Lambda, mean_eta, Q,
                                           leaf_pos, eps, u)
    cholH = try
        cholesky(Symmetric(H))
    catch
        return nothing, nothing, nothing
    end
    return eps, u, cholH
end

"""
    _phylo_poisson_xlv_marginal_loglik(Y, beta, Lambda, alpha_lv, sigma2_phy, phy, X_lv; kwargs...)

Internal Laplace marginal log-likelihood for the first phylo x Poisson x
predictor-informed latent-score S1 proof. The only admitted link is `LogLink`.
The integrated variables are the site-score innovations and the augmented-tree
phylogenetic random intercept. This function is intentionally private and
reduction-tested before any fitter, bridge route, or R grammar is exposed.
"""
function _phylo_poisson_xlv_marginal_loglik(Y::AbstractMatrix,
        beta::AbstractVector, Lambda::AbstractMatrix, alpha_lv::AbstractMatrix,
        sigma2_phy::Real, phy::AugmentedPhy, X_lv::AbstractMatrix;
        link::Link = LogLink(), maxiter::Integer = 80, tol::Real = 1e-9)
    _phylo_poisson_xlv_validate(Y, beta, Lambda, alpha_lv, phy, X_lv, link)
    sigma2_phy > 0 || return -Inf

    Yc = Matrix{Float64}(Y)
    beta_c = Vector{Float64}(beta)
    Lambda_c = Matrix{Float64}(Lambda)
    alpha_c = Matrix{Float64}(alpha_lv)
    X_c = Matrix{Float64}(X_lv)
    mean_eta = _lv_mean_eta(Lambda_c, X_c, alpha_c)

    Q_cond, leaf_pos = _phylo_qcond(phy)
    Q = Matrix(Q_cond ./ float(sigma2_phy))
    cholQ = try
        cholesky(Symmetric(Q))
    catch
        return -Inf
    end

    eps_hat, u_hat, cholH = _phylo_poisson_xlv_mode(Yc, beta_c, Lambda_c,
                                                    mean_eta, Q, leaf_pos;
                                                    maxiter = maxiter, tol = tol)
    eps_hat === nothing && return -Inf
    q = _phylo_poisson_xlv_logpost(Yc, beta_c, Lambda_c, mean_eta, Q, leaf_pos,
                                   eps_hat, u_hat)
    return q + 0.5 * logdet(cholQ) - 0.5 * logdet(cholH)
end
