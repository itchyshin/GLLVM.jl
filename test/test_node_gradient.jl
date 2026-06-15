using GLLVM, Test, Random, LinearAlgebra, ForwardDiff, SparseArrays

# node_gradient.jl + sparse_phy_grad.jl are wired into the GLLVM module, so this
# test uses the module's symbols directly — NO self-include. Exported node
# functions (node_grad, build_node_perspecies, grad_node_perspecies, node_blups)
# are used bare; module internals (build_sparse_phy_state, sparse_phy_grad,
# AugmentedPhy, gaussian_marginal_loglik) are GLLVM-qualified. Self-including the
# src files here would split the AugmentedPhy type against the suite's other
# phylo tests (which self-include sparse_phy.jl into Main).

const _gml = GLLVM.gaussian_marginal_loglik
const _aug = GLLVM.augmented_phy

# ---------------------------------------------------------------------------
# Test-only helpers (NOT ported into src/ — they are FD scaffolding).
# ---------------------------------------------------------------------------

# Fixed leaf covariance G_phy = S Q_cond⁻¹ S' so the dense FD reference uses the
# IDENTICAL Σ_phy = σ²_phy · G_phy as the node-frame state. Built densely (test
# only). Mirrors `_gphy` in test_sparse_phy_grad.jl.
function _gphy(phy)
    p = phy.n_leaves
    keep = filter(i -> i != phy.root_index, 1:phy.n_total)
    Qc = Matrix(phy.Q_topology[keep, keep])
    lp = Vector{Int}(undef, p)
    for t in 1:p
        l = phy.leaf_indices[t]
        lp[t] = phy.root_index < l ? l - 1 : l
    end
    return inv(Symmetric(Qc))[lp, lp]
end

# Small balanced + caterpillar Newick builders (local; the engine has
# random_balanced_tree but the caterpillar exercises the O(p)-on-all-shapes
# claim, so we build both explicitly here).
function _balanced_newick(leaves::Vector{String}, bl::Float64)
    length(leaves) == 1 && return leaves[1] * ":" * string(bl)
    mid = cld(length(leaves), 2)
    L = _balanced_newick(leaves[1:mid], bl)
    R = _balanced_newick(leaves[mid+1:end], bl)
    return "(" * L * "," * R * "):" * string(bl)
end
balanced_newick(p::Int; bl::Float64 = 0.1) =
    _balanced_newick(["t$i" for i in 1:p], bl) * ";"

function caterpillar_newick(p::Int; bl::Float64 = 0.1)
    p >= 2 || error("caterpillar needs p ≥ 2")
    s = "(t1:$bl,t2:$bl):$bl"
    for i in 3:p
        s = "($s,t$i:$bl):$bl"
    end
    return s * ";"
end

# Central FD gradient of f at x, step h (relative). Copied from the prototype.
function fd_grad(f, x::AbstractVector; h::Float64 = 1e-6)
    g = similar(float.(x))
    for i in eachindex(x)
        step = h * max(abs(x[i]), 1.0)
        xp = collect(float.(x)); xp[i] += step
        xm = collect(float.(x)); xm[i] -= step
        g[i] = (f(xp) - f(xm)) / (2 * step)
    end
    return g
end

