# Gaussian GLLVM marginal log-likelihood (closed-form).
#
# Single-tier (J1):  y[t,s] = (Λ_B η_s)[t] + X[t,s,:]' β + ε[t,s]
# With W tier and diagonal random effects (J2-A-WD), the engine adds
# per-observation terms:
#   y[t,s] = (Λ_B η_s)[t] + sum_k Λ_W[t,k] η_W[k,t,s]
#          + s_B[t,s] + s_W[t,s] + X[t,s,:]' β + ε[t,s]
# where η_s ~ N(0, I_{K_B}), η_W[:,t,s] ~ N(0, I_{K_W}) (per (t, s)!),
# s_B[t,s] ~ N(0, σ²_B[t]), s_W[t,s] ~ N(0, σ²_W[t]), ε ~ N(0, σ²_eps).
#
# Marginal site covariance (per site s):
#   Σ_y_site = Λ_B Λ_B' + diag(d_total)
#   d_total[t] = (Λ_W Λ_W')[t,t] + σ²_B[t] + σ²_W[t] + σ²_eps
# because the W tier and diag REs are independent across (t, s) and so
# contribute only to the per-trait diagonal of cov(y[:, s]).
#
# Generalised Woodbury (D = diag(d_total)):
#   Σ⁻¹ = D⁻¹ - D⁻¹ Λ_B (I + Λ_B' D⁻¹ Λ_B)⁻¹ Λ_B' D⁻¹
#   logdet(Σ) = sum(log.(d_total)) + logdet(I + Λ_B' D⁻¹ Λ_B)
# When D = σ²_eps I (the J1 case) this collapses to the J1 formula.

"""
    gaussian_marginal_loglik(y, Λ_B, σ_eps; X=nothing, β=nothing,
                              Λ_W=nothing, σ²_B=nothing, σ²_W=nothing) -> Real

Marginal log-likelihood of `y` (size p × n_sites) under the Gaussian
GLLVM with unit-tier loadings `Λ_B` (p × K_B), residual SD `σ_eps`,
and optional W tier (`Λ_W`, p × K_W) and per-trait diagonal random
effects (`σ²_B`, `σ²_W`, length p, positive variances).

The per-trait diagonal contribution is
    d_total[t] = (Λ_W Λ_W')[t,t] + σ²_B[t] + σ²_W[t] + σ²_eps.
The site covariance is `Σ_y = Λ_B Λ_B' + diag(d_total)`, inverted via
Woodbury (cost O(p K_B² + K_B³) per site).

Fixed effects: pass both `X::Array{<:Real, 3}` of shape (p, n_sites, q)
and `β::Vector` of length q, or neither.

`Λ_W = nothing`, `σ²_B = nothing`, `σ²_W = nothing` together reproduce
the J1 behaviour exactly (D = σ²_eps I).
"""
function gaussian_marginal_loglik(y::AbstractMatrix, Λ_B::AbstractMatrix, σ_eps::Real;
                                  X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                                  β::Union{Nothing, AbstractVector} = nothing,
                                  Λ_W::Union{Nothing, AbstractMatrix} = nothing,
                                  σ²_B::Union{Nothing, AbstractVector} = nothing,
                                  σ²_W::Union{Nothing, AbstractVector} = nothing)
    p, n = size(y)
    K    = size(Λ_B, 2)
    σ²   = σ_eps^2
    T    = promote_type(eltype(y), eltype(Λ_B), typeof(σ²))

    # Residual ε = y - X * β  if fixed effects supplied
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

    # Build per-trait diagonal d_total[t] = (Λ_W Λ_W')[t,t] + σ²_B[t] + σ²_W[t] + σ²
    # Element types must promote with σ², the existing T (data + Λ_B), and any
    # provided Λ_W / σ²_B / σ²_W (relevant under AD with Duals).
    Td = T
    if Λ_W !== nothing
        size(Λ_W, 1) == p ||
            throw(ArgumentError("Λ_W first dim ($(size(Λ_W, 1))) must equal p ($p)"))
        Td = promote_type(Td, eltype(Λ_W))
    end
    if σ²_B !== nothing
        length(σ²_B) == p ||
            throw(ArgumentError("σ²_B length ($(length(σ²_B))) must equal p ($p)"))
        Td = promote_type(Td, eltype(σ²_B))
    end
    if σ²_W !== nothing
        length(σ²_W) == p ||
            throw(ArgumentError("σ²_W length ($(length(σ²_W))) must equal p ($p)"))
        Td = promote_type(Td, eltype(σ²_W))
    end

    d_total = Vector{Td}(undef, p)
    @inbounds for t in 1:p
        v = convert(Td, σ²)
        if Λ_W !== nothing
            K_W = size(Λ_W, 2)
            for k in 1:K_W
                v += Λ_W[t, k]^2
            end
        end
        if σ²_B !== nothing
            v += σ²_B[t]
        end
        if σ²_W !== nothing
            v += σ²_W[t]
        end
        d_total[t] = v
    end

    # Generalised Woodbury:
    #   Σ_y = Λ_B Λ_B' + diag(d_total)
    #   Σ_y⁻¹ r = D⁻¹ r - D⁻¹ Λ_B (I + Λ_B' D⁻¹ Λ_B)⁻¹ Λ_B' D⁻¹ r
    #   logdet(Σ_y) = sum(log.(d_total)) + logdet(I + Λ_B' D⁻¹ Λ_B)
    d_inv = Vector{Td}(undef, p)
    @inbounds for t in 1:p
        d_inv[t] = one(Td) / d_total[t]
    end

    # A_K = I_K + Λ_B' D⁻¹ Λ_B  (K × K, cheap)
    DinvΛ = (d_inv) .* Λ_B                              # p × K, broadcast scales rows
    A_K   = I + Λ_B' * DinvΛ                            # K × K
    cA    = cholesky(Symmetric(A_K))

    logdet_Σ = sum(log, d_total) + logdet(cA)

    # quadratic form Σ_s r_s' Σ_y⁻¹ r_s
    #   D⁻¹ r              -> Dinv_r  (p × n)
    #   Λ_B' D⁻¹ r         -> ΛtDr    (K × n)
    #   (I + Λ_B' D⁻¹ Λ_B)⁻¹ Λ_B' D⁻¹ r -> z (K × n) via cA \
    #   D⁻¹ Λ_B z          -> DinvΛz (p × n)
    #   Σ⁻¹ r = D⁻¹ r - D⁻¹ Λ_B z
    Dinv_r = d_inv .* resid                              # p × n
    ΛtDr   = Λ_B' * Dinv_r                               # K × n
    z      = cA \ ΛtDr                                   # K × n
    DinvΛz = DinvΛ * z                                   # p × n
    Σinv_r = Dinv_r .- DinvΛz                            # p × n
    quad   = sum(resid .* Σinv_r)

    Tout = promote_type(T, Td)
    -convert(Tout, 0.5) * (n * p * log(convert(Tout, 2π)) + n * logdet_Σ + quad)
