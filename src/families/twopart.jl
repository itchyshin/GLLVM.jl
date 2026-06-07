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
        offsetz = nothing, offsetc = nothing,
        maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λc)
    offz = offsetz === nothing ? false : offsetz    # additive identity ⇒ no-offset path unchanged
    offc = offsetc === nothing ? false : offsetc
    z = zeros(K)
    sz = Vector{Float64}(undef, p); sc = Vector{Float64}(undef, p)
    Wz = Vector{Float64}(undef, p); Wc = Vector{Float64}(undef, p)
    # Per-call buffers, reused across Newton iterations. Each is written in place
    # with the SAME broadcast / BLAS expression as the allocating version, so the
    # computed values and FP-operation order are bit-identical.
    Λzz = Vector{Float64}(undef, p)    # Λz*z (occurrence linear-predictor contribution)
    Λcz = Vector{Float64}(undef, p)    # Λc*z (positive-part linear-predictor contribution)
    ηz  = Vector{Float64}(undef, p)    # clamped occurrence predictor
    ηc  = Vector{Float64}(undef, p)    # clamped positive-part predictor
    WzΛz = Matrix{Float64}(undef, p, K)  # Wz .* Λz
    WcΛc = Matrix{Float64}(undef, p, K)  # Wc .* Λc
    Amat = Matrix{Float64}(undef, K, K)  # Λz'(Wz.*Λz) (+ Λc'(Wc.*Λc) and + I in place)
    Atmp = Matrix{Float64}(undef, K, K)  # Λc'(Wc.*Λc) temp before accumulation
    g  = Vector{Float64}(undef, K)     # rhs Λz'sz + Λc'sc − z
    gc = Vector{Float64}(undef, K)     # Λc'sc temp before accumulation
    for _ in 1:maxiter
        mul!(Λzz, Λz, z)
        mul!(Λcz, Λc, z)
        ηz .= _clamp_eta.(βz .+ offz .+ Λzz)
        ηc .= _clamp_eta.(βc .+ offc .+ Λcz)
        @inbounds for t in 1:p
            s_z, s_c, W_z, W_c, _ = _tp_pieces(family, y[t], ηz[t], ηc[t])
            sz[t] = s_z; sc[t] = s_c; Wz[t] = W_z; Wc[t] = W_c
        end
        WzΛz .= Wz .* Λz                       # = Wz .* Λz (p×K)
        WcΛc .= Wc .* Λc                       # = Wc .* Λc (p×K)
        mul!(Amat, Λz', WzΛz)                  # = Λz' * (Wz .* Λz)
        mul!(Atmp, Λc', WcΛc)                  # = Λc' * (Wc .* Λc)
        Amat .+= Atmp                          # = Λz'(Wz.*Λz) + Λc'(Wc.*Λc)
        @inbounds for d in 1:K
            Amat[d, d] += 1.0                  # + I (adds 1.0 to each diagonal entry)
        end
        A = Symmetric(Amat)
        mul!(g, Λz', sz)                        # = Λz' * sz
        mul!(gc, Λc', sc)                       # = Λc' * sc
        g .= g .+ gc .- z                       # rhs = Λz'sz + Λc'sc − z
        Δ = _safe_solve(A, g)
        (Δ === nothing || !all(isfinite, Δ)) && break
        z = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

"""
    twopart_loglik_site(family, y, Λz, Λc, βz, βc; offsetz=nothing, offsetc=nothing,
                        maxiter=100, tol=1e-9) -> Float64

Two-part Laplace log-marginal for one site: `ℓ_s(ẑ) − ½ẑ'ẑ − ½logdet A(ẑ)`. Optional
`offsetz` / `offsetc` are known additive terms on the occurrence / positive-part
predictors (`η^z = β^z + offsetz + Λ^z z`, similarly `η^c`).
"""
function twopart_loglik_site(family, y::AbstractVector,
        Λz::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector;
        offsetz = nothing, offsetc = nothing,
        maxiter::Integer = 100, tol::Real = 1e-9)
    p = size(Λc, 1)
    offz = offsetz === nothing ? false : offsetz
    offc = offsetc === nothing ? false : offsetc
    K = size(Λc, 2)
    ẑ = _twopart_mode(family, y, Λz, Λc, βz, βc;
                      offsetz = offsetz, offsetc = offsetc, maxiter = maxiter, tol = tol)
    ηz = _clamp_eta.(βz .+ offz .+ Λz * ẑ)
    ηc = _clamp_eta.(βc .+ offc .+ Λc * ẑ)
    Wz = Vector{Float64}(undef, p); Wc = Vector{Float64}(undef, p)
    ℓ = 0.0
    @inbounds for t in 1:p
        _, _, W_z, W_c, logf = _tp_pieces(family, y[t], ηz[t], ηc[t])
        Wz[t] = W_z; Wc[t] = W_c; ℓ += logf
    end
    # Per-call buffers (written in place with the SAME broadcast / BLAS expressions
    # as before ⇒ bit-identical values and FP-operation order).
    WzΛz = Wz .* Λz                           # = Wz .* Λz (p×K)
    WcΛc = Wc .* Λc                           # = Wc .* Λc (p×K)
    Amat = Λz' * WzΛz                          # = Λz' * (Wz .* Λz) (K×K)
    Atmp = Λc' * WcΛc                          # = Λc' * (Wc .* Λc) (K×K)
    Amat .+= Atmp                              # = Λz'(Wz.*Λz) + Λc'(Wc.*Λc)
    @inbounds for d in 1:K
        Amat[d, d] += 1.0                      # + I (adds 1.0 to each diagonal entry)
    end
    A = Symmetric(Amat)
    return ℓ - 0.5 * dot(ẑ, ẑ) - 0.5 * logdet(A)
end

"""
    twopart_marginal_loglik_laplace(family, Y, Λz, Λc, βz, βc;
                                    offsetz=nothing, offsetc=nothing, kwargs...) -> Float64

Total two-part Laplace log-marginal over the `n` sites (columns of `Y`). `offsetz` /
`offsetc` (p×n, or `nothing`) are known additive offsets on the occurrence /
positive-part predictors; a constant per-species `offsetc` is equivalent to shifting
`βc` (the offset-absorption identity).
"""
function twopart_marginal_loglik_laplace(family, Y::AbstractMatrix,
        Λz::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector;
        offsetz = nothing, offsetc = nothing, kwargs...)
    acc = 0.0
    @inbounds for s in axes(Y, 2)
        ozs = offsetz === nothing ? nothing : view(offsetz, :, s)
        ocs = offsetc === nothing ? nothing : view(offsetc, :, s)
        acc += twopart_loglik_site(family, view(Y, :, s), Λz, Λc, βz, βc;
                                   offsetz = ozs, offsetc = ocs, kwargs...)
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
        offset = nothing,
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
            -delta_lognormal_marginal_loglik_laplace(Y, Λc, βz, βc, σ; offsetc = offset,
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
        offset = nothing,
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
            -hurdle_poisson_marginal_loglik_laplace(Y, Λc, βz, βc; offsetc = offset,
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

# ---------------------------------------------------------------------------
# Hurdle-NB — occurrence Bernoulli × zero-truncated negative-binomial (NB2) count
# with shared dispersion r (Var = μ + μ²/r). p0=(r/(r+μ))^r; μ_tr=μ/(1−p0);
# s^c=y−μ_tr; W^c=(V+μ²)/(1−p0)−μ_tr², V=μ+μ²/r (y>0; 0 for y=0). r→∞ ⇒ Hurdle-Poisson.
# ---------------------------------------------------------------------------

"""
    HurdleNB(r)

Marker for the Hurdle-NB family (Bernoulli occurrence × zero-truncated NB2 count,
shared dispersion `r`).
"""
struct HurdleNB
    r::Float64
end

function _tp_pieces(f::HurdleNB, y, ηz, ηc)
    π = inv(one(ηz) + exp(-ηz))
    Wz = π * (one(π) - π)
    if y > 0
        μ = exp(ηc); r = f.r
        p0 = (r / (r + μ))^r
        μtr = μ / (1 - p0)
        V = μ + μ^2 / r
        Wc = (V + μ^2) / (1 - p0) - μtr^2
        logf = log(π) + logpdf(NegativeBinomial(r, r / (r + μ)), Int(y)) - log1p(-p0)
        return (one(π) - π, y - μtr, Wz, Wc, logf)
    else
        return (-π, zero(ηc), Wz, zero(ηc), log1p(-π))
    end
end

"""
    hurdle_nb_marginal_loglik_laplace(Y, Λc, βz, βc, r; Λz=nothing, kwargs...) -> Float64

Two-part Laplace log-marginal for a Hurdle-NB GLLVM. `Λc=0` ⇒ exact independent
hurdle-NB loglik; as `r→∞` tends to the Hurdle-Poisson marginal.
"""
function hurdle_nb_marginal_loglik_laplace(Y::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector, r::Real;
        Λz::Union{Nothing, AbstractMatrix} = nothing, kwargs...)
    p, K = size(Λc)
    Λz_ = Λz === nothing ? zeros(p, K) : Λz
    return twopart_marginal_loglik_laplace(HurdleNB(float(r)), Y, Λz_, Λc, βz, βc; kwargs...)
end

"""
    HurdleNBFit

Result of [`fit_hurdle_nb_gllvm`](@ref): `βz`, `βc`, `Λc`, dispersion `r`, `loglik`,
`converged`, `iterations`.
"""
struct HurdleNBFit
    βz::Vector{Float64}
    βc::Vector{Float64}
    Λc::Matrix{Float64}
    r::Float64
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::HurdleNBFit)
    p, K = size(f.Λc)
    print(io, "HurdleNBFit(p=", p, ", K=", K, ", r=", round(f.r; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_hurdle_nb_gllvm(Y; K, …) -> HurdleNBFit

Fit a Hurdle-NB two-part GLLVM by L-BFGS over `[βz; βc; vec(Λc); log r]` (Λz=0).
"""
function fit_hurdle_nb_gllvm(Y::AbstractMatrix{<:Real}; K::Integer,
        offset = nothing,
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
    θ0 = vcat(βz0, βc0, pack_lambda(Λc0), log(10.0))
    function negll(θ)
        βz = θ[1:p]; βc = θ[(p + 1):(2p)]
        Λc = unpack_lambda(θ[(2p + 1):(2p + rr)], p, K)
        r = exp(θ[2p + rr + 1])
        v = try
            -hurdle_nb_marginal_loglik_laplace(Y, Λc, βz, βc, r; offsetc = offset,
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
    r = exp(θ̂[2p + rr + 1])
    return HurdleNBFit(βz, βc, Λc, r, -Optim.minimum(res),
                       Optim.converged(res), Optim.iterations(res))
end

# ---------------------------------------------------------------------------
# Delta-Gamma family — occurrence Bernoulli × positive Gamma (log-link mean).
# P(y=0)=1−π, density for y>0 = π·Gamma(y; shape α, scale μ/α), so E[y|y>0]=μ,
# Var[y|y>0]=μ²/α, μ=exp(η^c), π=logistic(η^z). The positive-block score/weight
# are the Gamma GLM pieces (log link, V(μ)=μ²/α): s^c=α(y−μ)/μ, W^c=α (y>0; 0 for
# y=0) — the expected-information weight, exactly as in families/gamma.jl. This is
# the second Delta family: same occurrence block as Delta-lognormal, Gamma swapped
# in for the positive part.
# ---------------------------------------------------------------------------

"""
    DeltaGamma(α)

Marker for the Delta-Gamma two-part family: Bernoulli occurrence × positive Gamma
with shared shape `α` (mean `μ=exp(η^c)`, `Var=μ²/α`).
"""
struct DeltaGamma
    α::Float64
end

function _tp_pieces(f::DeltaGamma, y, ηz, ηc)
    π = inv(one(ηz) + exp(-ηz))                 # occurrence prob = logistic(η^z)
    Wz = π * (one(π) - π)
    if y > 0
        α = f.α
        μ = exp(ηc)                             # mean (log link)
        sc = α * (y - μ) / μ                    # ∂logf/∂η^c (Gamma GLM, log link)
        return (one(π) - π, sc, Wz, α,
                log(π) + logpdf(Gamma(α, μ / α), y))
    else
        return (-π, zero(ηc), Wz, zero(ηc), log1p(-π))
    end
end

"""
    delta_gamma_marginal_loglik_laplace(Y, Λc, βz, βc, α; Λz=nothing, kwargs...) -> Float64

Total two-part Laplace log-marginal for a Delta-Gamma GLLVM: occurrence probability
`π = logistic(β^z + Λ_z z)` (intercept-only by default, `Λ_z = 0`) times a positive
Gamma with mean `μ = exp(β^c + Λ_c z)` and shape `α` (`Var = μ²/α`). `Y` is p×n with
`0` for absences and positive reals for the positive part. With `Λ_c = 0` (and
`Λ_z = 0`) this reduces exactly to the independent two-part-regression log-likelihood.
"""
function delta_gamma_marginal_loglik_laplace(Y::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector, α::Real;
        Λz::Union{Nothing, AbstractMatrix} = nothing, kwargs...)
    p, K = size(Λc)
    Λz_ = Λz === nothing ? zeros(p, K) : Λz
    return twopart_marginal_loglik_laplace(DeltaGamma(float(α)), Y, Λz_, Λc, βz, βc; kwargs...)
end

"""
    DeltaGammaFit

Result of [`fit_delta_gamma_gllvm`](@ref): occurrence logits `βz` (length p),
positive-part log-mean intercepts `βc` (length p), positive-part loadings `Λc`
(p×K), the shared shape `α` (`Var = μ²/α`), the maximised `loglik`, `converged`,
and `iterations`. (`Λz = 0` — occurrence is intercept-only in v1.)
"""
struct DeltaGammaFit
    βz::Vector{Float64}
    βc::Vector{Float64}
    Λc::Matrix{Float64}
    α::Float64
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::DeltaGammaFit)
    p, K = size(f.Λc)
    print(io, "DeltaGammaFit(p=", p, ", K=", K, ", α=", round(f.α; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_delta_gamma_gllvm(Y; K, …) -> DeltaGammaFit

Fit a Delta-Gamma two-part GLLVM by L-BFGS over `[βz; βc; vec(Λc); log α]` on the
two-part Laplace marginal ([`delta_gamma_marginal_loglik_laplace`](@ref)), with
`Λz = 0` (per-species occurrence intercept), jointly estimating the shape `α`. `Y`
is p×n with `0` for absences and positive reals otherwise. Finite-difference
gradient; warm start = `logit(empirical P(y>0))` occurrence intercepts + `log` mean
positive value as log-mean intercepts + SVD of positive-part log-residuals as
loadings + a method-of-moments `α₀` from the standardised positives.
"""
function fit_delta_gamma_gllvm(Y::AbstractMatrix{<:Real}; K::Integer,
        offset = nothing,
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
        βc0[t] = c == 0 ? 0.0 : log(max(s / c, 1e-6))
    end
    # method-of-moments shape from standardised positives r = y/μ̂ (mean≈1, Var≈1/α)
    sumsq = 0.0; nres = 0
    @inbounds for t in 1:p
        μt = exp(βc0[t])
        for j in 1:n
            if Y[t, j] > 0
                r = Y[t, j] / μt - 1.0; sumsq += r^2; nres += 1
            end
        end
    end
    α0 = nres > 1 ? clamp((nres - 1) / sumsq, 0.1, 100.0) : 1.0
    Zc = [Y[t, j] > 0 ? log(max(Y[t, j], 1e-6)) - βc0[t] : 0.0 for t in 1:p, j in 1:n]
    # Offset (on the positive-part predictor η^c = β^c + offset + Λ^c z): remove it
    # from the loadings warm start so the SVD sees the offset-free residual.
    offset === nothing || (@inbounds for t in 1:p, j in 1:n
        Y[t, j] > 0 && (Zc[t, j] -= offset[t, j])
    end)
    F = svd(Zc); kk = min(K, length(F.S))
    Λc0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λc0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end

    θ0 = vcat(βz0, βc0, pack_lambda(Λc0), log(α0))
    function negll(θ)
        βz = θ[1:p]; βc = θ[(p + 1):(2p)]
        Λc = unpack_lambda(θ[(2p + 1):(2p + rr)], p, K)
        α = exp(θ[2p + rr + 1])
        v = try
            -delta_gamma_marginal_loglik_laplace(Y, Λc, βz, βc, α; offsetc = offset,
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
    α = exp(θ̂[2p + rr + 1])
    return DeltaGammaFit(βz, βc, Λc, α, -Optim.minimum(res),
                         Optim.converged(res), Optim.iterations(res))
end

# ===========================================================================
# Zero-inflated families (ZIP / ZINB) — MIXTURE, not hurdle.
#
# A zero is produced by EITHER a structural-zero process (prob π) OR the count
# process (prob 1−π times the count's own P(0)):
#     P(y=0) = π + (1−π)·p₀,   P(y=k) = (1−π)·count(k)   (k ≥ 1)
# with π = logistic(η^z) and the count mean μ = exp(η^c). Unlike the hurdle
# families the count process is "active" at every observation, so a y=0 carries
# count-part information — its score s^c and Fisher weight W^cc are non-zero.
#
# These DO couple η^z and η^c at y=0 (∂²logf/∂η^z∂η^c ≠ 0). In the v1 convention
# the zero-inflation is per-species intercept-only (Λ_z = 0 — only β^z), so the
# latent z enters ONLY through η^c; the cross-term is multiplied by Λ_z = 0 in
# the shared-z mode-finder and drops out. The integral over z is therefore the
# same K-dimensional Laplace as the hurdle path, and these slot straight onto the
# existing `_tp_pieces` / `_twopart_mode` substrate — provided we supply the
# count-part score s^c, the *expected* Fisher information W^cc (≥ 0 ⇒ SPD), and
# the zero-inflated log-density. (Letting Λ_z load on z would need the 2×2
# cross-term machinery; that is a deliberate future extension.)
#
# W^cc is the expected information E[(s^c)²] in closed form (verified: ZIP → the
# Poisson weight μ as π → 0, ZINB → ZIP as r → ∞).
# ---------------------------------------------------------------------------

# Count-part expected information E[(∂logf/∂η^c)²] for the zero-inflated Poisson.
function _zi_Icc_pois(π, μ)
    e = exp(-μ); P0 = π + (one(π) - π) * e
    Icc = (one(π) - π) * (μ - e * μ^2) + (one(π) - π)^2 * e^2 * μ^2 / P0
    return max(Icc, 1e-12)
end

# Count-part expected information for the zero-inflated NB2 (dispersion r).
function _zi_Icc_nb(π, μ, r)
    p0 = (r / (r + μ))^r
    P0 = π + (one(π) - π) * p0
    Inb = μ * r / (r + μ)                    # = μ / (1 + μ/r), the NB2 info
    c = (r * μ / (r + μ))^2
    Icc = (one(π) - π) * (Inb - π * p0 * c / P0)
    return max(Icc, 1e-12)
end

"""
    ZIPoisson()

Marker for the zero-inflated Poisson family (structural zero prob `π=logistic(η^z)`
mixed with a Poisson count, mean `μ=exp(η^c)`).
"""
struct ZIPoisson end

function _tp_pieces(::ZIPoisson, y, ηz, ηc)
    π = inv(one(ηz) + exp(-ηz))
    μ = exp(ηc)
    Wz = π * (one(π) - π)                     # zero-inflation Fisher weight (unused: Λ_z = 0)
    Wcc = _zi_Icc_pois(π, μ)
    if y > 0
        return (-π, y - μ, Wz, Wcc, log1p(-π) + logpdf(Poisson(μ), Int(y)))
    else
        e = exp(-μ)
        P0 = π + (one(π) - π) * e
        g = (one(π) - π) * e / P0             # posterior P(count-zero | y=0)
        sz = π * (one(π) - π) * (one(π) - e) / P0
        return (sz, -g * μ, Wz, Wcc, log(P0))
    end
end

"""
    zip_marginal_loglik_laplace(Y, Λc, βz, βc; Λz=nothing, kwargs...) -> Float64

Two-part Laplace log-marginal for a zero-inflated Poisson GLLVM (structural-zero
`π=logistic(β^z)`, intercept-only by default; Poisson count with `μ=exp(β^c+Λ_c z)`).
`Y` is p×n integer counts. `Λc=0` ⇒ exact independent ZIP loglik; `β^z→−∞` ⇒ the
Poisson marginal.
"""
function zip_marginal_loglik_laplace(Y::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector;
        Λz::Union{Nothing, AbstractMatrix} = nothing, kwargs...)
    p, K = size(Λc)
    Λz_ = Λz === nothing ? zeros(p, K) : Λz
    return twopart_marginal_loglik_laplace(ZIPoisson(), Y, Λz_, Λc, βz, βc; kwargs...)
end

"""
    ZIPFit

Result of [`fit_zip_gllvm`](@ref): structural-zero logits `βz`, count log-mean
intercepts `βc`, count loadings `Λc`, `loglik`, `converged`, `iterations`.
"""
struct ZIPFit
    βz::Vector{Float64}
    βc::Vector{Float64}
    Λc::Matrix{Float64}
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::ZIPFit)
    p, K = size(f.Λc)
    print(io, "ZIPFit(p=", p, ", K=", K,
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

# Shared warm start for zero-inflated count fits: structural-zero logits from the
# excess-zero fraction, count log-mean from the positive counts, SVD loadings.
function _zi_warmstart(Y::AbstractMatrix, K::Integer)
    p, n = size(Y)
    βz0 = Vector{Float64}(undef, p); βc0 = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        nz = count(==(0), view(Y, t, :))
        propzero = nz / n
        s = 0.0; c = 0
        for j in 1:n
            if Y[t, j] > 0
                s += Y[t, j]; c += 1
            end
        end
        μ̂ = c == 0 ? 1.0 : max(s / c, 1.0)
        βc0[t] = log(μ̂)
        excess = clamp(propzero - exp(-μ̂), 1e-3, 0.8)   # structural-zero share
        βz0[t] = log(excess / (1 - excess))
    end
    Zc = [Y[t, j] > 0 ? log(max(Y[t, j], 0.5)) - βc0[t] : 0.0 for t in 1:p, j in 1:n]
    F = svd(Zc); kk = min(K, length(F.S))
    Λc0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λc0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    return βz0, βc0, Λc0
end

"""
    fit_zip_gllvm(Y; K, …) -> ZIPFit

Fit a zero-inflated Poisson GLLVM by L-BFGS over `[βz; βc; vec(Λc)]` (Λz=0).
`Y` p×n integer counts. Finite-difference gradient; warm start from the
excess-zero fraction + positive-count log-means + SVD loadings.
"""
function fit_zip_gllvm(Y::AbstractMatrix{<:Real}; K::Integer,
        offset = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)
    βz0, βc0, Λc0 = _zi_warmstart(Y, K)
    θ0 = vcat(βz0, βc0, pack_lambda(Λc0))
    function negll(θ)
        βz = θ[1:p]; βc = θ[(p + 1):(2p)]
        Λc = unpack_lambda(θ[(2p + 1):(2p + rr)], p, K)
        v = try
            -zip_marginal_loglik_laplace(Y, Λc, βz, βc; offsetc = offset,
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
    return ZIPFit(βz, βc, Λc, -Optim.minimum(res),
                  Optim.converged(res), Optim.iterations(res))
end

# ---------------------------------------------------------------------------
# Zero-inflated NB (ZINB) — structural zero × NB2 count with shared dispersion r.
# ---------------------------------------------------------------------------

"""
    ZINB(r)

Marker for the zero-inflated NB2 family (structural zero prob `π=logistic(η^z)`
mixed with an NB2 count, mean `μ=exp(η^c)`, dispersion `r`). `r→∞ ⇒ ZIP`.
"""
struct ZINB
    r::Float64
end

function _tp_pieces(f::ZINB, y, ηz, ηc)
    π = inv(one(ηz) + exp(-ηz))
    μ = exp(ηc); r = f.r
    Wz = π * (one(π) - π)
    Wcc = _zi_Icc_nb(π, μ, r)
    if y > 0
        sc = r * (y - μ) / (r + μ)
        logf = log1p(-π) + logpdf(NegativeBinomial(r, r / (r + μ)), Int(y))
        return (-π, sc, Wz, Wcc, logf)
    else
        p0 = (r / (r + μ))^r
        P0 = π + (one(π) - π) * p0
        g = (one(π) - π) * p0 / P0
        sz = π * (one(π) - π) * (one(π) - p0) / P0
        return (sz, -g * r * μ / (r + μ), Wz, Wcc, log(P0))
    end
end

"""
    zinb_marginal_loglik_laplace(Y, Λc, βz, βc, r; Λz=nothing, kwargs...) -> Float64

Two-part Laplace log-marginal for a zero-inflated NB2 GLLVM. `Λc=0` ⇒ exact
independent ZINB loglik; `r→∞` ⇒ the ZIP marginal.
"""
function zinb_marginal_loglik_laplace(Y::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector, r::Real;
        Λz::Union{Nothing, AbstractMatrix} = nothing, kwargs...)
    p, K = size(Λc)
    Λz_ = Λz === nothing ? zeros(p, K) : Λz
    return twopart_marginal_loglik_laplace(ZINB(float(r)), Y, Λz_, Λc, βz, βc; kwargs...)
end

"""
    ZINBFit

Result of [`fit_zinb_gllvm`](@ref): `βz`, `βc`, `Λc`, dispersion `r`, `loglik`,
`converged`, `iterations`.
"""
struct ZINBFit
    βz::Vector{Float64}
    βc::Vector{Float64}
    Λc::Matrix{Float64}
    r::Float64
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::ZINBFit)
    p, K = size(f.Λc)
    print(io, "ZINBFit(p=", p, ", K=", K, ", r=", round(f.r; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_zinb_gllvm(Y; K, …) -> ZINBFit

Fit a zero-inflated NB2 GLLVM by L-BFGS over `[βz; βc; vec(Λc); log r]` (Λz=0).
"""
function fit_zinb_gllvm(Y::AbstractMatrix{<:Real}; K::Integer,
        offset = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)
    βz0, βc0, Λc0 = _zi_warmstart(Y, K)
    θ0 = vcat(βz0, βc0, pack_lambda(Λc0), log(10.0))
    function negll(θ)
        βz = θ[1:p]; βc = θ[(p + 1):(2p)]
        Λc = unpack_lambda(θ[(2p + 1):(2p + rr)], p, K)
        r = exp(θ[2p + rr + 1])
        v = try
            -zinb_marginal_loglik_laplace(Y, Λc, βz, βc, r; offsetc = offset,
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
    r = exp(θ̂[2p + rr + 1])
    return ZINBFit(βz, βc, Λc, r, -Optim.minimum(res),
                   Optim.converged(res), Optim.iterations(res))
end

# ---------------------------------------------------------------------------
# Zero-inflated binomial (ZIB) — structural zero × Binomial(N, μ) count, with
# μ = logistic(η^c) and a shared scalar number of trials N. π → 0 ⇒ plain
# Binomial; N = 1 is the zero-inflated Bernoulli. Mirrors the ZINB substrate:
# the count-zero score magnitude rμ/(r+μ) is replaced by Nμ, and the NB2 count
# info μr/(r+μ) by the binomial-logit info Nμ(1−μ).
# ---------------------------------------------------------------------------

# Count-part expected information E[(∂logf/∂η^c)²] for the zero-inflated binomial
# (N trials, μ = success prob). As π → 0 this → Nμ(1−μ), the binomial-logit info.
function _zi_Icc_binom(π, μ, N)
    p0 = (one(μ) - μ)^N
    P0 = π + (one(π) - π) * p0
    Ibin = N * μ * (one(μ) - μ)              # = Nμ(1−μ), the binomial-logit info
    c = (N * μ)^2
    Icc = (one(π) - π) * (Ibin - π * p0 * c / P0)
    return max(Icc, 1e-12)
end

"""
    ZIB(N)

Marker for the zero-inflated binomial family: structural zero prob
`π = logistic(η^z)` mixed with a `Binomial(N, μ)` count, success probability
`μ = logistic(η^c)`, shared number of trials `N`. `π → 0 ⇒` plain Binomial;
`N = 1` is the zero-inflated Bernoulli.
"""
struct ZIB
    N::Int
end

function _tp_pieces(f::ZIB, y, ηz, ηc)
    π = inv(one(ηz) + exp(-ηz))
    μ = inv(one(ηc) + exp(-ηc))              # logit link for the count part
    N = f.N
    Wz = π * (one(π) - π)
    Wcc = _zi_Icc_binom(π, μ, N)
    if y > 0
        sc = y - N * μ
        logf = log1p(-π) + logpdf(Binomial(N, μ), Int(y))
        return (-π, sc, Wz, Wcc, logf)
    else
        p0 = (one(μ) - μ)^N
        P0 = π + (one(π) - π) * p0
        g = (one(π) - π) * p0 / P0           # posterior P(binomial-zero | y=0)
        sz = π * (one(π) - π) * (one(π) - p0) / P0
        return (sz, -g * N * μ, Wz, Wcc, log(P0))
    end
end

"""
    zib_marginal_loglik_laplace(Y, Λc, βz, βc, N; Λz=nothing, kwargs...) -> Float64

Two-part Laplace log-marginal for a zero-inflated binomial GLLVM (`N` trials).
`Y` is p×n with counts in `0:N`. `Λc = 0` ⇒ exact independent ZIB loglik;
`β^z → −∞` ⇒ the plain Binomial marginal.
"""
function zib_marginal_loglik_laplace(Y::AbstractMatrix, Λc::AbstractMatrix,
        βz::AbstractVector, βc::AbstractVector, N::Integer;
        Λz::Union{Nothing, AbstractMatrix} = nothing, kwargs...)
    p, K = size(Λc)
    Λz_ = Λz === nothing ? zeros(p, K) : Λz
    return twopart_marginal_loglik_laplace(ZIB(Int(N)), Y, Λz_, Λc, βz, βc; kwargs...)
end

"""
    ZIBFit

Result of [`fit_zib_gllvm`](@ref): structural-zero logits `βz`, count success-logit
intercepts `βc`, count loadings `Λc`, the shared number of trials `N`, `loglik`,
`converged`, `iterations`.
"""
struct ZIBFit
    βz::Vector{Float64}
    βc::Vector{Float64}
    Λc::Matrix{Float64}
    N::Int
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::ZIBFit)
    p, K = size(f.Λc)
    print(io, "ZIBFit(p=", p, ", K=", K, ", N=", f.N,
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

# Warm start for the zero-inflated binomial fit: success-logit intercept from the
# positive-part success fraction, structural-zero logit from the excess-zero share
# (over the binomial-zero rate), SVD loadings of the logit residuals.
function _zib_warmstart(Y::AbstractMatrix, N::Integer, K::Integer)
    p, n = size(Y)
    βz0 = Vector{Float64}(undef, p); βc0 = Vector{Float64}(undef, p)
    _logit(x) = (xx = clamp(x, 1e-3, 1 - 1e-3); log(xx / (1 - xx)))
    @inbounds for t in 1:p
        propzero = count(==(0), view(Y, t, :)) / n
        s = 0.0; c = 0
        for j in 1:n
            if Y[t, j] > 0
                s += Y[t, j] / N; c += 1
            end
        end
        μ̂ = c == 0 ? 1.0 / N : clamp(s / c, 1e-3, 1 - 1e-3)
        βc0[t] = _logit(μ̂)
        excess = clamp(propzero - (1 - μ̂)^N, 1e-3, 0.8)
        βz0[t] = log(excess / (1 - excess))
    end
    Zc = [Y[t, j] > 0 ? _logit(Y[t, j] / N) - βc0[t] : 0.0 for t in 1:p, j in 1:n]
    F = svd(Zc); kk = min(K, length(F.S))
    Λc0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λc0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    return βz0, βc0, Λc0
end

"""
    fit_zib_gllvm(Y; K, N, …) -> ZIBFit

Fit a zero-inflated binomial GLLVM by L-BFGS over `[βz; βc; vec(Λc)]` (Λz=0),
with a shared number of trials `N`. `Y` p×n with counts in `0:N`. Finite-difference
gradient; warm start from the excess-zero share + positive-part success logits +
SVD loadings.
"""
function fit_zib_gllvm(Y::AbstractMatrix{<:Real}; K::Integer, N::Integer,
        offset = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)
    βz0, βc0, Λc0 = _zib_warmstart(Y, N, K)
    θ0 = vcat(βz0, βc0, pack_lambda(Λc0))
    function negll(θ)
        βz = θ[1:p]; βc = θ[(p + 1):(2p)]
        Λc = unpack_lambda(θ[(2p + 1):(2p + rr)], p, K)
        v = try
            -zib_marginal_loglik_laplace(Y, Λc, βz, βc, N; offsetc = offset,
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
    return ZIBFit(βz, βc, Λc, Int(N), -Optim.minimum(res),
                  Optim.converged(res), Optim.iterations(res))
end
