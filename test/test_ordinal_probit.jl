using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Cumulative-PROBIT ordinal family (gllvmTMB's ordinal is probit; GLLVM.jl's
# OrdinalFit already had cumulative-logit, generalised here via the link kwarg).
# P(y ≤ c | z) = Φ(τ_c − η), η = (Λ z)_t, no intercept, cutpoints τ in the
# "dispersion" slot, σ²_d = 1 (standard-normal threshold latent residual).

# Central finite-difference gradient (matches test/test_truncpoisson.jl and
# test/test_nb1_lognormal.jl). NOTE: the `2 * step` denominator is an Int literal,
# not the Float32 `2f0` stencil — the FD step stays in θ's precision (Float64) to
# hit the ≤ 1e-6 target.
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

# Standard-normal cumulative-probit category probability reference.
_probit_logp(c, η, τ, C) = log(
    (c == C ? 1.0 : cdf(Normal(), τ[c] - η)) -
    (c == 1 ? 0.0 : cdf(Normal(), τ[c - 1] - η)))

@testset "Ordinal probit" begin

    # ---------------------------------------------------------------------
    # Family pieces: probit category probabilities normalise; the link CDF/
    # density are the standard normal; the logit path is byte-for-byte unchanged.
    # ---------------------------------------------------------------------
    @testset "probit _ord_prob / _ord_F / _ord_f match the standard normal" begin
        τ = [-0.8, 0.3, 1.1]
        C = length(τ) + 1
        for η in (-1.5, 0.0, 0.7, 2.0)
            @test sum(GLLVM._ord_prob(c, η, τ, ProbitLink()) for c in 1:C) ≈ 1.0 atol = 1e-12
            for c in 1:C
                @test GLLVM._ord_prob(c, η, τ, ProbitLink()) ≈ exp(_probit_logp(c, η, τ, C))
            end
        end
        # Link CDF/density are Φ and φ.
        for x in (-2.0, -0.4, 0.0, 1.3)
            @test GLLVM._ord_F(ProbitLink(), x) ≈ cdf(Normal(), x)
            @test GLLVM._ord_f(ProbitLink(), x) ≈ pdf(Normal(), x)
        end
        # Existing logit path is unchanged: no-link == LogitLink == logistic.
        for x in (-2.0, 0.0, 1.3)
            @test GLLVM._ord_F(x) == GLLVM._ord_F(LogitLink(), x)
            @test GLLVM._ord_f(x) == GLLVM._ord_f(LogitLink(), x)
        end
    end

    # ---------------------------------------------------------------------
    # Λ = 0 (η ≡ 0) reduces to the EXACT independent cumulative-probit loglik.
    # ---------------------------------------------------------------------
    @testset "Λ = 0 reduces to independent cumulative-probit loglik (exact)" begin
        Random.seed!(7120)
        p, K, n = 5, 2, 60
        C = 4
        τ = [-1.0, 0.0, 1.2]
        probs = [GLLVM._ord_prob(c, 0.0, τ, ProbitLink()) for c in 1:C]
        Y = [rand(Categorical(probs)) for t in 1:p, s in 1:n]
        ll = GLLVM.ordinal_marginal_loglik_laplace(Y, zeros(p, K), τ, ProbitLink())
        ll_indep = sum(_probit_logp(Y[t, s], 0.0, τ, C) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-8
        # The probit marginal differs from the logit marginal on the same data
        # (the two links are NOT the same model).
        ll_logit = GLLVM.ordinal_marginal_loglik_laplace(Y, zeros(p, K), τ)
        @test !(ll ≈ ll_logit)
    end

    # ---------------------------------------------------------------------
    # K = 1 single site Laplace ≈ numerical quadrature (loose, as for logit).
    # ---------------------------------------------------------------------
    @testset "K = 1 single site ≈ numerical quadrature" begin
        Random.seed!(7121)
        p, C = 6, 4
        τ = [-1.0, 0.2, 1.5]
        Λ = reshape(0.5 .* randn(p), p, 1)
        ztrue = randn()
        Y = Vector{Int}(undef, p)
        for t in 1:p
            pr = [GLLVM._ord_prob(c, Λ[t, 1] * ztrue, τ, ProbitLink()) for c in 1:C]
            Y[t] = rand(Categorical(pr))
        end
        Ym = reshape(Y, p, 1)
        ll_lap = GLLVM.ordinal_marginal_loglik_laplace(Ym, Λ, τ, ProbitLink())
        zs = range(-8, 8; length = 4001); dz = step(zs)
        marg = 0.0
        for z in zs
            lp = sum(log(GLLVM._ord_prob(Y[t], Λ[t, 1] * z, τ, ProbitLink())) for t in 1:p)
            marg += exp(lp) * pdf(Normal(), z) * dz
        end
        @test ll_lap ≈ log(marg) atol = 0.5
    end

    # ---------------------------------------------------------------------
    # FD gradient of the probit marginal (ForwardDiff vs central differences).
    # Packed θ = [vec(Λ); ψ]; ψ the unconstrained cutpoint increments.
    # ---------------------------------------------------------------------
    @testset "marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(7803)
        p, n, K = 4, 8, 1
        C = 4
        τtrue = [-1.0, 0.1, 1.1]
        rr = GLLVM.rr_theta_len(p, K)
        Λpack = GLLVM.pack_lambda(0.2 .* randn(p, K))
        Λgen = GLLVM.unpack_lambda(Λpack, p, K)
        η = Λgen * randn(K, n)
        Y = Matrix{Int}(undef, p, n)
        for i in 1:n, t in 1:p
            pr = [GLLVM._ord_prob(c, η[t, i], τtrue, ProbitLink()) for c in 1:C]
            Y[t, i] = rand(Categorical(pr))
        end
        ψ0 = similar(τtrue)
        ψ0[1] = τtrue[1]
        for c in 2:length(τtrue)
            ψ0[c] = log(τtrue[c] - τtrue[c - 1])
        end
        θ0 = vcat(Λpack, ψ0)
        f = θ -> -GLLVM.ordinal_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[1:rr], p, K),
            GLLVM._unpack_cutpoints(θ[(rr + 1):end]), ProbitLink())
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gad, gfd)
        @info "ordinal-probit marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # The implicit value+gradient the fitter actually optimises vs FD ≤ 1e-6.
    # ---------------------------------------------------------------------
    @testset "implicit fit gradient matches FD ≤ 1e-6" begin
        Random.seed!(7804)
        p, n, K = 4, 10, 1
        C = 4
        τtrue = [-1.0, 0.1, 1.1]
        rr = GLLVM.rr_theta_len(p, K)
        Λpack = GLLVM.pack_lambda(0.15 .* randn(p, K))
        Λgen = GLLVM.unpack_lambda(Λpack, p, K)
        η = Λgen * randn(K, n)
        Y = Matrix{Int}(undef, p, n)
        for i in 1:n, t in 1:p
            pr = [GLLVM._ord_prob(c, η[t, i], τtrue, ProbitLink()) for c in 1:C]
            Y[t, i] = rand(Categorical(pr))
        end
        ψ0 = similar(τtrue)
        ψ0[1] = τtrue[1]
        for c in 2:length(τtrue)
            ψ0[c] = log(τtrue[c] - τtrue[c - 1])
        end
        θ0 = vcat(Λpack, ψ0)
        vg = θ -> GLLVM.ordinal_marginal_loglik_laplace_implicit_value_grad(
            Y, θ, p, K, ProbitLink())
        _, gimp = vg(θ0)
        f = θ -> vg(θ)[1]
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gimp, gfd)
        @info "ordinal-probit implicit fit-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # simulate → fit → recover (cutpoints τ, ΛΛ' loading structure, σ²_d = 1).
    # Fixed seeds; recovery is asserted in a generous MC band. The convergence
    # flag is INFORMATIONAL (logged, not asserted).
    # ---------------------------------------------------------------------
    @testset "simulate → fit → recover (τ, ΛΛ', σ²_d=1)" begin
        Random.seed!(7220)
        p, K, n = 8, 2, 600
        τtrue = [-1.2, 0.0, 1.3]
        C = length(τtrue) + 1
        Λtrue = 0.7 .* randn(p, K)
        Y = simulate(Ordinal(), τtrue, Λtrue, n; link = ProbitLink(), seed = 74242)
        Yint = round.(Int, Y)
        @test sort(unique(vec(Yint))) == collect(1:C)      # all C categories appear
        fit = fit_ordinal_gllvm(Yint; K = K, link = ProbitLink())
        @info "ordinal-probit fit" converged=fit.converged loglik=fit.loglik link=fit.link
        @test fit isa OrdinalFit
        @test fit.C == C
        @test fit.link isa ProbitLink
        @test issorted(fit.τ)                              # ordering preserved
        @test cor(fit.τ, τtrue) > 0.95                     # cutpoints recovered
        @test maximum(abs.(fit.τ .- τtrue)) < 0.3          # on the probit scale
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λtrue * Λtrue')) > 0.8  # loadings up to rotation
        # σ²_d = 1 for the probit threshold latent (gllvmTMB ordinal-probit fid).
        σ2d = link_residual(fit, Yint)
        @test length(σ2d) == p
        @test all(σ2d .== 1.0)
        # The single-arg table entry is exactly 1 for Ordinal + ProbitLink.
        @test link_residual(Ordinal(), ProbitLink(), 0.0, nothing) == 1.0
        # And still π²/3 for the logit link (the existing path).
        @test link_residual(Ordinal(), LogitLink(), 0.0, nothing) == π^2 / 3
    end

    # ---------------------------------------------------------------------
    # Link actually changes the fit: a logit fit on probit-generated data
    # inflates the cutpoints by the ~1.6–1.8× logistic/normal scale ratio, so
    # the probit fit is the one that recovers τtrue.
    # ---------------------------------------------------------------------
    @testset "probit fit beats a mis-specified logit fit on probit data" begin
        Random.seed!(7305)
        p, K, n = 6, 2, 600
        τtrue = [-1.0, 0.5, 1.4]
        Λtrue = 0.6 .* randn(p, K)
        Y = round.(Int, simulate(Ordinal(), τtrue, Λtrue, n; link = ProbitLink(), seed = 73051))
        fit_probit = fit_ordinal_gllvm(Y; K = K, link = ProbitLink())
        fit_logit  = fit_ordinal_gllvm(Y; K = K)            # default LogitLink (mis-specified)
        err_probit = maximum(abs.(fit_probit.τ .- τtrue))
        err_logit  = maximum(abs.(fit_logit.τ  .- τtrue))
        @info "probit vs logit cutpoint error on probit data" err_probit err_logit
        @test err_probit < err_logit                        # correct link wins
        @test err_probit < 0.3
    end
end
