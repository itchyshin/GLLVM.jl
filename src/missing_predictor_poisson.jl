# Non-Gaussian missing predictor (mi() Phase 5a) — canonical-family augmented Laplace.
#
# A non-Gaussian GLLVM (Poisson-log or Binomial-logit — the canonical families,
# where the Fisher and observed Hessian weights coincide) with ONE missing
# site-level continuous predictor x_s and a broadcast slope b_x,
# x_s ~ N(μ_x, σ_x²), integrated by full-information ML:
#   y[t,s] ~ family(link⁻¹(η[t,s])),  η[t,s] = β_t + b_x x_s + (Λ z_s)_t,  z_s ~ N(0,I_K)
#
# Per site:
#   • x_s OBSERVED  — fold b_x x_s into the offset, Laplace over z (reuse the primal
#       mode + the implicit differentiable Newton step), plus the full x-prior
#       density logN(x_s; μ_x, σ_x²).
#   • x_s MISSING   — integrate x_s: augment the latent to (z, x), joint Laplace
#       with the rank-1 bordered Fisher Hessian
#         H = [ Λ'WΛ+I        b_x Λ'W ;
#               b_x (Λ'W)'  b_x²Σ_t W_t + 1/σ_x² ],   W = the family's Fisher weight,
#       marginal  ℓ(ẑ,x̂) − ½ẑ'ẑ − ½(x̂−μ_x)²/σ_x² − ½log σ_x² − ½logdet(H).
#       (The (2π) constants cancel as in the K-dim code; limits to the observed-
#       at-μ_x value as σ_x→0. Verified vs 2-D Gauss–Hermite quadrature.)
#
# AD-clean via the implicit "one differentiable Newton step at the mode" trick
# (mirrors laplace_grad.jl) on the (K+1) augmented system. Smallest slice =
# marginal primitive + oracle tests (no exported fitter; non-canonical families
# (NB/Gamma/Beta, observed-weight step) + the hand-coded (K+1) adjoint are
# follow-ons). See docs/dev-log/2026-06-13-nongaussian-mi-design.md.

using LinearAlgebra

# AD-friendly (μ, score, Fisher weight) for the canonical families.
_xs_glm(::Poisson, ::LogLink, η, n, y) = (μ = exp.(η); (μ, y .- μ, μ))
function _xs_glm(::Binomial, ::LogitLink, η, n, y)
    μ = 1 ./ (1 .+ exp.(-η))
    return (μ, y .- n .* μ, n .* μ .* (1 .- μ))
end

# Full AD-friendly log-pmf (the normalising constants are θ-independent, so they do
# not affect the gradient — but they ARE needed for the marginal VALUE to be a
# proper likelihood and to match the full-pmf oracles).
_binom_logpmf_full(μ, n, y) = y * log(μ) + (n - y) * log1p(-μ) +
                              loggamma(n + 1.0) - loggamma(y + 1.0) - loggamma(n - y + 1.0)
_xs_logker_sum(::Poisson, μ, n, y) = sum(_pois_logpmf(μ[t], y[t]) for t in eachindex(y))
_xs_logker_sum(::Binomial, μ, n, y) = sum(_binom_logpmf_full(μ[t], n[t], y[t]) for t in eachindex(y))

