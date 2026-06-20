# Poisson family pieces for the generic Laplace core (src/families/laplace.jl).
# y_t ~ Poisson(μ_t), μ = linkinv(link, η) (log link ⇒ μ = exp η). E[y]=μ, Var=μ.
# Score/weight wrt η: with the log link (me = μ) these reduce to (y − μ) and μ.
# Poisson has no trial count, so `n` is ignored.
_clamp_mu(::Poisson, μ) = max(μ, 1e-12)
_glm_score(::Poisson, μ, n, me, y) = (y - μ) / μ * me
_glm_weight(::Poisson, μ, n, me)   = me^2 / μ
_glm_logpdf(::Poisson, μ, n, y)    = logpdf(Poisson(μ), Int(y))

"""
    poisson_marginal_loglik_laplace(Y, Λ, β, link=LogLink(); kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Poisson GLLVM — a
thin wrapper over the family-generic `marginal_loglik_laplace` with `Poisson()`.
`Y` is the p×n integer count matrix; `Λ` p×K; `β` length-p. Poisson has no trial
counts, so a unit `N` is supplied internally.
"""
poisson_marginal_loglik_laplace(Y::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, link::Link = LogLink(); kwargs...) =
    marginal_loglik_laplace(Poisson(), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver (Poisson slice 2).
# ---------------------------------------------------------------------------

"""
    PoissonFit

Result of [`fit_poisson_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the `link`, the maximised Laplace `loglik`, the optimiser `converged`
flag, and `iterations`.
"""
struct PoissonFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::PoissonFit)
    p, K = size(f.Λ)
    print(io, "PoissonFit(p=", p, ", K=", K, ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_poisson_gllvm(Y; K, link=LogLink(), mask=nothing, …) -> PoissonFit

Fit a Poisson GLLVM by L-BFGS on the Laplace marginal log-likelihood
(`poisson_marginal_loglik_laplace`). `Y` is a p×n integer count matrix
(responses × sites) that may contain `missing` (gllvm-style NA); `K` the latent
dimension. Optimises intercepts `β` and loadings `Λ`. The default analytic
Laplace gradient is used on the plain no-mask/no-offset path, with an internal
finite-difference fallback; masked or offset fits use finite differences. Warm
start = empirical log-mean intercepts + an SVD (PPCA-style) loadings init.

Missing data: pass a `mask` (p×n Bool, `false` = unobserved) or simply include
`missing` entries in `Y` — either way the masked cells are dropped from the
marginal *and* from the warm start, so the fit depends only on the observed cells
(it is invariant to whatever sits in the masked positions).

Offset: pass a p×n `offset` (known additive term in `η = β + offset + Λz`, e.g.
log-exposure/effort/area). It is subtracted from the link-scale warm start so `β`
estimates the offset-free intercept.
"""
function fit_poisson_gllvm(Y::AbstractMatrix; K::Integer,
        link::Link = LogLink(), mask = nothing, offset = nothing,
        gradient::Symbol = :analytic,
        β_init = nothing, Λ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    # NA handling: derive the observation mask (explicit `mask`, else from `missing`)
    # and a sanitized count matrix with a safe placeholder in the masked cells.
    msk = mask === nothing ? (any(ismissing, Y) ? observed_mask(Y) : nothing) : mask
    Yc = Integer.(_sanitize_missing(Y, 0))

    # warm start: empirical log-scale intercepts + SVD (PPCA-like) loadings.
    # With an offset (η = β + offset + Λz), subtract it from the link-scale data so
    # β₀/Λ₀ estimate the offset-free part. Masked cells are overwritten with their
    # row's observed mean so neither the intercept nor the SVD sees the placeholder.
    Zemp = [linkfun(link, max(Yc[t, i] + 0.5, 1e-4)) for t in 1:p, i in 1:n]
    offset === nothing || (Zemp .-= offset)
    if msk !== nothing
        @inbounds for t in 1:p
            obs = view(msk, t, :)
            cnt = count(obs)
            rowmean = cnt > 0 ? sum(Zemp[t, i] for i in 1:n if msk[t, i]) / cnt : 0.0
            for i in 1:n
                msk[t, i] || (Zemp[t, i] = rowmean)
            end
        end
    end
    β0 = β_init === nothing ? vec(sum(Zemp; dims = 2)) ./ n : collect(float.(β_init))
    Λ0 = if Λ_init === nothing
        Zc = Zemp .- β0
        F = svd(Zc)
        kk = min(K, length(F.S))
        L = zeros(p, K)
        @inbounds for j in 1:kk
            L[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
        end
        L
    else
        collect(float.(Λ_init))
    end

    θ0 = vcat(β0, pack_lambda(Λ0))
    N1 = ones(Int, size(Yc))                     # unit trials, hoisted out of the per-eval closure
    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        v = try
            -marginal_loglik_laplace(Poisson(), Yc, N1, Λ, β, link; mask = msk, offset = offset,
                                     maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    opts = Optim.Options(g_tol = g_tol, iterations = iterations)
    # Exact gradient (issue #65): the implicit-step ForwardDiff gradient. Valid
    # for the plain Poisson marginal and the masked marginal — the mask is passed
    # through (masked-cell score/weight are zeroed, matching the masked objective;
    # FD-verified in test/test_missing_response.jl). The offset path still uses the
    # finite-difference gradient (the analytic gradient does not carry an offset).
    # A finite-difference fallback also covers any θ where the analytic gradient is
    # non-finite (e.g. a pathological line-search probe).
    res = if gradient === :analytic && offset === nothing
        function g!(G, θ)
            β = θ[1:p]; Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
            gg = try
                poisson_laplace_grad(Yc, Λ, β; mask = msk)
            catch
                nothing
            end
            if gg === nothing || !all(isfinite, gg)
                hh = 1e-6
                @inbounds for i in eachindex(θ)
                    θp = copy(θ); θp[i] += hh; θm = copy(θ); θm[i] -= hh
                    G[i] = (negll(θp) - negll(θm)) / (2hh)
                end
            else
                G .= .-gg                       # ∇(negll) = −∇(marginal)
            end
            return G
        end
        Optim.optimize(negll, g!, θ0, ls, opts)
    else
        Optim.optimize(negll, θ0, ls, opts; autodiff = :finite)
    end
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    return PoissonFit(β̂, Λ̂, link, -Optim.minimum(res),
                      Optim.converged(res), Optim.iterations(res))
end
