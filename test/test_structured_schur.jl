using GLLVM, Test, Random, LinearAlgebra, SparseArrays

@testset "structured Schur operator" begin
    Random.seed!(801)
    p, n, K = 12, 5, 2
    Lambda = 0.35 .* randn(p, K)
    Wsites = 0.2 .+ abs.(randn(p, n))
    R = randn(p, p)
    precision = Symmetric(R' * R + 0.5I)

    op = GLLVM._SchurUOperator(precision, Lambda, Wsites; sigma2 = 0.7)
    dense = Matrix(GLLVM._schur_u_dense(op))
    sparse_op = GLLVM._SchurUOperator(Symmetric(sparse(precision)), Lambda, Wsites; sigma2 = 0.7)
    sparse_dense = Matrix(GLLVM._schur_u_dense(sparse_op))

    @test size(op) == (p, p)
    @test dense ≈ dense' atol = 1e-12
    @test parent(sparse_op.precision) isa SparseMatrixCSC
    @test sparse_dense ≈ dense atol = 1e-10 rtol = 1e-10
    @test minimum(eigvals(Symmetric(dense))) > 0

    y = zeros(p)
    y_sparse = zeros(p)
    for _ in 1:5
        x = randn(p)
        mul!(y, op, x)
        mul!(y_sparse, sparse_op, x)
        @test y ≈ dense * x atol = 1e-10 rtol = 1e-10
        @test y_sparse ≈ y atol = 1e-10 rtol = 1e-10
        @test dot(x, y) > 0
    end

    @test_throws DimensionMismatch GLLVM._SchurUOperator(precision, randn(p + 1, K), Wsites; sigma2 = 1.0)
    @test_throws ArgumentError GLLVM._SchurUOperator(precision, Lambda, Wsites; sigma2 = 0.0)
end

@testset "structured Schur SLQ logdet" begin
    Random.seed!(802)
    p, n, K = 16, 4, 2
    Lambda = 0.2 .* randn(p, K)
    Wsites = 0.1 .+ rand(p, n)
    R = randn(p, p)
    precision = Symmetric(R' * R + I)
    op = GLLVM._SchurUOperator(precision, Lambda, Wsites; sigma2 = 1.3)
    dense = Matrix(GLLVM._schur_u_dense(op))
    dense_logdet = logdet(cholesky(Symmetric(dense)))

    full_basis = sqrt(float(p)) .* Matrix{Float64}(I, p, p)
    exact_slq = GLLVM._slq_logdet(op, full_basis; lanczos_steps = p, reorth = true)
    @test exact_slq ≈ dense_logdet atol = 1e-8 rtol = 1e-8
    @test GLLVM._schur_u_logdet(op; method = :dense) ≈ dense_logdet atol = 1e-10 rtol = 1e-10
    @test GLLVM._schur_u_logdet(op; method = :auto, dense_cutoff = p) ≈ dense_logdet atol = 1e-10 rtol = 1e-10
    @test GLLVM._schur_u_logdet(op; method = :slq, probes = full_basis,
        lanczos_steps = p, reorth = true) ≈ dense_logdet atol = 1e-8 rtol = 1e-8
    @test GLLVM._schur_u_logdet(op; method = :auto, dense_cutoff = 0,
        probes = full_basis, lanczos_steps = p, reorth = true) ≈ dense_logdet atol = 1e-8 rtol = 1e-8

    rng = MersenneTwister(803)
    probes = GLLVM._rademacher_probes(rng, p, 12)
    estimate_1 = GLLVM._slq_logdet(op, probes; lanczos_steps = 12, reorth = true)
    estimate_2 = GLLVM._slq_logdet(op, probes; lanczos_steps = 12, reorth = true)
    @test estimate_1 == estimate_2
    @test isfinite(estimate_1)
    @test_throws ArgumentError GLLVM._schur_u_logdet(op; method = :wat)
    @test_throws ArgumentError GLLVM._schur_u_logdet(op; dense_cutoff = -1)
end
