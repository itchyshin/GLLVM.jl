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

# ---------------------------------------------------------------------------
# Non-Gaussian per-site random row effect via the SAME augmented-constant-column
# trick on the family-generic dense Laplace marginal. The (K+1)-th latent loading
# is σ_row·1ₚ, so the per-site mode/A/logdet absorb it with no core change; the
# gradient is a direct ForwardDiff straight through the marginal value (the
# mixed-family pattern; AD-clean — verified). Poisson here proves the pattern;
# other families follow the identical recipe (warm start + dispersion aside).
# ---------------------------------------------------------------------------

"""
    PoissonRowREFit

Result of [`fit_poisson_row_re`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the per-site random row-effect SD `σ_row`, the `link`, the maximised Laplace
`loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct PoissonRowREFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    σ_row::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::PoissonRowREFit)
    p, K = size(f.Λ)
    print(io, "PoissonRowREFit(p=", p, ", K=", K,
          ", σ_row=", round(f.σ_row; sigdigits = 4), ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_poisson_row_re(Y; K, link=LogLink(), σ_row_init=0.3, …) -> PoissonRowREFit

Fit a Poisson GLLVM with a per-site random ROW effect by L-BFGS over
`[β; vec(Λ); log σ_row]` on the dense Laplace marginal, augmenting Λ with the
constant column `σ_row·1ₚ` (so r_i ~ N(0, σ_row²) enters η[t,i] for every trait).
`Y` is a p×n count matrix; `K` the latent dimension. Gradient = direct ForwardDiff
through `poisson_marginal_loglik_laplace`; MoreThuente line search. Warm start =
empirical log-mean intercepts + an SVD loadings init + a small `σ_row`.
"""
function fit_poisson_row_re(Y::AbstractMatrix{<:Integer}; K::Integer,
        link::Link = LogLink(), σ_row_init::Real = 0.3,
        g_tol::Real = 1e-5, iterations::Integer = 500)
    p, n = size(Y)
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1; got $K"))
    rr = rr_theta_len(p, K)

    Zemp = [linkfun(link, max(Y[t, i] + 0.5, 1e-4)) for t in 1:p, i in 1:n]
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0
    F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    θ0 = vcat(β0, pack_lambda(Λ0), log(float(σ_row_init)))

    ones_p = ones(p)
    nll = θ -> begin
        β     = θ[1:p]
        Λ     = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        σ_row = exp(θ[p + rr + 1])
        return -poisson_marginal_loglik_laplace(Y, hcat(Λ, σ_row .* ones_p), β, link)
    end

    ls = Optim.LBFGS(linesearch = Optim.LineSearches.MoreThuente())
    res = Optim.optimize(nll, θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :forward)
    θ̂     = Optim.minimizer(res)
    β̂     = θ̂[1:p]
    Λ̂     = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    σ_roŵ = exp(θ̂[p + rr + 1])
    return PoissonRowREFit(β̂, Λ̂, σ_roŵ, link, -Optim.minimum(res),
                           Optim.converged(res), Optim.iterations(res))
end

# ---------------------------------------------------------------------------
# Binomial + Negative-Binomial per-site random row effects — same augmented
# column on each family's Laplace marginal (AD-clean, probed). Binomial threads
# trial counts N; NB carries a log-dispersion r alongside log σ_row.
# ---------------------------------------------------------------------------

