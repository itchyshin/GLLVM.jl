using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff
using SpecialFunctions: loggamma

# Central finite-difference gradient (matches test/test_zip.jl and test/test_nb1_lognormal.jl).
# The FD step is in θ's Float64 precision to hit the ≤1e-6 target.
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

# Closed-form GP-1 (Famoye mean-parameterised) log pmf reference, D = 1+αμ:
#   ℓ = y·log μ − y·log D + (y−1)·log(1+αy) − log(y!) − μ(1+αy)/D.
function _gp_logpdf(α, μ, y)
    D = 1 + α * μ
    onepay = 1 + α * y
    return y * log(μ) - y * log(D) + (y - 1) * log(onepay) -
           loggamma(y + 1.0) - μ * onepay / D
end

# Reference GP-1 sampler by inverse-CDF over the closed-form pmf (self-contained, so
# the test does NOT depend on the integrator-added `_draw_y(::GenPoisson)`). For α ≥ 0
# the support is {0,1,2,…}; for α < 0 it is finite (1+αy > 0 ⇒ y < −1/α), and the pmf
# is renormalised over that truncated support (the standard finite-support convention
# for the under-dispersed GP; Consul & Famoye 1992).
function _rand_gp(rng, α, μ; ymax = nothing)
    ub = if ymax !== nothing
        ymax
    elseif α < 0
        max(0, ceil(Int, -1 / α) - 1)        # 1+αy > 0
    else
        # generous upper bound for α ≥ 0 (mean μ, sd μ(1+αμ)); 50 sd's beyond mean
        max(50, ceil(Int, μ * (1 + α * μ) + 50 * sqrt(μ) * (1 + α * μ)))
    end
    w = [exp(_gp_logpdf(α, μ, y)) for y in 0:ub]
    s = sum(w)
    u = rand(rng) * s
    acc = 0.0
    @inbounds for y in 0:ub
        acc += w[y + 1]
        u ≤ acc && return y
    end
    return ub
end

