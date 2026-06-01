using GLLVM, Test, Random, LinearAlgebra, SparseArrays, Distributions, ForwardDiff

function structured_central_difference_gradient(f, theta; h = 1e-6)
    g = similar(theta)
    @inbounds for i in eachindex(theta)
        step = h * max(1.0, abs(theta[i]))
        theta_plus = copy(theta)
        theta_minus = copy(theta)
        theta_plus[i] += step
        theta_minus[i] -= step
        g[i] = (f(theta_plus) - f(theta_minus)) / (2 * step)
    end
    return g
end

@testset "structured Poisson Laplace prototype" begin
    Random.seed!(821)
    p, n, K = 6, 5, 2
    β = fill(log(1.7), p)
    Λ = 0.18 .* randn(p, K)
    Y = rand.(Poisson.(exp.(β .+ 0.1 .* randn(p, n))))
    precision = Symmetric(spdiagm(0 => fill(1.4, p)))
    dense_precision = Symmetric(Matrix(parent(precision)))

    @test GLLVM._structured_poisson_logdet_precision(precision) ≈
        GLLVM._structured_poisson_logdet_precision(dense_precision) atol = 1e-12 rtol = 1e-12

    l1, S1, W1 = GLLVM._structured_poisson_lsw(Y, Λ, β, zeros(p), zeros(K, n))
    S2 = similar(S1)
    W2 = similar(W1)
    l2 = GLLVM._structured_poisson_lsw!(S2, W2, Y, Λ, β, zeros(p), zeros(K, n))
    @test l2 ≈ l1 atol = 1e-12 rtol = 1e-12
    @test S2 ≈ S1 atol = 1e-12 rtol = 1e-12
    @test W2 ≈ W1 atol = 1e-12 rtol = 1e-12

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

@testset "structured Poisson implicit gradient" begin
    Random.seed!(824)
    p, n, K = 4, 3, 1
    β = fill(log(1.4), p)
    Λ = 0.08 .* randn(p, K)
    Y = rand.(Poisson.(exp.(β .+ 0.05 .* randn(p, n))))
    precision = Symmetric(spdiagm(
        -1 => fill(-0.10, p - 1),
         0 => fill(1.25, p),
         1 => fill(-0.10, p - 1)))
    θ0 = vcat(β, GLLVM.pack_lambda(Λ))

    loglik = θ -> GLLVM._structured_poisson_marginal_loglik_laplace(
        Y, GLLVM.unpack_lambda(θ[(p + 1):end], p, K), θ[1:p], precision;
        sigma2 = 0.5, logdet_method = :dense, mode_solve = :dense,
        maxiter = 100, tol = 1e-12)
    value, gimp = GLLVM._structured_poisson_implicit_value_grad(
        θ0, Y, precision, p, K; sigma2 = 0.5, logdet_method = :dense,
        mode_solve = :dense, maxiter = 100, tol = 1e-12)
    gfd = structured_central_difference_gradient(loglik, θ0)

    @test value ≈ loglik(θ0) atol = 1e-10 rtol = 1e-10
    @test all(isfinite, gimp)
    @test all(isfinite, gfd)
    @test maximum(abs.(gimp .- gfd)) ≤ 1e-6

    mode = GLLVM._structured_poisson_mode(
        Y, Λ, β, precision; sigma2 = 0.5, mode_solve = :dense,
        maxiter = 100, tol = 1e-12)
    x0 = GLLVM._structured_poisson_pack_mode(mode.U, mode.Z)
    m = length(x0)
    qF = allx -> GLLVM._structured_poisson_qF(
        Y, precision, allx[1:m], allx[(m + 1):end], p, K;
        sigma2 = 0.5, logdet_method = :dense)
    J = ForwardDiff.jacobian(qF, vcat(x0, θ0))
    qx = vec(J[1, 1:m])
    Fx = J[2:end, 1:m]
    dense_adj = Fx' \ qx
    schur_adj = GLLVM._structured_poisson_adjoint_solve(
        qx, Y, Λ, β, precision, mode.U, mode.Z; sigma2 = 0.5,
        mode_solve = :dense)
    cg_adj = GLLVM._structured_poisson_adjoint_solve(
        qx, Y, Λ, β, precision, mode.U, mode.Z; sigma2 = 0.5,
        mode_solve = :cg, cg_tol = 1e-12, cg_maxiter = 100)
    @test maximum(abs.(schur_adj .- dense_adj)) ≤ 1e-8
    @test maximum(abs.(cg_adj .- dense_adj)) ≤ 1e-8
