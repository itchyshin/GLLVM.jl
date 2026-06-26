# Per-site Laplace marginal log-likelihood for the Binomial GLLVM.
#
# Model (site s, p binary/binomial responses):
#     y_{ts} ~ Binomial(n_{ts}, μ_{ts}),  μ_{ts} = linkinv(link, η_{ts}),
#     η_{ts} = β_t + (Λ z_s)_t,           z_s ~ N(0, I_K).
#
# Predictor-informed latent-score mean (C1 / Design 73):
#     z_total,s = X_lv[s, :] * alpha_lv + z_s,  z_s ~ N(0, I_K),
#     η_ts = β_t + (Λ z_total,s)_t.
#
# Conditional on the zero-mean innovation z_s this is the same Laplace problem
# with a parameter-dependent offset `Λ * alpha_lv' * X_lv[s, :]`.
#
# The marginal  ∫ p(y_s | z) N(z; 0, I) dz  is non-conjugate, so it is computed
# by a Laplace approximation: find the conditional mode ẑ_s by Fisher scoring,
# then
#     log p(y_s) ≈ ℓ(ẑ_s) − ½ ẑ_s'ẑ_s − ½ logdet(Λ' W Λ + I_K),
# where ℓ is the binomial log-likelihood and W are the Fisher working weights at
# the mode. This is the smallest correctness unit of the Binomial family (#7);
# the fit driver and gradient build on it. See the design note in the after-task
# log. Inner mode-finder uses the Fisher information (expected Hessian), so
# Λ' W Λ + I_K is always SPD.

# Binomial family pieces for the generic Laplace core (src/families/laplace.jl).
# y_t ~ Binomial(n_t, μ_t); E[y]=nμ, Var=nμ(1−μ). Score/weight wrt η below; with
# the logit link (me = μ(1−μ)) the weight reduces to the canonical nμ(1−μ).
_clamp_mu(::Binomial, μ) = clamp(μ, 1e-12, 1 - 1e-12)
_glm_score(::Binomial, μ, n, me, y) = (y - n * μ) / (μ * (one(μ) - μ)) * me
_glm_weight(::Binomial, μ, n, me)   = n * me^2 / (μ * (one(μ) - μ))
_glm_logpdf(::Binomial, μ, n, y)    = logpdf(Binomial(Int(n), μ), Int(y))

# Binomial-default convenience methods (back-compat: family ⇒ Binomial()), used
# by getLV(::BinomialFit) and the Binomial tests.
_laplace_mode(y::AbstractVector, n::AbstractVector, Λ::AbstractMatrix,
        β::AbstractVector, link::Link; kwargs...) =
    _laplace_mode(Binomial(), y, n, Λ, β, link; kwargs...)

laplace_loglik_site(y::AbstractVector, n::AbstractVector, Λ::AbstractMatrix,
        β::AbstractVector, link::Link; kwargs...) =
    laplace_loglik_site(Binomial(), y, n, Λ, β, link; kwargs...)

