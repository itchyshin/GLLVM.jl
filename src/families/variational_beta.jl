# Gaussian-variational (VA / ELBO) marginal for the Beta GLLVM with logit link.
# The non-conjugate companion to families/beta.jl's Laplace marginal. The
# per-trait expectation E_q[log p(y_t | η_t, φ)] is computed by 1-D Gauss–Hermite
# (GH) quadrature, exactly mirroring the Negative-Binomial VA path.
#
# Model. q(z_s) = N(m_s, diag(v_s)), prior N(0, I_K). Under q the linear predictor
# is Gaussian: η_ts ~ N(μη_t, σ²_t) with
#   μη_t = β_t + (Λ m_s)_t,   σ²_t = Σ_k Λ_tk² v_sk.
# Per site,
#   ELBO_s = Σ_t E_q[log p(y_t | η_t, φ)] − KL_s,
#   KL_s   = ½ Σ_k (v_sk + m_sk² − 1 − log v_sk).
# Beta (same parameterisation as families/beta.jl), μ = logistic(η):
#   log p(y|μ,φ) = loggamma(φ) − loggamma(μφ) − loggamma((1−μ)φ)
#                  + (μφ−1)·log y + ((1−μ)φ−1)·log(1−y).
# The expectation has no closed form, so with g(η) = log p(y_t | μ=logistic(η), φ):
#   E_q[g(η)] ≈ Σ_{j=1}^G (w_j/√π)·g( _clamp_eta(μη_t + √(2σ²_t)·x_j) ),
# with (x_j, w_j) the G-point Gauss–Hermite nodes/weights (Σ w = √π). Inside g, μ
# is clamped into (1e-12, 1−1e-12) before the logs/loggammas.
#
# As Λ→0 (⇒ σ²=0) the GH rule collapses to g(μη_t)=g(β_t) and the optimal q is the
# prior (m=0, v=1, KL=0), so the ELBO reduces EXACTLY to the independent-Beta loglik.

# `_gauss_hermite(G)` is shared with the other VA families (defined in
# families/variational.jl, included first).

# Beta conditional log-density at η (μ = logistic(η)), shared form with beta.jl.
@inline function _beta_logpdf_eta(η, y, φ)
    μ = clamp(1.0 / (1.0 + exp(-η)), 1e-12, 1 - 1e-12)
    return loggamma(φ) - loggamma(μ * φ) - loggamma((1 - μ) * φ) +
           (μ * φ - 1) * log(y) + ((1 - μ) * φ - 1) * log1p(-y)
end

# Per-site Beta ELBO at variational params packed as ψ = [m (K); logv (K)].
# Returns ELBO_s = Σ_t E_q[log p(y_t|η_t,φ)] − KL_s, with E_q by GH quadrature.
function _va_site_beta_elbo(ψ::AbstractVector, y::AbstractVector,
        Λ::AbstractMatrix, Λ2::AbstractMatrix, β::AbstractVector,
        φ::Real, x::AbstractVector, w::AbstractVector)
    p, K = size(Λ)
    m  = @view ψ[1:K]
    lv = @view ψ[(K + 1):(2K)]
    v  = exp.(lv)
    σ2 = Λ2 * v
    μη = β .+ Λ * m
    G  = length(x)
    invsqrtpi = 1.0 / sqrt(pi)
    ℓ = zero(eltype(ψ))
    @inbounds for t in 1:p
        sd = sqrt(2.0 * σ2[t])
        et = zero(eltype(ψ))
        for j in 1:G
            η = _clamp_eta(μη[t] + sd * x[j])
            et += w[j] * _beta_logpdf_eta(η, y[t], φ)
        end
        ℓ += invsqrtpi * et
    end
    kl = 0.5 * sum(v .+ m .^ 2 .- 1.0 .- lv)
    return ℓ - kl
end

# Profile (m_s, v_s) for one site by jointly minimising the negative ELBO over
# [m (K); logv (K)] with L-BFGS (finite-diff gradient), from m=0, logv=0.
function _va_site_beta(y::AbstractVector, Λ::AbstractMatrix, Λ2::AbstractMatrix,
        β::AbstractVector, φ::Real, x::AbstractVector, w::AbstractVector;
        maxiter::Integer = 100, tol::Real = 1e-9)
    K = size(Λ, 2)
    negelbo(ψ) = -_va_site_beta_elbo(ψ, y, Λ, Λ2, β, φ, x, w)
    ψ0 = zeros(2K)
    res = Optim.optimize(negelbo, ψ0, Optim.LBFGS(),
                         Optim.Options(g_tol = tol, iterations = maxiter);
                         autodiff = :finite)
    return -Optim.minimum(res)
end

"""
    beta_marginal_loglik_va(Y, Λ, β, φ; maxiter=100, tol=1e-9, gh=20) -> Float64

Gaussian-variational (VA) log-marginal lower bound (ELBO) over the `n` sites
(columns) of a Beta GLLVM with logit link — `Y` the p×n matrix of proportions in
(0,1), `Λ` p×K, `β` length-p, precision `φ > 0` (mean `μ = logistic(η)`,
per-observation `Beta(μφ, (1−μ)φ)`, `Var = μ(1−μ)/(1+φ)`). The per-site variational
posterior `q(z_s)=N(m_s, diag(v_s))` is profiled out by jointly minimising the
negative ELBO over `[m; logv]`; the per-trait expectation is evaluated by `gh`-point
Gauss–Hermite quadrature. The returned value is a **lower bound** on the true
log-marginal (≤ it for any `q`); as `Λ→0` it equals the independent-Beta loglik
exactly. Companion to [`beta_marginal_loglik_laplace`](@ref).
"""
function beta_marginal_loglik_va(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, φ::Real; maxiter::Integer = 100, tol::Real = 1e-9,
        gh::Integer = 20)
    size(Λ, 1) == size(Y, 1) == length(β) ||
        throw(DimensionMismatch("Λ, Y, β must share p = $(size(Y,1)) rows"))
    φ > 0 || throw(ArgumentError("precision φ must be > 0"))
    Λ2 = Λ .^ 2
    x, w = _gauss_hermite(gh)
    acc = 0.0
    @inbounds for s in axes(Y, 2)
        acc += _va_site_beta(view(Y, :, s), Λ, Λ2, β, float(φ), x, w;
                             maxiter = maxiter, tol = tol)
    end
    return acc
end
