using Test, GLLVModels, Random

@testset "public grouped Gaussian variance profile" begin
    rng = MersenneTwister(20_260_907)
    labels = repeat(1:12; inner=5)
    effect = 0.65 .* randn(rng, 12)
    Y = reshape([1.1 + effect[g] + 0.35randn(rng) for g in labels], 1, :)
    terms = [GroupingTerm(:unit; mode=:indep, common=false)]
    fit = fit_gllvm(Y; grouping=terms, unit=labels, iterations=100)
    @test isdefined(Main, :grouped_gaussian_variance_profile)
    begin
        interval = grouped_gaussian_variance_profile(Y, fit; term=:unit, trait=1)
        @test interval.status === :available
        @test interval.lower.endpoint < interval.center.fixed_variance < interval.upper.endpoint
        @test interval.selected_label == "unit.log_sd[1]"
        @test interval.target == (term=:unit, trait=1, scale=:variance,
            method=:profile_likelihood, level=.95)
        @test_throws ArgumentError grouped_gaussian_variance_profile(Y, fit; term=:cluster)
        @test_throws ArgumentError grouped_gaussian_variance_profile(Y, fit; term=:unit, trait=2)
        @test_throws ArgumentError grouped_gaussian_variance_profile(Y .+ 0.01, fit; term=:unit)
    end
end
