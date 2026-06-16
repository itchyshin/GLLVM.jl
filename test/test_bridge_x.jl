# Bridge fixed-effect covariates (X) for the one-part NON-Gaussian families:
# bridge_fit(...; X=...) must route to the native `fit_gllvm_cov` and return the
# covariate coefficients (per-trait intercepts + shared γ) in flat,
# JuliaCall-convertible arrays that EQUAL the direct `fit_gllvm_cov` fit (the
# oracle) to ~1e-8. The Gaussian-X path must preserve existing fields while
# exposing the full mean coefficient payload needed by the R bridge.
#
# Gates encoded here:
#   1. PARITY  — bridge-X coefficients == native fit_gllvm_cov coefficients (~1e-8)
#                for Poisson + Binomial (+ NB/Beta/Gamma, all families
#                fit_gllvm_cov supports).
#   2. FLAT CONTRACT — the new coef fields (alpha, beta_cov, gamma, dispersion,
#                loadings, …) are primitive Float64 arrays.
#   3. GAUSSIAN-X — bridge_fit gaussian + X preserves existing fields and returns
#                the full mean coefficient vector needed by the R bridge.
#   4. UNSUPPORTED — families fit_gllvm_cov can't fit with X (ordinal, nb1) and
#                mixed-family X reject loudly with an ArgumentError.

using Test
using GLLVM
using Random
using Statistics
using Distributions

# Build a (p,n,q) design carrying q shared site covariates: X[t,s,k] = x[k][s].
function _bridge_x_design(xs::Vector{<:AbstractVector}, p::Integer)
    q = length(xs); n = length(xs[1])
    X = zeros(p, n, q)
    @inbounds for k in 1:q, t in 1:p, s in 1:n
        X[t, s, k] = xs[k][s]
    end
    return X
end

# NaN-aware structural equality (NaN-valued arrays appear in the flat contract).
_bx_nan_eq(a::Number, b::Number) = (a == b) || (isnan(a) && isnan(b))
_bx_nan_eq(a::AbstractArray, b::AbstractArray) =
    size(a) == size(b) && all(_bx_nan_eq(x, y) for (x, y) in zip(a, b))
_bx_nan_eq(a, b) = a == b

function _bx_ci_max_absdiff(n1, lo1, hi1, n2, lo2, hi2)
    @test n1 == n2
    d = 0.0
    for i in eachindex(n1)
        for (x, y) in ((lo1[i], lo2[i]), (hi1[i], hi2[i]))
            (isnan(x) && isnan(y)) && continue
            @test !(isnan(x) ⊻ isnan(y))
            isnan(x) || (d = max(d, abs(x - y)))
        end
    end
    return d
end

# Simulate one-part responses with a covariate-driven mean (η = β + Xγ + Λz).
function _bx_sim(family_marker, p, n, K, q; seed = 7, Ntrial = 1)
    rng = Random.MersenneTwister(seed)
    β = 0.3 .* randn(rng, p)
    γ = 0.6 .* randn(rng, q)
    Λ = 0.4 .* randn(rng, p, K)
    xs = [randn(rng, n) for _ in 1:q]
    X = _bridge_x_design(xs, p)
    O = GLLVM._build_offset(X, γ)
    Z = randn(rng, K, n)
    η = β .+ O .+ Λ * Z
    Y = Matrix{Float64}(undef, p, n)
    for t in 1:p, s in 1:n
        η_ts = clamp(η[t, s], -6, 4)
        if family_marker isa Poisson
            Y[t, s] = float(rand(rng, Poisson(exp(η_ts))))
        elseif family_marker isa Binomial
            pr = 1 / (1 + exp(-η_ts))
            Y[t, s] = float(rand(rng, Binomial(Ntrial, pr)))
        elseif family_marker isa NegativeBinomial
            r = 8.0; μ = exp(η_ts)
            Y[t, s] = float(rand(rng, NegativeBinomial(r, r / (r + μ))))
        elseif family_marker isa Beta
            φ = 8.0; μ = clamp(1 / (1 + exp(-η_ts)), 1e-3, 1 - 1e-3)
            Y[t, s] = clamp(rand(rng, Beta(μ * φ, (1 - μ) * φ)), 1e-4, 1 - 1e-4)
        elseif family_marker isa Gamma
            shp = 4.0; μ = exp(clamp(η_ts, -3, 3))
            Y[t, s] = rand(rng, Gamma(shp, μ / shp)) + 1e-6
        else
            error("unhandled family in _bx_sim")
        end
    end
    return Y, X
end

