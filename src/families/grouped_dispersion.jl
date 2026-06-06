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

# ===========================================================================
# Beta family — grouped / species-specific precision φ (gllvm's disp.group with
# disp.formula = NULL). Each species t carries its own precision φ_{g(t)}, so the
# Var = μ(1−μ)/(1+φ) overdispersion can vary across species (or groups). With
# G = 1 this reduces EXACTLY to the shared-precision Beta fit. The precision φ is
# carried in the family marker `Beta(φ, ·)` — only its `α` field is read as φ.
# This mirrors the NB grouped path above; the shared Beta hot path (beta.jl) is
# left untouched.
# ===========================================================================

# Per-site Laplace log-marginal with per-species Beta precision markers `fams`.
function _beta_grouped_loglik_site(fams::AbstractVector, y::AbstractVector, n::AbstractVector,
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
    beta_grouped_marginal_loglik_laplace(Y, Λ, β, φvec; link=LogitLink(), mask=nothing,
                                         offset=nothing, kwargs...) -> Float64

Total Laplace log-marginal of a Beta GLLVM with **per-species** precision `φvec`
(length p; `Var_t = μ_t(1−μ_t)/(1+φvec[t])`). `Y` is the p×n matrix of proportions
in (0,1); `Λ` p×K; `β` length-p. With a constant `φvec = fill(φ, p)` this equals the
shared-precision [`beta_marginal_loglik_laplace`](@ref) to machine precision.
"""
function beta_grouped_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, φvec::AbstractVector; link::Link = LogitLink(),
        mask = nothing, offset = nothing, kwargs...)
    p = size(Λ, 1)
    length(φvec) == p || throw(ArgumentError("length(φvec)=$(length(φvec)) must equal p=$p"))
    N = ones(Int, size(Y))
    fams = [Beta(float(φvec[t]), 1.0) for t in 1:p]
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        mi = mask   === nothing ? nothing : view(mask, :, i)
        oi = offset === nothing ? nothing : view(offset, :, i)
        acc += _beta_grouped_loglik_site(fams, view(Y, :, i), view(N, :, i), Λ, β, link;
                                         mask = mi, offset = oi, kwargs...)
    end
    return acc
end

"""
    BetaGroupedFit

Result of [`fit_beta_gllvm_grouped`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the per-group precision vector `φ` (length G), the species→group map `group`
(length p), the `link`, the maximised Laplace `loglik`, `converged`, and
`iterations`. The per-species precision is `φ[group[t]]`.
"""
struct BetaGroupedFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    φ::Vector{Float64}
    group::Vector{Int}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::BetaGroupedFit)
    p, K = size(f.Λ)
    print(io, "BetaGroupedFit(p=", p, ", K=", K, ", G=", length(f.φ),
          ", φ=", round.(f.φ; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_beta_gllvm_grouped(Y; K, group, link=LogitLink(), mask=nothing, offset=nothing, …) -> BetaGroupedFit

Fit a Beta GLLVM with grouped / species-specific precision (gllvm's `disp.group`):
species `t` shares precision `φ[group[t]]`. `group` is a length-p vector of group
ids (relabelled to `1..G` internally; default `1:p` = per-species). L-BFGS over
`[β; vec(Λ); log φ_1 … log φ_G]`; finite-difference gradient; warm start from
empirical logit-mean intercepts + SVD loadings + a moderate per-group `φ₀`. With one
group this matches [`fit_beta_gllvm`](@ref).
"""
function fit_beta_gllvm_grouped(Y::AbstractMatrix; K::Integer,
        group::AbstractVector{<:Integer} = collect(1:size(Y, 1)),
        link::Link = LogitLink(), mask = nothing, offset = nothing,
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
    Yc  = _sanitize_missing(Y, 0.5)
    Zemp = [linkfun(link, clamp(float(Yc[t, i]), 1e-6, 1 - 1e-6)) for t in 1:p, i in 1:n]
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
        φg = exp.(θ[(p + rr + 1):(p + rr + G)])
        φvec = [φg[gidx[t]] for t in 1:p]
        v = try
            -beta_grouped_marginal_loglik_laplace(Yc, Λ, β, φvec; link = link, mask = msk,
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
    φ̂g = exp.(θ̂[(p + rr + 1):(p + rr + G)])
    return BetaGroupedFit(β̂, Λ̂, φ̂g, gidx, link, -Optim.minimum(res),
                          Optim.converged(res), Optim.iterations(res))
end

# ===========================================================================
# Gamma family — grouped / species-specific shape α (gllvm's disp.group with
# disp.formula = NULL). Each species t carries its own shape α_{g(t)}, so the
# Var = μ²/α overdispersion can vary across species (or groups). With G = 1 this
# reduces EXACTLY to the shared-shape Gamma fit. The shape α is carried in the
# family marker `Gamma(α, ·)` — only its `α` field is read. This mirrors the NB
# grouped path above; the shared Gamma hot path (gamma.jl) is left untouched.
# ===========================================================================

# Per-site Laplace log-marginal with per-species Gamma shape markers `fams`.
function _gamma_grouped_loglik_site(fams::AbstractVector, y::AbstractVector, n::AbstractVector,
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
    gamma_grouped_marginal_loglik_laplace(Y, Λ, β, αvec; link=LogLink(), mask=nothing,
                                          offset=nothing, kwargs...) -> Float64

Total Laplace log-marginal of a Gamma GLLVM with **per-species** shape `αvec`
(length p; `Var_t = μ_t²/αvec[t]`). `Y` is the p×n matrix of positive reals; `Λ`
p×K; `β` length-p. With a constant `αvec = fill(α, p)` this equals the shared-shape
[`gamma_marginal_loglik_laplace`](@ref) to machine precision.
"""
function gamma_grouped_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, αvec::AbstractVector; link::Link = LogLink(),
        mask = nothing, offset = nothing, kwargs...)
    p = size(Λ, 1)
    length(αvec) == p || throw(ArgumentError("length(αvec)=$(length(αvec)) must equal p=$p"))
    N = ones(Int, size(Y))
    fams = [Gamma(float(αvec[t]), 1.0) for t in 1:p]
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        mi = mask   === nothing ? nothing : view(mask, :, i)
        oi = offset === nothing ? nothing : view(offset, :, i)
        acc += _gamma_grouped_loglik_site(fams, view(Y, :, i), view(N, :, i), Λ, β, link;
                                          mask = mi, offset = oi, kwargs...)
    end
    return acc
end

"""
    GammaGroupedFit

Result of [`fit_gamma_gllvm_grouped`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the per-group shape vector `α` (length G), the species→group map `group`
(length p), the `link`, the maximised Laplace `loglik`, `converged`, and
`iterations`. The per-species shape is `α[group[t]]`.
"""
struct GammaGroupedFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    α::Vector{Float64}
    group::Vector{Int}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::GammaGroupedFit)
    p, K = size(f.Λ)
    print(io, "GammaGroupedFit(p=", p, ", K=", K, ", G=", length(f.α),
          ", α=", round.(f.α; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_gamma_gllvm_grouped(Y; K, group, link=LogLink(), mask=nothing, offset=nothing, …) -> GammaGroupedFit

Fit a Gamma GLLVM with grouped / species-specific shape (gllvm's `disp.group`):
species `t` shares shape `α[group[t]]`. `group` is a length-p vector of group ids
(relabelled to `1..G` internally; default `1:p` = per-species). L-BFGS over
`[β; vec(Λ); log α_1 … log α_G]`; finite-difference gradient; warm start from log
row-means as intercepts + SVD of row-centred log-Y as loadings + a moderate per-group
`α₀`. With one group this matches [`fit_gamma_gllvm`](@ref).
"""
function fit_gamma_gllvm_grouped(Y::AbstractMatrix; K::Integer,
        group::AbstractVector{<:Integer} = collect(1:size(Y, 1)),
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
    Yc  = _sanitize_missing(Y, 1.0)
    Zemp = log.(max.(Yc, 1e-6))
    offset === nothing || (Zemp .-= offset)
    _mask_warmstart!(Zemp, msk)
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0
    F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    θ0 = vcat(β0, pack_lambda(Λ0), fill(log(2.0), G))

    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        αg = exp.(θ[(p + rr + 1):(p + rr + G)])
        αvec = [αg[gidx[t]] for t in 1:p]
        v = try
            -gamma_grouped_marginal_loglik_laplace(Yc, Λ, β, αvec; link = link, mask = msk,
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
    α̂g = exp.(θ̂[(p + rr + 1):(p + rr + G)])
    return GammaGroupedFit(β̂, Λ̂, α̂g, gidx, link, -Optim.minimum(res),
                           Optim.converged(res), Optim.iterations(res))
end

# ===========================================================================
# NB1 family — grouped / species-specific dispersion φ (gllvm's disp.group with
# disp.formula = NULL, `family = negative.binomial1`). Each species t carries its
# own LINEAR-variance dispersion φ_{g(t)}, so the overdispersion Var = μ(1+φ) can
# vary across species (or groups). With G = 1 this reduces EXACTLY to the
# shared-dispersion NB1 fit. The dispersion is carried in the family marker
# `NB1(φ)`. This mirrors the NB2 grouped path above; the shared NB1 hot path
# (negbin1.jl) is left untouched.
# ===========================================================================

# Per-site Laplace log-marginal with per-species NB1 dispersion markers `fams`.
function _nb1_grouped_loglik_site(fams::AbstractVector, y::AbstractVector, n::AbstractVector,
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
    nb1_grouped_marginal_loglik_laplace(Y, Λ, β, φvec; link=LogLink(), mask=nothing,
                                        offset=nothing, kwargs...) -> Float64

Total Laplace log-marginal of a negative-binomial type-1 (NB1) GLLVM with
**per-species** dispersion `φvec` (length p; linear variance `Var_t = μ_t(1+φvec[t])`).
`Y` is the p×n integer count matrix; `Λ` p×K; `β` length-p. With a constant
`φvec = fill(φ, p)` this equals the shared-dispersion
[`nb1_marginal_loglik_laplace`](@ref) to machine precision.
"""
function nb1_grouped_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, φvec::AbstractVector; link::Link = LogLink(),
        mask = nothing, offset = nothing, kwargs...)
    p = size(Λ, 1)
    length(φvec) == p || throw(ArgumentError("length(φvec)=$(length(φvec)) must equal p=$p"))
    N = ones(Int, size(Y))
    fams = [NB1(float(φvec[t])) for t in 1:p]
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        mi = mask   === nothing ? nothing : view(mask, :, i)
        oi = offset === nothing ? nothing : view(offset, :, i)
        acc += _nb1_grouped_loglik_site(fams, view(Y, :, i), view(N, :, i), Λ, β, link;
                                        mask = mi, offset = oi, kwargs...)
    end
    return acc
end

"""
    NB1GroupedFit

Result of [`fit_nb1_gllvm_grouped`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the per-group dispersion vector `φ` (length G), the species→group map `group`
(length p), the `link`, the maximised Laplace `loglik`, `converged`, and
`iterations`. The per-species dispersion is `φ[group[t]]` (linear variance
`Var_t = μ_t(1+φ[group[t]])`).
"""
struct NB1GroupedFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    φ::Vector{Float64}
    group::Vector{Int}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::NB1GroupedFit)
    p, K = size(f.Λ)
    print(io, "NB1GroupedFit(p=", p, ", K=", K, ", G=", length(f.φ),
          ", φ=", round.(f.φ; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_nb1_gllvm_grouped(Y; K, group, link=LogLink(), mask=nothing, offset=nothing, …) -> NB1GroupedFit

Fit a negative-binomial type-1 (NB1) GLLVM with grouped / species-specific
dispersion (gllvm's `disp.group`): species `t` shares dispersion `φ[group[t]]`
(linear variance `Var_t = μ_t(1+φ[group[t]])`). `group` is a length-p vector of
group ids (relabelled to `1..G` internally; default `1:p` = per-species). L-BFGS over
`[β; vec(Λ); log φ_1 … log φ_G]`; finite-difference gradient; warm start from
empirical log-mean intercepts + SVD loadings + a moderate per-group `φ₀`. With one
group this matches [`fit_nb1_gllvm`](@ref).
"""
function fit_nb1_gllvm_grouped(Y::AbstractMatrix; K::Integer,
        group::AbstractVector{<:Integer} = collect(1:size(Y, 1)),
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
    θ0 = vcat(β0, pack_lambda(Λ0), fill(log(1.0), G))

    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        φg = exp.(θ[(p + rr + 1):(p + rr + G)])
        φvec = [φg[gidx[t]] for t in 1:p]
        v = try
            -nb1_grouped_marginal_loglik_laplace(Yc, Λ, β, φvec; link = link, mask = msk,
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
    φ̂g = exp.(θ̂[(p + rr + 1):(p + rr + G)])
    return NB1GroupedFit(β̂, Λ̂, φ̂g, gidx, link, -Optim.minimum(res),
                         Optim.converged(res), Optim.iterations(res))
end

# ===========================================================================
# Tweedie family — grouped / species-specific dispersion φ (gllvm's disp.group with
# disp.formula = NULL). Each species t carries its own dispersion φ_{g(t)}, so the
# Var = φ μ^power overdispersion can vary across species (or groups). The POWER
# p ∈ (1,2) is SHARED (a single global power, matching gllvm — `disp.formula`
# governs the dispersion only). With G = 1 this reduces EXACTLY to the
# shared-dispersion Tweedie fit. The dispersion φ and shared power are carried in
# the family marker `TweedieED(φ, power)`. This mirrors the NB2 grouped path above;
# the shared Tweedie hot path (tweedie.jl) is left untouched.
# ===========================================================================

# Per-site Laplace log-marginal with per-species Tweedie dispersion markers `fams`.
function _tweedie_grouped_loglik_site(fams::AbstractVector, y::AbstractVector, n::AbstractVector,
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
    tweedie_grouped_marginal_loglik_laplace(Y, Λ, β, φvec, power; link=LogLink(),
                                            mask=nothing, offset=nothing, kwargs...) -> Float64

Total Laplace log-marginal of a Tweedie GLLVM with **per-species** dispersion `φvec`
(length p) and a single SHARED `power` ∈ (1,2) (`Var_t = φvec[t]·μ_t^power`). `Y` is
the p×n matrix of non-negative reals (point mass at 0 allowed); `Λ` p×K; `β` length-p.
With a constant `φvec = fill(φ, p)` (same `power`) this equals the shared-dispersion
[`tweedie_marginal_loglik_laplace`](@ref) to machine precision.
"""
function tweedie_grouped_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, φvec::AbstractVector, power::Real; link::Link = LogLink(),
        mask = nothing, offset = nothing, kwargs...)
    p = size(Λ, 1)
    length(φvec) == p || throw(ArgumentError("length(φvec)=$(length(φvec)) must equal p=$p"))
    N = ones(Int, size(Y))
    fams = [TweedieED(float(φvec[t]), float(power)) for t in 1:p]
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        mi = mask   === nothing ? nothing : view(mask, :, i)
        oi = offset === nothing ? nothing : view(offset, :, i)
        acc += _tweedie_grouped_loglik_site(fams, view(Y, :, i), view(N, :, i), Λ, β, link;
                                            mask = mi, offset = oi, kwargs...)
    end
    return acc
end

"""
    TweedieGroupedFit

Result of [`fit_tweedie_gllvm_grouped`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the per-group dispersion vector `φ` (length G), the SHARED `power` ∈ (1,2), the
species→group map `group` (length p), the `link`, the maximised Laplace `loglik`,
`converged`, and `iterations`. The per-species dispersion is `φ[group[t]]`
(`Var_t = φ[group[t]]·μ_t^power`).
"""
struct TweedieGroupedFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    φ::Vector{Float64}
    power::Float64
    group::Vector{Int}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::TweedieGroupedFit)
    p, K = size(f.Λ)
    print(io, "TweedieGroupedFit(p=", p, ", K=", K, ", G=", length(f.φ),
          ", φ=", round.(f.φ; sigdigits = 4),
          ", power=", round(f.power; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_tweedie_gllvm_grouped(Y; K, group, power_init=1.5, link=LogLink(), …) -> TweedieGroupedFit

Fit a Tweedie GLLVM with grouped / species-specific dispersion (gllvm's `disp.group`):
species `t` shares dispersion `φ[group[t]]`, with a single SHARED power `p ∈ (1,2)`
(matching gllvm — `disp.formula` governs the dispersion only). `group` is a length-p
vector of group ids (relabelled to `1..G` internally; default `1:p` = per-species).
L-BFGS over `[β; vec(Λ); log φ_1 … log φ_G; ξ]`, the power mapped to `(1,2)` by
`p = 1 + 1/(1+exp(-ξ))` (so `ξ = 0 ⇒ p = 1.5`) — the SAME transform as the scalar
[`fit_tweedie_gllvm`](@ref). Finite-difference gradient; warm start from log row-means
intercepts + SVD loadings + a moderate per-group `φ₀` + `ξ₀ = logit(power_init − 1)`.
With one group this matches [`fit_tweedie_gllvm`](@ref).
"""
function fit_tweedie_gllvm_grouped(Y::AbstractMatrix{<:Real}; K::Integer,
        group::AbstractVector{<:Integer} = collect(1:size(Y, 1)),
        power_init::Real = 1.5, link::Link = LogLink(), mask = nothing, offset = nothing,
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
    Yc  = _sanitize_missing(Y, 1e-6)
    Zemp = log.(max.(Yc, 1e-6))
    offset === nothing || (Zemp .-= offset)
    _mask_warmstart!(Zemp, msk)
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0
    F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    ξ0 = log((float(power_init) - 1.0) / (2.0 - float(power_init)))   # logit(power_init - 1)
    θ0 = vcat(β0, pack_lambda(Λ0), fill(log(1.0), G), ξ0)

    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        φg = exp.(θ[(p + rr + 1):(p + rr + G)])
        φvec = [φg[gidx[t]] for t in 1:p]
        ξ = θ[p + rr + G + 1]
        pw = 1.0 + 1.0 / (1.0 + exp(-ξ))
        v = try
            -tweedie_grouped_marginal_loglik_laplace(Yc, Λ, β, φvec, pw; link = link,
                                                     mask = msk, offset = offset,
                                                     maxiter = newton_maxiter,
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
    φ̂g = exp.(θ̂[(p + rr + 1):(p + rr + G)])
    p̂ = 1.0 + 1.0 / (1.0 + exp(-θ̂[p + rr + G + 1]))
    return TweedieGroupedFit(β̂, Λ̂, φ̂g, p̂, gidx, link, -Optim.minimum(res),
                             Optim.converged(res), Optim.iterations(res))
end
