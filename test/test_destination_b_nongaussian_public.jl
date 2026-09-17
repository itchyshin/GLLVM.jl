using Test, GLLVModels, StatsModels

@testset "Destination B public non-Gaussian grouping" begin
    labels = repeat([:a,:b,:c], inner=2)
    terms = [GroupingTerm(:unit; mode=:indep, common=true)]
    counts = [1. 3 2 4 1 2; 2 1 3 2 4 1]
    proportions = (counts .+ 1) ./ 7
    for (family, Y, extras) in ((GLLVModels.Poisson(), counts, (;)),
            (GLLVModels.Binomial(), counts, (; N=fill(6.,size(counts)))),
            (GLLVModels.Beta(10.,1.), proportions, (;)),
            (GLLVModels.NegativeBinomial(5.,0.5), counts, (;)))
        @testset "$(typeof(family))" begin
            fit = fit_gllvm(Y; family, grouping=terms, unit=labels,
                iterations=0, extras...)
            @test fit isa GroupedNonGaussianFit
            @test isfinite(fit.loglik)
            ci = grouped_nongaussian_intervals(Y, fit; unit=labels, extras...)
            @test ci.status != :available # zero optimisation budget is diagnostic only
            if family isa Union{GLLVModels.Beta,GLLVModels.NegativeBinomial}
                @test fit.dispersion_mode == :trait
                @test length(fit.dispersion) == 2
            end
        end
    end
    data = (unit=labels, x=[-1.,0.,1.,-1.,0.,1.])
    f = gllvm(@formula(y ~ 1 + x), counts, data; family=GLLVModels.Poisson(),
        grouping=terms, unit=:unit, iterations=0)
    @test f isa GroupedNonGaussianFit
    @test size(f.mean_design) == (12,3)
    @test_throws ArgumentError fit_gllvm(counts; family=GLLVModels.Gamma(),
        grouping=terms, unit=labels, iterations=0)
    @test_throws ArgumentError fit_gllvm(counts; family=GLLVModels.NegativeBinomial(5.,0.5),
        grouping=terms, unit=labels, disp_group=:species, iterations=0)
end
