# Constrained ordination (reduced-rank regression of the latent variables on
# environmental predictors) for the non-Gaussian Laplace families.
#
# This is gllvm's flagship "what environment structures the community" model. The
# K latent variables are given a covariate-driven mean: each site's latent vector
# regresses on the q site covariates x_s through a q×K coefficient matrix B,
#
#     z_s ~ N(B' x_s, I_K),   η_{ts} = β_t + (Λ z_s)_t .
#
# Reparametrising u_s = z_s − B' x_s ~ N(0, I_K) turns the covariate-driven mean
# into a fixed, RANK-K offset on the linear predictor:
#
#     η_{ts} = β_t + (Λ B' x_s)_t + (Λ u_s)_t ,
#
# i.e. exactly the offset-augmented Laplace marginal already in the package
# (src/families/covariates.jl, `_marginal_loglik_offset`) with a unit-prior latent
# `u_s` and loadings Λ, the only new ingredient being the reduced-rank offset
#
#     O = Λ · B' · X'      (p × n).
#
# Because Λ enters BOTH the offset and the random-effect loadings, this is a
# genuine reduced-rank regression (RRR): the environment is projected onto the same
# K-dimensional latent axes that carry the residual community covariation. The
# fitted B columns are the canonical constrained-ordination axes (the
# environmental gradients the community responds to); Λ maps those axes onto
# species. Setting B = 0 recovers the unconstrained ordination verbatim.
#
# Design reuse: the offset is constant in u, so the offset-aware Laplace core
# `_marginal_loglik_offset` applies unchanged; every family-specific helper
# (`_cov_default_link`, `_cov_has_disp`, `_cov_disp_init`, `_cov_family`,
# `_cov_zemp`) is shared with the covariate fitters, and the L-BFGS driver mirrors
# `fit_gllvm_speciescov`, differing only in how the offset is assembled and in the
# θ block, which now packs `vec(B)` (length q·K) alongside β and Λ.

# Reduced-rank constrained-ordination offset O[t,s] = (Λ B' x_s)_t, returned as a
# p×n matrix O = Λ * (B' * X'). Conventions: Λ is p×K, B is q×K, X is n×q
# (row s = x_s'). Throws DimensionMismatch on any mismatch.
function _build_offset_constrained(Λ::AbstractMatrix, B::AbstractMatrix, X::AbstractMatrix)
    K = size(Λ, 2)
    size(B, 2) == K ||
        throw(DimensionMismatch("Λ has K = $K columns but B has $(size(B, 2)) columns"))
    q = size(B, 1)
    size(X, 2) == q ||
        throw(DimensionMismatch("B has q = $q rows but X has $(size(X, 2)) columns"))
    # O = Λ (p×K) * (B' (K×q) * X' (q×n)) = (p×n)
    return Λ * (B' * X')
end

"""
    constrained_marginal_loglik_laplace(family, Y, N, Λ, β, B, X, link; kwargs...) -> Float64

Laplace log-marginal for a constrained ordination (reduced-rank regression): the
offset-augmented marginal with site-covariate offset `O = Λ Bᵀ Xᵀ`, where `B`
(q×K) regresses the K latent axes onto the `q` covariates in `X` (n×q). Reduces
exactly to the unconstrained marginal when `B = 0` (then `O = 0`). Maximised by
[`fit_constrained_gllvm`](@ref).
"""
function constrained_marginal_loglik_laplace(family, Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, B::AbstractMatrix, X::AbstractMatrix,
        link::Link; kwargs...)
    O = _build_offset_constrained(Λ, B, X)
    return _marginal_loglik_offset(family, Y, N, Λ, β, O, link; kwargs...)
end

