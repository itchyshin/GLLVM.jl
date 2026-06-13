# Ordinal (ordered categorical, C levels) — proportional-odds cumulative-link
# GLLVM. y ∈ {1,…,C}; latent η = (Λ z)_t with z ~ N(0, I_K); common ordered
# cutpoints τ₁<…<τ_{C-1} (shared across species) absorb the category levels, so
# there is no separate species intercept. Cumulative model (McCullagh 1980),
# with link CDF F (F = logistic for logit, F = Φ for probit):
#   P(y ≤ c | z) = F(τ_c − η),
#   P(y = c | z) = F(τ_c − η) − F(τ_{c-1} − η),   τ₀ = −∞, τ_C = +∞.
# The link is selectable (`LogitLink()` default — gllvm-parity — or `ProbitLink()`);
# only the (F, f) pair changes, the score/weight/mode machinery is link-agnostic.
#
# The "mean" here is a vector of category probabilities, so this family does NOT
# use the scalar-μ generic Laplace core (families/laplace.jl). It carries its own
# per-site Fisher-scoring mode-finder, mirroring that core's normalisation —
# log p(y_s) ≈ ℓ(ẑ) − ½ẑ'ẑ − ½ logdet(Λ'WΛ + I). Per observation, wrt η:
#   score(η) = (f(τ_{c-1}−η) − f(τ_c−η)) / P(y=c)
#   W(η)     = Σ_{k=1}^{C} (f(τ_{k-1}−η) − f(τ_k−η))² / P(y=k)    (Fisher info ≥ 0)
# with f = F' the link density (logistic·(1−logistic) for logit; φ for probit).
# `_clamp_eta`/`_safe_solve` are reused from families/laplace.jl.

"""
    Ordinal

Family marker for the ordered-categorical (proportional-odds cumulative-logit)
GLLVM. `Distributions` has no ordinal type, so GLLVM defines its own. Categories
are coded `1:C`; the number of levels `C` is inferred from the data (`maximum(Y)`)
by the fitter, and equals `length(τ) + 1` in the marginal.
"""
struct Ordinal end

default_link(::Ordinal) = LogitLink()

# Link CDF F and density f = F'. The cumulative model and the analytic
# score/Fisher-weight are written generically in (F, f), so a new link only
# swaps these two. Logit (default) keeps its exact prior numerics; probit uses
# the standard-Normal CDF/pdf. η is clamped identically for both (parity of the
# mode-finder); probit does not overflow but the clamp is harmless on [−c, c].
_ord_F(x, ::LogitLink) = inv(one(x) + exp(-_clamp_eta(x)))            # logistic CDF (η-clamped)
_ord_f(x, ::LogitLink) = (Fx = _ord_F(x, LogitLink()); Fx * (one(Fx) - Fx))  # logistic density
_ord_F(x, ::ProbitLink) = cdf(Normal(), _clamp_eta(x))               # Φ (η-clamped for parity)
_ord_f(x, ::ProbitLink) = pdf(Normal(), _clamp_eta(x))               # φ
# Logit default: preserve byte-for-byte the original argument-less call sites.
_ord_F(x) = _ord_F(x, LogitLink())
_ord_f(x) = _ord_f(x, LogitLink())

# P(y = c) at linear predictor η with ordered cutpoints τ (length C−1).
@inline function _ord_prob(c::Integer, η, τ::AbstractVector, link::Link = LogitLink())
    C = length(τ) + 1
    Fhi = c == C ? one(η) : _ord_F(τ[c] - η, link)
    Flo = c == 1 ? zero(η) : _ord_F(τ[c - 1] - η, link)
    return Fhi - Flo
end

# Score ∂logP(y=c)/∂η and Fisher weight Σ_k (∂P_k/∂η)²/P_k at η.
function _ord_score_weight(c::Integer, η, τ::AbstractVector, link::Link = LogitLink())
    C = length(τ) + 1
    fhi = c == C ? zero(η) : _ord_f(τ[c] - η, link)
    flo = c == 1 ? zero(η) : _ord_f(τ[c - 1] - η, link)
    score = (flo - fhi) / max(_ord_prob(c, η, τ, link), 1e-12)
    W = zero(η)
    @inbounds for k in 1:C
        fk_hi = k == C ? zero(η) : _ord_f(τ[k] - η, link)
        fk_lo = k == 1 ? zero(η) : _ord_f(τ[k - 1] - η, link)
        dP = fk_lo - fk_hi
        W += dP^2 / max(_ord_prob(k, η, τ, link), 1e-12)
    end
    return score, W
