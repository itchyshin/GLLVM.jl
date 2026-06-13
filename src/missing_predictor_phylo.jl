# Phylogenetic missing-predictor FIML for the Gaussian GLLVM — the mi() axis,
# design Phase 3 (the high-value evolutionary feature).
#
# A species-level continuous predictor x (length p, one value per species/row,
# possibly `missing`) carries a phylogenetic prior x ~ N(α 1, σ_x² A) (A the
# p×p phylo correlation) and enters the response with a single slope b_x and a
# global intercept a:
#   y[t,s] = a + b_x x_t + (Λ η_s + ε_s)_t,   η_s ~ N(0,I_K), ε_s ~ N(0,σ_eps²I)
# (A *global* intercept, not per-species: a per-species intercept would confound
# with the per-species predictor x_t and leave b_x unidentified. The species
# predictor + phylo prior are what explain species-level means.)
#
# Missing x_t are integrated out in CLOSED FORM. Because x is a latent p-vector
# shared across all n sites, the marginal factorises as
#   log p(Y, x_o) = log N(x_o; α1_o, σ_x² A_oo)              (the observed prior)
#                 + log N(vec Y; mean, I_n⊗Σ_R + J_n⊗(b_x² Ṽ))
# with Σ_R = Λ Λᵀ + σ_eps² I, x̃ = x_o on observed coords and the conditional
# mean m_{m|o} on missing coords, Ṽ embedding V_{m|o} = σ_x²(A_mm −
# A_mo A_oo⁻¹ A_om) on the missing coords. The J_n⊗B block uses the rank
# identity logdet = (n−1) logdet Σ_R + logdet(Σ_R + nB), quad = Σ_s r_sᵀΣ_R⁻¹r_s
# − n r̄ᵀΣ_R⁻¹r̄ + n r̄ᵀ(Σ_R+nB)⁻¹r̄. (Validated vs a brute-force joint Gaussian
# to machine precision.)
#
# Borrows phylogenetic information across related species — model-based FIML,
# NOT impute-then-analyse. b_x and σ_x are identified by the observed species.
# Reference: gllvmTMB mi() Phase 3; the design's phylo-covariate model.

using LinearAlgebra

function _mi_phylo_precompute(A::AbstractMatrix, obs::AbstractVector{<:Integer},
                             mis::AbstractVector{<:Integer})
    Aoo = A[obs, obs]
    AooInv = inv(Aoo)
    logdetAoo = logdet(Aoo)
    if isempty(mis)
        Creg = zeros(0, length(obs))
        Acond = zeros(0, 0)
    else
        Amo = A[mis, obs]
        Aom = A[obs, mis]
        Amm = A[mis, mis]
        Creg = Amo * AooInv
        Acond = Matrix(Symmetric(Amm - Creg * Aom))
    end
    return (AooInv = AooInv, logdetAoo = logdetAoo, Creg = Creg, Acond = Acond)
end

# Param layout: [a (1), b_x (1), α (1), log_σx (1), log_σeps (1), vec(Λ) (p*K)]
function _mi_phylo_nll(params, y, xo, obs, mis, pc, p::Int, n::Int, K::Int)
    T = eltype(params)
    a = params[1]
    b_x = params[2]
    α = params[3]
    log_σx = params[4]
    σx2 = exp(2 * log_σx)
    σe2 = exp(2 * params[5])
    Λ = reshape(@view(params[6:(5 + p * K)]), p, K)

    rxo = xo .- α
    po = length(obs)
    lpxo = -0.5 * (po * log(2π) + po * 2 * log_σx + pc.logdetAoo +
                   dot(rxo, pc.AooInv * rxo) / σx2)

    xtil = Vector{T}(undef, p)
    xtil[obs] = xo
    B = zeros(T, p, p)
    if !isempty(mis)
        xtil[mis] = α .+ pc.Creg * rxo
        @views B[mis, mis] = (b_x^2 * σx2) .* pc.Acond
    end

    mean_s = a .+ b_x .* xtil
    Σ_R = Λ * Λ' + (σe2 + 1e-8) * I   # tiny floor guards cholesky if σ_eps underflows
    R = y .- mean_s
    rbar = vec(sum(R, dims = 2)) ./ n
    cholA = cholesky(Symmetric(Σ_R))
    cholAnB = cholesky(Symmetric(Σ_R .+ n .* B))
    logdetC = (n - 1) * logdet(cholA) + logdet(cholAnB)

    quad = zero(T)
    @inbounds for s in 1:n
        rs = @view R[:, s]
        quad += dot(rs, cholA \ rs)
    end
    quad += -n * dot(rbar, cholA \ rbar) + n * dot(rbar, cholAnB \ rbar)
    lpY = -0.5 * (p * n * log(2π) + logdetC + quad)
    return -(lpxo + lpY)
end

