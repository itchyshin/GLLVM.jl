# Grouped / species-specific dispersion for the negative binomial (NB2) — gllvm's
# `disp.group`. Each species t carries its own dispersion r_{g(t)} for a group
# assignment g: 1..p → 1..G, so overdispersion can vary across species (or groups
# of species) instead of one shared r. With G = 1 (all species in one group) this
# reduces EXACTLY to the shared-dispersion NB2 fit.
#
# Implementation note: the generic Laplace core (families/laplace.jl) broadcasts a
# SINGLE family marker over species (`Ref(family)`). Per-species dispersion instead
# needs a per-species marker, so this is a small isolated parallel of the core's
# site routine that broadcasts a length-p VECTOR of `NegativeBinomial(r_t)` markers
# — reusing the exact same NB `_glm_score`/`_glm_weight`/`_glm_logpdf`/`_clamp_mu`
# pieces. The shared families' hot path is left untouched.

# Per-site Laplace log-marginal with per-species NB dispersion markers `fams`.
function _nb_grouped_loglik_site(fams::AbstractVector, y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        mask = nothing, offset = nothing, maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    off = offset === nothing ? false : offset
    z = zeros(K)
    local A
    for _ in 1:maxiter
        η  = _clamp_eta.(β .+ off .+ Λ * z)
        μ  = _clamp_mu.(fams, linkinv.(Ref(link), η))
        me = mu_eta.(Ref(link), η)
        s  = _glm_score.(fams, μ, n, me, y)
        W  = _glm_weight.(fams, μ, n, me)
        if mask !== nothing
            s = ifelse.(mask, s, 0.0)
            W = ifelse.(mask, W, 0.0)
        end
        A  = Symmetric(Λ' * (W .* Λ) + I)
        Δ  = _safe_solve(A, Λ' * s .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break
        z  = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    η  = _clamp_eta.(β .+ off .+ Λ * z)
    μ  = _clamp_mu.(fams, linkinv.(Ref(link), η))
    me = mu_eta.(Ref(link), η)
    W  = _glm_weight.(fams, μ, n, me)
    if mask !== nothing
        W = ifelse.(mask, W, 0.0)
    end
    A  = Symmetric(Λ' * (W .* Λ) + I)
    ℓ = 0.0
    @inbounds for t in 1:p
        (mask === nothing || mask[t]) || continue
        ℓ += _glm_logpdf(fams[t], μ[t], n[t], y[t])
    end
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

"""
    nb_grouped_marginal_loglik_laplace(Y, Λ, β, rvec; link=LogLink(), mask=nothing,
                                       offset=nothing, kwargs...) -> Float64

Total Laplace log-marginal of a negative-binomial GLLVM with **per-species**
dispersion `rvec` (length p; `Var_t = μ_t + μ_t²/rvec[t]`). `Y` is the p×n integer
count matrix; `Λ` p×K; `β` length-p. With a constant `rvec = fill(r, p)` this equals
the shared-dispersion [`nb_marginal_loglik_laplace`](@ref) to machine precision.
"""
function nb_grouped_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, rvec::AbstractVector; link::Link = LogLink(),
        mask = nothing, offset = nothing, kwargs...)
    p = size(Λ, 1)
    length(rvec) == p || throw(ArgumentError("length(rvec)=$(length(rvec)) must equal p=$p"))
    N = ones(Int, size(Y))
    fams = [NegativeBinomial(float(rvec[t]), 0.5) for t in 1:p]
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        mi = mask   === nothing ? nothing : view(mask, :, i)
        oi = offset === nothing ? nothing : view(offset, :, i)
        acc += _nb_grouped_loglik_site(fams, view(Y, :, i), view(N, :, i), Λ, β, link;
                                       mask = mi, offset = oi, kwargs...)
    end
    return acc
end

"""
    NBGroupedFit

Result of [`fit_nb_gllvm_grouped`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the per-group dispersion vector `r_group` (length G), the species→group map
`group` (length p), the `link`, the maximised Laplace `loglik`, `converged`, and
`iterations`. The per-species dispersion is `r_group[group[t]]`.
"""
struct NBGroupedFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    r_group::Vector{Float64}
    group::Vector{Int}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::NBGroupedFit)
    p, K = size(f.Λ)
    print(io, "NBGroupedFit(p=", p, ", K=", K, ", G=", length(f.r_group),
          ", r_group=", round.(f.r_group; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_nb_gllvm_grouped(Y; K, group, link=LogLink(), mask=nothing, offset=nothing, …) -> NBGroupedFit

Fit a negative-binomial GLLVM with grouped / species-specific dispersion (gllvm's
`disp.group`): species `t` shares dispersion `r_group[group[t]]`. `group` is a
length-p vector of group ids (relabelled to `1..G` internally). L-BFGS over
`[β; vec(Λ); log r_1 … log r_G]`; finite-difference gradient; warm start from
empirical log-means + SVD loadings + a moderate per-group `r₀`. With one group this
matches [`fit_nb_gllvm`](@ref).
"""
function fit_nb_gllvm_grouped(Y::AbstractMatrix; K::Integer, group::AbstractVector{<:Integer},
        link::Link = LogLink(), mask = nothing, offset = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    length(group) == p || throw(ArgumentError("length(group)=$(length(group)) must equal p=$p"))
    rr = rr_theta_len(p, K)
    # relabel groups to 1..G, build species→group index
    labels = sort(unique(group))
    G = length(labels)
    gidx = [findfirst(==(group[t]), labels) for t in 1:p]

    msk = _resolve_obs_mask(mask, Y)
    Yc = Integer.(_sanitize_missing(Y, 0))
    Zemp = [linkfun(link, max(Yc[t, i] + 0.5, 1e-4)) for t in 1:p, i in 1:n]
    offset === nothing || (Zemp .-= offset)
    _mask_warmstart!(Zemp, msk)
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0
    F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    θ0 = vcat(β0, pack_lambda(Λ0), fill(log(10.0), G))

    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        rg = exp.(θ[(p + rr + 1):(p + rr + G)])
        rvec = [rg[gidx[t]] for t in 1:p]
        v = try
            -nb_grouped_marginal_loglik_laplace(Yc, Λ, β, rvec; link = link, mask = msk,
                                                offset = offset, maxiter = newton_maxiter,
                                                tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(negll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :finite)
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    r̂g = exp.(θ̂[(p + rr + 1):(p + rr + G)])
    return NBGroupedFit(β̂, Λ̂, r̂g, gidx, link, -Optim.minimum(res),
                        Optim.converged(res), Optim.iterations(res))
end
