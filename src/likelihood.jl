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
#
# Phylogenetic extension (J3):
# Two extra contributions, both *species-level* (shared across sites):
#   phylo_latent: y[t, s] += Σ_k Λ_phy[t, k] η_phy[k, t]
#       where η_phy[k, :] ~ MVN(0, Σ_phy) independently per axis k.
#   phylo_unique: y[t, s] += s_phy[t]
#       where s_phy[t] = σ_phy[t] * φ[t], φ ~ MVN(0, Σ_phy) once.
# Letting Λ_phy_aug = hcat(Λ_phy, σ_phy) (p × (K_phy + 1)), the marginal
# covariance of y_full = vec(y) (column-major) becomes:
#   Σ_y_full = I_n ⊗ A + J_n ⊗ B
# where A = Λ_B Λ_B' + diag(d_total) (the J2 site covariance) and
#       B = (Λ_phy_aug Λ_phy_aug') .* Σ_phy
# (Hadamard product with the supplied species covariance Σ_phy, p × p).
# J_n = 1_n 1_n' is rank 1: eigenvalue n with eigenvector 1_n/√n, and
# (n − 1) zero eigenvalues. In a basis with first row 1_n/√n the (p·n
# × p·n) covariance is block-diagonal: diag(A + n·B, A, …, A). Hence:
#   logdet(Σ_y_full) = logdet(A + n·B) + (n − 1)·logdet(A)
#   y' Σ⁻¹ y = n · m' (A + n·B)⁻¹ m + tr(Y_c' A⁻¹ Y_c)
# where m = mean(y, dims=2) and Y_c = y .- m. Two p×p Cholesky factor-
# isations suffice regardless of n.

