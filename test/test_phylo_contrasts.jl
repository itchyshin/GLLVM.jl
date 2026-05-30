using GLLVM, Test, Random, LinearAlgebra, Distributions, SparseArrays, Statistics

# Felsenstein's independent contrasts: NEW FILES that are not (yet) wired
# into the GLLVM module on this branch (per the PERF+++ hard constraint
# "do not modify src/GLLVM.jl"). Pull them in directly for the test.
include(joinpath(@__DIR__, "..", "src", "sparse_phy.jl"))
include(joinpath(@__DIR__, "..", "src", "phylo_contrasts.jl"))
include(joinpath(@__DIR__, "..", "src", "likelihood_contrasts.jl"))

@testset "Felsenstein contrasts" begin

    @testset "contrast matrix shape and structure" begin
        tree = augmented_phy("((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1);")
        U, w = felsenstein_contrast_matrix(tree)
        @test size(U) == (3, 4)                                    # 4 leaves → 3 contrasts
        @test all(w .> 0)
        # Rows of U sum to zero (centroid difference property)
        @test all(abs.(sum(U, dims = 2)) .< 1e-12)
    end

    @testset "transformed data has diagonal phy covariance" begin
        # Simulate phy-only BM data and verify the contrast representation
        # gives an empirically diagonal covariance whose diagonal matches
        # the predicted variance weights.
        Random.seed!(0)
        tree = augmented_phy("(((A:0.1,B:0.1):0.1,C:0.2):0.1,(D:0.2,E:0.2):0.1);")
        p = tree.n_leaves
        Σ_phy = sigma_phy_dense(tree; σ²_phy = 1.0)
        n = 5000
        y = cholesky(Symmetric(Σ_phy)).L * randn(p, n)
        U, w = felsenstein_contrast_matrix(tree)
        y_c = U * y
        emp_cov = (y_c * y_c') ./ n
        # Diagonal entries should match w within Monte-Carlo error.
        @test maximum(abs.(diag(emp_cov) ./ w .- 1)) < 0.1
        # Off-diagonal entries should be near zero (relative to mean weight).
        offdiag = emp_cov - Diagonal(diag(emp_cov))
        @test maximum(abs.(offdiag)) / mean(w) < 0.1
    end

    @testset "dense vs contrast log-lik agreement (trait-homogeneous BM)" begin
        # Trait-homogeneous BM is the AD-friendly fast path: no Λ_phy or
        # σ_phy supplied, just σ²_phy added uniformly across traits.
        Random.seed!(11)
        tree = augmented_phy("(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,(E:0.2,F:0.2):0.1);")
        p = tree.n_leaves
        K_B, n = 1, 20
        Λ_B = reshape(randn(p), p, 1)
        σ_eps  = 0.5
        σ²_phy = 0.7
        # Build dense Σ_phy with σ_phy = sqrt(σ²_phy) for trait-homogeneous
        # representation in the dense path. The dense path requires either
        # Λ_phy or σ_phy to be non-nothing, so we pass σ_phy = ones * √σ²_phy.
        Σ_phy = sigma_phy_dense(tree; σ²_phy = σ²_phy)
        σ_phy_dense = ones(p)             # trait-homogeneous scaling = 1 each
        # Generate y
        η_B   = randn(K_B, n)
        η_phy = cholesky(Symmetric(Σ_phy)).L * randn(p)            # length p, shared across sites
        y     = Λ_B * η_B .+ reshape(η_phy, p, 1) .+ σ_eps * randn(p, n)

        # Dense path: pass σ_phy = ones (so that B = (ones·ones').*Σ_phy = Σ_phy)
        ll_dense    = GLLVM.gaussian_marginal_loglik(y, Λ_B, σ_eps;
                                                     σ_phy = σ_phy_dense,
                                                     Σ_phy = Σ_phy)
        ll_contrast = gaussian_marginal_loglik_contrasts(y, Λ_B, σ_eps;
                                                         tree = tree,
                                                         σ²_phy = σ²_phy)
        @test ll_contrast ≈ ll_dense rtol = 1e-10
    end

    @testset "dense vs contrast log-lik agreement (trait-specific Λ_phy)" begin
        # Trait-specific phy: contrast path materialises Σ_phy and rotates
        # T B T'. Still numerically exact to 1e-10 versus the dense path.
        Random.seed!(1)
        tree = augmented_phy("(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,(E:0.2,F:0.2):0.1);")
        p = tree.n_leaves
        K_B, K_phy, n = 1, 1, 30
        σ²_phy = 1.0
        Σ_phy = sigma_phy_dense(tree; σ²_phy = σ²_phy)
        Λ_B   = reshape(randn(p), p, K_B)
        Λ_phy = reshape(0.3 * randn(p), p, K_phy)
        σ_eps = 0.5

        # Generate y with shared phylogenetic realisation.
        η_B   = randn(K_B, n)
        η_phy = cholesky(Symmetric(Σ_phy)).L * randn(p, K_phy)     # p × K_phy
        # Λ_phy .* η_phy: each axis contributes Λ_phy[:, k] .* η_phy[:, k]
        z_phy = vec(sum(Λ_phy .* η_phy, dims = 2))
        y     = Λ_B * η_B .+ reshape(z_phy, p, 1) .+ σ_eps * randn(p, n)

        ll_dense    = GLLVM.gaussian_marginal_loglik(y, Λ_B, σ_eps;
                                                     Λ_phy = Λ_phy,
                                                     Σ_phy = Σ_phy)
        ll_contrast = gaussian_marginal_loglik_contrasts(y, Λ_B, σ_eps;
                                                         Λ_phy = Λ_phy,
                                                         tree = tree,
                                                         σ²_phy = σ²_phy)
        @test ll_contrast ≈ ll_dense rtol = 1e-10
    end

    @testset "AD-friendly: ForwardDiff gradient through contrast log-lik" begin
        using ForwardDiff
        Random.seed!(2)
        tree = augmented_phy("((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1);")
        p = tree.n_leaves
        Λ_B0  = [0.5, 0.3, -0.2, 0.4]
        y     = randn(p, 20)
        function f(params)
            Λ_B    = reshape(params[1:4], 4, 1)
            σ_eps  = exp(params[5])
            σ²_phy = exp(params[6])
            return gaussian_marginal_loglik_contrasts(y, Λ_B, σ_eps;
                                                      tree = tree,
                                                      σ²_phy = σ²_phy)
        end
        params0 = [Λ_B0..., log(0.5), log(1.0)]
        g = ForwardDiff.gradient(f, params0)
        @test all(isfinite, g)
        @test length(g) == 6
    end

    @testset "AD-friendly with Λ_phy: ForwardDiff gradient" begin
        # Differentiate through Λ_phy as well, exercising the trait-
        # specific code path.
        using ForwardDiff
        Random.seed!(3)
        tree = augmented_phy("((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1);")
        p = tree.n_leaves
        y = randn(p, 10)
        function g(params)
            Λ_B    = reshape(params[1:4], 4, 1)
            Λ_phy  = reshape(params[5:8], 4, 1)
            σ_eps  = exp(params[9])
            σ²_phy = exp(params[10])
            return gaussian_marginal_loglik_contrasts(y, Λ_B, σ_eps;
                                                      Λ_phy = Λ_phy,
                                                      tree = tree,
                                                      σ²_phy = σ²_phy)
        end
        params0 = [0.5, 0.3, -0.2, 0.4, 0.2, 0.1, -0.1, 0.3, log(0.5), log(1.0)]
        grad = ForwardDiff.gradient(g, params0)
        @test all(isfinite, grad)
        @test length(grad) == 10
    end

    @testset "scales sub-cubically in p (trait-homogeneous path)" begin
        # The trait-homogeneous fast path forms T A T' (p × p) and a
        # Cholesky factorisation per call. For Brownian motion this still
        # involves a dense p × p Cholesky (O(p³) worst case) because
        # σ²_eps · I in the original basis becomes σ²_eps · T T' in the
        # transformed basis — and T T' is generically dense. The
        # AD-friendliness (vs the augmented sparse path) is the
        # differentiator here, not raw FLOPS.
        #
        # In the regime p ≲ 800 the dense Cholesky kernel is so well-
        # tuned (BLAS) that the empirical slope sits between 1.4 and
        # 2.5 — well below O(p³). The 2.5 cap below allows for that
        # transition. The bench file (`bench/contrast_bench.jl`)
        # reports the absolute timings at p up to 10⁴ for completeness.
        ps    = [100, 200, 400, 800]
        times = Float64[]
        for p in ps
            tree = random_balanced_tree(p)
            Λ_B  = randn(p, 2)
            y    = randn(p, 20)
            # Warmup so JIT does not pollute the first timing.
            gaussian_marginal_loglik_contrasts(y, Λ_B, 0.5;
                tree = tree, σ²_phy = 1.0)
            # Take the minimum of a few runs to reduce timer noise.
            sample = Float64[]
            for _ in 1:5
                t = @elapsed gaussian_marginal_loglik_contrasts(y, Λ_B, 0.5;
                    tree = tree, σ²_phy = 1.0)
                push!(sample, t)
            end
            push!(times, minimum(sample))
        end
        slopes = diff(log.(times)) ./ diff(log.(Float64.(ps)))
        @info "contrast log-lik log-log slopes: $(round.(slopes, digits=3))" times
        # Slope strictly less than O(p³) bound. The dense Cholesky on
        # the transformed p × p matrix dominates at the largest p but
        # the implementation does not waste extra polynomial factors.
        # Timing-based scaling check — flaky on shared CI runners; gate behind
        # GLLVM_PERF_TESTS so it runs on a consistent machine but not on CI.
        if get(ENV, "GLLVM_PERF_TESTS", "") == "1"
            @test maximum(slopes) < 2.5
        else
            @test_skip maximum(slopes) < 2.5
        end
    end
end
