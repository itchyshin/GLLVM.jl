# Confidence intervals for the non-Gaussian (Laplace) family fitters.
#
# The Gaussian path (src/confint.jl / confint_profile.jl / confint_bootstrap.jl)
# is tightly coupled to GllvmFit and the legacy θ_packed layout. The family
# fitters (Poisson / Binomial / NB / Beta / Gamma) each carry their own struct
# and a `[β; pack_lambda(Λ); (log-dispersion)]` working vector, so this file
# provides a SINGLE generic CI layer over a small per-family adapter, exposing
# all three R-style methods through one entry point:
#
#     confint(fit, Y; method = :wald | :profile | :bootstrap, ...)
#
# - :wald      — observed-information (finite-difference Hessian) → inv → SEs →
#                θ̂ ± z·SE, with an exp() back-transform for log-scale dispersion.
# - :profile   — invert the LRT: D(c) = 2(ℓ̂ − ℓ_p(c)) ~ χ²₁; bracket-then-bisect
#                each side (reuses `_profile_bisect_side` from confint_profile.jl).
# - :bootstrap — parametric: simulate Yᵇ ~ fitted model, refit, take percentiles.
#                Embarrassingly parallel — `parallel = true` runs the replicates
#                over `Threads.@threads`; each replicate seeds its own RNG
#                (`seed + b`) so results are independent of thread scheduling
#                (identical single- vs multi-core).
#
# The family fitters use finite-difference gradients (the Laplace inner
# mode-finder is not forward-AD-friendly), so the Hessian here is a
# central-difference one rather than ForwardDiff — consistent with how the
# fitters themselves are optimised.

using Distributions: Normal, Chisq, quantile
using Random: AbstractRNG, MersenneTwister, randn

# Families handled by this layer (single latent block, optional scalar dispersion).
const _FamilyFit = Union{PoissonFit, BinomialFit, NBFit, BetaFit, GammaFit}

# Two-part families ([βz; βc; pack_lambda(Λc); (log-dispersion)] layout).
const _TwoPartFit = Union{DeltaLogNormalFit, DeltaGammaFit, HurdlePoissonFit,
                          HurdleNBFit, ZIPFit, ZINBFit}

# Everything the unified confint(fit, Y; method=…) entry accepts.
const _CIFit = Union{_FamilyFit, _TwoPartFit}

# ---------------------------------------------------------------------------
# Per-family adapter. Bundles everything the generic routines need:
#   θ        — MLE working vector (matches the fitter's negll layout)
#   nll      — negative Laplace log-likelihood as a function of that vector
#   names    — term names in θ order
#   kinds    — :linear (β, Λ) or :log (a log-scale dispersion: r / φ / α)
#   simulate — rng -> Yᵇ (a fresh parametric draw from the fitted model)
#   refit    — Yᵇ -> working vector θ̂ᵇ (or `nothing` on refit failure)
# ---------------------------------------------------------------------------
struct _FamilyCI
    θ::Vector{Float64}
    nll::Function
    names::Vector{String}
    kinds::Vector{Symbol}
    simulate::Function
    refit::Function
end

# Shared GLM term names: β[t] for t in 1:p, then Λ[i,k] in pack_lambda order.
_glm_lin_names(p::Integer, K::Integer) =
    vcat(["beta[$t]" for t in 1:p], _confint_lambda_term_names("Lambda", p, K))

# --- Poisson ---------------------------------------------------------------
function _family_ci(fit::PoissonFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    θ = vcat(fit.β, pack_lambda(fit.Λ))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        v = try
            -poisson_marginal_loglik_laplace(Y, Λ, β, link; maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = rng -> _glm_simulate_counts(rng, fit.β, fit.Λ, link, n,
                                           (r, μ) -> Poisson(max(μ, 1e-12)))
    refit = function (Yb)
        fb = try fit_poisson_gllvm(Yb; K = K, link = link) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ))
    end
    return _FamilyCI(θ, nll, _glm_lin_names(p, K), fill(:linear, length(θ)), simulate, refit)
end

