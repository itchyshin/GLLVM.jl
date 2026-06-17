using GLLVM, Test, LinearAlgebra, Random, Statistics, ForwardDiff

# Block-NA cross-lineage coevolution: host species measure only host traits,
# partner species only partner traits. Observed d = [vec(Y_HH); vec(Y_PP)] is
# jointly Gaussian with the 2×2 block-of-Kroneckers covariance
# [A_H⊗Σ_HH, K_HP⊗Γ; ·, A_P⊗Σ_PP]; Γ = (ΛΛᵀ)[host,partner] is recovered from the
# cross block. The faithful realistic-data companion to fit_coevolution_gaussian.
@testset "fit_coevolution_blockna (block-NA coevolution)" begin
    decay(p, c) = [exp(-c * abs(i - j)) for i in 1:p, j in 1:p]

    @testset "covariance M equals the selection from the full Kronecker" begin
        Random.seed!(1)
        T_H, T_P, d = 2, 2, 2
        T = T_H + T_P
        n_H, n_P = 3, 2
        n = n_H + n_P
        K = decay(n, 0.4) + 1e-8I
        Λ = randn(T, d) .* 0.5
        σ2 = 0.3
        Σ_T = Λ * Λ' + σ2 * I
        A_H = K[1:n_H, 1:n_H]
        A_P = K[(n_H + 1):n, (n_H + 1):n]
        K_HP = K[1:n_H, (n_H + 1):n]
        M = GLLVM._blockna_cov(Σ_T, A_H, A_P, K_HP, T_H, T_P)
        full = kron(Matrix(K), Σ_T)
        obs = Int[]
        for i in 1:n_H, t in 1:T_H
            push!(obs, (i - 1) * T + t)
        end
        for i in (n_H + 1):n, t in (T_H + 1):T
            push!(obs, (i - 1) * T + t)
        end
        @test maximum(abs, M .- full[obs, obs]) < 1e-10
    end

    # NOTE — block-NA Γ identifiability is LIMITED. Γ is seen only through the single
    # cross-block K_HP⊗Γ (one shared association W = one replicate of the coevolution
    # signal; Boettiger et al. 2012). So recovery is weaker than the complete-data
    # fit_coevolution_gaussian (>0.9) and IMPROVES with association strength: the
    # probed median |cor(Γ̂,Γ_true)| rose from ≈0.50 (ρ=0.5, n=20) to ≈0.96 (ρ=0.9,
    # n=60). These tests assert the robust facts, not a tight single-dataset recovery.
    @testset "cross-block carries the coevolution signal (K_HP is necessary)" begin
        Random.seed!(5)
        T_H, T_P, d = 2, 2, 2
        T = T_H + T_P
        n_H, n_P = 24, 24
        n = n_H + n_P
        A_Hf = decay(n_H, 0.4)
        A_Pf = decay(n_P, 0.4)
        W = [exp(-abs(i - j) / 3) for i in 1:n_H, j in 1:n_P]
        K = Matrix(make_cross_kernel(A_Hf, A_Pf, W; rho = 0.7))
        A_H = K[1:n_H, 1:n_H]
        A_P = K[(n_H + 1):n, (n_H + 1):n]
        K_HP = K[1:n_H, (n_H + 1):n]
        Λ = vcat([1.0 0.0; 0.5 0.8], [0.7 0.3; -0.3 0.9])
        σ = 0.3
        Σ_T = Λ * Λ' + σ^2 * I
        Ys = cholesky(Symmetric(Σ_T)).L * randn(T, n) * cholesky(Symmetric(K)).U
        Y_HH = Ys[1:T_H, 1:n_H]
        Y_PP = Ys[(T_H + 1):T, (n_H + 1):n]
        res = fit_coevolution_blockna(Y_HH, Y_PP, A_H, A_P, K_HP; d = d)
        res0 = fit_coevolution_blockna(Y_HH, Y_PP, A_H, A_P, zeros(n_H, n_P); d = d)  # no cross block
        @test res.converged
        @test res.logLik > res0.logLik       # the cross kernel explains the host–partner cross-data
    end

    # Heavy: Γ recovery scales with association richness (the single-W limit).
    if get(ENV, "GLLVM_SLOW_TESTS", "") == "1"
        @testset "Γ recovery improves with association strength" begin
            Λ = vcat([1.0 0.0; 0.5 0.8], [0.7 0.3; -0.3 0.9])
            Γ_true = Λ[1:2, :] * Λ[3:4, :]'
            σ = 0.3
            function medcor(rho, nn, seeds)
                cs = Float64[]
                for s in seeds
                    Random.seed!(s)
                    n = 2nn
                    A_Hf = decay(nn, 0.4); A_Pf = decay(nn, 0.4)
                    W = [exp(-abs(i - j) / 3) for i in 1:nn, j in 1:nn]
                    K = Matrix(make_cross_kernel(A_Hf, A_Pf, W; rho = rho))
                    Σ = Λ * Λ' + σ^2 * I
                    Ys = cholesky(Symmetric(Σ)).L * randn(4, n) * cholesky(Symmetric(K)).U
                    r = fit_coevolution_blockna(Ys[1:2, 1:nn], Ys[3:4, (nn + 1):n],
                                                K[1:nn, 1:nn], K[(nn + 1):n, (nn + 1):n],
                                                K[1:nn, (nn + 1):n]; d = 2)
                    r.converged && push!(cs, abs(cor(vec((r.Λ * r.Λ')[1:2, 3:4]), vec(Γ_true))))
                end
                median(cs)
            end
            @test medcor(0.9, 40, 1:7) > 0.5
            @test medcor(0.9, 40, 1:7) > medcor(0.4, 40, 1:7)
        end
    end

    @testset "packed NLL is AD-clean (ForwardDiff vs central FD ≤ 1e-6)" begin
        Random.seed!(2)
        T_H, T_P, d = 2, 2, 2
        T = T_H + T_P
        n_H, n_P = 6, 6
        n = n_H + n_P
        K = decay(n, 0.4) + 1e-8I
        Λ = randn(T, d) .* 0.4
        σ = 0.4
        Σ_T = Λ * Λ' + σ^2 * I
        A_H = K[1:n_H, 1:n_H]
        A_P = K[(n_H + 1):n, (n_H + 1):n]
        K_HP = K[1:n_H, (n_H + 1):n]
        Ystar = cholesky(Symmetric(Σ_T)).L * randn(T, n) * cholesky(Symmetric(K)).U
        Y_HH = Ystar[1:T_H, 1:n_H]
        Y_PP = Ystar[(T_H + 1):T, (n_H + 1):n]
        d_obs = vcat(vec(Y_HH), vec(Y_PP))
        f(θ) = GLLVM._coevolution_blockna_nll(θ, d_obs, A_H, A_P, K_HP, T, T_H, T_P, d)
        θ = vcat(vec(Λ), log(σ))
        g_ad = ForwardDiff.gradient(f, θ)
        h = 1e-6
        g_fd = similar(θ)
        for i in eachindex(θ)
            θp = copy(θ); θm = copy(θ)
            θp[i] += h; θm[i] -= h
            g_fd[i] = (f(θp) - f(θm)) / (2h)
        end
        @test maximum(abs, g_ad .- g_fd) < 1e-6
    end
end
