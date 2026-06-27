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
const _FamilyFit = Union{PoissonFit, BinomialFit, NBFit, NB1Fit, GP1Fit, BetaFit, GammaFit, ExponentialFit,
                         TweedieFit, BetaBinomialFit, RowRandomFit}

# Two-part families ([βz; βc; pack_lambda(Λc); (log-dispersion)] layout).
const _TwoPartFit = Union{DeltaLogNormalFit, DeltaGammaFit, HurdlePoissonFit,
                          HurdleNBFit, ZIPFit, ZINBFit, ZIBFit, BetaHurdleFit}

# Everything the unified confint(fit, Y; method=…) entry accepts.
const _GroupedDispersionFit = Union{NBGroupedFit, NB1GroupedFit, BetaGroupedFit, GammaGroupedFit}

const _CIFit = Union{_FamilyFit, _TwoPartFit, _GroupedDispersionFit, OrdinalFit,
                     GllvmCovFit, OrderedBetaFit, QuadraticFit, RowEffectFit}

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

function _ci_mask(mask, Y::AbstractMatrix)
    mask === nothing && return nothing
    M = Matrix{Bool}(mask)
    size(M) == size(Y) || throw(ArgumentError(
        "confint mask must have size $(size(Y)); got $(size(M))"))
    all(M) && return nothing
    any(M) || throw(ArgumentError("confint mask has no observed cells"))
    return M
end

# --- Poisson ---------------------------------------------------------------
function _family_ci(fit::PoissonFit, Y::AbstractMatrix;
                    mask = nothing,
                    objective::Symbol = :laplace,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    M = _ci_mask(mask, Y)
    θ = vcat(fit.β, pack_lambda(fit.Λ))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        v = try
            objective === :va ?
                -poisson_marginal_loglik_va(Y, Λ, β; maxiter = newton_maxiter, tol = newton_tol) :
                -poisson_marginal_loglik_laplace(Y, Λ, β, link; mask = M,
                                                 maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = rng -> _glm_simulate_counts(rng, fit.β, fit.Λ, link, n,
                                           (r, μ) -> Poisson(max(μ, 1e-12)))
    refit = function (Yb)
        fb = try fit_poisson_gllvm(Yb; K = K, link = link, mask = M) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ))
    end
    return _FamilyCI(θ, nll, _glm_lin_names(p, K), fill(:linear, length(θ)), simulate, refit)
end

# --- Binomial --------------------------------------------------------------
function _family_ci(fit::BinomialFit, Y::AbstractMatrix;
                    N::Union{Nothing, AbstractMatrix} = nothing,
                    mask = nothing,
                    objective::Symbol = :laplace,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    Nm = N === nothing ? fill(1, p, n) : Matrix{Int}(N)
    M = _ci_mask(mask, Y)
    θ = vcat(fit.β, pack_lambda(fit.Λ))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        v = try
            objective === :va ?
                -binomial_marginal_loglik_va(Y, Nm, Λ, β; maxiter = newton_maxiter, tol = newton_tol) :
                -binomial_marginal_loglik_laplace(Y, Nm, Λ, β, link; mask = M,
                                                  maxiter = newton_maxiter, tol = newton_tol)
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
        fb = try fit_binomial_gllvm(Yb; K = K, link = link, N = Nm, mask = M) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ))
    end
    return _FamilyCI(θ, nll, _glm_lin_names(p, K), fill(:linear, length(θ)), simulate, refit)
end

# --- Negative binomial -----------------------------------------------------
function _family_ci(fit::NBFit, Y::AbstractMatrix;
                    mask = nothing,
                    objective::Symbol = :laplace,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    M = _ci_mask(mask, Y)
    θ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.r))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K); r = exp(θv[p + rr + 1])
        v = try
            objective === :va ?
                -nb_marginal_loglik_va(Y, Λ, β, r; maxiter = newton_maxiter, tol = newton_tol) :
                -nb_marginal_loglik_laplace(Y, Λ, β, r; link = link, mask = M,
                                            maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = rng -> _glm_simulate_counts(rng, fit.β, fit.Λ, link, n,
                                           (rg, μ) -> (m = max(μ, 1e-12); NegativeBinomial(fit.r, fit.r / (fit.r + m))))
    refit = function (Yb)
        fb = try fit_nb_gllvm(Yb; K = K, link = link, mask = M) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log(fb.r))
    end
    names = vcat(_glm_lin_names(p, K), "r")
    kinds = vcat(fill(:linear, length(θ) - 1), :log)
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

# --- Negative binomial type-1 (NB1, linear variance Var = μ(1+φ)) -----------
function _family_ci(fit::NB1Fit, Y::AbstractMatrix;
                    mask = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    M = _ci_mask(mask, Y)
    θ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.φ))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K); φ = exp(θv[p + rr + 1])
        v = try
            -nb1_marginal_loglik_laplace(Y, Λ, β, φ; link = link, mask = M,
                                         maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = rng -> _glm_simulate_counts(rng, fit.β, fit.Λ, link, n,
                                           (rg, μ) -> (m = max(μ, 1e-12); NegativeBinomial(m / fit.φ, 1 / (1 + fit.φ))))
    refit = function (Yb)
        fb = try fit_nb1_gllvm(Yb; K = K, link = link, mask = M) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log(fb.φ))
    end
    names = vcat(_glm_lin_names(p, K), "phi")
    kinds = vcat(fill(:linear, length(θ) - 1), :log)
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

# --- Generalized Poisson type-1 (GP-1, Var = μ(1+α μ)², signed dispersion α) ----
function _family_ci(fit::GP1Fit, Y::AbstractMatrix;
                    mask = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    M = _ci_mask(mask, Y)
    θ = vcat(fit.β, pack_lambda(fit.Λ), fit.α)            # α packed RAW (signed, not log)
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K); α = θv[p + rr + 1]
        v = try
            -gp1_marginal_loglik_laplace(Y, Λ, β, α; link = link, mask = M,
                                         maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = function (rng)
        fam = GeneralizedPoisson1(fit.α)
        Yb = Matrix{Int}(undef, p, n)
        @inbounds for s in 1:n
            η = fit.β .+ fit.Λ * randn(rng, K)
            for t in 1:p
                Yb[t, s] = _rand_gp1(rng, fam, linkinv(link, _clamp_eta(η[t])))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_gp1_gllvm(Yb; K = K, link = link, mask = M) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), fb.α)
    end
    names = vcat(_glm_lin_names(p, K), "alpha")
    kinds = fill(:linear, length(θ))                      # α is raw/linear, not log
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

