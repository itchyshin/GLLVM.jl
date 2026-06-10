# Tests for Wald confidence intervals on the one-part non-Gaussian fitters
# (src/confint_families.jl).
#
# For each family we fit a tiny model (small p, n, K = 1) with a fixed RNG seed,
# call `confint(fit; Y = ...)`, and check:
#   1. shape/finiteness of the returned NamedTuple (right fields, right length,
#      monotone bounds, positive SEs where the Hessian is PD);
#   2. agreement of the package's ForwardDiff-Hessian SEs with a *central
#      finite-difference* Hessian of the SAME packed NLL closure, to a loose
#      tolerance — the FD check is the core correctness assertion.
#
# Self-runnable: `julia --project=. test/test_confint_families.jl`.
#
# Note: the project test environment does not depend on StableRNGs, so these
# tests use `Random.seed!` for reproducibility — matching every other family fit
# test in this suite (e.g. test_poisson_fit.jl).

using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Central finite-difference Hessian of a scalar function f at x. The default
# step (1e-3) balances truncation error against floating-point cancellation in
# the mixed-partial 4-point stencil for an NLL of magnitude ~1e3.
function _fd_hessian(f, x::AbstractVector; h::Real = 1e-3)
    n = length(x)
    H = zeros(n, n)
    f0 = f(x)
    for i in 1:n
        for j in i:n
            if i == j
                xp = copy(x); xp[i] += h
                xm = copy(x); xm[i] -= h
                H[i, i] = (f(xp) - 2 * f0 + f(xm)) / h^2
            else
                xpp = copy(x); xpp[i] += h; xpp[j] += h
                xpm = copy(x); xpm[i] += h; xpm[j] -= h
                xmp = copy(x); xmp[i] -= h; xmp[j] += h
                xmm = copy(x); xmm[i] -= h; xmm[j] -= h
                v = (f(xpp) - f(xpm) - f(xmp) + f(xmm)) / (4h^2)
                H[i, j] = v
                H[j, i] = v
            end
        end
    end
    return H
end