"""
    BinomialRowREFit

Result of [`fit_binomial_row_re`](@ref): `β`, `Λ` (p×K), the per-site row-effect SD
`σ_row`, the `link`, `loglik`, `converged`, `iterations`.
"""
struct BinomialRowREFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    σ_row::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::BinomialRowREFit)
    p, K = size(f.Λ)
    print(io, "BinomialRowREFit(p=", p, ", K=", K, ", σ_row=", round(f.σ_row; sigdigits = 4),
          ", link=", nameof(typeof(f.link)), ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_binomial_row_re(Y; K, N=nothing, link=LogitLink(), σ_row_init=0.3, …) -> BinomialRowREFit

Binomial GLLVM with a per-site random ROW effect (augmented column σ_row·1ₚ on the
Laplace marginal). `Y` is p×n; `N` the trial counts (default all-ones = Bernoulli);
direct ForwardDiff gradient; MoreThuente line search.
"""
function fit_binomial_row_re(Y::AbstractMatrix{<:Integer}; K::Integer,
        N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
        link::Link = LogitLink(), σ_row_init::Real = 0.3,
        g_tol::Real = 1e-5, iterations::Integer = 500)
    p, n = size(Y)
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1; got $K"))
    Nm = N === nothing ? fill(1, p, n) : N
    size(Nm) == (p, n) || throw(DimensionMismatch("N must be $(p)×$(n)"))
    rr = rr_theta_len(p, K)
    Zemp = [linkfun(link, clamp((Y[t, i] + 0.5) / (Nm[t, i] + 1), 1e-4, 1 - 1e-4)) for t in 1:p, i in 1:n]
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0; F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    θ0 = vcat(β0, pack_lambda(Λ0), log(float(σ_row_init)))
    ones_p = ones(p)
    nll = θ -> begin
        β = θ[1:p]; Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K); σ_row = exp(θ[p + rr + 1])
        return -binomial_marginal_loglik_laplace(Y, Nm, hcat(Λ, σ_row .* ones_p), β, link)
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.MoreThuente())
    res = Optim.optimize(nll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations); autodiff = :forward)
    th = Optim.minimizer(res)
    return BinomialRowREFit(th[1:p], unpack_lambda(th[(p + 1):(p + rr)], p, K), exp(th[p + rr + 1]),
                            link, -Optim.minimum(res), Optim.converged(res), Optim.iterations(res))
end

"""
    NBRowREFit

Result of [`fit_nb_row_re`](@ref): `β`, `Λ` (p×K), NB2 dispersion `r`, the per-site
row-effect SD `σ_row`, the `link`, `loglik`, `converged`, `iterations`.
"""
struct NBRowREFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    r::Float64
    σ_row::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::NBRowREFit)
    p, K = size(f.Λ)
    print(io, "NBRowREFit(p=", p, ", K=", K, ", r=", round(f.r; sigdigits = 4),
          ", σ_row=", round(f.σ_row; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_nb_row_re(Y; K, link=LogLink(), r_init=10.0, σ_row_init=0.3, …) -> NBRowREFit

Negative-binomial (NB2) GLLVM with a per-site random ROW effect, jointly estimating
the dispersion `r` and `σ_row` via the augmented column on the Laplace marginal
(direct ForwardDiff; MoreThuente line search).
"""
function fit_nb_row_re(Y::AbstractMatrix{<:Integer}; K::Integer,
        link::Link = LogLink(), r_init::Real = 10.0, σ_row_init::Real = 0.3,
        g_tol::Real = 1e-5, iterations::Integer = 500)
    p, n = size(Y)
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1; got $K"))
    rr = rr_theta_len(p, K)
    Zemp = [linkfun(link, max(Y[t, i] + 0.5, 1e-4)) for t in 1:p, i in 1:n]
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0; F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    θ0 = vcat(β0, pack_lambda(Λ0), log(float(r_init)), log(float(σ_row_init)))
    ones_p = ones(p)
    nll = θ -> begin
        β = θ[1:p]; Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        r = exp(θ[p + rr + 1]); σ_row = exp(θ[p + rr + 2])
        return -nb_marginal_loglik_laplace(Y, hcat(Λ, σ_row .* ones_p), β, r; link = link)
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.MoreThuente())
    res = Optim.optimize(nll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations); autodiff = :forward)
    th = Optim.minimizer(res)
    return NBRowREFit(th[1:p], unpack_lambda(th[(p + 1):(p + rr)], p, K),
                      exp(th[p + rr + 1]), exp(th[p + rr + 2]), link,
                      -Optim.minimum(res), Optim.converged(res), Optim.iterations(res))
