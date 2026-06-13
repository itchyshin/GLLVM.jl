using GLLVM, Test, LinearAlgebra, Random, Distributions, ForwardDiff

# Non-Gaussian missing predictor (mi() Phase 5a): a Poisson-log response with one
# missing site-level continuous predictor x_s ~ N(μ_x, σ_x²) and a broadcast slope
# b_x, integrated via an augmented per-site Laplace over (z_s, x_s). Observed
# sites reuse the existing offset path (b_x x_s folded into the offset); missing
# sites add the rank-1 bordered (K+1) Newton. See
# docs/dev-log/2026-06-13-nongaussian-mi-design.md.
@testset "non-Gaussian missing predictor (Poisson, augmented Laplace)" begin

    @testset "complete-data equivalence (offset-absorption + x prior)" begin
        Random.seed!(1)
        p, n, K = 6, 300, 1
        β = randn(p) .* 0.3
        Λ = reshape(randn(p, K) .* 0.4, p, K)
        b_x, μ_x, σ_x = 0.6, 0.5, 0.8
        x = μ_x .+ σ_x .* randn(n)
        z = randn(K, n)
        η = β .+ b_x .* x' .+ Λ * z
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)

        # augmented marginal with ALL x observed
        ll_xs = GLLVM.marginal_loglik_laplace_xs(Poisson(), Y, N, Λ, β, LogLink();
                                                 x = x, b_x = b_x, μ_x = μ_x, σ_x2 = σ_x^2)
        # oracle: plain offset marginal (b_x x_s absorbed) + Σ_s logN(x_s; μ_x, σ_x²)
        offset = (b_x .* reshape(x, 1, n)) .* ones(p)        # p×n, offset[t,s] = b_x x_s
        ll_off = GLLVM.marginal_loglik_laplace(Poisson(), Y, N, Λ, β, LogLink(); offset = offset)
        ll_x = sum(logpdf(Normal(μ_x, σ_x), xs) for xs in x)
        @test ll_xs ≈ ll_off + ll_x atol = 1e-7
    end

    @testset "missing-site marginal matches 2-D Gauss–Hermite quadrature" begin
        Random.seed!(2)
        p, K = 5, 1
        β = randn(p) .* 0.3
        Λ = reshape([0.5, 0.4, -0.3, 0.35, 0.2], p, K)
        b_x, μ_x, σ_x = 0.6, 0.4, 0.7
        y = rand(Poisson(2.0), p)
        N = ones(Int, p)
        ll_lap = GLLVM.laplace_loglik_site_xs(Poisson(), y, N, Λ, β, LogLink();
                                              x_obs = nothing, b_x = b_x, μ_x = μ_x, σ_x2 = σ_x^2)
        # 2-D Gauss–Hermite reference over (z, x): ∫∫ p(y|z,x) N(z;0,1) N(x;μ_x,σ_x²)
        nodes, wts = GLLVM._gauss_hermite(80)
        zz = sqrt(2) .* nodes
        wz = wts ./ sqrt(π)
        xx = μ_x .+ sqrt(2) * σ_x .* nodes
        wx = wts ./ sqrt(π)
        acc = 0.0
        for (zi, wzi) in zip(zz, wz), (xi, wxi) in zip(xx, wx)
            ll = sum(logpdf(Poisson(exp(β[t] + b_x * xi + Λ[t, 1] * zi)), y[t]) for t in 1:p)
            acc += wzi * wxi * exp(ll)
        end
        @test ll_lap ≈ log(acc) rtol = 3e-2          # Laplace-approximation tolerance
    end

    @testset "packed marginal is AD-clean (ForwardDiff vs central FD ≤ 1e-6)" begin
        Random.seed!(3)
        p, n, K = 5, 60, 1
        β0 = randn(p) .* 0.3
        Λ0 = reshape([0.5, 0.4, -0.3, 0.35, 0.2], p, K)
        b_x, μ_x, σ_x = 0.5, 0.4, 0.7
        x = μ_x .+ σ_x .* randn(n)
        η = β0 .+ b_x .* x' .+ Λ0 * randn(K, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        xm = Vector{Union{Missing,Float64}}(x)
        xm[[3, 11, 25, 40]] .= missing
        # θ = [β (p); vec(Λ) (p*K); b_x; μ_x; log σ_x²]
        function f(θ)
            β = θ[1:p]
            Λ = reshape(θ[(p + 1):(p + p * K)], p, K)
            bx = θ[p + p * K + 1]
            mx = θ[p + p * K + 2]
            sx2 = exp(θ[p + p * K + 3])
            GLLVM.marginal_loglik_laplace_xs(Poisson(), Y, N, Λ, β, LogLink();
                                             x = xm, b_x = bx, μ_x = mx, σ_x2 = sx2)
        end
        θ = vcat(β0, vec(Λ0), b_x, μ_x, log(σ_x^2))
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

