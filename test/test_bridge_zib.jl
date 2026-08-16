# ZIB bridge admission — no-X only, under ACCEPTED Identity
# docs/dev-log/decisions/2026-08-16-zib-bridge-identity.md (B1–B5).
#
# What this file pins:
#   B1  "zib" is a real bridge family key (four aliases) and a one-part family,
#       but NOT an X family — X must still be rejected loudly.
#   B2  trials transport: ONE shared scalar N, REQUIRED at the boundary; a p×n N
#       is admitted only when uniform, then collapsed; unequal entries error
#       rather than silently taking N[1, 1]; `nothing` errors (N = 1 would be the
#       zero-inflated Bernoulli, where βz and βc are aliased).
#   B3  missing-response masks stay unwired (fit_zib_gllvm has no `mask` kwarg).
#   B4  no-X CI routes all three methods through _family_ci(::ZIBFit).
#   B5  capability row: cbind_binomial false, postfit_simulate false.
#
# Twin fence: gllvmTMB has NO ZIB, so there is no light RCall Δ to run and none
# may be invented. No parity, ADEMP, or coverage claim is made or tested here.

using Test
using Random
using LinearAlgebra
using Distributions
using GLLVM

# Zero-inflated binomial draw with a shared scalar trials count.
function _bzib_sim(p, n, K, N; seed = 1)
    Random.seed!(seed)
    βz = 0.4 .* randn(p) .- 0.8
    βc = 0.25 .* randn(p)
    Λc = 0.3 .* randn(p, K)
    Z = randn(K, n)
    ΛZ = Λc * Z
    Y = Matrix{Int}(undef, p, n)
    for t in 1:p, s in 1:n
        π = 1 / (1 + exp(-βz[t]))
        μ = 1 / (1 + exp(-(βc[t] + ΛZ[t, s])))
        Y[t, s] = rand() < π ? 0 : rand(Binomial(N, μ))
    end
    return Y, βz, βc, Λc
end

# Max |Δ| between two CI tables matched by term name.
function _bzib_ci_max_absdiff(names_a, lo_a, hi_a, names_b, lo_b, hi_b)
    d = 0.0
    for (i, nm) in enumerate(names_a)
        j = findfirst(==(nm), names_b)
        j === nothing && continue
        d = max(d, abs(lo_a[i] - lo_b[j]), abs(hi_a[i] - hi_b[j]))
    end
    return d
end

