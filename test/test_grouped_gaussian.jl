using Test, GLLVM, LinearAlgebra, SparseArrays

@testset "grouped Gaussian random-effect kernel" begin
    @test isdefined(GLLVM, :_grouped_gaussian_nll)
    if isdefined(GLLVM, :_grouped_gaussian_nll)
        f = GLLVM._grouped_gaussian_nll
        Y = [0.2 -0.4 0.8 0.1;
             1.1  0.3 -0.2 0.5]
        beta = [0.1, -0.2]
        Zshared = sparse([1, 2, 3, 4], [1, 1, 2, 2], ones(4), 4, 2)
        Zcrossed = sparse([1, 2, 3, 4], [1, 2, 1, 2], ones(4), 4, 2)
        Bshared = [0.49 0.14; 0.14 0.36]
        Bcrossed = [0.25 0.0; 0.0 0.16]
        sigma = 0.7

        # Independent observation-pair assembly: deliberately no production
        # Woodbury or Kronecker core arithmetic in this oracle.
        p, n = size(Y)
        V = sigma^2 * Matrix{Float64}(I, p * n, p * n)
        for (Z, B) in zip((Zshared, Zcrossed), (Bshared, Bcrossed))
            for j in 1:n, i in 1:n, b in 1:p, a in 1:p
                shared_node = sum(Z[i, k] * Z[j, k] for k in axes(Z, 2))
                V[a + p * (i - 1), b + p * (j - 1)] += shared_node * B[a, b]
            end
        end
        r = vec(Y .- beta)
        expected = (p * n * log(2pi) + logdet(V) + dot(r, V \ r)) / 2
        @test f(Y, beta, [Zshared, Zcrossed], [Bshared, Bcrossed], sigma) ≈ expected atol = 1e-12

        zero_expected = (p * n * log(2pi) + logdet(V)) / 2
        @test f(repeat(beta, 1, n), beta, [Zshared, Zcrossed], [Bshared, Bcrossed], sigma) ≈ zero_expected atol = 1e-12

        order = [4, 1, 3, 2]
        @test f(Y[:, order], beta, [Zshared[order, :], Zcrossed[order, :]],
                [Bshared, Bcrossed], sigma) ≈ expected atol = 1e-12
        @test f(Y, beta, [Zcrossed, Zshared], [Bcrossed, Bshared], sigma) ≈ expected atol = 1e-12

        @test_throws DimensionMismatch f(Y, beta, [Zshared], [Bshared, Bcrossed], sigma)
        @test_throws DimensionMismatch f(Y, beta, [Zshared[1:3, :]], [Bshared], sigma)
        @test_throws DimensionMismatch f(Y, beta, [Zshared], [ones(3, 3)], sigma)
        @test_throws ArgumentError f(Y, beta, [Zshared], [[1.0 2.0; 2.0 1.0]], sigma)
        @test_throws ArgumentError f(Y, beta, [Zshared], [Bshared], 0.0)
        @test_throws ArgumentError f(fill(NaN, 2, 4), beta, [Zshared], [Bshared], sigma)

        # The posterior-mode form of the Woodbury quadratic must remain
        # finite and agree with the analytic rank-one normalizer even when
        # r'r/sigma^2 and h'K^-1h are individually huge and nearly equal.
        extreme_Z = sparse(reshape(ones(4), 4, 1))
        extreme_L = [100.0;;]
        extreme_sigma = 1e-8
        extreme_Y = reshape(fill(100.0, 4), 1, :)
        extreme_value = GLLVM._grouped_gaussian_factor_nll(extreme_Y, [0.0],
            [extreme_Z], [extreme_L], extreme_sigma)
        extreme_expected = (4 * log(2pi) + 3 * log(extreme_sigma^2) +
            log(extreme_sigma^2 + 4 * extreme_L[1]^2) +
            4 * extreme_Y[1]^2 / (extreme_sigma^2 + 4 * extreme_L[1]^2)) / 2
        @test isfinite(extreme_value)
        @test extreme_value ≈ extreme_expected atol = 1e-8
    end