"""
    ConstrainedOrdinationFit

Result of [`fit_constrained_gllvm`](@ref): a GLLVM fit in which the K latent
variables are regressed on the site covariates (constrained ordination /
reduced-rank regression). Fields: `family` (the Distributions marker), per-species
intercepts `β` (length p), the RRR coefficient matrix `B` (q×K — column `k` is the
`k`-th constrained ordination axis in covariate space), loadings `Λ` (p×K,
mapping the latent axes onto species), `dispersion` (`r`/`φ`/`α`, or `NaN` when the
family has none), `link`, the maximised Laplace `loglik`, `converged`, and
`iterations`.
"""
struct ConstrainedOrdinationFit
    family::Distribution
    β::Vector{Float64}
    Λ::Matrix{Float64}
    B::Matrix{Float64}
    dispersion::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::ConstrainedOrdinationFit)
    p, K = size(f.Λ); q = size(f.B, 1)
    print(io, "ConstrainedOrdinationFit(", nameof(typeof(f.family)), ", p=", p, ", q=", q, ", K=", K)
    isnan(f.dispersion) || print(io, ", disp=", round(f.dispersion; sigdigits = 4))
    print(io, ", loglik=", round(f.loglik; sigdigits = 7), f.converged ? "" : ", NOT CONVERGED", ")")
end

# Residual Laplace modes U (K×n): the per-site mode of u_s ~ N(0, I) at the
# offset-augmented linear predictor η0 = β + (Λ B' x_s), with loadings Λ. Shared
# by getLV (which adds the constrained mean B' x_s) and predict (which uses U
# directly to reconstruct η = β + O + Λ U).
function _constrained_residual_modes(fit::ConstrainedOrdinationFit,
        Y::AbstractMatrix{<:Real}, X::AbstractMatrix{<:Real},
        Nm::AbstractMatrix)
    p, n = size(Y); K = size(fit.Λ, 2)
    fam = _cov_family(fit.family, fit.dispersion)
    O = _build_offset_constrained(fit.Λ, fit.B, X)
    U = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        η0 = fit.β .+ view(O, :, s)
        U[:, s] = _laplace_mode_off(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, η0, fit.link)
    end
    return U, O
end

"""
    getLV(fit::ConstrainedOrdinationFit, Y, X; rotate=true, N=nothing) -> n×K matrix

Conditional latent scores for a constrained-ordination (RRR) fit: the FULL latent
score `z_s = B' x_s + u_s`, where the constrained mean `B' x_s` is the
environment-driven part and `u_s` the per-site residual Laplace mode at
`η = β + Λ B' x_s + Λ u_s`. `X` is the `n×q` site-covariate matrix. `rotate=true`
applies the canonical [`rotation`](@ref) of `Λ`.
"""
function getLV(fit::ConstrainedOrdinationFit, Y::AbstractMatrix{<:Real}, X::AbstractMatrix{<:Real};
               rotate::Bool = true, N::Union{Nothing, AbstractMatrix} = nothing)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    U, _ = _constrained_residual_modes(fit, Y, X, Nm)
    Zt = (fit.B' * X')' .+ permutedims(U)        # n×K full latent score z_s = B'x_s + u_s
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::ConstrainedOrdinationFit, Y, X; type=:response, N=nothing) -> p×n matrix

`:link` = the linear predictor `η = β + (Λ B' x_s) + Λ û_s`, reconstructed from the
unrotated residual modes `û` (so `η = β + O + Λ U`); `:response` (= `:mean`) = the
mean `μ = linkinv(link, η)`.
"""
function predict(fit::ConstrainedOrdinationFit, Y::AbstractMatrix{<:Real}, X::AbstractMatrix{<:Real};
                 type::Symbol = :response, N::Union{Nothing, AbstractMatrix} = nothing)
    type in (:response, :mean, :link) ||
        throw(ArgumentError("type must be :response, :mean, or :link; got :$type"))
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    U, O = _constrained_residual_modes(fit, Y, X, Nm)
    η = fit.β .+ O .+ fit.Λ * U
    type === :link && return η
    return linkinv.(Ref(fit.link), _clamp_eta.(η))
end

# Post-fit accessors (mirror the covered covariate analogue GllvmCovFit in
# src/postfit.jl): `_loglik`/`_nparams` unlock the generic `aic`/`bic`, and
# `fitted` is the response-scale conditional prediction. (No `residuals`: like
# GllvmCovFit, no family-generic Dunn–Smyth residual is provided for this type.)
_loglik(fit::ConstrainedOrdinationFit) = fit.loglik

# Free parameters: β (p) + Λ (modulo K(K−1)/2 rotational df) + vec(B) (q·K) + dispersion?
function _nparams(fit::ConstrainedOrdinationFit)
    p, K = size(fit.Λ); q = size(fit.B, 1)
    return p + (p * K - div(K * (K - 1), 2)) + q * K + (isnan(fit.dispersion) ? 0 : 1)
end

"""
    fitted(fit::ConstrainedOrdinationFit, Y, X; N=nothing) -> p×n matrix of fitted means.
