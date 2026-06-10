# Standalone Lognormal family for GLLVM.jl.
#
# Model (site s): y_{ts} > 0 with  log(y_{ts}) ~ Normal(η_{ts}, σ²),
#     η_{ts} = β_t + (Λ z_s)_t,  z_s ~ N(0, I_K).
# Equivalently y = exp(η + σ·ε), ε ~ N(0,1). On the LOG (link) scale the model is
# exactly the Gaussian GLLVM, so the entire closed-form Gaussian machinery
# (likelihood.jl, fit.jl) is REUSED on Z = log(Y); the only extra term is the
# change-of-variables Jacobian −Σ log(y) that converts the log-scale Gaussian
# density to the y-scale lognormal density.
#
# This is the standalone twin of the lognormal *response* part used inside the
# delta-lognormal two-part family (families/twopart.jl); here the positive
# response is modelled on its own (no zero/Bernoulli component).
#
# AD-clean: `lognormal_marginal_loglik` is `gaussian_marginal_loglik` (already
# ForwardDiff-clean) plus a parameter-free data constant, so Duals flow through.

# Canonical link for the standalone Lognormal family (log link on y). Lets the
# single-family `simulate(LogNormal(), β, Λ, n)` overload resolve the link.
default_link(::LogNormal) = LogLink()

"""
    lognormal_marginal_loglik(Y, Λ, β, σ; kwargs...) -> Float64

Marginal log-likelihood (y-scale) over the `n` sites (columns) of a standalone
Lognormal GLLVM at explicit parameters: intercepts `β` (length p), loadings `Λ`
(p×K), and log-scale residual SD `σ` (`Var(log y) = σ²`). `Y` is the p×n matrix
of strictly positive responses. Computed as the Gaussian marginal of the centred
log-responses `log(Y) .- β` under `ΛΛᵀ + σ²I`, minus the change-of-variables
Jacobian `Σ_{t,s} log(y_{ts})`.
"""
function lognormal_marginal_loglik(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, σ::Real; kwargs...)
    p, n = size(Y)
    length(β) == p || throw(DimensionMismatch(
        "β length ($(length(β))) must equal p ($p)"))
    all(>(0), Y) || throw(ArgumentError("Lognormal responses must be strictly positive"))
    Z = log.(Y)
    R = Z .- β                                   # p×n centred log-responses (η-mean removed)
    gauss = gaussian_marginal_loglik(R, Λ, float(σ); kwargs...)
    return gauss - sum(Z)                        # Jacobian Σ log y of y → log y
end

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    LognormalFit

Result of [`fit_lognormal_gllvm`](@ref): intercepts `β` (length p; the per-trait
mean of `log(Y)`), loadings `Λ` (p×K) on the log scale, the log-scale residual SD
`σ` (`Var(log y) = σ²`), the `link` (always `LogLink()`), the maximised marginal
`loglik` (y-scale, including the lognormal Jacobian), the optimiser `converged`
flag, and `iterations`.
"""
struct LognormalFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    σ::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::LognormalFit)
    p, K = size(f.Λ)
    print(io, "LognormalFit(p=", p, ", K=", K, ", σ=", round(f.σ; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_lognormal_gllvm(Y; K, …) -> LognormalFit

Fit a standalone Lognormal GLLVM (`log(y) ~ Normal(η, σ²)`, log link) by reusing
the closed-form Gaussian fitter on the log scale. `Y` is a p×n matrix of strictly
positive responses; `K` the latent dimension.

Because the closed-form Gaussian GLLVM assumes zero-mean responses, the per-trait
intercept `β_t` (the joint MLE of the log-scale mean, which for iid sites is the
per-trait mean of `log(Y)`) is estimated as `mean_s log(Y[t, s])` and removed
before the Gaussian fit; `Λ` and `σ` are then fit on the centred log-responses by
[`fit_gaussian_gllvm`](@ref). The reported `loglik` is the y-scale lognormal
marginal at the fitted `(β, Λ, σ)` (Gaussian log-scale marginal plus the
`y → log y` Jacobian). Keyword arguments after `K` pass through to
`fit_gaussian_gllvm`.
"""
function fit_lognormal_gllvm(Y::AbstractMatrix{<:Real}; K::Integer, kwargs...)
    p, n = size(Y)
    all(>(0), Y) || throw(ArgumentError("Lognormal responses must be strictly positive"))
    Z = log.(Y)
    β̂ = vec(sum(Z; dims = 2)) ./ n               # joint MLE of the log-scale per-trait mean
    R = Z .- β̂                                    # centred log-responses
    gfit = fit_gaussian_gllvm(R; K = K, kwargs...)
    Λ̂ = gfit.pars.Λ
    σ̂ = gfit.pars.σ_eps
    # y-scale lognormal marginal at the fitted parameters (Gaussian + Jacobian).
    ll = gfit.logLik - sum(Z)
    return LognormalFit(collect(float.(β̂)), Matrix{Float64}(Λ̂), Float64(σ̂),
                        LogLink(), Float64(ll), gfit.converged, gfit.n_iter)
end