# SEs implied by a Hessian of the NLL (observed information): sqrt(diag(inv(H))).
function _se_from_hessian(H)
    Hsym = (H .+ H') ./ 2
    Σ = inv(Hsym)
    return sqrt.(diag(Σ))
end

# Common structural checks on a confint NamedTuple with `npar` rows.
function _check_ci_shape(ci, npar::Integer)
    @test propertynames(ci) == (:term, :estimate, :lower, :upper, :se, :pd_hessian)
    @test length(ci.term) == npar
    @test length(ci.estimate) == npar
    @test length(ci.lower) == npar
    @test length(ci.upper) == npar
    @test length(ci.se) == npar
    @test ci.pd_hessian isa Bool
    if ci.pd_hessian
        @test all(isfinite, ci.estimate)
        @test all(isfinite, ci.se)
        @test all(ci.se .> 0)
        @test all(isfinite, ci.lower)
        @test all(isfinite, ci.upper)
        @test all(ci.lower .< ci.upper)
    end
end

# Compare the package's reported SEs to those implied by a central-FD Hessian of
# the SAME packed NLL closure. Only meaningful when the package found a PD
# Hessian. Loose relative tolerance: the inner Laplace mode is itself iterative,
# so the FD Hessian and the AD Hessian agree only to a few digits.
function _check_fd_se_agreement(ci, θ̂, nll; rtol = 0.15, atol = 1e-3)
    ci.pd_hessian || return  # nothing to compare against
    H_fd = _fd_hessian(nll, θ̂)
    se_fd = _se_from_hessian(H_fd)
    @test all(isfinite, se_fd)
    for i in eachindex(ci.se)
        @test isapprox(ci.se[i], se_fd[i]; rtol = rtol, atol = atol)
    end
end

@testset "confint — non-Gaussian one-part families" begin

    @testset "Poisson" begin
        Random.seed!(2026)
        p, K, n = 4, 1, 120
        β_true = log.([4.0, 6.0, 3.0, 5.0])
        Λ_true = reshape(0.5 .* randn(p), p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_poisson_gllvm(Y; K = K)
        @test fit.converged
        ci = confint(fit; Y = Y)

        rr = GLLVM.rr_theta_len(p, K)
        npar = p + rr
        _check_ci_shape(ci, npar)
        @test ci.term[1:p] == ["beta[$j]" for j in 1:p]

        θ̂ = vcat(fit.β, GLLVM.pack_lambda(fit.Λ))
        nll = θ -> -GLLVM.poisson_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], fit.link)
        _check_fd_se_agreement(ci, θ̂, nll)

        # parm selector still works (mirrors the Gaussian confint behaviour).
        ci1 = confint(fit; Y = Y, parm = "beta[1]")
        @test ci1.term == ["beta[1]"]
    end

    @testset "Binomial (Bernoulli)" begin
        Random.seed!(2027)
        p, K, n = 4, 1, 200
        β_true = [0.3, -0.2, 0.6, -0.5]
        Λ_true = reshape(0.5 .* randn(p), p, K)
        η = β_true .+ Λ_true * randn(K, n)
        μ = @. 1 / (1 + exp(-η))
        Y = [rand() < μ[t, s] ? 1 : 0 for t in 1:p, s in 1:n]

        fit = fit_binomial_gllvm(Y; K = K)
        @test fit.converged
        ci = confint(fit; Y = Y)

        rr = GLLVM.rr_theta_len(p, K)
        npar = p + rr
        _check_ci_shape(ci, npar)

        Nm = fill(1, p, n)
        θ̂ = vcat(fit.β, GLLVM.pack_lambda(fit.Λ))
        nll = θ -> -GLLVM.binomial_marginal_loglik_laplace(
            Y, Nm, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], fit.link)
        _check_fd_se_agreement(ci, θ̂, nll)
    end

    @testset "Negative Binomial" begin
        Random.seed!(2028)
        p, K, n = 4, 1, 200
        r_true = 5.0
        β_true = log.([4.0, 6.0, 3.0, 5.0])
        Λ_true = reshape(0.4 .* randn(p), p, K)
        η = β_true .+ Λ_true * randn(K, n)
        μ = exp.(η)
        Y = [rand(NegativeBinomial(r_true, r_true / (r_true + μ[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_nb_gllvm(Y; K = K)
        @test fit.converged
        ci = confint(fit; Y = Y)

        rr = GLLVM.rr_theta_len(p, K)
        npar = p + rr + 1
        _check_ci_shape(ci, npar)
        @test ci.term[end] == "r"
        # r is log-parameterised ⇒ estimate equals fit.r on the raw scale.
        @test isapprox(ci.estimate[end], fit.r; rtol = 1e-8)

        θ̂ = vcat(fit.β, GLLVM.pack_lambda(fit.Λ), log(fit.r))
        nll = θ -> -GLLVM.nb_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
            GLLVM._positive_from_log(θ[p + rr + 1]); link = fit.link)
        _check_fd_se_agreement(ci, θ̂, nll)
    end

    @testset "Beta" begin
        Random.seed!(2029)
        p, K, n = 4, 1, 200
        φ_true = 15.0
        β_true = [0.2, -0.3, 0.5, -0.4]
        Λ_true = reshape(0.4 .* randn(p), p, K)
        η = β_true .+ Λ_true * randn(K, n)
        μ = @. 1 / (1 + exp(-η))
        Y = [clamp(rand(Beta(μ[t, s] * φ_true, (1 - μ[t, s]) * φ_true)), 1e-4, 1 - 1e-4)
             for t in 1:p, s in 1:n]

        fit = fit_beta_gllvm(Y; K = K)
        @test fit.converged
        ci = confint(fit; Y = Y)

        rr = GLLVM.rr_theta_len(p, K)
        npar = p + rr + 1
        _check_ci_shape(ci, npar)
        @test ci.term[end] == "phi"
        @test isapprox(ci.estimate[end], fit.φ; rtol = 1e-8)

        θ̂ = vcat(fit.β, GLLVM.pack_lambda(fit.Λ), log(fit.φ))
        nll = θ -> -GLLVM.beta_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
            GLLVM._positive_from_log(θ[p + rr + 1]); link = fit.link)
        _check_fd_se_agreement(ci, θ̂, nll)
    end

    @testset "Gamma (guarded)" begin
        Random.seed!(2030)
        p, K, n = 4, 1, 200
        α_true = 4.0
        β_true = log.([2.0, 3.0, 1.5, 2.5])
        Λ_true = reshape(0.3 .* randn(p), p, K)
        η = β_true .+ Λ_true * randn(K, n)
        μ = exp.(η)
        Y = [rand(Gamma(α_true, μ[t, s] / α_true)) for t in 1:p, s in 1:n]

        fit = fit_gamma_gllvm(Y; K = K)
        ci = confint(fit; Y = Y)

        rr = GLLVM.rr_theta_len(p, K)
        npar = p + rr + 1
        # Shape/finiteness must always hold; Gamma's Hessian may be non-PD, in
        # which case the guard returns NaN bounds with pd_hessian = false.
        _check_ci_shape(ci, npar)
        @test ci.term[end] == "alpha"
        @test isapprox(ci.estimate[end], fit.α; rtol = 1e-8)

        θ̂ = vcat(fit.β, GLLVM.pack_lambda(fit.Λ), log(fit.α))
        nll = θ -> -GLLVM.gamma_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
            GLLVM._positive_from_log(θ[p + rr + 1]); link = fit.link)
        # Only asserts when the package itself reports a PD Hessian.
        _check_fd_se_agreement(ci, θ̂, nll)
        if !ci.pd_hessian
            @info "Gamma confint: Hessian not PD at the MLE — guard returned NaN bounds (expected fragility)."
        end
    end

    @testset "Ordinal" begin
        Random.seed!(2031)
        p, K, n = 4, 1, 250
        C = 3
        τ_true = [-0.6, 0.8]
        Λ_true = reshape(0.6 .* randn(p), p, K)
        η = Λ_true * randn(K, n)
        function _draw_ord(ηts)
            P1 = 1 / (1 + exp(-(τ_true[1] - ηts)))
            P2 = 1 / (1 + exp(-(τ_true[2] - ηts)))
            u = rand()
            u < P1 ? 1 : (u < P2 ? 2 : 3)
        end
        Y = [_draw_ord(η[t, s]) for t in 1:p, s in 1:n]

        fit = fit_ordinal_gllvm(Y; K = K)
        @test fit.converged
        ci = confint(fit; Y = Y)

        rr = GLLVM.rr_theta_len(p, K)
        npar = rr + (C - 1)
        _check_ci_shape(ci, npar)
        @test ci.term[end - (C - 2):end] == ["psi[$c]" for c in 1:(C - 1)]

        # Reconstruct ψ from τ exactly as the confint method does.
        τ = fit.τ
        ψ = similar(τ)
        ψ[1] = τ[1]
        for c in 2:length(τ)
            ψ[c] = log(τ[c] - τ[c - 1])
        end
        θ̂ = vcat(GLLVM.pack_lambda(fit.Λ), ψ)
        nll = θ -> -GLLVM.ordinal_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[1:rr], p, K),
            GLLVM._unpack_cutpoints(θ[(rr + 1):(rr + C - 1)]))
        _check_fd_se_agreement(ci, θ̂, nll)
    end
end