# Dense Σ_phy = S Q_cond⁻¹ S' from an AugmentedPhy (σ²_phy applied separately).
# Copied from the prototype; used by the single-trait FD target.
function sigma_phy_unit(phy::GLLVM.AugmentedPhy)
    keep = filter(i -> i != phy.root_index, 1:phy.n_total)
    Qc = Matrix(phy.Q_topology[keep, keep])
    nb = size(Qc, 1); p = phy.n_leaves
    lp = [phy.root_index < phy.leaf_indices[t] ? phy.leaf_indices[t] - 1 : phy.leaf_indices[t]
          for t in 1:p]
    Sm = zeros(p, nb); for t in 1:p; Sm[t, lp[t]] = 1.0; end
    return Sm * (Qc \ Sm')
end

# Matched single-trait fixed-μ dense negll (σ²_phy folded into σ_phy; no Λ_B).
# Σ = σ²_eps I + Λ_φ Σ_phy Λ_φ. Copied from the prototype; FD target for
# grad_node_perspecies. NOTE grad_node_perspecies returns ∂negll/∂σ_phy =
# ½(trace − dataq) (optimiser convention; opposite sign to node_grad's
# ∂loglik), so the FD target here is `+negll_perspecies_dense` (un-negated).
function negll_perspecies_dense(phy::GLLVM.AugmentedPhy, y::AbstractVector,
                                σ_phy::AbstractVector, σ²_eps::Real, μ::Real)
    p = phy.n_leaves
    Σφ = sigma_phy_unit(phy)
    Λφ = Diagonal(σ_phy)
    Σ = σ²_eps .* I(p) .+ Λφ * Σφ * Λφ
    cΣ = cholesky(Symmetric((Σ + Σ') ./ 2))
    r = y .- μ
    return 0.5 * (p * log(2π) + logdet(cΣ) + dot(r, cΣ \ r))
end

relmax(a, b) = maximum(abs.(vec(a) .- vec(b))) / max(1.0, maximum(abs.(vec(b))))

# Dense marginal log-lik as a function of the natural parameters, packed into a
# single vector so ForwardDiff promotes every input to one Dual type (the dense
# path mutates A, so feeding partial Duals fails). phylo_unique layout (K_aug=1,
# no Λ_phy): [vec(Λ_B); σ²_eps; σ²_phy; σ_phy]   (σ²_eps, σ²_phy raw).
# Mirrors `_dense_packed` in test_sparse_phy_grad.jl, specialised to has_unique.
function _dense_packed_unique(y, Gphy, p, K_B)
    return function (par)
        cur = 0
        Λ_B = reshape(par[cur+1:cur+p*K_B], p, K_B); cur += p * K_B
        s2e = par[cur+1]; cur += 1
        s2p = par[cur+1]; cur += 1
        σ_phy = par[cur+1:cur+p]; cur += p
        _gml(y, Λ_B, sqrt(s2e); σ_phy = σ_phy, Σ_phy = s2p .* Gphy)
    end
end

@testset "node-frame analytic gradient" begin

    # ---- GATE 1: node_grad == ForwardDiff of the dense path, ~1e-6 rel.
    # Balanced + caterpillar small trees; phylo_unique (K_aug=1).
    @testset "node_grad FD ($(shape), p=$(p))" for shape in (:balanced, :caterpillar),
                                                    p in (8, 12)
        Random.seed!(300 + p + (shape === :balanced ? 0 : 1))
        nw = shape === :balanced ? balanced_newick(p; bl = 0.12) :
                                   caterpillar_newick(p; bl = 0.12)
        phy = _aug(nw)
        K_B = 2; n = 3 * p
        Gphy = _gphy(phy)
        Λ_B = 0.7 .* randn(p, K_B)
        σ_phy = abs.(randn(p)) .+ 0.3
        σ_eps = 0.5; σ²_phy = 0.8
        y = randn(p, n)

        st = GLLVM.build_sparse_phy_state(y, Λ_B, σ_eps; σ_phy = σ_phy,
                                    phy = phy, σ²_phy = σ²_phy)
        g = node_grad(st)

        f = _dense_packed_unique(y, Gphy, p, K_B)
        par0 = vcat(vec(Λ_B), σ_eps^2, σ²_phy, σ_phy)
        gfd = ForwardDiff.gradient(f, par0)
        cur = 0
        gLB = reshape(gfd[cur+1:cur+p*K_B], p, K_B); cur += p * K_B
        gs2e = gfd[cur+1]; cur += 1
        gs2p = gfd[cur+1]; cur += 1
        gsp = gfd[cur+1:cur+p]; cur += p

        @test relmax(g.dΛ_B, gLB) < 1e-6
        @test abs(g.dσ²_eps - gs2e) / max(1.0, abs(gs2e)) < 1e-6
        @test abs(g.dσ²_phy - gs2p) / max(1.0, abs(gs2p)) < 1e-6
        @test relmax(g.dσ_phy, gsp) < 1e-6

        @info "node_grad FD max-abs diffs ($shape, p=$p)" dΛ_B = maximum(abs.(g.dΛ_B .- gLB)) dσ²_eps = abs(g.dσ²_eps - gs2e) dσ²_phy = abs(g.dσ²_phy - gs2p) dσ_phy = maximum(abs.(g.dσ_phy .- gsp))
    end

    # ---- GATE 2: node_grad ≡ the preserved leaf-block reference to machine precision.
    @testset "node_grad ≡ leaf-block reference ($(shape), p=$(p))" for shape in (:balanced, :caterpillar),
                                                                         p in (8, 16, 32)
        Random.seed!(500 + p + (shape === :balanced ? 0 : 1))
        nw = shape === :balanced ? balanced_newick(p; bl = 0.1) :
                                   caterpillar_newick(p; bl = 0.1)
        phy = _aug(nw)
        K_B = 2; n = p + 3
        Λ_B = 0.7 .* randn(p, K_B)
        σ_phy = abs.(randn(p)) .+ 0.3
        σ_eps = 0.6; σ²_phy = 0.8
        y = randn(p, n)

        st = GLLVM.build_sparse_phy_state(y, Λ_B, σ_eps; σ_phy = σ_phy,
                                    phy = phy, σ²_phy = σ²_phy)
        ge = GLLVM._sparse_phy_grad_leafblock(st)
        gn = node_grad(st)

        @test relmax(gn.dΛ_B, ge.dΛ_B) < 1e-8
        @test abs(gn.dσ²_eps - ge.dσ²_eps) / max(1.0, abs(ge.dσ²_eps)) < 1e-8
        @test abs(gn.dσ²_phy - ge.dσ²_phy) / max(1.0, abs(ge.dσ²_phy)) < 1e-8
        @test relmax(gn.dσ_phy, ge.dσ_phy) < 1e-8

        @info "node ≡ leaf-block max-rel ($shape, p=$p)" dΛ_B = relmax(gn.dΛ_B, ge.dΛ_B) dσ²_eps = abs(gn.dσ²_eps - ge.dσ²_eps) / max(1.0, abs(ge.dσ²_eps)) dσ²_phy = abs(gn.dσ²_phy - ge.dσ²_phy) / max(1.0, abs(ge.dσ²_phy)) dσ_phy = relmax(gn.dσ_phy, ge.dσ_phy)
    end

    # ---- GATE 3: matched single-trait per-species node grad vs central FD.
    @testset "grad_node_perspecies FD ($(shape), p=$(p))" for shape in (:balanced, :caterpillar),
                                                               p in (8, 16, 32)
        nw = shape === :balanced ? balanced_newick(p; bl = 0.1) :
                                   caterpillar_newick(p; bl = 0.1)
        phy = _aug(nw)
        Random.seed!(200 + p); y = randn(p); μ = 0.21
        σ_phy = 0.3 .+ 0.7 .* abs.(randn(p)); σ²_eps = 0.5

        stn = build_node_perspecies(phy, σ_phy, σ²_eps)
        gn = grad_node_perspecies(stn, y, μ)
        # grad_node_perspecies = ∂negll/∂σ_phy (optimiser convention; opposite
        # sign to node_grad's ∂loglik). FD target is +negll (un-negated).
        f = sp -> negll_perspecies_dense(phy, y, sp, σ²_eps, μ)
        gfd = fd_grad(f, σ_phy; h = 1e-6)

        @test relmax(gn, gfd) < 1e-6
        @info "grad_node_perspecies FD max-rel ($shape, p=$p)" rel = relmax(gn, gfd)
    end

    # ---- GATE 4: node BLUPs (posterior mean) vs dense reference.
    @testset "node BLUPs vs dense ($(shape), p=$(p))" for shape in (:balanced, :caterpillar),
                                                          p in (8, 16, 32)
        nw = shape === :balanced ? balanced_newick(p; bl = 0.1) :
                                   caterpillar_newick(p; bl = 0.1)
        phy = _aug(nw)
        Random.seed!(400 + p); y = randn(p); μ = 0.137
        σ²_eps = 0.45; σ²_phy = 0.7; σ_phy = fill(sqrt(σ²_phy), p)

        stn = build_node_perspecies(phy, σ_phy, σ²_eps)
        û, ẑ_tip = node_blups(stn, y, μ)

        # Dense reference: û = Λ̃⁻¹ (σ_eps⁻² S' Λ_φ (y − μ)).
        keep = filter(i -> i != phy.root_index, 1:phy.n_total)
        Qc = Matrix(phy.Q_topology[keep, keep]); nb = size(Qc, 1)
        lp = stn.leaf_pos
        Sm = zeros(p, nb); for t in 1:p; Sm[t, lp[t]] = 1.0; end
        Λ̃ref = Qc .+ (1 / σ²_eps) .* (Sm' * Diagonal(σ_phy .^ 2) * Sm)
        rhsref = (1 / σ²_eps) .* (Sm' * (σ_phy .* (y .- μ)))
        û_ref = Λ̃ref \ rhsref

        @test relmax(û, û_ref) < 1e-8
        # Tip BLUP consistency: ẑ_tip[t] = σ_phy[t] û[leaf(t)].
        @test maximum(abs.(ẑ_tip .- [σ_phy[t] * û[lp[t]] for t in 1:p])) < 1e-12
        @info "node BLUP max-rel ($shape, p=$p)" rel = relmax(û, û_ref)
    end
end