end

# ---------------------------------------------------------------------------
# Beta + Gamma per-site random row effects — same augmented column + a
# log-dispersion (φ for Beta, α for Gamma) on the scalar-aux Laplace marginal.
# ---------------------------------------------------------------------------

"""
    BetaRowREFit

[`fit_beta_row_re`](@ref) result: `β`, `Λ` (p×K), dispersion `φ`, row SD `σ_row`,
`link`, `loglik`, `converged`, `iterations`.
"""
struct BetaRowREFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    φ::Float64
    σ_row::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::BetaRowREFit)
    p, K = size(f.Λ)
    print(io, "BetaRowREFit(p=", p, ", K=", K, ", φ=", round(f.φ; sigdigits = 4),
          ", σ_row=", round(f.σ_row; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7), f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_beta_row_re(Y; K, link=LogitLink(), φ_init=10.0, σ_row_init=0.3, …) -> BetaRowREFit

Beta GLLVM (responses in (0,1)) with a per-site random ROW effect, jointly estimating
the dispersion `φ` and `σ_row` via the augmented column on the Laplace marginal.
"""
function fit_beta_row_re(Y::AbstractMatrix{<:Real}; K::Integer,
        link::Link = LogitLink(), φ_init::Real = 10.0, σ_row_init::Real = 0.3,
        g_tol::Real = 1e-5, iterations::Integer = 500)
    p, n = size(Y)
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1; got $K"))
    rr = rr_theta_len(p, K)
    Zemp = [linkfun(link, clamp(float(Y[t, i]), 1e-6, 1 - 1e-6)) for t in 1:p, i in 1:n]
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0; F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    θ0 = vcat(β0, pack_lambda(Λ0), log(float(φ_init)), log(float(σ_row_init)))
    ones_p = ones(p)
    nll = θ -> begin
        β = θ[1:p]; Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        φ = exp(θ[p + rr + 1]); σ_row = exp(θ[p + rr + 2])
        return -beta_marginal_loglik_laplace(Y, hcat(Λ, σ_row .* ones_p), β, φ; link = link)
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.MoreThuente())
    res = Optim.optimize(nll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations); autodiff = :forward)
    th = Optim.minimizer(res)
    return BetaRowREFit(th[1:p], unpack_lambda(th[(p + 1):(p + rr)], p, K),
                        exp(th[p + rr + 1]), exp(th[p + rr + 2]), link,
                        -Optim.minimum(res), Optim.converged(res), Optim.iterations(res))
end

"""
    GammaRowREFit

[`fit_gamma_row_re`](@ref) result: `β`, `Λ` (p×K), shape `α`, row SD `σ_row`,
`link`, `loglik`, `converged`, `iterations`.
"""
struct GammaRowREFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    α::Float64
    σ_row::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::GammaRowREFit)
    p, K = size(f.Λ)
    print(io, "GammaRowREFit(p=", p, ", K=", K, ", α=", round(f.α; sigdigits = 4),
          ", σ_row=", round(f.σ_row; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7), f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_gamma_row_re(Y; K, link=LogLink(), α_init=2.0, σ_row_init=0.3, …) -> GammaRowREFit

Gamma GLLVM (responses > 0) with a per-site random ROW effect, jointly estimating the
shape `α` and `σ_row` via the augmented column on the Laplace marginal.
"""
function fit_gamma_row_re(Y::AbstractMatrix{<:Real}; K::Integer,
        link::Link = LogLink(), α_init::Real = 2.0, σ_row_init::Real = 0.3,
        g_tol::Real = 1e-5, iterations::Integer = 500)
    p, n = size(Y)
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1; got $K"))
    rr = rr_theta_len(p, K)
    Zemp = [log(max(float(Y[t, i]), 1e-6)) for t in 1:p, i in 1:n]
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0; F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    θ0 = vcat(β0, pack_lambda(Λ0), log(float(α_init)), log(float(σ_row_init)))
    ones_p = ones(p)
    nll = θ -> begin
        β = θ[1:p]; Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        α = exp(θ[p + rr + 1]); σ_row = exp(θ[p + rr + 2])
        return -gamma_marginal_loglik_laplace(Y, hcat(Λ, σ_row .* ones_p), β, α; link = link)
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.MoreThuente())
    res = Optim.optimize(nll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations); autodiff = :forward)
    th = Optim.minimizer(res)
    return GammaRowREFit(th[1:p], unpack_lambda(th[(p + 1):(p + rr)], p, K),
                         exp(th[p + rr + 1]), exp(th[p + rr + 2]), link,
                         -Optim.minimum(res), Optim.converged(res), Optim.iterations(res))
