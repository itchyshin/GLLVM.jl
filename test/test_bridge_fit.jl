# Focused tests for the R -> Julia bridge entry point `bridge_fit`
# (src/bridge.jl). The bridge fits ANY supported family and marshals the result
# into a flat, JuliaCall-convertible NamedTuple.
#
# Asserts:
#   (1) bridge_fit for gaussian, poisson, and a MIXED [gaussian,poisson,binomial]
#       returns the documented contract keys with the right shapes;
#   (2) its `loglik` and `loadings` match a DIRECT fit (fit_*_gllvm) to ~1e-8
#       (it is the same fit, just marshalled);
#   (3) every returned value is a primitive / array (JuliaCall-safe) — no field is
#       a custom Julia struct;
#   (4) the mixed return includes a `correlation` matrix.
#
# Self-runnable: `julia --project=. test/test_bridge_fit.jl`.

using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

# A value is JuliaCall-convertible if it is a Bool/Real scalar, a String, or a
# (possibly multi-dimensional) array of Reals or Strings. Anything else (a custom
# struct, a Link, a Distributions marker, …) fails the boundary.
_is_primitive_scalar(v) = v isa Bool || v isa Real || v isa AbstractString
function _is_juliacall_safe(v)
    _is_primitive_scalar(v) && return true
    if v isa AbstractArray
        return eltype(v) <: Real || eltype(v) <: AbstractString ||
               eltype(v) <: Bool
    end
    return false
end

# Canonical sign-fixed right-singular-vector rotation of Λ (mirrors the bridge's
# internal `_svd_rotation`), so loadings parity is checked under the SAME
# rotation the bridge applies. Used where `getLoadings`/`rotation` lack a method
# for the fit type (e.g. MixedFamilyFit).
function _canonical_rotation(Λ::AbstractMatrix)
    F = svd(Λ)
    V = Matrix(F.V)
    ΛV = Λ * V
    @inbounds for k in 1:size(V, 2)
        idx = argmax(abs.(@view ΛV[:, k]))
        ΛV[idx, k] < 0 && (@views V[:, k] .= .-V[:, k])
    end
    return V
end

# Required contract keys present on every bridge_fit return.
const _BRIDGE_KEYS = (:family, :families, :model, :d, :n_traits, :n_units,
    :trait_names, :unit_names, :loadings, :alpha, :dispersion, :sigma_eps,
    :Sigma, :correlation, :communality, :scores, :loglik, :aic, :bic, :df,
    :nobs, :converged, :iterations, :message, :link, :note)

function _assert_contract(res, p, n, K)
    for k in _BRIDGE_KEYS
        @test haskey(res, k)
    end
    # Every value marshals cleanly through JuliaCall (no custom structs).
    for k in keys(res)
        @test _is_juliacall_safe(getfield(res, k))
    end
    @test res.n_traits == p
    @test res.n_units == n
    @test res.d == K
    @test size(res.loadings) == (p, K)
    @test length(res.alpha) == p
    @test length(res.dispersion) == p
    @test size(res.Sigma) == (p, p)
    @test size(res.correlation) == (p, p)
    @test length(res.communality) == p
    @test length(res.families) == p
    @test length(res.trait_names) == p
    @test length(res.unit_names) == n
    @test isfinite(res.loglik)
    # correlation is a valid correlation matrix (unit diagonal, symmetric, in range).
    @test all(isapprox.(diag(res.correlation), 1.0; atol = 1e-8))
    @test res.correlation ≈ res.correlation'
    @test all(-1 - 1e-8 .<= res.correlation .<= 1 + 1e-8)
end

