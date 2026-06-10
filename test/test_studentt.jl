using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Central finite-difference gradient (matches test/test_family_forwarddiff_gradients.jl
# and test/test_nb1_lognormal.jl). NOTE the Float32 '2f0' stencil trap: the divisor
# is written `2 * step`, NOT `2f0 * step`, so it stays in the same eltype as theta.
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

@testset "Student-t (heavy-tailed continuous, fixed ν)" begin

    # ---------------------------------------------------------------------
    # Marginal sanity: as ν → ∞ the Student-t marginal → Gaussian marginal.
    # On the identity link the Gaussian GLLVM marginal is the closed-form
    # gaussian_marginal_loglik of the centred responses (Λ Λᵀ + σ² I), so a large
    # ν Student-t Laplace marginal should match it closely.
    # ---------------------------------------------------------------------
    @testset "marginal → Gaussian as ν → ∞" begin
        Random.seed!(701)
        p, K, n = 5, 2, 40
        β = [0.5, 1.0, -0.3, 0.8, 0.2]
        Λ = 0.3 .* randn(p, K)
        σ = 0.7
        Y = [β[t] + (Λ * randn(K))[1] + σ * randn() for t in 1:p, s in 1:n]
        ll_t = GLLVM.studentt_marginal_loglik_laplace(Y, Λ, β, σ; ν = 1e6)
        ll_g = GLLVM.gaussian_marginal_loglik(Y .- β, Λ, σ)
        @test ll_t ≈ ll_g rtol = 1e-3
    end

    @testset "Λ = 0 reduces to independent location-t loglik (exact)" begin
        Random.seed!(702)
        p, K, n = 4, 2, 30
        β = [0.4, 0.9, -0.2, 0.6]
        σ = 0.8
        ν = 4.0
        Y = [β[t] + σ * rand(TDist(ν)) for t in 1:p, s in 1:n]
        ll = GLLVM.studentt_marginal_loglik_laplace(Y, zeros(p, K), β, σ; ν = ν)
        # Independent location-scale t log-density: logpdf(TDist(ν), (y−β)/σ) − log σ.
        ll_indep = sum(logpdf(TDist(ν), (Y[t, s] - β[t]) / σ) - log(σ)
                       for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-8
    end

    # ---------------------------------------------------------------------
    # FD gradient of the marginal: ForwardDiff and the implicit-fit gradient
    # must each match central differences to ≤ 1e-6.
    # ---------------------------------------------------------------------
    @testset "marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(703)
        p, n, K = 4, 8, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = [0.3, 0.7, -0.1, 0.5]
        Λ0 = GLLVM.pack_lambda(0.2 .* randn(p, K))
        σ_true = 0.9
        ν = 4.0
        Y = [β0[t] + σ_true * rand(TDist(ν)) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0, log(σ_true))
        f = θ -> -GLLVM.studentt_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
            exp(θ[p + rr + 1]); ν = ν)
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gad, gfd)
        @info "Student-t marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    @testset "implicit fit gradient matches FD ≤ 1e-6" begin
        # The fit driver uses marginal_loglik_laplace_aux_value_grad (the generic
        # scalar-aux implicit path); check the value+gradient it optimises against
        # central differences.
        Random.seed!(704)
        p, n, K = 4, 10, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = [0.5, 1.0, -0.2, 0.7]
        Λ0 = GLLVM.pack_lambda(0.15 .* randn(p, K))
        σ_true = 0.8
        ν = 4.0
        Y = [β0[t] + σ_true * rand(TDist(ν)) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        θ0 = vcat(β0, Λ0, log(σ_true))
        family_from_aux = aux -> GLLVM.StudentTFamily(ν, GLLVM._positive_from_log(aux[1]))
        vg = θ -> GLLVM.marginal_loglik_laplace_aux_value_grad(
            family_from_aux, Y, N, θ, p, K, IdentityLink())
        _, gimp = vg(θ0)
        f = θ -> vg(θ)[1]
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gimp, gfd)
        @info "Student-t implicit fit-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # simulate → fit → recover (β, ΛΛ' structure, σ). Convergence flag is
    # INFORMATIONAL (heavy tails make the surface mildly non-quadratic); assert
    # recovery within a GENEROUS MC tolerance, not fit.converged.
    # ---------------------------------------------------------------------
    @testset "simulate → fit → recover (β, ΛΛ', σ)" begin
        Random.seed!(705)
        p, K, n = 6, 2, 600
        β_true = [0.5, 1.2, -0.4, 0.9, 0.1, 0.7]
        Λ_true = 0.5 .* randn(p, K)
        σ_true = 0.8
        ν = 4.0
        Y = simulate(StudentTFamily(ν, σ_true), β_true, Λ_true, n;
                     dispersion = σ_true, seed = 7051)
        fit = fit_studentt_gllvm(Y; K = K, nu = ν)
        @info "Student-t fit" converged=fit.converged σ̂=fit.σ ν=fit.ν
        @test size(fit.Λ) == (p, K)
        @test fit.ν == ν                                   # ν is held fixed
        @test maximum(abs.(fit.β .- β_true)) < 0.3
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.6
        @test isfinite(fit.σ) && fit.σ > 0
        @test fit.σ ≈ σ_true rtol = 0.35                   # scale identifiable-but-noisy
    end

    @testset "fit is robust: a few gross outliers barely move β̂ (vs Gaussian)" begin
        # Bounded-influence sanity: contaminate ~3% of cells with huge values and
        # confirm the Student-t intercepts stay close to the clean truth. This is
        # the qualitative property the heavy tail buys; a Gaussian fit would chase
        # the outliers far more. Recovery-only (no convergence assertion).
        Random.seed!(706)
        p, K, n = 5, 1, 400
        β_true = [0.5, 1.0, -0.3, 0.8, 0.2]
        Λ_true = 0.4 .* randn(p, K)
        σ_true = 0.6
        ν = 4.0
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        Y = η .+ σ_true .* randn(p, n)                     # clean Gaussian core
        ncontam = round(Int, 0.03 * p * n)
        idx = randperm(p * n)[1:ncontam]
        Y[idx] .+= 30.0 .* sign.(randn(ncontam))          # gross outliers
        fit = fit_studentt_gllvm(Y; K = K, nu = ν)
        @info "Student-t robustness fit" converged=fit.converged σ̂=fit.σ
        @test maximum(abs.(fit.β .- β_true)) < 0.6
    end

    # ---------------------------------------------------------------------
    # link_residual: σ²_d = σ²·ν/(ν−2) on the identity (latent) scale, μ̂-free.
    # ---------------------------------------------------------------------
    @testset "link_residual = σ²·ν/(ν−2) (μ̂-free, identity)" begin
        Random.seed!(707)
        p, K, n = 4, 1, 300
        β_true = [0.5, 1.0, -0.3, 0.8]
        Λ_true = 0.4 .* randn(p, K)
        σ_true = 0.7
        ν = 4.0
        Y = simulate(StudentTFamily(ν, σ_true), β_true, Λ_true, n;
                     dispersion = σ_true, seed = 7071)
        fit = fit_studentt_gllvm(Y; K = K, nu = ν)
        σ2d = link_residual(fit, Y)
        @test length(σ2d) == p
        @test all(isfinite, σ2d) && all(>(0), σ2d)
        @test all(σ2d .≈ fit.σ^2 * ν / (ν - 2))
        # Single-arg formula matches the documented closed form.
        @test link_residual(StudentTFamily(ν, fit.σ), IdentityLink(), 0.0, fit.σ) ≈
              fit.σ^2 * ν / (ν - 2)
        # ν ≤ 2 ⇒ no finite variance ⇒ Inf (flagged, not silently clamped).
        @test link_residual(StudentTFamily(2.0, 1.0), IdentityLink(), 0.0, 1.0) == Inf
    end

    @testset "simulate(fit, n) round-trips through StudentTFit" begin
        Random.seed!(708)
        p, K, n = 4, 1, 50
        β_true = [0.3, 0.8, -0.2, 0.5]
        Λ_true = 0.3 .* randn(p, K)
        σ_true = 0.6
        ν = 5.0
        Y = simulate(StudentTFamily(ν, σ_true), β_true, Λ_true, n;
                     dispersion = σ_true, seed = 7081)
        fit = fit_studentt_gllvm(Y; K = K, nu = ν)
        Y2 = simulate(fit, 20; seed = 999)
        @test size(Y2) == (p, 20)
        @test all(isfinite, Y2)
    end
end