# --- Beta ------------------------------------------------------------------
function _family_ci(fit::BetaFit, Y::AbstractMatrix;
                    mask = nothing,
                    objective::Symbol = :laplace,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    M = _ci_mask(mask, Y)
    θ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.φ))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K); φ = exp(θv[p + rr + 1])
        v = try
            objective === :va ?
                -beta_marginal_loglik_va(Y, Λ, β, φ; maxiter = newton_maxiter, tol = newton_tol) :
                -beta_marginal_loglik_laplace(Y, Λ, β, φ; link = link, mask = M,
                                              maxiter = newton_maxiter, tol = newton_tol)
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
        fb = try fit_beta_gllvm(Yb; K = K, link = link, mask = M) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log(fb.φ))
    end
    names = vcat(_glm_lin_names(p, K), "phi")
    kinds = vcat(fill(:linear, length(θ) - 1), :log)
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

# --- Gamma -----------------------------------------------------------------
function _family_ci(fit::GammaFit, Y::AbstractMatrix;
                    mask = nothing,
                    objective::Symbol = :laplace,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    M = _ci_mask(mask, Y)
    θ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.α))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K); α = exp(θv[p + rr + 1])
        v = try
            objective === :va ?
                -gamma_marginal_loglik_va(Y, Λ, β, α; maxiter = newton_maxiter, tol = newton_tol) :
                -gamma_marginal_loglik_laplace(Y, Λ, β, α; link = link, mask = M,
                                               maxiter = newton_maxiter, tol = newton_tol)
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
        fb = try fit_gamma_gllvm(Yb; K = K, link = link, mask = M) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log(fb.α))
    end
    names = vcat(_glm_lin_names(p, K), "alpha")
    kinds = vcat(fill(:linear, length(θ) - 1), :log)
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

# --- Grouped / per-trait dispersion bridge families -----------------------
_grouped_dispersion_names(p::Integer, K::Integer, parameter::AbstractString, G::Integer) =
    vcat(_glm_lin_names(p, K), ["$(parameter)[$g]" for g in 1:G])

function _family_ci(fit::NBGroupedFit, Y::AbstractMatrix;
                    mask = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K)
    link = fit.link; group = collect(Int, fit.group); G = length(fit.r_group)
    Yi = round.(Int, Y)
    M = _ci_mask(mask, Y)
    θ = vcat(fit.β, pack_lambda(fit.Λ), log.(fit.r_group))
    nll = function (θv)
        β = θv[1:p]
        Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        rg = exp.(θv[(p + rr + 1):(p + rr + G)])
        rvec = [rg[group[t]] for t in 1:p]
        v = try
            -nb_grouped_marginal_loglik_laplace(Yi, Λ, β, rvec; link = link,
                                                mask = M,
                                                maxiter = newton_maxiter,
                                                tol = newton_tol)
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
                μ = max(linkinv(link, _clamp_eta(η[t])), 1e-12)
                r = fit.r_group[group[t]]
                Yb[t, s] = rand(rng, NegativeBinomial(r, r / (r + μ)))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_nb_gllvm_grouped(Yb; K = K, group = group, link = link, mask = M) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log.(fb.r_group))
    end
    names = _grouped_dispersion_names(p, K, "r", G)
    kinds = vcat(fill(:linear, p + rr), fill(:log, G))
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

function _family_ci(fit::NB1GroupedFit, Y::AbstractMatrix;
                    mask = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K)
    link = fit.link; group = collect(Int, fit.group); G = length(fit.φ)
    Yi = round.(Int, Y)
    M = _ci_mask(mask, Y)
    θ = vcat(fit.β, pack_lambda(fit.Λ), log.(fit.φ))
    nll = function (θv)
        β = θv[1:p]
        Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        φg = exp.(θv[(p + rr + 1):(p + rr + G)])
        φvec = [φg[group[t]] for t in 1:p]
        v = try
            -nb1_grouped_marginal_loglik_laplace(Yi, Λ, β, φvec; link = link,
                                                 mask = M,
                                                 maxiter = newton_maxiter,
                                                 tol = newton_tol)
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
                μ = max(linkinv(link, _clamp_eta(η[t])), 1e-12)
                φ = fit.φ[group[t]]
                Yb[t, s] = rand(rng, NegativeBinomial(μ / φ, 1 / (1 + φ)))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_nb1_gllvm_grouped(Yb; K = K, group = group, link = link, mask = M) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log.(fb.φ))
    end
    names = _grouped_dispersion_names(p, K, "phi", G)
    kinds = vcat(fill(:linear, p + rr), fill(:log, G))
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

function _family_ci(fit::BetaGroupedFit, Y::AbstractMatrix;
                    mask = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K)
    link = fit.link; group = collect(Int, fit.group); G = length(fit.φ)
    Yf = clamp.(Float64.(Y), 1e-6, 1 - 1e-6)
    M = _ci_mask(mask, Y)
    θ = vcat(fit.β, pack_lambda(fit.Λ), log.(fit.φ))
    nll = function (θv)
        β = θv[1:p]
        Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        φg = exp.(θv[(p + rr + 1):(p + rr + G)])
        φvec = [φg[group[t]] for t in 1:p]
        v = try
            -beta_grouped_marginal_loglik_laplace(Yf, Λ, β, φvec; link = link,
                                                  mask = M,
                                                  maxiter = newton_maxiter,
                                                  tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = function (rng)
        Yb = Matrix{Float64}(undef, p, n)
        @inbounds for s in 1:n
            η = fit.β .+ fit.Λ * randn(rng, K)
            for t in 1:p
                μ = clamp(linkinv(link, _clamp_eta(η[t])), 1e-6, 1 - 1e-6)
                φ = fit.φ[group[t]]
                Yb[t, s] = clamp(rand(rng, Beta(μ * φ, (1 - μ) * φ)), 1e-6, 1 - 1e-6)
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_beta_gllvm_grouped(Yb; K = K, group = group, link = link, mask = M) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log.(fb.φ))
    end
    names = _grouped_dispersion_names(p, K, "phi", G)
    kinds = vcat(fill(:linear, p + rr), fill(:log, G))
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

