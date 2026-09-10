using Test, GLLVM, SparseArrays, LinearAlgebra

function _destination_b_grouped_fixture()
    Y = [1.0 3.0; 2.0 4.0]
    D = [1.0 0.0; 0.0 1.0; 1.0 0.0; 0.0 1.0]
    term = GroupingTerm(:unit; mode = :indep)
    parameters = [1.0, 2.0, log(0.5), log(0.6), log(0.7)]
    return GroupedGaussianFit([1.0, 2.0], 0.7,
        [Matrix(Diagonal([0.25, 0.36]))], [term], parameters,
        -10.0, true, 1e-7, -0.1, false, 7, :converged, D,
        Union{String,Symbol}["trait1", "trait2"],
        ["trait1", "trait2", "unit.log_sd[1]", "unit.log_sd[2]", "log_sigma_eps"],
        size(Y), Y, [sparse([1, 2], [1, 1], ones(2), 2, 1)])
end

function _destination_b_precision_fixture()
    phy = PrecisionPhy(random_balanced_tree(2; branch_length = 0.5))
    Y = [1.0 3.0; 2.0 4.0]
    D = [1.0 0.0; 0.0 1.0; 1.0 0.0; 0.0 1.0]
    return GLLVM.PrecisionMultivariateFit([1.0, 2.0], reshape([0.5, 0.2], 2, 1),
        [0.1, 0.2], [0.3, 0.4], :explicitunique, 1, phy, [1, 2], zeros(7),
        -11.0, false, 0.02, -0.3, true, 42.0, 4, :gradient_not_converged,
        Y, D, size(Y), Union{String,Symbol}["trait1", "trait2"])
end

@testset "Destination B postfit" begin
    @test isdefined(GLLVM, :destination_b_population_predict)

    grouped = _destination_b_grouped_fixture()
    precision = _destination_b_precision_fixture()

    @testset "standard methods retain fixed-effect meaning" begin
        expected = [1.0 1.0; 2.0 2.0]
        @test GLLVM.coef(grouped) == [1.0, 2.0]
        @test GLLVM.loglikelihood(grouped) == -10.0
        @test GLLVM.nobs(grouped) == 4
        @test GLLVM.dof(grouped) == 5
        @test GLLVM.coef(precision) == [1.0, 2.0]
        @test GLLVM.loglikelihood(precision) == -11.0
        @test GLLVM.nobs(precision) == 4
        @test GLLVM.dof(precision) == 7
        @test GLLVM.destination_b_population_predict(grouped) == expected
        @test GLLVM.predict(precision; type = :link) == expected
        @test GLLVM.fitted(grouped) == expected
        @test GLLVM.residuals(precision) == [0.0 2.0; 0.0 2.0]
    end

    @testset "new trait-major design is validated" begin
        design = [2.0 0.0; 0.0 3.0; 2.0 0.0; 0.0 3.0]
        @test GLLVM.predict(grouped, design) == [2.0 2.0; 6.0 6.0]
        @test GLLVM.predict(precision, reshape(design, 2, 2, 2)) == [2.0 2.0; 6.0 6.0]
        @test_throws DimensionMismatch GLLVM.predict(grouped, ones(4, 1))
        @test_throws DimensionMismatch GLLVM.predict(grouped, ones(3, 2))
        @test_throws ArgumentError GLLVM.predict(grouped; type = :conditional)
    end

    @testset "covariance extraction retains distinct model components" begin
        group_total = GLLVM.extract_Sigma(grouped; level = :unit)
        @test group_total.Sigma == Matrix(Diagonal([0.25, 0.36]))
        @test GLLVM.extract_Sigma(grouped; level = :unit, part = :shared).Sigma == zeros(2, 2)
        @test GLLVM.extract_Sigma(grouped; level = :unit, part = :unique).s == [0.25, 0.36]
        @test GLLVM.extract_Sigma(grouped; level = :residual).Sigma ≈ Matrix(Diagonal(fill(0.49, 2)))
        phylo = GLLVM.extract_Sigma(precision; level = :phylo)
        @test phylo.Sigma ≈ precision.loading * precision.loading' + Diagonal([0.1, 0.2])
        @test GLLVM.extract_Sigma(precision; level = :residual, part = :unique).s == [0.3, 0.4]
        @test_throws ArgumentError GLLVM.extract_Sigma(precision; level = :unit)
    end

    @testset "display separates convergence from curvature" begin
        grouped_display = sprint(show, MIME"text/plain"(), grouped)
        precision_display = sprint(show, MIME"text/plain"(), precision)
        @test occursin("convergence = true", grouped_display)
        @test occursin("observed curvature PD = false", grouped_display)
        @test occursin("convergence = false", precision_display)
        @test occursin("observed curvature PD = true", precision_display)
    end
end
