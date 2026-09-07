using Test, GLLVM, StatsModels

@testset "Destination B public Gaussian grouping routes" begin
    Y = [0.2 -0.3 0.7 0.6 -0.4 0.1; 0.8 0.2 -0.1 0.3 0.5 -0.2]
    data = (unit=[:a,:a,:b,:b,:c,:c], x=[-1.,0.,1.,-1.,0.,1.])
    terms = [GLLVM.GroupingTerm(:unit; mode=:indep)]
    @test isdefined(Main, :GroupingTerm)
    @test_throws ArgumentError fit_gllvm(Y; grouping=terms, unit=data.unit, K=1)
    @test_throws ArgumentError fit_gllvm(Y; grouping=terms, unit=data.unit, pervar=true)
    @test_throws ArgumentError fit_gllvm(Y; unit=data.unit, K=1)
    direct = fit_gllvm(Y; grouping=terms, unit=data.unit, iterations=2)
    @test direct isa GLLVM.GroupedGaussianFit
    formula_fit = gllvm(@formula(y ~ 1 + x), Y, data;
        grouping=terms, unit=:unit, iterations=2)
    @test formula_fit isa GLLVM.GroupedGaussianFit
    @test size(formula_fit.mean_design) == (length(Y), 3)
    @test_throws ArgumentError gllvm(@formula(y ~ 1), Y, data;
        grouping=terms, unit=:missing_column)
    @test_throws ArgumentError gllvm(@formula(y ~ 1), Y, data;
        grouping=terms, unit=:unit, X=zeros(12,2))
end
