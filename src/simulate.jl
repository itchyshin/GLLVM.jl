"""
    simulate_response(fit, y; nsim=1, rng=Random.default_rng(), kwargs...)

Draw in-sample response matrices from a fitted one-part GLLVM, conditional on
the fitted latent scores used by [`predict`](@ref). With `nsim = 1`, returns a
`p × n` matrix. With `nsim > 1`, returns a `p × n × nsim` array.

Supported fits are Gaussian, Poisson, Binomial, NB2, Beta, and Gamma. Ordinal
post-fit simulation is deliberately not routed yet because the R bridge
ordinal response semantics are still gated.
"""
function simulate_response end

function _simulate_nsim(nsim::Integer)
    nsim >= 1 || throw(ArgumentError("nsim must be a positive integer"))
    return Int(nsim)
end

_simulate_return(out::AbstractArray, nsim::Integer) =
    nsim == 1 ? out[:, :, 1] : out

function _simulate_trials(N, p::Integer, n::Integer)
    if N === nothing
        return fill(1, p, n)
    end
    Nm = Matrix{Int}(N)
    size(Nm) == (p, n) ||
        throw(DimensionMismatch("N must be $(p)x$(n); got $(size(Nm))"))
    all(Nm .>= 0) || throw(ArgumentError("N must contain non-negative trials"))
    return Nm
end

function simulate_response(fit::GllvmFit, y::AbstractMatrix;
                           nsim::Integer = 1,
                           rng::AbstractRNG = Random.default_rng(),
                           X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing)
    m = _simulate_nsim(nsim)
    μ = predict(fit, y; type = :response, X = X)
    p, n = size(μ)
    out = Array{Float64,3}(undef, p, n, m)
    σ = fit.pars.σ_eps
    @inbounds for k in 1:m, s in 1:n, t in 1:p
        out[t, s, k] = rand(rng, Normal(μ[t, s], σ))
    end
    return _simulate_return(out, m)
end

function simulate_response(fit::PoissonFit, Y::AbstractMatrix{<:Integer};
                           nsim::Integer = 1,
                           rng::AbstractRNG = Random.default_rng())
    m = _simulate_nsim(nsim)
    μ = predict(fit, Y; type = :response)
    p, n = size(μ)
    out = Array{Int,3}(undef, p, n, m)
    @inbounds for k in 1:m, s in 1:n, t in 1:p
        out[t, s, k] = rand(rng, Poisson(max(μ[t, s], 0.0)))
    end
    return _simulate_return(out, m)
end

function simulate_response(fit::BinomialFit, Y::AbstractMatrix{<:Integer};
                           nsim::Integer = 1,
                           rng::AbstractRNG = Random.default_rng(),
                           N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    m = _simulate_nsim(nsim)
    μ = predict(fit, Y; type = :response, N = N)
    p, n = size(μ)
    Nm = _simulate_trials(N, p, n)
    out = Array{Int,3}(undef, p, n, m)
    @inbounds for k in 1:m, s in 1:n, t in 1:p
        out[t, s, k] = rand(rng, Binomial(Nm[t, s], clamp(μ[t, s], 0.0, 1.0)))
    end
    return _simulate_return(out, m)
end

function simulate_response(fit::NBFit, Y::AbstractMatrix{<:Integer};
                           nsim::Integer = 1,
                           rng::AbstractRNG = Random.default_rng())
    m = _simulate_nsim(nsim)
    μ = predict(fit, Y; type = :response)
    p, n = size(μ)
    r = fit.r
    out = Array{Int,3}(undef, p, n, m)
    @inbounds for k in 1:m, s in 1:n, t in 1:p
        μts = max(μ[t, s], 0.0)
        prob = clamp(r / (r + μts), eps(Float64), 1.0 - eps(Float64))
        out[t, s, k] = rand(rng, NegativeBinomial(r, prob))
    end
    return _simulate_return(out, m)
end

function simulate_response(fit::BetaFit, Y::AbstractMatrix{<:Real};
                           nsim::Integer = 1,
                           rng::AbstractRNG = Random.default_rng())
    m = _simulate_nsim(nsim)
    μ = predict(fit, Y; type = :response)
    p, n = size(μ)
    φ = fit.φ
    out = Array{Float64,3}(undef, p, n, m)
    @inbounds for k in 1:m, s in 1:n, t in 1:p
        μts = clamp(μ[t, s], 1e-12, 1 - 1e-12)
        out[t, s, k] = rand(rng, Beta(μts * φ, (1 - μts) * φ))
    end
    return _simulate_return(out, m)
end

function simulate_response(fit::GammaFit, Y::AbstractMatrix{<:Real};
                           nsim::Integer = 1,
                           rng::AbstractRNG = Random.default_rng())
    m = _simulate_nsim(nsim)
    μ = predict(fit, Y; type = :response)
    p, n = size(μ)
    α = fit.α
    out = Array{Float64,3}(undef, p, n, m)
    @inbounds for k in 1:m, s in 1:n, t in 1:p
        out[t, s, k] = rand(rng, Gamma(α, max(μ[t, s], eps(Float64)) / α))
    end
    return _simulate_return(out, m)
end

function simulate_response(::OrdinalFit, Y::AbstractMatrix{<:Integer};
                           nsim::Integer = 1,
                           rng::AbstractRNG = Random.default_rng())
    _simulate_nsim(nsim)
    throw(ArgumentError(
        "simulate_response is not yet routed for OrdinalFit; ordinal response " *
        "simulation remains gated until R bridge ordinal semantics are reconciled"))
end
