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
# * ∂ℓ/∂σ²_phy, ∂ℓ/∂σ²_eps, ∂ℓ/∂Λ_phy, ∂ℓ/∂σ_phy : these need the leaf-block
#   of the augmented inverse M_sad⁻¹ (a SELECTED INVERSE). For a scalar σ²_phy
#   scaling a fixed tree there is a closed form for d/dσ²_phy log|Q_cond| alone
#   (= −(#augmented nodes)/σ²_phy; see edge_incidence.log_det_Q), but the FULL
#   marginal likelihood couples the tree to A through the loadings, so the
#   leaf-block of M_sad⁻¹ genuinely re-enters. We compute it EXACTLY via a
#   batched CHOLMOD solve `chol_Q_eff \ E_leaf` (cost O(p²); memory O(p²)).
#   This is sub-dominant to dense-ForwardDiff (O(p³) per directional derivative
#   × O(pK) params) so the analytic path is still dramatically faster at large
#   p, but it is NOT O(p): dropping to O(p) needs the Takahashi / tree
#   belief-propagation selected inverse, which is the explicit follow-up the
#   PERF task scoped out. `leaf_block_inv` is isolated for exactly that swap.
#
# This file is self-contained: it `include`s the sources it needs and does NOT
# modify src/GLLVM.jl or any existing file.

using SparseArrays
using LinearAlgebra

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
        G, S_K, chol_S_K, phy)
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
# Selected inverse: leaf-block of M_sad⁻¹ (and Q_eff⁻¹), the only non-O(p)
# kernel. Computed EXACTLY via a batched CHOLMOD solve against the leaf unit
# columns. Cost O(p²); isolate here so a future Takahashi / tree-BP selected
# inverse is a drop-in replacement.
#
# Returns `LB :: total × (K_aug·p)` with column c = (axis k, leaf t) holding
# M_sad⁻¹ e_{off_k+leaf_pos[t]}. The leaf rows of `LB` are the leaf×leaf block.
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
function leaf_block_inv(st::SparsePhyState)
    cols = _leaf_unit_columns(st)
    E = zeros(Float64, st.total, length(cols))
    @inbounds for (c, idx) in enumerate(cols)
        E[idx, c] = 1.0
    end
    return _MsadM(st, E), cols          # total × (K_aug·p)
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
    p, n, K_B = st.p, st.n, st.K_B
    cc = _Cinv(st, st.m)                 # C⁻¹ m
    Ainv_Yc = _AinvM(st, st.Y_c)         # p × n

    # ---- ∂ℓ/∂Λ_B = P_A Λ_B  (O(p K_B)) ------------------------------------
    Cinv_LB = _CinvM(st, st.Λ_B)
    Ainv_LB = _AinvM(st, st.Λ_B)
    ccLB  = cc * (cc' * st.Λ_B)
    AYcLB = Ainv_Yc * (Ainv_Yc' * st.Λ_B)
    dΛ_B = (-Cinv_LB) .+ n .* ccLB .- (n - 1) .* Ainv_LB .+ AYcLB

    # Build the leaf-block selected inverse once (drives the tree-coupled
    # derivatives). LB :: total × (K_aug·p), col c=(axis k, leaf t).
    LB, _ = leaf_block_inv(st)
    nb = st.nb
    # leaf_row_index[(axis l, leaf u)] = off_l + leaf_pos[u]  (row in `total`)
    # We need M_sad⁻¹ entries between leaf rows and the leaf columns we solved.
    # Index helper for the leaf rows in `total` space:
    leaf_rows = _leaf_unit_columns(st)   # same ordering as columns of LB

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
        # LB column c indexes (axis, leaf); we need rows at (other axis, same leaf).
        col = 0
        for k in 1:st.K_aug
            for t in 1:p
                col += 1
                # rows for (axis l, same leaf t):
                for l in 1:st.K_aug
                    row = (l - 1) * nb + st.leaf_pos[t]
                    tr_Msad_DtDinvD += LB[row, col] *
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
        # tr(M̃⁻¹ Z) = α tr(M_sad⁻¹ Z); M_sad⁻¹ leaf rows are LB[leaf_rows, :].
        Msad_leafblock = LB[leaf_rows, :]           # (K_aug·p) × (K_aug·p)
        trCinv = trAinv - st.α * sum(Msad_leafblock .* Z')
        trPA = -trCinv + n * dot(cc, cc) - (n - 1) * trAinv + sum(Ainv_Yc .^ 2)
        dσ²_eps = 0.5 * trPA
    end

    # ---- ∂ℓ/∂Λ_phy and ∂ℓ/∂σ_phy = (P_B ∘ Σ_phy) Λ_aug -------------------
    # P_B = n(−C⁻¹ + n cc cc'). (C⁻¹ ∘ Σ_phy) Λ_aug needs the leaf×leaf block of
    # C⁻¹ (selected inverse) — assembled from LB via C⁻¹ leaf-block = Woodbury.
    # We compute the dense leaf×leaf block of C⁻¹ once (O(p²)) then apply.
    Cleaf = _Cinv_leaf_block(st, LB, leaf_rows)     # p × p  (C⁻¹ on leaves)
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
function _Cinv_leaf_block(st::SparsePhyState, LB::AbstractMatrix, leaf_rows::AbstractVector)
    p = st.p
    # S A⁻¹ S' (p × p): apply A⁻¹ to leaf unit columns.
    Eleaf = Matrix{Float64}(I, p, p)
    Ainv_leaf = _AinvM(st, Eleaf)                    # p × p  (A⁻¹ S' = A⁻¹ on leaves)
    SAinvS = Ainv_leaf                               # symmetric leaf block of A⁻¹
    # W := S A⁻¹ D_K  (p × total): column j = A⁻¹(D_K e_j) restricted to leaves.
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
    Msad_leafblock = LB[leaf_rows, :]                # (ncol) × (ncol)
    return SAinvS .- st.α .* (W * (Msad_leafblock * W'))
end
