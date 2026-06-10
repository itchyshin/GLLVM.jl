using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Central finite-difference gradient (matches test/test_family_forwarddiff_gradients.jl).
function _central_fd_gradient(f, theta; h = 1e-6)
    g = similar(theta)
    @inbounds for i in eachindex(theta)
        step = h * max(1.0, abs(theta[i]))
        tp = copy(theta); tp[i] += step
        tm = copy(theta); tm[i] -= step
        g[i] = (f(tp) - f(tm)) / (2 * step)
    end
    return g
end

_max_rel_err(a, b) = maximum(abs.(a .- b) ./ max.(1.0, abs.(b)))

@testset "NB1 + standalone Lognormal" begin

    # ---------------------------------------------------------------------
    # NB1 — marginal sanity + FD gradient + recovery
    # ---------------------------------------------------------------------
    @testset "NB1 marginal reduces toward Poisson as φ → 0" begin
        Random.seed!(401)
        p, K, n = 5, 2, 30
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0])
        Λ = 0.3 .* randn(p, K)
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]
        ll_nb1 = GLLVM.nb1_marginal_loglik_laplace(Y, Λ, β, 1e-6)
        ll_pois = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test ll_nb1 ≈ ll_pois atol = 1e-3
    end

    @testset "NB1 Λ = 0 reduces to independent NB1-regression loglik (exact)" begin
        Random.seed!(402)
        p, K, n = 4, 2, 40
        β = log.([5.0, 8.0, 4.0, 6.0])
        φ = 0.8
        μ = exp.(β)
        # NB1 ⇒ NegativeBinomial(size = μ/φ, prob = 1/(1+φ)).
        Y = [rand(NegativeBinomial(μ[t] / φ, 1 / (1 + φ))) for t in 1:p, s in 1:n]
        ll = GLLVM.nb1_marginal_loglik_laplace(Y, zeros(p, K), β, φ)
        ll_indep = sum(logpdf(NegativeBinomial(μ[t] / φ, 1 / (1 + φ)), Y[t, s])
                       for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-7
    end

    @testset "NB1 marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(403)
        p, n, K = 4, 8, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(4.0), p)
        Λ0 = GLLVM.pack_lambda(0.1 .* randn(p, K))
        φ_true = 1.3
        μ = exp.(β0)
        Y = [rand(NegativeBinomial(μ[t] / φ_true, 1 / (1 + φ_true))) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0, log(φ_true))
        f = θ -> -GLLVM.nb1_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], exp(θ[p + rr + 1]))
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gad, gfd)
        @info "NB1 marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    @testset "NB1 implicit fit gradient matches FD ≤ 1e-6" begin
        # The fit driver uses marginal_loglik_laplace_implicit_value_grad; check
        # the value+gradient it actually optimises against central differences.
        Random.seed!(404)
        p, n, K = 4, 10, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(5.0), p)
        Λ0 = GLLVM.pack_lambda(0.15 .* randn(p, K))
        φ_true = 1.0
        μ = exp.(β0)
        Y = [rand(NegativeBinomial(μ[t] / φ_true, 1 / (1 + φ_true))) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        θ0 = vcat(β0, Λ0, log(φ_true))
        family_fromθ = θ -> GLLVM.NB1(GLLVM._positive_from_log(θ[end]))
        vg = θ -> GLLVM.marginal_loglik_laplace_implicit_value_grad(
            family_fromθ, Y, N, θ, p, K, LogLink())
        _, gimp = vg(θ0)
        f = θ -> vg(θ)[1]
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gimp, gfd)
        @info "NB1 implicit fit-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    @testset "NB1 simulate → fit → recover (β, ΛΛ', φ)" begin
        Random.seed!(405)
        p, K, n = 6, 2, 500
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.5 .* randn(p, K)
        φ_true = 1.0
        Y = simulate(NB1(φ_true), β_true, Λ_true, n;
                     dispersion = φ_true, seed = 4051)
        Yint = round.(Int, Y)
        fit = fit_nb1_gllvm(Yint; K = K)
        @info "NB1 fit" converged=fit.converged φ̂=fit.φ
        @test size(fit.Λ) == (p, K)
        @test maximum(abs.(fit.β .- β_true)) < 0.5
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.6
        @test isfinite(fit.φ) && fit.φ > 0
        @test fit.φ ≈ φ_true rtol = 0.6      # dispersion is identifiable-but-noisy
    end

    @testset "NB1 link_residual: matches log1p((1+φ)/μ̂) formula and is finite" begin
        Random.seed!(406)
        p, K, n = 4, 1, 300
        β_true = log.([5.0, 8.0, 4.0, 6.0])
        Λ_true = 0.4 .* randn(p, K)
        φ_true = 0.7
        Y = round.(Int, simulate(NB1(φ_true), β_true, Λ_true, n;
                                 dispersion = φ_true, seed = 4061))
        fit = fit_nb1_gllvm(Y; K = K)
        σ2d = link_residual(fit, Y)
        @test length(σ2d) == p
        @test all(isfinite, σ2d) && all(>(0), σ2d)
        # Single-arg formula matches the from-fit vector at the fit's mean.
        @test link_residual(GLLVM.NB1(fit.φ), LogLink(), 5.0, fit.φ) ≈ log1p((1 + fit.φ) / 5.0)
    end

    # ---------------------------------------------------------------------
    # Lognormal — marginal identity + FD gradient + recovery
    # ---------------------------------------------------------------------
    @testset "Lognormal marginal = Gaussian(log y) + Jacobian (exact)" begin
        Random.seed!(411)
        p, K, n = 5, 2, 50
        β = [0.5, 1.0, -0.3, 0.8, 0.2]
        Λ = 0.3 .* randn(p, K)
        σ = 0.6
        Y = simulate(LogNormal(), β, Λ, n; dispersion = σ, seed = 4111)
        Z = log.(Y)
        # Reference: Gaussian marginal of centred log-responses minus Σ log y.
        ref = GLLVM.gaussian_marginal_loglik(Z .- β, Λ, σ) - sum(Z)
        ll = GLLVM.lognormal_marginal_loglik(Y, Λ, β, σ)
        @test ll ≈ ref atol = 1e-9
    end

    @testset "Lognormal marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(412)
        p, K, n = 4, 1, 12
        rr = GLLVM.rr_theta_len(p, K)
        β0 = [0.4, 0.9, -0.2, 0.6]
        Λ0 = GLLVM.pack_lambda(0.2 .* randn(p, K))
        σ_true = 0.7
        Y = simulate(LogNormal(), β0, GLLVM.unpack_lambda(Λ0, p, K), n;
                     dispersion = σ_true, seed = 4121)
        θ0 = vcat(β0, Λ0, log(σ_true))
        f = θ -> -GLLVM.lognormal_marginal_loglik(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
            exp(θ[p + rr + 1]))
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gad, gfd)
        @info "Lognormal marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    @testset "Lognormal simulate → fit → recover (β, ΛΛ', σ)" begin
        Random.seed!(413)
        p, K, n = 6, 2, 600
        β_true = [0.5, 1.2, -0.4, 0.9, 0.1, 0.7]
        Λ_true = 0.5 .* randn(p, K)
        σ_true = 0.5
        Y = simulate(LogNormal(), β_true, Λ_true, n; dispersion = σ_true, seed = 4131)
        fit = fit_lognormal_gllvm(Y; K = K)
        @info "Lognormal fit" converged=fit.converged σ̂=fit.σ
        @test size(fit.Λ) == (p, K)
        @test maximum(abs.(fit.β .- β_true)) < 0.2
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.7
        @test fit.σ ≈ σ_true rtol = 0.15
        # Σ_y recovery on the log scale (rotation-invariant): ΛΛᵀ + σ²I.
        Σ_true = Λ_true * Λ_true' + σ_true^2 * I
        Σ_hat = fit.Λ * fit.Λ' + fit.σ^2 * I
        @test norm(Σ_true - Σ_hat) / norm(Σ_true) < 0.20
    end

    @testset "Lognormal link_residual = σ² (μ̂-free)" begin
        Random.seed!(414)
        p, K, n = 4, 1, 300
        β_true = [0.5, 1.0, -0.3, 0.8]
        Λ_true = 0.4 .* randn(p, K)
        σ_true = 0.6
        Y = simulate(LogNormal(), β_true, Λ_true, n; dispersion = σ_true, seed = 4141)
        fit = fit_lognormal_gllvm(Y; K = K)
        σ2d = link_residual(fit, Y)
        @test length(σ2d) == p
        @test all(σ2d .≈ fit.σ^2)
    end
end
