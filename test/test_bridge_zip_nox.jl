# ZIP bridge, NO-X arm — regression cover for a route that had never been fitted.
#
# Every pre-existing ZIP bridge test drives the +X arm (test_bridge_x.jl), so the
# no-X arm shipped assembling through `_bridge_assemble_ng`, which reads `fit.link`.
# `ZIPFit` has no `link` field, so `bridge_fit(; family = "zip")` without X threw
# `type ZIPFit has no field link` before any contract check could run. ZINB and ZIB
# avoided this by assembling directly. This file pins the no-X route so the arm
# cannot silently regress again.
#
# Twin fence: the twin gllvmTMB cut ZIP, so there is no light RCall Δ to run and
# none may be invented. No parity, ADEMP, or coverage claim is made or tested here.

using Test
using Random
using LinearAlgebra
using Distributions
using GLLVM

# Zero-inflated Poisson draw: structural zeros at logit(βz), counts at log(βc + Λc z).
function _bzip_sim(p, n, K; seed = 1)
    Random.seed!(seed)
    βz = 0.4 .* randn(p) .- 0.8
    βc = 0.5 .* randn(p) .+ 1.2
    Λc = 0.3 .* randn(p, K)
    Z = randn(K, n)
    ΛZ = Λc * Z
    Y = Matrix{Int}(undef, p, n)
    for t in 1:p, s in 1:n
        πz = 1 / (1 + exp(-βz[t]))
        μ = exp(βc[t] + ΛZ[t, s])
        Y[t, s] = rand() < πz ? 0 : rand(Poisson(μ))
    end
    return Y, βz, βc, Λc
end

# Max |Δ| between two CI tables matched by term name.
function _bzip_ci_max_absdiff(names_a, lo_a, hi_a, names_b, lo_b, hi_b)
    d = 0.0
    for (i, nm) in enumerate(names_a)
        j = findfirst(==(nm), names_b)
        j === nothing && continue
        d = max(d, abs(lo_a[i] - lo_b[j]), abs(hi_a[i] - hi_b[j]))
    end
    return d
end

@testset "ZIP bridge (no-X)" begin

    Y, _, _, _ = _bzip_sim(3, 40, 1; seed = 7301)
    Yf = Float64.(Y)

    @testset "no-X point route matches fit_zip_gllvm" begin
        oracle = fit_zip_gllvm(Y; K = 1)
        br = bridge_fit(; y = Yf, family = "zip", d = 1)

        @test br.family == "zip"
        @test br.model == "zip_rr"
        @test br.families == fill("zip", 3)
        @test br.d == 1
        @test br.n_traits == 3
        @test br.n_units == 40
        @test br.alpha ≈ oracle.βc atol = 1e-8
        @test br.beta_zero ≈ oracle.βz atol = 1e-8
        @test br.loadings ≈ GLLVM.getLoadings(oracle; rotate = true) atol = 1e-8
        @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
        @test br.df == GLLVM._nparams(oracle)
        @test all(isnan, br.dispersion)      # ZIP carries no dispersion parameter
        @test isnan(br.sigma_eps)
        # Same link naming as the ZIP+X arm (`_bridge_assemble_zip_cov`).
        @test br.link == fill("log", 3)
        @test size(br.Sigma) == (3, 3)
        @test size(br.correlation) == (3, 3)
        @test br.correlation ≈ br.correlation' atol = 1e-10
        @test all(isapprox(1.0), diag(br.correlation))
        @test br.communality == ones(3)      # shared-block fallback, stated in the note
        @test size(br.scores) == (40, 1)
        @test br.converged isa Bool
        @test br.nobs == 120

        # Note wording: honest about the shared-block Sigma and the twin fence.
        @test occursin("Julia-forward", br.note)
        @test occursin("twin-asymmetric", br.note)
        @test occursin("no twin light Δ", br.note)
        @test !occursin("parity", lowercase(br.note))

        # Aliases reach the same route.
        for alias in ("zipoisson", "zero_inflated_poisson", "zi_poisson", "ZIP")
            @test GLLVM._bridge_family_key(alias) == "zip"
        end
        br_alias = bridge_fit(; y = Yf, family = "zero_inflated_poisson", d = 1)
        @test br_alias.family == "zip"
        @test br_alias.loglik == br.loglik
    end

    @testset "no-X Wald CI matches native confint" begin
        Ys, _, _, _ = _bzip_sim(3, 35, 1; seed = 7302)
        oracle = fit_zip_gllvm(Ys; K = 1)
        nat = GLLVM.confint(oracle, Float64.(Ys); method = :wald)
        br = bridge_fit(; y = Float64.(Ys), family = "zip", d = 1,
                        options = Dict("ci_method" => "wald"))
        @test br.ci_method == "wald"
        @test br.ci_level == 0.95
        @test !isempty(br.ci_param_names)
        @test length(br.ci_lower) == length(br.ci_param_names)
        d = _bzip_ci_max_absdiff(br.ci_param_names, br.ci_lower, br.ci_upper,
                                 nat.term, nat.lower, nat.upper)
        println("ZIP bridge no-X Wald CI: max|Δ| vs native = $d (≤1e-8)")
        @test d ≤ 1e-8
        # Bounds are ordered wherever the observed information yielded finite ones;
        # a non-PD Hessian cell stays NaN rather than being faked.
        @test all(l <= u for (l, u) in zip(br.ci_lower, br.ci_upper)
                  if isfinite(l) && isfinite(u))
    end

    @testset "no-X masks still reject loudly" begin
        mask = trues(3, 40); mask[1, 1] = false
        @test_throws ArgumentError bridge_fit(; y = Yf, family = "zip", d = 1,
                                              mask = mask)
    end
end