function _family_ci(fit::GammaGroupedFit, Y::AbstractMatrix;
                    mask = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K)
    link = fit.link; group = collect(Int, fit.group); G = length(fit.α)
    Yf = max.(Float64.(Y), 1e-9)
    M = _ci_mask(mask, Y)
    θ = vcat(fit.β, pack_lambda(fit.Λ), log.(fit.α))
    nll = function (θv)
        β = θv[1:p]
        Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        αg = exp.(θv[(p + rr + 1):(p + rr + G)])
        αvec = [αg[group[t]] for t in 1:p]
        v = try
            -gamma_grouped_marginal_loglik_laplace(Yf, Λ, β, αvec; link = link,
                                                   mask = M,
                                                   maxiter = newton_maxiter,
                                                   tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = function (rng)
        Yb = Matrix{Float64}(undef, p, n)
        @inbounds for s in 1:n
            η = fit.β .+ fit.Λ * randn(rng, K)
            for t in 1:p
                μ = max(linkinv(link, _clamp_eta(η[t])), 1e-12)
                α = fit.α[group[t]]
                Yb[t, s] = rand(rng, Gamma(α, μ / α))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_gamma_gllvm_grouped(Yb; K = K, group = group, link = link, mask = M) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log.(fb.α))
    end
    names = _grouped_dispersion_names(p, K, "alpha", G)
    kinds = vcat(fill(:linear, p + rr), fill(:log, G))
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

# Compound Poisson–Gamma draw from a Tweedie (1 < p < 2) with mean μ, dispersion
# φ: N ~ Poisson(λ), λ = μ^{2-p}/(φ(2-p)); Y = Σᵢ Gammaᵢ(shape=(2-p)/(p-1),
# scale=φ(p-1)μ^{p-1}); N = 0 ⇒ exact zero (Dunn & Smyth 2005). No dedicated
# Tweedie sampler ships with the family pieces, so the bootstrap draws here.
function _rand_tweedie(rng::AbstractRNG, μ, φ, p)
    μ = max(float(μ), 1e-12)
    λ = μ^(2.0 - p) / (φ * (2.0 - p))
    N = rand(rng, Poisson(λ))
    N == 0 && return 0.0
    shape = (2.0 - p) / (p - 1.0)
    scale = φ * (p - 1.0) * μ^(p - 1.0)
    s = 0.0
    @inbounds for _ in 1:N
        s += rand(rng, Gamma(shape, scale))
    end
    return s
end

# --- Tweedie (compound Poisson–Gamma, power p ∈ (1,2) fixed at the fit) ------
# The fitter jointly estimates φ and the power p, but the CI layer profiles only
# the dispersion φ here (one log-scale term, like NB's r / Gamma's α); the power
# is held fixed at its fitted value `fit.p` throughout the Hessian / profile /
# bootstrap, so the working vector is [β; pack_lambda(Λ); log φ].
function _family_ci(fit::TweedieFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    pw = fit.p
    θ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.φ))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K); φ = exp(θv[p + rr + 1])
        v = try
            -tweedie_marginal_loglik_laplace(Y, Λ, β, φ, pw; link = link,
                                             maxiter = newton_maxiter, tol = newton_tol)
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
                μ = max(linkinv(link, _clamp_eta(η[t])), 1e-12)
                Yb[t, s] = _rand_tweedie(rng, μ, φ, pw)
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_tweedie_gllvm(Yb; K = K, link = link) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log(fb.φ))
    end
    names = vcat(_glm_lin_names(p, K), "phi")
    kinds = vcat(fill(:linear, length(θ) - 1), :log)
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

# --- Exponential (positive continuous, no dispersion) ----------------------
function _family_ci(fit::ExponentialFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    θ = vcat(fit.β, pack_lambda(fit.Λ))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        v = try
            -exponential_marginal_loglik_laplace(Y, Λ, β; link = link, maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = function (rng)
        Yb = Matrix{Float64}(undef, p, n)
        @inbounds for s in 1:n
            η = fit.β .+ fit.Λ * randn(rng, K)
            for t in 1:p
                Yb[t, s] = rand(rng, Exponential(max(linkinv(link, _clamp_eta(η[t])), 1e-12)))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_exponential_gllvm(Yb; K = K, link = link) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ))
    end
    return _FamilyCI(θ, nll, _glm_lin_names(p, K), fill(:linear, length(θ)), simulate, refit)
end

# --- Beta-binomial (overdispersed binomial; one Beta-precision φ) -----------
# Working vector [β; pack_lambda(Λ); log φ] — the NB/Beta scalar-dispersion
# template. Like the Binomial CIs, the trial counts N are NOT stored in the fit,
# so they are taken as data through the `N` kwarg (default all-ones / Bernoulli-
# overdispersed) and threaded through the marginal, the bootstrap draw, and the
# refit exactly as families/binomial.jl threads them.
function _family_ci(fit::BetaBinomialFit, Y::AbstractMatrix;
                    N::Union{Nothing, AbstractMatrix} = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); link = fit.link
    Nm = N === nothing ? fill(1, p, n) : Matrix{Int}(N)
    θ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.φ))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K); φ = exp(θv[p + rr + 1])
        v = try
            -betabinomial_marginal_loglik_laplace(Y, Nm, Λ, β, φ; link = link,
                                                  maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = function (rng)
        Yb = Matrix{Int}(undef, p, n); φ = fit.φ
        @inbounds for s in 1:n
            η = fit.β .+ fit.Λ * randn(rng, K)
            for t in 1:p
                μ = clamp(linkinv(link, _clamp_eta(η[t])), 1e-12, 1 - 1e-12)
                # beta-binomial draw: success prob ~ Beta(μφ, (1−μ)φ), then Binomial(N, ·).
                pdraw = clamp(rand(rng, Beta(μ * φ, (1 - μ) * φ)), 1e-12, 1 - 1e-12)
                Yb[t, s] = rand(rng, Binomial(Nm[t, s], pdraw))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_beta_binomial_gllvm(Yb; K = K, link = link, N = Nm) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), log(fb.φ))
    end
    names = vcat(_glm_lin_names(p, K), "phi")
    kinds = vcat(fill(:linear, length(θ) - 1), :log)
    return _FamilyCI(θ, nll, names, kinds, simulate, refit)
