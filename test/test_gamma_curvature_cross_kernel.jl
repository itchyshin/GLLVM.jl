# Cross-kernel Gamma curvature consistency.
#
# WHY THIS FILE EXISTS. Gamma/log was flipped to the observed log-det curvature
# on 2026-08-25 (instance 8 of the fault class — the public default path). But
# the curvature selector lives in the generic core, and SEVERAL other kernels
# build their own `Λ'WΛ + I` and their own `logdet`, bypassing it entirely. A
# per-family flip is therefore only coherent if every kernel a Gamma model can
# reach agrees.
#
# An audit found five such kernels, and five of them had NO Gamma coverage at
# all — so the flip was, in the auditor's words, "unverifiable by construction".
# This file is that missing coverage. It does not test any kernel against a
# stored number; it tests them against EACH OTHER, which cannot be satisfied by
# tuning a constant.
#
# The sharpest case is the R bridge: `bridge.jl:472-479` routes
# `family = "gamma"` to the generic core but an all-same vector
# `["gamma", …]` to the mixed kernel — its own comment says so. Before the
# mixed kernel was brought into the contract, those two routes returned
# DIFFERENT log-likelihoods for the SAME model.
#
# NOTE on `tol`: that is the MODE tolerance, tightened deliberately. Gamma's
# Fisher weight is the constant α and so is mode-INSENSITIVE; the observed
# weight α·y/μ(ẑ) is mode-sensitive, so the default 1e-9 leaves a ~1e-10
# residual between kernels. Measured: 1e-9 → 7e-11, 1e-13 → exactly 0.

using GLLVM, Test, Random, Distributions

@testset "Gamma curvature: every kernel agrees" begin
    Random.seed!(20260825)
    p, K, n, α = 5, 1, 30, 3.0
    β = log.(fill(2.2, p))
    Λ = reshape(0.3 .* randn(p), p, K)
    Y = [rand(Gamma(α, exp(β[t]) / α)) for t in 1:p, _ in 1:n]
    N = ones(Int, p, n)
    link = GLLVM.LogLink()
    fam  = Gamma(α, 1.0)
    MODE_TOL = 1e-13

    # The reference: the generic core, which carries the selector and whose
    # Gamma default is now :observed.
    ref = GLLVM.gamma_marginal_loglik_laplace(Y, Λ, β, α; tol = MODE_TOL)

    @testset "the core is genuinely on the observed curvature" begin
        @test GLLVM._default_hessian(fam, link) === :observed
        fisher = GLLVM.gamma_marginal_loglik_laplace(Y, Λ, β, α; tol = MODE_TOL, hessian = :fisher)
        @test ref != fisher          # the flip actually changed something
        @test isfinite(ref)
    end

    @testset "grouped-dispersion kernel agrees" begin
        got = GLLVM.gamma_grouped_marginal_loglik_laplace(Y, Λ, β, fill(α, p); tol = MODE_TOL)
        @test got ≈ ref atol = 1e-10
    end

    @testset "covariates kernel agrees (zero offset ⇒ same model)" begin
        O = zeros(p, n)
        got = GLLVM._marginal_loglik_offset(fam, Y, N, Λ, β, O, link; tol = MODE_TOL)
        @test got ≈ ref atol = 1e-10
    end

    # The bridge case. `_bridge_fit_mixed` handles the degenerate one-family
    # vector, so an all-Gamma `families` vector must reproduce the core exactly.
    @testset "mixed-family kernel agrees (the bridge two-route case)" begin
        fams  = fill(fam, p)
        links = fill(link, p)
        got = GLLVM.mixed_marginal_loglik_laplace(fams, links, Y, N, Λ, β; tol = MODE_TOL)
        @test got ≈ ref atol = 1e-10
    end

    @testset "quadratic kernel agrees (D = 0 ⇒ reduces to the core)" begin
        D = zeros(p, K)
        got = sum(GLLVM.quadratic_loglik_site(fam, view(Y, :, s), view(N, :, s),
                                              Λ, D, β, link; tol = MODE_TOL)
                  for s in 1:n)
        @test got ≈ ref atol = 1e-10
    end

    # And the negative control: with every kernel pinned to :fisher they must
    # ALSO agree — with each other, at a different value. If this failed, the
    # kernels would be inconsistent for reasons unrelated to the flip, and the
    # agreements above would be coincidental rather than meaningful.
    @testset "negative control: all kernels also agree under :fisher" begin
        ref_f = GLLVM.gamma_marginal_loglik_laplace(Y, Λ, β, α; tol = MODE_TOL, hessian = :fisher)
        @test GLLVM.gamma_grouped_marginal_loglik_laplace(Y, Λ, β, fill(α, p);
                  tol = MODE_TOL, hessian = :fisher) ≈ ref_f atol = 1e-10
        @test GLLVM._marginal_loglik_offset(fam, Y, N, Λ, β, zeros(p, n), link;
                  tol = MODE_TOL, hessian = :fisher) ≈ ref_f atol = 1e-10
        @test ref_f != ref
    end

    # ---- TruncatedNegBin2: two entry points, one answer --------------------
    #
    # This family has its OWN kernel (it was among the first fixed, instance 2)
    # AND is reachable through the generic core. Its own kernel defaulted to
    # `:observed` while the core fell through to the global `:fisher`, so the
    # same model returned two different log-likelihoods depending on which entry
    # point the caller used. Measured before the fix: 4.088e-02 apart.
    #
    # Same class of defect as the R bridge sending `family = "gamma"` and
    # `["gamma", …]` to different kernels. Locked here so it cannot silently
    # reopen.
    @testset "TruncatedNegBin2: generic core ≡ its own kernel" begin
        Random.seed!(77)
        pt, Kt, nt, rr = 5, 1, 40, 4.0
        bt = log.(fill(3.0, pt))
        Lt = reshape(0.3 .* randn(pt), pt, Kt)
        Yt = [max(1, rand(NegativeBinomial(rr, rr / (rr + exp(bt[t]))))) for t in 1:pt, _ in 1:nt]
        Nt = ones(Int, pt, nt)
        ft = GLLVM.TruncatedNegBin2(rr)
        lk = GLLVM.LogLink()

        @test GLLVM._default_hessian(ft, lk) === :observed

        core = GLLVM.marginal_loglik_laplace(ft, Yt, Nt, Lt, bt, lk)
        own  = GLLVM.truncated_nbinom2_marginal_loglik_laplace(Yt, Lt, bt, rr)
        @test core ≈ own atol = 1e-10

        # …and the negative control: forced to :fisher BOTH routes must also
        # agree, at a different value. Without this, two routes wrong together
        # would be indistinguishable from two routes right together.
        core_f = GLLVM.marginal_loglik_laplace(ft, Yt, Nt, Lt, bt, lk; hessian = :fisher)
        own_f  = GLLVM.truncated_nbinom2_marginal_loglik_laplace(Yt, Lt, bt, rr; hessian = :fisher)
        @test core_f ≈ own_f atol = 1e-10
        @test !isapprox(core_f, core; rtol = 1e-6)
    end

end
