using Test, GLLVM, StatsModels, LinearAlgebra

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

@testset "Destination B public latent unit fixed-coordinate oracle" begin
    p, n = 2, 8
    Y = [1.30 1.72 0.48 0.83 1.91 1.19 0.72 1.54;
         -0.52 -0.16 -1.08 -0.64 -0.23 -0.91 -0.37 -0.76]
    labels = [:a, :a, :b, :b, :c, :c, :d, :d]
    wrong_labels = [:a, :a, :a, :b, :c, :c, :d, :d]
    beta = [1.2, -0.7]
    Lambda = reshape([0.6, -0.4], p, 1)
    sigma_eps = 0.35
    theta = [beta; vec(Lambda); log(sigma_eps)]
    terms = [GroupingTerm(:unit; mode=:latent, rank=1, unique=false)]

    function dense_unit_nll(map)
        m = p * n
        V = zeros(m, m)
        for observation_i in 1:n, trait_i in 1:p,
                observation_j in 1:n, trait_j in 1:p
            i = trait_i + p * (observation_i - 1)
            j = trait_j + p * (observation_j - 1)
            if observation_i == observation_j && trait_i == trait_j
                V[i, j] += sigma_eps^2
            end
            if map[observation_i] == map[observation_j]
                V[i, j] += Lambda[trait_i, 1] * Lambda[trait_j, 1]
            end
        end
        factor = cholesky(Symmetric(V))
        residual = vec(Y) - repeat(beta, n)
        return (m * log(2pi) + logdet(factor) + dot(residual, factor \ residual)) / 2
    end

    dense_nll = dense_unit_nll(labels)
    wrong_dense_nll = dense_unit_nll(wrong_labels)
    fit = fit_gllvm(Y; family=GLLVM.Normal(), grouping=terms, unit=labels,
        start=theta, iterations=0)
    objective = GLLVM._grouped_gaussian_objective(Matrix{Float64}(Y), fit.mean_design,
        terms, fit.incidences)
    wrong_incidence = [GLLVM._grouped_incidence(wrong_labels, n)]
    wrong_objective = GLLVM._grouped_gaussian_objective(Matrix{Float64}(Y),
        fit.mean_design, terms, wrong_incidence)

    @test fit isa GroupedGaussianFit
    @test length(fit.incidences) == 1
    @test fit.parameters ≈ theta atol=1e-12 rtol=0
    @test fit.term_covariances[1] ≈ Lambda * Lambda' atol=1e-12 rtol=0
    @test objective(theta) ≈ dense_nll atol=1e-10 rtol=1e-10
    @test -fit.loglik ≈ dense_nll atol=1e-10 rtol=1e-10
    @test wrong_objective(theta) ≈ wrong_dense_nll atol=1e-10 rtol=1e-10
    @test !isapprox(wrong_dense_nll, dense_nll; atol=1e-6, rtol=0)
end
