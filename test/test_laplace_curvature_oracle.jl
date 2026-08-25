# An INDEPENDENT oracle for the Laplace log-det curvature.
#
# Why this file exists. The adversarial review of the role-separation contract
# found that the package cannot currently tell a curvature fix from a curvature
# regression: `test/parity/` is not referenced by `runtests.jl` at all, and the
# only in-suite comparisons against an independent reference are three
# quadrature checks at atol 0.5 / 0.5 / 0.06 — loose enough to pass under either
# weight. Changing the weight before an instrument exists that can adjudicate it
# is how a DIFFERENT wrong weight ships fully green.
#
# The two oracles here are chosen because neither can be satisfied by tuning:
#
#   (1) CROSS-IMPLEMENTATION. The generic ForwardDiff fallback is compared
#       against observed-curvature formulas derived independently, by hand, and
#       living in a different file (grouped_dispersion.jl). Agreement at 1e-10
#       between an AD derivative and a hand-derived closed form is not something
#       a wrong implementation produces by accident.
#
#   (2) DIRECTION-OF-CHANGE vs numerical quadrature, WHERE IT HOLDS. See the
#       honesty note below — it does not hold everywhere, and this file asserts
#       it only where it was measured to hold.

using GLLVM, Test, Random, Distributions

@testset "Laplace curvature oracle" begin

    # ---- Oracle 1: generic fallback ≡ independently hand-derived formulas ----
    @testset "fallback ≡ grouped analytic (Gamma/log)" begin
        link = GLLVM.LogLink()
        for α in (0.7, 3.0, 12.0), η in (-1.5, 0.0, 2.0), y in (0.05, 1.0, 7.5)
            f  = Gamma(α, 1.0)
            μ  = GLLVM._clamp_mu(f, GLLVM.linkinv(link, η))
            me = GLLVM.mu_eta(link, η)
            @test GLLVM._glm_obs_weight(f, μ, 1, me, y, link, η) ≈
                  GLLVM._gamma_grouped_laplace_weight(:observed, f, μ, me, y, link) rtol = 1e-10
        end
    end

    @testset "fallback ≡ grouped analytic (Beta/logit)" begin
        link = GLLVM.LogitLink()
        for φ in (8.0, 12.0, 30.0), η in (-1.2, 0.0, 0.9), y in (0.15, 0.5, 0.87)
            f  = Beta(φ, 1.0)
            μ  = GLLVM._clamp_mu(f, GLLVM.linkinv(link, η))
            me = GLLVM.mu_eta(link, η)
            @test GLLVM._glm_obs_weight(f, μ, 1, me, y, link, η) ≈
                  GLLVM._beta_grouped_laplace_weight(:observed, f, μ, me, y, link, η) rtol = 1e-10
        end
    end

    # ---- The observed weight is genuinely signed --------------------------
    # Beta/logit produces NEGATIVE observed curvature at reachable (η, y). The
    # design anticipated this only for Student-t and GP-1; it is true here too,
    # which is why the PD guard sits at the Λ'WΛ + I assembly and why the weight
    # must never be clamped.
    @testset "Beta observed curvature can be negative (PD guard is load-bearing)" begin
        link = GLLVM.LogitLink()
        f = Beta(12.0, 1.0); η = -1.2; y = 0.87
        μ  = GLLVM._clamp_mu(f, GLLVM.linkinv(link, η))
        me = GLLVM.mu_eta(link, η)
        @test GLLVM._glm_obs_weight(f, μ, 1, me, y, link, η) < 0
        @test GLLVM._glm_weight(f, μ, 1, me) > 0        # Fisher is ≥ 0 by construction
    end

    # ---- Oracle 2: direction of change vs numerical quadrature -------------
    #
    # HONESTY NOTE, recorded because it contradicts the assumption this oracle
    # was proposed under. "Observed is closer to the exact marginal" is NOT a
    # universal property, and this file does not pretend it is. Measured over 12
    # seeds per family on K=1, p=6 fixtures:
    #
    #     Gamma / log    observed closer  12/12   (error 20-60x smaller)
    #     Beta  / logit  observed closer   2/12   (errors comparable, ~5e-3)
    #
    # So the assertion below is made for Gamma ONLY. For Beta the honest
    # statement is that the two approximations are comparable and Fisher is
    # usually marginally closer on these fixtures.
    #
    # This does not weaken the case for the change, because the goal is PARITY
    # WITH TMB, which computes the observed Hessian structurally — not "be
    # closer to the exact integral". Those are different claims and conflating
    # them would be exactly the kind of overclaim this project keeps catching.
    @testset "Gamma/log: observed is strictly closer to quadrature" begin
        function quad_gamma(y, Λ, β, α; lo = -10.0, hi = 10.0, m = 8001)
            zs = range(lo, hi; length = m); dz = step(zs); marg = 0.0
            for z in zs
                μ = exp.(β .+ Λ[:, 1] .* z)
                lp = sum(logpdf(Gamma(α, μ[t] / α), y[t]) for t in eachindex(y))
                marg += exp(lp) * pdf(Normal(), z) * dz
            end
            return log(marg)
        end
        for seed in (1, 4, 7, 12)
            Random.seed!(seed)
            p = 6; β = log.(fill(3.0, p)); α = 10.0
            Λ = reshape(0.3 .* randn(p), p, 1); zt = randn()
            μt = exp.(β .+ Λ[:, 1] .* zt)
            y  = [rand(Gamma(α, μt[t] / α)) for t in 1:p]
            Y  = reshape(y, p, 1)
            q  = quad_gamma(y, Λ, β, α)
            ef = abs(GLLVM.gamma_marginal_loglik_laplace(Y, Λ, β, α; hessian = :fisher)   - q)
            eo = abs(GLLVM.gamma_marginal_loglik_laplace(Y, Λ, β, α; hessian = :observed) - q)
            @test eo < ef
        end
    end
end
