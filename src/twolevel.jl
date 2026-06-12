# Two-level (between- vs within-individual) reduced-rank Gaussian GLLVM —
# the behavioural-syndromes decomposition (paper Eq 11).
#
# Model, per trait t of observation j on individual i:
#   y_ijt = μ_t + (Λ_B z_B,i)[t] + s_B,it + (Λ_W z_W,ij)[t] + s_W,ijt
# with z_B,i ~ N(0, I_{K_B}), z_W,ij ~ N(0, I_{K_W}),
#      s_B,i ~ N(0, diag(σ²_B)), s_W,ij ~ N(0, diag(σ²_W)).
#
# The between block is SHARED across all observations of an individual (the
# syndrome): cov contribution Σ_B = Λ_B Λ_Bᵀ + diag(σ²_B), p×p, common to every
# observation of i. The within block + observation residual are INDEPENDENT per
# observation (the state): Σ_W = Λ_W Λ_Wᵀ + diag(σ²_W), p×p, per observation.
#
# Stacking the n_i observations of individual i (n_i·p vector, observation-major)
# gives covariance
#   Σ_i = I_{n_i} ⊗ Σ_W + J_{n_i} ⊗ Σ_B,   J_{n_i} = 1 1ᵀ (rank 1).
# This is the SAME rotation-trick structure as the grouped-intercept / phylo
# paths: J_{n_i} has eigenvalue n_i (eigenvector 1/√n_i) and n_i−1 zeros, so in a
# basis whose first row is 1/√n_i the block is block-diagonal
# diag(Σ_W + n_i Σ_B, Σ_W, …, Σ_W). Hence per individual
#   logdet Σ_i = logdet(Σ_W + n_i Σ_B) + (n_i − 1)·logdet(Σ_W)
#   yᵢ' Σ_i⁻¹ yᵢ = n_i·m_i'(Σ_W + n_i Σ_B)⁻¹ m_i + tr(Y_ic' Σ_W⁻¹ Y_ic)
# with m_i the per-trait mean over i's observations and Y_ic the centred
# residuals. Individuals are independent ⇒ ℓ = Σ_i ℓ_i. Both p×p covariances are
# ΛΛᵀ + diag, inverted by Woodbury on the well-conditioned K×K core so the path
# stays robust as σ²_W → 0. AD-clean (verified against a central FD gradient).
#
# μ_t (per-trait grand mean) is profiled out analytically as the GLS mean; for
# the recovery test the data are centred so μ = 0.

