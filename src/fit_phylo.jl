# O(p) single-trait single-variance phylogenetic Gaussian fit.
#
# Model (one trait over p species on a tree):
#     y = μ·1 + σ·u + ε,   u ~ N(0, Σ_phy_unit),  ε ~ N(0, σ²_eps I)
#   ⇒ y ~ N(μ·1, Σ),       Σ = σ²_eps I + σ²_phy · Σ_phy_unit,   σ²_phy = σ².
#
# Σ_phy_unit = S Q_cond⁻¹ S' is the unit-variance Brownian-motion tip
# covariance and is NEVER formed densely. Reusing the node machinery
# (`build_node_perspecies` → `NodePerSpecies`), every likelihood evaluation is
# O(p): log|Σ| via the matrix-determinant lemma (CHOLMOD logdet of the sparse
# node factors) and the quadratic form via a Woodbury solve. Three free
# parameters {μ, σ²_phy, σ²_eps}, fit by L-BFGS.
#
# Ported from the local bench prototype `julia/P4_fit_sv.jl` (provenance noted
# in docs/dev-log/decisions/). CHOLMOD blocks forward-mode AD, so the L-BFGS
# gradient is finite-difference (3 FD evals per gradient ⇒ still O(p)).

"""
    PhyloGaussianFit

Result of [`fit_phylo_gaussian`](@ref): the maximum-likelihood estimates `μ`,
`σ²_phy`, `σ²_eps` of the single-trait single-variance phylogenetic Gaussian
model, the achieved `negll`, the optimiser `converged` flag, and the number of
`iterations` taken.
"""
struct PhyloGaussianFit
    μ::Float64
    σ²_phy::Float64
    σ²_eps::Float64
    negll::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::PhyloGaussianFit)
    print(io, "PhyloGaussianFit(μ=", round(f.μ; sigdigits = 5),
          ", σ²_phy=", round(f.σ²_phy; sigdigits = 5),
          ", σ²_eps=", round(f.σ²_eps; sigdigits = 5),
          ", negll=", round(f.negll; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

# Σ⁻¹ b via Woodbury (O(p)):
#   Σ⁻¹ b = σ_eps⁻² b − σ_eps⁻⁴ · σ_phy ⊙ S [ Λ̃⁻¹ ( S' (σ_phy ⊙ b) ) ].
function _phylo_sigma_inv_apply(st::NodePerSpecies, b::AbstractVector)
    p = st.phy.n_leaves
    inve = 1.0 / st.σ²_eps
    sp = st.σ_phy
    φb = sp .* b
    rhs = zeros(Float64, st.nb)
    @inbounds for t in 1:p
        rhs[st.leaf_pos[t]] = φb[t]
    end
    sol = (st.cΛ̃ \ rhs)::Vector{Float64}
    out = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        out[t] = inve * b[t] - inve^2 * sp[t] * sol[st.leaf_pos[t]]
    end
    return out
end

# O(p) negative log-likelihood given a prebuilt node state (σ²_phy, σ²_eps
# baked into st). log|Σ| = p·log σ²_eps + log|Λ̃| − log|Q_cond|.
function _phylo_negll(st::NodePerSpecies, y::AbstractVector, μ::Real)
    p = st.phy.n_leaves
    logdetΣ = p * log(st.σ²_eps) + logdet(st.cΛ̃) - logdet(st.chol_Qcond)
    r = y .- μ
    quad = dot(r, _phylo_sigma_inv_apply(st, r))
    return 0.5 * (p * log(2π) + logdetΣ + quad)
end

# GLS-profiled μ̂ = (1ᵀ Σ⁻¹ 1)⁻¹ (1ᵀ Σ⁻¹ y), via two Woodbury solves.
function _phylo_profile_mu(st::NodePerSpecies, y::AbstractVector)
    one_p = ones(Float64, st.phy.n_leaves)
    Σi1 = _phylo_sigma_inv_apply(st, one_p)
    Σiy = _phylo_sigma_inv_apply(st, y)
    return dot(one_p, Σiy) / dot(one_p, Σi1)
end

# Large finite penalty so the line search never sees Inf/NaN at pathological
# variance trials (σ² → 0 / Inf / NaN).
const _PHYLO_PENALTY = 1e12

"""
    fit_phylo_gaussian(phy, y; profile_mu=true, μ0, logσ²phy0, logσ²eps0,
                       g_tol=1e-5, iterations=500) -> PhyloGaussianFit

Fit the O(p) single-trait single-variance phylogenetic Gaussian model
`y ~ N(μ·1, σ²_eps·I + σ²_phy·Σ_phy_unit)` by L-BFGS on the sparse, O(p)
marginal negative log-likelihood — where `Σ_phy_unit` is the unit-variance
Brownian-motion tip covariance of the tree, never formed densely.

`phy` is an `AugmentedPhy` (from [`augmented_phy`](@ref)) or a Newick string;
`y` is the length-`p` trait vector in tip order. When `profile_mu` (default),
`μ` is profiled out by generalised least squares at every evaluation and only
`(σ²_phy, σ²_eps)` are optimised; otherwise all three are optimised jointly.
Variances are optimised on the log scale (kept strictly positive). The L-BFGS
gradient is finite-difference (CHOLMOD blocks forward-mode AD), which is still
O(p) per gradient.

A single exact gradient/likelihood evaluation scales linearly in the number of
species `p` (≈0.8 ms at p=10,000), where dense phylogenetic GLLVMs cap near
`p ≈ 500`.
"""
function fit_phylo_gaussian(phy::AugmentedPhy, y::AbstractVector;
        profile_mu::Bool = true,
        μ0::Real = mean(y),
        logσ²phy0::Real = log(var(y) / 2),
        logσ²eps0::Real = log(var(y) / 2),
        g_tol::Real = 1e-5, iterations::Integer = 500)
    p = phy.n_leaves
    length(y) == p ||
        throw(DimensionMismatch("length(y) = $(length(y)) ≠ number of tips $p"))
    yf = collect(float.(y))
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    opts = Optim.Options(g_tol = g_tol, iterations = iterations)

    if profile_mu
        # θ = (log σ²_phy, log σ²_eps); μ profiled at every evaluation.
        function negll2(θ)
            (all(isfinite, θ) && abs(θ[1]) < 50 && abs(θ[2]) < 50) || return _PHYLO_PENALTY
            σ²_phy = exp(θ[1]); σ²_eps = exp(θ[2])
            st = build_node_perspecies(phy, fill(sqrt(σ²_phy), p), σ²_eps)
            v = _phylo_negll(st, yf, _phylo_profile_mu(st, yf))
            return isfinite(v) ? v : _PHYLO_PENALTY
        end
        res = Optim.optimize(negll2, [float(logσ²phy0), float(logσ²eps0)], ls, opts;
                             autodiff = :finite)
        θ̂ = Optim.minimizer(res)
        σ²_phy = exp(θ̂[1]); σ²_eps = exp(θ̂[2])
        st = build_node_perspecies(phy, fill(sqrt(σ²_phy), p), σ²_eps)
        μ̂ = _phylo_profile_mu(st, yf)
        return PhyloGaussianFit(μ̂, σ²_phy, σ²_eps, Optim.minimum(res),
                                Optim.converged(res), Optim.iterations(res))
    else
        # θ = (μ, log σ²_phy, log σ²_eps); all three jointly.
        function negll3(θ)
            (all(isfinite, θ) && abs(θ[2]) < 50 && abs(θ[3]) < 50) || return _PHYLO_PENALTY
            μ = θ[1]; σ²_phy = exp(θ[2]); σ²_eps = exp(θ[3])
            st = build_node_perspecies(phy, fill(sqrt(σ²_phy), p), σ²_eps)
            v = _phylo_negll(st, yf, μ)
            return isfinite(v) ? v : _PHYLO_PENALTY
        end
        res = Optim.optimize(negll3, [float(μ0), float(logσ²phy0), float(logσ²eps0)],
                             ls, opts; autodiff = :finite)
        θ̂ = Optim.minimizer(res)
        return PhyloGaussianFit(θ̂[1], exp(θ̂[2]), exp(θ̂[3]), Optim.minimum(res),
                                Optim.converged(res), Optim.iterations(res))
    end
end

fit_phylo_gaussian(newick::AbstractString, y::AbstractVector; kwargs...) =
    fit_phylo_gaussian(augmented_phy(newick), y; kwargs...)
