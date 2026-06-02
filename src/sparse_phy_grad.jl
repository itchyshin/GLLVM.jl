# Analytic gradient of the augmented-state sparse phylogenetic Gaussian
# marginal log-likelihood (`gaussian_marginal_loglik_sparse_phy`).
#
# WHY THIS FILE EXISTS
# --------------------
# The fast O(p) sparse phylo path in `likelihood_sparse_phy.jl` is built on
# CHOLMOD's sparse Cholesky, which is Float64-only: `ForwardDiff.Dual` cannot
# flow through it, so that path is evaluation-only and a gradient-based
# optimiser cannot drive it. This file supplies a HAND-CODED ANALYTIC gradient
# — the same capability TMB (Kristensen et al. 2016) gives its sparse Cholesky
# — so the sparse path becomes both fast AND fittable.
#
# THE MATH (adjoint / reverse-mode of the closed-form marginal likelihood)
# ------------------------------------------------------------------------
# The rotation-trick marginal log-likelihood (identical to the dense path in
# `likelihood.jl`) is, with A = Λ_B Λ_B' + diag(d_total), B = (Λ_aug Λ_aug') ∘
# Σ_phy, C := A + n·B, m = mean_s y, Y_c = y − m:
#
#   2ℓ = −[ n p log 2π + logdet(C) + (n−1)logdet(A)
#           + n m'C⁻¹m + tr(Y_c'A⁻¹Y_c) ]
#
# Differentiating w.r.t. the entries of A and B (matrix calculus:
# d logdet M = tr(M⁻¹ dM), d(b'M⁻¹b) = −(M⁻¹b)'dM(M⁻¹b)) and using dC = dA+n dB
# gives the two symmetric adjoint matrices
#
#   P_A = −C⁻¹ + n (C⁻¹m)(C⁻¹m)' − (n−1)A⁻¹ + (A⁻¹Y_c)(A⁻¹Y_c)'      (∂2ℓ/∂A)
#   P_B = n ( −C⁻¹ + n (C⁻¹m)(C⁻¹m)' )                                (∂2ℓ/∂B)
#
# so that ∂ℓ/∂θ = ½[ tr(P_A · dA/dθ) + tr(P_B · dB/dθ) ]. Pushing these through
# the parameter maps (A = Λ_BΛ_B' + diag, B = σ²_phy (Λ_augΛ_aug') ∘ G_phy with
# G_phy = S Q_cond⁻¹ S' the FIXED tree covariance):
#
#   ∂ℓ/∂Λ_B   = P_A Λ_B
#   ∂ℓ/∂σ²_eps= ½ tr(P_A)                          (standard model: dA = I)
#   ∂ℓ/∂σ²_phy= ½ ⟨P_B, B⟩ / σ²_phy
#   ∂ℓ/∂Λ_phy = (P_B ∘ Σ_phy) Λ_aug[:, 1:K_phy]
#   ∂ℓ/∂σ_phy = (P_B ∘ Σ_phy) Λ_aug[:, end]        (the phylo-unique column)
#
# CRUCIAL IDENTITY (lets us avoid the dense p×p C and forming Σ_y):
#   n·B = α · D_K Q_full_cond⁻¹ D_K'   with α = n σ²_phy
# (D_K selects+scales leaves per axis; Q_full_cond = blockdiag(Q_cond)^{K_aug}).
# Hence C = A + α D_K Q_full_cond⁻¹ D_K' and the matrix-inversion lemma gives a
# Woodbury form for C⁻¹ in terms of A⁻¹ (rank-K_B, cheap) and the augmented
# sparse solve M_sad (CHOLMOD, O(p) on a tree). Every C⁻¹·v is therefore O(p).
#
#   C⁻¹ v = A⁻¹v − A⁻¹ D_K (M̃⁻¹ (D_K' A⁻¹ v)),   M̃⁻¹ = α M_sad⁻¹,
#   M̃ = Q_full_cond/α + D_K'A⁻¹D_K,  M_sad = Q_eff − α G cap⁻¹ G'  (the file's).
#
# All log-determinant and quadratic-form pieces reuse the exact decomposition
# already derived in `likelihood_sparse_phy.jl`; we never re-factorise anything
# the value pass did not.
#
# COST / SCALING (reported honestly by bench/sparse_phy_grad_bench.jl)
# --------------------------------------------------------------------
# * ∂ℓ/∂Λ_B : O(p·K_B) — K_B+K_aug sparse solves + low-rank algebra.
# * Single phylogenetic axis (`K_aug == 1`): the tree-coupled scalar and
#   loading-gradient terms reduce to same-leaf selected-inverse entries. The
#   Takahashi branch below computes those entries in O(p) on tree factors, so
#   the full single-axis gradient is O(p) up to small K_B dense algebra.
# * Multiple phylogenetic axes (`K_aug >= 2`): ∂ℓ/∂σ²_phy, ∂ℓ/∂σ²_eps,
#   ∂ℓ/∂Λ_phy, ∂ℓ/∂σ_phy need the dense (K_aug·p) × (K_aug·p) leaf-leaf block
#   of M_sad⁻¹ (= cross-leaf entries of the augmented inverse). On a
#   tree-augmented Q_eff, the L+Lᵀ pattern of the Cholesky factor covers only
#   the K_aug × K_aug same-leaf coupling block (K_aug²·p in-pattern entries);
#   the cross-leaf entries are DENSE and ARE NOT in pattern. Takahashi gives
#   the in-pattern entries in O(K_aug·p), but the dense cross-leaf entries
#   still need a batched CHOLMOD solve `chol_Q_eff \ E_leaf` (cost O(p²);
#   memory O(p²)) plus the rank-K_B Woodbury correction. That general
#   multi-axis path is therefore O(p²), not O(p).
#
# This file is self-contained: it `include`s the sources it needs and does NOT
# modify src/GLLVM.jl or any existing file.

