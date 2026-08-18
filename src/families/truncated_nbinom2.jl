# Zero-truncated NB2 family for the generic Laplace core.
#
# Twin gllvmTMB family_id 11 (`truncated_nbinom2()`, log link; y ≥ 1 strictly):
#   ℓ = log NB2(y; μ, φ) − log(1 − p0),   μ = exp(η), p0 = (φ/(μ+φ))^φ,
#   φ = exp(log_phi_truncnb2) per trait on the twin.
# Arc1 Julia = shared scalar r ≡ φ, pack [β; pack(Λ); log r] (length p+rr+1).
# Arc1b = per-trait r_t ≡ twin log_phi_truncnb2, pack [β; pack(Λ); log r_1…log r_p]
#   (length p+rr+p); rvec = exp.(θ[tail]); fams = TruncatedNegBin2.(rvec);
#   mode via `_grouped_laplace_mode` (do not edit grouped_dispersion.jl).
# Score / weight (log link) — NB2 chain-rule factor a = r_t/(r_t+μ) is REQUIRED:
#   μ_tr = μ/(1−p0);  Var_tr = (V+μ²)/(1−p0) − μ_tr²,  V = μ + μ²/r_t;
#   s = a · (y − μ_tr);  W = a² · Var_tr.
# (Do NOT omit `a`; Sol ceiling 2026-08-15: bare (y−μ_tr) mismatches dℓ/dη.)
# Cite: gllvmTMB `src/gllvmTMB.cpp` fid==11; Identity 2026-08-15-truncated-nbinom2-identity.md.

"""
    TruncatedNegBin2(r)
    TruncatedNegBin2()

Marker for zero-truncated NB2 (support `{1,2,…}`; log link on the *untruncated*
mean `μ = exp(η)`; dispersion `r` with `Var = μ + μ²/r` ≡ twin `φ`).
`TruncatedNegBin2()` uses a warm-start default `r = 10` for `fit_gllvm` dispatch;
the fitter jointly estimates shared `r`. Distinct from Distributions.jl
`NegativeBinomial` and from the hurdle occurrence×truncated two-part family.
"""
struct TruncatedNegBin2{T<:Real}
    r::T
end
TruncatedNegBin2() = TruncatedNegBin2{Float64}(10.0)

_clamp_mu(::TruncatedNegBin2, μ) = max(μ, 1e-12)

# Truncated mean / variance helpers (untruncated μ > 0, r > 0).
function _truncnb2_mean_var(μ, r)
    p0 = (r / (r + μ))^r
    denom = 1 - p0
    μtr = μ / denom
    V = μ + μ^2 / r
    var_tr = (V + μ^2) / denom - μtr^2
    return μtr, var_tr
end

# NB2 mean-to-η factor a = r/(r+μ). Ordinary NB2 log-link score is a·(y−μ);
# truncated replaces μ with μ_tr. General link: ∂ℓ/∂η = a · (y − μ_tr)/μ · me.
function _glm_score(f::TruncatedNegBin2, μ, n, me, y)
    r = f.r
    μtr, _ = _truncnb2_mean_var(μ, r)
    a = r / (r + μ)
    return a * (y - μtr) / μ * me
end

function _glm_weight(f::TruncatedNegBin2, μ, n, me)
    r = f.r
    _, var_tr = _truncnb2_mean_var(μ, r)
    a = r / (r + μ)
    return (a * me / μ)^2 * var_tr
end

function _glm_logpdf(f::TruncatedNegBin2, μ, n, y)
    yi = Int(y)
    yi < 1 && return oftype(μ, -Inf)
    r = f.r
    p0 = (r / (r + μ))^r
    # log(1 − p0); p0 → 1 when μ → 0.
    log_nz = p0 ≥ 1 - eps(typeof(μ)) ? oftype(μ, -Inf) : log1p(-p0)
    return logpdf(NegativeBinomial(r, r / (r + μ)), yi) - log_nz
end

_laplace_mode_should_backtrack(::TruncatedNegBin2) = true