@testset "bridge_fit contract + parity" begin

    @testset "gaussian: contract + parity to direct fit" begin
        rng = MersenneTwister(11)
        p, n, K = 5, 80, 2
        Λtrue = randn(rng, p, K)
        Z = randn(rng, K, n)
        Y = Λtrue * Z .+ 0.4 .* randn(rng, p, n) .+ [1.0, -2.0, 0.5, 3.0, 0.0]

        res = bridge_fit(; y = Y, family = "gaussian", d = K)
        _assert_contract(res, p, n, K)
        @test res.family == "gaussian"
        @test all(res.families .== "gaussian")
        @test isfinite(res.sigma_eps)
        @test size(res.scores) == (n, K)

        # Direct fit on the SAME centred matrix the bridge fits.
        alpha = vec(mean(Y; dims = 2))
        Yc = Y .- alpha
        direct = fit_gaussian_gllvm(Yc; K = K)
        @test res.loglik ≈ direct.logLik atol = 1e-8
        @test res.alpha ≈ alpha atol = 1e-10
        @test res.sigma_eps ≈ direct.pars.σ_eps atol = 1e-8
        # Rotated loadings match (same canonical SVD rotation on both sides).
        @test res.loadings ≈ getLoadings(direct; rotate = true) atol = 1e-7
    end

    @testset "poisson: contract + parity to direct fit" begin
        rng = MersenneTwister(22)
        p, n, K = 4, 90, 1
        β = [0.5, 1.0, -0.5, 0.2]
        Λtrue = 0.6 .* randn(rng, p, K)
        Z = randn(rng, K, n)
        η = β .+ Λtrue * Z
        Y = [rand(rng, Poisson(exp(clamp(η[t, i], -8, 8)))) for t in 1:p, i in 1:n]

        res = bridge_fit(; y = Y, family = "poisson", d = K)
        _assert_contract(res, p, n, K)
        @test res.family == "poisson"
        @test all(isnan, res.dispersion)            # Poisson carries no dispersion
        @test size(res.scores) == (n, K)

        direct = fit_poisson_gllvm(round.(Int, Y); K = K)
        @test res.loglik ≈ direct.loglik atol = 1e-8
        @test res.alpha ≈ direct.β atol = 1e-8
        @test res.loadings ≈ getLoadings(direct; rotate = true) atol = 1e-7
    end

    @testset "mixed [gaussian, poisson, binomial]: contract + correlation + parity" begin
        rng = MersenneTwister(33)
        p, n, K = 3, 120, 1
        β = [0.0, 0.5, 0.2]
        Λtrue = reshape([1.0, 0.8, -0.7], p, K)
        Z = randn(rng, K, n)
        η = β .+ Λtrue * Z
        Y = Matrix{Float64}(undef, p, n)
        for i in 1:n
            Y[1, i] = η[1, i] + 0.3 * randn(rng)                       # gaussian
            Y[2, i] = rand(rng, Poisson(exp(clamp(η[2, i], -8, 8))))    # poisson
            Y[3, i] = rand(rng, Bernoulli(1 / (1 + exp(-η[3, i]))))     # binomial
        end

        fams = ["gaussian", "poisson", "binomial"]
        res = bridge_fit(; y = Y, family = fams, d = K)
        _assert_contract(res, p, n, K)
        @test res.family == "mixed"
        @test res.families == fams
        @test size(res.scores) == (n, K)
        # (4) the mixed return includes a correlation matrix.
        @test res.correlation isa AbstractMatrix
        @test size(res.correlation) == (p, p)

        # Parity: same mixed fit, marshalled. fit_mixed_gllvm takes Distributions
        # markers; the bridge builds the same ones from the strings.
        markers = [Normal(), Poisson(), Binomial()]
        direct = fit_mixed_gllvm(Y; families = markers, K = K)
        @test res.loglik ≈ direct.loglik atol = 1e-8
        # getLoadings(::MixedFamilyFit) has no _loadings method, so rotate the raw
        # Λ with the same canonical rotation the bridge applies.
        direct_loadings = direct.Λ * _canonical_rotation(direct.Λ)
        @test res.loadings ≈ direct_loadings atol = 1e-7
        @test res.alpha ≈ direct.β atol = 1e-8
        # The cross-family correlation matches the direct extractor.
        @test res.correlation ≈ correlation(direct, Y) atol = 1e-7
    end

end