@testset "non-Gaussian missing predictor (Binomial, augmented Laplace)" begin
    Ntri = 12

    @testset "complete-data equivalence (offset-absorption + x prior)" begin
        Random.seed!(11)
        p, n, K = 6, 300, 1
        β = randn(p) .* 0.3
        Λ = reshape(randn(p, K) .* 0.4, p, K)
        b_x, μ_x, σ_x = 0.5, 0.4, 0.7
        x = μ_x .+ σ_x .* randn(n)
        η = β .+ b_x .* x' .+ Λ * randn(K, n)
        μ = 1 ./ (1 .+ exp.(-η))
        Y = [rand(Binomial(Ntri, μ[t, s])) for t in 1:p, s in 1:n]
        N = fill(Ntri, p, n)
        ll_xs = GLLVM.marginal_loglik_laplace_xs(Binomial(), Y, N, Λ, β, LogitLink();
                                                 x = x, b_x = b_x, μ_x = μ_x, σ_x2 = σ_x^2)
        offset = (b_x .* reshape(x, 1, n)) .* ones(p)
        ll_off = GLLVM.marginal_loglik_laplace(Binomial(), Y, N, Λ, β, LogitLink(); offset = offset)
        ll_x = sum(logpdf(Normal(μ_x, σ_x), xs) for xs in x)
        @test ll_xs ≈ ll_off + ll_x atol = 1e-7
    end

    @testset "missing-site marginal matches 2-D Gauss–Hermite quadrature" begin
        Random.seed!(12)
        p, K = 5, 1
        β = randn(p) .* 0.3
        Λ = reshape([0.5, 0.4, -0.3, 0.35, 0.2], p, K)
        b_x, μ_x, σ_x = 0.5, 0.4, 0.7
        y = [rand(Binomial(Ntri, 0.5)) for _ in 1:p]
        N = fill(Ntri, p)
        ll_lap = GLLVM.laplace_loglik_site_xs(Binomial(), y, N, Λ, β, LogitLink();
                                              x_obs = nothing, b_x = b_x, μ_x = μ_x, σ_x2 = σ_x^2)
        nodes, wts = GLLVM._gauss_hermite(80)
        zz = sqrt(2) .* nodes
        wz = wts ./ sqrt(π)
        xx = μ_x .+ sqrt(2) * σ_x .* nodes
        wx = wts ./ sqrt(π)
        acc = 0.0
        for (zi, wzi) in zip(zz, wz), (xi, wxi) in zip(xx, wx)
            μq = 1 ./ (1 .+ exp.(-(β .+ b_x * xi .+ Λ[:, 1] .* zi)))
            ll = sum(logpdf(Binomial(N[t], μq[t]), y[t]) for t in 1:p)
            acc += wzi * wxi * exp(ll)
        end
        @test ll_lap ≈ log(acc) rtol = 3e-2
    end

    @testset "packed marginal is AD-clean (ForwardDiff vs central FD ≤ 1e-6)" begin
        Random.seed!(13)
        p, n, K = 5, 60, 1
        β0 = randn(p) .* 0.3
        Λ0 = reshape([0.5, 0.4, -0.3, 0.35, 0.2], p, K)
        b_x, μ_x, σ_x = 0.5, 0.4, 0.7
        x = μ_x .+ σ_x .* randn(n)
        ηd = β0 .+ b_x .* x' .+ Λ0 * randn(K, n)
        μd = 1 ./ (1 .+ exp.(-ηd))
        Y = [rand(Binomial(Ntri, μd[t, s])) for t in 1:p, s in 1:n]
        N = fill(Ntri, p, n)
        xm = Vector{Union{Missing,Float64}}(x)
        xm[[3, 11, 25, 40]] .= missing
        function f(θ)
            β = θ[1:p]
            Λ = reshape(θ[(p + 1):(p + p * K)], p, K)
            bx = θ[p + p * K + 1]
            mx = θ[p + p * K + 2]
            sx2 = exp(θ[p + p * K + 3])
            GLLVM.marginal_loglik_laplace_xs(Binomial(), Y, N, Λ, β, LogitLink();
                                             x = xm, b_x = bx, μ_x = mx, σ_x2 = sx2)
        end
        θ = vcat(β0, vec(Λ0), b_x, μ_x, log(σ_x^2))
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