end

# ---------------------------------------------------------------------------
# Grouped Gaussian random intercept (SP1.2): r_g ~ N(0, σ_u²) shared by all sites
# in group g ⇒ cross-site correlation WITHIN a group. The marginal over the stacked
# y has covariance Σ = kron(I_n, A) + kron(G, B), A = ΛΛ' + σ_eps²I, B = σ_u²·1ₚ1ₚᵀ,
# G[i,j] = 1{g(i)=g(j)}. Groups are independent, so ℓ = Σ_g ℓ_g where each group block
# is I_{n_g}⊗A + J_{n_g}⊗B — solved by the SAME rotation trick as the phylo path:
#   y_g'Σ_g⁻¹y_g = n_g·m_g'(A+n_g B)⁻¹m_g + tr(Y_gc'A⁻¹Y_gc),
#   logdet Σ_g   = logdet(A+n_g B) + (n_g−1)logdet(A).
# B is rank-1 ⇒ (A+n_g B)⁻¹ and logdet(A+n_g B) come from ONE chol(A) via
# Sherman-Morrison + the matrix-determinant lemma (v = 1ₚ):
#   (A+n_g σ_u² vv')⁻¹m = A⁻¹m − [n_g σ_u² (v'A⁻¹m)/(1+n_g σ_u² v'A⁻¹v)]·A⁻¹v,
#   logdet(A+n_g σ_u² vv') = logdet(A) + log(1 + n_g σ_u² v'A⁻¹v).
# Cost O(p³ + L·p²). Singleton groups (n_g=1) reduce to the per-site row effect.
# ---------------------------------------------------------------------------

