# Bridge confidence-interval routing: bridge_fit(...; ci_method=...) must return
# flat, JuliaCall-convertible CI arrays that EQUAL the native confint / profile_ci
# / bootstrap_ci on the equivalent native fit (the oracle). The default
# ci_method="none" must leave the bridge output byte-identical to before.
#
# Gates encoded here:
#   1. PARITY  — bridge-CI bounds == native-CI bounds (~1e-8 for wald/profile;
#                MC-tolerant + identical-seed exactness for bootstrap).
#   2. BACK-COMPAT — ci_method="none" returns exactly the pre-CI fields.
#   3. COVERAGE — Wald for every one-part family confint supports; profile +
#                bootstrap proven for Poisson + Gaussian.
#   4. FLAT CONTRACT — every CI field is a primitive String/Float64/array.

using Test
using GLLVM
using Random
using Statistics

# ---------------------------------------------------------------------------
# Small simulators (p traits × n units), reused across families.
# ---------------------------------------------------------------------------
function _bridge_ci_latent(p, n, K, seed)
    rng = Random.MersenneTwister(seed)
    Λ = 0.5 .* randn(rng, p, K)
    β = 0.3 .* randn(rng, p)
    Z = randn(rng, K, n)
    η = β .+ Λ * Z
    return Λ, β, Z, η
end

function _sim_gaussian(p, n, K; seed = 11)
    _, _, _, η = _bridge_ci_latent(p, n, K, seed)
    rng = Random.MersenneTwister(seed + 1000)
    return η .+ 0.4 .* randn(rng, p, n)
end

function _sim_poisson_bridge_ci(p, n, K; seed = 12)
    _, _, _, η = _bridge_ci_latent(p, n, K, seed)
    rng = Random.MersenneTwister(seed + 1000)
    Y = Matrix{Int}(undef, p, n)
    for i in eachindex(η)
        Y[i] = rand(rng, GLLVM.Poisson(exp(clamp(η[i], -8, 4))))
    end
    return Y
end

function _sim_binomial(p, n, K, Ntrial; seed = 13)
    _, _, _, η = _bridge_ci_latent(p, n, K, seed)
    rng = Random.MersenneTwister(seed + 1000)
    Y = Matrix{Int}(undef, p, n)
    for i in eachindex(η)
        pr = 1 / (1 + exp(-η[i]))
        Y[i] = rand(rng, GLLVM.Binomial(Ntrial, pr))
    end
    return Y
end

function _sim_nb(p, n, K; seed = 14, r = 5.0)
    _, _, _, η = _bridge_ci_latent(p, n, K, seed)
    rng = Random.MersenneTwister(seed + 1000)
    Y = Matrix{Int}(undef, p, n)
    for i in eachindex(η)
        μ = exp(clamp(η[i], -8, 4))
        pr = r / (r + μ)
        Y[i] = rand(rng, GLLVM.NegativeBinomial(r, pr))
    end
    return Y
end

function _sim_beta(p, n, K; seed = 15, φ = 8.0)
    _, _, _, η = _bridge_ci_latent(p, n, K, seed)
    rng = Random.MersenneTwister(seed + 1000)
    Y = Matrix{Float64}(undef, p, n)
    for i in eachindex(η)
        μ = 1 / (1 + exp(-η[i]))
        μ = clamp(μ, 1e-3, 1 - 1e-3)
        Y[i] = clamp(rand(rng, GLLVM.Beta(μ * φ, (1 - μ) * φ)), 1e-4, 1 - 1e-4)
    end
    return Y
end

function _sim_gamma(p, n, K; seed = 16, shape = 4.0)
    _, _, _, η = _bridge_ci_latent(p, n, K, seed)
    rng = Random.MersenneTwister(seed + 1000)
    Y = Matrix{Float64}(undef, p, n)
    for i in eachindex(η)
        μ = exp(clamp(η[i], -4, 4))
        Y[i] = rand(rng, GLLVM.Gamma(shape, μ / shape)) + 1e-6
    end
    return Y
end