"""
    gaussian_marginal_loglik(y, Λ_B, σ_eps; X=nothing, β=nothing,
                              Λ_W=nothing, σ²_B=nothing, σ²_W=nothing,
                              Λ_phy=nothing, σ_phy=nothing,
                              Σ_phy=nothing) -> Real

Marginal log-likelihood of `y` (size p × n_sites) under the Gaussian
GLLVM with unit-tier loadings `Λ_B` (p × K_B), residual SD `σ_eps`,
and optional W tier (`Λ_W`, p × K_W) and per-trait diagonal random
effects (`σ²_B`, `σ²_W`, length p, positive variances).

The per-trait diagonal contribution is
    d_total[t] = (Λ_W Λ_W')[t,t] + σ²_B[t] + σ²_W[t] + σ²_eps.
Without phylogeny, the site covariance is `A = Λ_B Λ_B' + diag(d_total)`,
inverted via Woodbury (cost O(p K_B² + K_B³) per site).

Fixed effects: pass both `X::Array{<:Real, 3}` of shape (p, n_sites, q)
and `β::Vector` of length q, or neither.

`Λ_W = nothing`, `σ²_B = nothing`, `σ²_W = nothing` together reproduce
the J1 behaviour exactly (D = σ²_eps I).

Phylogenetic extension (`Σ_phy::AbstractMatrix`, p × p, supplied by
caller — typically a species-trait covariance derived from a tree):
  - `Λ_phy::AbstractMatrix` (p × K_phy): phylo-latent loadings.
  - `σ_phy::AbstractVector` (length p): per-trait phylo-unique SDs.
With Λ_phy_aug = hcat(Λ_phy, σ_phy) the marginal covariance of vec(y)
is `I_n ⊗ A + J_n ⊗ B` where `B = (Λ_phy_aug Λ_phy_aug') .* Σ_phy`.
The rotation trick (J_n has rank 1) reduces this to two p×p Cholesky
factorisations regardless of n.
"""
function gaussian_marginal_loglik(y::AbstractMatrix, Λ_B::AbstractMatrix, σ_eps::Real;
                                  X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                                  β::Union{Nothing, AbstractVector} = nothing,
                                  Λ_W::Union{Nothing, AbstractMatrix} = nothing,
                                  σ²_B::Union{Nothing, AbstractVector} = nothing,
                                  σ²_W::Union{Nothing, AbstractVector} = nothing,
                                  Λ_phy::Union{Nothing, AbstractMatrix} = nothing,
                                  σ_phy::Union{Nothing, AbstractVector} = nothing,
                                  Σ_phy::Union{Nothing, AbstractMatrix} = nothing)
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

    # Phylogenetic block: Σ_phy is the (p × p) species covariance supplied by
    # the caller. Without Σ_phy the J3 branch is skipped and the code falls
    # back to the J2 site-stacked Woodbury path.
    has_phy = Σ_phy !== nothing && (Λ_phy !== nothing || σ_phy !== nothing)
    if Σ_phy !== nothing
        size(Σ_phy, 1) == p ||
            throw(ArgumentError("Σ_phy first dim ($(size(Σ_phy, 1))) must equal p ($p)"))
        size(Σ_phy, 2) == p ||
            throw(ArgumentError("Σ_phy second dim ($(size(Σ_phy, 2))) must equal p ($p)"))
        Td = promote_type(Td, eltype(Σ_phy))
    end
    if Λ_phy !== nothing
        size(Λ_phy, 1) == p ||
            throw(ArgumentError("Λ_phy first dim ($(size(Λ_phy, 1))) must equal p ($p)"))
        Td = promote_type(Td, eltype(Λ_phy))
    end
    if σ_phy !== nothing
        length(σ_phy) == p ||
            throw(ArgumentError("σ_phy length ($(length(σ_phy))) must equal p ($p)"))
        Td = promote_type(Td, eltype(σ_phy))
    end
    if has_phy && Σ_phy === nothing
        throw(ArgumentError("Σ_phy must be supplied when Λ_phy or σ_phy is non-nothing"))
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

    if !has_phy
        # ----- J2-A-WD path: site-stacked Woodbury, A = Λ_B Λ_B' + diag(d_total)
        #   Σ_y = Λ_B Λ_B' + diag(d_total)
        #   Σ_y⁻¹ r = D⁻¹ r - D⁻¹ Λ_B (I + Λ_B' D⁻¹ Λ_B)⁻¹ Λ_B' D⁻¹ r
        #   logdet(Σ_y) = sum(log.(d_total)) + logdet(I + Λ_B' D⁻¹ Λ_B)
        d_inv = Vector{Td}(undef, p)
        @inbounds for t in 1:p
            d_inv[t] = one(Td) / d_total[t]
        end

        # A_K = I_K + Λ_B' D⁻¹ Λ_B  (K × K, cheap)
        DinvΛ = (d_inv) .* Λ_B                          # p × K, broadcast scales rows
        A_K   = I + Λ_B' * DinvΛ                        # K × K
        cA    = cholesky(Symmetric(A_K))

        logdet_Σ = sum(log, d_total) + logdet(cA)

        # quadratic form Σ_s r_s' Σ_y⁻¹ r_s
        #   D⁻¹ r              -> Dinv_r  (p × n)
        #   Λ_B' D⁻¹ r         -> ΛtDr    (K × n)
        #   (I + Λ_B' D⁻¹ Λ_B)⁻¹ Λ_B' D⁻¹ r -> z (K × n) via cA \
        #   D⁻¹ Λ_B z          -> DinvΛz (p × n)
        #   Σ⁻¹ r = D⁻¹ r - D⁻¹ Λ_B z
        Dinv_r = d_inv .* resid                          # p × n
        ΛtDr   = Λ_B' * Dinv_r                           # K × n
        z      = cA \ ΛtDr                               # K × n
        DinvΛz = DinvΛ * z                               # p × n
        Σinv_r = Dinv_r .- DinvΛz                        # p × n
        quad   = sum(resid .* Σinv_r)

        Tout = promote_type(T, Td)
        return -convert(Tout, 0.5) * (n * p * log(convert(Tout, 2π)) + n * logdet_Σ + quad)
    else
        # ----- J3 phylogenetic path via rotation trick.
        # Build A = Λ_B Λ_B' + diag(d_total) (full p × p) and
        #       B = (Λ_phy_aug Λ_phy_aug') .* Σ_phy.
        # Λ_phy_aug = hcat(Λ_phy, σ_phy) when both supplied, else whichever
        # is non-nothing (as a p × K_aug matrix).
        A = Λ_B * Λ_B'
        @inbounds for t in 1:p
            A[t, t] += d_total[t]
        end

        Λ_phy_aug = if Λ_phy !== nothing && σ_phy !== nothing
            hcat(Λ_phy, σ_phy)
        elseif Λ_phy !== nothing
            Λ_phy
        else
            reshape(σ_phy, p, 1)
        end
        B = (Λ_phy_aug * Λ_phy_aug') .* Σ_phy

        # Per-trait mean across sites and column-centered residual matrix.
        # m::Vector keeps the linear-algebra below 1-D for AD compatibility.
        m = vec(sum(resid, dims = 2)) ./ n             # length p
        Y_centered = resid .- reshape(m, p, 1)         # p × n

        # Symmetrise to defeat round-off-induced asymmetry before cholesky.
        cA_sym  = cholesky(Symmetric((A + A') ./ 2))
        AnB     = A .+ n .* B
        cAnB    = cholesky(Symmetric((AnB + AnB') ./ 2))

        # Quadratic form via the rotation trick:
        #   y' Σ⁻¹ y = n · m' (A + n·B)⁻¹ m + tr(Y_c' A⁻¹ Y_c)
        # Solve (A + n·B) x = m and A X = Y_c, then accumulate.
        v_mean = cAnB \ m                              # length p
        quad_mean = n * dot(m, v_mean)
        V_c = cA_sym \ Y_centered                      # p × n
        quad_centered = sum(Y_centered .* V_c)

        logdet_Σ_full = logdet(cAnB) + (n - 1) * logdet(cA_sym)
        quad = quad_mean + quad_centered

        Tout = promote_type(T, Td)
        return -convert(Tout, 0.5) * (n * p * log(convert(Tout, 2π)) + logdet_Σ_full + quad)
    end
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
    gaussian_nll_packed(params, y; spec, X=nothing, Σ_phy=nothing) -> Real

J2-A-WD / J3 signature carrying a `spec::NamedTuple` with fields
`(q, p, K_B, K_W, has_diag)` and optionally `K_phy` and
`has_phy_unique` for the phylogenetic block. Parameter layout:

    [β               (spec.q entries)
     log_σ_eps       (1)
     log_σ_B         (p entries if spec.has_diag)
     log_σ_W         (p entries if spec.has_diag)
     θ_rr_B          (rr_theta_len(p, K_B) entries)
     θ_rr_W          (rr_theta_len(p, K_W) entries if spec.K_W > 0)
     σ_phy           (p entries if spec.has_phy_unique, identity link — signed)
     θ_rr_phy        (rr_theta_len(p, K_phy) entries if spec.K_phy > 0)]

`X` may be passed as a keyword (required iff `spec.q > 0`). `Σ_phy`
(p × p) is required iff `spec.K_phy > 0` or `spec.has_phy_unique`.

For the J1 case `(K_W = 0, has_diag = false)`, the layout collapses to
`[β; log_σ_eps; θ_rr_B]` and the result matches the legacy positional
method above.
"""
function gaussian_nll_packed(params::AbstractVector, y::AbstractMatrix;
                             spec::NamedTuple,
                             X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                             Σ_phy::Union{Nothing, AbstractMatrix} = nothing)
    q        = spec.q
    p        = spec.p
    K_B      = spec.K_B
    K_W      = spec.K_W
    has_diag = spec.has_diag
    # Phy fields are optional on the spec so existing call sites keep working.
    K_phy          = hasproperty(spec, :K_phy)          ? spec.K_phy          : 0
    has_phy_unique = hasproperty(spec, :has_phy_unique) ? spec.has_phy_unique : false

    size(y, 1) == p ||
        throw(ArgumentError("y first dim ($(size(y, 1))) must equal spec.p ($p)"))

    rr_B = rr_theta_len(p, K_B)
    rr_W = K_W > 0 ? rr_theta_len(p, K_W) : 0
    rr_phy = K_phy > 0 ? rr_theta_len(p, K_phy) : 0
    diag_count = has_diag ? 2 * p : 0
    phy_diag_count = has_phy_unique ? p : 0
    n_expected = q + 1 + diag_count + rr_B + rr_W + phy_diag_count + rr_phy
    length(params) == n_expected || throw(ArgumentError(
        "params length ($(length(params))) must equal $n_expected " *
        "(q=$q + 1 + diag=$(diag_count) + rr_B=$rr_B + rr_W=$rr_W " *
        "+ phy_diag=$(phy_diag_count) + rr_phy=$rr_phy)"))

    if (K_phy > 0 || has_phy_unique) && Σ_phy === nothing
        throw(ArgumentError("Σ_phy is required when spec.K_phy > 0 or spec.has_phy_unique"))
    end

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

    if has_phy_unique
        # Identity link: σ_phy is a signed loading-like vector (entries may
        # be negative). Joint sign flip (σ_phy → -σ_phy, φ → -φ) is the lone
        # non-identifiable symmetry; fit.jl applies a global sign anchor.
        σ_phy = @view params[(cursor + 1):(cursor + p)]
        cursor += p
    else
        σ_phy = nothing
    end

    if K_phy > 0
        θ_rr_phy = @view params[(cursor + 1):(cursor + rr_phy)]
        cursor += rr_phy
        Λ_phy    = unpack_lambda(θ_rr_phy, p, K_phy)
    else
        Λ_phy = nothing
    end

    σ_eps = exp(log_σ_eps)
    -gaussian_marginal_loglik(y, Λ_B, σ_eps;
                              X = X, β = β,
                              Λ_W = Λ_W, σ²_B = σ²_B, σ²_W = σ²_W,
                              Λ_phy = Λ_phy, σ_phy = σ_phy, Σ_phy = Σ_phy)
end

# Predictor-informed latent-score mean, Design-73 / gllvmTMB C1 analogue:
#
#   z_total[s, :] = X_lv[s, :] * alpha_lv + z_innovation[s, :]
#   y[:, s]       = X[:, s, :] * β + Λ_B * z_total[s, :] + ε[:, s]
#
# Marginally this is an ordinary Gaussian GLLVM with the same covariance and a
# constrained fixed mean term `Λ_B * alpha_lv' * X_lv[s, :]`. The alpha
# coefficients are rotation-dependent; the product `B_lv = Λ_B * alpha_lv'` is
# the rotation-stable trait-effect estimand.
function _lv_score_mean(X_lv::AbstractMatrix, alpha_lv::AbstractMatrix)
    size(X_lv, 2) == size(alpha_lv, 1) ||
        throw(ArgumentError(
            "X_lv second dim ($(size(X_lv, 2))) must equal alpha_lv rows ($(size(alpha_lv, 1)))"))
    return X_lv * alpha_lv
end

function _lv_mean_eta(Λ_B::AbstractMatrix, X_lv::AbstractMatrix,
                      alpha_lv::AbstractMatrix)
    return Λ_B * _lv_score_mean(X_lv, alpha_lv)'
end

"""
    gaussian_lv_nll_packed(params, y, p, K; X=nothing, q=0,
                           X_lv, q_lv) -> Real

Explicit Gaussian negative log-likelihood for the C1 predictor-informed
unit-tier latent-score model. Parameter layout:

- `params[1:q]` = ordinary fixed-effect coefficients `β` when `q > 0`;
- next `q_lv * K` entries = `alpha_lv`, reshaped as `q_lv × K`;
- next entry = `log σ_eps`;
- remaining entries = packed unit-tier loadings `Λ_B`.

This path deliberately does **not** use the profiled-`σ_eps` objective: the
latent-score predictor mean enters as `Λ_B * alpha_lv' * X_lv[s, :]`, so a
separate profile derivation is required before it can join the fast profiled
Gaussian route.
"""
function gaussian_lv_nll_packed(params::AbstractVector, y::AbstractMatrix,
                                p::Integer, K::Integer;
                                X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                                q::Integer = 0,
                                X_lv::AbstractMatrix,
                                q_lv::Integer)
    size(y, 1) == p ||
        throw(ArgumentError("y first dim ($(size(y, 1))) must equal p ($p)"))
    n = size(y, 2)
    size(X_lv, 1) == n ||
        throw(ArgumentError("X_lv first dim ($(size(X_lv, 1))) must equal n_sites ($n)"))
    size(X_lv, 2) == q_lv ||
        throw(ArgumentError("X_lv second dim ($(size(X_lv, 2))) must equal q_lv ($q_lv)"))
    if X === nothing
        q == 0 || throw(ArgumentError("q must be 0 when X is nothing"))
        β = nothing
    else
        q == size(X, 3) ||
            throw(ArgumentError("q ($q) must equal size(X, 3) ($(size(X, 3)))"))
        β = @view params[1:q]
    end

    rr_B = rr_theta_len(p, K)
    n_expected = q + q_lv * K + 1 + rr_B
    length(params) == n_expected || throw(ArgumentError(
        "params length ($(length(params))) must equal $n_expected " *
        "(q=$q + alpha_lv=$(q_lv * K) + 1 + rr_B=$rr_B)"))

    cursor = q
    alpha_vec = @view params[(cursor + 1):(cursor + q_lv * K)]
    alpha_lv = reshape(alpha_vec, q_lv, K)
    cursor += q_lv * K
    log_σ = params[cursor + 1]
    cursor += 1
    θ_rr = @view params[(cursor + 1):(cursor + rr_B)]

    Λ = unpack_lambda(θ_rr, p, K)
    y_adj = y .- _lv_mean_eta(Λ, X_lv, alpha_lv)
    return -gaussian_marginal_loglik(y_adj, Λ, exp(log_σ); X = X, β = β)
end
