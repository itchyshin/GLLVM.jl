# Two-part / mixture family substrate for GLLVM.jl (shared-z, Option A — one
# latent z drives both parts via part-specific loadings Λ_z, Λ_c). Two-part
# observations depend on TWO linear predictors η^z (occurrence/zero) and η^c
# (positive/count), so they do not fit the scalar-μ generic core in
# families/laplace.jl. Each two-part family instead provides, dispatched on its
# marker:
#     _tp_pieces(family, y, η^z, η^c) -> (s^z, s^c, W^z, W^c, logf)
# the per-observation block scores s = ∂logf/∂η, the expected-information Fisher
# weights W = −E[∂²logf/∂η²] (cross term is 0 — the two parts are conditionally
# independent), and the two-part log-density logf. The shared-z mode-finder then
# assembles (spec §2.0):
#     A(z) = Λ_z'diag(W^z)Λ_z + Λ_c'diag(W^c)Λ_c + I       (SPD)
#     g(z) = Λ_z's^z + Λ_c's^c − z
#     z ← z + A(z)⁻¹ g(z)                                  (Fisher scoring)
#     log p(y_s) ≈ ℓ_s(ẑ) − ½ẑ'ẑ − ½logdet A(ẑ).
# `_clamp_eta`/`_safe_solve` are reused from families/laplace.jl. With the v1
# default Λ_z = 0 the occurrence block drops out of A and g (the integral is
# genuinely K-dimensional; β^z carries a per-species occurrence intercept).

# Per-site joint mode ẑ over the shared latent z (Fisher-scoring Newton).
function _twopart_mode(family, y::AbstractVector,
        Λz::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector;
        maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λc)
    z = zeros(K)
    sz = Vector{Float64}(undef, p); sc = Vector{Float64}(undef, p)
    Wz = Vector{Float64}(undef, p); Wc = Vector{Float64}(undef, p)
    for _ in 1:maxiter
        ηz = _clamp_eta.(βz .+ Λz * z)
        ηc = _clamp_eta.(βc .+ Λc * z)
        @inbounds for t in 1:p
            s_z, s_c, W_z, W_c, _ = _tp_pieces(family, y[t], ηz[t], ηc[t])
            sz[t] = s_z; sc[t] = s_c; Wz[t] = W_z; Wc[t] = W_c
        end
        A = Symmetric(Λz' * (Wz .* Λz) + Λc' * (Wc .* Λc) + I)
        Δ = _safe_solve(A, Λz' * sz .+ Λc' * sc .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break
        z = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

"""
    twopart_loglik_site(family, y, Λz, Λc, βz, βc; maxiter=100, tol=1e-9) -> Float64

Two-part Laplace log-marginal for one site: `ℓ_s(ẑ) − ½ẑ'ẑ − ½logdet A(ẑ)`.
"""
function twopart_loglik_site(family, y::AbstractVector,
        Λz::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector;
        maxiter::Integer = 100, tol::Real = 1e-9)
    p = size(Λc, 1)
    ẑ = _twopart_mode(family, y, Λz, Λc, βz, βc; maxiter = maxiter, tol = tol)
    ηz = _clamp_eta.(βz .+ Λz * ẑ)
    ηc = _clamp_eta.(βc .+ Λc * ẑ)
    Wz = Vector{Float64}(undef, p); Wc = Vector{Float64}(undef, p)
    ℓ = 0.0
    @inbounds for t in 1:p
        _, _, W_z, W_c, logf = _tp_pieces(family, y[t], ηz[t], ηc[t])
        Wz[t] = W_z; Wc[t] = W_c; ℓ += logf
    end
    A = Symmetric(Λz' * (Wz .* Λz) + Λc' * (Wc .* Λc) + I)
    return ℓ - 0.5 * dot(ẑ, ẑ) - 0.5 * logdet(A)
end

"""
    twopart_marginal_loglik_laplace(family, Y, Λz, Λc, βz, βc; kwargs...) -> Float64

Total two-part Laplace log-marginal over the `n` sites (columns of `Y`).
"""
function twopart_marginal_loglik_laplace(family, Y::AbstractMatrix,
        Λz::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector; kwargs...)
    acc = 0.0
    @inbounds for s in axes(Y, 2)
        acc += twopart_loglik_site(family, view(Y, :, s), Λz, Λc, βz, βc; kwargs...)
    end
    return acc
end

# ---------------------------------------------------------------------------
# Delta-lognormal family — occurrence Bernoulli × positive lognormal.
# P(y=0)=1−π, density for y>0 = π·LogNormal(y; meanlog=η^c, sdlog=σ),
# π = logistic(η^z). The positive part is Gaussian in log y, so W^c=1/σ² is the
# exact Hessian and the Laplace marginal is exact (the cleanest substrate check).
# ---------------------------------------------------------------------------

"""
    DeltaLogNormal(σ)

Marker for the Delta-lognormal two-part family with shared log-scale SD `σ`.
"""
struct DeltaLogNormal
    σ::Float64
end

function _tp_pieces(f::DeltaLogNormal, y, ηz, ηc)
    π = inv(one(ηz) + exp(-ηz))                 # occurrence prob = logistic(η^z)
    Wz = π * (one(π) - π)
    if y > 0
        σ = f.σ
        sc = (log(y) - ηc) / σ^2                # ∂logf/∂η^c, θ = η^c (meanlog)
        return (one(π) - π, sc, Wz, inv(σ^2),
                log(π) + logpdf(LogNormal(ηc, σ), y))
    else
        return (-π, zero(ηc), Wz, zero(ηc), log1p(-π))
    end
end

"""
    delta_lognormal_marginal_loglik_laplace(Y, Λc, βz, βc, σ; Λz=nothing, kwargs...) -> Float64

Total two-part Laplace log-marginal for a Delta-lognormal GLLVM: occurrence
probability `π = logistic(β^z + Λ_z z)` (intercept-only by default, `Λ_z = 0`)
times a positive lognormal with meanlog `η^c = β^c + Λ_c z` and sdlog `σ`. `Y` is
p×n with `0` for absences and positive reals for the positive part. With `Λ_c = 0`
(and `Λ_z = 0`) this reduces exactly to the independent two-part-regression
log-likelihood.
"""
function delta_lognormal_marginal_loglik_laplace(Y::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector, σ::Real;
        Λz::Union{Nothing, AbstractMatrix} = nothing, kwargs...)
    p, K = size(Λc)
    Λz_ = Λz === nothing ? zeros(p, K) : Λz
    return twopart_marginal_loglik_laplace(DeltaLogNormal(float(σ)), Y, Λz_, Λc, βz, βc; kwargs...)
end
