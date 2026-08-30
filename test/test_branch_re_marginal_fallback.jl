using GLLVM, Test, LinearAlgebra, SparseArrays

@testset "branch RE equivalent marginal representation" begin
    phy = edge_phy("((A:0.1,B:0.2):0.3,(C:0.4,D:0.5):0.1);")
    cache = branch_re_cache(phy)
    Z = path_membership(phy)
    V = Matrix(Z * Diagonal(phy.branch_lengths) * Z')
    y = [0.1, -0.3, 0.8, 0.2]
    one = ones(4)
    for (signal, noise) in ((1e6, 1e-6), (1.0, 1e-320))
        S = signal * V + noise * I
        @test cond(S) < 6
        C = cholesky(Symmetric(S))
        mu = dot(one, C \ y) / dot(one, C \ one)
        r = y .- mu
        nll = (4log(2pi) + logdet(C) + dot(r, C \ r)) / 2
        got, got_mu = branch_re_profile_negll(cache, y, signal, noise)
        @test got ≈ nll atol=1e-10
        @test got_mu ≈ mu atol=1e-12
        z = signal .* phy.branch_lengths .* (Z' * (C \ r))
        got_z, _, _ = branch_blups(cache, y, signal, noise, mu)
        @test got_z ≈ z atol=1e-10
    end
    for signal in (NaN, Inf, -1.0, 0.0)
        @test_throws DomainError branch_blups(cache, y, signal, 1.0, 0.0)
    end
    @test_throws ArgumentError branch_blups(cache, y[1:3], 1.0, 1.0, 0.0)
end