"""
    binomial_marginal_loglik_laplace(Y, N, Λ, β, link; kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites of a Binomial GLLVM — a thin
wrapper over the family-generic `marginal_loglik_laplace` with `Binomial()`.
`Y`, `N` are p×n response and trial-count matrices; `Λ` p×K; `β` length-p.
"""
binomial_marginal_loglik_laplace(Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, link::Link; kwargs...) =
    marginal_loglik_laplace(Binomial(), Y, N, Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver (Binomial slice 4).
# ---------------------------------------------------------------------------

"""
    BinomialFit

Result of [`fit_binomial_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the `link`, the maximised Laplace `loglik`, the optimiser `converged`
flag, and `iterations`. Fits using `X_lv` additionally retain `alpha_lv`, the
raw latent-axis coefficients for the predictor-informed score mean; use
[`extract_lv_effects`](@ref) for the rotation-stable trait-scale product
`Λ * alpha_lv'`.
"""
struct BinomialFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
    alpha_lv::Union{Nothing, Matrix{Float64}}
    theta_packed::Vector{Float64}
end

BinomialFit(β::Vector{Float64}, Λ::Matrix{Float64}, link::Link,
            loglik::Float64, converged::Bool, iterations::Int) =
    BinomialFit(β, Λ, link, loglik, converged, iterations, nothing, Float64[])

function Base.show(io::IO, f::BinomialFit)
    p, K = size(f.Λ)
    print(io, "BinomialFit(p=", p, ", K=", K, ", link=", nameof(typeof(f.link)),
          f.alpha_lv === nothing ? "" : ", X_lv=true",
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    binomial_lv_nll_packed(params, Y, N, p, K, link; X_lv, q_lv, kwargs...) -> Real

Negative Laplace log-likelihood for the predictor-informed latent-score
binomial model. Parameter layout:

- `params[1:p]` = per-trait intercepts `β`;
- next `q_lv * K` entries = `alpha_lv`, reshaped as `q_lv × K`;
- remaining entries = packed reduced-rank loadings `Λ`.

The conditional latent variable is the zero-mean innovation. The predictor mean
enters the Laplace core as the parameter-dependent offset
`Λ * alpha_lv' * X_lv[s, :]`.
"""
function binomial_lv_nll_packed(params::AbstractVector, Y::AbstractMatrix,
        N::AbstractMatrix, p::Integer, K::Integer, link::Link;
        X_lv::AbstractMatrix, q_lv::Integer,
        mask = nothing, offset = nothing,
        maxiter::Integer = 100, tol::Real = 1e-9)
    size(Y, 1) == p ||
        throw(ArgumentError("Y first dim ($(size(Y, 1))) must equal p ($p)"))
    n = size(Y, 2)
    size(N) == (p, n) || throw(DimensionMismatch("N must be $(p)×$(n)"))
    size(X_lv, 1) == n ||
        throw(ArgumentError("X_lv first dim ($(size(X_lv, 1))) must equal n_sites ($n)"))
    size(X_lv, 2) == q_lv ||
        throw(ArgumentError("X_lv second dim ($(size(X_lv, 2))) must equal q_lv ($q_lv)"))
    q_lv > 0 || throw(ArgumentError("q_lv must be positive"))

    rr = rr_theta_len(p, K)
    n_expected = p + q_lv * K + rr
    length(params) == n_expected || throw(ArgumentError(
        "params length ($(length(params))) must equal $n_expected " *
        "(p=$p + alpha_lv=$(q_lv * K) + rr=$rr)"))

    cursor = 0
    β = @view params[(cursor + 1):(cursor + p)]
    cursor += p
    alpha_vec = @view params[(cursor + 1):(cursor + q_lv * K)]
    alpha_lv = reshape(alpha_vec, q_lv, K)
    cursor += q_lv * K
    θ_rr = @view params[(cursor + 1):(cursor + rr)]
    Λ = unpack_lambda(θ_rr, p, K)

    lv_offset = _lv_mean_eta(Λ, X_lv, alpha_lv)
    off = offset === nothing ? lv_offset : offset .+ lv_offset
    return -binomial_marginal_loglik_laplace(Y, N, Λ, β, link;
                                             mask = mask, offset = off,
                                             maxiter = maxiter, tol = tol)
end

"""
    fit_binomial_gllvm(Y; K, link=LogitLink(), N=nothing, X_lv=nothing, …) -> BinomialFit

Fit a Binomial GLLVM by L-BFGS on the Laplace marginal log-likelihood
(`binomial_marginal_loglik_laplace`). `Y` is a p×n integer response
matrix (responses × sites); `N` the matching trial counts (default all-ones,
i.e. Bernoulli / binary). `K` is the latent dimension. Optimises the intercepts
`β` and loadings `Λ`.

`X_lv` (n×q_lv) activates the predictor-informed latent-score mean
`z_total[s, :] = X_lv[s, :] * alpha_lv + z_s`; this point-estimate route
estimates `alpha_lv` jointly with `β` and `Λ`. `LogitLink`, `ProbitLink`, and
`CLogLogLink` are all supported through the same Laplace core. Confidence
interval engines for this expanded parameter layout remain a separate gate.

The default analytic Laplace gradient is used on the logit no-offset path, with
an internal finite-difference fallback; non-logit links and offset fits use
finite differences. `X_lv` fits also use finite differences because the offset
depends jointly on `Λ` and `alpha_lv`. Warm start: empirical link-scale
intercepts + an SVD (PPCA-style) loadings init; `alpha_lv` starts from a
least-squares regression of the initial latent scores on `X_lv`.
"""
function fit_binomial_gllvm(Y::AbstractMatrix; K::Integer,
        link::Link = LogitLink(),
        N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing, mask = nothing,
        offset = nothing, gradient::Symbol = :analytic,
        β_init = nothing, Λ_init = nothing,
        X_lv::Union{Nothing, AbstractMatrix} = nothing,
        alpha_lv_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    K >= 0 || throw(ArgumentError("K must be non-negative for fit_binomial_gllvm"))
    Nm = N === nothing ? fill(1, p, n) : N
    size(Nm) == (p, n) || throw(DimensionMismatch("N must be $(p)×$(n)"))
    rr = rr_theta_len(p, K)

    q_lv = 0
    X_lv_fit = nothing
    if X_lv !== nothing
        K > 0 || throw(ArgumentError("X_lv requires a positive latent dimension K"))
        size(X_lv, 1) == n ||
            throw(ArgumentError("X_lv first dim ($(size(X_lv, 1))) must equal n_sites ($n)"))
        q_lv = size(X_lv, 2)
        q_lv > 0 || throw(ArgumentError("X_lv must have at least one predictor column"))
        X_lv_fit = Matrix{Float64}(X_lv)
        if alpha_lv_init !== nothing
            size(alpha_lv_init, 1) == q_lv ||
                throw(ArgumentError(
                    "alpha_lv_init first dim ($(size(alpha_lv_init, 1))) must equal size(X_lv, 2) ($q_lv)"))
            size(alpha_lv_init, 2) == K ||
                throw(ArgumentError(
                    "alpha_lv_init second dim ($(size(alpha_lv_init, 2))) must equal K ($K)"))
        end
    elseif alpha_lv_init !== nothing
        throw(ArgumentError("alpha_lv_init requires X_lv"))
    end

    msk = _resolve_obs_mask(mask, Y)                  # NA handling
    Yc  = Integer.(_sanitize_missing(Y, 0))

    # warm start: empirical link-scale intercepts + SVD (PPCA-like) loadings
    Zemp = [linkfun(link, clamp((Yc[t, i] + 0.5) / (Nm[t, i] + 1), 1e-4, 1 - 1e-4))
            for t in 1:p, i in 1:n]
    offset === nothing || (Zemp .-= offset)           # offset (η = β + offset + Λz)
    _mask_warmstart!(Zemp, msk)
    β0 = β_init === nothing ? vec(sum(Zemp; dims = 2)) ./ n : collect(float.(β_init))
    Zc = Zemp .- β0
    Λ0 = if Λ_init === nothing
        F = svd(Zc)
        kk = min(K, length(F.S))
        L = zeros(p, K)
        @inbounds for j in 1:kk
            L[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
        end
        L
    else
        collect(float.(Λ_init))
    end

    alpha0 = if X_lv_fit === nothing
        nothing
    elseif alpha_lv_init === nothing
        F = svd(Zc)
        kk = min(K, length(F.S))
        scores0 = zeros(Float64, n, K)
        @inbounds for j in 1:kk
            scores0[:, j] = sqrt(n) .* F.V[:, j]
        end
        X_lv_fit \ scores0
    else
        Matrix{Float64}(alpha_lv_init)
    end

    θ0 = vcat(β0, pack_lambda(Λ0))
    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        v = try
            -binomial_marginal_loglik_laplace(Yc, Nm, Λ, β, link; mask = msk, offset = offset,
                                              maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    opts = Optim.Options(g_tol = g_tol, iterations = iterations)
    res = if X_lv_fit !== nothing
        θ0_lv = vcat(β0, vec(alpha0), pack_lambda(Λ0))
        negll_lv = θ -> begin
            v = try
                binomial_lv_nll_packed(θ, Yc, Nm, p, K, link;
                                       X_lv = X_lv_fit, q_lv = q_lv,
                                       mask = msk, offset = offset,
                                       maxiter = newton_maxiter, tol = newton_tol)
            catch
                return 1e12
            end
            return isfinite(v) ? v : 1e12
        end
        Optim.optimize(negll_lv, θ0_lv, ls, opts; autodiff = :finite)
    elseif gradient === :analytic && offset === nothing && link isa LogitLink
        ag = θ -> begin
            β = θ[1:p]; Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
            try -binomial_laplace_grad(Yc, Nm, Λ, β; mask = msk) catch; nothing end
        end
        _optimize_with_analytic(negll, ag, θ0, ls, opts)
    else
        Optim.optimize(negll, θ0, ls, opts; autodiff = :finite)
    end
    θ̂ = Optim.minimizer(res)
    if X_lv_fit !== nothing
        cursor = 0
        β̂ = collect(θ̂[(cursor + 1):(cursor + p)])
        cursor += p
        alpha_hat = reshape(collect(θ̂[(cursor + 1):(cursor + q_lv * K)]), q_lv, K)
        cursor += q_lv * K
        Λ̂ = unpack_lambda(@view(θ̂[(cursor + 1):(cursor + rr)]), p, K)
        return BinomialFit(β̂, Λ̂, link, -Optim.minimum(res),
                           Optim.converged(res), Optim.iterations(res),
                           alpha_hat, collect(Float64, θ̂))
    else
        β̂ = θ̂[1:p]
        Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
        return BinomialFit(β̂, Λ̂, link, -Optim.minimum(res),
                           Optim.converged(res), Optim.iterations(res))
    end
end