end

# --- Random row effect (per-site random intercept σ_row, + family dispersion) ---
# Working vector [β; pack_lambda(Λ); log σ_row; (log-dispersion)] — `σ_row` is the
# row-effect SD on the log scale (it stays ≥ 0), and the underlying family's
# dispersion (NB `r` / Beta `φ` / Gamma `α`) is the optional trailing log-scale
# term, exactly as the fitter lays it out. The marginal is the augmented
# (K+1)-latent reparameterisation `Λ̃ = [Λ | σ_row·𝟙_p]`; the bootstrap draws
# z_s ~ N(0,I_K) and ρ_s ~ N(0, σ_row²) then the per-family response.
function _family_ci(fit::RowRandomFit, Y::AbstractMatrix;
                    N::Union{Nothing, AbstractMatrix} = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K)
    lk = fit.link; fam0 = fit.family; hasd = _cov_has_disp(fam0)
    Nm = N === nothing ? fill(1, p, n) : N
    θ = hasd ? vcat(fit.β, pack_lambda(fit.Λ), log(fit.σ_row), log(fit.dispersion)) :
               vcat(fit.β, pack_lambda(fit.Λ), log(fit.σ_row))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        σ_row = exp(θv[p + rr + 1])
        disp = hasd ? exp(θv[p + rr + 2]) : NaN
        fam = _cov_family(fam0, disp)
        v = try
            -row_random_marginal_loglik_laplace(fam, Y, Nm, Λ, β, σ_row; link = lk,
                                                maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    simulate = function (rng)
        Yb = Matrix{Float64}(undef, p, n); fam = _cov_family(fam0, fit.dispersion)
        @inbounds for s in 1:n
            ρ = fit.σ_row * randn(rng)                       # per-site random intercept
            η = fit.β .+ ρ .+ fit.Λ * randn(rng, K)
            for t in 1:p
                μ = linkinv(lk, _clamp_eta(η[t]))
                Yb[t, s] = _cov_sample(fam, μ, Nm[t, s], rng)
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try
            fit_row_random_gllvm(Yb; family = fam0, K = K, link = lk,
                                 N = fam0 isa Binomial ? Nm : nothing)
        catch
            return nothing
        end
        return hasd ? vcat(fb.β, pack_lambda(fb.Λ), log(fb.σ_row), log(fb.dispersion)) :
                      vcat(fb.β, pack_lambda(fb.Λ), log(fb.σ_row))
    end
    names = vcat(_glm_lin_names(p, K), "sigma_row")
    kinds = vcat(fill(:linear, p + rr), :log)
    if hasd
        push!(names, _cov_dispname(fam0)); push!(kinds, :log)
    end
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
                    objective::Symbol = :laplace,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λc); n = size(Y, 2); rr = rr_theta_len(p, K)
    θ = vcat(fit.βz, fit.βc, pack_lambda(fit.Λc), log(fit.α))
    nll = function (θv)
        βz = θv[1:p]; βc = θv[(p + 1):(2p)]
        Λc = unpack_lambda(θv[(2p + 1):(2p + rr)], p, K); α = exp(θv[2p + rr + 1])
        v = try
            objective === :va ?
                -delta_gamma_marginal_loglik_va(Y, Λc, βz, βc, α; maxiter = newton_maxiter, tol = newton_tol) :
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

# --- Beta-hurdle (Bernoulli occurrence × positive Beta) --------------------
function _family_ci(fit::BetaHurdleFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λc); n = size(Y, 2); rr = rr_theta_len(p, K)
    θ = vcat(fit.βz, fit.βc, pack_lambda(fit.Λc), log(fit.φ))
    nll = function (θv)
        βz = θv[1:p]; βc = θv[(p + 1):(2p)]
        Λc = unpack_lambda(θv[(2p + 1):(2p + rr)], p, K); φ = exp(θv[2p + rr + 1])
        v = try
            -beta_hurdle_marginal_loglik_laplace(Y, Λc, βz, βc, φ;
                                                 maxiter = newton_maxiter, tol = newton_tol)
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
                    μ = clamp(inv(1 + exp(-ηc[t])), 1e-6, 1 - 1e-6)
                    Yb[t, s] = rand(rng, Beta(μ * fit.φ, (1 - μ) * fit.φ))
                end
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_beta_hurdle_gllvm(Yb; K = K) catch; return nothing end
        return vcat(fb.βz, fb.βc, pack_lambda(fb.Λc), log(fb.φ))
    end
    names = vcat(_twopart_lin_names(p, K), "phi")
    return _FamilyCI(θ, nll, names, vcat(fill(:linear, length(θ) - 1), :log), sim, refit)
end

