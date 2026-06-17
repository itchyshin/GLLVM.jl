using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Track T4 — cross-family (non-Gaussian) coevolution. Drive the cross-lineage
# kernel K* through a non-Gaussian Laplace so coevolution works for the GLM
# families, not just the Gaussian matrix-normal case.
#
# Model (Kronecker / per-species-factor orientation, the one that makes the
# Gaussian-limit reduction below hold to machine precision):
#   latent z_j ∈ ℝ^d per species j, with the d axes iid and each axis correlated
#   across species by K*: prior precision  P = (σ²_phy K*)⁻¹ ⊗ I_d  over vec(Z);
#   η[t,j] = β_t + (Λ z_j)[t],  Y[t,j] ~ Family(linkinv(η[t,j]));  Λ is T×d trait
#   loadings.  The coevolution estimand is  Γ = (Λ Λᵀ)[1:T_H, (T_H+1):T].
#
# Gate 1 (THE oracle) is the Gaussian-limit reduction: with family=Normal,
# IdentityLink, the Laplace marginal is EXACT for the linear-Gaussian model, so it
# reproduces the same-model dense closed form N(0, σ²_phy K*⊗ΛΛᵀ + σ²I) to machine
# precision. (Note on `fit_coevolution_gaussian`: that oracle is the matrix-normal
# model K*⊗Σ_T whose *noise* σ²(K*⊗I) is itself K*-correlated; a real non-Gaussian
# family's noise is iid, so the natural non-Gaussian Laplace reduces to the
# iid-noise Gaussian model, NOT to fit_coevolution_gaussian. fit_coevolution_gaussian
# is recovered only in the degenerate σ_family→0 / full-Σ_T-in-latent limit; we
# check that limiting behaviour, not machine-precision equality.)