end

@testset "structured Poisson internal fitter" begin
    Random.seed!(823)
    p, n, K = 5, 8, 1
    β = fill(log(1.5), p)
    Λ = 0.10 .* randn(p, K)
    Y = rand.(Poisson.(exp.(β .+ 0.08 .* randn(p, n))))
    precision = Symmetric(spdiagm(
        -1 => fill(-0.15, p - 1),
         0 => fill(1.3, p),
         1 => fill(-0.15, p - 1)))

    dense = GLLVM._fit_structured_poisson_laplace(
        Y, precision; K = K, sigma2 = 0.5, mode_solve = :dense,
        logdet_method = :dense, iterations = 4, g_tol = 1e-4,
        cg_tol = 1e-10, maxiter = 80, tol = 1e-9)
    cg = GLLVM._fit_structured_poisson_laplace(
        Y, precision; K = K, sigma2 = 0.5, mode_solve = :cg,
        logdet_method = :dense, iterations = 4, g_tol = 1e-4,
        cg_tol = 1e-10, maxiter = 80, tol = 1e-9)
    cg_finite = GLLVM._fit_structured_poisson_laplace(
        Y, precision; K = K, sigma2 = 0.5, mode_solve = :cg,
        logdet_method = :dense, iterations = 4, g_tol = 1e-4,
        cg_tol = 1e-10, maxiter = 80, tol = 1e-9, gradient = :finite)
    cg_cold = GLLVM._fit_structured_poisson_laplace(
        Y, precision; K = K, sigma2 = 0.5, mode_solve = :cg,
        logdet_method = :dense, iterations = 4, g_tol = 1e-4,
        cg_tol = 1e-10, maxiter = 80, tol = 1e-9, mode_cache = false)

    @test dense.loglik >= dense.initial_loglik - 1e-7
    @test cg.loglik >= cg.initial_loglik - 1e-7
    @test cg.loglik ≈ dense.loglik atol = 1e-5 rtol = 1e-5
    @test cg.loglik ≈ cg_finite.loglik atol = 1e-5 rtol = 1e-5
    @test cg.loglik ≈ cg_cold.loglik atol = 1e-5 rtol = 1e-5
    @test cg.β ≈ dense.β atol = 1e-5 rtol = 1e-5
    @test cg.Λ ≈ dense.Λ atol = 1e-5 rtol = 1e-5
    @test cg.mode_cache === true
    @test cg_cold.mode_cache === false
    @test cg.gradient === :implicit
    @test cg_finite.gradient === :finite
    @test dense.objective_calls > 0
    @test cg.objective_calls > 0

    @test_throws ArgumentError GLLVM._fit_structured_poisson_laplace(
        Y, precision; K = 0, sigma2 = 0.5)
    @test_throws ArgumentError GLLVM._fit_structured_poisson_laplace(
        Y, precision; K = K, sigma2 = 0.5, gradient = :wat)
    @test_throws DimensionMismatch GLLVM._fit_structured_poisson_laplace(
        Y, precision; K = K, sigma2 = 0.5, β_init = zeros(p + 1))
    @test_throws DimensionMismatch GLLVM._structured_poisson_mode(
        Y, Λ, β, precision; sigma2 = 0.5, U_init = zeros(p + 1))
    @test_throws DimensionMismatch GLLVM._structured_poisson_mode(
        Y, Λ, β, precision; sigma2 = 0.5, Z_init = zeros(K + 1, n))
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