# --- Ordered-beta (proportions with point masses at 0 and 1) ---------------
function _family_ci(fit::OrderedBetaFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); rr = rr_theta_len(p, K)
    θ = vcat(fit.β, pack_lambda(fit.Λ), fit.c0, fit.c1, log(fit.φ))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        c0 = θv[p + rr + 1]; c1 = θv[p + rr + 2]; φ = exp(θv[p + rr + 3])
        v = try
            -ordered_beta_marginal_loglik_laplace(Y, Λ, β, c0, c1, φ;
                                                  maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    sim   = _ -> error("bootstrap is not supported for ordered-beta CIs")
    refit = function (Yb)
        fb = try fit_ordered_beta_gllvm(Yb; K = K) catch; return nothing end
        return vcat(fb.β, pack_lambda(fb.Λ), fb.c0, fb.c1, log(fb.φ))
    end
    names = vcat(_glm_lin_names(p, K), "cut0", "cut1", "phi")
    kinds = vcat(fill(:linear, p + rr + 2), :log)
    return _FamilyCI(θ, nll, names, kinds, sim, refit)
end

# ---------------------------------------------------------------------------
# Structural models (quadratic, RRR, row-effects, species-cov, fourth-corner,
# concurrent/constrained). Each adapter mirrors that fitter's own negll layout
# and reconstructs the dispersion via _cov_family (covariates.jl). Bootstrap is
# unsupported (sim stub errors); Wald + profile work. Dispersion (when present)
# is the last θ entry on the log scale.
# ---------------------------------------------------------------------------
function _family_ci(fit::QuadraticFit, Y::AbstractMatrix;
                    N::Union{Nothing, AbstractMatrix} = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); pK = p * K
    lk = fit.link; fam0 = fit.family; hasd = _cov_has_disp(fam0)
    Nm = N === nothing ? fill(1, p, n) : N
    θ = hasd ? vcat(fit.β, pack_lambda(fit.Λ), vec(fit.D), log(fit.dispersion)) :
               vcat(fit.β, pack_lambda(fit.Λ), vec(fit.D))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        D = reshape(θv[(p + rr + 1):(p + rr + pK)], p, K)
        disp = hasd ? exp(θv[p + rr + pK + 1]) : NaN
        v = try
            -quadratic_marginal_loglik_laplace(_cov_family(fam0, disp), Y, Nm, Λ, D, β, lk;
                                               maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    names = vcat(_glm_lin_names(p, K), ["D[$t,$k]" for k in 1:K for t in 1:p])
    kinds = fill(:linear, p + rr + pK)
    hasd && (push!(names, "dispersion"); push!(kinds, :log))
    return _FamilyCI(θ, nll, names, kinds,
                     _ -> error("bootstrap not supported for quadratic CIs"), _ -> nothing)
end

function _family_ci(fit::RowEffectFit, Y::AbstractMatrix;
                    N::Union{Nothing, AbstractMatrix} = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); nfree = n - 1
    lk = fit.link; fam0 = fit.family; hasd = _cov_has_disp(fam0)
    Nm = N === nothing ? fill(1, p, n) : N
    ρfree0 = fit.ρ[2:end]                       # ρ_1 ≡ 0 reference
    θ = hasd ? vcat(fit.β, ρfree0, pack_lambda(fit.Λ), log(fit.dispersion)) :
               vcat(fit.β, ρfree0, pack_lambda(fit.Λ))
    nll = function (θv)
        β = θv[1:p]; ρfree = θv[(p + 1):(p + nfree)]
        Λ = unpack_lambda(θv[(p + nfree + 1):(p + nfree + rr)], p, K)
        disp = hasd ? exp(θv[p + nfree + rr + 1]) : NaN
        ρ = vcat(zero(eltype(ρfree)), ρfree); O = _build_offset_row(ρ, p)
        v = try
            -_marginal_loglik_offset(_cov_family(fam0, disp), Y, Nm, Λ, β, O, lk;
                                     maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    names = vcat(["beta[$t]" for t in 1:p], ["rho[$(s + 1)]" for s in 1:nfree],
                 _confint_lambda_term_names("Lambda", p, K))
    kinds = fill(:linear, p + nfree + rr)
    hasd && (push!(names, "dispersion"); push!(kinds, :log))
    return _FamilyCI(θ, nll, names, kinds,
                     _ -> error("bootstrap not supported for row-effect CIs"), _ -> nothing)
end

# The covariate structural models need their design matrix (not stored in the fit),
# so they get dedicated Wald entries (like confint_spde_latent), reusing _family_wald.

"""
    confint_speciescov(fit::GllvmSpeciesCovFit, Y, X; level=0.95, parm=nothing, N=nothing) -> NamedTuple

Wald CIs for the species-specific-covariate GLLVM. `X` is the p×n×q design used in the fit.
"""
function confint_speciescov(fit::GllvmSpeciesCovFit, Y::AbstractMatrix, X::AbstractArray{<:Real,3};
        level::Real = 0.95, parm = nothing, N::Union{Nothing,AbstractMatrix} = nothing,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); q = size(X, 3); pq = p * q
    lk = fit.link; fam0 = fit.family; hasd = _cov_has_disp(fam0)
    Nm = N === nothing ? fill(1, p, n) : N
    θ = hasd ? vcat(fit.β, vec(fit.B), pack_lambda(fit.Λ), log(fit.dispersion)) :
               vcat(fit.β, vec(fit.B), pack_lambda(fit.Λ))
    nll = function (θv)
        β = θv[1:p]; B = reshape(θv[(p + 1):(p + pq)], p, q)
        Λ = unpack_lambda(θv[(p + pq + 1):(p + pq + rr)], p, K)
        disp = hasd ? exp(θv[p + pq + rr + 1]) : NaN
        v = try
            -_marginal_loglik_offset(_cov_family(fam0, disp), Y, Nm, Λ, β,
                                     _build_offset_species(X, B), lk;
                                     maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    names = vcat(["beta[$t]" for t in 1:p], ["B[$t,$j]" for j in 1:q for t in 1:p],
                 _confint_lambda_term_names("Lambda", p, K))
    kinds = fill(:linear, p + pq + rr)
    hasd && (push!(names, "dispersion"); push!(kinds, :log))
    ad = _FamilyCI(θ, nll, names, kinds, _ -> error("bootstrap unsupported"), _ -> nothing)
    sel = _family_select(parm, ad.names)
    isempty(sel) && throw(ArgumentError("parm selector matched no parameters"))
    return _family_wald(ad, sel, level)
end

"""
    confint_fourthcorner(fit::FourthCornerFit, Y, Xenv, TR; level=0.95, parm=nothing, N=nothing) -> NamedTuple

Wald CIs for the fourth-corner trait–environment GLLVM (`Xenv` n×q, `TR` p×r).
"""
function confint_fourthcorner(fit::FourthCornerFit, Y::AbstractMatrix,
        Xenv::AbstractMatrix, TR::AbstractMatrix;
        level::Real = 0.95, parm = nothing, N::Union{Nothing,AbstractMatrix} = nothing,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K)
    q = size(Xenv, 2); r = size(TR, 2); qr = q * r
    lk = fit.link; fam0 = fit.family; hasd = _cov_has_disp(fam0)
    Nm = N === nothing ? fill(1, p, n) : N
    θ = hasd ? vcat(fit.β, vec(fit.C), pack_lambda(fit.Λ), log(fit.dispersion)) :
               vcat(fit.β, vec(fit.C), pack_lambda(fit.Λ))
    nll = function (θv)
        β = θv[1:p]; C = reshape(θv[(p + 1):(p + qr)], q, r)
        Λ = unpack_lambda(θv[(p + qr + 1):(p + qr + rr)], p, K)
        disp = hasd ? exp(θv[p + qr + rr + 1]) : NaN
        v = try
            -_marginal_loglik_offset(_cov_family(fam0, disp), Y, Nm, Λ, β,
                                     _build_offset_fourthcorner(Xenv, TR, C), lk;
                                     maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    names = vcat(["beta[$t]" for t in 1:p], ["C[$i,$j]" for j in 1:r for i in 1:q],
                 _confint_lambda_term_names("Lambda", p, K))
    kinds = fill(:linear, p + qr + rr)
    hasd && (push!(names, "dispersion"); push!(kinds, :log))
    ad = _FamilyCI(θ, nll, names, kinds, _ -> error("bootstrap unsupported"), _ -> nothing)
    sel = _family_select(parm, ad.names)
    isempty(sel) && throw(ArgumentError("parm selector matched no parameters"))
    return _family_wald(ad, sel, level)
end

"""
    confint_rrr(fit::RRRFit, Y, X; level=0.95, parm=nothing, N=nothing) -> NamedTuple

Wald CIs for the reduced-rank-regression (constrained) ordination (`X` n×q).
"""
function confint_rrr(fit::RRRFit, Y::AbstractMatrix, X::AbstractMatrix;
        level::Real = 0.95, parm = nothing, N::Union{Nothing,AbstractMatrix} = nothing)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); q = size(X, 2); qK = q * K
    lk = fit.link; fam0 = fit.family; hasd = _cov_has_disp(fam0)
    Nm = N === nothing ? fill(1, p, n) : N
    θ = hasd ? vcat(fit.β, pack_lambda(fit.Λ), vec(fit.B), log(fit.dispersion)) :
               vcat(fit.β, pack_lambda(fit.Λ), vec(fit.B))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        B = reshape(θv[(p + rr + 1):(p + rr + qK)], q, K)
        disp = hasd ? exp(θv[p + rr + qK + 1]) : NaN
        v = try
            -rrr_marginal_loglik(_cov_family(fam0, disp), Y, Nm, Λ, B, β, X, lk)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    names = vcat(_glm_lin_names(p, K), ["B[$i,$k]" for k in 1:K for i in 1:q])
    kinds = fill(:linear, p + rr + qK)
    hasd && (push!(names, "dispersion"); push!(kinds, :log))
    ad = _FamilyCI(θ, nll, names, kinds, _ -> error("bootstrap unsupported"), _ -> nothing)
    sel = _family_select(parm, ad.names)
    isempty(sel) && throw(ArgumentError("parm selector matched no parameters"))
    return _family_wald(ad, sel, level)
end

"""
    confint_constrained(fit::ConstrainedOrdinationFit, Y, X; level=0.95, parm=nothing, N=nothing) -> NamedTuple

Wald CIs for the concurrent / constrained ordination (`X` n×q).
"""
function confint_constrained(fit::ConstrainedOrdinationFit, Y::AbstractMatrix, X::AbstractMatrix;
        level::Real = 0.95, parm = nothing, N::Union{Nothing,AbstractMatrix} = nothing,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); q = size(X, 2); qK = q * K
    lk = fit.link; fam0 = fit.family; hasd = _cov_has_disp(fam0)
    Nm = N === nothing ? fill(1, p, n) : N
    θ = hasd ? vcat(fit.β, pack_lambda(fit.Λ), vec(fit.B), log(fit.dispersion)) :
               vcat(fit.β, pack_lambda(fit.Λ), vec(fit.B))
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        B = reshape(θv[(p + rr + 1):(p + rr + qK)], q, K)
        disp = hasd ? exp(θv[p + rr + qK + 1]) : NaN
        v = try
            -_marginal_loglik_offset(_cov_family(fam0, disp), Y, Nm, Λ, β,
                                     _build_offset_constrained(Λ, B, X), lk;
                                     maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    names = vcat(_glm_lin_names(p, K), ["B[$i,$k]" for k in 1:K for i in 1:q])
    kinds = fill(:linear, p + rr + qK)
    hasd && (push!(names, "dispersion"); push!(kinds, :log))
    ad = _FamilyCI(θ, nll, names, kinds, _ -> error("bootstrap unsupported"), _ -> nothing)
    sel = _family_select(parm, ad.names)
    isempty(sel) && throw(ArgumentError("parm selector matched no parameters"))
    return _family_wald(ad, sel, level)
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

# --- Zero-inflated binomial ------------------------------------------------
function _family_ci(fit::ZIBFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λc); n = size(Y, 2); rr = rr_theta_len(p, K); Ntr = fit.N
    θ = vcat(fit.βz, fit.βc, pack_lambda(fit.Λc))
    nll = function (θv)
        βz = θv[1:p]; βc = θv[(p + 1):(2p)]
        Λc = unpack_lambda(θv[(2p + 1):(2p + rr)], p, K)
        v = try
            -zib_marginal_loglik_laplace(Y, Λc, βz, βc, Ntr; maxiter = newton_maxiter, tol = newton_tol)
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
                π = inv(1 + exp(-fit.βz[t])); μ = inv(1 + exp(-ηc[t]))
                Yb[t, s] = rand(rng) < π ? 0 : rand(rng, Binomial(Ntr, μ))
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_zib_gllvm(Yb; K = K, N = Ntr) catch; return nothing end
        return vcat(fb.βz, fb.βc, pack_lambda(fb.Λc))
    end
    return _FamilyCI(θ, nll, _twopart_lin_names(p, K), fill(:linear, length(θ)), sim, refit)
end
# Working vector [pack_lambda(Λ); τ] in the NATURAL cutpoint parameterisation
# (the fitter optimises ψ-increments, but the MLE τ̂ is strictly ordered, so the
# Wald Hessian / profile / bootstrap all run directly in τ-space — the
# interpretable scale). The ordinal marginal clamps category probabilities at
# 1e-12, so the small perturbations used by the Hessian / refits stay finite even
# if a τ momentarily loses ordering.
function _family_ci(fit::OrdinalFit, Y::AbstractMatrix;
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    p, K = size(fit.Λ); n = size(Y, 2); rr = rr_theta_len(p, K); C = fit.C
    θ = vcat(pack_lambda(fit.Λ), fit.τ)
    nll = function (θv)
        Λ = unpack_lambda(θv[1:rr], p, K)
        τ = θv[(rr + 1):(rr + C - 1)]
        v = try
            -ordinal_marginal_loglik_laplace(Y, Λ, τ; link = fit.link,
                                             maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    sim = function (rng)
        Yb = Matrix{Int}(undef, p, n)
        @inbounds for s in 1:n
            η = fit.Λ * randn(rng, K)
            for t in 1:p
                u = rand(rng); cum = 0.0; cat = C
                for c in 1:C
                    cum += _ord_prob(c, η[t], fit.τ, fit.link)
                    if u <= cum
                        cat = c; break
                    end
                end
                Yb[t, s] = cat
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try fit_ordinal_gllvm(Yb; K = K, link = fit.link) catch; return nothing end
        fb.C == C || return nothing                 # category-count mismatch ⇒ drop replicate
        return vcat(pack_lambda(fb.Λ), fb.τ)
    end
    names = vcat(_confint_lambda_term_names("Lambda", p, K), ["tau[$c]" for c in 1:(C - 1)])
    return _FamilyCI(θ, nll, names, fill(:linear, length(θ)), sim, refit)
end

# --- Covariate fit (GllvmCovFit: β + Xγ + Λz) ------------------------------
# Working vector [β; γ_free; pack_lambda(Λ); (log-dispersion)]. Fixed-zero γ
# entries are structural constraints, not free Hessian/profile/bootstrap terms.
# Requires the full (p,n,q) design `X` (and Binomial trial counts `N`) via
# confint(...; X=…, N=…); the free-column slice is reconstructed from fit.γ_fixed.
function _family_ci(fit::GllvmCovFit, Y::AbstractMatrix;
                    X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                    N::Union{Nothing, AbstractMatrix} = nothing,
                    newton_maxiter::Integer = 100, newton_tol::Real = 1e-9, kwargs...)
    X === nothing && throw(ArgumentError("confint on a GllvmCovFit needs the design `X` (the same array passed to fit_gllvm_cov): confint(fit, Y; method=…, X=X)"))
    p, K = size(fit.Λ); n = size(Y, 2); q_full = length(fit.γ); rr = rr_theta_len(p, K)
    length(fit.γ_fixed) == q_full || throw(ArgumentError(
        "fit.γ_fixed length ($(length(fit.γ_fixed))) must equal length(fit.γ) = $q_full"))
    Xfit, γ_free_idx = _slice_fixed_X(X, fit.γ_fixed)
    q = length(γ_free_idx)
    lk = fit.link; has_disp = !isnan(fit.dispersion)
    Nm = N === nothing ? fill(1, p, n) : N
    γ_free = fit.γ[γ_free_idx]
    θ = has_disp ? vcat(fit.β, γ_free, pack_lambda(fit.Λ), log(fit.dispersion)) :
                   vcat(fit.β, γ_free, pack_lambda(fit.Λ))
    nll = function (θv)
        β = θv[1:p]; γ = θv[(p + 1):(p + q)]
        Λ = unpack_lambda(θv[(p + q + 1):(p + q + rr)], p, K)
        disp = has_disp ? exp(θv[p + q + rr + 1]) : NaN
        fam = _cov_family(fit.family, disp)
        O = _build_offset(Xfit, γ)
        v = try
            -_marginal_loglik_offset(fam, Y, Nm, Λ, β, O, lk; maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    sim = function (rng)
        Yb = Matrix{Float64}(undef, p, n)
        O = _build_offset(X, fit.γ); fam = _cov_family(fit.family, fit.dispersion)
        @inbounds for s in 1:n
            η = fit.β .+ view(O, :, s) .+ fit.Λ * randn(rng, K)
            for t in 1:p
                μ = linkinv(lk, _clamp_eta(η[t]))
                Yb[t, s] = _cov_sample(fam, μ, Nm[t, s], rng)
            end
        end
        return Yb
    end
    refit = function (Yb)
        fb = try
            fit_gllvm_cov(Yb; family = fit.family, X = X, K = K, link = lk,
                          N = fit.family isa Binomial ? Nm : nothing,
                          γ_fixed = fit.γ_fixed)
        catch
            return nothing
        end
        fb_γ_free = fb.γ[γ_free_idx]
        return has_disp ? vcat(fb.β, fb_γ_free, pack_lambda(fb.Λ), log(fb.dispersion)) :
                          vcat(fb.β, fb_γ_free, pack_lambda(fb.Λ))
    end
    names = vcat(["beta[$t]" for t in 1:p], ["gamma[$k]" for k in γ_free_idx],
                 _confint_lambda_term_names("Lambda", p, K))
    kinds = fill(:linear, length(names))
    if has_disp
        names = vcat(names, _cov_dispname(fit.family)); kinds = vcat(kinds, :log)
    end
    return _FamilyCI(θ, nll, names, kinds, sim, refit)
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
        # NB `2 * f0`, not `2f0`: the latter lexes as the Float32 literal 2.0f0,
        # dropping the central term and corrupting every observed-information SE.
        H[i, i] = (f(xp) - 2 * f0 + f(xm)) / h[i]^2
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
        # Seed the first candidate near the Wald bound (θ̂ ± √cutoff·SE) so the
        # bracket is found in ~1 refit; false-position root-finding does the rest.
        step = max(sqrt(cutoff) * sei, 1e-3)
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
        θb = try
            ad.refit(ad.simulate(rng))     # guard both sim + refit so one bad replicate can't crash the run
        catch
            nothing
        end
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
            mask = nothing,
            n_boot = 200, seed = 0, parallel = false, objective = :laplace,
            newton_maxiter = 100, newton_tol = 1e-9) -> NamedTuple

Confidence intervals for a non-Gaussian family GLLVM fit — the scalar-μ GLM
families (`PoissonFit`, `BinomialFit`, `NBFit`, `BetaFit`, `GammaFit`,
`TweedieFit`, `BetaBinomialFit`), the random-row-effect fit (`RowRandomFit`,
which adds a `sigma_row` term plus the underlying family's dispersion), and the
two-part families (`DeltaLogNormalFit`, `DeltaGammaFit`, `HurdlePoissonFit`,
`HurdleNBFit`, `ZIPFit`, `ZINBFit`, `ZIBFit`). `Y` is the same response matrix
passed to the fitter; it is needed to reconstruct the marginal likelihood. For
`BinomialFit` / `BetaBinomialFit` (and a `Binomial`-family `RowRandomFit`) supply
the trial counts via `N` (default all-ones). For response-mask fits, pass the
same Boolean `mask` matrix used by the fitter; masked cells are ignored by the
likelihood and by bootstrap refits.

Term names are `beta[t]` / `Lambda[i,k]` (+ a dispersion `r`/`phi`/`alpha`) for
the GLM families, `... + phi` for `BetaBinomialFit` (the Beta precision) and
`... + sigma_row (+ r/phi/alpha)` for `RowRandomFit`, and `betaz[t]` (occurrence / zero-inflation logits) / `betac[t]`
(positive / count intercepts) / `Lambda[i,k]` (+ `sigma`/`alpha`/`r`) for the
two-part families. For `TweedieFit` the dispersion term is `phi`; the power
`p ∈ (1,2)` is held fixed at its fitted value, so only `phi` is profiled.

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

`objective` selects which marginal the Hessian is taken from. The default
`:laplace` uses the negative Laplace marginal at the fit (the behaviour for all
fit types). `:va` instead uses the negative variational (ELBO) marginal and is
available only for the scalar-μ GLM families (`PoissonFit`, `NBFit`,
`BinomialFit`, `BetaFit`, `GammaFit`) with `method = :wald`; combine it with a VA
fit (e.g. `fit_poisson_gllvm_va`) for VA-consistent standard errors. Masked
confidence intervals currently require `objective = :laplace`.

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
                 X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                 mask = nothing,
                 n_boot::Integer = 200,
                 seed::Integer = 0,
                 parallel::Bool = false,
                 objective::Symbol = :laplace,
                 newton_maxiter::Integer = 100,
                 newton_tol::Real = 1e-9)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    objective in (:laplace, :va) ||
        throw(ArgumentError("objective must be :laplace or :va; got :$objective"))
    if objective === :va && !(fit isa Union{PoissonFit, NBFit, BinomialFit, BetaFit, GammaFit, DeltaGammaFit})
        throw(ArgumentError("objective=:va is only available for Poisson/NB/Binomial/Beta/Gamma/Delta-Gamma fits"))
    end
    if objective === :va && method !== :wald
        throw(ArgumentError("objective=:va currently supports method=:wald only"))
    end
    if objective === :va && mask !== nothing
        throw(ArgumentError("objective=:va is not routed for masked confidence intervals; use objective=:laplace"))
    end
    ad = _family_ci(fit, Y; N = N, X = X, objective = objective,
                    mask = mask,
                    newton_maxiter = newton_maxiter, newton_tol = newton_tol)
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

# ---------------------------------------------------------------------------
# Wald CIs for the SPDE-latent model. It needs the observation locations (not
# stored in the fit) to rebuild the projector, so it gets a dedicated entry
# rather than the generic confint(fit, Y) dispatch — but reuses the same Wald
# machinery (_FamilyCI + _family_wald).
# ---------------------------------------------------------------------------
"""
    confint_spde_latent(fit::SPDELatentFit, Y, locs; level=0.95, parm=nothing,
                        α=2, newton_maxiter=50, newton_tol=1e-9) -> NamedTuple

Wald confidence intervals for the SPDE-latent GLLVM. `Y` (p×M) and `locs` (M×2) must
match the fit. β and Λ are reported on their natural scale; κ, τ, and any dispersion
on the positive scale. SEs come from the observed information (finite-difference
Hessian of the θ-marginal, which rebuilds the Matérn precision each evaluation).
"""
function confint_spde_latent(fit::SPDELatentFit, Y::AbstractMatrix, locs::AbstractMatrix;
                             level::Real = 0.95, parm = nothing, α::Integer = 2,
                             newton_maxiter::Integer = 50, newton_tol::Real = 1e-9)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    p, K = size(fit.Λ); rr = rr_theta_len(p, K)
    Cdiag, G = spde_fem(fit.nodes, fit.tris)
    A = spde_projector(fit.nodes, fit.tris, locs)
    Ntr = ones(eltype(Y), size(Y))
    nd = _spde_disp_len(fit.family)
    dbase = p + rr + 2
    θ = vcat(fit.β, pack_lambda(fit.Λ), log(fit.κ), log(fit.τ),
             nd == 0 ? Float64[] : [log(fit.dispersion)])
    nll = function (θv)
        β = θv[1:p]; Λ = unpack_lambda(θv[(p + 1):(p + rr)], p, K)
        κ = exp(θv[p + rr + 1]); τ = exp(θv[p + rr + 2])
        fam = _spde_make_family(fit.family, view(θv, (dbase + 1):(dbase + nd)))
        v = try
            Q = spde_precision(Cdiag, G, κ, τ; α = α)
            -spde_latent_marginal_loglik(fam, Y, Ntr, Λ, β, fit.link, A, Q;
                                         maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    names = vcat(["beta[$t]" for t in 1:p],
                 _confint_lambda_term_names("Lambda", p, K), "kappa", "tau")
    kinds = vcat(fill(:linear, p + rr), :log, :log)
    if nd > 0
        push!(names, "dispersion"); push!(kinds, :log)
    end
    sim   = _ -> error("bootstrap is not supported for SPDE-latent CIs")
    refit = _ -> nothing
    ad = _FamilyCI(θ, nll, names, kinds, sim, refit)
    sel = _family_select(parm, ad.names)
    isempty(sel) && throw(ArgumentError("parm selector matched no parameters"))
    return _family_wald(ad, sel, level)
end
