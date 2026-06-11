# Generic Laplace-approximated marginal log-likelihood for non-Gaussian GLLVM
# families. The family-specific pieces — the Fisher-scoring score and weight, the
# μ clamp, and the conditional log-density — dispatch on the Distributions family
# type, so Binomial, Poisson, … share one mode-finder (no hardcoded family switch).
#
# Model (site s): y_{ts} ~ Family(μ_{ts}[, n_{ts}]),  μ = linkinv(link, η),
#     η = β_t + (Λ z_s)_t,  z_s ~ N(0, I_K).
# The marginal ∫ p(y_s|z) N(z;0,I) dz (non-conjugate) is computed by Laplace:
# find the conditional mode ẑ by Fisher scoring (expected Hessian ⇒ Λ'WΛ + I
# is always SPD), then  log p(y_s) ≈ ℓ(ẑ) − ½ẑ'ẑ − ½ logdet(Λ'WΛ + I).
#
# Each family provides, dispatched on its type:
#   _clamp_mu(family, μ)              domain-safe μ
#   _glm_score(family, μ, n, me, y)   ∂ℓ/∂η contribution (score)
#   _glm_weight(family, μ, n, me)     Fisher information wrt η (≥ 0)
#   _glm_logpdf(family, μ, n, y)      conditional log-density
# (see families/binomial.jl, families/poisson.jl).

# η clamp is family-agnostic; μ clamp dispatches on the family.
_clamp_eta(η) = clamp(η, -30.0, 30.0)
_positive_from_log(x) = exp(clamp(x, -30.0, 30.0))

# Robust linear solve: returns `nothing` if the factorization is singular or
# fails, so the inner Newton can stop gracefully. A = Λ'WΛ + I is SPD by
# construction but can be numerically singular when the Fisher weights blow up
# (huge μ at the η clamp — e.g. a Poisson rate driven to exp(30)).
_safe_solve(A, b) = try
    A \ b
catch
    nothing
end

struct _LaplaceModeWorkspace{T}
    η::Vector{T}
    μ::Vector{T}
    me::Vector{T}
    s::Vector{T}
    W::Vector{T}
    A::Matrix{T}
    rhs::Vector{T}
    Δ::Vector{T}
end

function _LaplaceModeWorkspace(::Type{T}, p::Int, K::Int) where {T}
    return _LaplaceModeWorkspace{T}(
        Vector{T}(undef, p),
        Vector{T}(undef, p),
        Vector{T}(undef, p),
        Vector{T}(undef, p),
        Vector{T}(undef, p),
        Matrix{T}(undef, K, K),
        Vector{T}(undef, K),
        Vector{T}(undef, K),
    )
end

