# Gradient-free EM for the Gaussian phylogenetic GLLVM (phylo_unique config).
#
# This is the phylo extension of `em_fa.jl`. It fits the SAME model that
# `fit_gaussian_gllvm(y; K, has_phy_unique = true, Σ_phy = Σ_phy)` fits via
# gradient-based optimisation, but with closed-form EM updates that need NO
# gradient — only fast linear solves. The phylo solves can be done with the
# dense Σ_phy (reference) or with the augmented-state sparse precision
# (`AugmentedPhy`, the O(p) path in `sparse_phy.jl`), sidestepping the
# CHOLMOD autodiff limitation that blocks the gradient-based fit on the fast
# path.
#
# ---------------------------------------------------------------------------
# Model (phylo_unique, K_B site factors + per-trait phylo random effect)
# ---------------------------------------------------------------------------
#   y[:, s] = Λ_B η_s + diag(σ_phy) φ + ε_s ,   s = 1, …, n
#   η_s ~ N(0, I_{K_B})        (per-site latent factors, independent)
#   φ   ~ N(0, Σ_phy)          (ONE shared phylo random effect, length p)
#   ε_s ~ N(0, σ²_eps I_p)
#
# Σ_phy (p × p) is the FIXED tree-derived species covariance. The free
# parameters are Λ_B (p × K_B), σ_eps (> 0), and the per-trait phylo SDs
# σ_phy (length p). With Λ_φ ≡ diag(σ_phy) the phylo block of cov(vec(y)) is
# J_n ⊗ B,  B = (σ_phy σ_phy') ∘ Σ_phy = Λ_φ Σ_phy Λ_φ, and the site block is
# I_n ⊗ A,  A = Λ_B Λ_B' + σ²_eps I. This is EXACTLY the dense J3
# phylo_unique covariance in `likelihood.jl`.
#
# ---------------------------------------------------------------------------
# EM (Rubin & Thayer 1982, generalised with a per-trait-shared latent φ)
# ---------------------------------------------------------------------------
# Missing data Z = (η_1, …, η_n, φ). All Gaussian ⇒ E-step is exact.
#
# E-step. Let m = mean_s(y_s), β = Λ_B' A⁻¹.
#   φ posterior (treat m as one obs with noise A/n, conjugate Gaussian):
#       V_φ = (Σ_phy⁻¹ + n Λ_φ A⁻¹ Λ_φ)⁻¹
#       μ_φ = V_φ (n Λ_φ A⁻¹ m)
#   Equivalent z-space form (z = Λ_φ φ, the phylo effect on the data scale):
#       μ_z = n B (A + n B)⁻¹ m        (the ancestral-state BLUP)
#       V_z = B − n B (A + n B)⁻¹ B
#   η_s posterior (law of total expectation over φ):
#       E[η_s|Y]    = β (y_s − Λ_φ μ_φ)
#       Cov(η_s|Y)  = (I − β Λ_B) + β Λ_φ V_φ Λ_φ β'
#       Cov(η_s,φ|Y) = − β Λ_φ V_φ
#
# M-step (closed form). Per trait t, regress y[t, :] on the latent design
# u_s = (η_s, φ[t]); coefficients (Λ_B[t, :], σ_phy[t]):
#       G_t = Σ_s E[u_s u_s'|Y]   ((K_B+1) × (K_B+1))
#       h_t = Σ_s E[u_s y[t,s]|Y] (K_B+1)
#       (Λ_B[t,:], σ_phy[t]) = G_t⁻¹ h_t
# σ²_eps = (Σ_{t,s} y[t,s]² − Σ_t θ_t' h_t) / (n p)   (WLS residual trace).
#
# Monotone non-decrease of the marginal log-lik is an EM invariant and is
# asserted by the caller / tests. The marginal log-lik itself is evaluated
# with the dense closed form `gaussian_marginal_loglik` so the EM trajectory
# is comparable to the gradient-based fit to machine precision.

using LinearAlgebra
using SparseArrays
using Statistics

