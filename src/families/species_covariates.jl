# Species-specific covariate coefficients (a p×q matrix B) for the non-Gaussian
# Laplace families.
#
# The shared-coefficient path (src/families/covariates.jl) puts ONE coefficient
# vector γ (length q) in front of the covariates, so every species responds to a
# given environmental gradient identically. This file relaxes that: each species t
# carries its OWN coefficient row B[t, :], so the additive offset becomes
#
#     o_{ts} = Σ_k X[t,s,k]·B[t,k]
#
# and the linear predictor is
#
#     η_{ts} = β_t + Σ_k X[t,s,k]·B[t,k] + (Λ z_s)_t .
#
# This is the species-environment interaction surface gllvmTMB exposes via its
# fourth-corner / species-specific slope terms. The shared-γ path is the special
# case B[t, :] ≡ γ for all t.
#
# Design reuse: the offset is still constant in z, so the offset-aware Laplace
# core `_marginal_loglik_offset` (src/families/covariates.jl) applies verbatim — we
# only change how the (p×n) offset matrix `O` is assembled. Every family-specific
# helper (`_cov_default_link`, `_cov_has_disp`, `_cov_disp_init`, `_cov_family`,
# `_cov_zemp`) is shared with the shared-γ fitter, and the L-BFGS driver mirrors
# `fit_gllvm_cov` exactly, differing only in the θ block that now packs the full
# `vec(B)` (length p·q) in place of γ (length q).

# Offset matrix O[t,s] = Σ_k X[t,s,k]·B[t,k] from X::(p,n,q) and B::(p×q).
# Each species t uses its own coefficient row B[t, :].
function _build_offset_species(X::AbstractArray{<:Real, 3}, B::AbstractMatrix)
    size(X, 1) == size(B, 1) ||
        throw(DimensionMismatch("X has p = $(size(X, 1)) species but B has $(size(B, 1)) rows"))
    size(X, 3) == size(B, 2) ||
        throw(DimensionMismatch("X has q = $(size(X, 3)) covariates but B has $(size(B, 2)) columns"))
    # Broadcast B::(p×q) to (p×1×q) and contract over the covariate axis.
    return dropdims(sum(X .* reshape(B, size(B, 1), 1, size(B, 2)); dims = 3); dims = 3)
end

"""
    GllvmSpeciesCovFit

Result of [`fit_gllvm_speciescov`](@ref): a GLLVM fit with **species-specific**
fixed-effect covariate coefficients. Fields: `family` (the Distributions marker),
per-species intercepts `β` (length p), the species-specific coefficient matrix `B`
(p×q, row `t` are species `t`'s slopes), loadings `Λ` (p×K), `dispersion`
(`r`/`φ`/`α`, or `NaN` when the family has none), `link`, the maximised Laplace
`loglik`, `converged`, and `iterations`.
"""
struct GllvmSpeciesCovFit
    family::Distribution
    β::Vector{Float64}
    B::Matrix{Float64}
    Λ::Matrix{Float64}
    dispersion::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::GllvmSpeciesCovFit)
    p, K = size(f.Λ); q = size(f.B, 2)
    print(io, "GllvmSpeciesCovFit(", nameof(typeof(f.family)), ", p=", p, ", q=", q, ", K=", K)
    isnan(f.dispersion) || print(io, ", disp=", round(f.dispersion; sigdigits = 4))
    print(io, ", loglik=", round(f.loglik; sigdigits = 7), f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_gllvm_speciescov(Y; family, X, K, link=nothing, N=nothing, …) -> GllvmSpeciesCovFit

Fit a non-Gaussian GLLVM with **species-specific** covariate coefficients by
L-BFGS over `[β; vec(B); vec(Λ); (log-dispersion)]` on the offset-augmented Laplace
marginal, where the linear predictor is
`η_{ts} = β_t + Σ_k X[t,s,k]·B[t,k] + (Λ z_s)_t`.

This generalises [`fit_gllvm_cov`](@ref): rather than one shared coefficient vector
`γ` (length q), every species `t` gets its own slope row `B[t, :]`. The shared-γ
fit is the special case where all rows of `B` are equal.

`family` is a `Distributions` marker — `Poisson()`, `NegativeBinomial()`,
`Binomial()`, `Beta()`, or `Gamma()` — and dispatches the marginal (the dispersion,
where present, is jointly estimated). `X` is the `(p, n, q)` covariate array (same
contract as the Gaussian engine); `Y` is `p × n`; `N` supplies Binomial trial counts
(default all-ones). Finite-difference gradient.

```julia
# Poisson abundance with one site covariate, species-specific responses:
X = reshape(repeat(temp', p), p, n, 1)            # X[t,s,1] = temp[s]
fit = fit_gllvm_speciescov(Y; family = Poisson(), X = X, K = 2)
fit.B            # p×1 matrix of per-species environmental slopes
```
"""
function fit_gllvm_speciescov(Y::AbstractMatrix{<:Real}; family, X::AbstractArray{<:Real, 3},
        K::Integer, link::Union{Nothing, Link} = nothing,
        N::Union{Nothing, AbstractMatrix} = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    size(X, 1) == p && size(X, 2) == n ||
        throw(DimensionMismatch("X must be (p, n, q) = ($p, $n, q); got $(size(X))"))
    q = size(X, 3)
    rr = rr_theta_len(p, K)
    lk = link === nothing ? _cov_default_link(family) : link
    Nm = N === nothing ? fill(1, p, n) : N
    has_disp = _cov_has_disp(family)

    # Warm start: link-scale row means for β, zero species-specific slopes, SVD
    # loadings — identical machinery to fit_gllvm_cov.
    Zemp = _cov_zemp(family, Y, Nm, lk)
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0
    F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end

    θ0 = has_disp ? vcat(β0, zeros(p * q), pack_lambda(Λ0), log(_cov_disp_init(family))) :
                    vcat(β0, zeros(p * q), pack_lambda(Λ0))
    function negll(θ)
        β = θ[1:p]
        B = reshape(θ[(p + 1):(p + p * q)], p, q)
        Λ = unpack_lambda(θ[(p + p * q + 1):(p + p * q + rr)], p, K)
        disp = has_disp ? exp(θ[p + p * q + rr + 1]) : NaN
        fam = _cov_family(family, disp)
        O = _build_offset_species(X, B)
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
    B̂ = reshape(θ̂[(p + 1):(p + p * q)], p, q)
    Λ̂ = unpack_lambda(θ̂[(p + p * q + 1):(p + p * q + rr)], p, K)
    disp̂ = has_disp ? exp(θ̂[p + p * q + rr + 1]) : NaN
    return GllvmSpeciesCovFit(family, β̂, B̂, Λ̂, disp̂, lk, -Optim.minimum(res),
                              Optim.converged(res), Optim.iterations(res))
end
