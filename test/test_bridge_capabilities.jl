using Test
using GLLVM
using Random
using Distributions

# Local bridge_capabilities() must report the HONEST narrow one-part bridge
# surface of this branch's bridge_fit: Gaussian admits fixed-effect X; all
# non-Gaussian X rows remain blocked. These tests pin the column key set and
# cross-check flags against real bridge_fit behaviour so the table cannot drift.

@testset "bridge_capabilities honest local surface" begin
    cap = bridge_capabilities()

    expected_families =
        ["gaussian", "poisson", "binomial", "negbinomial", "beta", "gamma", "ordinal"]
    nf = length(expected_families)

    @testset "column key set matches integration shape" begin
        expected_keys = (
            :family, :fit_no_x, :fixed_effect_X, :missing_response, :cbind_binomial,
            :ci_no_x_wald, :ci_no_x_profile, :ci_no_x_bootstrap,
            :ci_mask_wald, :ci_mask_profile, :ci_mask_bootstrap,
            :ci_x_wald, :ci_x_profile, :ci_x_bootstrap,
            :postfit_coef, :postfit_fit_stats, :postfit_summary,
            :postfit_predict, :postfit_residuals, :postfit_simulate,
            :postfit_ordination, :status, :notes,
        )
        @test Set(keys(cap)) == Set(expected_keys)
        # one row per local family; mixed-family vector row is honestly omitted
        @test cap.family == expected_families
        for k in expected_keys
            @test length(getfield(cap, k)) == nf
        end
    end

    @testset "honest values" begin
        # fit_no_x: every local family fits with no covariates
        @test all(cap.fit_no_x)
        # fixed-effect X is admitted only for Gaussian; masks are unsupported
        @test cap.fixed_effect_X == [f == "gaussian" for f in cap.family]
        @test all(.!cap.missing_response)
        # cbind binomial trials accepted only for the binomial family
        @test cap.cbind_binomial == [f == "binomial" for f in cap.family]
        # Wald CI routes for ALL families (incl. ordinal); profile routes for
        # the non-ordinal no-X rows; bootstrap routes for gaussian only.
        @test all(cap.ci_no_x_wald)
        @test cap.ci_no_x_profile == [f != "ordinal" for f in cap.family]
        @test cap.ci_no_x_bootstrap == [f == "gaussian" for f in cap.family]
        # no masks; covariate CIs are admitted only for Gaussian
        @test all(.!cap.ci_mask_wald)
        @test all(.!cap.ci_mask_profile)
        @test all(.!cap.ci_mask_bootstrap)
        @test cap.ci_x_wald == [f == "gaussian" for f in cap.family]
        @test cap.ci_x_profile == [f == "gaussian" for f in cap.family]
        @test cap.ci_x_bootstrap == [f == "gaussian" for f in cap.family]
        # postfit: coef/fit_stats/summary/predict/residuals/ordination supported;
        # simulate is NOT (no post-fit response simulator on this branch).
        @test all(cap.postfit_coef)
        @test all(cap.postfit_fit_stats)
        @test all(cap.postfit_summary)
        @test all(cap.postfit_predict)
        @test all(cap.postfit_residuals)
        @test all(.!cap.postfit_simulate)
        @test all(cap.postfit_ordination)
        @test all(==("partial"), cap.status)
        @test all(s -> s isa AbstractString && !isempty(s), cap.notes)
    end

    @testset "behavioural cross-check: flags match real bridge_fit" begin
        rng = MersenneTwister(2026)

        # cbind_binomial = true (binomial) — a real binomial fit with N succeeds.
        N = fill(5, 3, 24)
        Yb = Float64.(reshape(
            [rand(rng, Binomial(N[i], 0.4)) for i in eachindex(N)], 3, 24))
        @test cap.cbind_binomial[findfirst(==("binomial"), cap.family)]
        br = bridge_fit(; y = Yb, family = "binomial", d = 1, N = N)
        @test br.family == "binomial"
        @test br.converged isa Bool

        # fixed_effect_X = true for Gaussian — a real Gaussian X fit succeeds.
        Yg = randn(rng, 3, 26)
        Xg = zeros(size(Yg, 1), size(Yg, 2), 1)
        for t in axes(Xg, 1), s in axes(Xg, 2)
            Xg[t, s, 1] = randn(rng)
            Yg[t, s] += 0.25 * Xg[t, s, 1]
        end
        @test cap.fixed_effect_X[findfirst(==("gaussian"), cap.family)]
        brg = bridge_fit(; y = Yg, family = "gaussian", d = 1, X = Xg)
        direct_g = fit_gaussian_gllvm(Yg; K = 1, X = Xg)
        @test brg.family == "gaussian"
        @test haskey(brg, :mean_coef)
        @test brg.mean_coef ≈ direct_g.pars.β atol = 1e-8
        @test brg.loglik ≈ direct_g.logLik atol = 1e-8
        @test size(brg.scores) == (size(Yg, 2), 1)

        # fixed_effect_X remains false for non-Gaussian rows — passing X throws.
        Yp = Float64.(rand(rng, Poisson(2.0), 3, 24))
        X = zeros(size(Yp, 1), size(Yp, 2), 1)
        @test !cap.fixed_effect_X[findfirst(==("poisson"), cap.family)]
        @test_throws ArgumentError bridge_fit(; y = Yp, family = "poisson", d = 1, X = X)

        # Gaussian X CI routes are real and selected-entry capable.
        @test cap.ci_x_wald[findfirst(==("gaussian"), cap.family)]
        brg_wald = bridge_fit(; y = Yg, family = "gaussian", d = 1, X = Xg,
                              options = Dict(
                                  "ci_method" => "wald",
                                  "ci_parm" => "beta[1]",
                              ))
        @test brg_wald.ci_method == "wald"
        @test brg_wald.ci_status == "ok"
        @test brg_wald.ci_param_names == ["beta[1]"]
        @test brg_wald.ci_lower[1] < brg_wald.ci_estimate[1] < brg_wald.ci_upper[1]

        @test cap.ci_x_profile[findfirst(==("gaussian"), cap.family)]
        brg_profile = bridge_fit(; y = Yg, family = "gaussian", d = 1, X = Xg,
                                 options = Dict(
                                     "ci_method" => "profile",
                                     "ci_parm" => "beta[1]",
                                     "profile_max_expand" => 5,
                                     "profile_max_bisect" => 8,
                                 ))
        @test brg_profile.ci_method == "profile"
        @test brg_profile.ci_status in ("ok", "partial")
        @test brg_profile.ci_param_names == ["beta[1]"]
        @test brg_profile.ci_lower[1] < brg_profile.ci_estimate[1] < brg_profile.ci_upper[1]

        @test cap.ci_x_bootstrap[findfirst(==("gaussian"), cap.family)]
        brg_boot = bridge_fit(; y = Yg, family = "gaussian", d = 1, X = Xg,
                              options = Dict(
                                  "ci_method" => "bootstrap",
                                  "ci_parm" => "beta[1]",
                                  "ci_nboot" => 3,
                                  "ci_seed" => 2026,
                              ))
        @test brg_boot.ci_method == "bootstrap"
        @test brg_boot.ci_status == "ok"
        @test brg_boot.ci_param_names == ["beta[1]"]
        @test brg_boot.ci_estimate[1] == brg_boot.mean_coef[1]

        # mixed-family vector is rejected (consistent with the omitted row).
        @test_throws ArgumentError bridge_fit(;
            y = Yp, family = ["poisson", "gaussian"], d = 1)

        # ci_no_x_wald = true for ordinal — a real ordinal Wald CI is routed.
        @test cap.ci_no_x_wald[findfirst(==("ordinal"), cap.family)]
        Yo = Float64.(rand(rng, 1:3, 3, 30))
        bro = bridge_fit(; y = Yo, family = "ordinal", d = 1,
                         options = Dict("ci_method" => "wald"))
        @test bro.ci_method == "wald"
        @test bro.ci_status == "ok"
        @test !isempty(bro.ci_lower)

        # ci_no_x_bootstrap = false for a non-Gaussian family — bootstrap is not
        # routed, matching the advertised false flag.
        @test !cap.ci_no_x_bootstrap[findfirst(==("poisson"), cap.family)]
        brp = bridge_fit(; y = Yp, family = "poisson", d = 1,
                        options = Dict("ci_method" => "bootstrap"))
        @test brp.ci_status == "unsupported"
        @test isempty(brp.ci_lower)

        # ci_no_x_profile = true for non-ordinal rows — selected profile terms
        # are routed through the flat bridge payload.
        @test cap.ci_no_x_profile[findfirst(==("poisson"), cap.family)]
        brprof = bridge_fit(; y = Yp, family = "poisson", d = 1,
                            options = Dict(
                                "ci_method" => "profile",
                                "ci_parm" => "beta[1]",
                                "profile_max_expand" => 8,
                                "profile_max_bisect" => 12,
                            ))
        @test brprof.ci_method == "profile"
        @test brprof.ci_status in ("ok", "partial")
        @test brprof.ci_param_names == ["beta[1]"]
        @test length(brprof.ci_lower) == 1
        @test brprof.ci_lower[1] < brprof.ci_estimate[1] < brprof.ci_upper[1]

        # Ordinal profile payloads stay unavailable through the bridge even
        # though native OrdinalFit profile internals exist.
        @test !cap.ci_no_x_profile[findfirst(==("ordinal"), cap.family)]
        bro_prof = bridge_fit(; y = Yo, family = "ordinal", d = 1,
                              options = Dict("ci_method" => "profile"))
        @test bro_prof.ci_status == "unsupported"
        @test isempty(bro_prof.ci_lower)
    end
end