@testset "ZIB bridge admission (no-X)" begin

    # -- B1: family-key admission and list membership ---------------------------
    @testset "family key + list membership" begin
        for alias in ("zib", "zibinomial", "zero_inflated_binomial", "zi_binomial",
                      "ZIB", "  Zero_Inflated_Binomial  ")
            @test GLLVM._bridge_family_key(alias) == "zib"
        end
        @test "zib" in GLLVM._BRIDGE_ONEPART_FAMILIES
        # No-X only: the X arm is a separate arc gated on a +X CI engine.
        @test !("zib" in GLLVM._BRIDGE_X_FAMILIES)
        # ZIB's N is one shared scalar, NOT the per-observation cbind contract.
        @test !("zib" in GLLVM._BRIDGE_TRIALS_FAMILIES)
        # fit_zib_gllvm has no `mask` kwarg.
        @test !("zib" in GLLVM._BRIDGE_MASK_FAMILIES)
        @test !("zib" in GLLVM._BRIDGE_MASK_CI_FAMILIES)
        # No-X CI is real, so zib must NOT be fenced out of the CI columns.
        @test !("zib" in GLLVM._BRIDGE_NO_CI_FAMILIES)
        # No simulate(::ZIBFit) method exists — shared with zip/zinb.
        @test "zib" in GLLVM._BRIDGE_NO_SIMULATE_FAMILIES
        @test !hasmethod(GLLVM.simulate, Tuple{GLLVM.ZIBFit, Int})
    end

    # -- B2: trials normalisation, without running a fit ------------------------
    @testset "shared scalar trials contract" begin
        @test GLLVM._bridge_zib_trials(6, 3, 5) == 6
        @test GLLVM._bridge_zib_trials(6.0, 3, 5) == 6
        @test GLLVM._bridge_zib_trials(fill(6, 3, 5), 3, 5) == 6
        @test GLLVM._bridge_zib_trials(fill(6.0, 3, 5), 3, 5) == 6

        # N is REQUIRED: the binomial `nothing → 1` default would silently select
        # the zero-inflated Bernoulli, where (βz, βc) is exactly aliased.
        err = try
            GLLVM._bridge_zib_trials(nothing, 3, 5); nothing
        catch e
            e
        end
        @test err isa ArgumentError
        @test occursin("requires an explicit trials count N", err.msg)
        @test occursin("Bernoulli", err.msg)

        # Unequal entries error rather than collapsing to N[1, 1].
        Nbad = fill(6, 3, 5); Nbad[2, 3] = 7
        err2 = try
            GLLVM._bridge_zib_trials(Nbad, 3, 5); nothing
        catch e
            e
        end
        @test err2 isa ArgumentError
        @test occursin("ONE shared scalar trials count N", err2.msg)
        @test occursin("not the ZIB contract", err2.msg)

        @test_throws ArgumentError GLLVM._bridge_zib_trials(0, 3, 5)
        @test_throws ArgumentError GLLVM._bridge_zib_trials(fill(6, 2, 5), 3, 5)
    end

    # -- B1/B2: live no-X route vs the native fitter ----------------------------
    Ntr = 6
    Y, _, _, _ = _bzib_sim(3, 40, 1, Ntr; seed = 9401)
    Yf = Float64.(Y)

    @testset "no-X point route matches fit_zib_gllvm" begin
        oracle = fit_zib_gllvm(Y; K = 1, N = Ntr)
        br = bridge_fit(; y = Yf, family = "zib", d = 1, N = Ntr)

        @test br.family == "zib"
        @test br.model == "zib_rr"
        @test br.families == fill("zib", 3)
        @test br.d == 1
        @test br.n_traits == 3
        @test br.n_units == 40
        @test br.trials == Ntr
        @test br.alpha ≈ oracle.βc atol = 1e-8
        @test br.beta_zero ≈ oracle.βz atol = 1e-8
        @test br.loadings ≈ GLLVM.getLoadings(oracle; rotate = true) atol = 1e-8
        @test isapprox(br.loglik, oracle.loglik; atol = 1e-8)
        @test br.df == GLLVM._nparams(oracle)
        @test all(isnan, br.dispersion)      # ZIB carries no dispersion parameter
        @test isnan(br.sigma_eps)
        @test br.link == fill("LogitLink", 3)
        @test size(br.Sigma) == (3, 3)
        @test size(br.correlation) == (3, 3)
        @test br.correlation ≈ br.correlation' atol = 1e-10
        @test all(isapprox(1.0), diag(br.correlation))
        @test br.communality == ones(3)      # shared-block fallback, stated in the note
        @test size(br.scores) == (40, 1)
        @test br.converged isa Bool
        @test br.nobs == 120

        # Note wording: honest about the shared scalar N and the twin fence.
        @test occursin("Julia-forward", br.note)
        @test occursin("twin-asymmetric", br.note)
        @test occursin("shared scalar trials count N", br.note)
        @test occursin("not per-observation cbind", br.note)
        @test occursin("no twin light Δ", br.note)
        @test occursin("has no ZIB", br.note)
        @test !occursin("parity", lowercase(br.note))

        # A uniform p×n N is the R `cbind(success, failure)` call shape; it must
        # collapse to the same scalar fit, bit for bit.
        br_mat = bridge_fit(; y = Yf, family = "zib", d = 1, N = fill(Ntr, 3, 40))
        @test br_mat.trials == Ntr
        @test br_mat.loglik == br.loglik
        @test br_mat.alpha == br.alpha
        @test br_mat.beta_zero == br.beta_zero

        # Aliases reach the same route.
        br_alias = bridge_fit(; y = Yf, family = "zero_inflated_binomial", d = 1, N = Ntr)
        @test br_alias.family == "zib"
        @test br_alias.loglik == br.loglik
    end

    # -- B2/B3: the boundary rejects loudly, before any fit runs ----------------
    @testset "unsupported ZIB combos error" begin
        # N is required.
        @test_throws ArgumentError bridge_fit(; y = Yf, family = "zib", d = 1)
        # Non-uniform N is rejected rather than silently collapsed.
        Nbad = fill(Ntr, 3, 40); Nbad[1, 2] = Ntr + 1
        @test_throws ArgumentError bridge_fit(; y = Yf, family = "zib", d = 1, N = Nbad)
        # Responses must live in 0:N.
        Ybig = copy(Yf); Ybig[1, 1] = Ntr + 1
        @test_throws ArgumentError bridge_fit(; y = Ybig, family = "zib", d = 1, N = Ntr)
        # Masks are not wired (no `mask` kwarg on fit_zib_gllvm).
        mask = trues(3, 40); mask[1, 1] = false
        @test_throws ArgumentError bridge_fit(; y = Yf, family = "zib", d = 1, N = Ntr,
                                              mask = mask)
        # Fixed-effect X is a separate arc (gated on a +X CI engine).
        X = randn(3, 40, 1)
        @test_throws ArgumentError bridge_fit(; y = Yf, family = "zib", d = 1, N = Ntr,
                                              X = X)
        # X_lv is not wired either.
        @test_throws ArgumentError bridge_fit(; y = Yf, family = "zib", d = 1, N = Ntr,
                                              X_lv = randn(40, 1))
        # Per-trait mixed-family vectors still reject zib.
        @test_throws ArgumentError bridge_fit(; y = Yf, family = fill("zib", 3), d = 1,
                                              N = Ntr)
    end

    # -- B4: no-X Wald CI payload == the native confint oracle ------------------
    @testset "no-X Wald CI matches native confint" begin
        Ys, _, _, _ = _bzib_sim(3, 35, 1, Ntr; seed = 9402)
        oracle = fit_zib_gllvm(Ys; K = 1, N = Ntr)
        nat = GLLVM.confint(oracle, Float64.(Ys); method = :wald)
        br = bridge_fit(; y = Float64.(Ys), family = "zib", d = 1, N = Ntr,
                        options = Dict("ci_method" => "wald"))
        @test br.ci_method == "wald"
        @test br.ci_level == 0.95
        @test !isempty(br.ci_param_names)
        @test length(br.ci_lower) == length(br.ci_param_names)
        @test br.ci_note == ""
        d = _bzib_ci_max_absdiff(br.ci_param_names, br.ci_lower, br.ci_upper,
                                 nat.term, nat.lower, nat.upper)
        println("ZIB bridge no-X Wald CI: max|Δ| vs native = $d (≤1e-8)")
        @test d ≤ 1e-8
        @test all(isfinite, br.ci_estimate)
        # Bounds are ordered wherever the observed information yielded finite ones;
        # a non-PD Hessian cell stays NaN rather than being faked, so only finite
        # pairs are checked.
        @test all(l <= u for (l, u) in zip(br.ci_lower, br.ci_upper)
                  if isfinite(l) && isfinite(u))
    end
end