end

# Per-site Laplace mode ẑ (Fisher-scoring Newton); η = Λ z (no intercept).
function _ordinal_laplace_mode(y::AbstractVector, Λ::AbstractMatrix, τ::AbstractVector,
        link::Link = LogitLink(); mask = nothing, maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    z = zeros(K)
    s = Vector{Float64}(undef, p)
    W = Vector{Float64}(undef, p)
    for _ in 1:maxiter
        η = _clamp_eta.(Λ * z)
        @inbounds for t in 1:p
            if mask !== nothing && !mask[t]
                s[t] = 0.0; W[t] = 0.0          # masked (missing) ⇒ no contribution
            else
                st, wt = _ord_score_weight(Int(y[t]), η[t], τ, link)
                s[t] = st; W[t] = wt
            end
        end
        A = Symmetric(Λ' * (W .* Λ) + I)
        Δ = _safe_solve(A, Λ' * s .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break
        z = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

"""
    ordinal_loglik_site(y, Λ, τ; maxiter=100, tol=1e-9) -> Float64

Laplace log-marginal for one site of a cumulative-logit ordinal GLLVM:
`ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I)`. `y` length-p ordinal responses (`1:C`),
`Λ` p×K, `τ` the `C−1` ordered cutpoints.
"""
function ordinal_loglik_site(y::AbstractVector, Λ::AbstractMatrix, τ::AbstractVector,
        link::Link = LogitLink(); mask = nothing, maxiter::Integer = 100, tol::Real = 1e-9)
    p = size(Λ, 1)
    z = _ordinal_laplace_mode(y, Λ, τ, link; mask = mask, maxiter = maxiter, tol = tol)
    η = _clamp_eta.(Λ * z)
    W = Vector{Float64}(undef, p)
    ℓ = 0.0
    @inbounds for t in 1:p
        if mask !== nothing && !mask[t]
            W[t] = 0.0                          # masked ⇒ dropped from logdet, no logpdf
        else
            ℓ += log(max(_ord_prob(Int(y[t]), η[t], τ, link), 1e-12))
            _, wt = _ord_score_weight(Int(y[t]), η[t], τ, link)
            W[t] = wt
        end
    end
    A = Symmetric(Λ' * (W .* Λ) + I)
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

"""
    ordinal_marginal_loglik_laplace(Y, Λ, τ; link=LogitLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a proportional-odds
cumulative ordinal GLLVM. `Y` is the p×n matrix of ordinal responses coded
`1:C`; `Λ` p×K; `τ` the `C−1` ordered cutpoints (shared across species). `link`
selects the cumulative-link CDF `F` (`LogitLink()` default, `ProbitLink()`). With
`Λ = 0` (η ≡ 0) the latent variable drops out and this reduces to the exact
independent cumulative-link log-likelihood `Σ log(F(τ_c) − F(τ_{c−1}))`.
"""
function ordinal_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix,
        τ::AbstractVector; link::Link = LogitLink(), mask = nothing, kwargs...)
    acc = 0.0
    @inbounds for s in axes(Y, 2)
        mcol = mask === nothing ? nothing : view(mask, :, s)
        acc += ordinal_loglik_site(view(Y, :, s), Λ, τ, link; mask = mcol, kwargs...)
    end
    return acc
end

# ---------------------------------------------------------------------------
# Fit driver (Ordinal family slice 2).
# ---------------------------------------------------------------------------

"""
    OrdinalFit

Result of [`fit_ordinal_gllvm`](@ref): loadings `Λ` (p×K), the `C−1` ordered
cutpoints `τ`, the number of categories `C`, the `link`, the maximised Laplace
`loglik`, the optimiser `converged` flag, and `iterations`. (No species intercept
— the common cutpoints carry the category levels.)
"""
struct OrdinalFit
    Λ::Matrix{Float64}
    τ::Vector{Float64}
    C::Int
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::OrdinalFit)
    p, K = size(f.Λ)
    print(io, "OrdinalFit(p=", p, ", K=", K, ", C=", f.C,
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

# Ordered cutpoints from unconstrained ψ: τ₁ = ψ₁, τ_c = τ_{c-1} + exp(ψ_c).
function _unpack_cutpoints(ψ::AbstractVector)
    m = length(ψ)
    τ = Vector{float(eltype(ψ))}(undef, m)
    τ[1] = ψ[1]
    @inbounds for c in 2:m
        τ[c] = τ[c - 1] + exp(ψ[c])
    end
    return τ
end

"""
    fit_ordinal_gllvm(Y; K, link=LogitLink(), …) -> OrdinalFit

Fit a proportional-odds cumulative ordinal GLLVM by L-BFGS over
`[vec(Λ); ψ]`, where the `C−1` ordered cutpoints are the unconstrained increments
`τ₁ = ψ₁, τ_c = τ_{c-1} + exp(ψ_c)` (so ordering holds for free) and the marginal
is [`ordinal_marginal_loglik_laplace`](@ref). `link` selects the cumulative-link
CDF (`LogitLink()` default, `ProbitLink()`). `Y` is a p×n matrix of ordinal
responses coded `1:C` (`C = maximum(Y)`). Finite-difference gradient; warm start =
empirical cumulative-proportion cutpoints + a normal-scores SVD loadings init.
"""
function fit_ordinal_gllvm(Y::AbstractMatrix{<:Integer}; K::Integer,
        link::Link = LogitLink(), Λ_init = nothing, mask = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    obs = mask === nothing ? trues(p, n) : mask
    # Category count and warm starts use OBSERVED cells only, so a masked cell's
    # (arbitrary) value never leaks into the fit.
    C = 0
    @inbounds for i in eachindex(Y)
        obs[i] && (C = max(C, Int(Y[i])))
    end
    C ≥ 2 || throw(ArgumentError("ordinal response needs ≥ 2 observed categories; got $C"))
    rr = rr_theta_len(p, K)
    # Sanitise masked cells to a valid category for the warm starts only.
    Ys = mask === nothing ? Y : [obs[t, i] ? Int(Y[t, i]) : 1 for t in 1:p, i in 1:n]

    # Loadings warm start: SVD of a row-centred normal-scores latent proxy.
    Zproxy = [quantile(Normal(), clamp((Ys[t, i] - 0.5) / C, 1e-3, 1 - 1e-3))
              for t in 1:p, i in 1:n]
    Λ0 = if Λ_init === nothing
        Zc = Zproxy .- (sum(Zproxy; dims = 2) ./ n)
        F = svd(Zc); kk = min(K, length(F.S))
        L = zeros(p, K)
        @inbounds for j in 1:kk
            L[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
        end
        L
    else
        collect(float.(Λ_init))
    end

    # Cutpoint warm start: τ_c = logit(empirical P(y ≤ c)); to ψ increments.
    counts = zeros(Int, C)
    @inbounds for i in eachindex(Ys)
        obs[i] && (counts[Int(Ys[i])] += 1)
    end
    cum = cumsum(counts ./ sum(counts))
    τ0 = [log(clamp(cum[c], 1e-3, 1 - 1e-3) / (1 - clamp(cum[c], 1e-3, 1 - 1e-3)))
          for c in 1:(C - 1)]
    ψ0 = similar(τ0)
    ψ0[1] = τ0[1]
    @inbounds for c in 2:(C - 1)
        ψ0[c] = log(max(τ0[c] - τ0[c - 1], 1e-3))
    end

    θ0 = vcat(pack_lambda(Λ0), ψ0)
    function negll(θ)
        Λ = unpack_lambda(θ[1:rr], p, K)
        τ = _unpack_cutpoints(θ[(rr + 1):(rr + C - 1)])
        v = try
            -ordinal_marginal_loglik_laplace(Y, Λ, τ; link = link, mask = mask,
                                             maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(negll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :finite)
    θ̂ = Optim.minimizer(res)
    Λ̂ = unpack_lambda(θ̂[1:rr], p, K)
    τ̂ = _unpack_cutpoints(θ̂[(rr + 1):(rr + C - 1)])
    return OrdinalFit(Λ̂, τ̂, C, link, -Optim.minimum(res),
                      Optim.converged(res), Optim.iterations(res))
end
