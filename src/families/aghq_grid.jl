# Stage-1a AGHQ grid on the live twin pin `.gllvmTMB_aghq_grid`
# (gllvmTMB R/fit-multi.R). Probabilists' (standard-normal) Gauss–Hermite.
# This is NOT VA `_gauss_hermite` (physicists' e^{-t²} rule for ELBO E_q).
# Provenance: docs/dev-log/decisions/2026-08-17-aghq-stage1a-grid.md
# Identity lock: docs/dev-log/decisions/2026-08-17-aghq-identity.md (#248).
# No public aghq= knob. Ledger rows stay missing.

"""
    AGHQGrid

Tensor Gauss–Hermite grid on the live `.gllvmTMB_aghq_grid` convention.
`nodes` is `k^d × d` (one row per tensor node); `logw` is length `k^d` with

```
logw_j = Σ_m log w_{j_m} + (d/2) log(2π) + ½ u_j'u_j
```

Internal. Not a public estimator surface.
"""
struct AGHQGrid
    nodes::Matrix{Float64}
    logw::Vector{Float64}
    d::Int
    k::Int
end

"""
    _aghq_gh_normal(k) -> (nodes, weights)

One-dimensional Gauss–Hermite rule for the standard-normal measure
(probabilists' scaling): `Σ w = 1` and `Σ w x² = 1` for `k ≥ 2`, so
`E[g(Z)] ≈ Σ_j w_j g(x_j)` for `Z ~ N(0, 1)`. Golub–Welsch Jacobi matrix
has zero diagonal and off-diagonals `√(1:(k-1))`; weights are the squared
first eigenvector components. `k = 1` is the Laplace point rule
`(nodes, weights) = ([0], [1])`.

Must not call [`_gauss_hermite`](@ref): that is the physicists' `e^{-t²}`
rule (`Σ w = √π`) used by VA.
"""
function _aghq_gh_normal(k::Integer)
    k ≥ 1 || throw(ArgumentError("_aghq_gh_normal: k must be ≥ 1, got $k"))
    k == 1 && return ([0.0], [1.0])
    off = [sqrt(Float64(j)) for j in 1:(k - 1)]
    E = eigen(SymTridiagonal(zeros(k), off))
    ord = sortperm(E.values)
    return (E.values[ord], E.vectors[1, ord] .^ 2)
end

"""
    aghq_grid(d, k) -> AGHQGrid

`d`-dimensional tensor product of the [`_aghq_gh_normal`](@ref) rule with
`k` nodes per axis, on the live `.gllvmTMB_aghq_grid` convention. First
axis varies fastest (R `expand.grid` order).
"""
function aghq_grid(d::Integer, k::Integer)
    d ≥ 1 || throw(ArgumentError("aghq_grid: d must be ≥ 1, got $d"))
    k ≥ 1 || throw(ArgumentError("aghq_grid: k must be ≥ 1, got $k"))
    nodes1, w1 = _aghq_gh_normal(k)
    logw1 = log.(w1)
    ngrid = k^d
    nodes = Matrix{Float64}(undef, ngrid, d)
    logw = Vector{Float64}(undef, ngrid)
    half_log2π = (d / 2) * log(2π)
    idx = 0
    for I in Iterators.product(ntuple(_ -> 1:k, d)...)
        idx += 1
        s2 = 0.0
        lw = 0.0
        @inbounds for m in 1:d
            u = nodes1[I[m]]
            nodes[idx, m] = u
            lw += logw1[I[m]]
            s2 += u * u
        end
        logw[idx] = lw + half_log2π + 0.5 * s2
    end
    return AGHQGrid(nodes, logw, Int(d), Int(k))
end

