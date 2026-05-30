# test_gaussian_parity.jl — Gaussian GLLVM parity: GLLVM.jl vs R gllvmTMB
#
# Included by runparity.jl after the env gate and RCall load succeed.
# NEVER included by test/runtests.jl.
#
# ── Why rotation-invariant quantities only? ──────────────────────────────────
# The loading matrix Λ has two non-identifiable symmetries under a Gaussian
# GLLVM:
#
#   1. Rotation invariance: for any orthogonal Q, ΛQ gives the same marginal
#      covariance ΛΛᵀ and thus the same likelihood.  Two implementations that
#      agree on the log-likelihood can return completely different Λ matrices.
#
#   2. Column-sign flip: flipping the sign of any column of Λ (together with
#      the corresponding row of the latent-factor draws) leaves the model
#      unchanged.
#
# GLLVM.jl pins the rotational degree of freedom with a lower-triangular
# constraint, but gllvmTMB uses a different canonical form.  Even with
# the same constraint, sign choices may differ.  Comparing raw Λ entries
# would produce spurious failures.
#
# The rotation-INVARIANT quantities that CAN be compared meaningfully:
#   • marginal log-likelihood (scalar, fully invariant)
#   • fitted covariance Σ_y = ΛΛᵀ + σ²_eps I  (invariant under ΛQ, Q'Q=I)
#   • residual SD σ_eps (invariant)
#
# All @test assertions below use only these invariants.

using GLLVM, RCall, Test, Random, LinearAlgebra, Statistics

