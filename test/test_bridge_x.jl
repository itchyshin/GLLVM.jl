# Bridge fixed-effect covariates (X) for the one-part NON-Gaussian families:
# Poisson/Binomial → `fit_gllvm_cov`; NB2/Beta/Gamma → per-trait
# `fit_*_gllvm_grouped_cov` (twin API B under X). Bridge coefficients must equal
# the matching native oracle to ~1e-8. Gaussian-X preserves existing fields while
# exposing the full mean coefficient payload needed by the R bridge.
#
# Gates encoded here:
#   1. PARITY  — bridge-X coefficients == native oracle (~1e-8).
#   2. FLAT CONTRACT — the new coef fields (alpha, beta_cov, gamma, dispersion,
#                loadings, …) are primitive Float64 arrays.
#   3. GAUSSIAN-X — bridge_fit gaussian + X preserves existing fields and returns
#                the full mean coefficient vector needed by the R bridge.
#   4. UNSUPPORTED — remaining X fences (e.g. mixed-family X; CI under ordinal+X) and
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
    # -- PARITY: bridge-X coefficients == native oracle (~1e-8) ----------------
    @testset "coefficient parity vs native X fitter" begin
        shared_cases = [
            ("poisson",  Poisson(),  (p = 5, n = 80, K = 1, q = 1), nothing),
            ("binomial", Binomial(), (p = 5, n = 80, K = 1, q = 1), 6),
        ]
        for (key, marker, dims, Ntrial) in shared_cases
            @testset "$key" begin
                Y, X = _bx_sim(marker, dims.p, dims.n, dims.K, dims.q;
                               seed = 100 + dims.p, Ntrial = Ntrial === nothing ? 1 : Ntrial)
                Nm = key == "binomial" ? fill(Ntrial, dims.p, dims.n) : nothing
                oracle = Nm === nothing ?
                    GLLVM.fit_gllvm_cov(Y; family = marker, X = X, K = dims.K) :
                    GLLVM.fit_gllvm_cov(Y; family = marker, X = X, K = dims.K, N = Nm)
                br = bridge_fit(; y = Y, family = key, d = dims.K, N = Nm, X = X)
                @test br.gamma ≈ oracle.γ atol = 1e-8
                @test br.beta_cov ≈ oracle.β atol = 1e-8
                @test br.alpha ≈ oracle.β atol = 1e-8
                @test br.loadings ≈ GLLVM.getLoadings(oracle; rotate = true) atol = 1e-8
                @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
                if isnan(oracle.dispersion)
                    @test all(isnan, br.dispersion)
                else
                    @test all(d -> isapprox(d, oracle.dispersion; atol = 1e-8), br.dispersion)
                end
            end
        end

        @testset "negbinomial (per-trait grouped_cov)" begin
            Y, X = _bx_sim(NegativeBinomial(), 4, 80, 1, 1; seed = 104)
            Yi = round.(Int, Y)
            oracle = GLLVM.fit_nb_gllvm_grouped_cov(Yi; X = X, K = 1, group = collect(1:4))
            br = bridge_fit(; y = Y, family = "negbinomial", d = 1, X = X)
            @test br.gamma ≈ oracle.γ atol = 1e-8
            @test br.beta_cov ≈ oracle.β atol = 1e-8
            @test br.alpha ≈ oracle.β atol = 1e-8
            @test br.loadings ≈ GLLVM.getLoadings(oracle; rotate = true) atol = 1e-8
            @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
            disp_true = [oracle.r_group[oracle.group[t]] for t in 1:4]
            @test br.dispersion ≈ disp_true atol = 1e-8
        end

        @testset "beta (per-trait grouped_cov)" begin
            Y, X = _bx_sim(Beta(), 4, 80, 1, 1; seed = 105)
            oracle = GLLVM.fit_beta_gllvm_grouped_cov(Y; X = X, K = 1, group = collect(1:4))
            br = bridge_fit(; y = Y, family = "beta", d = 1, X = X)
            @test br.gamma ≈ oracle.γ atol = 1e-8
            @test br.beta_cov ≈ oracle.β atol = 1e-8
            @test br.alpha ≈ oracle.β atol = 1e-8
            @test br.loadings ≈ GLLVM.getLoadings(oracle; rotate = true) atol = 1e-8
            @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
            disp_true = [oracle.φ[oracle.group[t]] for t in 1:4]
            @test br.dispersion ≈ disp_true atol = 1e-8
        end

        @testset "gamma (per-trait grouped_cov)" begin
            Y, X = _bx_sim(Gamma(), 4, 80, 1, 1; seed = 106)
            oracle = GLLVM.fit_gamma_gllvm_grouped_cov(Y; X = X, K = 1, group = collect(1:4))
            br = bridge_fit(; y = Y, family = "gamma", d = 1, X = X)
            @test br.gamma ≈ oracle.γ atol = 1e-8
            @test br.beta_cov ≈ oracle.β atol = 1e-8
            @test br.alpha ≈ oracle.β atol = 1e-8
            @test br.loadings ≈ GLLVM.getLoadings(oracle; rotate = true) atol = 1e-8
            @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
            disp_true = [oracle.α[oracle.group[t]] for t in 1:4]
            @test br.dispersion ≈ disp_true atol = 1e-8
        end

        @testset "betabinomial (per-trait grouped_cov)" begin
            Random.seed!(109)
            p, n, K, q = 4, 90, 1, 1
            β = 0.2 .* randn(p); γ = [0.4]; Λ = 0.3 .* randn(p, K)
            x1 = randn(n)
            X = _bridge_x_design([x1], p)
            O = GLLVM._build_offset(X, γ)
            Z = randn(K, n)
            η = β .+ O .+ Λ * Z
            φ = 9.0
            Nt = fill(6, p, n)
            Y = Matrix{Float64}(undef, p, n)
            for t in 1:p, s in 1:n
                μ = clamp(1 / (1 + exp(-clamp(η[t, s], -6, 6))), 1e-3, 1 - 1e-3)
                a = μ * φ; b = (1 - μ) * φ
                pr = clamp(rand(Distributions.Beta(a, b)), 1e-6, 1 - 1e-6)
                Y[t, s] = float(rand(Distributions.Binomial(Nt[t, s], pr)))
            end
            oracle = GLLVM.fit_beta_binomial_gllvm_grouped_cov(Y; X = X, K = K, N = Nt,
                                                               group = collect(1:p))
            br = bridge_fit(; y = Y, family = "betabinomial", d = K, N = Nt, X = X)
            @test br.gamma ≈ oracle.γ atol = 1e-8
            @test br.beta_cov ≈ oracle.β atol = 1e-8
            @test br.alpha ≈ oracle.β atol = 1e-8
            @test br.loadings ≈ GLLVM.getLoadings(oracle; rotate = true) atol = 1e-8
            @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
            disp_true = [oracle.φ[oracle.group[t]] for t in 1:p]
            @test br.dispersion ≈ disp_true atol = 1e-8
        end

        @testset "ordinal (per-trait cutpoint cov)" begin
            Random.seed!(107)
            p, n, K, q, C = 4, 70, 1, 1, 3
            β = 0.2 .* randn(p); γ = [0.45]; Λ = 0.3 .* randn(p, K)
            X = randn(p, n, q)
            O = GLLVM._build_offset(X, γ)
            Z = randn(K, n)
            η = β .+ O .+ Λ * Z
            Y = Matrix{Float64}(undef, p, n)
            for t in 1:p, s in 1:n
                η_ts = clamp(η[t, s], -5, 5)
                u = rand()
                y = C
                for c in 1:(C - 1)
                    τc = c == 1 ? 0.0 : 1.1
                    if u <= GLLVM._ord_F(τc - η_ts, LogitLink())
                        y = c; break
                    end
                end
                Y[t, s] = float(y)
            end
            Yi = round.(Int, Y)
            oracle = GLLVM.fit_ordinal_gllvm_pertrait_cov(Yi; X = X, K = 1)
            br = bridge_fit(; y = Y, family = "ordinal", d = 1, X = X)
            @test br.gamma ≈ oracle.γ atol = 1e-8
            @test br.beta_cov ≈ oracle.β atol = 1e-8
            @test br.alpha ≈ oracle.β atol = 1e-8
            @test br.loadings ≈ GLLVM.getLoadings(oracle; rotate = true) atol = 1e-8
            @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
            @test br.cutpoint_mode == "per_trait"
            @test br.cutpoints ≈ oracle.τ atol = 1e-8
            @test br.n_categories == oracle.C
        end

        @testset "zip (dual-γ ZIPCovFit; Julia-forward)" begin
            Random.seed!(108)
            p, n, K, q = 3, 55, 1, 1
            βz = 0.3 .* randn(p) .- 0.7
            γz = [0.3]; βc = 0.2 .* randn(p) .+ 0.5; γc = [0.4]
            Λc = 0.25 .* randn(p, K)
            X = randn(p, n, q)
            Oz = GLLVM._build_offset(X, γz); Oc = GLLVM._build_offset(X, γc)
            Z = randn(K, n)
            Y = Matrix{Float64}(undef, p, n)
            for t in 1:p, s in 1:n
                π = 1 / (1 + exp(-(βz[t] + Oz[t, s])))
                μ = exp(clamp(βc[t] + Oc[t, s] + (Λc * Z)[t, s], -4, 4))
                Y[t, s] = rand() < π ? 0.0 : float(rand(Poisson(μ)))
            end
            Yi = round.(Int, Y)
            oracle = GLLVM.fit_zip_gllvm_cov(Yi; X = X, K = K, iterations = 120)
            br = bridge_fit(; y = Y, family = "zip", d = K, X = X)
            @test br.family == "zip"
            @test br.model == "zip_x_rr"
            @test br.gamma ≈ oracle.γc atol = 1e-8
            @test br.gamma_z ≈ oracle.γz atol = 1e-8
            @test br.gamma_c ≈ oracle.γc atol = 1e-8
            @test br.beta_zero ≈ oracle.βz atol = 1e-8
            @test br.beta_cov ≈ oracle.βc atol = 1e-8
            @test br.alpha ≈ oracle.βc atol = 1e-8
            @test br.loadings ≈ GLLVM.getLoadings(oracle; rotate = true) atol = 1e-8
            @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
            @test occursin("Julia-forward", br.note)
            @test occursin("twin", lowercase(br.note))
            @test !occursin("parity vs gllvmTMB", br.note)
        end
    end

    # -- CI ROUTING: bridge-X CI payloads == native confint oracles -------------
    @testset "X-row CI payloads" begin
        shared_cases = [
            ("poisson",  Poisson(),  (p = 4, n = 70, K = 1, q = 1), nothing),
            ("binomial", Binomial(), (p = 4, n = 70, K = 1, q = 1), 6),
        ]
        for (key, marker, dims, Ntrial) in shared_cases
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

        @testset "negbinomial Wald (grouped_cov)" begin
            Y, X = _bx_sim(NegativeBinomial(), 3, 70, 1, 1; seed = 523)
            Yi = round.(Int, Y)
            oracle = GLLVM.fit_nb_gllvm_grouped_cov(Yi; X = X, K = 1, group = collect(1:3))
            nat = GLLVM.confint(oracle, Yi; method = :wald, X = X)
            br = bridge_fit(; y = Y, family = "negbinomial", d = 1, X = X,
                            options = Dict("ci_method" => "wald"))
            @test br.ci_method == "wald"
            @test any(==("gamma[1]"), br.ci_param_names)
            d = _bx_ci_max_absdiff(br.ci_param_names, br.ci_lower, br.ci_upper,
                                   nat.term, nat.lower, nat.upper)
            @test d < 1e-8
        end

        @testset "beta Wald (grouped_cov)" begin
            Y, X = _bx_sim(Beta(), 3, 70, 1, 1; seed = 524)
            oracle = GLLVM.fit_beta_gllvm_grouped_cov(Y; X = X, K = 1, group = collect(1:3))
            nat = GLLVM.confint(oracle, Y; method = :wald, X = X)
            br = bridge_fit(; y = Y, family = "beta", d = 1, X = X,
                            options = Dict("ci_method" => "wald"))
            @test br.ci_method == "wald"
            @test any(==("gamma[1]"), br.ci_param_names)
            d = _bx_ci_max_absdiff(br.ci_param_names, br.ci_lower, br.ci_upper,
                                   nat.term, nat.lower, nat.upper)
            @test d < 1e-8
        end

        @testset "gamma Wald (grouped_cov)" begin
            Y, X = _bx_sim(Gamma(), 3, 70, 1, 1; seed = 525)
            oracle = GLLVM.fit_gamma_gllvm_grouped_cov(Y; X = X, K = 1, group = collect(1:3))
            nat = GLLVM.confint(oracle, Y; method = :wald, X = X)
            br = bridge_fit(; y = Y, family = "gamma", d = 1, X = X,
                            options = Dict("ci_method" => "wald"))
            @test br.ci_method == "wald"
            @test any(==("gamma[1]"), br.ci_param_names)
            d = _bx_ci_max_absdiff(br.ci_param_names, br.ci_lower, br.ci_upper,
                                   nat.term, nat.lower, nat.upper)
            @test d < 1e-8
        end

        @testset "betabinomial Wald (grouped_cov)" begin
            Random.seed!(526)
            p, n, K, q, Ntr = 3, 70, 1, 1, 6
            β = 0.2 .* randn(p); γ = [0.4]; Λ = 0.3 .* randn(p, K)
            x1 = randn(n)
            X = _bridge_x_design([x1], p)
            O = GLLVM._build_offset(X, γ)
            Z = randn(K, n)
            η = β .+ O .+ Λ * Z
            φ = 9.0
            Nt = fill(Ntr, p, n)
            Y = Matrix{Float64}(undef, p, n)
            for t in 1:p, s in 1:n
                μ = clamp(1 / (1 + exp(-clamp(η[t, s], -6, 6))), 1e-3, 1 - 1e-3)
                a = μ * φ; b = (1 - μ) * φ
                pr = clamp(rand(Distributions.Beta(a, b)), 1e-6, 1 - 1e-6)
                Y[t, s] = float(rand(Distributions.Binomial(Nt[t, s], pr)))
            end
            oracle = GLLVM.fit_beta_binomial_gllvm_grouped_cov(Y; X = X, K = K, N = Nt,
                                                               group = collect(1:p))
            nat = GLLVM.confint(oracle, Y; method = :wald, X = X, N = Nt)
            br = bridge_fit(; y = Y, family = "betabinomial", d = K, N = Nt, X = X,
                            options = Dict("ci_method" => "wald"))
            @test br.ci_method == "wald"
            @test any(==("gamma[1]"), br.ci_param_names)
            d = _bx_ci_max_absdiff(br.ci_param_names, br.ci_lower, br.ci_upper,
                                   nat.term, nat.lower, nat.upper)
            @test d < 1e-8
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

    @testset "coef_fixed bridge option fixes Gaussian β / non-Gaussian γ to zero" begin
        Random.seed!(333)
        p, n, K = 4, 55, 1
        x1 = randn(n); x2 = randn(n)
        X = _bridge_x_design([x1, x2], p)
        Yg = randn(p, n) .+ 0.6 .* reshape(x1, 1, n)

        brg = bridge_fit(; y = Yg, family = "gaussian", d = K, X = X,
                         options = Dict("coef_fixed" => [false, true]))
        brg_drop = bridge_fit(; y = Yg, family = "gaussian", d = K,
                              X = X[:, :, 1:1])
        @test brg.mean_coef[2] == 0.0
        @test brg.mean_coef_status == ["estimated", "fixed"]
        @test brg.mean_coef[1] ≈ brg_drop.mean_coef[1] atol = 1e-10
        @test brg.loglik ≈ brg_drop.loglik atol = 1e-10
        @test brg.df == brg_drop.df

        Yp = [rand(Poisson(exp(clamp(0.2 + 0.5 * x1[s], -5, 4)))) for t in 1:p, s in 1:n]
        brp = bridge_fit(; y = Float64.(Yp), family = "poisson", d = K, X = X,
                         options = Dict("coef_fixed" => [false, true]))
        brp_drop = bridge_fit(; y = Float64.(Yp), family = "poisson", d = K,
                              X = X[:, :, 1:1])
        @test brp.gamma[2] == 0.0
        @test brp.gamma_status == ["estimated", "fixed"]
        @test brp.gamma[1] ≈ brp_drop.gamma[1] atol = 1e-8
        @test brp.loglik ≈ brp_drop.loglik atol = 1e-8
        @test brp.df == brp_drop.df
    end

    # -- UNSUPPORTED X combos reject loudly --------------------------------------
    @testset "unsupported X combos error" begin
        # ordinal+X is wired; CI under X remains fenced (same as no-X per-trait)
        Yo = Float64.(rand(1:3, 3, 40))
        Xo = randn(3, 40, 1)
        @test_throws ArgumentError bridge_fit(; y = Yo, family = "ordinal", d = 1, X = Xo,
                                              options = Dict("ci_method" => "wald"))
        # zip+X point fit wired; CI under X fenced (Rung 2 not DoD)
        Yz = Float64.(rand(0:4, 3, 40))
        Xz = randn(3, 40, 1)
        @test_throws ArgumentError bridge_fit(; y = Yz, family = "zip", d = 1, X = Xz,
                                              options = Dict("ci_method" => "wald"))
        brz = bridge_fit(; y = Yz, family = "zip", d = 1, X = Xz,
                         options = Dict("ci_method" => "none"))
        @test brz.converged isa Bool
        @test length(brz.gamma) == 1
        @test length(brz.gamma_z) == 1
        # nb1: twin API B under X (per-trait φ + shared γ)
        Yn = Float64.(rand(0:5, 3, 40))
        Xn = randn(3, 40, 1)
        brn = bridge_fit(; y = Yn, family = "nb1", d = 1, X = Xn,
                         options = Dict("ci_method" => "none"))
        @test brn.converged isa Bool
        @test length(brn.gamma) == 1
        @test length(brn.dispersion) == 3
        # betabinomial: point fit under X converges; CI is now routed (FD Hessian).
        Ybb = Float64.(rand(0:6, 3, 40))
        Xbb = randn(3, 40, 1)
        Nbb = fill(6, 3, 40)
        brbb = bridge_fit(; y = Ybb, family = "betabinomial", d = 1, N = Nbb, X = Xbb,
                          options = Dict("ci_method" => "none"))
        @test brbb.converged isa Bool
        @test length(brbb.gamma) == 1
        @test length(brbb.dispersion) == 3
        @test !(:ci_method in keys(brbb))
        # mixed-family X still unsupported
        Ym = randn(2, 30)
        Xm = randn(2, 30, 1)
        @test_throws ArgumentError bridge_fit(; y = Ym, family = ["gaussian", "poisson"],
                                              d = 1, X = Xm)
    end
end