# --- Binomial --------------------------------------------------------------
function _family_ci(fit::BinomialFit, Y::AbstractMatrix;
                    N::Union{Nothing, AbstractMatrix} = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    Nm = N === nothing ? fill(1, p, n) : Matrix{Int}(N)
    θ = vcat(fit.β, pack_lambda(fit.Λ))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        v = try
            -binomial_marginal_loglik_laplace(Y, Nm, Λ, β, link; maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = function (rng)
        Yb = Matrix{Int}(undef, p, n)
        @inbounds for s in 1:n
            η = fit.β .+ fit.Λ * randn(rng, K)
            for t in 1:p
                μ = clamp(linkinv(link, _clamp_eta(η[t])), 1e-12, 1 - 1e-12)
                Yb[t, s] = rand(rng, Binomial(Nm[t, s], μ))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_binomial_gllvm(Yb; K = K, link = link, N = Nm) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ))
    end
    return _FamilyCI(θ, nll, _glm_lin_names(p, K), fill(:linear, length(θ)), simulate, refit)
end

# --- Negative binomial -----------------------------------------------------
function _family_ci(fit::NBFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    θ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.r))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K); r = exp(θv[p + rr + 1])
        v = try
            -nb_marginal_loglik_laplace(Y, Λ, β, r; link = link, maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = rng -> _glm_simulate_counts(rng, fit.β, fit.Λ, link, n,
                                           (rg, μ) -> (m = max(μ, 1e-12); NegativeBinomial(fit.r, fit.r / (fit.r + m))))
    refit = function (Yb)
        fb = try fit_nb_gllvm(Yb; K = K, link = link) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log(fb.r))
    end
    names = vcat(_glm_lin_names(p, K), "r")
    kinds = vcat(fill(:linear, length(θ) - 1), :log)
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

# --- Beta ------------------------------------------------------------------
function _family_ci(fit::BetaFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    θ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.φ))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K); φ = exp(θv[p + rr + 1])
        v = try
            -beta_marginal_loglik_laplace(Y, Λ, β, φ; link = link, maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = function (rng)
        Yb = Matrix{Float64}(undef, p, n); φ = fit.φ
        @inbounds for s in 1:n
            η = fit.β .+ fit.Λ * randn(rng, K)
            for t in 1:p
                μ = clamp(linkinv(link, _clamp_eta(η[t])), 1e-6, 1 - 1e-6)
                Yb[t, s] = clamp(rand(rng, Beta(μ * φ, (1 - μ) * φ)), 1e-6, 1 - 1e-6)
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_beta_gllvm(Yb; K = K, link = link) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log(fb.φ))
    end
    names = vcat(_glm_lin_names(p, K), "phi")
    kinds = vcat(fill(:linear, length(θ) - 1), :log)
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

# --- Gamma -----------------------------------------------------------------
function _family_ci(fit::GammaFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    θ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.α))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K); α = exp(θv[p + rr + 1])
        v = try
            -gamma_marginal_loglik_laplace(Y, Λ, β, α; link = link, maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = function (rng)
        Yb = Matrix{Float64}(undef, p, n); α = fit.α
        @inbounds for s in 1:n
            η = fit.β .+ fit.Λ * randn(rng, K)
            for t in 1:p
                μ = max(linkinv(link, _clamp_eta(η[t])), 1e-12)
                Yb[t, s] = rand(rng, Gamma(α, μ / α))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_gamma_gllvm(Yb; K = K, link = link) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log(fb.α))
    end
    names = vcat(_glm_lin_names(p, K), "alpha")
    kinds = vcat(fill(:linear, length(θ) - 1), :log)
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

# Count-family simulation (Poisson / NB share the loop; `make` builds the
# per-cell Distributions sampler from (rng, μ)).
function _glm_simulate_counts(rng::AbstractRNG, β::AbstractVector, Λ::AbstractMatrix,
                              link::Link, n::Integer, make)
    p, K = size(Λ)
    Yb = Matrix{Int}(undef, p, n)
    @inbounds for s in 1:n
        η = β .+ Λ * randn(rng, K)
        for t in 1:p
            μ = linkinv(link, _clamp_eta(η[t]))
            Yb[t, s] = rand(rng, make(rng, μ))
        end
    end
    return Yb
end

# ---------------------------------------------------------------------------
# Two-part family adapters. Shared layout [βz; βc; pack_lambda(Λc); (log-disp)];
# βz are occurrence/zero-inflation logits, βc the positive/count log-(or log-mean)
# intercepts. `make_nll` closes over the family's marginal; `sim` draws Yᵇ; `refit`
# returns the working vector or `nothing`.
# ---------------------------------------------------------------------------
_twopart_lin_names(p::Integer, K::Integer) =
    vcat(["betaz[$t]" for t in 1:p], ["betac[$t]" for t in 1:p],
         _confint_lambda_term_names("Lambda", p, K))

