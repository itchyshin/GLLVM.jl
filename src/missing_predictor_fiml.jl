# Missing-predictor FIML for the Gaussian GLLVM — the mi() axis, Phase-2a slice.
#
# A single site-level continuous predictor x (one value per site, possibly
# `missing`) enters the response mean with a slope b_x broadcast across all
# traits (gllvmTMB's mi() unit-level semantic). x is given a covariate model
# x_s ~ N(μ_x, σ_x²) and the missing x_s are integrated out in CLOSED FORM,
# because (y_s, x_s) is jointly Gaussian — this is full-information maximum
# likelihood, NOT impute-then-analyse.
#
# Per site s, with η_s ~ N(0, I_K), ε_s ~ N(0, σ_eps² I_p):
#   x_s = μ_x + e_x,           e_x ~ N(0, σ_x²)
#   y_s = a + b_x x_s 1_p + Λ_B η_s + ε_s
# so the joint of (y_s, x_s) is Gaussian. FIML over observed cells:
#   • x_s observed → log N(y_s | x_s) + log N(x_s)         (condition on x)
#       with Cov(y_s | x_s) = Λ_B Λ_Bᵀ + σ_eps² I
#   • x_s missing  → log N(y_s) marginal                   (integrate out x)
#       with Cov(y_s) = Λ_B Λ_Bᵀ + σ_eps² I + b_x² σ_x² 11ᵀ
#                     = Λ_aug Λ_augᵀ + σ_eps² I,  Λ_aug = [Λ_B | b_x σ_x 1_p]
# Both per-site densities are `low-rank + σ²I`, so one Woodbury kernel serves
# both (rank K observed, rank K+1 missing). No Laplace, no formula parser.
#
# Closed form is exact for Gaussian y + Gaussian x; b_x and σ_x are jointly
# identified because x is observed at the non-missing sites. Non-Gaussian
# responses or discrete/structured missing predictors need the Laplace
# augmented-latent path (out of scope for this slice).
#
# Reference: gllvmTMB mi() Phase 2a (continuous site-level predictor);
# Little & Rubin 2002 (FIML for missing data).

using LinearAlgebra