@testset "bridge fixed-effect X (non-Gaussian one-part families)" begin
    # -- PARITY: bridge-X coefficients == fit_gllvm_cov oracle (~1e-8) -----------
    @testset "coefficient parity vs fit_gllvm_cov" begin
        cases = [
            ("poisson",     Poisson(),          (p = 5, n = 80, K = 1, q = 1), nothing),
            ("binomial",    Binomial(),         (p = 5, n = 80, K = 1, q = 1), 6),
            ("negbinomial", NegativeBinomial(), (p = 4, n = 80, K = 1, q = 1), nothing),
            ("beta",        Beta(),             (p = 4, n = 80, K = 1, q = 1), nothing),
            ("gamma",       Gamma(),            (p = 4, n = 80, K = 1, q = 1), nothing),
        ]
        for (key, marker, dims, Ntrial) in cases
            @testset "$key" begin
                Y, X = _bx_sim(marker, dims.p, dims.n, dims.K, dims.q;
                               seed = 100 + dims.p, Ntrial = Ntrial === nothing ? 1 : Ntrial)
                Nm = key == "binomial" ? fill(Ntrial, dims.p, dims.n) : nothing
                # Oracle: direct fit_gllvm_cov on the SAME data.
                oracle = Nm === nothing ?
                    GLLVM.fit_gllvm_cov(Y; family = marker, X = X, K = dims.K) :
                    GLLVM.fit_gllvm_cov(Y; family = marker, X = X, K = dims.K, N = Nm)
                # Bridge: same data through bridge_fit with X.
                br = bridge_fit(; y = Y, family = key, d = dims.K, N = Nm, X = X)

                @test br.gamma ≈ oracle.γ atol = 1e-8         # the headline: env coefficients
                @test br.beta_cov ≈ oracle.β atol = 1e-8      # per-trait intercepts
                @test br.alpha ≈ oracle.β atol = 1e-8         # alpha mirrors the intercept
                @test br.loadings ≈ GLLVM.getLoadings(oracle; rotate = true) atol = 1e-8
                @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
                if isnan(oracle.dispersion)
                    @test all(isnan, br.dispersion)
                else
                    @test all(d -> isapprox(d, oracle.dispersion; atol = 1e-8), br.dispersion)
                end
            end
        end
    end

    # -- CI ROUTING: bridge-X CI payloads == native confint oracles -------------
    @testset "X-row CI payloads" begin
        cases = [
            ("poisson",     Poisson(),          (p = 4, n = 70, K = 1, q = 1), nothing),
            ("binomial",    Binomial(),         (p = 4, n = 70, K = 1, q = 1), 6),
            ("negbinomial", NegativeBinomial(), (p = 3, n = 70, K = 1, q = 1), nothing),
            ("beta",        Beta(),             (p = 3, n = 70, K = 1, q = 1), nothing),
            ("gamma",       Gamma(),            (p = 3, n = 70, K = 1, q = 1), nothing),
        ]
        for (key, marker, dims, Ntrial) in cases
            @testset "$key Wald" begin
                Y, X = _bx_sim(marker, dims.p, dims.n, dims.K, dims.q;
                               seed = 520 + dims.p, Ntrial = Ntrial === nothing ? 1 : Ntrial)
                Nm = key == "binomial" ? fill(Ntrial, dims.p, dims.n) : nothing
                oracle = Nm === nothing ?
                    GLLVM.fit_gllvm_cov(Y; family = marker, X = X, K = dims.K) :
                    GLLVM.fit_gllvm_cov(Y; family = marker, X = X, K = dims.K, N = Nm)
                nat = GLLVM.confint(oracle, Y; method = :wald, X = X, N = Nm)
                br = bridge_fit(; y = Y, family = key, d = dims.K, N = Nm, X = X,
                                options = Dict("ci_method" => "wald"))
                @test br.ci_method == "wald"
                @test br.ci_level == 0.95
                @test any(==("gamma[1]"), br.ci_param_names)
                d = _bx_ci_max_absdiff(br.ci_param_names, br.ci_lower, br.ci_upper,
                                       nat.term, nat.lower, nat.upper)
                @test d < 1e-8
            end
        end

        # Gaussian-X uses the Gaussian CI engines, which have a distinct
        # signature from the GllvmCovFit non-Gaussian path.
        Random.seed!(707)
        p, n, q, K = 3, 40, 1, 1
        Xg = randn(p, n, q)
        Yg = randn(p, n)
        gf = GLLVM.fit_gaussian_gllvm(Yg; K = K, X = Xg)
        natg = GLLVM.confint(gf; y = Yg, X = Xg, level = 0.95)
        brg = bridge_fit(; y = Yg, family = "gaussian", d = K, X = Xg,
                         options = Dict("ci_method" => "wald"))
        dg = _bx_ci_max_absdiff(brg.ci_param_names, brg.ci_lower, brg.ci_upper,
                                natg.term, natg.lower, natg.upper)
        @test dg < 1e-8

        # Profile/bootstrap are routed through the same native covariate CI
        # engines; use a tiny K=0 Poisson-X fixture to keep this test quick.
        Yp, Xp = _bx_sim(Poisson(), 2, 24, 0, 1; seed = 808)
        pf = GLLVM.fit_gllvm_cov(Yp; family = Poisson(), X = Xp, K = 0)
        nat_profile = GLLVM.confint(pf, Yp; method = :profile, X = Xp)
        br_profile = bridge_fit(; y = Yp, family = "poisson", d = 0, X = Xp,
                                options = Dict("ci_method" => "profile"))
        @test br_profile.ci_method == "profile"
        dp = _bx_ci_max_absdiff(br_profile.ci_param_names, br_profile.ci_lower,
                                br_profile.ci_upper, nat_profile.term,
                                nat_profile.lower, nat_profile.upper)
        @test dp < 1e-6

        br_boot = bridge_fit(; y = Yp, family = "poisson", d = 0, X = Xp,
                             options = Dict("ci_method" => "bootstrap",
                                            "ci_nboot" => 6,
                                            "ci_seed" => 41))
        @test br_boot.ci_method == "bootstrap"
        @test any(==("gamma[1]"), br_boot.ci_param_names)
        @test length(br_boot.ci_param_names) == length(br_boot.ci_estimate)
    end

    # -- FLAT CONTRACT: the coef fields are JuliaCall-convertible primitives ------
    @testset "flat coefficient contract" begin
        Y, X = _bx_sim(Poisson(), 5, 70, 1, 2; seed = 222)
        br = bridge_fit(; y = Y, family = "poisson", d = 1, X = X)
        @test br.gamma isa Vector{Float64}
        @test length(br.gamma) == size(X, 3)
        @test br.beta_cov isa Vector{Float64}
        @test length(br.beta_cov) == size(Y, 1)
        @test br.alpha isa Vector{Float64}
        @test br.loadings isa Matrix{Float64}
        @test br.dispersion isa Vector{Float64}
        @test br.family == "poisson"
        @test br.n_traits == size(Y, 1)
        @test br.n_units == size(Y, 2)
        @test br.loglik isa Float64
        @test br.converged isa Bool
        @test occursin("covariate", lowercase(br.note))
    end

    # -- GAUSSIAN-X: existing fields plus full mean coefficient vector -----------
    @testset "Gaussian-X mean coefficient payload" begin
        Random.seed!(303)
        p, n, q, K = 4, 50, 2, 1
        Xg = randn(p, n, q)
        Yg = randn(p, n)
        br = bridge_fit(; y = Yg, family = "gaussian", d = K, X = Xg)
        # Rebuild the expected Gaussian-X return from the public pieces (mirrors
        # the bridge's gaussian-X branch exactly).
        fit = GLLVM.fit_gaussian_gllvm(Yg; K = K, X = Xg)
        β = collect(Float64, fit.pars.β)
        alpha = zeros(Float64, p)
        for t in 1:p
            acc = 0.0
            for s in 1:n, k in 1:q
                acc += Xg[t, s, k] * β[k]
            end
            alpha[t] = acc / n
        end
        @test br.model == "gaussian_x_rr"
        @test br.mean_coef isa Vector{Float64}
        @test br.mean_coef ≈ β atol = 0
        @test _bx_nan_eq(br.alpha, alpha)
        @test isapprox(br.loglik, fit.logLik; atol = 0)
        @test br.sigma_eps == fit.pars.σ_eps
    end

    # -- UNSUPPORTED X combos reject loudly --------------------------------------
    @testset "unsupported X combos error" begin
        # ordinal: fit_gllvm_cov has no ordinal kernel
        Yo = Float64.(rand(1:3, 3, 30))
        Xo = randn(3, 30, 1)
        @test_throws ArgumentError bridge_fit(; y = Yo, family = "ordinal", d = 1, X = Xo)
        # nb1: fit_gllvm_cov has no nb1 kernel
        Yn = Float64.(rand(0:5, 3, 30))
        Xn = randn(3, 30, 1)
        @test_throws ArgumentError bridge_fit(; y = Yn, family = "nb1", d = 1, X = Xn)
        # mixed-family X still unsupported
        Ym = randn(2, 30)
        Xm = randn(2, 30, 1)
        @test_throws ArgumentError bridge_fit(; y = Ym, family = ["gaussian", "poisson"],
                                              d = 1, X = Xm)
    end
end
