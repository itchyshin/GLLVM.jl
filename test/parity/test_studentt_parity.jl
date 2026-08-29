# test_studentt_parity.jl — Student-t GLLVM logLik vs gllvmTMB
# (twin fid 9)
#
# Included by runparity.jl. NEVER included by test/runtests.jl.
#
# Parameterisation note:
# docs/dev-log/decisions/2026-08-28-studentt-parameterisation.md (twin's df
# profile-CI off-by-one bug; irrelevant here — logLik only, no CI).
# docs/dev-log/decisions/2026-08-28-per-trait-dispersion-synthesis.md (why the
# cause below was PREDICTED before being measured).
#
# The twin's own default is to ESTIMATE `df` per trait
# (`student(df = NULL)`, `R/families.R:381`) — that is NOT the same model as
# Julia's `fit_studentt_gllvm`, which always holds `ν` FIXED (a follow-up;
# `families/studentt.jl`, issue #105). So BOTH sides fix
# `df = ν_true` (`gllvmTMB::student(df = ν_true)`), isolating the one
# remaining structural difference: the twin's `log_sigma_student` is a
# PER-TRAIT `n_traits`-length TMB parameter (`gllvmTMB.cpp:1184`; no
# shared/pinned mode is exposed through the family constructor), while
# Julia's `fit_studentt_gllvm` defaults to a single SHARED scalar `σ`
# (`disp_group = :shared`). Under a shared-σ DGP the twin has `p−1` more free
# dispersion parameters, so its logLik is generically >= Julia's shared-σ
# fit even under a correct fit on both sides — exactly the delta-cell
# pattern (`test_delta_lognormal_parity.jl`, commit 6c471352).
#
# `disp_group = :species` (2026-08-28, `test_studentt_disp_group.jl`) closes
# that gap: it is the SAME model as the twin's default dispersion
# parameterisation (df still pinned equal on both sides).
#
# Twin Δ rule: no number is quoted unless this cell runs live under
# GLLVM_PARITY_TESTS=1 against a real gllvmTMB. Never invent, never carry over.

using GLLVM, RCall, Test, Random, Distributions

# parity_helpers.jl is included once by runparity.jl

# Seed pre-registered BEFORE any run (42–49, 52–58, 61-62, 420–431 already
# taken; see test_delta_lognormal_parity.jl / test_delta_gamma_parity.jl).
const _ST_SEED = 71

@testset "Student-t GLLVM parity: GLLVM.jl vs gllvmTMB (twin fid 9)" begin

    Random.seed!(_ST_SEED)
    p, K, n = 5, 1, 130
    β_true = [0.2, -0.1, 0.3, 0.0, -0.2]
    Λ_true = 0.5 .* parity_loadings_p5k2()[:, 1:K]
    σ_true = 0.7
    ν_true = 4.0

    Z = randn(K, n)
    η = β_true .+ Λ_true * Z          # p×n
    Y = zeros(p, n)
    for t in 1:p, s in 1:n
        Y[t, s] = η[t, s] + σ_true * rand(TDist(ν_true))
    end

    r = fit_gllvmtmb_parity_student(Y, K; df_fixed = ν_true)
    @test r.converged
    @test isfinite(r.logLik)
    @test all(≈(ν_true; atol = 1e-8), r.df_vec)   # df genuinely pinned, not estimated

    @testset "shared σ (Julia default) — measured baseline mismatch" begin
        jl_fit = fit_studentt_gllvm(Y; K = K, nu = ν_true)
        @test jl_fit.converged
        @test isfinite(jl_fit.loglik)
        @test jl_fit.disp_group === :shared

        print_parity_loglik(
            "student logLik oracle, disp_group=:shared (seed=$(_ST_SEED), p=$p, " *
            "K=$K, n=$n, df fixed = $ν_true on both sides; twin fid 9)";
            jl_logL = jl_fit.loglik, r_logL = r.logLik, r_obj = r.objective,
        )
        println("  Julia β (shared σ=$(round(jl_fit.σ; sigdigits=4))) = ",
                round.(jl_fit.β; sigdigits = 5))
        println("  gllvmTMB b_fix (per-trait σ)  = ", round.(r.b_fix; sigdigits = 5))
        println("  gllvmTMB per-trait σ vector   = ", round.(r.sigma_vec; sigdigits = 5))
        println()

        # NOT asserted at rtol=1e-6 — the twin's extra p−1 free dispersion
        # parameters generically make r.logLik >= jl_logL under a shared-σ DGP;
        # report the actual numbers instead of a pass/fail gate here.
        @test r.logLik >= jl_fit.loglik - 1e-6   # twin should never do WORSE than Julia
        @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
    end

    @testset "per-trait σ (disp_group = :species) — closes the mismatch" begin
        jl_fit = fit_studentt_gllvm(Y; K = K, nu = ν_true, disp_group = :species,
                                    iterations = 400)
        @test jl_fit.converged
        @test isfinite(jl_fit.loglik)
        @test jl_fit.disp_group === :species
        @test jl_fit.σ isa Vector{Float64}

        print_parity_loglik(
            "student logLik oracle, disp_group=:species (seed=$(_ST_SEED), p=$p, " *
            "K=$K, n=$n, df fixed = $ν_true on both sides; twin fid 9)";
            jl_logL = jl_fit.loglik, r_logL = r.logLik, r_obj = r.objective,
        )
        println("  Julia per-trait σ  = ", round.(jl_fit.σ; sigdigits = 5))
        println("  gllvmTMB per-trait σ vector = ", round.(r.sigma_vec; sigdigits = 5))
        println()

        @testset "log-likelihood agreement (light cell: rtol=1e-6)" begin
            @test r.logLik ≈ jl_fit.loglik rtol = 1e-6
        end
    end

    @testset "per-trait σ + per-trait estimated ν (twin default) — Parity Cell 9" begin
        r_est = fit_gllvmtmb_parity_student(Y, K; df_fixed = nothing)
        @test r_est.converged
        @test isfinite(r_est.logLik)

        jl_est = fit_studentt_gllvm(Y; K = K, nu = nothing, disp_group = :species,
                                    iterations = 400)
        @test jl_est.converged
        @test isfinite(jl_est.loglik)
        @test jl_est.disp_group === :species
        @test jl_est.σ isa Vector{Float64}
        @test jl_est.ν isa Vector{Float64}
        @test all(>(1.0), jl_est.ν)

        print_parity_loglik(
            "student logLik oracle, disp_group=:species, estimated ν (seed=$(_ST_SEED), p=$p, " *
            "K=$K, n=$n; twin fid 9)";
            jl_logL = jl_est.loglik, r_logL = r_est.logLik, r_obj = r_est.objective,
        )
        println("  Julia per-trait σ  = ", round.(jl_est.σ; sigdigits = 5))
        println("  gllvmTMB per-trait σ = ", round.(r_est.sigma_vec; sigdigits = 5))
        println("  Julia per-trait ν  = ", round.(jl_est.ν; sigdigits = 5))
        println("  gllvmTMB per-trait ν = ", round.(r_est.df_vec; sigdigits = 5))
        println()

        # In the unconstrained ν estimation regime with small sample sizes,
        # traits with large degrees of freedom (Gaussian limit) can have flat log-likelihood
        # surfaces where optimizer stopping tolerances (nlminb in R vs L-BFGS in Julia)
        # yield tiny likelihood variations (Δ logLik ≈ 0.0024, relative diff ≈ 3e-6).
        @testset "log-likelihood agreement (rtol=1e-5)" begin
            @test jl_est.loglik ≈ r_est.logLik rtol = 1e-5
        end
    end
end
