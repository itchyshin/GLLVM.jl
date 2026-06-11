using GLLVM, Test, LinearAlgebra, Random, ForwardDiff

# Trait-covariance taxonomy (SP1.5): latent / dep / indep + the `specific` knob.

@testset "Trait-covariance taxonomy (SP1.5)" begin

    @testset "constructors" begin
        c = latent(2)
        @test c isa LatentCov && c.kind === :latent && c.K == 2 && c.specific == false
        @test latent(3; specific = true).specific == true
        @test indep().kind === :indep && indep().K == 0 && indep().specific == true
        @test dep().kind === :dep
        @test_throws ArgumentError latent(0)
    end

    @testset "parameter counts" begin
        p = 5
        @test cov_nloadings(latent(2), p) == GLLVM.rr_theta_len(p, 2)
        @test cov_nloadings(indep(), p) == 0
        @test cov_nspecific(latent(2; specific = true), p) == p
        @test cov_nspecific(latent(2), p) == 0          # specific=false ⇒ no s_t
        @test cov_nspecific(indep(), p) == p
    end

    @testset "trait_cov: latent — specific=FALSE is pure ΛΛᵀ" begin
        Random.seed!(50501)
        p, K = 4, 2
        Λ = 0.6 .* randn(p, K); s = abs.(randn(p)) .+ 0.1
        Σ_pure = trait_cov(latent(K), Λ, s)             # specific=false
        @test Σ_pure ≈ Λ * Λ'                            # NOT a single sigma — pure ΛΛᵀ
        Σ_spec = trait_cov(latent(K; specific = true), Λ, s)
        @test Σ_spec ≈ Λ * Λ' + Diagonal(s)
        @test Σ_spec - Σ_pure ≈ Diagonal(s)             # specific adds exactly diag(s)
    end

    @testset "trait_cov: indep + dep" begin
        Random.seed!(50502)
        p = 4; s = abs.(randn(p)) .+ 0.1
        @test trait_cov(indep(), randn(p, 1), s) ≈ Diagonal(s)   # Λ ignored
        Lp = randn(p, p)                                          # dep = full-rank ΛΛᵀ
        @test trait_cov(dep(), Lp, s) ≈ Lp * Lp'
        @test cov_nloadings(dep(), p) == GLLVM.rr_theta_len(p, p)
        @test_throws DimensionMismatch trait_cov(dep(), randn(p, 1), s)   # needs full p×p
    end

    @testset "AD-friendly" begin
        Random.seed!(50503)
        p, K = 3, 1
        f = θ -> begin
            Λ = reshape(θ[1:(p * K)], p, K); s = θ[(p * K + 1):end] .^ 2
            sum(trait_cov(latent(K; specific = true), Λ, s))
        end
        θ = randn(p * K + p)
        g = ForwardDiff.gradient(f, θ)
        @test all(isfinite, g)
        @test length(g) == p * K + p
    end
end
