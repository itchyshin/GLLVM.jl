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
    @inbounds for s in 1:n
        A = Matrix{Float64}(I, K, K)
        for t in 1:p
            A .+= Wsites[t, s] .* (Lambda[t, :] * Lambda[t, :]')
        end
        @test op.Ainvs[s] ≈ inv(Symmetric(A)) atol = 1e-12 rtol = 1e-12
    end

    S_work = Matrix{Float64}(undef, p, p)
    dense_work = Matrix(GLLVM._schur_u_dense!(
        S_work, op, zeros(p), zeros(p), zeros(K), zeros(K)))
    @test dense_work ≈ dense atol = 1e-10 rtol = 1e-10
    @test_throws DimensionMismatch GLLVM._schur_u_dense!(
        zeros(p + 1, p), op, zeros(p), zeros(p), zeros(K), zeros(K))

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

    ws = GLLVM._SchurUOperatorWorkspace(Float64, p, K, n)
    op_ws = GLLVM._SchurUOperator(precision, Lambda, Wsites, ws; sigma2 = 0.7)
    @test op_ws.Wsum === ws.Wsum
    @test op_ws.Achols === ws.Achols
    @test op_ws.Ainvs === ws.Ainvs
    @test Matrix(GLLVM._schur_u_dense(op_ws)) ≈ dense atol = 1e-10 rtol = 1e-10

    Wsites2 = Wsites .+ 0.05
    op_ws2 = GLLVM._SchurUOperator(precision, Lambda, Wsites2, ws; sigma2 = 0.7)
    op_ref2 = GLLVM._SchurUOperator(precision, Lambda, Wsites2; sigma2 = 0.7)
    @test Matrix(GLLVM._schur_u_dense(op_ws2)) ≈
        Matrix(GLLVM._schur_u_dense(op_ref2)) atol = 1e-10 rtol = 1e-10

    b = randn(p)
    x_cg = zeros(p)
    cg = GLLVM._schur_u_cg!(x_cg, op, b; tol = 1e-10, maxiter = 4 * p)
    @test cg.converged
    @test x_cg ≈ dense \ b atol = 1e-8 rtol = 1e-8

    scratch = (r = zeros(p), d = zeros(p), q = zeros(p),
        tmp = zeros(K), sol = zeros(K))
    x_scratch = zeros(p)
    cg_scratch = GLLVM._schur_u_cg!(
        x_scratch, op, b, scratch.r, scratch.d, scratch.q,
        scratch.tmp, scratch.sol; tol = 1e-10, maxiter = 4 * p)
    @test cg_scratch.converged
    @test x_scratch ≈ x_cg atol = 1e-10 rtol = 1e-10

    @test_throws DimensionMismatch GLLVM._SchurUOperator(precision, randn(p + 1, K), Wsites; sigma2 = 1.0)
    @test_throws ArgumentError GLLVM._SchurUOperator(precision, Lambda, Wsites; sigma2 = 0.0)
    @test_throws DimensionMismatch GLLVM._SchurUOperator(
        precision, Lambda, Wsites, GLLVM._SchurUOperatorWorkspace(Float64, p + 1, K, n);
        sigma2 = 0.7)
    @test_throws DimensionMismatch GLLVM._schur_u_cg!(zeros(p + 1), op, b)
    @test_throws DimensionMismatch GLLVM._schur_u_cg!(
        zeros(p), op, b, zeros(p - 1), scratch.d, scratch.q,
        scratch.tmp, scratch.sol)
    @test_throws ArgumentError GLLVM._schur_u_cg!(zeros(p), op, b; tol = 0.0)
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
    exact_slq_inv, Xfull = GLLVM._slq_logdet_invprobes(
        op, full_basis; lanczos_steps = p, reorth = true)
    @test exact_slq_inv ≈ dense_logdet atol = 1e-8 rtol = 1e-8
    @test Xfull ≈ dense \ full_basis atol = 1e-7 rtol = 1e-7
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

    orthogonal = GLLVM._orthogonal_probes(MersenneTwister(804), p, 5)
    @test size(orthogonal) == (p, 5)
    @test diag(orthogonal' * orthogonal) ≈ fill(float(p), 5) atol = 1e-10 rtol = 1e-10
    @test maximum(abs, orthogonal' * orthogonal - float(p) * I) ≤ 1e-10
    orthogonal_estimate = GLLVM._slq_logdet(op, orthogonal; lanczos_steps = 12, reorth = true)
    @test isfinite(orthogonal_estimate)

    @test_throws ArgumentError GLLVM._schur_u_logdet(op; method = :wat)
    @test_throws ArgumentError GLLVM._schur_u_logdet(op; dense_cutoff = -1)
    @test_throws DimensionMismatch GLLVM._slq_logdet_invprobes(
        op, zeros(p + 1, 2); lanczos_steps = 2)
    @test_throws ArgumentError GLLVM._orthogonal_probes(MersenneTwister(805), p, p + 1)
end
