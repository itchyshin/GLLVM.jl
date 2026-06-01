# simulate(fit, …) — draw a fresh response matrix from a fitted non-Gaussian GLLVM.
# Reuses the per-family samplers (`_cov_sample`, `families/covariates.jl`): draws a
# new per-site latent `z_s ~ N(0, I_K)`, forms `η`, and samples each response. The
# shared `laplace.jl` core is untouched.

using Random: AbstractRNG, default_rng

# (family marker carrying the fitted dispersion, link) for each scalar-μ fit.
_sim_family(fit::PoissonFit)     = (Poisson(), fit.link)
_sim_family(fit::NBFit)          = (NegativeBinomial(fit.r, 0.5), fit.link)
_sim_family(fit::BetaFit)        = (Beta(fit.φ, 1.0), fit.link)
_sim_family(fit::GammaFit)       = (Gamma(fit.α, 1.0), fit.link)
_sim_family(fit::ExponentialFit) = (Exponential(1.0), fit.link)

const _ScalarMuFit = Union{PoissonFit, NBFit, BetaFit, GammaFit, ExponentialFit}

# Element type of a simulated matrix: continuous families → Float64, else Int.
_sim_eltype(fam) = fam isa Union{Beta, Gamma, Exponential} ? Float64 : Int

"""
    simulate(fit, n; rng=Random.default_rng()) -> p×n matrix

Simulate a fresh response matrix (`p` species × `n` sites) from a fitted
non-Gaussian GLLVM (`PoissonFit`, `NBFit`, `BetaFit`, `GammaFit`,
`ExponentialFit`). A new latent `z_s ~ N(0, I_K)` is drawn per site, `η = β + Λ z`,
and each response sampled from the fitted family at `μ = linkinv(link, η)`. Pass a
fixed `rng` to reproduce. (For `BinomialFit` pass `N`; for a covariate
`GllvmCovFit` use the `X` method below.)
"""
function simulate(fit::_ScalarMuFit, n::Integer; rng::AbstractRNG = default_rng())
    fam, link = _sim_family(fit)
    p, K = size(fit.Λ)
    Y = Matrix{_sim_eltype(fam)}(undef, p, n)
    @inbounds for s in 1:n
        η = fit.β .+ fit.Λ * randn(rng, K)
        for t in 1:p
            μ = linkinv(link, _clamp_eta(η[t]))
            Y[t, s] = _cov_sample(fam, μ, 1, rng)
        end
    end
    return Y
end

"""
    simulate(fit::BinomialFit, n; N=nothing, rng=Random.default_rng()) -> p×n matrix

Binomial simulation with trial counts `N` (default all-ones / Bernoulli).
"""
function simulate(fit::BinomialFit, n::Integer;
                  N::Union{Nothing, AbstractMatrix} = nothing, rng::AbstractRNG = default_rng())
    p, K = size(fit.Λ)
    Nm = N === nothing ? fill(1, p, n) : N
    Y = Matrix{Int}(undef, p, n)
    @inbounds for s in 1:n
        η = fit.β .+ fit.Λ * randn(rng, K)
        for t in 1:p
            μ = clamp(linkinv(fit.link, _clamp_eta(η[t])), 1e-12, 1 - 1e-12)
            Y[t, s] = rand(rng, Binomial(Nm[t, s], μ))
        end
    end
    return Y
end

"""
    simulate(fit::GllvmCovFit, X; N=nothing, rng=Random.default_rng()) -> p×n matrix

Simulate from a fitted covariate model at the design `X` (`(p, n, q)`), with the
fixed-effect offset: `η = β + Xγ + Λ z`. `n` is taken from `size(X, 2)`.
"""
function simulate(fit::GllvmCovFit, X::AbstractArray{<:Real, 3};
                  N::Union{Nothing, AbstractMatrix} = nothing, rng::AbstractRNG = default_rng())
    p, K = size(fit.Λ); n = size(X, 2)
    fam = _cov_family(fit.family, fit.dispersion)
    Nm = N === nothing ? fill(1, p, n) : N
    O = _build_offset(X, fit.γ)
    Y = Matrix{_sim_eltype(fit.family)}(undef, p, n)
    @inbounds for s in 1:n
        η = fit.β .+ view(O, :, s) .+ fit.Λ * randn(rng, K)
        for t in 1:p
            μ = linkinv(fit.link, _clamp_eta(η[t]))
            Y[t, s] = _cov_sample(fam, μ, Nm[t, s], rng)
        end
    end
    return Y
end
