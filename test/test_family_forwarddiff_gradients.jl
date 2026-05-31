using GLLVM, Test, Random, Distributions, ForwardDiff

function central_difference_gradient(f, theta; h = 1e-6)
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

@testset "non-Gaussian fitter objectives: ForwardDiff gradients" begin
    Random.seed!(20260531)
    p, n, K = 4, 8, 1
    rr = GLLVM.rr_theta_len(p, K)
    lambda0 = 0.1 .* randn(p, K)
    theta_lambda0 = GLLVM.pack_lambda(lambda0)
    beta_log = fill(log(3.0), p)
    beta_logit = fill(0.2, p)

    cases = Tuple{String, Function, Vector{Float64}}[]

    Y_binomial = [rand(Binomial(5, 0.55)) for _ in 1:p, _ in 1:n]
    N_binomial = fill(5, p, n)
    push!(cases, (
        "binomial",
        theta -> -GLLVM.binomial_marginal_loglik_laplace(
            Y_binomial, N_binomial,
            GLLVM.unpack_lambda(theta[(p + 1):(p + rr)], p, K),
            theta[1:p], LogitLink()),
        vcat(beta_logit, theta_lambda0),
    ))

    Y_poisson = [rand(Poisson(3.0)) for _ in 1:p, _ in 1:n]
    push!(cases, (
        "poisson",
        theta -> -GLLVM.poisson_marginal_loglik_laplace(
            Y_poisson,
            GLLVM.unpack_lambda(theta[(p + 1):(p + rr)], p, K),
            theta[1:p]),
        vcat(beta_log, theta_lambda0),
    ))

    Y_nb = [rand(NegativeBinomial(8.0, 8.0 / (8.0 + 3.0))) for _ in 1:p, _ in 1:n]
    push!(cases, (
        "negative-binomial",
        theta -> -GLLVM.nb_marginal_loglik_laplace(
            Y_nb,
            GLLVM.unpack_lambda(theta[(p + 1):(p + rr)], p, K),
            theta[1:p], exp(theta[p + rr + 1])),
        vcat(beta_log, theta_lambda0, log(8.0)),
    ))

    Y_beta = [rand(Beta(3.0, 3.0)) for _ in 1:p, _ in 1:n]
    push!(cases, (
        "beta",
        theta -> -GLLVM.beta_marginal_loglik_laplace(
            Y_beta,
            GLLVM.unpack_lambda(theta[(p + 1):(p + rr)], p, K),
            theta[1:p], exp(theta[p + rr + 1])),
        vcat(beta_logit, theta_lambda0, log(6.0)),
    ))

    Y_gamma = [rand(Gamma(3.0, 1.0)) for _ in 1:p, _ in 1:n]
    push!(cases, (
        "gamma",
        theta -> -GLLVM.gamma_marginal_loglik_laplace(
            Y_gamma,
            GLLVM.unpack_lambda(theta[(p + 1):(p + rr)], p, K),
            theta[1:p], exp(theta[p + rr + 1])),
        vcat(beta_log, theta_lambda0, log(3.0)),
    ))

    Y_ordinal = [rand(1:3) for _ in 1:p, _ in 1:n]
    psi0 = [-0.5, log(1.2)]
    push!(cases, (
        "ordinal",
        theta -> -GLLVM.ordinal_marginal_loglik_laplace(
            Y_ordinal,
            GLLVM.unpack_lambda(theta[1:rr], p, K),
            GLLVM._unpack_cutpoints(theta[(rr + 1):(rr + 2)])),
        vcat(theta_lambda0, psi0),
    ))

    @testset "$name gradient" for (name, objective, theta0) in cases
        gad = ForwardDiff.gradient(objective, theta0)
        gfd = central_difference_gradient(objective, theta0)
        @test all(isfinite, gad)
        @test all(isfinite, gfd)
        @test maximum(abs.(gad .- gfd)) ≤ 1e-6
    end
end