function _sim_ordinal(p, n, K, C; seed = 17)
    _, _, _, η = _bridge_ci_latent(p, n, K, seed)
    rng = Random.MersenneTwister(seed + 1000)
    cut = collect(range(-1.5, 1.5; length = C - 1))
    Y = Matrix{Int}(undef, p, n)
    for j in 1:n, t in 1:p
        lp = η[t, j]
        probs = Float64[]
        prev = 0.0
        for c in 1:(C - 1)
            cur = 1 / (1 + exp(-(cut[c] - lp)))
            push!(probs, cur - prev)
            prev = cur
        end
        push!(probs, 1 - prev)
        u = rand(rng); acc = 0.0; lvl = C
        for c in 1:C
            acc += probs[c]
            if u <= acc
                lvl = c; break
            end
        end
        Y[t, j] = lvl
    end
    return Y
end

# NaN-aware structural equality (the flat contract carries NaN-valued arrays, so
# plain `==` would spuriously report inequality for byte-identical fits).
_nan_eq(a::Number, b::Number) = (a == b) || (isnan(a) && isnan(b))
_nan_eq(a::AbstractArray, b::AbstractArray) =
    size(a) == size(b) && all(_nan_eq(x, y) for (x, y) in zip(a, b))
_nan_eq(a, b) = a == b

# Compare two CI tables (term-keyed) at a tolerance, on shared terms.
function _ci_max_absdiff(a_terms, a_lo, a_hi, b_terms, b_lo, b_hi)
    maxd = 0.0
    for (i, t) in enumerate(a_terms)
        j = findfirst(==(t), b_terms)
        j === nothing && continue
        for (x, y) in ((a_lo[i], b_lo[j]), (a_hi[i], b_hi[j]))
            (isnan(x) && isnan(y)) && continue
            (isnan(x) || isnan(y)) && return Inf
            maxd = max(maxd, abs(x - y))
        end
    end
    return maxd
end