# 0.5 (p log 2π + logdet Σ + rᵀ Σ⁻¹ r) for Σ = L Lᵀ + s2 I_p, L is p×m, via the
# matrix-determinant lemma + Woodbury (only an m×m factorisation; m = K or K+1).
function _mi_lowrank_halfnll(r::AbstractVector, L::AbstractMatrix, s2::Real)
    p, m = size(L)
    M = (L' * L) ./ s2 + I            # m×m
    cholM = cholesky(Symmetric(M))
    logdetΣ = p * log(s2) + logdet(cholM)
    Ltr = L' * r
    w = cholM \ (Ltr ./ s2)           # M⁻¹ (Lᵀ r / s2)
    Σinv_r = (r .- L * w) ./ s2
    return 0.5 * (p * log(2π) + logdetΣ + dot(r, Σinv_r))
end

# Σ⁻¹ r for Σ = L Lᵀ + s2 I (concrete post-fit use, e.g. EBLUPs).
function _mi_lowrank_solve(r::AbstractVector, L::AbstractMatrix, s2::Real)
    M = (L' * L) ./ s2 + I
    w = cholesky(Symmetric(M)) \ (L' * r ./ s2)
    return (r .- L * w) ./ s2
end

function _mi_fiml_nll(params, y, xobs, isobs, p::Int, n::Int, K::Int)
    a = @view params[1:p]
    b_x = params[p + 1]
    μ_x = params[p + 2]
    log_σx = params[p + 3]
    σ_x2 = exp(2 * log_σx)
    σ_eps2 = exp(2 * params[p + 4])
    Λ = reshape(@view(params[(p + 5):(p + 4 + p * K)]), p, K)
    Λ_aug = hcat(Λ, (b_x * exp(log_σx)) .* ones(eltype(params), p))

    nll = zero(eltype(params))
    @inbounds for s in 1:n
        ys = @view y[:, s]
        if isobs[s]
            r = ys .- (a .+ b_x * xobs[s])
            nll += _mi_lowrank_halfnll(r, Λ, σ_eps2)
            nll += 0.5 * (log(2π) + 2 * log_σx + (xobs[s] - μ_x)^2 / σ_x2)
        else
            r = ys .- (a .+ b_x * μ_x)
            nll += _mi_lowrank_halfnll(r, Λ_aug, σ_eps2)
        end
    end
    return nll
end

"""
    fit_gaussian_mi_fiml(y, x; K, x_tol=1e-8, g_tol=1e-8, iterations=1000)
        -> NamedTuple

Fit a Gaussian GLLVM with one site-level continuous predictor `x` whose missing
entries are integrated out by full-information maximum likelihood. `y` is `p × n`
(traits × sites); `x` is length `n` (one value per site) and may contain
`missing` or `NaN`. The predictor enters the response mean with a single slope
`b_x` broadcast across all traits, and is modelled as `x ~ N(μ_x, σ_x²)`.

Returns a NamedTuple with `b_x`, the per-trait intercepts `a`, covariate-model
params `μ_x`, `σ_x`, residual `σ_eps`, loadings `Λ` (`p × K`), the conditional
modes `eblup_x` (length `n`; observed values at observed sites, `E[x_s | y_s]`
at missing sites), `logLik`, `converged`, and `n_missing`.

Faithful to gllvmTMB's `mi()` Phase 2a (continuous site-level predictor). The
closed-form FIML is exact for the all-Gaussian case — no imputation, no Laplace.
"""
function fit_gaussian_mi_fiml(y::AbstractMatrix, x::AbstractVector; K::Integer,
                              g_tol::Real = 1e-8, iterations::Integer = 1000)
    p, n = size(y)
    length(x) == n ||
        throw(ArgumentError("length(x) = $(length(x)) must equal n_sites = $n."))
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1."))

    isobs = [!(ismissing(xi) || (xi isa Real && isnan(xi))) for xi in x]
    any(isobs) || throw(ArgumentError("x has no observed values."))
    xobs = [isobs[s] ? Float64(x[s]) : 0.0 for s in 1:n]
    n_missing = count(!, isobs)

    # warm start
    a0 = vec(Statistics.mean(y, dims = 2))
    xo = xobs[isobs]
    μ_x0 = Statistics.mean(xo)
    σ_x0 = max(Statistics.std(xo), 1e-3)
    ybar = vec(Statistics.mean(y .- a0, dims = 1))          # site-mean residual
    b_x0 = let xc = xobs[isobs] .- μ_x0
        sum(xc .* ybar[isobs]) / max(sum(abs2, xc), 1e-8)
    end
    Yc = y .- a0
    C = Symmetric((Yc * Yc') ./ n)
    E = eigen(C)
    idx = sortperm(E.values, rev = true)[1:K]
    Λ0 = E.vectors[:, idx] .* sqrt.(max.(E.values[idx] .- 1e-2, 1e-2))'
    σ_eps0 = sqrt(max(Statistics.mean(E.values[1:max(1, p - K)]), 1e-2))

    params0 = vcat(a0, b_x0, μ_x0, log(σ_x0), log(σ_eps0), vec(Λ0))
    nll(θ) = _mi_fiml_nll(θ, y, xobs, isobs, p, n, K)

    opts = Optim.Options(g_tol = g_tol, iterations = iterations)
    res = Optim.optimize(nll, params0, Optim.LBFGS(), opts; autodiff = :forward)
    θ = Optim.minimizer(res)

    a = θ[1:p]
    b_x = θ[p + 1]
    μ_x = θ[p + 2]
    σ_x = exp(θ[p + 3])
    σ_eps = exp(θ[p + 4])
    Λ = reshape(θ[(p + 5):(p + 4 + p * K)], p, K)

    # EBLUPs: observed value, or E[x_s | y_s] at missing sites.
    Λ_aug = hcat(Λ, (b_x * σ_x) .* ones(p))
    eblup = Vector{Float64}(undef, n)
    for s in 1:n
        if isobs[s]
            eblup[s] = xobs[s]
        else
            r = y[:, s] .- (a .+ b_x * μ_x)
            eblup[s] = μ_x + b_x * σ_x^2 * sum(_mi_lowrank_solve(r, Λ_aug, σ_eps^2))
        end
    end

    return (b_x = b_x, a = a, μ_x = μ_x, σ_x = σ_x, σ_eps = σ_eps, Λ = Λ,
            eblup_x = eblup, logLik = -Optim.minimum(res),
            converged = Optim.converged(res), n_missing = n_missing)
end
