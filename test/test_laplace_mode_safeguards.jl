using GLLVM, Test, Distributions, LinearAlgebra

function _test_mode_logpost(family, y, n, Λ, β, link, z)
    η = GLLVM._clamp_eta.(β .+ Λ * z)
    μ = GLLVM._clamp_mu.(Ref(family), GLLVM.linkinv.(Ref(link), η))
    return sum(GLLVM._glm_logpdf.(Ref(family), μ, n, y)) - 0.5 * dot(z, z)
end

function _test_raw_fisher_step(family, y, n, Λ, β, link, z)
    η = GLLVM._clamp_eta.(β .+ Λ * z)
    μ = GLLVM._clamp_mu.(Ref(family), GLLVM.linkinv.(Ref(link), η))
    me = GLLVM.mu_eta.(Ref(link), η)
    s = GLLVM._glm_score.(Ref(family), μ, n, me, y)
    W = GLLVM._glm_weight.(Ref(family), μ, n, me)
    A = Symmetric(transpose(Λ) * (W .* Λ) + I)
    Δ = A \ (transpose(Λ) * s .- z)
    return z .+ Δ
end

@testset "Laplace mode safeguards" begin
    @testset "large Fisher step is backtracked when it lowers the mode objective" begin
        family = Poisson()
        link = LogLink()
        β = [0.027111812179665865, -6.343738849683577, -1.9285473083710833,
             5.844618467076597, -7.282086019725499]
        Λ = [1.6378763545845256 -0.2997412107108223;
             2.938892000759414 3.532958506497486;
             -1.8034518046326478 5.234377052821923;
             -3.0538110614677794 2.799401177648909;
             4.412785564525367 0.6161319022454046]
        y = [6, 2, 8, 7, 7]
        n = ones(Int, length(y))
        z0 = [17.508610524342412, -7.909886918110572]

        q0 = _test_mode_logpost(family, y, n, Λ, β, link, z0)
        z_full = _test_raw_fisher_step(family, y, n, Λ, β, link, z0)
        q_full = _test_mode_logpost(family, y, n, Λ, β, link, z_full)
        @test q_full < q0

        z_guarded = copy(z0)
        GLLVM._laplace_mode!(z_guarded, family, y, n, Λ, β, link; maxiter = 1)
        q_guarded = _test_mode_logpost(family, y, n, Λ, β, link, z_guarded)
        @test q_guarded >= q0
        @test q_guarded > q_full
    end

    @testset "non-finite warm start restarts to a finite mode" begin
        family = Poisson()
        link = LogLink()
        β = log.([2.0, 3.0, 4.0])
        Λ = [0.4 0.1; -0.2 0.3; 0.1 -0.5]
        y = [2, 3, 4]
        n = ones(Int, length(y))
        z = [Inf, -Inf]

        GLLVM._laplace_mode!(z, family, y, n, Λ, β, link)
        @test all(isfinite, z)
        @test isfinite(_test_mode_logpost(family, y, n, Λ, β, link, z))
    end
end