using SparseArrays
using LinearAlgebra

# Takahashi (1973) / Erisman–Tinney (1975) selected inverse — used to obtain
# same-leaf entries of `Q_eff⁻¹` in `O(K_aug·p)`. For `K_aug == 1`, those
# selected entries are enough for the whole tree-coupled gradient. For
# `K_aug >= 2`, they are not enough to reconstruct the dense cross-leaf block,
# so `leaf_block_inv` keeps the exact batched-solve path.
include(joinpath(@__DIR__, "takahashi_selinv.jl"))

# ---------------------------------------------------------------------------
# State container: everything the value AND gradient need, built once.
# ---------------------------------------------------------------------------
struct SparsePhyState{TF}
    p::Int
    n::Int
    K_B::Int
    K_aug::Int
    K_phy::Int
    has_unique::Bool
    σ_eps::Float64
    σ²_phy::Float64
    d_total::Vector{Float64}
    d_inv::Vector{Float64}
    Λ_B::Matrix{Float64}
    Λ_aug::Matrix{Float64}        # p × K_aug = [Λ_phy | σ_phy]
    m::Vector{Float64}
    Y_c::Matrix{Float64}
    DinvΛB::Matrix{Float64}
    cap::Matrix{Float64}
    chol_cap::Cholesky{Float64,Matrix{Float64}}
    Q_cond::SparseMatrixCSC{Float64,Int}
    nb::Int
    leaf_pos::Vector{Int}
    chol_Qcond::TF
    α::Float64
    total::Int
    Q_eff::SparseMatrixCSC{Float64,Int}
    chol_Q_eff::TF
    G::Matrix{Float64}
    X_G::Matrix{Float64}                          # = chol_Q_eff \ G ; (K_aug·nb) × K_B
    S_K::Matrix{Float64}
    chol_S_K::Cholesky{Float64,Matrix{Float64}}
    phy::AugmentedPhy{Float64}
end