# In-place inner Laplace mode-finder (Fisher-scoring Newton). Starts from the
# contents of `z` and overwrites it with the conditional mode ẑ. This is used by
# cached fitter paths so neighbouring Optim probes do not repeatedly cold-start
# each site's latent mode.
function _laplace_mode!(z::AbstractVector, family, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        maxiter::Integer = 100, tol::Real = 1e-9)
    for _ in 1:maxiter
        η  = _clamp_eta.(β .+ Λ * z)
        μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
        me = mu_eta.(Ref(link), η)
        # NA-aware (missing-data FIML): a missing response cell drops from this site —
        # 0 score, 0 working weight (so it leaves A = Λ'WΛ + I, which stays SPD). For a
        # dense (non-Missing) Y the ismissing guard is statically false and elided, so
        # this is byte-equivalent to the broadcast it replaces.
        s  = similar(η)
        W  = similar(η)
        @inbounds for t in eachindex(y)
            if ismissing(y[t])
                s[t] = zero(eltype(s)); W[t] = zero(eltype(W))
            else
                s[t] = _glm_score(family, μ[t], n[t], me[t], y[t])
                W[t] = _glm_weight(family, μ[t], n[t], me[t])
            end
        end
        A  = Symmetric(Λ' * (W .* Λ) + I)
        Δ  = _safe_solve(A, Λ' * s .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break   # singular A ⇒ stop at current ẑ
        z .+= Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

function _laplace_mode!(z::AbstractVector, family, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link,
        work::_LaplaceModeWorkspace; maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    η = work.η
    μ = work.μ
    me = work.me
    s = work.s
    W = work.W
    A = work.A
    rhs = work.rhs
    Δ = work.Δ
    for _ in 1:maxiter
        mul!(η, Λ, z)
        @inbounds for t in 1:p
            η[t] = _clamp_eta(β[t] + η[t])
            if ismissing(y[t])                       # NA-aware FIML: drop missing cell
                s[t] = zero(eltype(s)); W[t] = zero(eltype(W))
            else
                μ[t] = _clamp_mu(family, linkinv(link, η[t]))
                me[t] = mu_eta(link, η[t])
                s[t] = _glm_score(family, μ[t], n[t], me[t], y[t])
                W[t] = _glm_weight(family, μ[t], n[t], me[t])
            end
        end

        fill!(A, zero(eltype(A)))
        @inbounds for k in 1:K
            A[k, k] = one(eltype(A))
        end
        @inbounds for t in 1:p
            for k in 1:K
                WΛtk = W[t] * Λ[t, k]
                for l in 1:K
                    A[k, l] += WΛtk * Λ[t, l]
                end
            end
        end

        @inbounds for k in 1:K
            rhs[k] = -z[k]
        end
        @inbounds for t in 1:p
            for k in 1:K
                rhs[k] += Λ[t, k] * s[t]
            end
        end

        C = try
            cholesky(Symmetric(A))
        catch
            break
        end
        copyto!(Δ, rhs)
        ldiv!(C, Δ)
        all(isfinite, Δ) || break
        z .+= Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

# Inner Laplace mode-finder (Fisher-scoring Newton). Returns the conditional mode
# ẑ (length K) for one site. Shared across families and by getLV (src/postfit.jl).
function _laplace_mode(family, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        maxiter::Integer = 100, tol::Real = 1e-9, z_init = nothing)
    K = size(Λ, 2)
    T = promote_type(eltype(Λ), eltype(β))
    z = z_init === nothing ? zeros(T, K) : collect(T, z_init)
    return _laplace_mode!(z, family, y, n, Λ, β, link;
                          maxiter = maxiter, tol = tol)
end

"""
    laplace_loglik_site(family, y, n, Λ, β, link; maxiter=100, tol=1e-9) -> Float64

Laplace-approximated log-marginal for one site of a non-Gaussian GLLVM. `family`
is a `Distributions` family marker (e.g. `Binomial()`, `Poisson()`); `y`, `n` are
the response and trial counts (length p; `n` is ignored by families without
trials); `Λ` p×K; `β` length-p; `link` a `Link`. Returns
`ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I)`.
"""
function laplace_loglik_site(family, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        maxiter::Integer = 100, tol::Real = 1e-9)
    p = size(Λ, 1)
    z  = _laplace_mode(family, y, n, Λ, β, link; maxiter = maxiter, tol = tol)
    η  = _clamp_eta.(β .+ Λ * z)
    μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    # NA-aware FIML: missing cells contribute 0 weight and drop from the ℓ sum.
    W  = similar(η)
    @inbounds for t in 1:p
        W[t] = ismissing(y[t]) ? zero(eltype(W)) : _glm_weight(family, μ[t], n[t], me[t])
    end
    A  = Symmetric(Λ' * (W .* Λ) + I)
    ℓ = zero(eltype(A))
    @inbounds for t in 1:p
        ismissing(y[t]) || (ℓ += _glm_logpdf(family, μ[t], n[t], y[t]))
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

"""
    marginal_loglik_laplace(family, Y, N, Λ, β, link; kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a non-Gaussian GLLVM.
`Y`, `N` are p×n response and trial-count matrices.
"""
function marginal_loglik_laplace(family, Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, link::Link; kwargs...)
    acc = zero(promote_type(eltype(Λ), eltype(β)))
    @inbounds for i in axes(Y, 2)
        acc += laplace_loglik_site(family, view(Y, :, i), view(N, :, i), Λ, β, link; kwargs...)
    end
    return acc
end

# Value and mode-equation stack for one site at fixed `z` and packed `θ`.
# `family_fromθ` maps the packed parameter vector to the family marker, allowing
# dispersion families to keep log-dispersion in θ while differentiating wrt θ.
function _scalar_laplace_qF(family_fromθ, y::AbstractVector, n::AbstractVector,
        θ::AbstractVector, z::AbstractVector, p::Int, K::Int, link::Link)
    rr = rr_theta_len(p, K)
    β = θ[1:p]
    Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    family = family_fromθ(θ)
    η  = _clamp_eta.(β .+ Λ * z)
    μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    # NA-aware FIML (generic implicit path → all non-Gaussian families): a missing cell
    # contributes 0 score/weight (drops from A and F = Λ's − z) and is skipped in ℓ. qF
    # is then independent of the missing cell, so the implicit-function gradient is
    # automatically correct. Byte-equivalent on dense Y (guard statically false).
    s  = similar(η)
    W  = similar(η)
    @inbounds for t in 1:p
        if ismissing(y[t])
            s[t] = zero(eltype(s)); W[t] = zero(eltype(W))
        else
            s[t] = _glm_score(family, μ[t], n[t], me[t], y[t])
            W[t] = _glm_weight(family, μ[t], n[t], me[t])
        end
    end
    A  = Symmetric(Λ' * (W .* Λ) + I)
    ℓ = zero(eltype(A))
    @inbounds for t in 1:p
        ismissing(y[t]) || (ℓ += _glm_logpdf(family, μ[t], n[t], y[t]))
    end
    q = ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
    F = Λ' * s .- z
    return vcat(q, F)
end

function _implicit_site_gradient(qF, x0::AbstractVector, K::Int)
    J = ForwardDiff.jacobian(qF, x0)
    qz = vec(J[1, 1:K])
    qθ = vec(J[1, (K + 1):end])
    Fz = J[2:end, 1:K]
    Fθ = J[2:end, (K + 1):end]
    adj = Fz' \ qz
    return qF(x0)[1], qθ - Fθ' * adj
end

function _scalar_laplace_site_implicit_value_grad(family_fromθ,
        y::AbstractVector, n::AbstractVector, θ::AbstractVector,
        p::Int, K::Int, link::Link; maxiter::Integer = 100, tol::Real = 1e-9)
    rr = rr_theta_len(p, K)
    β = θ[1:p]
    Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    family = family_fromθ(θ)
    z = _laplace_mode(family, y, n, Λ, β, link; maxiter = maxiter, tol = tol)
    x0 = vcat(z, θ)
    qF = x -> _scalar_laplace_qF(family_fromθ, y, n, x[(K + 1):end],
                                 x[1:K], p, K, link)
    return _implicit_site_gradient(qF, x0, K)
end

"""
    marginal_loglik_laplace_implicit_value_grad(family_fromθ, Y, N, θ, p, K, link; kwargs...)

Return `(loglik, gradient)` for the packed scalar-family Laplace objective.
The site modes are found once with the Fisher-scoring solver, then the gradient
uses the implicit mode equation `F_z dz/dθ = -F_θ` instead of differentiating
through the Newton iterations.
"""
function marginal_loglik_laplace_implicit_value_grad(family_fromθ,
        Y::AbstractMatrix, N::AbstractMatrix, θ::AbstractVector,
        p::Int, K::Int, link::Link; kwargs...)
    value = zero(eltype(θ))
    grad = zeros(eltype(θ), length(θ))
    @inbounds for i in axes(Y, 2)
        v, g = _scalar_laplace_site_implicit_value_grad(
            family_fromθ, view(Y, :, i), view(N, :, i), θ, p, K, link; kwargs...)
        value += v
        grad .+= g
    end
    return value, grad
end

_canonical_weight_eta_derivative(::Poisson, μ, n, W) = W
_canonical_weight_eta_derivative(::Binomial, μ, n, W) = W * (one(μ) - 2 * μ)

function _canonical_laplace_site_implicit_value_grad(family,
        y::AbstractVector, n::AbstractVector, θ::AbstractVector,
        p::Int, K::Int, link::Link; maxiter::Integer = 100, tol::Real = 1e-9,
        z_init = nothing, z_store = nothing)
    rr = rr_theta_len(p, K)
    β = @view θ[1:p]
    Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    return _canonical_laplace_site_implicit_value_grad_parts(
        family, y, n, β, Λ, θ, p, K, link;
        maxiter = maxiter, tol = tol, z_init = z_init, z_store = z_store)
end

function _canonical_laplace_site_implicit_value_grad_parts(family,
        y::AbstractVector, n::AbstractVector, β::AbstractVector,
        Λ::AbstractMatrix, θ::AbstractVector, p::Int, K::Int, link::Link;
        maxiter::Integer = 100, tol::Real = 1e-9,
        z_init = nothing, z_store = nothing, mode_work = nothing)
    z = if z_store === nothing
        zlocal = z_init === nothing ? zeros(promote_type(eltype(Λ), eltype(β)), K) :
                 collect(promote_type(eltype(Λ), eltype(β)), z_init)
        mode_work === nothing ?
            _laplace_mode!(zlocal, family, y, n, Λ, β, link;
                           maxiter = maxiter, tol = tol) :
            _laplace_mode!(zlocal, family, y, n, Λ, β, link, mode_work;
                           maxiter = maxiter, tol = tol)
    else
        z_init !== nothing && z_init !== z_store && copyto!(z_store, z_init)
        mode_work === nothing ?
            _laplace_mode!(z_store, family, y, n, Λ, β, link;
                           maxiter = maxiter, tol = tol) :
            _laplace_mode!(z_store, family, y, n, Λ, β, link, mode_work;
                           maxiter = maxiter, tol = tol)
    end
    η  = _clamp_eta.(β .+ Λ * z)
    μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    # NA-aware FIML: a missing cell gets s=W=Wη=0 and is skipped in ℓ; downstream a[t]
    # and every grad term carry a factor of a[t]/W[t]/s[t], so missing cells vanish.
    s  = similar(η)
    W  = similar(η)
    Wη = similar(η)
    @inbounds for t in 1:p
        if ismissing(y[t])
            s[t]  = zero(eltype(s))
            W[t]  = zero(eltype(W))
            Wη[t] = zero(eltype(Wη))
        else
            s[t]  = _glm_score(family, μ[t], n[t], me[t], y[t])
            W[t]  = _glm_weight(family, μ[t], n[t], me[t])
            Wη[t] = _canonical_weight_eta_derivative(family, μ[t], n[t], W[t])
        end
    end

    A = Symmetric(Λ' * (W .* Λ) + I)
    C = cholesky(A)
    M = C \ Matrix{eltype(A)}(I, K, K)
    ΛM = Λ * M

    ℓ = zero(eltype(A))
    h = similar(W)
    @inbounds for t in 1:p
        ismissing(y[t]) || (ℓ += _glm_logpdf(family, μ[t], n[t], y[t]))
        h[t] = dot(view(Λ, t, :), view(ΛM, t, :))
    end
    value = ℓ - 0.5 * dot(z, z) - 0.5 * logdet(C)

    # q = log-likelihood Laplace contribution, F = Λ's - z.
    # For canonical Poisson-log and Binomial-logit, ∂s/∂η = -W and
    # F_z = -(I + Λ'WΛ), so only one K×K adjoint solve is needed.
    a = similar(s)
    @inbounds for t in 1:p
        a[t] = s[t] - 0.5 * h[t] * Wη[t]
    end
    qz = Λ' * a .- z
    adj = -(C \ qz)
    λadj = Λ * adj

    grad = zeros(eltype(θ), length(θ))
    @inbounds for t in 1:p
        grad[t] = a[t] + W[t] * λadj[t]
    end
    @inbounds for k in 1:K
        # Diagonal loading Λ[k,k] is stored in θ[p+k].
        t = k
        grad[p + k] = a[t] * z[k] - W[t] * ΛM[t, k] -
                      s[t] * adj[k] + W[t] * z[k] * λadj[t]
        for t in (k + 1):p
            idx = p + _lower_index(p, K, t, k)
            grad[idx] = a[t] * z[k] - W[t] * ΛM[t, k] -
                        s[t] * adj[k] + W[t] * z[k] * λadj[t]
        end
    end
    return value, grad
end

"""
    marginal_loglik_laplace_canonical_value_grad(family, Y, N, θ, p, K, link; kwargs...)

Return `(loglik, gradient)` for canonical scalar-family Laplace objectives
without a per-site ForwardDiff Jacobian. This is currently valid for
Poisson-log and Binomial-logit, where `∂s/∂η = -W` and
`F_z = -(I + Λ'WΛ)`.
"""
function marginal_loglik_laplace_canonical_value_grad(family,
        Y::AbstractMatrix, N::AbstractMatrix, θ::AbstractVector,
        p::Int, K::Int, link::Link; kwargs...)
    rr = rr_theta_len(p, K)
    β = @view θ[1:p]
    Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    value = zero(eltype(θ))
    grad = zeros(eltype(θ), length(θ))
    @inbounds for i in axes(Y, 2)
        v, g = _canonical_laplace_site_implicit_value_grad_parts(
            family, view(Y, :, i), view(N, :, i), β, Λ, θ, p, K, link; kwargs...)
        value += v
        grad .+= g
    end
    return value, grad
end

function marginal_loglik_laplace_canonical_value_grad!(Zcache::AbstractMatrix,
        family, Y::AbstractMatrix, N::AbstractMatrix, θ::AbstractVector,
        p::Int, K::Int, link::Link; kwargs...)
    rr = rr_theta_len(p, K)
    β = @view θ[1:p]
    Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    value = zero(eltype(θ))
    grad = zeros(eltype(θ), length(θ))
    @inbounds for i in axes(Y, 2)
        zbuf = view(Zcache, :, i)
        v, g = _canonical_laplace_site_implicit_value_grad_parts(
            family, view(Y, :, i), view(N, :, i), β, Λ, θ, p, K, link;
            z_init = zbuf, z_store = zbuf, kwargs...)
        value += v
        grad .+= g
    end
    return value, grad
end

function _obs_lsw_aux(family_from_aux, link::Link, y, n, v::AbstractVector)
    η = v[1]
    aux = view(v, 2:length(v))
    family = family_from_aux(aux)
    μ = _clamp_mu(family, linkinv(link, _clamp_eta(η)))
    me = mu_eta(link, _clamp_eta(η))
    return [
        _glm_logpdf(family, μ, n, y),
        _glm_score(family, μ, n, me, y),
        _glm_weight(family, μ, n, me),
    ]
end

function _obs_lsw_aux_derivatives_fallback(family_from_aux, link::Link, y, n, η, aux)
    v0 = vcat(η, aux)
    lsw = v -> _obs_lsw_aux(family_from_aux, link, y, n, v)
    vals = lsw(v0)
    J = ForwardDiff.jacobian(lsw, v0)
    return vals[1], vals[2], vals[3], J[1, 2], J[2, 1], J[2, 2], J[3, 1], J[3, 2]
end

function _obs_lsw_aux_derivatives(family, family_from_aux, link::Link, y, n, η, aux)
    return _obs_lsw_aux_derivatives_fallback(family_from_aux, link, y, n, η, aux)
end

function _obs_lsw_aux_derivatives(f::NegativeBinomial, family_from_aux, link::LogLink,
        y, n, η, aux)
    ηc = _clamp_eta(η)
    ηc == η || return _obs_lsw_aux_derivatives_fallback(
        family_from_aux, link, y, n, η, aux)
    r = f.r
    μ = _clamp_mu(f, exp(ηc))
    μ > 1e-12 || return _obs_lsw_aux_derivatives_fallback(
        family_from_aux, link, y, n, η, aux)
    rpμ = r + μ
    logrpμ = log(rpμ)
    ℓ = loggamma(y + r) - loggamma(r) - loggamma(y + one(r)) +
        r * (log(r) - logrpμ) + y * (log(μ) - logrpμ)
    s = r * (y - μ) / rpμ
    W = r * μ / rpμ
    qaux = r * (digamma(y + r) - digamma(r) + log(r) - log(rpμ) +
                one(r) - (r + y) / rpμ)
    sη = -r * μ * (r + y) / rpμ^2
    saux = r * μ * (y - μ) / rpμ^2
    Wη = r^2 * μ / rpμ^2
    Waux = r * μ^2 / rpμ^2
    return ℓ, s, W, qaux, sη, saux, Wη, Waux
end

function _obs_lsw_aux_derivatives(f::Beta, family_from_aux, link::LogitLink,
        y, n, η, aux)
    ηc = _clamp_eta(η)
    ηc == η || return _obs_lsw_aux_derivatives_fallback(
        family_from_aux, link, y, n, η, aux)
    φ = f.α
    μ = _clamp_mu(f, inv(one(ηc) + exp(-ηc)))
    (1e-6 < μ < 1 - 1e-6) || return _obs_lsw_aux_derivatives_fallback(
        family_from_aux, link, y, n, η, aux)

    a = μ * φ
    b = (one(μ) - μ) * φ
    ystar = log(y) - log1p(-y)
    log1my = log1p(-y)
    ψa = digamma(a)
    ψb = digamma(b)
    ψφ = digamma(φ)
    ψ1a = trigamma(a)
    ψ1b = trigamma(b)
    ψ2a = polygamma(2, a)
    ψ2b = polygamma(2, b)
    μstar = ψa - ψb
    A = ystar - μstar
    me = μ * (one(μ) - μ)
    m2 = me * (one(μ) - 2 * μ)
    ν = ψ1a + ψ1b

    ℓ = loggamma(φ) - loggamma(a) - loggamma(b) +
        (a - one(a)) * log(y) + (b - one(b)) * log1my
    s = φ * A * me
    W = φ^2 * ν * me^2
    qaux = φ * (ψφ - μ * ψa - (one(μ) - μ) * ψb +
                μ * log(y) + (one(μ) - μ) * log1my)
    sη = φ * (-φ * ν * me^2 + A * m2)
    saux = φ * me * (A - (a * ψ1a - b * ψ1b))
    Wη = φ^2 * (φ * (ψ2a - ψ2b) * me^3 + 2 * ν * me * m2)
    Waux = 2 * W + φ^2 * me^2 * (a * ψ2a + b * ψ2b)
    return ℓ, s, W, qaux, sη, saux, Wη, Waux
end

function _obs_lsw_aux_derivatives(f::Gamma, family_from_aux, link::LogLink,
        y, n, η, aux)
    ηc = _clamp_eta(η)
    ηc == η || return _obs_lsw_aux_derivatives_fallback(
        family_from_aux, link, y, n, η, aux)
    y > zero(y) || return _obs_lsw_aux_derivatives_fallback(
        family_from_aux, link, y, n, η, aux)
    α = f.α
    μ = _clamp_mu(f, exp(ηc))
    μ > 1e-12 || return _obs_lsw_aux_derivatives_fallback(
        family_from_aux, link, y, n, η, aux)
    ℓ = α * (log(α) - log(μ)) - loggamma(α) +
        (α - one(α)) * log(y) - α * y / μ
    s = α * (y / μ - one(μ))
    W = α
    qaux = α * (log(α) + one(α) - digamma(α) - log(μ) + log(y) - y / μ)
    sη = -α * y / μ
    saux = s
    Wη = zero(α)
    Waux = α
    return ℓ, s, W, qaux, sη, saux, Wη, Waux
end

function _scalar_aux_laplace_site_implicit_value_grad(family_from_aux,
        y::AbstractVector, n::AbstractVector, θ::AbstractVector,
        p::Int, K::Int, link::Link; maxiter::Integer = 100, tol::Real = 1e-9,
        z_init = nothing, z_store = nothing)
    rr = rr_theta_len(p, K)
    β = @view θ[1:p]
    Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    aux = @view θ[(p + rr + 1):length(θ)]
    length(aux) == 1 || throw(ArgumentError(
        "scalar-aux implicit gradient expects one auxiliary parameter; got $(length(aux))"))
    family = family_from_aux(aux)
    return _scalar_aux_laplace_site_implicit_value_grad_parts(
        family, family_from_aux, y, n, β, Λ, aux, θ, p, K, link;
        maxiter = maxiter, tol = tol, z_init = z_init, z_store = z_store)
end

function _scalar_aux_laplace_site_implicit_value_grad_parts(family, family_from_aux,
        y::AbstractVector, n::AbstractVector, β::AbstractVector,
        Λ::AbstractMatrix, aux::AbstractVector, θ::AbstractVector,
        p::Int, K::Int, link::Link; maxiter::Integer = 100, tol::Real = 1e-9,
        z_init = nothing, z_store = nothing, mode_work = nothing)
    z = if z_store === nothing
        zlocal = z_init === nothing ? zeros(promote_type(eltype(Λ), eltype(β)), K) :
                 collect(promote_type(eltype(Λ), eltype(β)), z_init)
        mode_work === nothing ?
            _laplace_mode!(zlocal, family, y, n, Λ, β, link;
                           maxiter = maxiter, tol = tol) :
            _laplace_mode!(zlocal, family, y, n, Λ, β, link, mode_work;
                           maxiter = maxiter, tol = tol)
    else
        z_init !== nothing && z_init !== z_store && copyto!(z_store, z_init)
        mode_work === nothing ?
            _laplace_mode!(z_store, family, y, n, Λ, β, link;
                           maxiter = maxiter, tol = tol) :
            _laplace_mode!(z_store, family, y, n, Λ, β, link, mode_work;
                           maxiter = maxiter, tol = tol)
    end
    η = _clamp_eta.(β .+ Λ * z)

    T = promote_type(eltype(θ), eltype(z))
    ℓ = zero(T)
    qaux = zero(T)
    s = Vector{T}(undef, p)
    W = Vector{T}(undef, p)
    sη = Vector{T}(undef, p)
    saux = Vector{T}(undef, p)
    Wη = Vector{T}(undef, p)
    Waux = Vector{T}(undef, p)
    @inbounds for t in 1:p
        if ismissing(y[t])                       # NA-aware FIML: drop missing cell
            s[t] = zero(T); W[t] = zero(T)
            sη[t] = zero(T); saux[t] = zero(T)
            Wη[t] = zero(T); Waux[t] = zero(T)
            continue                             # 0 contribution to ℓ, qaux, A, Fz, grad
        end
        ℓt, st, Wt, qauxt, sηt, sauxt, Wηt, Wauxt =
            _obs_lsw_aux_derivatives(family, family_from_aux, link, y[t], n[t], η[t], aux)
        ℓ += ℓt
        s[t] = st
        W[t] = Wt
        qaux += qauxt
        sη[t] = sηt
        saux[t] = sauxt
        Wη[t] = Wηt
        Waux[t] = Wauxt
    end

    A = Symmetric(Λ' * (W .* Λ) + I)
    C = cholesky(A)
    M = C \ Matrix{eltype(A)}(I, K, K)
    ΛM = Λ * M

    h = similar(W)
    @inbounds for t in 1:p
        h[t] = dot(view(Λ, t, :), view(ΛM, t, :))
        qaux -= 0.5 * h[t] * Waux[t]
    end
    value = ℓ - 0.5 * dot(z, z) - 0.5 * logdet(C)

    a = similar(s)
    @inbounds for t in 1:p
        a[t] = s[t] - 0.5 * h[t] * Wη[t]
    end
    qz = Λ' * a .- z
    Fz = Λ' * (sη .* Λ)
    @inbounds for k in 1:K
        Fz[k, k] -= one(eltype(Fz))
    end
    adj = Fz' \ qz
    λadj = Λ * adj

    grad = zeros(eltype(θ), length(θ))
    @inbounds for t in 1:p
        grad[t] = a[t] - sη[t] * λadj[t]
    end
    @inbounds for k in 1:K
        t = k
        grad[p + k] = a[t] * z[k] - W[t] * ΛM[t, k] -
                      s[t] * adj[k] - sη[t] * z[k] * λadj[t]
        for t in (k + 1):p
            idx = p + _lower_index(p, K, t, k)
            grad[idx] = a[t] * z[k] - W[t] * ΛM[t, k] -
                        s[t] * adj[k] - sη[t] * z[k] * λadj[t]
        end
    end
    grad[end] = qaux - dot(Λ' * saux, adj)
    return value, grad
end

"""
    marginal_loglik_laplace_aux_value_grad(family_from_aux, Y, N, θ, p, K, link; kwargs...)

Return `(loglik, gradient)` for scalar-family Laplace objectives with one
auxiliary packed parameter after `[β; vec(Λ)]`, such as `log r` for NB2 or
`log φ` for Beta. The helper differentiates each observation only with respect
to `(η, aux)` and applies the packed implicit-gradient chain rule analytically.
"""
function marginal_loglik_laplace_aux_value_grad(family_from_aux,
        Y::AbstractMatrix, N::AbstractMatrix, θ::AbstractVector,
        p::Int, K::Int, link::Link; kwargs...)
    rr = rr_theta_len(p, K)
    β = @view θ[1:p]
    Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    aux = @view θ[(p + rr + 1):length(θ)]
    length(aux) == 1 || throw(ArgumentError(
        "scalar-aux implicit gradient expects one auxiliary parameter; got $(length(aux))"))
    family = family_from_aux(aux)
    use_mode_work = !(family isa NegativeBinomial)
    value = zero(eltype(θ))
    grad = zeros(eltype(θ), length(θ))
    if use_mode_work
        mode_work = _LaplaceModeWorkspace(eltype(θ), p, K)
        zwork = zeros(eltype(θ), K)
        @inbounds for i in axes(Y, 2)
            fill!(zwork, zero(eltype(zwork)))
            v, g = _scalar_aux_laplace_site_implicit_value_grad_parts(
                family, family_from_aux, view(Y, :, i), view(N, :, i),
                β, Λ, aux, θ, p, K, link;
                z_store = zwork, mode_work = mode_work, kwargs...)
            value += v
            grad .+= g
        end
    else
        @inbounds for i in axes(Y, 2)
            v, g = _scalar_aux_laplace_site_implicit_value_grad_parts(
                family, family_from_aux, view(Y, :, i), view(N, :, i),
                β, Λ, aux, θ, p, K, link; kwargs...)
            value += v
            grad .+= g
        end
    end
    return value, grad
end

"""
    marginal_loglik_laplace_aux_value_grad!(Zcache, family_from_aux, Y, N, θ, p, K, link; kwargs...)

Cache-backed variant of [`marginal_loglik_laplace_aux_value_grad`](@ref) for
benchmarking and future fitter experiments. `Zcache` stores the per-site
Laplace modes between calls; production fitters stay on the stateless path
until optimizer line-search behaviour is fully validated with the cache.
"""
function marginal_loglik_laplace_aux_value_grad!(Zcache::AbstractMatrix,
        family_from_aux, Y::AbstractMatrix, N::AbstractMatrix, θ::AbstractVector,
        p::Int, K::Int, link::Link; kwargs...)
    size(Zcache, 1) == K && size(Zcache, 2) == size(Y, 2) ||
        throw(DimensionMismatch("Zcache must have size (K, n_sites) = ($(K), $(size(Y, 2))); got $(size(Zcache))"))
    rr = rr_theta_len(p, K)
    β = @view θ[1:p]
    Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    aux = @view θ[(p + rr + 1):length(θ)]
    length(aux) == 1 || throw(ArgumentError(
        "scalar-aux implicit gradient expects one auxiliary parameter; got $(length(aux))"))
    family = family_from_aux(aux)
    use_mode_work = !(family isa NegativeBinomial)
    value = zero(eltype(θ))
    grad = zeros(eltype(θ), length(θ))
    if use_mode_work
        mode_work = _LaplaceModeWorkspace(eltype(θ), p, K)
        @inbounds for i in axes(Y, 2)
            zbuf = view(Zcache, :, i)
            v, g = _scalar_aux_laplace_site_implicit_value_grad_parts(
                family, family_from_aux, view(Y, :, i), view(N, :, i),
                β, Λ, aux, θ, p, K, link;
                z_init = zbuf, z_store = zbuf, mode_work = mode_work, kwargs...)
            value += v
            grad .+= g
        end
    else
        @inbounds for i in axes(Y, 2)
            zbuf = view(Zcache, :, i)
            v, g = _scalar_aux_laplace_site_implicit_value_grad_parts(
                family, family_from_aux, view(Y, :, i), view(N, :, i),
                β, Λ, aux, θ, p, K, link;
                z_init = zbuf, z_store = zbuf, kwargs...)
            value += v
            grad .+= g
        end
    end
    return value, grad
end

function _penalty_negloglik_fg!(F, G, θ)
    if G !== nothing
        any_nonzero = false
        @inbounds for i in eachindex(θ)
            gi = if isfinite(θ[i])
                2 * θ[i]
            elseif θ[i] < 0
                -one(eltype(G))
            else
                one(eltype(G))
            end
            G[i] = gi
            any_nonzero |= !iszero(gi)
        end
        !any_nonzero && !isempty(G) && (G[1] = one(eltype(G)))
    end
    if F !== nothing
        s = zero(eltype(θ))
        @inbounds for x in θ
            isfinite(x) && (s += abs2(x))
        end
        return oftype(first(θ), 1e12) + s
    end
    return nothing
end

function _penalized_negloglik_fg!(F, G, value_grad, θ)
    try
        value, grad = value_grad(θ)
        if !isfinite(value) || !all(isfinite, grad)
            return _penalty_negloglik_fg!(F, G, θ)
        end
        G !== nothing && (G .= .-grad)
        F !== nothing && return -value
        return nothing
    catch
        return _penalty_negloglik_fg!(F, G, θ)
    end
end