@testset "Gaussian GLLVM parity: GLLVM.jl vs gllvmTMB" begin

    # ── 1. Simulate data (inline DGP — same pattern as test/test_fit.jl) ────
    # simulate.jl is currently a placeholder (see src/simulate.jl). We use
    # the canonical inline DGP from the existing test suite.
    Random.seed!(42)
    p, K, n = 5, 2, 80   # small: p traits, K latent factors, n sites

    Λ_true = [
        0.8   0.0;   # lower-triangular canonical form (top K×K block)
        0.5   0.6;
        0.3  -0.4;
       -0.2   0.5;
        0.1   0.3
    ]
    σ_true = 0.7

    η = randn(K, n)                       # K × n latent scores
    y = Λ_true * η + σ_true * randn(p, n) # p × n data matrix (sites in columns)

    # ── 2. Julia fit via GLLVM.jl ────────────────────────────────────────────
    jl_fit = fit_gaussian_gllvm(y; K = K)

    @test jl_fit.converged           "GLLVM.jl fit did not converge"
    @test isfinite(jl_fit.logLik)    "GLLVM.jl logLik is not finite"

    jl_logL  = jl_fit.logLik
    jl_Λ     = jl_fit.pars.Λ          # p × K loadings (rotation-non-unique)
    jl_σ_eps = jl_fit.pars.σ_eps      # residual SD
    jl_Σ_y   = jl_Λ * jl_Λ' + jl_σ_eps^2 * I(p)   # rotation-invariant

    # ── 3. R fit via gllvmTMB ────────────────────────────────────────────────
    #
    # DRAFT: R call shape not yet validated against a live R env —
    # verify when R + gllvmTMB are installed (Phase 1.0 follow-up).
    #
    # gllvmTMB formula reference:
    #   gllvm(y, family = "gaussian", num.lv = K)  [gllvm-style]
    #   or, for the TMB variant:
    #   gllvmTMB(traits(cbind(y1,…,yp)) ~ 1, data = ..., family = gaussian(),
    #             num.lv = K)
    #
    # The API below uses `gllvm::gllvm()` (the CRAN package) rather than the
    # development `gllvmTMB` function, because the CRAN interface is more
    # stable and the Gaussian log-likelihood is identical between the two when
    # num.lv = K and family = "gaussian".  If the maintainer's R environment
    # has only the TMB variant, swap the R call accordingly — see the
    # DRAFT comment above.

    @rput y K p n         # transfer Julia → R

    r_result = R"""
        # DRAFT: R call shape not yet validated against a live R env — verify
        # when R + gllvmTMB are installed (Phase 1.0 follow-up).

        # gllvmTMB is the development version of gllvm on GitHub.  The CRAN
        # package is 'gllvm'; the function call is gllvm::gllvm().
        # For the dev TMB variant, it may be gllvmTMB::gllvmTMB() instead.
        # Adjust the library() call and function name to match the installation.

        if (!requireNamespace("gllvm", quietly = TRUE)) {
            stop("R package 'gllvm' is not installed. ",
                 "Install with: install.packages('gllvm')")
        }
        library(gllvm)

        # y arrives as a p × n matrix (species in rows, sites in columns).
        # gllvm expects sites in rows, species in columns, so transpose.
        Y_r <- t(y)          # n × p

        # Fit Gaussian GLLVM with K latent variables, intercept-only mean.
        # DRAFT: num.lv, family, and optimizer arguments should be verified
        # against the installed gllvm / gllvmTMB version.
        fit_r <- gllvm(
            Y_r,
            num.lv  = K,
            family  = "gaussian",
            # Use VA (variational approximation) or Laplace; for Gaussian with
            # no random covariate effects the VA log-lik equals the exact
            # marginal — but confirm this with the gllvmTMB docs.
            # method  = "VA",    # uncomment if needed
            seed    = 42L
        )

        # Extract the rotation-invariant quantities.
        # DRAFT: extractor names below are based on the gllvm 1.x API;
        # verify field names match the installed version.
        r_logL   <- fit_r$logL           # marginal log-likelihood (scalar)
        r_theta  <- fit_r$params$theta   # loadings matrix (n.lv × p, DRAFT name)
        r_sigma  <- fit_r$params$sigma   # residual SD vector (length p) or scalar

        # Build Σ_y on the R side for transfer.  gllvm stores loadings as
        # (p × K) in params$theta or params$LvXcoef — DRAFT: confirm shape.
        # Here we assume theta is p × K (transposing if necessary).
        Lam <- r_theta          # adjust if shape differs
        if (nrow(Lam) != p || ncol(Lam) != K) {
            Lam <- t(Lam)       # try transposing
        }
        # Use the mean residual SD if it is returned per-trait.
        sigma_eps_r <- if (length(r_sigma) == 1L) r_sigma else mean(r_sigma)
        Sigma_y_r   <- Lam %*% t(Lam) + diag(sigma_eps_r^2, p)

        list(logL     = r_logL,
             sigma    = sigma_eps_r,
             Sigma_y  = Sigma_y_r)
    """

    r_logL   = rcopy(Float64,     R"r_result$logL")
    r_sigma  = rcopy(Float64,     R"r_result$sigma")
    r_Σ_y    = rcopy(Matrix{Float64}, R"r_result$Sigma_y")

    # ── 4. Parity assertions (rotation-invariant quantities only) ────────────
    #
    # Tolerances are PROVISIONAL and intentionally moderate.  The package
    # headline claims machine-precision log-likelihood agreement vs gllvmTMB.
    # These can be tightened (e.g. logL rtol → 1e-6) once the R call is
    # validated in a live environment and the gllvmTMB objective is confirmed
    # to be the same marginal log-likelihood as GLLVM.jl's.

    @testset "log-likelihood agreement (provisional rtol=1e-3)" begin
        # Both should return the same marginal log-likelihood at the MLE.
        # A relative gap > 1e-3 suggests one optimizer is not at the optimum
        # or the objectives are not equivalent.
        @test jl_logL ≈ r_logL rtol=1e-3
    end

    @testset "fitted covariance Σ_y agreement (provisional atol=1e-2)" begin
        # Σ_y = ΛΛᵀ + σ²_eps I is rotation-invariant and should agree
        # entry-wise up to optimizer-induced rounding.
        for i in 1:p, j in 1:p
            @test jl_Σ_y[i, j] ≈ r_Σ_y[i, j] atol=1e-2 broken=false
        end
    end

    @testset "residual SD σ_eps agreement (provisional rtol=5e-2)" begin
        # If gllvmTMB returns per-trait σ values, r_sigma is the mean;
        # GLLVM.jl currently fits a shared σ_eps.  Agreement within 5% at
        # n=80, p=5 is consistent with MLE sampling variation.
        @test jl_σ_eps ≈ r_sigma rtol=5e-2
    end

end  # @testset