# Zero-truncated count samplers (rejection; rare fall-through returns 1).
function _rand_ztpois(rng::AbstractRNG, μ)
    d = Poisson(max(μ, 1e-12))
    for _ in 1:10_000
        y = rand(rng, d); y > 0 && return y
    end
    return 1
end
function _rand_ztnb(rng::AbstractRNG, r, μ)
    d = NegativeBinomial(r, r / (r + max(μ, 1e-12)))
    for _ in 1:10_000
        y = rand(rng, d); y > 0 && return y
    end
    return 1
end

# --- Delta-lognormal -------------------------------------------------------
function _family_ci(fit::DeltaLogNormalFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λc); n = size(Y, 2); rr = rr_theta_len(p, K)
    θ = vcat(fit.βz, fit.βc, pack_lambda(fit.Λc), log(fit.σ))
    nll = function (θv)
        βz = θv[1:p]; βc = θv[(p + 1):(2p)]
        Λc = unpack_lambda(θv[(2p + 1):(2p + rr)], p, K); σ = exp(θv[2p + rr + 1])
        v = try
            -delta_lognormal_marginal_loglik_laplace(Y, Λc, βz, βc, σ; maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    sim = function (rng)
        Yb = zeros(Float64, p, n)
        @inbounds for s in 1:n
            ηc = fit.βc .+ fit.Λc * randn(rng, K)
            for t in 1:p
                π = inv(1 + exp(-fit.βz[t]))
                rand(rng) < π && (Yb[t, s] = exp(ηc[t] + fit.σ * randn(rng)))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_delta_lognormal_gllvm(Yb; K = K) catch; return nothing end
        return vcat(fb.βz, fb.βc, pack_lambda(fb.Λc), log(fb.σ))
    end
    names = vcat(_twopart_lin_names(p, K), "sigma")
    return _FamilyCI(θ, nll, names, vcat(fill(:linear, length(θ) - 1), :log), sim, refit)
end

# --- Delta-Gamma -----------------------------------------------------------
function _family_ci(fit::DeltaGammaFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λc); n = size(Y, 2); rr = rr_theta_len(p, K)
    θ = vcat(fit.βz, fit.βc, pack_lambda(fit.Λc), log(fit.α))
    nll = function (θv)
        βz = θv[1:p]; βc = θv[(p + 1):(2p)]
        Λc = unpack_lambda(θv[(2p + 1):(2p + rr)], p, K); α = exp(θv[2p + rr + 1])
        v = try
            -delta_gamma_marginal_loglik_laplace(Y, Λc, βz, βc, α; maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    sim = function (rng)
        Yb = zeros(Float64, p, n)
        @inbounds for s in 1:n
            ηc = fit.βc .+ fit.Λc * randn(rng, K)
            for t in 1:p
                π = inv(1 + exp(-fit.βz[t]))
                if rand(rng) < π
                    μ = exp(ηc[t]); Yb[t, s] = rand(rng, Gamma(fit.α, μ / fit.α))
                end
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_delta_gamma_gllvm(Yb; K = K) catch; return nothing end
        return vcat(fb.βz, fb.βc, pack_lambda(fb.Λc), log(fb.α))
    end
    names = vcat(_twopart_lin_names(p, K), "alpha")
    return _FamilyCI(θ, nll, names, vcat(fill(:linear, length(θ) - 1), :log), sim, refit)
end

# --- Hurdle-Poisson --------------------------------------------------------
function _family_ci(fit::HurdlePoissonFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λc); n = size(Y, 2); rr = rr_theta_len(p, K)
    θ = vcat(fit.βz, fit.βc, pack_lambda(fit.Λc))
    nll = function (θv)
        βz = θv[1:p]; βc = θv[(p + 1):(2p)]
        Λc = unpack_lambda(θv[(2p + 1):(2p + rr)], p, K)
        v = try
            -hurdle_poisson_marginal_loglik_laplace(Y, Λc, βz, βc; maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    sim = function (rng)
        Yb = zeros(Int, p, n)
        @inbounds for s in 1:n
            ηc = fit.βc .+ fit.Λc * randn(rng, K)
            for t in 1:p
                π = inv(1 + exp(-fit.βz[t]))
                rand(rng) < π && (Yb[t, s] = _rand_ztpois(rng, exp(ηc[t])))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_hurdle_poisson_gllvm(Yb; K = K) catch; return nothing end
        return vcat(fb.βz, fb.βc, pack_lambda(fb.Λc))
    end
    return _FamilyCI(θ, nll, _twopart_lin_names(p, K), fill(:linear, length(θ)), sim, refit)
end

# --- Hurdle-NB -------------------------------------------------------------
function _family_ci(fit::HurdleNBFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λc); n = size(Y, 2); rr = rr_theta_len(p, K)
    θ = vcat(fit.βz, fit.βc, pack_lambda(fit.Λc), log(fit.r))
    nll = function (θv)
        βz = θv[1:p]; βc = θv[(p + 1):(2p)]
        Λc = unpack_lambda(θv[(2p + 1):(2p + rr)], p, K); r = exp(θv[2p + rr + 1])
        v = try
            -hurdle_nb_marginal_loglik_laplace(Y, Λc, βz, βc, r; maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    sim = function (rng)
        Yb = zeros(Int, p, n)
        @inbounds for s in 1:n
            ηc = fit.βc .+ fit.Λc * randn(rng, K)
            for t in 1:p
                π = inv(1 + exp(-fit.βz[t]))
                rand(rng) < π && (Yb[t, s] = _rand_ztnb(rng, fit.r, exp(ηc[t])))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_hurdle_nb_gllvm(Yb; K = K) catch; return nothing end
        return vcat(fb.βz, fb.βc, pack_lambda(fb.Λc), log(fb.r))
    end
    names = vcat(_twopart_lin_names(p, K), "r")
    return _FamilyCI(θ, nll, names, vcat(fill(:linear, length(θ) - 1), :log), sim, refit)
end

# --- Zero-inflated Poisson -------------------------------------------------
function _family_ci(fit::ZIPFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λc); n = size(Y, 2); rr = rr_theta_len(p, K)
    θ = vcat(fit.βz, fit.βc, pack_lambda(fit.Λc))
    nll = function (θv)
        βz = θv[1:p]; βc = θv[(p + 1):(2p)]
        Λc = unpack_lambda(θv[(2p + 1):(2p + rr)], p, K)
        v = try
            -zip_marginal_loglik_laplace(Y, Λc, βz, βc; maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    sim = function (rng)
        Yb = zeros(Int, p, n)
        @inbounds for s in 1:n
            ηc = fit.βc .+ fit.Λc * randn(rng, K)
            for t in 1:p
                π = inv(1 + exp(-fit.βz[t]))
                Yb[t, s] = rand(rng) < π ? 0 : rand(rng, Poisson(exp(ηc[t])))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_zip_gllvm(Yb; K = K) catch; return nothing end
        return vcat(fb.βz, fb.βc, pack_lambda(fb.Λc))
    end
    return _FamilyCI(θ, nll, _twopart_lin_names(p, K), fill(:linear, length(θ)), sim, refit)
end

# --- Zero-inflated NB ------------------------------------------------------
function _family_ci(fit::ZINBFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λc); n = size(Y, 2); rr = rr_theta_len(p, K)
    θ = vcat(fit.βz, fit.βc, pack_lambda(fit.Λc), log(fit.r))
    nll = function (θv)
        βz = θv[1:p]; βc = θv[(p + 1):(2p)]
        Λc = unpack_lambda(θv[(2p + 1):(2p + rr)], p, K); r = exp(θv[2p + rr + 1])
        v = try
            -zinb_marginal_loglik_laplace(Y, Λc, βz, βc, r; maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    sim = function (rng)
        Yb = zeros(Int, p, n)
        @inbounds for s in 1:n
            ηc = fit.βc .+ fit.Λc * randn(rng, K)
            for t in 1:p
                π = inv(1 + exp(-fit.βz[t])); μ = exp(ηc[t])
                Yb[t, s] = rand(rng) < π ? 0 : rand(rng, NegativeBinomial(fit.r, fit.r / (fit.r + μ)))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_zinb_gllvm(Yb; K = K) catch; return nothing end
        return vcat(fb.βz, fb.βc, pack_lambda(fb.Λc), log(fb.r))
    end
    names = vcat(_twopart_lin_names(p, K), "r")
    return _FamilyCI(θ, nll, names, vcat(fill(:linear, length(θ) - 1), :log), sim, refit)
end

# ---------------------------------------------------------------------------
# Generic numerics
# ---------------------------------------------------------------------------

# Central-difference Hessian of `f` at `x`. Step ∝ eps^(1/4) (the optimum for
# the 3-point second derivative, balancing O(h²) truncation against O(eps/h²)
# rounding). O(m²) function evaluations.
function _fd_hessian(f, x::AbstractVector)
    m = length(x)
    h = [eps()^(1 / 4) * max(abs(x[i]), 1.0) for i in 1:m]
    H = Matrix{Float64}(undef, m, m)
    f0 = f(x)
    @inbounds for i in 1:m
        xp = copy(x); xp[i] += h[i]
        xm = copy(x); xm[i] -= h[i]
        H[i, i] = (f(xp) - 2f0 + f(xm)) / h[i]^2
    end
    @inbounds for i in 1:m, j in (i + 1):m
        xpp = copy(x); xpp[i] += h[i]; xpp[j] += h[j]
        xpm = copy(x); xpm[i] += h[i]; xpm[j] -= h[j]
        xmp = copy(x); xmp[i] -= h[i]; xmp[j] += h[j]
        xmm = copy(x); xmm[i] -= h[i]; xmm[j] -= h[j]
        H[i, j] = H[j, i] = (f(xpp) - f(xpm) - f(xmp) + f(xmm)) / (4 * h[i] * h[j])
    end
    return H
end

# Resolve a `parm` selector against the term names. `nothing` → all; an exact
# name, a group prefix ("beta", "Lambda"), a dispersion name ("r"/"phi"/"alpha"),
# or a vector of any of these.
function _family_select(parm, names::Vector{String})
    parm === nothing && return collect(eachindex(names))
    sels = parm isa AbstractVector ? parm : [parm]
    idx = Int[]
    for s in sels
        ss = String(s)
        exact = findall(==(ss), names)
        if !isempty(exact)
            append!(idx, exact)
        elseif ss in ("beta", "Lambda")
            pref = ss == "beta" ? "beta[" : "Lambda["
            append!(idx, findall(n -> startswith(n, pref), names))
        else
            grp = findall(n -> startswith(n, ss), names)
            isempty(grp) && throw(ArgumentError("parm selector \"$ss\" matched no terms"))
            append!(idx, grp)
        end
    end
    return unique(idx)
end

# Natural-scale point estimate for entry i (exp() for log-scale dispersion).
_family_estimate(ad::_FamilyCI, i::Integer) = ad.kinds[i] === :log ? exp(ad.θ[i]) : ad.θ[i]

# ---------------------------------------------------------------------------
# Wald
# ---------------------------------------------------------------------------
function _family_wald(ad::_FamilyCI, sel::Vector{Int}, level::Real)
    m = length(ad.θ)
    H = _fd_hessian(ad.nll, ad.θ)
    pd = all(isfinite, H)
    se = fill(NaN, m)
    if pd
        Σ = try inv(Symmetric((H .+ H') ./ 2)) catch; nothing end
        if Σ === nothing
            pd = false
        else
            for i in 1:m
                v = Σ[i, i]
                (isfinite(v) && v > 0) ? (se[i] = sqrt(v)) : (pd = false)
            end
        end
    end
    z = quantile(Normal(), 0.5 + level / 2)
    term = String[]; est = Float64[]; lo = Float64[]; hi = Float64[]; ses = Float64[]
    for i in sel
        push!(term, ad.names[i]); push!(ses, se[i])
        θi = ad.θ[i]; sei = se[i]
        if ad.kinds[i] === :log
            push!(est, exp(θi))
            push!(lo, isfinite(sei) ? exp(θi - z * sei) : NaN)
            push!(hi, isfinite(sei) ? exp(θi + z * sei) : NaN)
        else
            push!(est, θi)
            push!(lo, isfinite(sei) ? θi - z * sei : NaN)
            push!(hi, isfinite(sei) ? θi + z * sei : NaN)
        end
    end
    return (term = term, estimate = est, lower = lo, upper = hi, se = ses,
            method = :wald, pd_hessian = pd)
end

# ---------------------------------------------------------------------------
# Profile likelihood
# ---------------------------------------------------------------------------

# Constrained refit: minimise nll over θ_{-i} with θ_i fixed at c. Returns
# (ℓ_profile, ok, θ_red_solution). Finite-difference gradient (nll is not
# AD-friendly through the Laplace mode-finder).
function _family_profile_refit(ad::_FamilyCI, i::Integer, c::Real, θ_red_warm::AbstractVector)
    m = length(ad.θ)
    cf = float(c)
    full = function (θr)
        θf = Vector{Float64}(undef, m)
        @inbounds for j in 1:(i - 1); θf[j] = θr[j]; end
        θf[i] = cf
        @inbounds for j in (i + 1):m; θf[j] = θr[j - 1]; end
        return θf
    end
    nll_red = θr -> ad.nll(full(θr))
    res = try
        Optim.optimize(nll_red, collect(Float64, θ_red_warm),
                       Optim.LBFGS(), Optim.Options(g_tol = 1e-4, iterations = 200);
                       autodiff = :finite)
    catch
        return (NaN, false, collect(Float64, θ_red_warm))
    end
    nmin = Optim.minimum(res)
    isfinite(nmin) || return (NaN, false, collect(Float64, θ_red_warm))
    return (-nmin, true, Optim.minimizer(res))
end

function _family_profile(ad::_FamilyCI, sel::Vector{Int}, level::Real)
    m = length(ad.θ)
    cutoff = quantile(Chisq(1), level)
    ll_full = -ad.nll(ad.θ)
    # Wald SEs to seed the bracket steps (cheap relative to the refits).
    H = _fd_hessian(ad.nll, ad.θ)
    se_all = fill(NaN, m)
    if all(isfinite, H)
        Σ = try inv(Symmetric((H .+ H') ./ 2)) catch; nothing end
        if Σ !== nothing
            for i in 1:m
                v = Σ[i, i]; (isfinite(v) && v > 0) && (se_all[i] = sqrt(v))
            end
        end
    end

    term = String[]; est = Float64[]; lo = Float64[]; hi = Float64[]; meth = Symbol[]
    for i in sel
        θi = float(ad.θ[i])
        sei = (isnan(se_all[i]) || se_all[i] ≤ 0) ? max(abs(θi) / 2, 0.1) : se_all[i]
        warm_lo = vcat(ad.θ[1:(i - 1)], ad.θ[(i + 1):m])
        warm_hi = copy(warm_lo)
        function dev_lo(c)
            ll, ok, sol = _family_profile_refit(ad, i, c, warm_lo)
            ok ? (warm_lo = sol; 2.0 * (ll_full - ll)) : NaN
        end
        function dev_hi(c)
            ll, ok, sol = _family_profile_refit(ad, i, c, warm_hi)
            ok ? (warm_hi = sol; 2.0 * (ll_full - ll)) : NaN
        end
        step = max(sei, 1e-3)
        lower = _profile_bisect_side(dev_lo, θi, -step, cutoff)
        upper = _profile_bisect_side(dev_hi, θi,  step, cutoff)
        if ad.kinds[i] === :log
            lower = isnan(lower) ? NaN : exp(lower)
            upper = isnan(upper) ? NaN : exp(upper)
        end
        push!(term, ad.names[i]); push!(est, _family_estimate(ad, i))
        push!(lo, lower); push!(hi, upper)
        push!(meth, (isnan(lower) && isnan(upper)) ? :failed :
                    (isnan(lower) || isnan(upper)) ? :partial : :profile)
    end
    return (term = term, estimate = est, lower = lo, upper = hi, status = meth, method = :profile)
end

# ---------------------------------------------------------------------------
# Parametric bootstrap (optionally threaded)
# ---------------------------------------------------------------------------
function _family_bootstrap(ad::_FamilyCI, sel::Vector{Int}, level::Real,
                           n_boot::Integer, seed::Integer, parallel::Bool)
    m = length(ad.θ)
    reps = fill(NaN, n_boot, m)
    ok = fill(false, n_boot)   # Vector{Bool} (one byte/elt) — safe for concurrent distinct-index writes (a BitVector is not)
    work = function (b)
        rng = MersenneTwister(seed + b)
        θb = ad.refit(ad.simulate(rng))
        if θb !== nothing && length(θb) == m && all(isfinite, θb)
            @inbounds reps[b, :] .= θb
            ok[b] = true
        end
        return nothing
    end
    if parallel
        Threads.@threads for b in 1:n_boot
            work(b)
        end
    else
        for b in 1:n_boot
            work(b)
        end
    end

    a = (1 - level) / 2
    term = String[]; est = Float64[]; lo = Float64[]; hi = Float64[]
    for i in sel
        col = Float64[]
        for b in 1:n_boot
            isnan(reps[b, i]) || push!(col, ad.kinds[i] === :log ? exp(reps[b, i]) : reps[b, i])
        end
        push!(term, ad.names[i]); push!(est, _family_estimate(ad, i))
        if length(col) ≥ 10
            push!(lo, quantile(col, a)); push!(hi, quantile(col, 1 - a))
        else
            push!(lo, NaN); push!(hi, NaN)
        end
    end
    return (term = term, estimate = est, lower = lo, upper = hi,
            n_converged = count(ok), method = :bootstrap)
end

# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------
"""
    confint(fit, Y; method = :wald, level = 0.95, parm = nothing, N = nothing,
            n_boot = 200, seed = 0, parallel = false,
            newton_maxiter = 100, newton_tol = 1e-9) -> NamedTuple

Confidence intervals for a non-Gaussian family GLLVM fit — the scalar-μ GLM
families (`PoissonFit`, `BinomialFit`, `NBFit`, `BetaFit`, `GammaFit`) and the
two-part families (`DeltaLogNormalFit`, `DeltaGammaFit`, `HurdlePoissonFit`,
`HurdleNBFit`, `ZIPFit`, `ZINBFit`). `Y` is the same response matrix passed to
the fitter; it is needed to reconstruct the marginal likelihood.

Term names are `beta[t]` / `Lambda[i,k]` (+ a dispersion `r`/`phi`/`alpha`) for
the GLM families, and `betaz[t]` (occurrence / zero-inflation logits) / `betac[t]`
(positive / count intercepts) / `Lambda[i,k]` (+ `sigma`/`alpha`/`r`) for the
two-part families.

`method` selects the inference:

  - `:wald`      — observed-information Wald intervals. The Hessian of the
                   negative Laplace log-likelihood is formed by central finite
                   differences at the MLE, inverted for the asymptotic
                   covariance. Returns an extra `pd_hessian::Bool`.
  - `:profile`   — profile-likelihood intervals: invert `D(c)=2(ℓ̂−ℓ_p(c)) ~ χ²₁`
                   by bracket-then-bisection on each side (a constrained refit
                   per candidate). Returns an extra per-term `status` vector
                   (`:profile` / `:partial` / `:failed`).
  - `:bootstrap` — parametric bootstrap: simulate `n_boot` datasets from the
                   fitted model, refit each, take percentile bounds. Set
                   `parallel = true` to run replicates over `Threads.@threads`
                   (each replicate seeds its own RNG `seed + b`, so multi-core
                   and single-core give identical results). Returns an extra
                   `n_converged::Int`.

All methods return `term`, `estimate` (dispersion on its natural scale),
`lower`, `upper`, and `method`. Dispersion parameters (`r`, `phi`, `alpha`) are
parameterised on the log scale internally; their bounds are reported on the
natural (positive) scale.

`parm` subsets the terms by name: an exact name (`"beta[1]"`, `"Lambda[2,1]"`,
`"r"`), a group (`"beta"`, `"Lambda"`), or a vector of these. `N` supplies the
Binomial trial counts (default all-ones / Bernoulli).

```julia
fit = fit_poisson_gllvm(Y; K = 2)
confint(fit, Y; method = :wald)
confint(fit, Y; method = :profile, parm = "beta[1]")
confint(fit, Y; method = :bootstrap, n_boot = 500, parallel = true)
```
"""
function confint(fit::_CIFit, Y::AbstractMatrix;
                 method::Symbol = :wald,
                 level::Real = 0.95,
                 parm = nothing,
                 N::Union{Nothing, AbstractMatrix} = nothing,
                 n_boot::Integer = 200,
                 seed::Integer = 0,
                 parallel::Bool = false,
                 newton_maxiter::Integer = 100,
                 newton_tol::Real = 1e-9)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    ad = _family_ci(fit, Y; N = N, newton_maxiter = newton_maxiter, newton_tol = newton_tol)
    sel = _family_select(parm, ad.names)
    isempty(sel) && throw(ArgumentError("parm selector matched no parameters"))
    if method === :wald
        return _family_wald(ad, sel, level)
    elseif method === :profile
        return _family_profile(ad, sel, level)
    elseif method === :bootstrap
        return _family_bootstrap(ad, sel, level, n_boot, seed, parallel)
    else
        throw(ArgumentError("method must be :wald, :profile, or :bootstrap; got :$method"))
    end
end
