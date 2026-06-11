# Random-effects fitters (plan SP1.1+). First slice: a Gaussian per-site random ROW
# effect — r_i ~ N(0, σ_row²) added to η[t,i] for every trait t (gllvm's random
# `row.eff`). Marginally this adds σ_row²·1ₚ1ₚᵀ to the per-site covariance Σ_y, i.e.
# it is an augmented constant loadings column σ_row·1ₚ — so the EXISTING closed-form
# Gaussian marginal (gaussian_marginal_loglik) handles it UNCHANGED: we fit
# [vec(Λ); log σ_eps; log σ_row] and pass hcat(Λ, σ_row·1ₚ) as the loadings.
#
# SCOPE: per-site (each site its own level) row effect ⇒ the marginal stays
# per-site-iid. GROUPED row effects (sites sharing a level) induce cross-site
# correlation and need the non-iid path — a later slice.

"""
    GaussianRowREFit

Result of [`fit_gaussian_row_re`](@ref): K-dim loadings `Λ` (p×K), residual SD
`σ_eps`, the per-site random row-effect SD `σ_row` (gllvm random `row.eff`), the
maximised marginal `loglik`, the optimiser `converged` flag, and `iterations`.
Assumes a zero-mean (per-trait-centred) `y`, matching the closed-form marginal.
"""
struct GaussianRowREFit
    Λ::Matrix{Float64}
    σ_eps::Float64
    σ_row::Float64
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::GaussianRowREFit)
    p, K = size(f.Λ)
    print(io, "GaussianRowREFit(p=", p, ", K=", K,
          ", σ_eps=", round(f.σ_eps; sigdigits = 4),
          ", σ_row=", round(f.σ_row; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_gaussian_row_re(y; K, σ_row_init=0.1, g_tol=1e-6, iterations=500) -> GaussianRowREFit

Fit a Gaussian GLLVM with a per-site random ROW effect by L-BFGS over
`[vec(Λ); log σ_eps; log σ_row]` on the closed-form marginal. `y` is a `p×n`
(traits × sites) **zero-mean** matrix; `K` the latent dimension. The row effect adds
`σ_row²·1ₚ1ₚᵀ` to the per-site covariance via an augmented constant loadings column,
reusing [`gaussian_marginal_loglik`](@ref) unchanged. Warm start = PPCA for `Λ`/`σ_eps`
plus a small `σ_row`; the line search is MoreThuente (Wolfe).
"""
function fit_gaussian_row_re(y::AbstractMatrix; K::Integer,
        σ_row_init::Real = 0.1, g_tol::Real = 1e-6, iterations::Integer = 500)
    p, n = size(y)
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1; got $K"))
    K < p || throw(ArgumentError("need K < p for identifiability; got K=$K, p=$p"))
    rr = rr_theta_len(p, K)

    yf = Matrix{Float64}(y)
    Λ0, σ_eps0 = ppca_init(yf, K)
    θ0 = vcat(pack_lambda(Λ0), log(σ_eps0), log(float(σ_row_init)))

    ones_p = ones(p)
    nll = θ -> begin
        Λ     = unpack_lambda(θ[1:rr], p, K)
        σ_eps = exp(θ[rr + 1])
        σ_row = exp(θ[rr + 2])
        Λ_aug = hcat(Λ, σ_row .* ones_p)              # σ_row²·1ₚ1ₚᵀ in Σ_y
        return -gaussian_marginal_loglik(yf, Λ_aug, σ_eps)
    end

    ls = Optim.LBFGS(linesearch = Optim.LineSearches.MoreThuente())
    res = Optim.optimize(nll, θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :forward)

    θ̂     = Optim.minimizer(res)
    Λ̂     = unpack_lambda(θ̂[1:rr], p, K)
    σ_epŝ = exp(θ̂[rr + 1])
    σ_roŵ = exp(θ̂[rr + 2])
    return GaussianRowREFit(Λ̂, σ_epŝ, σ_roŵ, -Optim.minimum(res),
                            Optim.converged(res), Optim.iterations(res))
end