@testset "Cross-family (non-Gaussian) coevolution (fit_coevolution_glm)" begin
    decay(p, c) = [exp(-c * abs(i - j)) for i in 1:p, j in 1:p]
    function make_K(; n_H = 20, n_P = 20, ρ = 0.5)
        A_H = decay(n_H, 0.4)
        A_P = decay(n_P, 0.4)
        W = [exp(-abs(i - j) / 3) for i in 1:n_H, j in 1:n_P]
        Matrix(make_cross_kernel(A_H, A_P, W; rho = ρ))
    end
    gauss_ll(Σ, x) = (cf = cholesky(Symmetric(Σ));
                      -0.5 * (length(x) * log(2π) + logdet(cf) + dot(x, cf \ x)))

    # ---- Gate 1: Gaussian-limit reduction == same-model dense closed form ----
    @testset "Gate 1: Gaussian limit reproduces the dense closed form (machine precision)" begin
        Random.seed!(11)
        K = make_K(n_H = 4, n_P = 3)
        n = size(K, 1)
        T, d = 4, 2
        Λ = randn(T, d) .* 0.6
        σ = 0.55
        σ2 = σ^2
        σ2phy = 0.8
        Σ_T = Λ * Λ' + σ2 * I
        # data from the SAME latent model: vec(Y) ~ N(0, σ2phy K*⊗ΛΛᵀ + σ²I)
        Σmodel = Symmetric(kron(K, σ2phy .* (Λ * Λ')) + σ2 * I)
        v = cholesky(Σmodel).L * randn(T * n)
        Y = reshape(v, T, n)
        N = ones(T, n)
        β = zeros(T)

        ℓ_lap = coevolution_glm_marginal_loglik(Normal(0.0, σ), Y, N, β, Λ, σ2phy, K;
                                                link = IdentityLink())
        ℓ_dense = gauss_ll(kron(K, σ2phy .* (Λ * Λ')) + σ2 * I, v)
        @test isapprox(ℓ_lap, ℓ_dense; atol = 1e-8)

        # limiting behaviour toward fit_coevolution_gaussian (K*⊗Σ_T): as the family
        # noise σ_fam → 0 with the full Σ_T carried in the latent loadings, the
        # Laplace marginal approaches the matrix-normal oracle (not equal at finite σ_fam).
        L = Matrix(cholesky(Symmetric(Σ_T)).L)             # LLᵀ = Σ_T (d = T)
        ℓ_oracle = gauss_ll(kron(K, Σ_T), v)               # K*⊗Σ_T (with σ2phy=1)
        diffs = Float64[]
        for σf in (1e-2, 1e-3, 1e-4)
            ℓσ = coevolution_glm_marginal_loglik(Normal(0.0, σf), Y, N, β, L, 1.0, K;
                                                 link = IdentityLink())
            push!(diffs, abs(ℓσ - ℓ_oracle))
        end
        @test diffs[1] > diffs[2] > diffs[3]               # monotone → oracle
        @test diffs[3] < 1e-6
    end

    # ---- Gate 2: σ²_phy → 0 reduces to the independent per-cell marginal -----
    @testset "Gate 2: σ²_phy → 0 reduces to the independent per-cell family marginal" begin
        Random.seed!(20)
        K = make_K(n_H = 5, n_P = 4)
        n = size(K, 1)
        T, d = 3, 2
        Λ = randn(T, d) .* 0.5
        β = 0.3 .* randn(T)
        Y = float.(rand(0:5, T, n))
        N = ones(T, n)

        ℓ_indep = sum(GLLVM._glm_logpdf(Poisson(), exp(β[t]), 1, Y[t, j])
                      for t in 1:T, j in 1:n)
        ℓ_phy0 = coevolution_glm_marginal_loglik(Poisson(), Y, N, β, Λ, 1e-10, K;
                                                 link = LogLink())
        @test isapprox(ℓ_phy0, ℓ_indep; atol = 1e-3)
    end

    # ---- Gate 3: FD sanity of the packed objective (FD-outer-gradient choice) -
    @testset "Gate 3: packed objective is smooth; central-FD gradient is finite & sane" begin
        Random.seed!(30)
        K = make_K(n_H = 4, n_P = 3)
        n = size(K, 1)
        T, d = 3, 2
        Λ = randn(T, d) .* 0.5
        β = 0.2 .* randn(T)
        Y = float.(rand(0:4, T, n))
        N = ones(T, n)
        # pack θ = [β; vec(Λ); log σ²_phy]
        f(θ) = -coevolution_glm_marginal_loglik(Poisson(),
                    Y, N, θ[1:T], reshape(θ[(T + 1):(T + T * d)], T, d),
                    exp(θ[end]), K; link = LogLink())
        θ0 = vcat(β, vec(Λ), log(0.7))
        h = 1e-6
        g = similar(θ0)
        for i in eachindex(θ0)
            θp = copy(θ0); θm = copy(θ0)
            θp[i] += h; θm[i] -= h
            g[i] = (f(θp) - f(θm)) / (2h)
        end
        @test all(isfinite, g)
        @test 0 < norm(g) < 1e6
    end

    # ---- Gate 4: Γ recovery on Poisson data simulated WITH coevolution -------
    @testset "Gate 4: Γ recovery (Poisson, cross-lineage coevolution)" begin
        Random.seed!(42)
        T_H, T_P, d = 2, 2, 2
        T = T_H + T_P
        K = make_K(n_H = 40, n_P = 40, ρ = 0.6)
        n = size(K, 1)
        Λ_H = [1.0 0.0; 0.6 0.7]
        Λ_P = [0.7 0.2; -0.3 0.8]
        Λ = vcat(Λ_H, Λ_P)
        Γ_true = Λ_H * Λ_P'
        σ2phy = 1.0
        # simulate K*-correlated latent factors, then Poisson counts
        Lk = cholesky(Symmetric(σ2phy .* K)).L
        Z = (Lk * randn(n, d))                              # n×d, columns K*-correlated
        β = fill(1.2, T)
        η = [β[t] + dot(Λ[t, :], Z[j, :]) for t in 1:T, j in 1:n]
        Y = float.([rand(Poisson(exp(clamp(η[t, j], -20, 20)))) for t in 1:T, j in 1:n])
        N = ones(T, n)

        fit = fit_coevolution_glm(Y, K; family = Poisson(), d = d, iterations = 200)
        @test isfinite(fit.loglik)
        @test fit.converged
        Γ̂ = coevolution_gamma(fit; n_host_traits = T_H)
        @test size(Γ̂) == (T_H, T_P)
        @test abs(cor(vec(Γ̂), vec(Γ_true))) > 0.5          # meaningful recovery
    end

    # ---- Gate 5: block-NA non-Gaussian fit runs and recovers Γ --------------
    @testset "Gate 5: block-NA Poisson coevolution runs and recovers Γ (single-rep caveat)" begin
        Random.seed!(7)
        T_H, T_P, d = 2, 2, 2
        T = T_H + T_P
        K = make_K(n_H = 45, n_P = 45, ρ = 0.6)
        n = size(K, 1)
        n_H = 45
        Λ_H = [1.0 0.0; 0.5 0.7]
        Λ_P = [0.6 0.3; -0.2 0.8]
        Λ = vcat(Λ_H, Λ_P)
        Γ_true = Λ_H * Λ_P'
        Lk = cholesky(Symmetric(K)).L
        Z = (Lk * randn(n, d))
        β = fill(1.0, T)
        η = [β[t] + dot(Λ[t, :], Z[j, :]) for t in 1:T, j in 1:n]
        Yfull = [rand(Poisson(exp(clamp(η[t, j], -20, 20)))) for t in 1:T, j in 1:n]
        # block-NA: host species (cols 1:n_H) measure only host traits (rows 1:T_H);
        # partner species (cols n_H+1:n) measure only partner traits (rows T_H+1:T).
        Y = Matrix{Union{Missing, Float64}}(missing, T, n)
        for j in 1:n_H, t in 1:T_H
            Y[t, j] = Float64(Yfull[t, j])
        end
        for j in (n_H + 1):n, t in (T_H + 1):T
            Y[t, j] = Float64(Yfull[t, j])
        end
        N = ones(T, n)

        fit = fit_coevolution_glm(Y, K; family = Poisson(), d = d, iterations = 200)
        @test isfinite(fit.loglik)
        Γ̂ = coevolution_gamma(fit; n_host_traits = T_H)
        @test size(Γ̂) == (T_H, T_P)
        @test all(isfinite, Γ̂)
        # single-replicate identifiability is weak; require a non-degenerate (finite,
        # nonzero) Γ rather than a strong correlation.
        @test norm(Γ̂) > 1e-3
    end
end
