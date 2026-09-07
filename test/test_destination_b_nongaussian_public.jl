using Test, GLLVM, StatsModels

@testset "Destination B public non-Gaussian grouping" begin
    labels = repeat([:a,:b,:c], inner=2)
    terms = [GroupingTerm(:unit; mode=:indep, common=true)]
    counts = [1. 3 2 4 1 2; 2 1 3 2 4 1]
    proportions = (counts .+ 1) ./ 7
    for (family, Y, extras) in ((GLLVM.Poisson(), counts, (;)),
            (GLLVM.Binomial(), counts, (; N=fill(6.,size(counts)))),
            (GLLVM.Beta(10.,1.), proportions, (;)),
            (GLLVM.NegativeBinomial(5.,0.5), counts, (;)))
        @testset "$(typeof(family))" begin
            fit = fit_gllvm(Y; family, grouping=terms, unit=labels,
                iterations=0, extras...)
            @test fit isa GroupedNonGaussianFit
            @test isfinite(fit.loglik)
            ci = grouped_nongaussian_intervals(Y, fit; unit=labels, extras...)
            @test ci.status != :available # zero optimisation budget is diagnostic only
            if family isa Union{GLLVM.Beta,GLLVM.NegativeBinomial}
                @test fit.dispersion_mode == :trait
                @test length(fit.dispersion) == 2
            end
        end
    end
    data = (unit=labels, x=[-1.,0.,1.,-1.,0.,1.])
    f = gllvm(@formula(y ~ 1 + x), counts, data; family=GLLVM.Poisson(),
        grouping=terms, unit=:unit, iterations=0)
    @test f isa GroupedNonGaussianFit
    @test size(f.mean_design) == (12,3)
    @test_throws ArgumentError fit_gllvm(counts; family=GLLVM.Gamma(),
        grouping=terms, unit=labels, iterations=0)
    @test_throws ArgumentError fit_gllvm(counts; family=GLLVM.NegativeBinomial(5.,0.5),
        grouping=terms, unit=labels, disp_group=:species, iterations=0)
end
