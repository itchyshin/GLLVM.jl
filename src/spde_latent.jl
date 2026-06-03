# SPDE / Matérn-GMRF spatial field as a *latent variable* inside a (non-Gaussian)
# multi-species GLLVM — the joint-Laplace path over the spatial GMRF.
#
# Where src/spde_fit.jl fits a single Gaussian response as μ + A·u + ε (one field,
# conjugate, closed-form marginal), this module lets the spatial field carry the
# latent variables of a *multi-species* GLLVM under an arbitrary response family.
#
# Model (p species × M sites; mesh with N nodes):
#
#     u_k ~ N(0, Q⁻¹)            k = 1..K   independent Matérn-GMRF fields on nodes
#     z_·k = A · u_k             site scores of field k          (M-vector)
#     η_{ts} = β_t + (Λ z_s)_t   linear predictor                (p × M)
#     y_{ts} ~ Family(linkinv(η_{ts}))
#
# So the K latent variables are *spatially smooth* across sites (gllvm's
# `corLV = "spatial"`), with smoothness/range set by the sparse SPDE precision
# Q(κ, τ) from spde_precision. As Q → I and A → I the fields become i.i.d.
# N(0, I) per site and the model collapses to the ordinary independent-site GLLVM.
#
# Marginal by joint Laplace over the stacked field U = [u_1 … u_K] ∈ ℝ^{N×K}.
# With prior precision P = I_K ⊗ Q and data log-likelihood ℓ_data(U), let
# φ(U) = ℓ_data(U) − ½ Σ_k u_kᵀ Q u_k and Û = argmax φ. Then
#
#     log p(Y) ≈ ℓ_data(Û) − ½ Σ_k û_kᵀ Q û_k + (K/2)·logdet Q − ½·logdet H,
#
# H = −∇²φ(Û) = (I_K ⊗ Q) + data-Hessian, the data-Hessian block (k,k′) being
# Aᵀ diag_s(Σ_t W_{ts} Λ_{tk} Λ_{tk′}) A with Fisher weights W_{ts} ≥ 0. Both Q and
# H are sparse SPD, so a single sparse (CHOLMOD) Cholesky of each gives the solve
# and the log-determinant. This mirrors the phylogenetic sparse-precision path and
# the INLA-style identities used in spde_fit.jl.
#
# The family pieces (_glm_score / _glm_weight / _glm_logpdf / _clamp_mu) are shared
# with the per-site Laplace core (src/families/laplace.jl); a minimal Normal set is
# added here so the conjugate-Gaussian anchor exercises the *same* code path.
#
# References:
#   - Lindgren, Rue & Lindström 2011 (SPDE ↔ Matérn, JRSSB)
#   - Rue & Held 2005 (GMRFs; sparse-precision Gaussian inference)
#   - Tierney & Kadane 1986 (Laplace approximation for marginals)
#   - Niku et al. 2019 (gllvm; spatially-correlated latent variables)

using LinearAlgebra
using SparseArrays

# --- Normal family pieces for the conjugate-Gaussian anchor ----------------
# Gaussian responses normally use the closed-form marginal (likelihood.jl); the
# generic Laplace core has no Normal methods. We add them here (carrying σ in the
# Distributions `Normal(μ, σ)` marker) so the SPDE-latent Gaussian case runs
# through the identical joint-Laplace machinery — and, since the Laplace
# approximation is exact for a conjugate Gaussian, must reproduce
# `spde_gaussian_marginal_loglik` to machine precision.
_clamp_mu(::Normal, μ) = μ
_glm_score(f::Normal, μ, n, me, y) = (y - μ) * me / f.σ^2
_glm_weight(f::Normal, μ, n, me)   = me^2 / f.σ^2
_glm_logpdf(f::Normal, μ, n, y)    = logpdf(Normal(μ, f.σ), y)

