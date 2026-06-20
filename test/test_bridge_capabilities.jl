using Test
using GLLVM
using Random
using Distributions

# Local bridge_capabilities() must report the HONEST narrow no-X one-part
# surface of this branch's bridge_fit. These tests pin the column key set and
# the honest values, AND cross-check the false/true flags against real
# bridge_fit behaviour so the advertised table cannot drift from reality.

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
        # fixed-effect X and missing-response masks are unsupported everywhere
        @test all(.!cap.fixed_effect_X)
        @test all(.!cap.missing_response)
        # cbind binomial trials accepted only for the binomial family
        @test cap.cbind_binomial == [f == "binomial" for f in cap.family]
        # Wald CI routes for ALL families (incl. ordinal); profile never routes;
        # bootstrap routes for gaussian only.
        @test all(cap.ci_no_x_wald)
        @test all(.!cap.ci_no_x_profile)
        @test cap.ci_no_x_bootstrap == [f == "gaussian" for f in cap.family]
        # no masks / no covariates on this branch
        @test all(.!cap.ci_mask_wald)
        @test all(.!cap.ci_mask_profile)
        @test all(.!cap.ci_mask_bootstrap)
        @test all(.!cap.ci_x_wald)
        @test all(.!cap.ci_x_profile)
        @test all(.!cap.ci_x_bootstrap)
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

        # fixed_effect_X = false (all) — passing X throws.
        Yp = Float64.(rand(rng, Poisson(2.0), 3, 24))
        X = zeros(size(Yp, 1), size(Yp, 2), 1)
        @test !cap.fixed_effect_X[findfirst(==("poisson"), cap.family)]
        @test_throws ArgumentError bridge_fit(; y = Yp, family = "poisson", d = 1, X = X)

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
    end
end