end

@testset "grouped term unpack keeps unique variances concrete" begin
    terms = GLLVM.GroupingTerm[
        GLLVM.GroupingTerm(:unit; mode = :latent, rank = 1, unique = true),
        GLLVM.GroupingTerm(:cluster; mode = :dep),
    ]
    theta = zeros(7)
    _, uniques, _, used = GLLVM._grouped_term_unpack(theta, 2, terms)
    @test used == length(theta)
    @test eltype(uniques) === Union{Nothing,Vector{Float64}}
end

@testset "low-rank grouped Gaussian factor kernel" begin
    @test isdefined(GLLVM, :_grouped_gaussian_factor_nll)
    if isdefined(GLLVM, :_grouped_gaussian_factor_nll)
        f = GLLVM._grouped_gaussian_factor_nll
        Y = [0.2 -0.4 0.8 0.1;
             1.1  0.3 -0.2 0.5;
            -0.1  0.6 0.4 -0.3]
        beta = [0.1, -0.2, 0.3]
        Zshared = sparse([1, 2, 3, 4], [1, 1, 2, 2], ones(4), 4, 2)
        Zcrossed = sparse([1, 2, 3, 4], [1, 2, 1, 2], ones(4), 4, 2)
        Lshared = [0.7; -0.2; 0.4;;]
        Lcrossed = [-0.3; 0.5; 0.1;;]
        sigma = 0.7
        p, n = size(Y)

        function dense_factor_covariance(uniques)
            V = sigma^2 * Matrix{Float64}(I, p * n, p * n)
            for (Z, L, d) in zip((Zshared, Zcrossed), (Lshared, Lcrossed), uniques)
                B = L * L' + (d === nothing ? zeros(p, p) : Diagonal(d))
                for j in 1:n, i in 1:n, b in 1:p, a in 1:p
                    shared_node = sum(Z[i, k] * Z[j, k] for k in axes(Z, 2))
                    V[a + p * (i - 1), b + p * (j - 1)] += shared_node * B[a, b]
                end
            end
            V
        end

        r = vec(Y .- beta)
        Vbare = dense_factor_covariance((nothing, nothing))
        bare_expected = (p * n * log(2pi) + logdet(Vbare) + dot(r, Vbare \ r)) / 2
        @test rank(Lshared * Lshared') == 1
        @test !isposdef(Symmetric(Lshared * Lshared'))
        @test f(Y, beta, [Zshared, Zcrossed], [Lshared, Lcrossed], sigma) ≈ bare_expected atol = 1e-12
        @test f(Y, beta, [Zshared, Zcrossed], [Lshared, Lcrossed], sigma;
                uniques = [zeros(3), nothing]) ≈ bare_expected atol = 1e-12

        unique = [0.04, 0.0, 0.09]
        Vunique = dense_factor_covariance((unique, nothing))
        unique_expected = (p * n * log(2pi) + logdet(Vunique) + dot(r, Vunique \ r)) / 2
        @test f(Y, beta, [Zshared, Zcrossed], [Lshared, Lcrossed], sigma;
                uniques = [unique, nothing]) ≈ unique_expected atol = 1e-12

        order = [4, 1, 3, 2]
        @test f(Y[:, order], beta, [Zshared[order, :], Zcrossed[order, :]],
                [Lshared, Lcrossed], sigma) ≈ bare_expected atol = 1e-12
        @test f(Y, beta, [Zcrossed, Zshared], [Lcrossed, Lshared], sigma) ≈ bare_expected atol = 1e-12

        @test_throws DimensionMismatch f(Y, beta, [Zshared], [Lshared, Lcrossed], sigma)
        @test_throws DimensionMismatch f(Y, beta, [Zshared], [Lshared], sigma;
                                        uniques = [[0.1, 0.2]])
        @test_throws ArgumentError f(Y, beta, [Zshared], [Lshared], sigma;
                                     uniques = [[0.1, -0.2, 0.3]])
    end
end
