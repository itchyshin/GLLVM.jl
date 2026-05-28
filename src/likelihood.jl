# Gaussian GLLVM marginal log-likelihood (single-tier, closed-form).
#
# Model:  y[t,s] = (Λ * η_s)[t] + ε[t,s], η_s ~ N(0, I_K), ε ~ N(0, σ²)
# Marginal:  y_s ~ N(0, Λ Λ' + σ² I_p)
# Closed-form because everything is Gaussian; no Laplace approximation.

"""
    gaussian_marginal_loglik(y, Λ, σ_eps) -> Real

Marginal log-likelihood of `y` (size p × n_sites) under the Gaussian
GLLVM with loading matrix `Λ` (p × K) and observation SD `σ_eps`.

Uses the Woodbury identity for the p × p covariance inversion, so cost
is O(p K² + K³) per site rather than O(p³).
"""
function gaussian_marginal_loglik(y::AbstractMatrix, Λ::AbstractMatrix, σ_eps::Real)
    p, n = size(y)
    K    = size(Λ, 2)
    σ²   = σ_eps^2
    T    = promote_type(eltype(y), eltype(Λ), typeof(σ²))

    # M = (σ² I_K + Λ' Λ)⁻¹  (K × K, cheap)
    A    = σ² * I + Λ'Λ                # K × K
    cA   = cholesky(Symmetric(A))      # PSD by construction
    # logdet(Σ_y) = (p - K) log σ² + logdet(A)
    logdet_Σ = (p - K) * log(σ²) + logdet(cA)

    # quadratic form Σ_s y_s' Σ_y⁻¹ y_s
    # Σ_y⁻¹ y = (1/σ²) (y - Λ M Λ' y) = (1/σ²) (y - Λ (cA \ (Λ' y)))
    ΛTY  = Λ' * y                       # K × n
    Z    = cA \ ΛTY                     # K × n
    R    = y .- Λ * Z                   # p × n
    quad = sum(y .* R) / σ²

    -convert(T, 0.5) * (n * p * log(convert(T, 2π)) + n * logdet_Σ + quad)
end

# Convenience helper: log-likelihood as a function of (theta_rr, log_σ_eps)
# given fixed (y, p, K). Used by the Optim driver in fit.jl.
"""
    gaussian_nll_packed(params, y, p, K) -> Real

Negative log-likelihood as a function of the packed parameter vector
`params = [log_σ_eps; θ_rr]` (length 1 + rr_theta_len(p, K)).
Unpacks Λ via `unpack_lambda` (defined in packing.jl).
"""
function gaussian_nll_packed(params::AbstractVector, y::AbstractMatrix, p::Integer, K::Integer)
    log_σ = params[1]
    θ_rr  = @view params[2:end]
    Λ     = unpack_lambda(θ_rr, p, K)
    σ_eps = exp(log_σ)
    -gaussian_marginal_loglik(y, Λ, σ_eps)
end