"""
    truncated_nbinom2_marginal_loglik_laplace(Y, Λ, β, r; link=LogLink(), kwargs...) -> Float64

Laplace log-marginal for a zero-truncated NB2 GLLVM with shared dispersion `r`.
`Y` must be integer counts with every observed cell `≥ 1`.
"""
truncated_nbinom2_marginal_loglik_laplace(Y::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, r::Real;
        link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(TruncatedNegBin2(float(r)), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

"""
    TruncatedNegBin2Fit

Result of [`fit_truncated_nbinom2_gllvm`](@ref): intercepts `β`, loadings `Λ`,
shared dispersion `r` (`Var = μ + μ²/r` ≡ twin `φ`), link, loglik, convergence.
"""
struct TruncatedNegBin2Fit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    r::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
    theta_packed::Vector{Float64}
end

function Base.show(io::IO, f::TruncatedNegBin2Fit)
    p, K = size(f.Λ)
    print(io, "TruncatedNegBin2Fit(p=", p, ", K=", K,
          ", r=", round(f.r; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_truncated_nbinom2_gllvm(Y; K, link=LogLink(), …) -> TruncatedNegBin2Fit

Fit a zero-truncated NB2 GLLVM by Laplace + LBFGS (finite-difference outer
gradient) over `[β; pack(Λ); log r]` (shared scalar `r`; length `p+rr+1`).
Twin per-trait `log_phi_truncnb2` is [`fit_truncated_nbinom2_gllvm_pertrait`](@ref)
(Arc1b). Twin-aligned: log link on untruncated `μ`, support `y ≥ 1`.
Throws if any observed cell is `< 1`.
"""
function fit_truncated_nbinom2_gllvm(Y::AbstractMatrix; K::Integer,
        link::Link = LogLink(), mask = nothing, offset = nothing,
        β_init = nothing, Λ_init = nothing, r_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    link isa LogLink || throw(ArgumentError(
        "fit_truncated_nbinom2_gllvm: only LogLink is supported (twin truncated_nbinom2)"))
    p, n = size(Y)
    rr = rr_theta_len(p, K)
    msk = mask === nothing ? (any(ismissing, Y) ? observed_mask(Y) : nothing) : mask
    Yc = Integer.(_sanitize_missing(Y, 1))   # placeholder 1 for masked (never enters ℓ)
    @inbounds for t in 1:p, s in 1:n
        (msk !== nothing && !msk[t, s]) && continue
        Yc[t, s] < 1 && throw(ArgumentError(
            "truncated_nbinom2 requires y ≥ 1; found y=$(Yc[t, s]) at ($t,$s)"))
    end

    Zemp = [linkfun(link, max(Float64(Yc[t, i]), 1.0)) for t in 1:p, i in 1:n]
    offset === nothing || (Zemp .-= offset)
    if msk !== nothing
        @inbounds for t in 1:p
            obs = view(msk, t, :)
            cnt = count(obs)
            rowmean = cnt > 0 ? sum(Zemp[t, i] for i in 1:n if msk[t, i]) / cnt : 0.0
            for i in 1:n
                msk[t, i] || (Zemp[t, i] = rowmean)
            end
        end
    end
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
    logr0 = r_init === nothing ? log(10.0) : log(float(r_init))

    θ0 = vcat(β0, pack_lambda(Λ0), logr0)
    N1 = ones(Int, size(Yc))
    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        r = exp(θ[p + rr + 1])
        v = try
            -marginal_loglik_laplace(TruncatedNegBin2(float(r)), Yc, N1, Λ, β, link;
                                     mask = msk, offset = offset,
                                     maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    opts = Optim.Options(g_tol = g_tol, iterations = iterations)
    res = Optim.optimize(negll, θ0, ls, opts; autodiff = :finite)
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    r̂ = exp(θ̂[p + rr + 1])
    return TruncatedNegBin2Fit(β̂, Λ̂, r̂, link, -Optim.minimum(res),
                               Optim.converged(res), Optim.iterations(res),
                               collect(Float64, θ̂))
end

# ---------------------------------------------------------------------------
# Arc1b — per-trait r_t ≡ twin log_phi_truncnb2
# pack [β; pack(Λ); log r_1 … log r_p], length p+rr+p
# ---------------------------------------------------------------------------

function _truncnb2_pertrait_loglik_site(fams::AbstractVector, y::AbstractVector,
        n::AbstractVector, Λ::AbstractMatrix, β::AbstractVector, link::Link;
        mask = nothing, offset = nothing, maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    off = offset === nothing ? false : offset
    z = _grouped_laplace_mode(fams, y, n, Λ, β, link;
                              mask = mask, offset = offset, maxiter = maxiter, tol = tol)
    η  = _clamp_eta.(β .+ off .+ Λ * z)
    μ  = _clamp_mu.(fams, linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    W  = _glm_weight.(fams, μ, n, me)
    if mask !== nothing
        W = ifelse.(mask, W, 0.0)
    end
    A = Symmetric(Λ' * (W .* Λ) + I)
    ℓ = 0.0
    @inbounds for t in 1:p
        (mask === nothing || mask[t]) || continue
        ℓ += _glm_logpdf(fams[t], μ[t], n[t], y[t])
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

"""
    truncated_nbinom2_pertrait_marginal_loglik_laplace(Y, Λ, β, rvec; link=LogLink(), kwargs...) -> Float64

Laplace log-marginal for a zero-truncated NB2 GLLVM with **per-trait**
dispersion `rvec` (length p; `r_t` ≡ twin `φ_t = exp(log_phi_truncnb2[t])`).
Equal `r_t` reduces to the shared-`r` [`truncated_nbinom2_marginal_loglik_laplace`](@ref).
`Y` must be integer counts with every observed cell `≥ 1`. Mode-finding reuses
`_grouped_laplace_mode` with `fams = TruncatedNegBin2.(rvec)`.
"""
function truncated_nbinom2_pertrait_marginal_loglik_laplace(Y::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, rvec::AbstractVector;
        link::Link = LogLink(), mask = nothing, offset = nothing, kwargs...)
    p = size(Λ, 1)
    length(rvec) == p || throw(ArgumentError(
        "length(rvec)=$(length(rvec)) must equal p=$p"))
    N1 = ones(Int, size(Y))
    fams = TruncatedNegBin2.(float.(rvec))
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        mi = mask   === nothing ? nothing : view(mask, :, i)
        oi = offset === nothing ? nothing : view(offset, :, i)
        acc += _truncnb2_pertrait_loglik_site(fams, view(Y, :, i), view(N1, :, i),
                                              Λ, β, link; mask = mi, offset = oi, kwargs...)
    end
    return acc
end

"""
    TruncatedNegBin2PerTraitFit

Result of [`fit_truncated_nbinom2_gllvm_pertrait`](@ref): intercepts `β`,
loadings `Λ`, per-trait dispersion `r` (length p; `Var_t = μ_t + μ_t²/r_t`
≡ twin `φ_t`), link, loglik, convergence.
"""
struct TruncatedNegBin2PerTraitFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    r::Vector{Float64}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
    theta_packed::Vector{Float64}
end

function Base.show(io::IO, f::TruncatedNegBin2PerTraitFit)
    p, K = size(f.Λ)
    print(io, "TruncatedNegBin2PerTraitFit(p=", p, ", K=", K,
          ", r∈[", round(minimum(f.r); sigdigits = 4), ", ",
          round(maximum(f.r); sigdigits = 4), "]",
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_truncated_nbinom2_gllvm_pertrait(Y; K, link=LogLink(), …) -> TruncatedNegBin2PerTraitFit

Fit a zero-truncated NB2 GLLVM with **per-trait** dispersion by Laplace + LBFGS
over `[β; pack(Λ); log r_1 … log r_p]` (length `p+rr+p`). Twin-aligned:
`r_t` ≡ `φ_t = exp(log_phi_truncnb2[t])`; log link on untruncated `μ`;
support `y ≥ 1`. Score/weight keep `a = r_t/(r_t+μ)` (Sol 2026-08-15).
Throws if any observed cell is `< 1`.
"""
function fit_truncated_nbinom2_gllvm_pertrait(Y::AbstractMatrix; K::Integer,
        link::Link = LogLink(), mask = nothing, offset = nothing,
        β_init = nothing, Λ_init = nothing, r_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    link isa LogLink || throw(ArgumentError(
        "fit_truncated_nbinom2_gllvm_pertrait: only LogLink is supported (twin truncated_nbinom2)"))
    p, n = size(Y)
    rr = rr_theta_len(p, K)
    msk = mask === nothing ? (any(ismissing, Y) ? observed_mask(Y) : nothing) : mask
    Yc = Integer.(_sanitize_missing(Y, 1))
    @inbounds for t in 1:p, s in 1:n
        (msk !== nothing && !msk[t, s]) && continue
        Yc[t, s] < 1 && throw(ArgumentError(
            "truncated_nbinom2 requires y ≥ 1; found y=$(Yc[t, s]) at ($t,$s)"))
    end

    Zemp = [linkfun(link, max(Float64(Yc[t, i]), 1.0)) for t in 1:p, i in 1:n]
    offset === nothing || (Zemp .-= offset)
    if msk !== nothing
        @inbounds for t in 1:p
            obs = view(msk, t, :)
            cnt = count(obs)
            rowmean = cnt > 0 ? sum(Zemp[t, i] for i in 1:n if msk[t, i]) / cnt : 0.0
            for i in 1:n
                msk[t, i] || (Zemp[t, i] = rowmean)
            end
        end
    end
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
    logr0 = if r_init === nothing
        fill(log(10.0), p)
    elseif r_init isa AbstractVector
        length(r_init) == p || throw(ArgumentError(
            "length(r_init)=$(length(r_init)) must equal p=$p"))
        log.(float.(r_init))
    else
        fill(log(float(r_init)), p)
    end

    θ0 = vcat(β0, pack_lambda(Λ0), logr0)
    length(θ0) == p + rr + p || throw(ArgumentError(
        "per-trait pack length $(length(θ0)) ≠ p+rr+p=$(p + rr + p)"))
    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        rvec = exp.(θ[(p + rr + 1):(p + rr + p)])
        v = try
            -truncated_nbinom2_pertrait_marginal_loglik_laplace(Yc, Λ, β, rvec;
                    link = link, mask = msk, offset = offset,
                    maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    opts = Optim.Options(g_tol = g_tol, iterations = iterations)
    res = Optim.optimize(negll, θ0, ls, opts; autodiff = :finite)
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    r̂ = exp.(θ̂[(p + rr + 1):(p + rr + p)])
    return TruncatedNegBin2PerTraitFit(β̂, Λ̂, r̂, link, -Optim.minimum(res),
                                       Optim.converged(res), Optim.iterations(res),
                                       collect(Float64, θ̂))
end