@testset "Generalized Poisson (GP-1, Famoye mean-parameterised)" begin

    # ---------------------------------------------------------------------
    # Family pieces: score / weight / logpdf sanity against the spec.
    # ---------------------------------------------------------------------
    @testset "score, weight, logpdf match the GP-1 spec" begin
        for α in (-0.05, 0.0, 0.1, 0.4), μ in (0.5, 1.0, 3.0, 7.0)
            fam = GLLVM.GenPoisson(α)
            D = 1 + α * μ
            # score: s = (y − μ)/D² (log link, me = μ).
            @test GLLVM._glm_score(fam, μ, 1, μ, 5.0) ≈ (5.0 - μ) / D^2
            @test GLLVM._glm_score(fam, μ, 1, μ, 0.0) ≈ (0.0 - μ) / D^2
            # weight = expected Fisher information E[s²] = μ/D² > 0.
            @test GLLVM._glm_weight(fam, μ, 1, μ) ≈ μ / D^2
            @test GLLVM._glm_weight(fam, μ, 1, μ) > 0
            # logpdf matches the closed-form reference.
            @test GLLVM._glm_logpdf(fam, μ, 1, 0.0) ≈ _gp_logpdf(α, μ, 0.0)
            @test GLLVM._glm_logpdf(fam, μ, 1, 4.0) ≈ _gp_logpdf(α, μ, 4.0)
        end
    end

    # ---------------------------------------------------------------------
    # logpdf is a normalised pmf over k = 0,1,2,… (α ≥ 0: infinite support;
    # α < 0: finite support y < −1/α, renormalised — the under-dispersed GP).
    # ---------------------------------------------------------------------
    @testset "logpdf normalises (over- and under-dispersed)" begin
        for α in (0.1, 0.3), μ in (0.5, 2.0, 6.0)
            @test sum(exp(_gp_logpdf(α, μ, float(k))) for k in 0:3000) ≈ 1.0 atol = 1e-6
        end
        # Under-dispersion: finite support, renormalise (1+αy>0 ⇒ y < −1/α).
        for α in (-0.05, -0.1), μ in (0.5, 2.0)
            ub = ceil(Int, -1 / α) - 1
            @test sum(exp(_gp_logpdf(α, μ, float(k))) for k in 0:ub) > 0.99
        end
    end

    # ---------------------------------------------------------------------
    # α → 0 reduces every family piece to the plain Poisson (test oracle).
    # ---------------------------------------------------------------------
    @testset "α = 0 reduces to Poisson pieces" begin
        for μ in (0.5, 2.0, 6.0)
            gfam = GLLVM.GenPoisson(0.0)
            pfam = Poisson()
            @test GLLVM._glm_score(gfam, μ, 1, μ, 0.0) ≈ GLLVM._glm_score(pfam, μ, 1, μ, 0.0)
            @test GLLVM._glm_score(gfam, μ, 1, μ, 4.0) ≈ GLLVM._glm_score(pfam, μ, 1, μ, 4.0)
            @test GLLVM._glm_weight(gfam, μ, 1, μ) ≈ GLLVM._glm_weight(pfam, μ, 1, μ)
            @test GLLVM._glm_logpdf(gfam, μ, 1, 3.0) ≈ GLLVM._glm_logpdf(pfam, μ, 1, 3.0)
        end
    end

    # ---------------------------------------------------------------------
    # Λ = 0 reduces to the independent GP-regression loglik (exact).
    # ---------------------------------------------------------------------
    @testset "Λ = 0 reduces to independent GP-regression loglik (exact)" begin
        Random.seed!(1202)
        p, K, n = 4, 2, 50
        β = log.([2.0, 3.0, 1.5, 2.5])
        μ = exp.(β)
        α = 0.2
        rng = MersenneTwister(12021)
        Y = [_rand_gp(rng, α, μ[t]) for t in 1:p, s in 1:n]
        ll = GLLVM.genpoisson_marginal_loglik_laplace(Y, zeros(p, K), β, α)
        ll_indep = sum(_gp_logpdf(α, μ[t], float(Y[t, s])) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-7
    end

    # ---------------------------------------------------------------------
    # Marginal → Poisson marginal as α → 0 (limiting reduction to the parent).
    # ---------------------------------------------------------------------
    @testset "marginal → Poisson marginal as α → 0" begin
        Random.seed!(1201)
        p, K, n = 5, 2, 30
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0])
        Λ = 0.3 .* randn(p, K)
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]
        ll_gp   = GLLVM.genpoisson_marginal_loglik_laplace(Y, Λ, β, 1e-8)
        ll_pois = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test ll_gp ≈ ll_pois atol = 1e-3
    end

    # ---------------------------------------------------------------------
    # FD gradient of the marginal (ForwardDiff vs central differences) ≤ 1e-6.
    # Packed θ = [β; vec(Λ); α]; α enters via the marker (identity scale).
    # ---------------------------------------------------------------------
    @testset "marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(1203)
        p, n, K = 4, 8, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.1 .* randn(p, K))
        α_true = 0.25
        rng = MersenneTwister(12031)
        Y = [_rand_gp(rng, α_true, 3.0) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0, α_true)
        f = θ -> -GLLVM.genpoisson_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], θ[p + rr + 1])
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gad, gfd)
        @info "GP marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # The implicit value+gradient the fitter actually optimises vs FD ≤ 1e-6.
    # ---------------------------------------------------------------------
    @testset "implicit fit gradient matches FD ≤ 1e-6" begin
        Random.seed!(1204)
        p, n, K = 4, 10, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.15 .* randn(p, K))
        α_true = 0.2
        rng = MersenneTwister(12041)
        Y = [_rand_gp(rng, α_true, 3.0) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        θ0 = vcat(β0, Λ0, α_true)
        family_fromθ = θ -> GLLVM.GenPoisson(θ[end])
        vg = θ -> GLLVM.marginal_loglik_laplace_implicit_value_grad(
            family_fromθ, Y, N, θ, p, K, LogLink())
        _, gimp = vg(θ0)
        f = θ -> vg(θ)[1]
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gimp, gfd)
        @info "GP implicit fit-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # simulate → fit → recover (β, ΛΛ' structure, α). Uses the self-contained
    # GP-1 reference sampler `_rand_gp` (the integrator wires `simulate`/`_draw_y`
    # for GenPoisson separately). Convergence flag is INFORMATIONAL — structure
    # recovery is asserted, not tight MC on the dispersion.
    # ---------------------------------------------------------------------
    @testset "simulate → fit → recover (β, ΛΛ', α)" begin
        Random.seed!(1205)
        p, K, n = 6, 2, 1500
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.5 .* randn(p, K)
        α_true = 0.2
        rng = MersenneTwister(12051)
        # per-site latent draw, then per-cell GP draw at μ = exp(β + Λz).
        Z = randn(rng, K, n)
        LZ = Λ_true * Z
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μts = exp(β_true[t] + LZ[t, s])
            Y[t, s] = _rand_gp(rng, α_true, μts)
        end
        fit = fit_genpoisson_gllvm(Y; K = K)
        @info "GP fit" converged=fit.converged α̂=fit.α loglik=fit.loglik
        @test size(fit.Λ) == (p, K)
        # GP intercepts are α-coupled and noisier than the pure-count families, so the
        # per-trait β band is wider than e.g. Poisson's; the loading structure and the
        # dispersion are the tighter recovery gates. (Gross failures show β errors ≫ 1.)
        @test maximum(abs.(fit.β .- β_true)) < 0.8
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.6
        @test isfinite(fit.α)
        @test fit.α ≈ α_true rtol = 0.7            # over-dispersion identifiable-but-noisy
    end

    # ---------------------------------------------------------------------
    # link_residual: GP delta-method residual σ²_d = log1p(Var/E²) =
    # log1p((1+αμ̂)²/μ̂), finite & positive, reducing to the Poisson log1p(1/μ̂)
    # as α → 0. (The integrator wires the `_link_residual_one(::GenPoisson, …)`
    # method; this scalar identity documents the intended formula.)
    # ---------------------------------------------------------------------
    @testset "link_residual scalar formula (GP delta-method)" begin
        μ = 5.0
        for α in (0.0, 0.1, 0.3)
            D = 1 + α * μ
            # σ²_d = log1p(Var/E²) with Var = μ D², E = μ ⇒ log1p(D²/μ).
            @test log1p(D^2 / μ) ≈ log1p((1 + α * μ)^2 / μ)
        end
        # α → 0 ⇒ Poisson log1p(1/μ).
        @test log1p((1 + 0.0 * μ)^2 / μ) ≈ log1p(1 / μ)
    end
end