end

# ---------------------------------------------------------------------------
# Packed NLL drivers
# ---------------------------------------------------------------------------

"""
    gaussian_nll_packed(params, y, p, K; X=nothing, q=0) -> Real

J1 / J2-A signature (single-tier, optional fixed effects). Parameter
layout:
- `params[1:q]`     = β (when `q > 0`)
- `params[q + 1]`   = log σ_eps
- `params[(q+2):end]` = θ_rr (packed Λ_B, length `rr_theta_len(p, K)`)
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

"""
    gaussian_nll_packed(params, y; spec) -> Real

J2-A-WD signature carrying a `spec::NamedTuple` with fields
`(q, p, K_B, K_W, has_diag)`. Parameter layout:

    [β               (spec.q entries)
     log_σ_eps       (1)
     log_σ_B         (p entries if spec.has_diag)
     log_σ_W         (p entries if spec.has_diag)
     θ_rr_B          (rr_theta_len(p, K_B) entries)
     θ_rr_W          (rr_theta_len(p, K_W) entries if spec.K_W > 0)]

`X` may be passed as a keyword (required iff `spec.q > 0`).

For the J1 case `(K_W = 0, has_diag = false)`, the layout collapses to
`[β; log_σ_eps; θ_rr_B]` and the result matches the legacy positional
method above.
"""
function gaussian_nll_packed(params::AbstractVector, y::AbstractMatrix;
                             spec::NamedTuple,
                             X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing)
    q        = spec.q
    p        = spec.p
    K_B      = spec.K_B
    K_W      = spec.K_W
    has_diag = spec.has_diag

    size(y, 1) == p ||
        throw(ArgumentError("y first dim ($(size(y, 1))) must equal spec.p ($p)"))

    rr_B = rr_theta_len(p, K_B)
    rr_W = K_W > 0 ? rr_theta_len(p, K_W) : 0
    diag_count = has_diag ? 2 * p : 0
    n_expected = q + 1 + diag_count + rr_B + rr_W
    length(params) == n_expected || throw(ArgumentError(
        "params length ($(length(params))) must equal $n_expected " *
        "(q=$q + 1 + diag=$(diag_count) + rr_B=$rr_B + rr_W=$rr_W)"))

    # Layout cursor
    cursor = 0

    if q > 0
        X === nothing && throw(ArgumentError("spec.q = $q > 0 requires X"))
        size(X, 3) == q || throw(ArgumentError(
            "size(X, 3) ($(size(X, 3))) must equal spec.q ($q)"))
        β = @view params[(cursor + 1):(cursor + q)]
        cursor += q
    else
        X === nothing || throw(ArgumentError("spec.q = 0 but X was supplied"))
        β = nothing
    end

    log_σ_eps = params[cursor + 1]
    cursor += 1

    if has_diag
        log_σ_B = @view params[(cursor + 1):(cursor + p)]
        cursor += p
        log_σ_W = @view params[(cursor + 1):(cursor + p)]
        cursor += p
        # Variances on the natural scale.
        σ²_B = exp.(2 .* log_σ_B)
        σ²_W = exp.(2 .* log_σ_W)
    else
        σ²_B = nothing
        σ²_W = nothing
    end

    θ_rr_B = @view params[(cursor + 1):(cursor + rr_B)]
    cursor += rr_B
    Λ_B    = unpack_lambda(θ_rr_B, p, K_B)

    if K_W > 0
        θ_rr_W = @view params[(cursor + 1):(cursor + rr_W)]
        cursor += rr_W
        Λ_W    = unpack_lambda(θ_rr_W, p, K_W)
    else
        Λ_W = nothing
    end

    σ_eps = exp(log_σ_eps)
    -gaussian_marginal_loglik(y, Λ_B, σ_eps;
                              X = X, β = β,
                              Λ_W = Λ_W, σ²_B = σ²_B, σ²_W = σ²_W)
end