"""
    build_sparse_phy_state(y, Λ_B, σ_eps; Λ_phy, σ_phy, phy, σ²_phy)

Assemble the augmented-state sparse machinery for the STANDARD phylogenetic
GLLVM (no W tier, no per-trait diagonal REs, scalar `σ²_phy`). Mirrors the
construction in `likelihood_sparse_phy.jl` and is shared between the value
(`sparse_phy_value`) and the analytic gradient (`sparse_phy_grad`).
"""
function build_sparse_phy_state(y::AbstractMatrix,
                                Λ_B::AbstractMatrix,
                                σ_eps::Real;
                                Λ_phy::Union{Nothing,AbstractMatrix} = nothing,
                                σ_phy::Union{Nothing,AbstractVector} = nothing,
                                phy::AugmentedPhy,
                                σ²_phy::Real = 1.0)
    p, n = size(y)
    K_B = size(Λ_B, 2)
    p == phy.n_leaves ||
        throw(ArgumentError("y first dim ($p) must equal phy.n_leaves ($(phy.n_leaves))"))
    (Λ_phy === nothing && σ_phy === nothing) &&
        throw(ArgumentError("supply Λ_phy and/or σ_phy"))

    σ² = float(σ_eps)^2
    d_total = fill(σ², p)
    d_inv = 1.0 ./ d_total

    K_phy = Λ_phy === nothing ? 0 : size(Λ_phy, 2)
    has_unique = σ_phy !== nothing
    Λ_aug = if Λ_phy !== nothing && σ_phy !== nothing
        hcat(Matrix{Float64}(Λ_phy), Vector{Float64}(σ_phy))
    elseif Λ_phy !== nothing
        Matrix{Float64}(Λ_phy)
    else
        reshape(Vector{Float64}(σ_phy), p, 1)
    end
    K_aug = size(Λ_aug, 2)
    Λ_B64 = Matrix{Float64}(Λ_B)

    m = vec(sum(y, dims = 2)) ./ n
    Y_c = Matrix{Float64}(y) .- reshape(m, p, 1)

    DinvΛB = d_inv .* Λ_B64
    cap = Matrix(I + Λ_B64' * DinvΛB)
    chol_cap = cholesky(Symmetric((cap + cap') ./ 2))

    keep = filter(i -> i != phy.root_index, 1:phy.n_total)
    Q_cond = phy.Q_topology[keep, keep]
    nb = size(Q_cond, 1)
    leaf_pos = Vector{Int}(undef, p)
    @inbounds for t in 1:p
        lp = phy.leaf_indices[t]
        leaf_pos[t] = phy.root_index < lp ? lp - 1 : lp
    end
    chol_Qcond = cholesky(Symmetric(Q_cond))

    α = n * float(σ²_phy)
    total = K_aug * nb

    I_q = Int[]; J_q = Int[]; V_q = Float64[]
    sizehint!(I_q, K_aug * nnz(Q_cond) + K_aug * K_aug * p)
    sizehint!(J_q, K_aug * nnz(Q_cond) + K_aug * K_aug * p)
    sizehint!(V_q, K_aug * nnz(Q_cond) + K_aug * K_aug * p)
    rows = rowvals(Q_cond); vals = nonzeros(Q_cond)
    for k_blk in 1:K_aug
        offset = (k_blk - 1) * nb
        for j in 1:nb, idx in nzrange(Q_cond, j)
            push!(I_q, rows[idx] + offset); push!(J_q, j + offset); push!(V_q, vals[idx])
        end
    end
    @inbounds for k_blk in 1:K_aug, l_blk in 1:K_aug
        off_k = (k_blk - 1) * nb; off_l = (l_blk - 1) * nb
        for t in 1:p
            v = α * Λ_aug[t, k_blk] * Λ_aug[t, l_blk] / d_total[t]
            push!(I_q, leaf_pos[t] + off_k); push!(J_q, leaf_pos[t] + off_l); push!(V_q, v)
        end
    end
    Q_eff = sparse(I_q, J_q, V_q, total, total)
    chol_Q_eff = cholesky(Symmetric(Q_eff))

    G = zeros(Float64, total, K_B)
    @inbounds for k_blk in 1:K_aug
        offset = (k_blk - 1) * nb
        for t in 1:p
            base = offset + leaf_pos[t]
            factor = Λ_aug[t, k_blk] * d_inv[t]
            for j in 1:K_B
                G[base, j] = factor * Λ_B64[t, j]
            end
        end
    end
    X_G = chol_Q_eff \ G
    M_K = G' * X_G
    S_K = cap .- α .* M_K
    chol_S_K = cholesky(Symmetric((S_K + S_K') ./ 2))

    return SparsePhyState{typeof(chol_Q_eff)}(
        p, n, K_B, K_aug, K_phy, has_unique, float(σ_eps), float(σ²_phy),
        d_total, d_inv, Λ_B64, Λ_aug, m, Y_c, DinvΛB, cap, chol_cap,
        Q_cond, nb, leaf_pos, chol_Qcond, α, total, Q_eff, chol_Q_eff,
        G, X_G, S_K, chol_S_K, phy)
end

# ---------------------------------------------------------------------------
# Linear-operator helpers (all O(p) per application).
# ---------------------------------------------------------------------------
# A⁻¹ via Woodbury: A⁻¹ b = D⁻¹b − DinvΛB (cap \ (Λ_B' D⁻¹ b)).
function _Ainv(st::SparsePhyState, b::AbstractVector)
    Dinv_b = st.d_inv .* b
    Dinv_b .- st.DinvΛB * (st.chol_cap \ (st.Λ_B' * Dinv_b))
end
function _AinvM(st::SparsePhyState, B::AbstractMatrix)
    Dinv_B = st.d_inv .* B
    Dinv_B .- st.DinvΛB * (st.chol_cap \ (st.Λ_B' * Dinv_B))
end

# M_sad⁻¹ via Woodbury on M_sad = Q_eff − α G cap⁻¹ G' with S_K = cap − α M_K:
#   M_sad⁻¹ b = Q_eff⁻¹ b + α Q_eff⁻¹ G (S_K \ (G' Q_eff⁻¹ b)).
function _Msad(st::SparsePhyState, b::AbstractVector)
    x0 = st.chol_Q_eff \ b
    x0 .+ st.α .* (st.chol_Q_eff \ (st.G * (st.chol_S_K \ (st.G' * x0))))
end
function _MsadM(st::SparsePhyState, B::AbstractMatrix)
    X0 = st.chol_Q_eff \ B
    X0 .+ st.α .* (st.chol_Q_eff \ (st.G * (st.chol_S_K \ (st.G' * X0))))
end

# D_K' : p-vector v ↦ total-vector (place λ_aug[t,k] v[t] at off_k+leaf_pos[t]).
function _DKt(st::SparsePhyState, v::AbstractVector)
    z = zeros(eltype(v), st.total)
    @inbounds for k in 1:st.K_aug
        off = (k - 1) * st.nb
        for t in 1:st.p
            z[off + st.leaf_pos[t]] += st.Λ_aug[t, k] * v[t]
        end
    end
    z
end
# D_K  : total-vector z ↦ p-vector (out[t] = Σ_k λ_aug[t,k] z[off_k+leaf_pos[t]]).
function _DK(st::SparsePhyState, z::AbstractVector)
    out = zeros(eltype(z), st.p)
    @inbounds for k in 1:st.K_aug
        off = (k - 1) * st.nb
        for t in 1:st.p
            out[t] += st.Λ_aug[t, k] * z[off + st.leaf_pos[t]]
        end
    end
    out
end

# C⁻¹ v via the Woodbury form (all O(p)).
function _Cinv(st::SparsePhyState, v::AbstractVector)
    Av = _Ainv(st, v)
    w = _DKt(st, Av)
    Mw = st.α .* _Msad(st, w)
    Av .- _Ainv(st, _DK(st, Mw))
end
_CinvM(st::SparsePhyState, B::AbstractMatrix) =
    reduce(hcat, (_Cinv(st, @view B[:, j]) for j in 1:size(B, 2)))

# tr(A⁻¹) closed form (Woodbury): tr(D⁻¹) − tr(cap⁻¹ DinvΛB' DinvΛB).
_trAinv(st::SparsePhyState) = sum(st.d_inv) - tr(st.chol_cap \ (st.DinvΛB' * st.DinvΛB))

# ---------------------------------------------------------------------------
# Selected inverse: leaf-row × leaf-col block of `M_sad⁻¹`.
#
# Downstream gradient terms only consume the `(K_aug·p) × (K_aug·p)`
# leaf-leaf block of `M_sad⁻¹`; the OLD implementation built the full
# `total × (K_aug·p)` matrix and immediately sliced the leaf rows. The new
# implementation returns ONLY the dense leaf-leaf block, computed via the
# Woodbury decomposition
#
#   M_sad⁻¹ = Q_eff⁻¹ + α · X_G · S_K⁻¹ · X_G'
#
# with `X_G = chol_Q_eff \ G` (pre-computed in the state build, no
# additional solve here). The leaf-block of Q_eff⁻¹ is obtained via a single
# batched CHOLMOD solve against leaf unit columns (cost `O(K_aug² · p²)`).
# This is the EXACT same matrix value as the old `_MsadM(st, E)` would have
# returned at leaf rows; the savings come from never allocating the
# `total × ncol` rows we then discard.
#
# Notes on Takahashi (1973) / Erisman–Tinney (1975):
# ---------------------------------------------------
# A genuinely linear `O(K_aug · p)` selected inverse of `Q_eff` IS available
# (see `src/takahashi_selinv.jl`), but its sparsity coverage is restricted
# to the `L + Lᵀ` pattern. On a tree-augmented `Q_eff` that pattern includes
# the K_aug × K_aug same-leaf axis-coupling block (K_aug²·p in-pattern
# leaf-leaf entries) but does NOT cover the CROSS-leaf entries of
# `Q_eff⁻¹`, which are dense and non-zero in general (we verified this
# empirically at p = 20: max out-of-pattern `|Q_eff⁻¹[leaf, leaf]|` ≈ 0.26).
# Reconstructing those cross-leaf entries needs the same batched solve we
# already do — so Takahashi cannot lower the asymptotic cost of
# `leaf_block_inv` for the FULL dense leaf-leaf block. The `K_aug == 1`
# gradient branch below avoids this helper because its scalar/loading
# contractions need only same-leaf entries. The general multi-axis gradient
# still depends on `leaf_block_inv` and remains O(p²) overall.
# ---------------------------------------------------------------------------
function _leaf_unit_columns(st::SparsePhyState)
    cols = Vector{Int}(undef, st.K_aug * st.p)
    c = 0
    @inbounds for k in 1:st.K_aug
        off = (k - 1) * st.nb
        for t in 1:st.p
            c += 1
            cols[c] = off + st.leaf_pos[t]
        end
    end
    cols
end

"""
    leaf_block_inv(st::SparsePhyState) -> (LB_leaf, cols)

Dense (K_aug·p) × (K_aug·p) leaf-row × leaf-col block of `M_sad⁻¹`. `cols`
are the augmented-state column indices corresponding to each column of
`LB_leaf` (= the leaf positions, axis-stacked). Computed via the Woodbury
form `M_sad⁻¹ = Q_eff⁻¹ + α · X_G · S_K⁻¹ · X_G'`, restricted to leaf rows
and columns. The leaf-block of `Q_eff⁻¹` is obtained from a single batched
CHOLMOD solve against the leaf unit columns (the dominant cost).
"""
function leaf_block_inv(st::SparsePhyState)
    cols = _leaf_unit_columns(st)
    ncol = length(cols)
    # Q_eff⁻¹ at (leaf, leaf): batched solve against the leaf unit columns,
    # then slice the leaf rows out. Same cost as the old `_MsadM` solve, but
    # we skip the rank-K_B Woodbury correction inside the solve and apply
    # it once at the dense-block level below.
    E = zeros(Float64, st.total, ncol)
    @inbounds for (c, idx) in enumerate(cols)
        E[idx, c] = 1.0
    end
    QinvE = st.chol_Q_eff \ E                        # total × ncol  (= Q_eff⁻¹ at leaf cols)
    Qinv_leafblock = QinvE[cols, :]                   # ncol × ncol
    # Rank-K_B Woodbury correction at leaf rows and cols:
    X_G_leaf = st.X_G[cols, :]                       # ncol × K_B
    LB_leaf = Qinv_leafblock .+ st.α .* (X_G_leaf * (st.chol_S_K \ X_G_leaf'))
    return LB_leaf, cols
end

# ---------------------------------------------------------------------------
# Value (re-derived from the state; matches gaussian_marginal_loglik_sparse_phy).
# ---------------------------------------------------------------------------
function sparse_phy_value(st::SparsePhyState)
    logdet_A = sum(log, st.d_total) + logdet(st.chol_cap)
    logdet_Q_eff = logdet(st.chol_Q_eff)
    logdet_Qcond = logdet(st.chol_Qcond)
    logdet_M_sad = logdet_Q_eff + logdet(st.chol_S_K) - logdet(st.chol_cap)
    logdet_AnB = logdet_A + logdet_M_sad - st.K_aug * logdet_Qcond
    Cinv_m = _Cinv(st, st.m)
    quad_mean = st.n * dot(st.m, Cinv_m)
    Ainv_Yc = _AinvM(st, st.Y_c)
    quad_centered = sum(st.Y_c .* Ainv_Yc)
    logdet_full = logdet_AnB + (st.n - 1) * logdet_A
    return -0.5 * (st.n * st.p * log(2π) + logdet_full + quad_mean + quad_centered)
end

# ---------------------------------------------------------------------------
# Takahashi fast path for a single phylogenetic axis (`K_aug == 1`).
# ---------------------------------------------------------------------------
function _single_axis_leaf_rows(st::SparsePhyState)
    rows = Vector{Int}(undef, st.p)
    @inbounds for t in 1:st.p
        rows[t] = st.leaf_pos[t]
    end
    return rows
end

function _single_axis_Msad_inv_diag(st::SparsePhyState)
    Qeff_diag = takahashi_diag(st.chol_Q_eff)
    leafrows = _single_axis_leaf_rows(st)
    XGleaf = st.X_G[leafrows, :]
    WR = st.chol_S_K \ XGleaf'
    out = Vector{Float64}(undef, st.p)
    @inbounds for t in 1:st.p
        out[t] = Qeff_diag[leafrows[t]] + st.α * dot(@view(XGleaf[t, :]), @view(WR[:, t]))
    end
    return out
end

function _single_axis_loading_grad(st::SparsePhyState, cc::AbstractVector,
                                   msad_diag::AbstractVector)
    p, n, K_B = st.p, st.n, st.K_B
    λ = @view st.Λ_aug[:, 1]
    c = st.d_inv[1]

    # rank-K_B correction: σ²_phy (S M_sad⁻¹ D_K' F)_{t,:}·F_{t,:},
    # F (p×K_B) with F Fᵀ = DinvΛB cap⁻¹ DinvΛBᵀ.
    F = collect((st.chol_cap.L \ st.DinvΛB')')
    DKtF = zeros(Float64, st.total, K_B)
    @inbounds for a in 1:K_B, t in 1:p
        DKtF[st.leaf_pos[t], a] += λ[t] * F[t, a]
    end
    MsadinvDKtF = _MsadM(st, DKtF)
    leafrows = _single_axis_leaf_rows(st)
    SMsadDKtF = MsadinvDKtF[leafrows, :]
    corr = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        corr[t] = dot(@view(SMsadDKtF[t, :]), @view(F[t, :]))
    end

    # trace term τ_t = (Σ_phy Λ_axis C⁻¹)_{tt}.
    τ = st.σ²_phy .* (c .* λ .* msad_diag .- corr)

    # data term (Σ_phy Λ_axis cc)_t = σ²_phy (S Q_cond⁻¹ S')(λ .* cc).
    λcc = λ .* cc
    rhs = zeros(Float64, st.nb)
    @inbounds for t in 1:p
        rhs[st.leaf_pos[t]] = λcc[t]
    end
    sol = st.chol_Qcond \ rhs
    Σλcc = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        Σλcc[t] = st.σ²_phy * sol[st.leaf_pos[t]]
    end

    dλ = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        dλ[t] = n * (n * cc[t] * Σλcc[t] - τ[t])
    end
    return dλ
end

function _single_axis_scalar_grads(st::SparsePhyState, cc::AbstractVector,
                                   Ainv_Yc::AbstractMatrix,
                                   msad_diag::AbstractVector;
                                   want_σ²_eps::Bool)
    p, n, K_B = st.p, st.n, st.K_B
    λ = @view st.Λ_aug[:, 1]

    # dσ²_phy = ½ ⟨P_B, B⟩ / σ²_phy.
    tr_Msad_DtDinvD = 0.0
    @inbounds for t in 1:p
        tr_Msad_DtDinvD += msad_diag[t] * (λ[t]^2 * st.d_inv[t])
    end
    Msad_G = _MsadM(st, st.G)
    tr_Msad_GcapG = tr(st.chol_cap \ (st.G' * Msad_G))
    tr_Msad_H = tr_Msad_DtDinvD - tr_Msad_GcapG
    trCinvB = st.σ²_phy * tr_Msad_H
    Bcc = _Bphy_apply(st, cc)
    ccBcc = dot(cc, Bcc)
    dσ²_phy = 0.5 * (n * (-trCinvB + n * ccBcc)) / st.σ²_phy

    want_σ²_eps || return dσ²_phy, 0.0

    # dσ²_eps = ½ tr(P_A). With K_aug == 1, the trace contraction splits into
    # same-leaf Takahashi diagonal and a small rank-K_B correction.
    trAinv = _trAinv(st)
    c = st.d_inv[1]
    F = collect((st.chol_cap.L \ st.DinvΛB')')
    M_F = F' * F
    G_F = 2c .* Matrix{Float64}(I, K_B, K_B) .- M_F
    sameleaf_c2 = 0.0
    @inbounds for t in 1:p
        sameleaf_c2 += λ[t]^2 * msad_diag[t]
    end
    sameleaf_c2 *= c^2

    W = Matrix{Float64}(undef, st.total, K_B)
    @inbounds for a in 1:K_B
        W[:, a] = _DKt(st, @view F[:, a])
    end
    MW = _MsadM(st, W)
    WtMW = W' * MW
    lowrank = tr(G_F * WtMW)
    sum_LB_Z = sameleaf_c2 - lowrank
    trCinv = trAinv - st.α * sum_LB_Z
    trPA = -trCinv + n * dot(cc, cc) - (n - 1) * trAinv + sum(Ainv_Yc .^ 2)
    dσ²_eps = 0.5 * trPA

    return dσ²_phy, dσ²_eps
end

function _sparse_phy_grad_single_axis_takahashi(st::SparsePhyState;
                                                want_σ²_eps::Bool = true)
    cc = _Cinv(st, st.m)
    Ainv_Yc = _AinvM(st, st.Y_c)

    Cinv_LB = _CinvM(st, st.Λ_B)
    Ainv_LB = _AinvM(st, st.Λ_B)
    ccLB = cc * (cc' * st.Λ_B)
    AYcLB = Ainv_Yc * (Ainv_Yc' * st.Λ_B)
    dΛ_B = (-Cinv_LB) .+ st.n .* ccLB .- (st.n - 1) .* Ainv_LB .+ AYcLB

    msad_diag = _single_axis_Msad_inv_diag(st)
    daxis = _single_axis_loading_grad(st, cc, msad_diag)
    dσ²_phy, dσ²_eps = _single_axis_scalar_grads(
        st, cc, Ainv_Yc, msad_diag; want_σ²_eps = want_σ²_eps)

    dΛ_phy = st.K_phy > 0 ? reshape(daxis, st.p, 1) : nothing
    dσ_phy = st.has_unique ? daxis : nothing
    return (; dΛ_B, dσ²_eps, dσ²_phy, dΛ_phy, dσ_phy)
end

# ---------------------------------------------------------------------------
# Analytic gradient. Returns a NamedTuple of derivatives w.r.t. the natural
# parameters present in the standard model:
#   dΛ_B    :: p × K_B
#   dσ²_eps :: Float64
#   dσ²_phy :: Float64
#   dΛ_phy  :: p × K_phy   (present iff Λ_phy was supplied)
#   dσ_phy  :: Vector{p}   (present iff σ_phy was supplied)
# `dΛ_phy`/`dσ_phy` are `nothing` when the corresponding block is absent.
# ---------------------------------------------------------------------------
function sparse_phy_grad(st::SparsePhyState; want_σ²_eps::Bool = true)
    if st.K_aug == 1
        return _sparse_phy_grad_single_axis_takahashi(st; want_σ²_eps = want_σ²_eps)
    end

    p, n, K_B = st.p, st.n, st.K_B
    cc = _Cinv(st, st.m)                 # C⁻¹ m
    Ainv_Yc = _AinvM(st, st.Y_c)         # p × n

    # ---- ∂ℓ/∂Λ_B = P_A Λ_B  (O(p K_B)) ------------------------------------
    Cinv_LB = _CinvM(st, st.Λ_B)
    Ainv_LB = _AinvM(st, st.Λ_B)
    ccLB  = cc * (cc' * st.Λ_B)
    AYcLB = Ainv_Yc * (Ainv_Yc' * st.Λ_B)
    dΛ_B = (-Cinv_LB) .+ n .* ccLB .- (n - 1) .* Ainv_LB .+ AYcLB

    # Build the leaf-row × leaf-col block of M_sad⁻¹ once (drives the
    # tree-coupled derivatives). `LB` :: (K_aug·p) × (K_aug·p), with both
    # rows and columns indexed by (axis, leaf) — stride is `p` not `nb`,
    # i.e. row/col `(k - 1) * p + t` corresponds to axis k, leaf t.
    LB, _ = leaf_block_inv(st)

    # ---- ∂ℓ/∂σ²_phy = ½ ⟨P_B, B⟩ / σ²_phy  --------------------------------
    # ⟨P_B, B⟩ = n[ −tr(C⁻¹ B) + n (cc' B cc) ]
    # tr(C⁻¹ B) = σ²_phy · tr(M_sad⁻¹ H),  H = D_K' A⁻¹ D_K = D_K'D⁻¹D_K − G cap⁻¹ G'
    #   tr(M_sad⁻¹ D_K'D⁻¹D_K) : diagonal-in-leaf-across-axes  → leaf-block of M_sad⁻¹
    #   tr(M_sad⁻¹ G cap⁻¹ G') = tr(cap⁻¹ G' M_sad⁻¹ G)        → O(p K_B)
    # cc'Bcc: B cc via B = σ²_phy (Λ_augΛ_aug') ∘ Σ_phy = (Λ_aug Λ_aug') ∘ (σ²_phy G_phy);
    #   (R ∘ Σ_phy) w with R = u u' is diag(u) Σ_phy diag(u) w  → sparse solves.
    # leaf-diag-across-axes contraction of D_K'D⁻¹D_K with M_sad⁻¹:
    tr_Msad_DtDinvD = 0.0
    @inbounds begin
        # For axis pair (k,l) and leaf t: entry (D_K'D⁻¹D_K)[(k,t),(l,t)] =
        # λ_k[t] λ_l[t] d_inv[t]; contracted with M_sad⁻¹[(k,t),(l,t)].
        # `LB` row/col for (axis a, leaf t) = (a - 1) * p + t.
        for k in 1:st.K_aug
            for t in 1:p
                row_k = (k - 1) * p + t
                for l in 1:st.K_aug
                    row_l = (l - 1) * p + t
                    tr_Msad_DtDinvD += LB[row_l, row_k] *
                        (st.Λ_aug[t, k] * st.Λ_aug[t, l] * st.d_inv[t])
                end
            end
        end
    end
    Msad_G = _MsadM(st, st.G)                       # total × K_B
    tr_Msad_GcapG = tr(st.chol_cap \ (st.G' * Msad_G))
    tr_Msad_H = tr_Msad_DtDinvD - tr_Msad_GcapG
    trCinvB = st.σ²_phy * tr_Msad_H
    Bcc = _Bphy_apply(st, cc)
    ccBcc = dot(cc, Bcc)
    dσ²_phy = 0.5 * (n * (-trCinvB + n * ccBcc)) / st.σ²_phy

    # ---- ∂ℓ/∂σ²_eps = ½ tr(P_A) ------------------------------------------
    dσ²_eps = 0.0
    if want_σ²_eps
        trAinv = _trAinv(st)
        # tr(C⁻¹) = tr(A⁻¹) − tr(M̃⁻¹ Z),  Z = D_K' A⁻² D_K,  M̃⁻¹ = α M_sad⁻¹.
        # Z[(k,t),(l,u)] = λ_k[t] λ_l[u] (A⁻²)[t,u]. Using A⁻¹ = D⁻¹ + low-rank,
        # contract Z with M_sad⁻¹ leaf-block exactly (leaf×leaf, O(p²)).
        # Form AinvE_leaf := A⁻¹ applied to leaf-unit p-columns scaled by λ.
        # Simpler/robust: assemble U = A⁻¹ D_K explicitly on leaves then
        # Z = U'U; contract α tr(M_sad⁻¹ Z) using LB leaf rows.
        # U columns indexed like LB columns: U[:, c=(k,t)] = A⁻¹ (λ_k[t] e_{leaf t}).
        ncol = st.K_aug * p
        U = zeros(Float64, p, ncol)
        c = 0
        @inbounds for k in 1:st.K_aug
            for t in 1:p
                c += 1
                e = zeros(Float64, p); e[t] = st.Λ_aug[t, k]
                U[:, c] = _Ainv(st, e)
            end
        end
        Z = U' * U                                  # ncol × ncol = D_K' A⁻² D_K
        # tr(M̃⁻¹ Z) = α tr(M_sad⁻¹ Z); `LB` IS the leaf-leaf block already.
        trCinv = trAinv - st.α * sum(LB .* Z')
        trPA = -trCinv + n * dot(cc, cc) - (n - 1) * trAinv + sum(Ainv_Yc .^ 2)
        dσ²_eps = 0.5 * trPA
    end

    # ---- ∂ℓ/∂Λ_phy and ∂ℓ/∂σ_phy = (P_B ∘ Σ_phy) Λ_aug -------------------
    # P_B = n(−C⁻¹ + n cc cc'). (C⁻¹ ∘ Σ_phy) Λ_aug needs the leaf×leaf block of
    # C⁻¹ (selected inverse) — assembled from LB via C⁻¹ leaf-block = Woodbury.
    # We compute the dense leaf×leaf block of C⁻¹ once (O(p²)) then apply.
    Cleaf = _Cinv_leaf_block(st, LB)                # p × p  (C⁻¹ on leaves)
    Σ_phy_leaf = _Sigma_phy_leaf(st)                # p × p
    PB_leaf = n .* (-Cleaf .+ n .* (cc * cc'))      # P_B restricted to leaves
    PB_had = PB_leaf .* Σ_phy_leaf
    dΛ_aug = PB_had * st.Λ_aug                       # p × K_aug

    dΛ_phy = st.K_phy > 0 ? dΛ_aug[:, 1:st.K_phy] : nothing
    dσ_phy = st.has_unique ? dΛ_aug[:, end] : nothing

    return (; dΛ_B, dσ²_eps, dσ²_phy, dΛ_phy, dσ_phy)
end

# B_phy · w  with B = (Λ_aug Λ_aug') ∘ Σ_phy, Σ_phy = σ²_phy S Q_cond⁻¹ S'.
# (Λ_aug Λ_aug')∘Σ_phy applied to w = Σ_k diag(λ_k) Σ_phy diag(λ_k) w, and
# Σ_phy z = σ²_phy S Q_cond⁻¹ (S' z)  — an O(p) sparse solve per axis.
function _Bphy_apply(st::SparsePhyState, w::AbstractVector)
    out = zeros(Float64, st.p)
    @inbounds for k in 1:st.K_aug
        wz = st.Λ_aug[:, k] .* w
        # lift to nb-space at leaves, solve Q_cond, project back, scale
        rhs = zeros(Float64, st.nb)
        for t in 1:st.p
            rhs[st.leaf_pos[t]] = wz[t]
        end
        sol = st.chol_Qcond \ rhs
        for t in 1:st.p
            out[t] += st.Λ_aug[t, k] * st.σ²_phy * sol[st.leaf_pos[t]]
        end
    end
    out
end

# Dense leaf×leaf Σ_phy = σ²_phy · (S Q_cond⁻¹ S'). O(p²); used only for the
# Λ_phy/σ_phy Hadamard gradient term.
function _Sigma_phy_leaf(st::SparsePhyState)
    E = zeros(Float64, st.nb, st.p)
    @inbounds for t in 1:st.p
        E[st.leaf_pos[t], t] = 1.0
    end
    Sol = st.chol_Qcond \ E                          # nb × p
    G_phy = Sol[st.leaf_pos, :]                       # p × p  (= S Q_cond⁻¹ S')
    return st.σ²_phy .* G_phy
end

# Dense leaf×leaf block of C⁻¹ from the M_sad⁻¹ leaf-block (selected inverse)
# via the Woodbury form C⁻¹ = A⁻¹ − A⁻¹ D_K (α M_sad⁻¹) D_K' A⁻¹.
# On leaves: (S C⁻¹ S') = (S A⁻¹ S') − (S A⁻¹ D_K)(α M_sad⁻¹)(D_K' A⁻¹ S').
# `LB` is the (K_aug·p) × (K_aug·p) leaf-leaf block of M_sad⁻¹.
function _Cinv_leaf_block(st::SparsePhyState, LB::AbstractMatrix)
    p = st.p
    # S A⁻¹ S' (p × p): apply A⁻¹ to leaf unit columns.
    Eleaf = Matrix{Float64}(I, p, p)
    Ainv_leaf = _AinvM(st, Eleaf)                    # p × p  (A⁻¹ S' = A⁻¹ on leaves)
    SAinvS = Ainv_leaf                               # symmetric leaf block of A⁻¹
    # W := S A⁻¹ D_K  (p × ncol): column (k, t) = A⁻¹(D_K e_{(k,t)}) on leaves.
    # D_K e_{(k,leaf_t)} = λ_k[t] e_{leaf_t}; A⁻¹ of that, taken on leaves =
    #   λ_k[t] · Ainv_leaf[:, t]. So W's column (k,t) = λ_k[t] Ainv_leaf[:, t].
    ncol = st.K_aug * p
    W = zeros(Float64, p, ncol)
    c = 0
    @inbounds for k in 1:st.K_aug
        for t in 1:p
            c += 1
            W[:, c] = st.Λ_aug[t, k] .* @view Ainv_leaf[:, t]
        end
    end
    return SAinvS .- st.α .* (W * (LB * W'))
end