# ---------------------------------------------------------------------------
# Sparse (A + n B)⁻¹ apply via the augmented-state saddle point.
# ---------------------------------------------------------------------------
# B = Λ_φ Σ_phy Λ_φ for phylo_unique (Λ_aug = σ_phy, a single column). The
# augmented precision represents Σ_phy = σ²_phy · S Q_cond⁻¹ S'. With α = n σ²_phy
# the system (A + n B) v = rhs is solved by the Schur complement (mirrors the
# determinant/quadratic machinery in `likelihood_sparse_phy.jl`):
#       M_sad η = D_K' A⁻¹ rhs ,    v = A⁻¹ (rhs − α D_K η)
#       M_sad   = Q_eff − α G cap⁻¹ G'
# Q_eff = Q_cond + α (S' diag(σ_phy²/d) S) (sparse, O(p) factorisation), G is
# the rank-K_B Woodbury coupling, cap = I + Λ_B' D⁻¹ Λ_B. This returns the
# ancestral-state BLUP machinery without ever forming the dense Σ_phy.

"""
    AnBSparseSolver

Pre-factorised augmented-state solver for `(A + n B)` where
`A = Λ_B Λ_B' + σ²_eps I` and `B = diag(σ_phy) Σ_phy diag(σ_phy)`, with
`Σ_phy` represented by an `AugmentedPhy` (sparse precision). Built once per
E-step; applies `(A + n B)⁻¹` to vectors in O(p) per solve.

Reuses the saddle-point factorisation strategy of
`gaussian_marginal_loglik_sparse_phy` (`likelihood_sparse_phy.jl`).
"""
struct AnBSparseSolver
    phy::GLLVM.AugmentedPhy{Float64}
    n_block::Int
    leaf_pos::Vector{Int}
    d_total::Vector{Float64}
    d_inv::Vector{Float64}
    Λ_B::Matrix{Float64}
    DinvΛB::Matrix{Float64}
    chol_cap::Cholesky{Float64,Matrix{Float64}}
    chol_Q_eff::SparseArrays.CHOLMOD.Factor{Float64}
    G::Matrix{Float64}
    chol_S_K::Cholesky{Float64,Matrix{Float64}}
    σ_phy::Vector{Float64}
    α::Float64
end

