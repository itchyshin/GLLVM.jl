# Faithful cross-lineage coevolution — the Kronecker (matrix-normal) fitter.
#
# Unlike the Hadamard cross-kernel fit (which proves K* is necessary but recovers
# Γ only weakly from one dataset), this trait⊗species form RECOVERS the
# coevolution estimand Γ = Λ_H Λ_Pᵀ, because the trait loadings Λ are identified
# from covariation across the many species — the gllvmTMB identifiability.
#
# Model (complete data, one observation per species):
#   Y (T × n) ~ MN(0, Σ_T, K*),  Σ_T = Λ Λᵀ + σ² I_T,  Λ is T×d
#   i.e. Cov(vec Y) = K* ⊗ Σ_T.   K* = make_cross_kernel(A_H, A_P, W, ρ) (n×n).
# Γ = (Λ Λᵀ)[1:T_H, (T_H+1):T] is the host-trait × partner-trait block.
#
# Marginal via the Kronecker eigentrick (validated to machine precision against
# the brute-force K* ⊗ Σ_T density): eigendecompose K* = V diag(d) Vᵀ once; the
# columns of Ỹ = Y V are independent, Ỹ[:,j] ~ N(0, d_j Σ_T), so
#   −2 logL = T n log(2π) + T Σ_j log(d_j) + n logdet(Σ_T)
#             + tr(Σ_T⁻¹ Ỹ diag(1/d_j) Ỹᵀ)
# Cost: one n×n eigendecomposition (constant) + a T×T cholesky per NLL eval.
#
# Complete-data slice; block-NA (host species lacking partner traits) and
# replication are deferred — see docs/dev-log/2026-06-13-coevolution-kronecker-design.md.
# Reference: Tolkoff et al. 2018 (phylogenetic factor analysis); the gllvmTMB
# cross-lineage coevolution kernel.

using LinearAlgebra

function _coevolution_kron_precompute(K_star::AbstractMatrix)
    E = eigen(Symmetric(Matrix(K_star)))
    dv = E.values
    minimum(dv) > 0 ||
        throw(ArgumentError("K_star must be positive definite (min eigenvalue $(minimum(dv)))."))
    return E.vectors, dv
end

# params = [vec(Λ) (T*d), log σ]
function _coevolution_kron_nll(params, Y, V, dv, T::Int, n::Int, d::Int)
    Λ = reshape(@view(params[1:(T * d)]), T, d)
    σ2 = exp(2 * params[T * d + 1])
    Σ_T = Λ * Λ' + σ2 * I
    cholΣ = cholesky(Symmetric(Σ_T))
    Ỹ = Y * V                                   # T×n (Y, V constant data)
    quad = zero(eltype(params))
    @inbounds for j in 1:n
        yj = @view Ỹ[:, j]
        quad += dot(yj, cholΣ \ yj) / dv[j]
    end
    logdetterm = T * sum(log, dv) + n * logdet(cholΣ)
    return 0.5 * (T * n * log(2π) + logdetterm + quad)
end

"""
    fit_coevolution_gaussian(Y, K_star; d, g_tol=1e-8, iterations=1000)
        -> NamedTuple

Fit the matrix-normal cross-lineage coevolution model
`Y (T × n) ~ MN(0, Λ Λᵀ + σ² I, K_star)` by maximum likelihood, where `Y` is
`T × n` (stacked traits × stacked species, host block first), `K_star` is the
`n × n` species cross-kernel from `make_cross_kernel`, and `Λ` is the
`T × d` trait loadings. Recovers the coevolution estimand
`Γ = (Λ Λᵀ)[1:T_H, (T_H+1):T]` faithfully (the trait⊗species identifiability the
Hadamard fit lacks).

Returns a NamedTuple with `Λ` (`T × d`), `σ`, `logLik`, and `converged`. Slice
the host×partner block of `Λ Λᵀ` for `Γ`. Complete-data only; block-NA and
replication are deferred.
"""
function fit_coevolution_gaussian(Y::AbstractMatrix, K_star::AbstractMatrix;
                                  d::Integer, g_tol::Real = 1e-8,
                                  iterations::Integer = 1000)
    T, n = size(Y)
    (size(K_star, 1) == n && size(K_star, 2) == n) ||
        throw(ArgumentError("K_star must be n × n = $n × $n; got $(size(K_star))."))
    d ≥ 1 || throw(ArgumentError("d must be ≥ 1."))
    d ≤ T || throw(ArgumentError("d must be ≤ T = $T."))

    V, dv = _coevolution_kron_precompute(K_star)

    # warm start: trait covariance estimate S = Ỹ diag(1/d_j) Ỹᵀ / n, then PCA.
    Ỹ = Y * V
    S = Symmetric((Ỹ * Diagonal(1 ./ dv) * Ỹ') ./ n)
    E = eigen(S)
    idx = sortperm(E.values, rev = true)
    σ0 = d < T ? sqrt(max(Statistics.mean(E.values[idx[(d + 1):end]]), 1e-2)) : 0.1
    Λ0 = E.vectors[:, idx[1:d]] .* sqrt.(max.(E.values[idx[1:d]] .- σ0^2, 1e-2))'

    params0 = vcat(vec(Λ0), log(σ0))
    nll(θ) = _coevolution_kron_nll(θ, Y, V, dv, T, n, d)
    res = Optim.optimize(nll, params0, Optim.LBFGS(),
                         Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :forward)
    θ = Optim.minimizer(res)
    Λ = reshape(θ[1:(T * d)], T, d)
    σ = exp(θ[T * d + 1])
    return (Λ = Λ, σ = σ, logLik = -Optim.minimum(res), converged = Optim.converged(res))
end