"""
    fit_gaussian_mi_phylo(y, x, A; K, g_tol=1e-8, iterations=1000) -> NamedTuple

Fit a Gaussian GLLVM with a **species-level** continuous predictor `x` (length
`p`, one value per species/row of `y`, may contain `missing`/`NaN`) under a
phylogenetic covariate model `x ~ N(α 1, σ_x² A)`, where `A` is the `p × p`
phylogenetic correlation matrix. The missing `x_t` are integrated out by
full-information maximum likelihood, borrowing phylogenetic information across
related species (model-based, not impute-then-analyse).

`y` is `p × n` (species × sites). `x` enters the response mean with a global
intercept and a single slope: `y[t,s] = a + b_x x_t + Λ η_s + ε_s`.

Returns a NamedTuple with `b_x`, global intercept `a`, covariate-model params
`α`, `σ_x`, residual `σ_eps`, loadings `Λ` (`p × K`), the EBLUPs `eblup_x`
(length `p`; observed values at observed species, `E[x_t | Y, x_obs]` at missing
species), `logLik`, `converged`, and `n_missing`.

Faithful to gllvmTMB's `mi()` phylogenetic predictor (design Phase 3). Closed
form, exact for the all-Gaussian case — no Laplace.
"""
function fit_gaussian_mi_phylo(y::AbstractMatrix, x::AbstractVector,
                               A::AbstractMatrix; K::Integer,
                               g_tol::Real = 1e-8, iterations::Integer = 1000)
    p, n = size(y)
    length(x) == p ||
        throw(ArgumentError("length(x) = $(length(x)) must equal p = $p (x is species-level)."))
    (size(A, 1) == p && size(A, 2) == p) ||
        throw(ArgumentError("A must be p × p = $p × $p; got $(size(A))."))
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1."))

    isobs = [!(ismissing(xi) || (xi isa Real && isnan(xi))) for xi in x]
    obs = findall(isobs)
    mis = findall(!, isobs)
    length(obs) ≥ 1 || throw(ArgumentError("x has no observed values."))
    xo = Float64[Float64(x[i]) for i in obs]
    pc = _mi_phylo_precompute(Float64.(A), obs, mis)

    # warm start
    ȳ = vec(Statistics.mean(y, dims = 2))
    α0 = Statistics.mean(xo)
    σx0 = max(Statistics.std(xo), 1e-2)
    xfill = fill(α0, p)
    xfill[obs] = xo
    xc = xo .- α0
    b_x0 = sum(xc .* (ȳ[obs] .- Statistics.mean(ȳ[obs]))) / max(sum(abs2, xc), 1e-8)
    a0 = Statistics.mean(ȳ) - b_x0 * Statistics.mean(xfill)
    Yc = y .- (a0 .+ b_x0 .* xfill)
    C = Symmetric((Yc * Yc') ./ n)
    E = eigen(C)
    idx = sortperm(E.values, rev = true)[1:K]
    Λ0 = E.vectors[:, idx] .* sqrt.(max.(E.values[idx] .- 1e-2, 1e-2))'
    σe0 = sqrt(max(Statistics.mean(E.values[1:max(1, p - K)]), 1e-2))

    params0 = vcat(a0, b_x0, α0, log(σx0), log(σe0), vec(Λ0))
    nll(θ) = _mi_phylo_nll(θ, y, xo, obs, mis, pc, p, n, K)

    opts = Optim.Options(g_tol = g_tol, iterations = iterations)
    res = Optim.optimize(nll, params0, Optim.LBFGS(), opts; autodiff = :forward)
    θ = Optim.minimizer(res)

    a = θ[1]
    b_x = θ[2]
    α = θ[3]
    σ_x = exp(θ[4])
    σ_eps = exp(θ[5])
    Λ = reshape(θ[6:(5 + p * K)], p, K)

    # EBLUPs: posterior of the missing x given Y and the observed x.
    eblup = Vector{Float64}(undef, p)
    eblup[obs] = xo
    if !isempty(mis)
        Σ_R = Λ * Λ' + σ_eps^2 * I
        Σ_Rinv = inv(Symmetric(Σ_R))
        xtil_o = zeros(p)
        xtil_o[obs] = xo
        U = y .- (a .+ b_x .* xtil_o)
        Su = vec(sum(U, dims = 2))
        Vmo = σ_x^2 .* pc.Acond
        m_mo = α .+ pc.Creg * (xo .- α)
        prec = inv(Vmo) + n * b_x^2 .* Σ_Rinv[mis, mis]
        rhs = (Vmo \ m_mo) .+ b_x .* (Σ_Rinv * Su)[mis]
        eblup[mis] = prec \ rhs
    end

    return (b_x = b_x, a = a, α = α, σ_x = σ_x, σ_eps = σ_eps, Λ = Λ,
            eblup_x = eblup, logLik = -Optim.minimum(res),
            converged = Optim.converged(res), n_missing = length(mis))
end