@testset "bridge CI routing" begin
    # -- BACKWARD COMPAT: ci_method="none" (default) is byte-identical ----------
    @testset "backward-compat (none == default)" begin
        Y = _sim_poisson_bridge_ci(4, 50, 1; seed = 21)
        base = bridge_fit(; y = Float64.(Y), family = "poisson", d = 1)
        none = bridge_fit(; y = Float64.(Y), family = "poisson", d = 1,
                          options = Dict("ci_method" => "none"))
        @test keys(base) == keys(none)
        for k in keys(base)
            @test _nan_eq(base[k], none[k])
        end
        # default really is "none": no ci_* fields leak into the default contract
        @test !(:ci_method in keys(base))
        @test !(:ci_lower in keys(base))
    end

    # -- PARITY (oracle): Wald, one-part families --------------------------------
    @testset "Wald parity vs native confint" begin
        # Gaussian
        Yg = _sim_gaussian(4, 60, 1; seed = 22)
        alpha = vec(mean(Yg; dims = 2)); Yc = Yg .- alpha
        gf = GLLVM.fit_gaussian_gllvm(Yc; K = 1)
        nat = GLLVM.confint(gf; y = Yc, level = 0.95)
        br = bridge_fit(; y = Yg, family = "gaussian", d = 1,
                        options = Dict("ci_method" => "wald"))
        @test br.ci_method == "wald"
        @test br.ci_level == 0.95
        d = _ci_max_absdiff(br.ci_param_names, br.ci_lower, br.ci_upper,
                            nat.term, nat.lower, nat.upper)
        @test d < 1e-8

        # Poisson
        Yp = _sim_poisson_bridge_ci(4, 60, 1; seed = 23)
        pf = GLLVM.fit_poisson_gllvm(Yp; K = 1)
        natp = GLLVM.confint(pf, Float64.(Yp); method = :wald, level = 0.95)
        brp = bridge_fit(; y = Float64.(Yp), family = "poisson", d = 1,
                         options = Dict("ci_method" => "wald"))
        dp = _ci_max_absdiff(brp.ci_param_names, brp.ci_lower, brp.ci_upper,
                             natp.term, natp.lower, natp.upper)
        @test dp < 1e-8

        # Binomial
        Yb = _sim_binomial(4, 60, 1, 6; seed = 24)
        Nb = fill(6, size(Yb)...)
        bf = GLLVM.fit_binomial_gllvm(Yb; K = 1, N = Nb)
        natb = GLLVM.confint(bf, Float64.(Yb); method = :wald, level = 0.95, N = Nb)
        brb = bridge_fit(; y = Float64.(Yb), family = "binomial", d = 1, N = Nb,
                         options = Dict("ci_method" => "wald"))
        db = _ci_max_absdiff(brb.ci_param_names, brb.ci_lower, brb.ci_upper,
                             natb.term, natb.lower, natb.upper)
        @test db < 1e-8

        # Negative Binomial
        Yn = _sim_nb(4, 60, 1; seed = 25)
        nf = GLLVM.fit_nb_gllvm(Yn; K = 1)
        natn = GLLVM.confint(nf, Float64.(Yn); method = :wald, level = 0.95)
        brn = bridge_fit(; y = Float64.(Yn), family = "negbinomial", d = 1,
                         options = Dict("ci_method" => "wald"))
        dn = _ci_max_absdiff(brn.ci_param_names, brn.ci_lower, brn.ci_upper,
                             natn.term, natn.lower, natn.upper)
        @test dn < 1e-8

        # Beta
        Ybe = _sim_beta(4, 60, 1; seed = 26)
        bef = GLLVM.fit_beta_gllvm(Ybe; K = 1)
        natbe = GLLVM.confint(bef, Ybe; method = :wald, level = 0.95)
        brbe = bridge_fit(; y = Ybe, family = "beta", d = 1,
                          options = Dict("ci_method" => "wald"))
        dbe = _ci_max_absdiff(brbe.ci_param_names, brbe.ci_lower, brbe.ci_upper,
                              natbe.term, natbe.lower, natbe.upper)
        @test dbe < 1e-8

        # Gamma
        Yga = _sim_gamma(4, 60, 1; seed = 27)
        gaf = GLLVM.fit_gamma_gllvm(Yga; K = 1)
        natga = GLLVM.confint(gaf, Yga; method = :wald, level = 0.95)
        brga = bridge_fit(; y = Yga, family = "gamma", d = 1,
                          options = Dict("ci_method" => "wald"))
        dga = _ci_max_absdiff(brga.ci_param_names, brga.ci_lower, brga.ci_upper,
                              natga.term, natga.lower, natga.upper)
        @test dga < 1e-8

        # Ordinal
        Yo = _sim_ordinal(3, 70, 1, 3; seed = 28)
        of = GLLVM.fit_ordinal_gllvm(Yo; K = 1)
        nato = GLLVM.confint(of, Float64.(Yo); method = :wald, level = 0.95)
        bro = bridge_fit(; y = Float64.(Yo), family = "ordinal", d = 1,
                         options = Dict("ci_method" => "wald"))
        dorr = _ci_max_absdiff(bro.ci_param_names, bro.ci_lower, bro.ci_upper,
                               nato.term, nato.lower, nato.upper)
        @test dorr < 1e-8
    end

    # -- PARITY: profile (Poisson + Gaussian) -----------------------------------
    @testset "profile parity vs native" begin
        # Poisson: native vector profile
        Yp = _sim_poisson_bridge_ci(3, 60, 1; seed = 31)
        pf = GLLVM.fit_poisson_gllvm(Yp; K = 1)
        natp = GLLVM.confint(pf, Float64.(Yp); method = :profile, level = 0.95)
        brp = bridge_fit(; y = Float64.(Yp), family = "poisson", d = 1,
                         options = Dict("ci_method" => "profile"))
        @test brp.ci_method == "profile"
        dp = _ci_max_absdiff(brp.ci_param_names, brp.ci_lower, brp.ci_upper,
                             natp.term, natp.lower, natp.upper)
        @test dp < 1e-6

        # Gaussian: native per-parameter profile_ci, looped over all terms
        Yg = _sim_gaussian(3, 60, 1; seed = 32)
        alpha = vec(mean(Yg; dims = 2)); Yc = Yg .- alpha
        gf = GLLVM.fit_gaussian_gllvm(Yc; K = 1)
        nterm = length(gf.pars.θ_packed)
        nat_lo = Float64[]; nat_hi = Float64[]
        for i in 1:nterm
            pc = GLLVM.profile_ci(gf, i; y = Yc, level = 0.95)
            push!(nat_lo, pc.lower); push!(nat_hi, pc.upper)
        end
        brg = bridge_fit(; y = Yg, family = "gaussian", d = 1,
                         options = Dict("ci_method" => "profile"))
        @test length(brg.ci_lower) == nterm
        dg = 0.0
        for i in 1:nterm
            for (x, y) in ((brg.ci_lower[i], nat_lo[i]), (brg.ci_upper[i], nat_hi[i]))
                (isnan(x) && isnan(y)) && continue
                @test !(isnan(x) ⊻ isnan(y))
                isnan(x) || (dg = max(dg, abs(x - y)))
            end
        end
        @test dg < 1e-6
    end

    # -- PARITY: bootstrap (Poisson + Gaussian), fixed seed ----------------------
    @testset "bootstrap parity vs native (fixed seed)" begin
        nb = 40
        # Poisson
        Yp = _sim_poisson_bridge_ci(3, 50, 1; seed = 41)
        pf = GLLVM.fit_poisson_gllvm(Yp; K = 1)
        natp = GLLVM.confint(pf, Float64.(Yp); method = :bootstrap, level = 0.95,
                             n_boot = nb, seed = 7)
        brp = bridge_fit(; y = Float64.(Yp), family = "poisson", d = 1,
                         options = Dict("ci_method" => "bootstrap",
                                        "ci_nboot" => nb, "ci_seed" => 7))
        @test brp.ci_method == "bootstrap"
        dp = _ci_max_absdiff(brp.ci_param_names, brp.ci_lower, brp.ci_upper,
                             natp.term, natp.lower, natp.upper)
        # identical seed ⇒ identical replicates ⇒ identical percentiles
        @test dp < 1e-8

        # Gaussian
        Yg = _sim_gaussian(3, 50, 1; seed = 42)
        alpha = vec(mean(Yg; dims = 2)); Yc = Yg .- alpha
        gf = GLLVM.fit_gaussian_gllvm(Yc; K = 1)
        natg = GLLVM.bootstrap_ci(gf; y = Yc, n_boot = nb, level = 0.95, seed = 7)
        brg = bridge_fit(; y = Yg, family = "gaussian", d = 1,
                         options = Dict("ci_method" => "bootstrap",
                                        "ci_nboot" => nb, "ci_seed" => 7))
        dg = _ci_max_absdiff(brg.ci_param_names, brg.ci_lower, brg.ci_upper,
                             natg.term, natg.lower, natg.upper)
        @test dg < 1e-8
    end

    # -- FLAT CONTRACT: CI fields are JuliaCall-convertible primitives -----------
    @testset "flat CI contract" begin
        Yp = _sim_poisson_bridge_ci(3, 50, 1; seed = 51)
        br = bridge_fit(; y = Float64.(Yp), family = "poisson", d = 1,
                        options = Dict("ci_method" => "wald"))
        @test br.ci_method isa String
        @test br.ci_level isa Float64
        @test br.ci_param_names isa Vector{String}
        @test br.ci_estimate isa Vector{Float64}
        @test br.ci_lower isa Vector{Float64}
        @test br.ci_upper isa Vector{Float64}
        @test br.ci_note isa String
        @test length(br.ci_lower) == length(br.ci_param_names)
        @test length(br.ci_upper) == length(br.ci_param_names)
        @test length(br.ci_estimate) == length(br.ci_param_names)
        # custom level flows through
        br90 = bridge_fit(; y = Float64.(Yp), family = "poisson", d = 1,
                          options = Dict("ci_method" => "wald", "ci_level" => 0.90))
        @test br90.ci_level == 0.90
        @test all(br90.ci_upper .- br90.ci_lower .<= br.ci_upper .- br.ci_lower .+ 1e-9)
    end

    # -- Unsupported method errors loudly ---------------------------------------
    @testset "unsupported ci_method errors" begin
        Yp = _sim_poisson_bridge_ci(3, 40, 1; seed = 61)
        @test_throws ArgumentError bridge_fit(; y = Float64.(Yp), family = "poisson",
            d = 1, options = Dict("ci_method" => "garbage"))
    end
end