"""
fitted(fit::ConstrainedOrdinationFit, Y::AbstractMatrix{<:Real}, X::AbstractMatrix{<:Real};
       N::Union{Nothing, AbstractMatrix} = nothing) =
    predict(fit, Y, X; type = :response, N = N)

"""
    fit_constrained_gllvm(Y; family, X, K, link=nothing, N=nothing, …) -> ConstrainedOrdinationFit

Fit a **constrained-ordination** GLLVM by L-BFGS over `[β; vec(Λ); vec(B);
(log-dispersion)]` on the reduced-rank offset-augmented Laplace marginal. The K
latent variables carry a covariate-driven mean, `z_s ~ N(B' x_s, I_K)`, so the
linear predictor is

    η_{ts} = β_t + (Λ B' x_s)_t + (Λ u_s)_t ,   u_s ~ N(0, I_K),

a reduced-rank regression of the latent axes on the environment: the fitted q×K
matrix `B` gives the canonical constrained ordination axes (the environmental
gradients the community responds to) and `Λ` maps them onto species. With `B = 0`
this reduces exactly to the unconstrained ordination.

`family` is a `Distributions` marker — `Poisson()`, `NegativeBinomial()`,
`Binomial()`, `Beta()`, or `Gamma()` — and dispatches the marginal (the
dispersion, where present, is jointly estimated). `X` is the `n×q` site-covariate
matrix (row `s` is `x_s'`); `Y` is `p × n`; `N` supplies Binomial trial counts
(default all-ones). Finite-difference gradient.

```julia
# Poisson community constrained by two site covariates onto K = 2 axes:
fit = fit_constrained_gllvm(Y; family = Poisson(), X = X, K = 2)
fit.B            # q×2 constrained ordination axes (environment → latent)
fit.Λ            # p×2 species loadings on those axes
```
"""
function fit_constrained_gllvm(Y::AbstractMatrix{<:Real}; family, X::AbstractMatrix{<:Real},
        K::Integer, link::Union{Nothing, Link} = nothing,
        N::Union{Nothing, AbstractMatrix} = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    size(X, 1) == n ||
        throw(DimensionMismatch("X must be (n, q) = ($n, q) with one row per site; got $(size(X))"))
    q = size(X, 2)
    rr = rr_theta_len(p, K)
    lk = link === nothing ? _cov_default_link(family) : link
    Nm = N === nothing ? fill(1, p, n) : N
    has_disp = _cov_has_disp(family)

    # Warm start: link-scale row means for β, SVD loadings, zero RRR coefficients —
    # the same machinery as fit_gllvm_speciescov (B starts at the unconstrained
    # ordination, B = 0).
    Zemp = _cov_zemp(family, Y, Nm, lk)
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0
    F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    B0 = zeros(q, K)

    θ0 = has_disp ? vcat(β0, pack_lambda(Λ0), vec(B0), log(_cov_disp_init(family))) :
                    vcat(β0, pack_lambda(Λ0), vec(B0))
    qK = q * K
    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        B = reshape(θ[(p + rr + 1):(p + rr + qK)], q, K)
        disp = has_disp ? exp(θ[p + rr + qK + 1]) : NaN
        fam = _cov_family(family, disp)
        O = _build_offset_constrained(Λ, B, X)
        v = try
            -_marginal_loglik_offset(fam, Y, Nm, Λ, β, O, lk;
                                     maxiter = newton_maxiter, tol = newton_tol)
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
    B̂ = reshape(θ̂[(p + rr + 1):(p + rr + qK)], q, K)
    disp̂ = has_disp ? exp(θ̂[p + rr + qK + 1]) : NaN
    return ConstrainedOrdinationFit(family, β̂, Λ̂, B̂, disp̂, lk, -Optim.minimum(res),
                                    Optim.converged(res), Optim.iterations(res))
end
