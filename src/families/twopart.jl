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

# ---------------------------------------------------------------------------
# Fit driver (Delta-lognormal slice 2).
# ---------------------------------------------------------------------------

"""
    DeltaLogNormalFit

Result of [`fit_delta_lognormal_gllvm`](@ref): occurrence logits `βz` (length p),
positive-part meanlog intercepts `βc` (length p), positive-part loadings `Λc`
(p×K), the shared log-scale SD `σ`, the maximised `loglik`, `converged`, and
`iterations`. (`Λz = 0` — occurrence is intercept-only in v1.)
"""
struct DeltaLogNormalFit
    βz::Vector{Float64}
    βc::Vector{Float64}
    Λc::Matrix{Float64}
    σ::Float64
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::DeltaLogNormalFit)
    p, K = size(f.Λc)
    print(io, "DeltaLogNormalFit(p=", p, ", K=", K, ", σ=", round(f.σ; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_delta_lognormal_gllvm(Y; K, …) -> DeltaLogNormalFit

Fit a Delta-lognormal two-part GLLVM by L-BFGS over `[βz; βc; vec(Λc); log σ]` on
the two-part Laplace marginal ([`delta_lognormal_marginal_loglik_laplace`](@ref)),
with `Λz = 0` (per-species occurrence intercept). `Y` is p×n with `0` for absences
and positive reals otherwise. Finite-difference gradient; warm start =
`logit(empirical P(y>0))` occurrence intercepts + mean / SVD of the positive-part
log-responses + `σ₀ = sd(log y_{>0})`.
"""
function fit_delta_lognormal_gllvm(Y::AbstractMatrix{<:Real}; K::Integer,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    βz0 = Vector{Float64}(undef, p)
    βc0 = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        npres = count(>(0), view(Y, t, :))
        pr = clamp((npres + 0.5) / (n + 1), 1e-3, 1 - 1e-3)
        βz0[t] = log(pr / (1 - pr))
        s = 0.0; c = 0
        for j in 1:n
            if Y[t, j] > 0
                s += log(Y[t, j]); c += 1
            end
        end
        βc0[t] = c == 0 ? 0.0 : s / c
    end
    sumsq = 0.0; nres = 0
    @inbounds for t in 1:p, j in 1:n
        if Y[t, j] > 0
            r = log(Y[t, j]) - βc0[t]; sumsq += r^2; nres += 1
        end
    end
    σ0 = nres > 1 ? max(sqrt(sumsq / (nres - 1)), 0.1) : 0.5
    Zc = [Y[t, j] > 0 ? log(Y[t, j]) - βc0[t] : 0.0 for t in 1:p, j in 1:n]
    F = svd(Zc); kk = min(K, length(F.S))
    Λc0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λc0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end

    θ0 = vcat(βz0, βc0, pack_lambda(Λc0), log(σ0))
    function negll(θ)
        βz = θ[1:p]
        βc = θ[(p + 1):(2p)]
        Λc = unpack_lambda(θ[(2p + 1):(2p + rr)], p, K)
        σ = exp(θ[2p + rr + 1])
        v = try
            -delta_lognormal_marginal_loglik_laplace(Y, Λc, βz, βc, σ;
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
    βz = θ̂[1:p]; βc = θ̂[(p + 1):(2p)]
    Λc = unpack_lambda(θ̂[(2p + 1):(2p + rr)], p, K)
    σ = exp(θ̂[2p + rr + 1])
    return DeltaLogNormalFit(βz, βc, Λc, σ, -Optim.minimum(res),
                             Optim.converged(res), Optim.iterations(res))
end

# ---------------------------------------------------------------------------
# Hurdle-Poisson — occurrence Bernoulli × ZERO-TRUNCATED Poisson count.
# P(y=0)=1−π, P(y=k)=π·Poisson(k;μ)/(1−e^{−μ}) for k≥1, π=logistic(η^z), μ=exp(η^c).
# Positive-block score/weight use the truncated mean μ_tr=μ/(1−e^{−μ}) and its
# variance Var_tr = μ_tr(1+μ−μ_tr): s^c = y−μ_tr, W^c = Var_tr (y>0; 0 for y=0).
# ---------------------------------------------------------------------------

"""
    HurdlePoisson()

Marker for the Hurdle-Poisson two-part family (Bernoulli occurrence × zero-truncated
Poisson count).
"""
struct HurdlePoisson end

function _tp_pieces(::HurdlePoisson, y, ηz, ηc)
    π = inv(one(ηz) + exp(-ηz))
    Wz = π * (one(π) - π)
    if y > 0
        μ = exp(ηc)
        p0 = exp(-μ)
        μtr = μ / (1 - p0)                       # zero-truncated mean
        Wc = μtr * (1 + μ - μtr)                 # zero-truncated variance ≥ 0
        logf = log(π) + logpdf(Poisson(μ), Int(y)) - log1p(-p0)
        return (one(π) - π, y - μtr, Wz, Wc, logf)
    else
        return (-π, zero(ηc), Wz, zero(ηc), log1p(-π))
    end
end

"""
    hurdle_poisson_marginal_loglik_laplace(Y, Λc, βz, βc; Λz=nothing, kwargs...) -> Float64

Total two-part Laplace log-marginal for a Hurdle-Poisson GLLVM (occurrence
`π=logistic(β^z)`, intercept-only by default; zero-truncated Poisson count with
`μ=exp(β^c+Λ_c z)`). `Y` is p×n integer counts (`0`=absence). `Λc=0` ⇒ exact
independent hurdle-Poisson loglik.
"""
function hurdle_poisson_marginal_loglik_laplace(Y::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector;
        Λz::Union{Nothing, AbstractMatrix} = nothing, kwargs...)
    p, K = size(Λc)
    Λz_ = Λz === nothing ? zeros(p, K) : Λz
    return twopart_marginal_loglik_laplace(HurdlePoisson(), Y, Λz_, Λc, βz, βc; kwargs...)
end

"""
    HurdlePoissonFit

Result of [`fit_hurdle_poisson_gllvm`](@ref): occurrence logits `βz`, count log-mean
intercepts `βc`, count loadings `Λc`, `loglik`, `converged`, `iterations`.
"""
struct HurdlePoissonFit
    βz::Vector{Float64}
    βc::Vector{Float64}
    Λc::Matrix{Float64}
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::HurdlePoissonFit)
    p, K = size(f.Λc)
    print(io, "HurdlePoissonFit(p=", p, ", K=", K,
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_hurdle_poisson_gllvm(Y; K, …) -> HurdlePoissonFit

Fit a Hurdle-Poisson two-part GLLVM by L-BFGS over `[βz; βc; vec(Λc)]` (Λz=0).
`Y` p×n integer counts. Finite-difference gradient; warm start =
`logit(empirical P(y>0))` + `log` mean positive count + SVD loadings.
"""
function fit_hurdle_poisson_gllvm(Y::AbstractMatrix{<:Real}; K::Integer,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)
    βz0 = Vector{Float64}(undef, p); βc0 = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        npres = count(>(0), view(Y, t, :))
        pr = clamp((npres + 0.5) / (n + 1), 1e-3, 1 - 1e-3)
        βz0[t] = log(pr / (1 - pr))
        s = 0.0; c = 0
        for j in 1:n
            if Y[t, j] > 0
                s += Y[t, j]; c += 1
            end
        end
        βc0[t] = c == 0 ? 0.0 : log(max(s / c, 1.0))
    end
    Zc = [Y[t, j] > 0 ? log(max(Y[t, j], 0.5)) - βc0[t] : 0.0 for t in 1:p, j in 1:n]
    F = svd(Zc); kk = min(K, length(F.S))
    Λc0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λc0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end

    θ0 = vcat(βz0, βc0, pack_lambda(Λc0))
    function negll(θ)
        βz = θ[1:p]; βc = θ[(p + 1):(2p)]
        Λc = unpack_lambda(θ[(2p + 1):(2p + rr)], p, K)
        v = try
            -hurdle_poisson_marginal_loglik_laplace(Y, Λc, βz, βc;
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
    βz = θ̂[1:p]; βc = θ̂[(p + 1):(2p)]
    Λc = unpack_lambda(θ̂[(2p + 1):(2p + rr)], p, K)
    return HurdlePoissonFit(βz, βc, Λc, -Optim.minimum(res),
                            Optim.converged(res), Optim.iterations(res))
end