"""
    build_AnB_sparse(Λ_B, σ_eps, σ_phy, phy, n; σ²_phy=1.0) -> AnBSparseSolver

Factorise the augmented-state representation of `(A + n B)` for the
phylo_unique model. `phy::AugmentedPhy` supplies the sparse Σ_phy precision;
`σ²_phy` scales it (Σ_phy = σ²_phy · S Q_cond⁻¹ S').
"""
function build_AnB_sparse(Λ_B::AbstractMatrix, σ_eps::Real,
                          σ_phy::AbstractVector, phy::GLLVM.AugmentedPhy,
                          n::Integer; σ²_phy::Real = 1.0)
    p   = phy.n_leaves
    K_B = size(Λ_B, 2)
    σ²  = float(σ_eps)^2
    Λ_B64 = Matrix{Float64}(Λ_B)
    σ_phy64 = Vector{Float64}(σ_phy)

    d_total = fill(σ², p)                      # A = Λ_B Λ_B' + σ²_eps I
    d_inv   = 1.0 ./ d_total
    DinvΛB  = d_inv .* Λ_B64                    # p × K_B
    cap     = Matrix(I + Λ_B64' * DinvΛB)       # K_B × K_B
    chol_cap = cholesky(Symmetric((cap + cap') ./ 2))

    keep    = filter(i -> i != phy.root_index, 1:phy.n_total)
    Q_cond  = phy.Q_topology[keep, keep]
    n_block = size(Q_cond, 1)
    leaf_pos = Vector{Int}(undef, p)
    @inbounds for t in 1:p
        lp = phy.leaf_indices[t]
        phy.root_index < lp && (lp -= 1)
        leaf_pos[t] = lp
    end

    α = n * float(σ²_phy)

    # Q_eff = Q_cond + α · (S' diag(σ_phy² / d_total) S)   (K_aug = 1 here)
    I_q = Int[]; J_q = Int[]; V_q = Float64[]
    rows = rowvals(Q_cond); vals = nonzeros(Q_cond)
    sizehint!(I_q, nnz(Q_cond) + p)
    sizehint!(J_q, nnz(Q_cond) + p)
    sizehint!(V_q, nnz(Q_cond) + p)
    for j in 1:n_block
        for idx in nzrange(Q_cond, j)
            push!(I_q, rows[idx]); push!(J_q, j); push!(V_q, vals[idx])
        end
    end
    @inbounds for t in 1:p
        push!(I_q, leaf_pos[t]); push!(J_q, leaf_pos[t])
        push!(V_q, α * σ_phy64[t]^2 * d_inv[t])
    end
    Q_eff = sparse(I_q, J_q, V_q, n_block, n_block)
    chol_Q_eff = cholesky(Symmetric(Q_eff))

    # G[(leaf_pos[t]), j] = σ_phy[t] · d_inv[t] · Λ_B[t, j]
    G = zeros(Float64, n_block, K_B)
    @inbounds for t in 1:p
        factor = σ_phy64[t] * d_inv[t]
        for j in 1:K_B
            G[leaf_pos[t], j] = factor * Λ_B64[t, j]
        end
    end
    X_G = chol_Q_eff \ G
    M_K = G' * X_G
    S_K = cap .- α .* M_K
    chol_S_K = cholesky(Symmetric((S_K + S_K') ./ 2))

    return AnBSparseSolver(phy, n_block, leaf_pos, d_total, d_inv,
                           Λ_B64, DinvΛB, chol_cap, chol_Q_eff, G, chol_S_K,
                           σ_phy64, α)
end

# A⁻¹ b via Woodbury for A = D + Λ_B Λ_B'.
@inline function _Ainv(s::AnBSparseSolver, b::AbstractVector)
    Dinv_b = s.d_inv .* b
    return Dinv_b .- s.DinvΛB * (s.chol_cap \ (s.Λ_B' * Dinv_b))
end

"""
    solve_AnB(s::AnBSparseSolver, rhs) -> v

Apply `(A + n B)⁻¹` to `rhs` (length p) via the sparse augmented-state
saddle-point. O(p) given the pre-factorisation.
"""
function solve_AnB(s::AnBSparseSolver, rhs::AbstractVector)
    p = s.phy.n_leaves
    Ainv_rhs = _Ainv(s, rhs)
    # b = D_K' A⁻¹ rhs  (concentrated at leaf positions, scaled by σ_phy)
    b = zeros(Float64, s.n_block)
    @inbounds for t in 1:p
        b[s.leaf_pos[t]] = s.σ_phy[t] * Ainv_rhs[t]
    end
    ξ0 = s.chol_Q_eff \ b
    yK = s.chol_S_K \ (s.G' * ξ0)
    ξ  = ξ0 .+ s.α .* (s.chol_Q_eff \ (s.G * yK))   # M_sad⁻¹ b
    # v = A⁻¹ rhs − α A⁻¹ D_K ξ ;  (D_K ξ)[t] = σ_phy[t] ξ[leaf_pos[t]]
    DKξ = zeros(Float64, p)
    @inbounds for t in 1:p
        DKξ[t] = s.σ_phy[t] * ξ[s.leaf_pos[t]]
    end
    return Ainv_rhs .- s.α .* _Ainv(s, DKξ)
end

"""
    blup_phylo_sparse(y, Λ_B, σ_eps, σ_phy, phy; σ²_phy=1.0) -> μ_z

Ancestral-state BLUP of the phylo random effect on the data scale,
`μ_z = n B (A + n B)⁻¹ m` with `m = mean_s(y_s)`, computed via the sparse
augmented-state solve (no dense Σ_phy). `B v = Λ_φ Σ_phy Λ_φ v` is applied
through the same augmented machinery.
"""
function blup_phylo_sparse(y::AbstractMatrix, Λ_B::AbstractMatrix, σ_eps::Real,
                           σ_phy::AbstractVector, phy::GLLVM.AugmentedPhy;
                           σ²_phy::Real = 1.0)
    p, n = size(y)
    s = build_AnB_sparse(Λ_B, σ_eps, σ_phy, phy, n; σ²_phy = σ²_phy)
    m = vec(sum(Matrix{Float64}(y), dims = 2)) ./ n
    w = solve_AnB(s, m)                          # (A + n B)⁻¹ m
    # μ_z = n B w ;  B w = Λ_φ Σ_phy Λ_φ w. Σ_phy x via augmented solve:
    # Σ_phy x = σ²_phy S Q_cond⁻¹ S' x  (S' x concentrated at leaf positions).
    Λφw = σ_phy .* w
    return μ_z_from_components(s, σ²_phy, Λφw, n)
end

# Helper: μ_z = n Λ_φ Σ_phy Λ_φ (A+nB)⁻¹ m, with Σ_phy applied via Q_cond.
# We need a Q_cond Cholesky distinct from Q_eff; build lazily here. To keep
# `AnBSparseSolver` lean we recompute the Σ_phy apply directly from phy.
function μ_z_from_components(s::AnBSparseSolver, σ²_phy::Real,
                            Λφw::AbstractVector, n::Integer)
    p = s.phy.n_leaves
    keep   = filter(i -> i != s.phy.root_index, 1:s.phy.n_total)
    Q_cond = s.phy.Q_topology[keep, keep]
    chol_Qcond = cholesky(Symmetric(Q_cond))
    rhs = zeros(Float64, s.n_block)
    @inbounds for t in 1:p
        rhs[s.leaf_pos[t]] = Λφw[t]
    end
    sol = chol_Qcond \ rhs
    Σφw = Vector{Float64}(undef, p)              # Σ_phy (Λ_φ w)
    @inbounds for t in 1:p
        Σφw[t] = σ²_phy * sol[s.leaf_pos[t]]
    end
    return n .* (s.σ_phy .* Σφw)                 # μ_z = n Λ_φ Σ_phy Λ_φ w
end

# ---------------------------------------------------------------------------
# Dense E-step + M-step (reference path; drives the EM fit).
# ---------------------------------------------------------------------------

# Dense E-step. Returns the sufficient statistics the M-step consumes plus
# the BLUPs. `A = Λ_B Λ_B' + σ²_eps I`, `B = (σ_phy σ_phy') ∘ Σ_phy`.
function _estep_dense(y::AbstractMatrix, Λ_B::AbstractMatrix, σ_eps::Real,
                      σ_phy::AbstractVector, Σ_phy::AbstractMatrix)
    p, n = size(y)
    K_B  = size(Λ_B, 2)
    σ²   = float(σ_eps)^2

    A  = Λ_B * Λ_B'
    @inbounds for t in 1:p
        A[t, t] += σ²
    end
    cA = cholesky(Symmetric((A + A') ./ 2))
    β  = Λ_B' / cA                                # K_B × p  (= Λ_B' A⁻¹)

    m   = vec(sum(y, dims = 2)) ./ n              # length p
    Λφ  = σ_phy                                   # diag(Λ_φ) as a vector

    # φ posterior: V_φ = (Σ_phy⁻¹ + n Λ_φ A⁻¹ Λ_φ)⁻¹, μ_φ = V_φ n Λ_φ A⁻¹ m.
    Ainv_Λφ = cA \ Diagonal(Λφ)                   # A⁻¹ Λ_φ  (p × p)
    Vφ_inv  = inv(Symmetric((Σ_phy + Σ_phy') ./ 2)) .+ n .* (Diagonal(Λφ) * Ainv_Λφ)
    cVφ     = cholesky(Symmetric((Vφ_inv + Vφ_inv') ./ 2))
    Vφ      = inv(cVφ)                            # p × p
    μ_φ     = Vφ * (n .* (Λφ .* (cA \ m)))        # length p

    # η posterior aggregated over sites.
    ImβΛ   = I - β * Λ_B                          # K_B × K_B  (= I − β Λ_B)
    βΛφ    = β .* reshape(Λφ, 1, p)               # K_B × p   (β Λ_φ, scale cols)
    βΛφVφ  = βΛφ * Vφ                             # K_B × p   (β Λ_φ V_φ)
    # E[η_s|Y] = β (y_s − Λ_φ μ_φ)
    zhat   = Λφ .* μ_φ                            # Λ_φ μ_φ  (= μ_z, BLUP)
    Eη     = β * (y .- reshape(zhat, p, 1))       # K_B × n
    sumEη  = vec(sum(Eη, dims = 2))               # K_B

    # Sufficient statistics for the M-step.
    # S_ηη = Σ_s E[η_s η_s'|Y] = n(I − βΛ_B) + n β Λ_φ V_φ Λ_φ β' + Eη Eη'
    S_ηη = n .* ImβΛ .+ n .* (βΛφVφ * βΛφ') .+ Eη * Eη'
    S_ηη = Symmetric((S_ηη + S_ηη') ./ 2)
    # E[φ[t]²|Y] = V_φ[t,t] + μ_φ[t]²
    Eφ2  = diag(Vφ) .+ μ_φ .^ 2                   # length p
    # Σ_s E[η_s φ[t]|Y] = sumEη μ_φ[t] − n (β Λ_φ V_φ)[:,t]
    #   stored as a K_B × p matrix C: C[:,t]
    C_ηφ = sumEη * μ_φ' .- n .* βΛφVφ             # K_B × p
    # Σ_s E[η_s y[t,s]|Y] = Σ_s E[η_s|Y] y[t,s]  →  K_B × p, col t
    H_ηy = Eη * y'                                # K_B × p (H_ηy[:,t] = Σ_s Eη_s y[t,s])

    return (; β, m, Eη, sumEη, S_ηη, Eφ2, C_ηφ, H_ηy, μ_φ, μ_z = zhat, Vφ)
end

# Dense M-step. Per-trait WLS for (Λ_B[t,:], σ_phy[t]); σ²_eps residual trace.
#
# For trait t the latent design is u_s = (η_s, φ[t]); the joint optimum of
# (Λ_B[t,:], σ_phy[t]) is the UNCONSTRAINED solution of the (K_B+1) normal
# equations G_t θ_t = h_t. This is the exact maximiser of the Q-function over
# those coordinates, so the EM step is monotone by construction.
#
# σ_phy is left SIGNED (no abs / no projection). The dense fit
# (`fit_gaussian_gllvm`) restricts σ_phy = exp(log_σ_phy) > 0; the two agree
# when the optimum is interior to the positive orthant (all σ_phy
# comfortably > 0), which is the regime this EM targets. A hard non-negativity
# projection is intentionally NOT used: clamping σ_phy[t] to 0 creates an
# absorbing boundary that traps EM away from an interior MLE, whereas naïve
# abs() overshoots the 0 boundary and breaks monotonicity. The honest scope is
# therefore "interior optimum"; the boundary case is documented as a known
# limitation. The reported σ_phy take the global sign convention σ_phy[1] ≥ 0
# (flipping ALL signs jointly is the only φ-orientation symmetry that leaves
# every B[t,t'] = σ_phy[t] σ_phy[t'] Σ_phy[t,t'] unchanged).
function _mstep_dense(y::AbstractMatrix, ss)
    p, n = size(y)
    K_B  = size(ss.H_ηy, 1)
    Λ_B_new   = Matrix{Float64}(undef, p, K_B)
    σ_phy_new = Vector{Float64}(undef, p)

    sy2 = sum(abs2, y)                            # Σ_{t,s} y[t,s]²
    quad_fit = 0.0                                # Σ_t θ_t' h_t

    S_ηη = Matrix(ss.S_ηη)
    @inbounds for t in 1:p
        # G_t ((K_B+1)×(K_B+1)): [[S_ηη, C_t]; [C_t', n Eφ2[t]]]
        Gt = Matrix{Float64}(undef, K_B + 1, K_B + 1)
        Gt[1:K_B, 1:K_B] .= S_ηη
        Gt[1:K_B, K_B+1]  .= ss.C_ηφ[:, t]
        Gt[K_B+1, 1:K_B]  .= ss.C_ηφ[:, t]
        Gt[K_B+1, K_B+1]   = n * ss.Eφ2[t]
        # h_t: [Σ_s Eη_s y[t,s]; μ_φ[t] Σ_s y[t,s]]
        ht = Vector{Float64}(undef, K_B + 1)
        ht[1:K_B] .= ss.H_ηy[:, t]
        ht[K_B+1]  = ss.μ_φ[t] * (n * ss.m[t])
        θt = Symmetric((Gt + Gt') ./ 2) \ ht
        Λ_B_new[t, :] .= θt[1:K_B]
        σ_phy_new[t]   = θt[K_B+1]
        quad_fit += dot(θt, ht)
    end

    σ²_eps_new = max((sy2 - quad_fit) / (n * p), eps())
    return Λ_B_new, sqrt(σ²_eps_new), σ_phy_new
end

# ---------------------------------------------------------------------------
# Public EM driver
# ---------------------------------------------------------------------------

"""
    EMPhyloFit

Result of `em_fit_phylo`. Fields:
* `Λ_B`        – fitted site loadings (p × K_B).
* `σ_eps`      – fitted residual SD.
* `σ_phy`      – fitted per-trait phylo SDs (length p).
* `logLik`     – final marginal log-likelihood (dense closed form).
* `n_iter`     – EM iterations run.
* `converged`  – whether the log-lik increment fell below `tol`.
* `loglik_trace` – log-lik at each iteration (monotone non-decreasing).
* `blup_phy`   – ancestral-state BLUP of the phylo effect on the data scale
                 (μ_z, length p) from the LAST E-step.
* `blup_phi`   – BLUP of the unit-scale phylo latent φ (μ_φ, length p).
"""
struct EMPhyloFit
    Λ_B::Matrix{Float64}
    σ_eps::Float64
    σ_phy::Vector{Float64}
    logLik::Float64
    n_iter::Int
    converged::Bool
    loglik_trace::Vector{Float64}
    blup_phy::Vector{Float64}
    blup_phi::Vector{Float64}
end

"""
    em_fit_phylo(y, K_B, Σ_phy;
                 λ_init=nothing, σ_eps_init=nothing, σ_phy_init=nothing,
                 tol=1e-9, max_iter=1000, assert_monotone=true) -> EMPhyloFit

Gradient-free EM fit of the Gaussian phylo_unique GLLVM: `K_B` site latent
factors plus one per-trait phylogenetic random effect with covariance
`(σ_phy σ_phy') ∘ Σ_phy`. Matches `fit_gaussian_gllvm(y; K = K_B,
has_phy_unique = true, Σ_phy = Σ_phy)`.

`y` is (p, n_sites). `Σ_phy` is the fixed (p × p) tree-derived species
covariance. Warm-started from PPCA (`ppca_init`) unless `λ_init`/`σ_eps_init`
are supplied. Returns an `EMPhyloFit` including the ancestral-state BLUPs
from the final E-step.

When `assert_monotone` (default), a log-lik DECREASE beyond `1e-7` triggers an
error — a monotone non-decrease is an EM invariant, so a decrease is a bug.
"""
function em_fit_phylo(y::AbstractMatrix, K_B::Integer, Σ_phy::AbstractMatrix;
                      λ_init = nothing, σ_eps_init = nothing,
                      σ_phy_init = nothing,
                      tol = 1e-9, max_iter = 1000, assert_monotone = true)
    p, n = size(y)
    K_B ≥ 1 || throw(ArgumentError("K_B must be ≥ 1"))
    K_B < p || throw(ArgumentError("EM requires K_B < p; got K_B=$K_B, p=$p"))
    size(Σ_phy) == (p, p) ||
        throw(ArgumentError("Σ_phy must be p × p; got $(size(Σ_phy)) for p=$p"))

    yf = Matrix{Float64}(y)

    # ----- Warm start (PPCA for Λ_B, σ_eps; small phylo SD to start) -----
    if λ_init === nothing || σ_eps_init === nothing
        Λ0, σ0 = GLLVM.ppca_init(yf, K_B)
        Λ_B   = λ_init === nothing ? Matrix{Float64}(Λ0) : Matrix{Float64}(λ_init)
        σ_eps = σ_eps_init === nothing ? float(σ0) : float(σ_eps_init)
    else
        Λ_B   = Matrix{Float64}(λ_init)
        σ_eps = float(σ_eps_init)
    end
    σ_phy = if σ_phy_init === nothing
        # Start the phylo SD from the marginal scale of the data.
        fill(0.1 * sqrt(mean(abs2, yf)), p)
    else
        Vector{Float64}(σ_phy_init)
    end

    loglik_trace = Float64[]
    loglik_prev  = -Inf
    converged    = false
    iters_run    = 0
    local blup_phy = zeros(Float64, p)
    local blup_phi = zeros(Float64, p)

    for iter in 1:max_iter
        iters_run = iter
        # Marginal log-lik at the CURRENT parameters (dense closed form), i.e.
        # at the output of the previous M-step ⇒ sequence is monotone.
        ll = GLLVM.gaussian_marginal_loglik(yf, Λ_B, σ_eps;
                                            σ_phy = σ_phy, Σ_phy = Σ_phy)
        push!(loglik_trace, ll)

        if iter > 1
            inc = ll - loglik_prev
            if assert_monotone && inc < -1e-7
                error("EM log-lik decreased by $(abs(inc)) at iter $iter " *
                      "(was $loglik_prev, now $ll) — EM monotonicity violated.")
            end
            if abs(inc) < tol
                converged = true
                # E-step once more to refresh BLUPs at the converged params.
                ss = _estep_dense(yf, Λ_B, σ_eps, σ_phy, Σ_phy)
                blup_phy = copy(ss.μ_z); blup_phi = copy(ss.μ_φ)
                break
            end
        end
        loglik_prev = ll

        ss = _estep_dense(yf, Λ_B, σ_eps, σ_phy, Σ_phy)
        blup_phy = copy(ss.μ_z); blup_phi = copy(ss.μ_φ)
        Λ_B, σ_eps, σ_phy = _mstep_dense(yf, ss)
    end

    ll_final = GLLVM.gaussian_marginal_loglik(yf, Λ_B, σ_eps;
                                              σ_phy = σ_phy, Σ_phy = Σ_phy)
    if !isempty(loglik_trace) && ll_final > loglik_trace[end]
        push!(loglik_trace, ll_final)
    end

    # Global φ-orientation convention: flipping ALL σ_phy signs jointly leaves
    # every B[t,t'] = σ_phy[t] σ_phy[t'] Σ_phy[t,t'] unchanged (and flips μ_φ,
    # leaving the data-scale BLUP μ_z = diag(σ_phy) μ_φ invariant). Anchor the
    # sign so the dominant-magnitude trait's σ_phy is ≥ 0, matching the dense
    # fit's σ_phy = exp(log_σ_phy) > 0 convention for interior optima.
    t_anchor = argmax(abs.(σ_phy))
    if σ_phy[t_anchor] < 0
        σ_phy = -σ_phy
        blup_phi = -blup_phi          # μ_z = diag(σ_phy) μ_φ unchanged
    end

    return EMPhyloFit(Λ_B, σ_eps, σ_phy, ll_final, iters_run, converged,
                      loglik_trace, blup_phy, blup_phi)
end