"""
    aghq_grid_ok(grid; tol=1e-8) -> Bool

Live-pin sanity check: `Σ_j exp(logw_j) φ_d(u_j) = 1`. For `k > 1` also
requires the second-moment identity `Σ_j w_j u_j u_j' = I`. The `k = 1`
rule is the Laplace point (single node at 0) and carries no second moment.
"""
function aghq_grid_ok(grid::AGHQGrid; tol::Real = 1e-8)
    d = grid.d
    size(grid.nodes, 2) == d || return false
    length(grid.logw) == size(grid.nodes, 1) || return false
    log_phi = -0.5 .* sum(abs2, grid.nodes; dims = 2) .- (d / 2) * log(2π)
    w = exp.(grid.logw .+ vec(log_phi))
    abs(sum(w) - 1) ≤ tol || return false
    size(grid.nodes, 1) == 1 && return true
    M = zeros(d, d)
    @inbounds for j in axes(grid.nodes, 1)
        u = view(grid.nodes, j, :)
        M .+= w[j] .* (u * u')
    end
    return isapprox(M, Matrix{Float64}(I, d, d); atol = 1e-6)
end

function _aghq_stage1a_reject_extra(family, row_effects, phylo, mi,
        unique_latent, s_B, use_lv_B, multinomial)
    row_effects === nothing ||
        throw(ArgumentError("AGHQ Stage 1a: row effects are not a loadings-only z_B block"))
    phylo === nothing ||
        throw(ArgumentError("AGHQ Stage 1a: phylogenetic structure is not a loadings-only z_B block"))
    mi === nothing ||
        throw(ArgumentError("AGHQ Stage 1a: mi() is not a loadings-only z_B block"))
    unique_latent === nothing || unique_latent === false ||
        throw(ArgumentError("AGHQ Stage 1a: unique / free s_B latents are ineligible"))
    s_B === nothing ||
        throw(ArgumentError("AGHQ Stage 1a: free s_B is ineligible (loadings-only z_B)"))
    use_lv_B === nothing || use_lv_B === false ||
        throw(ArgumentError("AGHQ Stage 1a: use_lv_B is ineligible (loadings-only z_B)"))
    multinomial === nothing || multinomial === false ||
        throw(ArgumentError("AGHQ Stage 1a: multinomial is ineligible"))
    occursin("Multinomial", string(nameof(typeof(family)))) &&
        throw(ArgumentError("AGHQ Stage 1a: multinomial is ineligible"))
    return nothing
end

"""
    _aghq_kd_bound(d, k) -> Nothing

Cheap tensor-cost bound on a dense loadings-only `z_B` block of latent
dimension `d` (size `k^d`). Hopper pin: analogue of twin `tw ≤ 4` is
`d ≤ 5` on this complete block — not a treewidth measurement, not
`.aghq_gate`. `_aghq_d_bound` and `aghq_gate` stay undefined.

Throws `ArgumentError` when `k < 1` or `d < 1`, and when `k > 1` and
`d > 5`. Returns `nothing` at `k = 1` for every `d ≥ 1` (including
`d > 5`) so the site evaluator stays the `u = 0` Laplace template
(A4.4 unpaid — do not skip to a different function). Error text names
tensor `k^d` / `d`, never treewidth.
"""
function _aghq_kd_bound(d::Integer, k::Integer)
    if k < 1 || d < 1
        throw(ArgumentError(
            "AGHQ Stage 1a: tensor cost k^d requires k ≥ 1 and d ≥ 1, got d=$d, k=$k"))
    end
    if k > 1 && d > 5
        throw(ArgumentError(
            "AGHQ Stage 1a: tensor cost k^d with d=$d, k=$k exceeds d ≤ 5; " *
            "k = 1 remains Laplace"))
    end
    return nothing
end

@inline function _aghq_logsumexp(x::AbstractVector)
    m = maximum(x)
    isfinite(m) || return m
    s = 0.0
    @inbounds for xi in x
        s += exp(xi - m)
    end
    return m + log(s)
end

"""
    aghq_stage1a_loglik_site(family, y, n, Λ, β, link; k=1, ...) -> Float64

Stage-1a/1b site evaluator on a single loadings-only `z_B` block. Liu–Pierce
adaptation at the existing Laplace mode (Hopper A4(2) pin; no `√2`):

```
z_ij = ẑᵢ + Lᵢ^{-T} uⱼ
log Lᵢ = −½ logdet Aᵢ + logsumexpⱼ(logwⱼ + inner_ll(i,j))
```

`Aᵢ = Λ'WΛ + I` is the Laplace expected-Fisher cache at `ẑᵢ`; `L^{-T}` is
`R^{-1}` from `cholesky(Aᵢ)`. `inner_ll` is the Stage-1a joint
`ℓ − ½ z′z − (d/2) log(2π)` at each mapped node. At `k = 1` the single
node is `u = 0`, so this **is** the existing Laplace golden — the template
is evaluated, not skipped (twin fit-time `k = 1` → Laplace routing is A4.4).

Fails loud if the random part is not loadings-only `z_B`
(`unique`/`s_B`, `use_lv_B`, `mi()`, multinomial, row effects, phylo).
At `k > 1`, also fails loud when `d > 5` ([`_aghq_kd_bound`](@ref);
tensor cost `k^d` / `d ≤ 5`). `k = 1` is still the Laplace template.
Not a public `aghq=` surface. Not a capability claim.
"""
function aghq_stage1a_loglik_site(family, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        k::Integer = 1, mask = nothing, offset = nothing,
        row_effects = nothing, phylo = nothing, mi = nothing,
        unique_latent = nothing, s_B = nothing,
        use_lv_B = nothing, multinomial = nothing,
        maxiter::Integer = 100, tol::Real = 1e-9)
    k ≥ 1 || throw(ArgumentError("AGHQ Stage 1a: k must be ≥ 1, got $k"))
    _aghq_stage1a_reject_extra(family, row_effects, phylo, mi, unique_latent,
                              s_B, use_lv_B, multinomial)
    d = size(Λ, 2)
    _aghq_kd_bound(d, k)
    grid = aghq_grid(d, k)
    p = size(Λ, 1)
    off = offset === nothing ? false : offset
    z = _laplace_mode(family, y, n, Λ, β, link;
                      mask = mask, offset = offset, maxiter = maxiter, tol = tol)
    Λz = Λ * z
    η = _clamp_eta.(β .+ off .+ Λz)
    μ = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    W = _glm_weight.(Ref(family), μ, n, me)
    if mask !== nothing
        W = ifelse.(mask, W, 0.0)
    end
    Amat = Λ' * (W .* Λ)
    @inbounds for i in 1:d
        Amat[i, i] += 1.0
    end
    A = Symmetric(Amat)
    logdet_i = -0.5 * logdet(A)
    # A = R'R; L = R' so L^{-T} = R^{-1}. No √2; no twin ridge / 1e-8 floor.
    R = cholesky(A).U
    ngrid = size(grid.nodes, 1)
    terms = Vector{Float64}(undef, ngrid)
    half_log2π = (d / 2) * log(2π)
    @inbounds for j in 1:ngrid
        zj = z + (R \ view(grid.nodes, j, :))
        Λzj = Λ * zj
        ηj = _clamp_eta.(β .+ off .+ Λzj)
        μj = _clamp_mu.(Ref(family), linkinv.(Ref(link), ηj))
        ℓj = 0.0
        for t in 1:p
            (mask === nothing || mask[t]) || continue
            ℓj += _glm_logpdf(family, μj[t], n[t], y[t])
        end
        inner_ll = ℓj - 0.5 * dot(zj, zj) - half_log2π
        terms[j] = grid.logw[j] + inner_ll
    end
    return logdet_i + _aghq_logsumexp(terms)
end

"""
    aghq_stage1a_marginal_loglik(family, Y, N, Λ, β, link; k=1, ...) -> Float64

Sum of [`aghq_stage1a_loglik_site`](@ref) over sites. Loadings-only `z_B`.
`k = 1` remains the Laplace template golden; `k > 1` is Stage-1b adaptation.
"""
function aghq_stage1a_marginal_loglik(family, Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        k::Integer = 1, mask = nothing, offset = nothing, kwargs...)
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        mi = mask === nothing ? nothing : view(mask, :, i)
        oi = offset === nothing ? nothing : view(offset, :, i)
        acc += aghq_stage1a_loglik_site(family, view(Y, :, i), view(N, :, i),
                                        Λ, β, link; k = k, mask = mi, offset = oi,
                                        kwargs...)
    end
    return acc
end