# ---------------------------------------------------------------------------
# Woodbury helpers for Σ = Λ Λᵀ + diag(d).  Λ is p×K, d a length-p positive
# vector.  Returns closures (Σ⁻¹ applied to a matrix, logdet Σ) computed from one
# K×K cholesky — never a p×p chol of Σ — so it stays well-conditioned as d → 0.
# ---------------------------------------------------------------------------
function _woodbury_core(Λ::AbstractMatrix, d::AbstractVector)
    p, K = size(Λ)
    T = promote_type(eltype(Λ), eltype(d))
    d_inv = one(T) ./ d                                  # length p
    DinvΛ = d_inv .* Λ                                   # p×K (row-scaled)
    A_K = Matrix{T}(I, K, K) + Λ' * DinvΛ                # K×K core
    cA = cholesky(Symmetric(A_K))
    logdetΣ = sum(log, d) + logdet(cA)
    # Σ⁻¹ V = D⁻¹V − D⁻¹Λ (I + Λ'D⁻¹Λ)⁻¹ Λ'D⁻¹V
    Σinv = V -> begin
        DinvV = d_inv .* V
        DinvV .- DinvΛ * (cA \ (Λ' * DinvV))
    end
    return Σinv, logdetΣ
end

# Build Σ = Λ Λᵀ + diag(σ²_diag) DENSELY (for the n_i Σ_B and Σ_W + n_i Σ_B sum,
# whose Woodbury core would need rank K_B + p; a direct dense p×p chol is simplest
# and p is small in the two-level regime). Symmetrised before factoring.
function _dense_sigma(Λ::AbstractMatrix, σ²_diag::AbstractVector)
    p = size(Λ, 1)
    T = promote_type(eltype(Λ), eltype(σ²_diag))
    A = Matrix{T}(Λ * Λ')
    @inbounds for t in 1:p
        A[t, t] += σ²_diag[t]
    end
    return (A + A') ./ 2
end

# ---------------------------------------------------------------------------
# Two-level marginal log-likelihood (centred y; μ profiled to 0 by centring).
# `ind_idx` is a vector of column-index vectors, one per individual.
# ---------------------------------------------------------------------------
function _twolevel_loglik(y::AbstractMatrix, ind_idx::Vector{Vector{Int}},
        Λ_B::AbstractMatrix, σ²_B::AbstractVector,
        Λ_W::AbstractMatrix, σ²_W::AbstractVector)
    p, ntot = size(y)
    T = promote_type(eltype(y), eltype(Λ_B), eltype(σ²_B), eltype(Λ_W), eltype(σ²_W))

    # Within block Σ_W = Λ_W Λ_Wᵀ + diag(σ²_W): used for EVERY individual's
    # centred part, so factor once via Woodbury.
    ΣW_inv, logdetΣW = _woodbury_core(Λ_W, σ²_W)

    # Between block Σ_B = Λ_B Λ_Bᵀ + diag(σ²_B): only ever enters as
    # Σ_W + n_i Σ_B, which we factor per distinct n_i. Cache by group size.
    ΣB = _dense_sigma(Λ_B, σ²_B)
    ΣW = _dense_sigma(Λ_W, σ²_W)
    mean_cache = Dict{Int, Any}()        # n_i -> (cholesky(Σ_W + n_i Σ_B), logdet)

    twopi = convert(T, 2π)
    ll = zero(T)
    for idx in ind_idx
        ni = length(idx)
        Yi = Matrix{T}(@view y[:, idx])             # p × n_i
        mi = vec(sum(Yi, dims = 2)) ./ ni           # per-trait mean over obs
        Yic = Yi .- reshape(mi, p, 1)               # centred residuals

        # Centred part: tr(Y_ic' Σ_W⁻¹ Y_ic)
        quad_centered = sum(Yic .* ΣW_inv(Yic))

        # Mean part: n_i · m_i' (Σ_W + n_i Σ_B)⁻¹ m_i
        cMean, logdetMean = get!(mean_cache, ni) do
            M = ΣW .+ ni .* ΣB
            cM = cholesky(Symmetric((M + M') ./ 2))
            (cM, logdet(cM))
        end
        quad_mean = ni * dot(mi, cMean \ mi)

        logdet_i = logdetMean + (ni - 1) * logdetΣW
        quad_i = quad_mean + quad_centered
        ll += -convert(T, 0.5) * (ni * p * log(twopi) + logdet_i + quad_i)
    end
    return ll
end

"""
    twolevel_marginal_loglik(y, individual, Λ_B, σ²_B, Λ_W, σ²_W) -> Real

Marginal log-likelihood of the Gaussian two-level reduced-rank GLLVM
(behavioural-syndromes decomposition, paper Eq 11). `y` is `p × n_obs` (each
column one observation, observation-major); `individual` a length-`n_obs` vector
assigning each observation to an individual. The between-individual block
`Σ_B = Λ_B Λ_Bᵀ + diag(σ²_B)` is shared across all observations of an individual;
the within-individual block `Σ_W = Λ_W Λ_Wᵀ + diag(σ²_W)` is independent per
observation. `y` is assumed centred (per-trait grand mean removed). Solved per
individual by the rotation trick on `Σ_i = I_{n_i} ⊗ Σ_W + J_{n_i} ⊗ Σ_B`.
"""
function twolevel_marginal_loglik(y::AbstractMatrix, individual::AbstractVector,
        Λ_B::AbstractMatrix, σ²_B::AbstractVector,
        Λ_W::AbstractMatrix, σ²_W::AbstractVector)
    codes, _ = _code_grouping(individual)
    L = maximum(codes)
    ind_idx = [findall(==(g), codes) for g in 1:L]
    return _twolevel_loglik(y, ind_idx, Λ_B, σ²_B, Λ_W, σ²_W)
end

# ---------------------------------------------------------------------------
# Packed parameter layout (all variances on the log scale; loadings via the
# reduced-rank lower-triangular packing):
#   [ θ_rr_B (rr_theta_len(p,K_B))
#     log σ²_B  (p)
#     θ_rr_W (rr_theta_len(p,K_W))
#     log σ²_W  (p) ]
# ---------------------------------------------------------------------------
function _twolevel_unpack(θ::AbstractVector, p::Integer, K_B::Integer, K_W::Integer)
    rrB = rr_theta_len(p, K_B)
    rrW = rr_theta_len(p, K_W)
    c = 0
    Λ_B = unpack_lambda(@view(θ[(c + 1):(c + rrB)]), p, K_B); c += rrB
    σ²_B = exp.(@view θ[(c + 1):(c + p)]);                    c += p
    Λ_W = unpack_lambda(@view(θ[(c + 1):(c + rrW)]), p, K_W); c += rrW
    σ²_W = exp.(@view θ[(c + 1):(c + p)]);                    c += p
    return Λ_B, σ²_B, Λ_W, σ²_W
end
_twolevel_npar(p, K_B, K_W) = rr_theta_len(p, K_B) + p + rr_theta_len(p, K_W) + p

"""
    TwoLevelFit

Result of [`fit_twolevel_gaussian`](@ref): between-individual loadings `Λ_B`
(p×K_B) and per-trait between variances `σ²_B`; within-individual loadings `Λ_W`
(p×K_W) and per-trait within variances `σ²_W`; the assembled per-level covariances
`Σ_B = Λ_B Λ_Bᵀ + diag(σ²_B)` and `Σ_W = Λ_W Λ_Wᵀ + diag(σ²_W)`; number of
individuals `nindiv`; maximised `loglik`; `converged`; `iterations`.
"""
struct TwoLevelFit
    Λ_B::Matrix{Float64}
    σ²_B::Vector{Float64}
    Λ_W::Matrix{Float64}
    σ²_W::Vector{Float64}
    Σ_B::Matrix{Float64}
    Σ_W::Matrix{Float64}
    nindiv::Int
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::TwoLevelFit)
    p, K_B = size(f.Λ_B)
    K_W = size(f.Λ_W, 2)
    print(io, "TwoLevelFit(p=", p, ", K_B=", K_B, ", K_W=", K_W,
          ", nindiv=", f.nindiv, ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_twolevel_gaussian(y, individual; K_B, K_W, center=true, …) -> TwoLevelFit

Fit the Gaussian two-level reduced-rank GLLVM (behavioural-syndromes
decomposition). `y` is `p × n_obs` (observation-major columns); `individual` a
length-`n_obs` grouping vector. `K_B` / `K_W` are the between- / within-individual
reduced-rank dimensions. By default the per-trait grand mean is removed
(`center=true`) so μ is profiled out; pass `center=false` if `y` is already
centred. Optimises `[θ_rr_B; logσ²_B; θ_rr_W; logσ²_W]` on the per-individual
rotation-trick marginal (direct ForwardDiff; guarded BackTracking line search).

Recovers `Σ_B = Λ_B Λ_Bᵀ + diag(σ²_B)` and `Σ_W = Λ_W Λ_Wᵀ + diag(σ²_W)`; pass
the result to [`repeatability`](@ref), [`communality_B`](@ref) /
[`communality_W`](@ref), and [`correlation_B`](@ref) / [`correlation_W`](@ref).
"""
function fit_twolevel_gaussian(y::AbstractMatrix, individual::AbstractVector;
        K_B::Integer, K_W::Integer, center::Bool = true,
        σ²_B_init::Real = 0.5, σ²_W_init::Real = 0.5,
        g_tol::Real = 1e-8, iterations::Integer = 1000)
    p, ntot = size(y)
    length(individual) == ntot ||
        throw(DimensionMismatch("individual length must equal n_obs = $ntot"))
    K_B ≥ 1 && K_W ≥ 1 || throw(ArgumentError("K_B and K_W must be ≥ 1"))

    yf = Matrix{Float64}(y)
    if center
        μ = vec(sum(yf, dims = 2)) ./ ntot
        yf = yf .- reshape(μ, p, 1)
    end

    codes, _ = _code_grouping(individual)
    L = maximum(codes)
    ind_idx = [findall(==(g), codes) for g in 1:L]

    rrB = rr_theta_len(p, K_B)
    rrW = rr_theta_len(p, K_W)

    # Warm-start the loadings from PPCA on the full y (split the total variance
    # roughly between the two levels via the diag inits). The PPCA loadings give a
    # sane scale; the optimiser refines the between/within split.
    Λ0, _ = ppca_init(yf, max(K_B, K_W))
    θ0 = vcat(pack_lambda(Λ0[:, 1:K_B] ./ sqrt(2)),
              fill(log(float(σ²_B_init)), p),
              pack_lambda(Λ0[:, 1:K_W] ./ sqrt(2)),
              fill(log(float(σ²_W_init)), p))

    nll = θ -> begin
        v = try
            Λ_B, σ²_B, Λ_W, σ²_W = _twolevel_unpack(θ, p, K_B, K_W)
            -_twolevel_loglik(yf, ind_idx, Λ_B, σ²_B, Λ_W, σ²_W)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end

    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(nll, θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :forward)
    th = Optim.minimizer(res)
    Λ_B, σ²_B, Λ_W, σ²_W = _twolevel_unpack(th, p, K_B, K_W)
    Λ_Bf = Matrix{Float64}(Λ_B); σ²_Bf = Vector{Float64}(σ²_B)
    Λ_Wf = Matrix{Float64}(Λ_W); σ²_Wf = Vector{Float64}(σ²_W)
    Σ_B = Matrix{Float64}(_dense_sigma(Λ_Bf, σ²_Bf))
    Σ_W = Matrix{Float64}(_dense_sigma(Λ_Wf, σ²_Wf))
    return TwoLevelFit(Λ_Bf, σ²_Bf, Λ_Wf, σ²_Wf, Σ_B, Σ_W, L,
                       -Optim.minimum(res), Optim.converged(res), Optim.iterations(res))
end

# ---------------------------------------------------------------------------
# Two-level extractors.
# ---------------------------------------------------------------------------

"""
    repeatability(fit::TwoLevelFit) -> Vector

Per-trait repeatability `R_t = Σ_B[t,t] / (Σ_B[t,t] + Σ_W[t,t])` — the share of
the total per-trait variance attributable to stable between-individual
differences (the among-individual / total partition). Values in [0, 1].
"""
function repeatability(fit::TwoLevelFit)
    p = size(fit.Σ_B, 1)
    return [fit.Σ_B[t, t] / (fit.Σ_B[t, t] + fit.Σ_W[t, t]) for t in 1:p]
end

"""
    communality_B(fit::TwoLevelFit) -> Vector

Per-trait between-level communality `c²_B,t = (Λ_B Λ_Bᵀ)[t,t] / Σ_B[t,t]` — the
share of the between-individual trait variance carried by the shared between
loadings (vs the per-trait residual σ²_B). Values in [0, 1].
"""
function communality_B(fit::TwoLevelFit)
    ΛΛt = fit.Λ_B * fit.Λ_B'
    p = size(fit.Σ_B, 1)
    return [ΛΛt[t, t] / fit.Σ_B[t, t] for t in 1:p]
end

"""
    communality_W(fit::TwoLevelFit) -> Vector

Per-trait within-level communality `c²_W,t = (Λ_W Λ_Wᵀ)[t,t] / Σ_W[t,t]` — the
share of the within-individual (observation-level) trait variance carried by the
shared within loadings (vs the per-trait residual σ²_W). Values in [0, 1].
"""
function communality_W(fit::TwoLevelFit)
    ΛΛt = fit.Λ_W * fit.Λ_W'
    p = size(fit.Σ_W, 1)
    return [ΛΛt[t, t] / fit.Σ_W[t, t] for t in 1:p]
end

# Standardise a covariance to a correlation (diagonal exactly 1; NaN on Σ_tt ≤ 0).
function _to_correlation(Σ::AbstractMatrix)
    p = size(Σ, 1)
    R = Matrix{Float64}(undef, p, p)
    @inbounds for j in 1:p, i in 1:p
        d = Σ[i, i] * Σ[j, j]
        R[i, j] = (Σ[i, i] > 0 && Σ[j, j] > 0) ? Σ[i, j] / sqrt(d) : NaN
    end
    return R
end

"""
    correlation_B(fit::TwoLevelFit) -> Matrix

Between-individual cross-trait correlation `C_B = D_B^{-1/2} Σ_B D_B^{-1/2}` (the
behavioural-syndrome correlation matrix), `Σ_B = Λ_B Λ_Bᵀ + diag(σ²_B)`.
"""
correlation_B(fit::TwoLevelFit) = _to_correlation(fit.Σ_B)

"""
    correlation_W(fit::TwoLevelFit) -> Matrix

Within-individual cross-trait correlation `C_W = D_W^{-1/2} Σ_W D_W^{-1/2}` (the
observation-level / state correlation matrix), `Σ_W = Λ_W Λ_Wᵀ + diag(σ²_W)`.
"""
correlation_W(fit::TwoLevelFit) = _to_correlation(fit.Σ_W)
