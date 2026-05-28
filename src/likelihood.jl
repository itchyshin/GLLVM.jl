# Gaussian GLLVM marginal log-likelihood (single-tier, closed-form).
#
# Model:  y[t,s] = (Λ * η_s)[t] + (X[t,s,:]' * β) + ε[t,s],
#         η_s ~ N(0, I_K), ε ~ N(0, σ²)
# Marginal:  y_s - X[:,s,:] β ~ N(0, Λ Λ' + σ² I_p)
# Closed-form because everything is Gaussian; no Laplace approximation.

"""
    gaussian_marginal_loglik(y, Λ, σ_eps; X=nothing, β=nothing) -> Real

Marginal log-likelihood of `y` (size p × n_sites) under the Gaussian
GLLVM with loading matrix `Λ` (p × K) and observation SD `σ_eps`.

Uses the Woodbury identity for the p × p covariance inversion, so cost
is O(p K² + K³) per site rather than O(p³).

Optional fixed-effects:
- `X::AbstractArray{<:Real, 3}` of shape `(p, n_sites, q)`: per-trait,
  per-site covariates. `X[t, s, :]' * β` is the mean contribution at
  observation (t, s).
- `β::AbstractVector` of length `q`: regression coefficients.

`X = nothing` and `β = nothing` together preserve the no-fixed-effects
behaviour. Either both must be supplied or neither.
"""
function gaussian_marginal_loglik(y::AbstractMatrix, Λ::AbstractMatrix, σ_eps::Real;
                                  X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                                  β::Union{Nothing, AbstractVector} = nothing)
    p, n = size(y)
    K    = size(Λ, 2)
    σ²   = σ_eps^2
    T    = promote_type(eltype(y), eltype(Λ), typeof(σ²))

    # Compute residual ε = y - X * β  if fixed effects supplied
    if X === nothing && β === nothing
        resid = y
    else
        (X === nothing || β === nothing) &&
            throw(ArgumentError("Provide both X and β or neither"))
        q = size(X, 3)
        size(X, 1) == p ||
            throw(ArgumentError("X first dim ($(size(X,1))) must equal p ($p)"))
        size(X, 2) == n ||
            throw(ArgumentError("X second dim ($(size(X,2))) must equal n_sites ($n)"))
        length(β) == q ||
            throw(ArgumentError("β length ($(length(β))) must equal size(X, 3) ($q)"))
        Tres = promote_type(T, eltype(X), eltype(β))
        resid = Matrix{Tres}(undef, p, n)
        @inbounds for s in 1:n, t in 1:p
            μ_ts = zero(Tres)
            for k in 1:q
                μ_ts += X[t, s, k] * β[k]
            end
            resid[t, s] = y[t, s] - μ_ts
        end
    end

    # M = (σ² I_K + Λ' Λ)⁻¹  (K × K, cheap)
    A    = σ² * I + Λ'Λ                # K × K
    cA   = cholesky(Symmetric(A))      # PSD by construction
    # logdet(Σ_y) = (p - K) log σ² + logdet(A)
    logdet_Σ = (p - K) * log(σ²) + logdet(cA)

    # quadratic form Σ_s r_s' Σ_y⁻¹ r_s  where r_s = y_s - X[:,s,:] β
    # Σ_y⁻¹ r = (1/σ²) (r - Λ M Λ' r) = (1/σ²) (r - Λ (cA \ (Λ' r)))
    ΛTR  = Λ' * resid                   # K × n
    Z    = cA \ ΛTR                     # K × n
    R    = resid .- Λ * Z               # p × n
    quad = sum(resid .* R) / σ²

    -convert(T, 0.5) * (n * p * log(convert(T, 2π)) + n * logdet_Σ + quad)
end

# Convenience helper: log-likelihood as a function of (theta_rr, log_σ_eps)
# given fixed (y, p, K). Used by the Optim driver in fit.jl.
"""
    gaussian_nll_packed(params, y, p, K; X=nothing, q=0) -> Real

Negative log-likelihood as a function of the packed parameter vector.

Parameter layout (1-based):
- `params[1:q]`     = β (fixed-effects coefficients), present iff `q > 0`
- `params[q + 1]`   = log σ_eps
- `params[(q+2):end]` = θ_rr (packed Λ, length `rr_theta_len(p, K)`)

When `X` is supplied, `q = size(X, 3)` must be passed too (the caller
knows this dimension; we don't infer it from `params` to keep the
slicing unambiguous).
"""
function gaussian_nll_packed(params::AbstractVector, y::AbstractMatrix,
                             p::Integer, K::Integer;
                             X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                             q::Integer = 0)
    if X === nothing
        q == 0 || throw(ArgumentError("q must be 0 when X is nothing"))
        β = nothing
    else
        q == size(X, 3) ||
            throw(ArgumentError("q ($q) must equal size(X, 3) ($(size(X, 3)))"))
        β = @view params[1:q]
    end
    log_σ = params[q + 1]
    θ_rr  = @view params[(q + 2):end]
    Λ     = unpack_lambda(θ_rr, p, K)
    σ_eps = exp(log_σ)
    -gaussian_marginal_loglik(y, Λ, σ_eps; X = X, β = β)
end
