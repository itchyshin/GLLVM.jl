# Restricted maximum likelihood (REML) for the Gaussian GLLVM.
#
# REML estimates the variance components after integrating out the fixed effects β
# under a flat prior, removing the downward bias ML has in the variance components
# from estimating β. For y_i ~ N(X_i β, Σ_y(θ_v)):
#
#   ℓ_REML(θ_v) = ℓ_ML(β̂_GLS(θ_v), θ_v) + (q/2)·log(2π) − ½·logdet(M),
#   M  = Σ_i X_iᵀ Σ_y⁻¹ X_i  (q×q),   β̂_GLS = M⁻¹ Σ_i X_iᵀ Σ_y⁻¹ y_i.
#
# The Σ_y⁻¹ solves reuse the SAME Woodbury factorisation as the marginal
# (Σ_y = Λ_B Λ_Bᵀ + diag(d_total)); ℓ_ML at β̂ reuses `gaussian_marginal_loglik`
# UNCHANGED. AD-clean (ForwardDiff flows through the Cholesky / solves), and by the
# envelope theorem the gradient through β̂ is correct (∂ℓ_ML/∂β = 0 at β̂_GLS).
#
# Scope: the non-phylogenetic Gaussian path (Λ_B + diagonal, optional Λ_W / σ²_B /
# σ²_W) with fixed effects X. REML is for the GAUSSIAN family only (maintainer
# directive); non-Gaussian fits stay ML.

# Per-trait diagonal d_total[t] = σ_eps² + (Λ_W Λ_W')[t,t] + σ²_B[t] + σ²_W[t].
function _gaussian_d_total(p::Integer, σ²::Real, T::Type, Λ_W, σ²_B, σ²_W)
    d = fill(convert(T, σ²), p)
    if Λ_W !== nothing
        @inbounds for t in 1:p, k in 1:size(Λ_W, 2)
            d[t] += Λ_W[t, k]^2
        end
    end
    σ²_B !== nothing && (d .+= σ²_B)
    σ²_W !== nothing && (d .+= σ²_W)
    return d
end

