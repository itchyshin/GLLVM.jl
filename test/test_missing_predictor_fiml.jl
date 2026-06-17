using GLLVM, Test, LinearAlgebra, Random, Statistics, ForwardDiff

# Missing-predictor FIML (the mi() axis), Gaussian Phase-2a slice: a site-level
# continuous predictor x (one value per site, may be `missing`) modelled as
# x ~ N(μ_x, σ_x²) and integrated out in CLOSED FORM via the joint Gaussian of
# (y_s, x_s). Faithful to gllvmTMB's mi() unit-level semantic: a single slope b_x
# broadcast across all traits. No Laplace, no formula parser.
@testset "fit_gaussian_mi_fiml (missing-predictor FIML, Gaussian)" begin
    # y_s = a + b_x x_s 1_p + Λ η_s + σ_eps ε_s ;  x_s ~ N(μ_x, σ_x²)
    function simulate(; p = 4, n = 300, K = 1, a, b_x, μ_x, σ_x, σ_eps, Λ, seed = 1)
        Random.seed!(seed)
        x = μ_x .+ σ_x .* randn(n)
        η = randn(K, n)
        y = a .+ b_x .* x' .+ Λ * η .+ σ_eps .* randn(p, n)
        return collect(y), collect(x)
    end

    @testset "complete-data equivalence with fit_gaussian_gllvm" begin
        p, n, K = 4, 300, 1
        a = [0.5, -0.3, 0.2, 0.1]
        b_x = 0.8
        Λ = reshape([0.7, 0.5, -0.4, 0.3], p, K)
        y, x = simulate(; p, n, K, a, b_x, μ_x = 1.0, σ_x = 0.7, σ_eps = 0.3, Λ, seed = 7)

        # ordinary fit: per-trait intercepts (p cols) + broadcast x covariate (1 col)
        Xfull = zeros(p, n, p + 1)
        for t in 1:p
            Xfull[t, :, t] .= 1.0
        end
        Xfull[:, :, p + 1] .= reshape(x, 1, n)
        fit_g = fit_gaussian_gllvm(y; K = K, X = Xfull)
        b_x_g = fit_g.pars.β[end]
        a_g = fit_g.pars.β[1:p]

        res = fit_gaussian_mi_fiml(y, x; K = K)
        @test res.converged
        # slope + intercepts are rotation-invariant mean params: must match the
        # ordinary fit when x is fully observed (the x-model factors out).
        @test res.b_x ≈ b_x_g atol = 1e-2
        @test res.a ≈ a_g atol = 1e-2
    end

    @testset "recovers b_x on complete data (smoke)" begin
        p, n, K = 4, 400, 1
        b_x = 1.0
        Λ = reshape([0.6, 0.5, -0.4, 0.3], p, K)
        y, x = simulate(; p, n, K, a = zeros(p), b_x, μ_x = 0.5, σ_x = 0.8, σ_eps = 0.3, Λ, seed = 3)
        res = fit_gaussian_mi_fiml(y, x; K = K)
        @test abs(res.b_x - b_x) < 0.15
    end

    @testset "fits with missing x cells and returns EBLUPs" begin
        p, n, K = 4, 300, 1
        b_x = 0.9
        Λ = reshape([0.6, 0.5, -0.4, 0.3], p, K)
        y, x = simulate(; p, n, K, a = zeros(p), b_x, μ_x = 0.5, σ_x = 0.8, σ_eps = 0.3, Λ, seed = 5)
        xm = Vector{Union{Missing,Float64}}(x)
        miss = [3, 17, 50, 120, 200, 250]
        xtrue = x[miss]
        xm[miss] .= missing
        res = fit_gaussian_mi_fiml(y, xm; K = K)
        @test res.converged
        @test length(res.eblup_x) == n
        @test all(!ismissing, res.eblup_x)
        # EBLUPs at missing sites track the held-out truth
        @test cor(res.eblup_x[miss], xtrue) > 0.5
    end

    @testset "packed NLL is AD-clean (ForwardDiff vs central FD ≤ 1e-6)" begin
        p, n, K = 4, 120, 1
        Λ = reshape([0.6, 0.5, -0.4, 0.3], p, K)
        y, x = simulate(; p, n, K, a = [0.2, -0.1, 0.0, 0.3], b_x = 0.8,
                        μ_x = 0.5, σ_x = 0.7, σ_eps = 0.3, Λ, seed = 2)
        xm = Vector{Union{Missing,Float64}}(x)
        xm[[5, 20, 60, 90]] .= missing
        isobs = [!ismissing(xi) for xi in xm]
        xobs = [isobs[s] ? Float64(xm[s]) : 0.0 for s in 1:n]
        f(θ) = GLLVM._mi_fiml_nll(θ, y, xobs, isobs, p, n, K)
        θ = vcat([0.2, -0.1, 0.0, 0.3], 0.8, 0.5, log(0.7), log(0.3), vec(Λ))
        g_ad = ForwardDiff.gradient(f, θ)
        h = 1e-6
        g_fd = similar(θ)
        for i in eachindex(θ)
            θp = copy(θ)
            θm = copy(θ)
            θp[i] += h
            θm[i] -= h
            g_fd[i] = (f(θp) - f(θm)) / (2h)
        end
        @test maximum(abs, g_ad .- g_fd) < 1e-6
    end

    # Heavy MC gate: FIML recovers b_x under MAR and beats complete-case deletion.
    # Opt-in (slow): GLLVM_SLOW_TESTS=1.
    if get(ENV, "GLLVM_SLOW_TESTS", "") == "1"
        @testset "FIML recovers b_x under MAR and beats complete-case" begin
            p, n, K = 4, 500, 1
            b_x_true = 1.0
            Λ = reshape([0.6, 0.5, -0.4, 0.3], p, K)
            bf = Float64[]
            bc = Float64[]
            for r in 1:50
                y, x = simulate(; p, n, K, a = zeros(p), b_x = b_x_true,
                                μ_x = 0.5, σ_x = 0.8, σ_eps = 0.7, Λ, seed = 100 + r)
                Random.seed!(900 + r)
                y1 = y[1, :]                                   # MAR: missingness on a trait, not x
                pmiss = 1 ./ (1 .+ exp.(-(-0.4 .+ 3.0 .* (y1 .- mean(y1)) ./ std(y1))))
                miss = rand(n) .< pmiss
                xm = Vector{Union{Missing,Float64}}(x)
                xm[miss] .= missing
                push!(bf, fit_gaussian_mi_fiml(y, xm; K = K).b_x)
                obs = .!miss
                push!(bc, fit_gaussian_mi_fiml(y[:, obs], x[obs]; K = K).b_x)  # complete-case
            end
            @test abs(mean(bf) - b_x_true) < 0.04                          # FIML ~unbiased
            @test mean(abs.(bc .- b_x_true)) > 1.8 * mean(abs.(bf .- b_x_true))  # cc more biased
        end
    end
end
