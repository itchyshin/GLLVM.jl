using GLLVM, Test, Random, LinearAlgebra, SparseArrays, Distributions

@testset "structured Poisson Laplace prototype" begin
    Random.seed!(821)
    p, n, K = 6, 5, 2
    β = fill(log(1.7), p)
    Λ = 0.18 .* randn(p, K)
    Y = rand.(Poisson.(exp.(β .+ 0.1 .* randn(p, n))))
    precision = Symmetric(spdiagm(0 => fill(1.4, p)))

    dense = GLLVM._structured_poisson_marginal_loglik_laplace(
        Y, Λ, β, precision; sigma2 = 0.6, logdet_method = :dense,
        return_diagnostics = true)
    @test isfinite(dense.value)
    @test dense.mode.iterations <= 50
    @test dense.mode.maxstep < 1e-7

    full_basis = sqrt(float(p)) .* Matrix{Float64}(I, p, p)
    exact_slq = GLLVM._structured_poisson_marginal_loglik_laplace(
        Y, Λ, β, precision; sigma2 = 0.6, logdet_method = :slq,
        probes = full_basis, lanczos_steps = p, reorth = true)
    @test exact_slq ≈ dense.value atol = 1e-8 rtol = 1e-8

    cg = GLLVM._structured_poisson_marginal_loglik_laplace(
        Y, Λ, β, precision; sigma2 = 0.6, logdet_method = :dense,
        mode_solve = :cg, cg_tol = 1e-10, return_diagnostics = true)
    @test cg.mode.cg_converged
    @test cg.value ≈ dense.value atol = 1e-6 rtol = 1e-6

    @test_throws DimensionMismatch GLLVM._structured_poisson_marginal_loglik_laplace(
        Y, randn(p + 1, K), β, precision; sigma2 = 0.6)
    @test_throws ArgumentError GLLVM._structured_poisson_marginal_loglik_laplace(
        Y, Λ, β, precision; sigma2 = 0.0)
    @test_throws ArgumentError GLLVM._structured_poisson_marginal_loglik_laplace(
        Y, Λ, β, precision; sigma2 = 0.6, mode_solve = :wat)
end

@testset "structured Poisson sigma-to-zero reduction" begin
    Random.seed!(822)
    p, n, K = 5, 4, 1
    β = fill(log(1.4), p)
    Λ = 0.12 .* randn(p, K)
    Y = rand.(Poisson.(exp.(β .+ 0.05 .* randn(p, n))))
    precision = Symmetric(Matrix{Float64}(I, p, p))

    base = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β; maxiter = 100, tol = 1e-10)
    structured = GLLVM._structured_poisson_marginal_loglik_laplace(
        Y, Λ, β, precision; sigma2 = 1e-8, logdet_method = :dense,
        maxiter = 100, tol = 1e-10)
    @test structured ≈ base atol = 1e-5 rtol = 1e-5
end