# Assemble the sparse Laplace Hessian H = (I_K ⊗ Q) + data-Hessian at the current
# field. `W` is the p×M matrix of Fisher weights, `Λ` p×K, `A` the M×N projector,
# `Q` the N×N precision. Block (k,k′) = Aᵀ diag_s(Σ_t W_{ts}Λ_{tk}Λ_{tk′}) A
# (+ Q on the diagonal blocks).
function _spde_latent_hessian(Q::AbstractMatrix, A::AbstractMatrix,
        Λ::AbstractMatrix, W::AbstractMatrix)
    N = size(A, 2)
    K = size(Λ, 2)
    if K == 1
        ω = vec((Λ[:, 1] .* Λ[:, 1])' * W)          # length-M site weights
        return Q + A' * Diagonal(ω) * A
    end
    # General K: build the K×K grid of N×N sparse blocks, row-major, then hvcat.
    blocks = Vector{Any}(undef, K * K)
    idx = 0
    for k in 1:K, k′ in 1:K
        idx += 1
        ω = vec((Λ[:, k] .* Λ[:, k′])' * W)
        B = A' * Diagonal(ω) * A
        blocks[idx] = k == k′ ? (Q + B) : B
    end
    return hvcat(ntuple(_ -> K, K), blocks...)
end

"""
    spde_latent_marginal_loglik(family, Y, N, Λ, β, link, A, Q;
                                maxiter=50, tol=1e-9) -> Float64

Joint-Laplace marginal log-likelihood of a GLLVM whose `K = size(Λ, 2)` latent
variables are SPDE/Matérn-GMRF spatial fields on a mesh with `N = size(A, 2)`
nodes. `Y` is the p×M response (species × sites), `N` the matching trial-count
matrix (ones for families without trials), `Λ` the p×K loadings, `β` the length-p
intercepts, `link` a `Link`, `A` the M×N sparse projector (`spde_projector`), and
`Q` the N×N sparse SPD precision (`spde_precision`).

Returns `ℓ_data(Û) − ½Σ_k û_kᵀQû_k + (K/2)logdet Q − ½logdet H`, with the field
mode `Û` found by Fisher-scoring Newton over the stacked GMRF. An infeasible step
(non-SPD `H`) returns `-Inf`.
"""
function spde_latent_marginal_loglik(family, Y::AbstractMatrix, Ntr::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, link::Link,
        A::AbstractMatrix, Q::AbstractMatrix;
        maxiter::Integer = 50, tol::Real = 1e-9)
    p, M = size(Y)
    K = size(Λ, 2)
    Nn = size(A, 2)

    Qs = sparse(Q)
    local cholQ
    try
        cholQ = cholesky(Symmetric(Qs))
    catch
        return -Inf
    end

    U = zeros(Nn, K)

    # Fisher-scoring Newton on φ(U) = ℓ_data(U) − ½ Σ_k u_kᵀ Q u_k.
    for _ in 1:maxiter
        Z  = A * U                                   # M×K site scores
        η  = _clamp_eta.(β .+ Λ * Z')                # p×M
        μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
        me = mu_eta.(Ref(link), η)
        S  = _glm_score.(Ref(family), μ, Ntr, me, Y) # p×M score wrt η
        W  = _glm_weight.(Ref(family), μ, Ntr, me)   # p×M Fisher weight ≥ 0

        Grad = A' * (S' * Λ) - Qs * U                # N×K gradient of φ
        H = _spde_latent_hessian(Qs, A, Λ, W)
        local cholH
        try
            cholH = cholesky(Symmetric(sparse(H)))
        catch
            return -Inf
        end
        Δ = reshape(cholH \ vec(Grad), Nn, K)
        all(isfinite, Δ) || return -Inf
        U .+= Δ
        maximum(abs, Δ) < tol && break
    end

    # Evaluate the Laplace marginal at the mode Û.
    Z  = A * U
    η  = _clamp_eta.(β .+ Λ * Z')
    μ  = _clamp_mu.(Ref(family), linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    W  = _glm_weight.(Ref(family), μ, Ntr, me)

    ℓ_data = 0.0
    @inbounds for s in 1:M, t in 1:p
        ℓ_data += _glm_logpdf(family, μ[t, s], Ntr[t, s], Y[t, s])
    end

    quad = 0.5 * sum(U .* (Qs * U))                  # ½ Σ_k û_kᵀ Q û_k
    H = _spde_latent_hessian(Qs, A, Λ, W)
    local cholH
    try
        cholH = cholesky(Symmetric(sparse(H)))
    catch
        return -Inf
    end

    return ℓ_data - quad + 0.5 * K * logdet(cholQ) - 0.5 * logdet(cholH)
end

# ---------------------------------------------------------------------------
# Fit driver (no-dispersion families: Poisson, Bernoulli/Binomial).
# ---------------------------------------------------------------------------

"""
    SPDELatentFit

Result of [`fit_spde_latent_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the Matérn inverse-range `κ` and precision-scale `τ`, the `link` and
`family`, the maximised joint-Laplace `loglik`, the optimiser `converged` flag and
`iterations`, and the mesh (`nodes`, `tris`) the model was fit on.
"""
struct SPDELatentFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    κ::Float64
    τ::Float64
    link::Link
    family::Any
    loglik::Float64
    converged::Bool
    iterations::Int
    nodes::Any
    tris::Any
end

function Base.show(io::IO, f::SPDELatentFit)
    p, K = size(f.Λ)
    print(io, "SPDELatentFit(p=", p, ", K=", K,
          ", family=", nameof(typeof(f.family)),
          ", κ=", round(f.κ; sigdigits = 4), ", τ=", round(f.τ; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_spde_latent_gllvm(Y, nodes, tris, locs; family=Poisson(), K=1,
                          link=default_link(family), α=2, N=nothing,
                          κ_init=1.0, τ_init=1.0,
                          g_tol=1e-5, iterations=300,
                          newton_maxiter=50, newton_tol=1e-9) -> SPDELatentFit

Fit a spatially-structured GLLVM whose `K` latent variables are SPDE/Matérn-GMRF
fields, by L-BFGS on [`spde_latent_marginal_loglik`](@ref). `Y` is p×M (species ×
sites) observed at the M rows of `locs`, over the triangular mesh (`nodes`,
`tris`). The FEM matrices and the projector `A` are built once; each evaluation
rebuilds the sparse precision `Q = spde_precision(Cdiag, G, exp(logκ), exp(logτ); α)`.

The parameter vector is `θ = [β; pack_lambda(Λ); log κ; log τ]`. Supported for the
no-dispersion families (Poisson, Bernoulli/Binomial); supply trial counts `N`
(p×M) for Binomial. Warm start: empirical link-scale intercepts + an SVD loadings
init; `κ`, `τ` from `κ_init`, `τ_init`.
"""
function fit_spde_latent_gllvm(Y::AbstractMatrix, nodes::AbstractMatrix,
        tris::AbstractMatrix{<:Integer}, locs::AbstractMatrix;
        family = Poisson(), K::Integer = 1,
        link::Link = default_link(family), α::Integer = 2,
        N = nothing, κ_init::Real = 1.0, τ_init::Real = 1.0,
        g_tol::Real = 1e-5, iterations::Integer = 300,
        newton_maxiter::Integer = 50, newton_tol::Real = 1e-9)
    p, M = size(Y)
    rr = rr_theta_len(p, K)

    Cdiag, G = spde_fem(nodes, tris)
    A = spde_projector(nodes, tris, locs)
    Ntr = N === nothing ? ones(eltype(Y), p, M) : N

    # Warm start: empirical link-scale intercepts + SVD loadings (PPCA-like).
    Zemp = [linkfun(link, _ws_mean(family, Y[t, s], Ntr[t, s])) for t in 1:p, s in 1:M]
    β0 = vec(sum(Zemp; dims = 2)) ./ M
    Zc = Zemp .- β0
    F = svd(Zc)
    kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(M))
    end

    θ0 = vcat(β0, pack_lambda(Λ0), log(float(κ_init)), log(float(τ_init)))

    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        κ = exp(θ[p + rr + 1])
        τ = exp(θ[p + rr + 2])
        v = try
            Q = spde_precision(Cdiag, G, κ, τ; α = α)
            -spde_latent_marginal_loglik(family, Y, Ntr, Λ, β, link, A, Q;
                                         maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end

    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(negll, θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :finite)

    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    κ̂ = exp(θ̂[p + rr + 1])
    τ̂ = exp(θ̂[p + rr + 2])

    return SPDELatentFit(β̂, Λ̂, κ̂, τ̂, link, family, -Optim.minimum(res),
                         Optim.converged(res), Optim.iterations(res), nodes, tris)
end

# Domain-safe empirical mean for the link-scale warm start.
_ws_mean(::Poisson, y, n) = max(float(y) + 0.5, 1e-4)
_ws_mean(::Binomial, y, n) = clamp((float(y) + 0.5) / (float(n) + 1.0), 1e-4, 1 - 1e-4)
_ws_mean(::Normal, y, n) = float(y)
_ws_mean(f, y, n) = float(y)