"""
    _gaussian_gls(y, X, Λ_B, σ_eps; Λ_W, σ²_B, σ²_W) -> (β̂, logdet_M)

GLS fixed-effect estimate `β̂ = M⁻¹ Σ_i X_iᵀ Σ_y⁻¹ y_i` and `logdet(M)` with
`M = Σ_i X_iᵀ Σ_y⁻¹ X_i`, using the non-phylo Woodbury solve for `Σ_y⁻¹`. `X` is
`p×n×q`. AD-friendly.
"""
function _gaussian_gls(y::AbstractMatrix, X::AbstractArray{<:Real, 3},
        Λ_B::AbstractMatrix, σ_eps::Real;
        Λ_W = nothing, σ²_B = nothing, σ²_W = nothing)
    p, n = size(y); q = size(X, 3)
    T = promote_type(eltype(y), eltype(Λ_B), eltype(X), typeof(σ_eps^2))
    d_total = _gaussian_d_total(p, σ_eps^2, T, Λ_W, σ²_B, σ²_W)
    d_inv = one(T) ./ d_total
    DinvΛ = d_inv .* Λ_B
    cA = cholesky(Symmetric(I + Λ_B' * DinvΛ))            # K×K Woodbury core
    # Σ_y⁻¹ V = D⁻¹V − D⁻¹Λ (I + Λ'D⁻¹Λ)⁻¹ Λ'D⁻¹V
    Sinv = V -> begin
        DV = d_inv .* V
        DV .- DinvΛ * (cA \ (Λ_B' * DV))
    end
    M = zeros(T, q, q)
    vrhs = zeros(T, q)
    @inbounds for i in 1:n
        Xi = Matrix{T}(@view X[:, i, :])                 # p×q
        SXi = Sinv(Xi)                                    # p×q
        M .+= Xi' * SXi
        vrhs .+= Xi' * Sinv(Vector{T}(@view y[:, i]))     # q
    end
    cM = cholesky(Symmetric(M))
    return cM \ vrhs, logdet(cM)
end

"""
    gaussian_reml_loglik(y, X, Λ_B, σ_eps; Λ_W, σ²_B, σ²_W) -> Real

REML log-likelihood of the variance components for a Gaussian GLLVM with fixed
effects `X` (`p×n×q`): the ML marginal at the GLS `β̂` plus the restricted-likelihood
adjustment `(q/2)log(2π) − ½logdet(Σ_i X_iᵀΣ_y⁻¹X_i)`. Reuses
[`gaussian_marginal_loglik`](@ref) for the ML part. Non-phylo path only.
"""
function gaussian_reml_loglik(y::AbstractMatrix, X::AbstractArray{<:Real, 3},
        Λ_B::AbstractMatrix, σ_eps::Real;
        Λ_W = nothing, σ²_B = nothing, σ²_W = nothing)
    q = size(X, 3)
    β̂, logdet_M = _gaussian_gls(y, X, Λ_B, σ_eps; Λ_W = Λ_W, σ²_B = σ²_B, σ²_W = σ²_W)
    ll_ml = gaussian_marginal_loglik(y, Λ_B, σ_eps; X = X, β = β̂,
                                     Λ_W = Λ_W, σ²_B = σ²_B, σ²_W = σ²_W)
    T = typeof(ll_ml)
    return ll_ml + convert(T, q / 2) * log(convert(T, 2π)) - convert(T, 0.5) * logdet_M
end

# ---------------------------------------------------------------------------
# Focused REML fit driver (J1/J2-A: Λ_B + σ_eps + fixed effects X).
# ---------------------------------------------------------------------------

"""
    GaussianREMLFit

Result of [`fit_gaussian_reml`](@ref): GLS fixed effects `β` (length q), loadings `Λ`
(p×K), residual SD `σ_eps`, the maximised `reml_loglik` (REML criterion), `converged`,
`iterations`.
"""
struct GaussianREMLFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    σ_eps::Float64
    reml_loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::GaussianREMLFit)
    p, K = size(f.Λ)
    print(io, "GaussianREMLFit(p=", p, ", K=", K, ", q=", length(f.β),
          ", σ_eps=", round(f.σ_eps; sigdigits = 4),
          ", reml_loglik=", round(f.reml_loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_gaussian_reml(y, X; K, g_tol=1e-6, iterations=500) -> GaussianREMLFit

Fit a Gaussian GLLVM by REML over `[vec(Λ); log σ_eps]` (the fixed effects `β` are
profiled out via GLS each step, so they are not optimised parameters). `y` is `p×n`;
`X` the `p×n×q` fixed-effect design (include an intercept column to REML-adjust for
trait means). Warm start = OLS `β` → PPCA on the residuals. MoreThuente line search.
"""
function fit_gaussian_reml(y::AbstractMatrix, X::AbstractArray{<:Real, 3}; K::Integer,
        g_tol::Real = 1e-6, iterations::Integer = 500)
    p, n = size(y)
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1; got $K"))
    K < p || throw(ArgumentError("need K < p; got K=$K, p=$p"))
    size(X, 1) == p && size(X, 2) == n || throw(DimensionMismatch("X must be p×n×q"))
    q = size(X, 3)
    rr = rr_theta_len(p, K)

    # warm start: OLS β, PPCA on residuals
    M_ols = zeros(q, q); v_ols = zeros(q)
    @inbounds for s in 1:n
        Xs = @view X[:, s, :]
        M_ols .+= Xs' * Xs
        v_ols .+= Xs' * @view(y[:, s])
    end
    β_ols = M_ols \ v_ols
    yres = Matrix{Float64}(undef, p, n)
    @inbounds for s in 1:n, t in 1:p
        μ = 0.0
        for k in 1:q
            μ += X[t, s, k] * β_ols[k]
        end
        yres[t, s] = y[t, s] - μ
    end
    Λ0, σ0 = ppca_init(yres, K)
    θ0 = vcat(pack_lambda(Λ0), log(σ0))

    nll = θ -> -gaussian_reml_loglik(y, X, unpack_lambda(θ[1:rr], p, K), exp(θ[rr + 1]))
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.MoreThuente())
    res = Optim.optimize(nll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations); autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    Λ̂ = unpack_lambda(θ̂[1:rr], p, K)
    σ̂ = exp(θ̂[rr + 1])
    β̂, _ = _gaussian_gls(y, X, Λ̂, σ̂)
    return GaussianREMLFit(collect(Float64, β̂), Λ̂, σ̂, -Optim.minimum(res),
                           Optim.converged(res), Optim.iterations(res))
end