function _grouped_intercept_loglik(y::AbstractMatrix, group_idx::Vector{Vector{Int}},
        Λ_B::AbstractMatrix, σ_eps::Real, σ_u::Real)
    p, n = size(y)
    T = promote_type(eltype(y), eltype(Λ_B), typeof(σ_eps), typeof(σ_u))
    σ² = σ_eps^2; σu² = σ_u^2
    K = size(Λ_B, 2)
    # Woodbury form of A = ΛΛ' + σ²I — factor the well-conditioned K×K core, NOT the
    # p×p A, so it stays robust as σ_eps → 0 (a direct chol(A) goes singular there):
    #   A⁻¹V = (V − Λ(σ²I+Λ'Λ)⁻¹Λ'V)/σ²,  logdet A = (p−K)logσ² + logdet(σ²I+Λ'Λ).
    Kc = Λ_B' * Λ_B
    @inbounds for k in 1:K
        Kc[k, k] += σ²
    end
    cKc = cholesky(Symmetric(Kc))
    logdetA = (p - K) * log(σ²) + logdet(cKc)
    Ainv = V -> (V .- Λ_B * (cKc \ (Λ_B' * V))) ./ σ²
    onep = ones(T, p)
    Ainv_1 = Ainv(onep)
    vAv = dot(onep, Ainv_1)
    twopi = convert(T, 2π)
    ll = zero(T)
    for idx in group_idx
        ng = length(idx)
        Yg = y[:, idx]                                   # p × ng
        mg = vec(sum(Yg, dims = 2)) ./ ng
        Ygc = Yg .- reshape(mg, p, 1)
        quad_centered = sum(Ygc .* Ainv(Ygc))            # tr(Y_gc'A⁻¹Y_gc)
        Ainv_mg = Ainv(mg)
        smcoef = (ng * σu²) / (1 + ng * σu² * vAv)
        AnB_inv_mg = Ainv_mg .- (smcoef * dot(onep, Ainv_mg)) .* Ainv_1
        quad_mean = ng * dot(mg, AnB_inv_mg)
        logdet_g = ng * logdetA + log(1 + ng * σu² * vAv)
        ll += -convert(T, 0.5) * (ng * p * log(twopi) + logdet_g + quad_mean + quad_centered)
    end
    return ll
end

"""
    gaussian_grouped_intercept_loglik(y, grouping, Λ_B, σ_eps, σ_u) -> Real

Marginal log-likelihood of a Gaussian GLLVM with a grouped random intercept: a shared
effect r_g ~ N(0, σ_u²) for every site in group g (cross-site correlation within a
group). `y` is p×n; `grouping` a length-n vector assigning each site to a group. Solved
per group by the rotation trick + a rank-1 Sherman-Morrison on one shared chol(ΛΛ'+σ²I).
"""
function gaussian_grouped_intercept_loglik(y::AbstractMatrix, grouping::AbstractVector,
        Λ_B::AbstractMatrix, σ_eps::Real, σ_u::Real)
    codes, _ = _code_grouping(grouping)
    L = maximum(codes)
    group_idx = [findall(==(g), codes) for g in 1:L]
    return _grouped_intercept_loglik(y, group_idx, Λ_B, σ_eps, σ_u)
end

"""
    GaussianGroupedREFit

Result of [`fit_gaussian_grouped_re`](@ref): loadings `Λ` (p×K), residual SD `σ_eps`,
grouped random-intercept SD `σ_u`, the number of groups `nlevels`, the maximised
`loglik`, `converged`, `iterations`.
"""
struct GaussianGroupedREFit
    Λ::Matrix{Float64}
    σ_eps::Float64
    σ_u::Float64
    nlevels::Int
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::GaussianGroupedREFit)
    p, K = size(f.Λ)
    print(io, "GaussianGroupedREFit(p=", p, ", K=", K, ", nlevels=", f.nlevels,
          ", σ_eps=", round(f.σ_eps; sigdigits = 4), ", σ_u=", round(f.σ_u; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_gaussian_grouped_re(y, grouping; K, σ_u_init=0.3, …) -> GaussianGroupedREFit

Fit a Gaussian GLLVM with a grouped random intercept (`(1|grouping)`) by L-BFGS over
`[vec(Λ); log σ_eps; log σ_u]` on the per-group rotation-trick marginal. `grouping` is a
length-n vector of group labels (any type; coded by first appearance). Warm start = PPCA
+ a small `σ_u`; MoreThuente line search; direct ForwardDiff gradient.
"""
function fit_gaussian_grouped_re(y::AbstractMatrix, grouping::AbstractVector; K::Integer,
        σ_u_init::Real = 0.3, g_tol::Real = 1e-6, iterations::Integer = 500)
    p, n = size(y)
    length(grouping) == n || throw(DimensionMismatch("grouping length must be n=$n"))
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1; got $K"))
    codes, _ = _code_grouping(grouping)
    L = maximum(codes)
    group_idx = [findall(==(g), codes) for g in 1:L]
    rr = rr_theta_len(p, K)
    yf = Matrix{Float64}(y)
    Λ0, σ0 = ppca_init(yf, K)
    θ0 = vcat(pack_lambda(Λ0), log(σ0), log(float(σ_u_init)))
    nll = θ -> -_grouped_intercept_loglik(yf, group_idx,
        unpack_lambda(θ[1:rr], p, K), exp(θ[rr + 1]), exp(θ[rr + 2]))
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.MoreThuente())
    res = Optim.optimize(nll, θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :forward)
    th = Optim.minimizer(res)
    return GaussianGroupedREFit(unpack_lambda(th[1:rr], p, K), exp(th[rr + 1]), exp(th[rr + 2]),
                                L, -Optim.minimum(res), Optim.converged(res), Optim.iterations(res))
end

# ---------------------------------------------------------------------------
# Poisson observation-level random effect (OLRE) = the Poisson `specific=TRUE`:
# per-trait overdispersion ψ_t (the estimated specific variance s_t in ψ = s + d).
# Built by the augmented-DIAGONAL trick: η[t,i] = β_t + (Λz_i)_t + √ψ_t·u_{t,i} with
# (z_i,u_i) ~ N(0,I_{K+p}), i.e. Λ_aug = [Λ | diag(√ψ)] (p×(K+p)) on the SAME
# family-generic Laplace marginal (AD-clean — probed). The latent grows K→K+p; the
# u-block is diagonal but the generic marginal treats it densely (fine at moderate p).
# ---------------------------------------------------------------------------

"""
    PoissonOLREFit

Result of [`fit_poisson_olre`](@ref): `β`, `Λ` (p×K), the per-trait OLRE variances `ψ`
(length p — the specific `s_t` overdispersion), `link`, `loglik`, `converged`, `iterations`.
"""
struct PoissonOLREFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    ψ::Vector{Float64}
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::PoissonOLREFit)
    p, K = size(f.Λ)
    print(io, "PoissonOLREFit(p=", p, ", K=", K, ", mean ψ=", round(sum(f.ψ) / p; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7), f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_poisson_olre(Y; K, link=LogLink(), ψ_init=0.3, …) -> PoissonOLREFit

Fit a Poisson GLLVM with a per-trait observation-level random effect (overdispersion),
i.e. the Poisson `specific=TRUE`: jointly estimate `[β; vec(Λ); log ψ_1…log ψ_p]` on the
dense Laplace marginal via the augmented-diagonal `Λ_aug = [Λ | diag(√ψ)]`. Direct
ForwardDiff gradient; MoreThuente line search. `ψ_t` is the estimated specific residual
`s_t` (the `ψ = s + d` decomposition); total latent-scale residual is `ψ_t + ln(1+1/μ̂_t)`.
"""
function fit_poisson_olre(Y::AbstractMatrix{<:Integer}; K::Integer,
        link::Link = LogLink(), ψ_init::Real = 0.3,
        g_tol::Real = 1e-5, iterations::Integer = 500)
    p, n = size(Y)
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1; got $K"))
    rr = rr_theta_len(p, K)
    Zemp = [linkfun(link, max(Y[t, i] + 0.5, 1e-4)) for t in 1:p, i in 1:n]
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0; F = svd(Zc); kk = min(K, length(F.S))
    Λ0 = zeros(p, K)
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    θ0 = vcat(β0, pack_lambda(Λ0), fill(log(float(ψ_init)), p))
    nll = θ -> begin
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        ψ = exp.(θ[(p + rr + 1):(p + rr + p)])
        Λ_aug = hcat(Λ, Matrix(Diagonal(sqrt.(ψ))))
        return -poisson_marginal_loglik_laplace(Y, Λ_aug, β, link)
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.MoreThuente())
    res = Optim.optimize(nll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations); autodiff = :forward)
    th = Optim.minimizer(res)
    return PoissonOLREFit(th[1:p], unpack_lambda(th[(p + 1):(p + rr)], p, K),
                          exp.(th[(p + rr + 1):(p + rr + p)]), link,
                          -Optim.minimum(res), Optim.converged(res), Optim.iterations(res))
end