# Primal augmented (z, x) Newton mode (Float64; called on primal parameter values).
function _mode_xs(family, y, n, Λ, β, link, b_x::Real, μ_x::Real, σ_x2::Real;
                  maxiter::Integer = 100, tol::Real = 1e-9)
    K = size(Λ, 2)
    z = zeros(K)
    x = float(μ_x)
    for _ in 1:maxiter
        η = _clamp_eta.(β .+ b_x * x .+ Λ * z)
        μ, s, W = _xs_glm(family, link, η, n, y)
        gz = Λ' * s .- z
        gx = b_x * sum(s) - (x - μ_x) / σ_x2
        A = Λ' * (W .* Λ) + I
        c = b_x .* (Λ' * W)
        dd = b_x^2 * sum(W) + 1 / σ_x2
        H = [A c; c' dd]
        Δ = H \ vcat(gz, gx)
        all(isfinite, Δ) || break
        z = z .+ Δ[1:K]
        x = x + Δ[K + 1]
        maximum(abs, Δ) < tol && break
    end
    return z, x
end

# Differentiable per-site marginal with the site-predictor x_s (observed or missing).
# β, Λ, b_x, μ_x, σ_x2 may carry duals; the mode is primal (no dual leakage).
function _site_xs_diffable(family, y, n, Λ, β, link, x_obs, b_x, μ_x, σ_x2)
    K = size(Λ, 2)
    Λv = ForwardDiff.value.(Λ)
    βv = ForwardDiff.value.(β)
    bxv = ForwardDiff.value(b_x)
    mxv = ForwardDiff.value(μ_x)
    sx2v = ForwardDiff.value(σ_x2)

    if x_obs !== nothing
        ẑ = _laplace_mode(family, y, n, Λv, βv, link; offset = bxv * x_obs)
        off = b_x * x_obs
        η = _clamp_eta.(β .+ off .+ Λ * ẑ)
        μ, s, W = _xs_glm(family, link, η, n, y)
        A = Λ' * (W .* Λ) + I
        z = ẑ .+ (A \ (Λ' * s .- ẑ))
        ηz = _clamp_eta.(β .+ off .+ Λ * z)
        μz, _, Wz = _xs_glm(family, link, ηz, n, y)
        Az = Λ' * (Wz .* Λ) + I
        ℓ = _xs_logker_sum(family, μz, n, y)
        lpx = -0.5 * log(2π) - 0.5 * log(σ_x2) - 0.5 * (x_obs - μ_x)^2 / σ_x2
        return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(Az) + lpx
    else
        ẑ, x̂ = _mode_xs(family, y, n, Λv, βv, link, bxv, mxv, sx2v)
        η = _clamp_eta.(β .+ b_x * x̂ .+ Λ * ẑ)
        μ, s, W = _xs_glm(family, link, η, n, y)
        gz = Λ' * s .- ẑ
        gx = b_x * sum(s) - (x̂ - μ_x) / σ_x2
        A = Λ' * (W .* Λ) + I
        c = b_x .* (Λ' * W)
        dd = b_x^2 * sum(W) + 1 / σ_x2
        H = [A c; c' dd]
        Δ = H \ vcat(gz, gx)
        z = ẑ .+ Δ[1:K]
        x = x̂ + Δ[K + 1]
        ηz = _clamp_eta.(β .+ b_x * x .+ Λ * z)
        μz, _, Wz = _xs_glm(family, link, ηz, n, y)
        Az = Λ' * (Wz .* Λ) + I
        cz = b_x .* (Λ' * Wz)
        ddz = b_x^2 * sum(Wz) + 1 / σ_x2
        Hz = [Az cz; cz' ddz]
        ℓ = _xs_logker_sum(family, μz, n, y)
        return ℓ - 0.5 * dot(z, z) - 0.5 * (x - μ_x)^2 / σ_x2 -
               0.5 * log(σ_x2) - 0.5 * logdet(Hz)
    end
end

_xs_supported(family, link) =
    (family isa Poisson && link isa LogLink) || (family isa Binomial && link isa LogitLink)

"""
    laplace_loglik_site_xs(family, y, n, Λ, β, link; x_obs, b_x, μ_x, σ_x2) -> Float64

Per-site Laplace marginal for a non-Gaussian GLLVM with one site-level predictor
`x_s` (observed value `x_obs`, or `nothing` if missing-and-integrated), broadcast
slope `b_x`, predictor model `x_s ~ N(μ_x, σ_x²)`. Canonical families:
`Poisson()` + `LogLink` and `Binomial()` + `LogitLink`.
"""
function laplace_loglik_site_xs(family, y::AbstractVector, n::AbstractVector,
                                Λ::AbstractMatrix, β::AbstractVector, link;
                                x_obs, b_x, μ_x, σ_x2)
    _xs_supported(family, link) || throw(ArgumentError(
        "laplace_loglik_site_xs: supports Poisson()+LogLink and Binomial()+LogitLink (canonical families)."))
    return _site_xs_diffable(family, y, n, Λ, β, link, x_obs, b_x, μ_x, σ_x2)
end

"""
    marginal_loglik_laplace_xs(family, Y, N, Λ, β, link; x, b_x, μ_x, σ_x2) -> Float64

Total Laplace log-marginal over sites for a canonical non-Gaussian GLLVM
(Poisson-log or Binomial-logit) with one missing site-level continuous predictor
integrated by FIML (mi() Phase 5a). `x` is length-n (entries may be
`missing`/`NaN`). Observed sites contribute the joint `(y_s, x_s)` density;
missing sites contribute the marginal of `y_s` with `x_s` integrated out.
"""
function marginal_loglik_laplace_xs(family, Y::AbstractMatrix, N::AbstractMatrix,
                                    Λ::AbstractMatrix, β::AbstractVector, link;
                                    x::AbstractVector, b_x, μ_x, σ_x2)
    acc = zero(promote_type(eltype(Λ), eltype(β), typeof(b_x), typeof(μ_x), typeof(σ_x2)))
    @inbounds for s in axes(Y, 2)
        xs = x[s]
        x_obs = (ismissing(xs) || (xs isa Real && isnan(xs))) ? nothing : Float64(xs)
        acc += laplace_loglik_site_xs(family, view(Y, :, s), view(N, :, s), Λ, β, link;
                                      x_obs = x_obs, b_x = b_x, μ_x = μ_x, σ_x2 = σ_x2)
    end
    return acc
end

_mi_canonical_link(::Poisson) = LogLink()
_mi_canonical_link(::Binomial) = LogitLink()

function _mi_init_lambda(family, Y, N, β0, K)
    p, n = size(Y)
    Z = Matrix{Float64}(undef, p, n)
    if family isa Poisson
        @. Z = log(Y + 0.5) - β0
    else
        @. Z = log((Y + 0.5) / (N - Y + 0.5)) - β0
    end
    C = Symmetric((Z * Z') ./ n)
    E = eigen(C)
    idx = sortperm(E.values, rev = true)[1:K]
    return E.vectors[:, idx] .* sqrt.(max.(E.values[idx], 1e-2))'
end

"""
    fit_gllvm_mi(family, Y, x; K, N=nothing, link=canonical, ...) -> NamedTuple

Fit a non-Gaussian GLLVM (canonical family: `Poisson()`+`LogLink` or
`Binomial()`+`LogitLink`) with one site-level continuous predictor `x` (length
`n`, entries may be `missing`/`NaN`), where the missing `x_s` are integrated out
by full-information ML (the augmented (z,x) Laplace of
`marginal_loglik_laplace_xs`). `Y` is `p × n`; `N` is the `p × n`
trial-count matrix for Binomial (`ones` for Poisson). The predictor enters with a
single broadcast slope `b_x` and predictor model `x ~ N(μ_x, σ_x²)`.

Returns a NamedTuple with `β`, `Λ` (`p × K`), `b_x`, `μ_x`, `σ_x`, `logLik`,
`converged`, `n_missing`. Optimised with L-BFGS over the AD-clean marginal.
"""
function fit_gllvm_mi(family, Y::AbstractMatrix, x::AbstractVector; K::Integer,
                      N::Union{Nothing,AbstractMatrix} = nothing,
                      link = _mi_canonical_link(family),
                      g_tol::Real = 1e-8, iterations::Integer = 1000)
    p, n = size(Y)
    length(x) == n || throw(ArgumentError("length(x) = $(length(x)) must equal n = $n."))
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1."))
    _xs_supported(family, link) || throw(ArgumentError(
        "fit_gllvm_mi: canonical families only (Poisson()+LogLink, Binomial()+LogitLink)."))
    Nm = N === nothing ? ones(Int, p, n) : N

    isobs = [!(ismissing(xi) || (xi isa Real && isnan(xi))) for xi in x]
    any(isobs) || throw(ArgumentError("x has no observed values."))
    xo = Float64[Float64(x[i]) for i in findall(isobs)]
    μ_x0 = Statistics.mean(xo)
    σ_x0 = max(Statistics.std(xo), 1e-2)

    rowmean = vec(sum(Y, dims = 2)) ./ n
    β0 = family isa Poisson ? log.(max.(rowmean, 0.5)) :
         log.((rowmean .+ 0.5) ./ (vec(sum(Nm, dims = 2)) ./ n .- rowmean .+ 0.5))
    Λ0 = _mi_init_lambda(family, Y, Nm, β0, K)

    θ0 = vcat(β0, vec(Λ0), 0.0, μ_x0, log(σ_x0^2))
    function negll(θ)
        β = θ[1:p]
        Λ = reshape(θ[(p + 1):(p + p * K)], p, K)
        bx = θ[p + p * K + 1]
        mx = θ[p + p * K + 2]
        sx2 = exp(θ[p + p * K + 3])
        return -marginal_loglik_laplace_xs(family, Y, Nm, Λ, β, link;
                                           x = x, b_x = bx, μ_x = mx, σ_x2 = sx2)
    end
    res = Optim.optimize(negll, θ0, Optim.LBFGS(),
                         Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :forward)
    θ = Optim.minimizer(res)
    β = θ[1:p]
    Λ = reshape(θ[(p + 1):(p + p * K)], p, K)
    b_x = θ[p + p * K + 1]
    μ_x = θ[p + p * K + 2]
    σ_x = exp(0.5 * θ[p + p * K + 3])
    return (β = β, Λ = Λ, b_x = b_x, μ_x = μ_x, σ_x = σ_x,
            logLik = -Optim.minimum(res), converged = Optim.converged(res),
            n_missing = count(!, isobs))
end
