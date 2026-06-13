using GLLVM, Test, LinearAlgebra, Random, Statistics, ForwardDiff

# Faithful cross-lineage coevolution recovery via the Kronecker (matrix-normal)
# fitter: Y (T × n) ~ MN(0, Λ Λᵀ + σ² I, K*), trait loadings Λ (T×d), species
# kernel K* = make_cross_kernel(...). The coevolution estimand is the
# host-trait × partner-trait block Γ = (Λ Λᵀ)[1:T_H, (T_H+1):T]. Unlike the
# Hadamard fit-contrast, this trait⊗species form RECOVERS Γ (Λ is identified from
# cross-species covariation, as in the gllvmTMB twin). Marginal via the Kronecker
# eigentrick (validated to machine precision). Complete-data slice; block-NA +
# replication deferred (see docs/dev-log/2026-06-13-coevolution-kronecker-design.md).
@testset "fit_coevolution_gaussian (Kronecker matrix-normal coevolution)" begin
    decay(p, c) = [exp(-c * abs(i - j)) for i in 1:p, j in 1:p]

    function make_K(; n_H = 20, n_P = 20, ρ = 0.5)
        A_H = decay(n_H, 0.4)
        A_P = decay(n_P, 0.4)
        W = [exp(-abs(i - j) / 3) for i in 1:n_H, j in 1:n_P]
        Matrix(make_cross_kernel(A_H, A_P, W; rho = ρ))
    end

    @testset "marginal closed form == brute-force MN density" begin
        Random.seed!(1)
        T, n, d = 5, 7, 2
        K = decay(n, 0.4) + 1e-8I
        Λ = randn(T, d) .* 0.6
        σ = 0.55
        Σ_T = Λ * Λ' + σ^2 * I
        Y = cholesky(Symmetric(Σ_T)).L * randn(T, n) * cholesky(Symmetric(K)).U
        # brute force: vec(Y) ~ N(0, K ⊗ Σ_T)
        Σf = Symmetric(kron(Matrix(K), Σ_T))
        cf = cholesky(Σf)
        v = vec(Y)
        brute = -0.5 * (T * n * log(2π) + logdet(cf) + dot(v, cf \ v))
        V, dv = GLLVM._coevolution_kron_precompute(K)
        θ = vcat(vec(Λ), log(σ))
        nll = GLLVM._coevolution_kron_nll(θ, Y, V, dv, T, n, d)
        @test -nll ≈ brute atol = 1e-7
    end

    @testset "recovers a planted Γ (the win the Hadamard form lacked)" begin
        Random.seed!(4)
        T_H, T_P, d = 2, 2, 2
        T = T_H + T_P
        K = make_K(n_H = 24, n_P = 24)
        n = size(K, 1)
        Λ_H = [1.0 0.0; 0.5 0.8]
        Λ_P = [0.7 0.3; -0.3 0.9]
        Λ = vcat(Λ_H, Λ_P)
        Γ_true = Λ_H * Λ_P'
        σ = 0.3
        Σ_T = Λ * Λ' + σ^2 * I
        Y = cholesky(Symmetric(Σ_T)).L * randn(T, n) * cholesky(Symmetric(K)).U

        res = fit_coevolution_gaussian(Y, K; d = d)
        @test res.converged
        Λ̂ = res.Λ
        Γ̂ = (Λ̂ * Λ̂')[1:T_H, (T_H + 1):T]
        @test abs(cor(vec(Γ̂), vec(Γ_true))) > 0.9          # FAITHFUL recovery

        # null kernel (ρ = 0, block-diagonal) fits strictly worse on K*-structured data
        K_null = make_K(n_H = 24, n_P = 24, ρ = 0.0)
        res0 = fit_coevolution_gaussian(Y, K_null; d = d)
        @test res.logLik > res0.logLik
    end

    @testset "packed NLL is AD-clean (ForwardDiff vs central FD ≤ 1e-6)" begin
        Random.seed!(2)
        T, n, d = 4, 12, 2
        K = make_K(n_H = 6, n_P = 6)
        Λ = randn(T, d) .* 0.5
        σ = 0.4
        Σ_T = Λ * Λ' + σ^2 * I
        Y = cholesky(Symmetric(Σ_T)).L * randn(T, n) * cholesky(Symmetric(K)).U
        V, dv = GLLVM._coevolution_kron_precompute(K)
        f(θ) = GLLVM._coevolution_kron_nll(θ, Y, V, dv, T, n, d)
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
