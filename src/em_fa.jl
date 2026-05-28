# EM algorithm for factor analysis with per-trait diagonal idiosyncratic
# variance. Reference: Rubin & Thayer (1982) "EM algorithms for ML factor
# analysis", Psychometrika 47, 69-76.
#
# Model:  y[:, s] ~ N(0, Λ Λ' + diag(ψ))  with Λ ∈ R^{p × K}, ψ ∈ R^p_{++}.
#
# Both M-step updates have closed form (no inner optimisation). For
# moderate p and K, this is competitive with LBFGS + AD on wall-clock
# per iteration AND often converges in fewer iterations.
#
# This file defines `em_fa` inside the gllvmTMB module via `@eval`, so it
# can be referenced as `gllvmTMB.em_fa` without modifying the module's
# top-level `gllvmTMB.jl` include list.

@eval gllvmTMB begin

using LinearAlgebra

"""
    em_fa(y::AbstractMatrix, K::Integer;
          λ_init = nothing, ψ_init = nothing,
          tol = 1e-8, max_iter = 500)
        -> (Λ, ψ, loglik, n_iter, converged)

EM for factor analysis. `y` is (p, n). Returns Λ (p × K), ψ (p-vector of
positive idiosyncratic variances), final log-likelihood, iteration count,
and convergence flag.

E-step (per observation s):
    β = Λ'(ΛΛ' + Ψ)⁻¹                        (K × p, via Woodbury)
    E[η_s | y_s]      = β y_s
    E[η_s η_s' | y_s] = I − β Λ + β y_s y_s' β'

M-step (aggregated over s = 1, …, n):
    S_yy = Y Y'                              (p × p)
    S_yη = S_yy β'                            (p × K)
    S_ηη = n (I − β Λ) + β S_yy β'            (K × K)
    Λ_new = S_yη S_ηη⁻¹
    ψ_new = diag(S_yy − Λ_new S_yη') / n

Both updates are closed-form. The log-likelihood is evaluated via
Woodbury at the start of each iteration (i.e. at the parameters produced
by the previous M-step) so monotone non-decrease is testable.
"""
function em_fa(y::AbstractMatrix, K::Integer;
               λ_init = nothing, ψ_init = nothing,
               tol = 1e-8, max_iter = 500)
    p, n = size(y)
    @assert K ≥ 1 && K < p

    # Initialisation -------------------------------------------------
    Λ = if isnothing(λ_init)
        # Small noise with positive diagonal entries; upper-triangular
        # zeros above the K-th column to break rotational symmetry.
        Λ_init = 0.1 .* randn(p, K)
        for k in 1:K
            Λ_init[k, k] = abs(Λ_init[k, k]) + 0.5
        end
        for i in 1:K, k in 1:K
            if i < k
                Λ_init[i, k] = 0.0
            end
        end
        Λ_init
    else
        copy(λ_init)
    end

    ψ = if isnothing(ψ_init)
        vec(sum(y .^ 2, dims = 2)) ./ n
    else
        copy(ψ_init)
    end
    ψ .= max.(ψ, eps())

    # Pre-compute the constant data scatter ---------------------------
    S_yy = y * y'                       # p × p, symmetric, PSD
    loglik_prev = -Inf

    # Helper: log-likelihood of y under N(0, Λ Λ' + diag(ψ)) via Woodbury.
    # Returns (loglik, ΛTΨinv, M_inv, β) so the caller can reuse them
    # for the E-step.
    function _loglik_woodbury(Λ, ψ)
        Ψinv_diag = 1.0 ./ ψ                          # p
        ΛTΨinv    = Λ' .* Ψinv_diag'                  # K × p   (= Λ' Ψ⁻¹)
        M         = Symmetric(I + ΛTΨinv * Λ)         # K × K   (= I + Λ' Ψ⁻¹ Λ)
        Mchol     = cholesky(M)
        M_inv     = inv(Mchol)
        β         = M_inv * ΛTΨinv                    # K × p
        # logdet(Σ_y) = sum(log ψ) + logdet(I + Λ' Ψ⁻¹ Λ)
        logdetΣ   = sum(log.(ψ)) + logdet(Mchol)
        # tr(Y' Σ_y⁻¹ Y) = tr(Y' Ψ⁻¹ Y) − tr((Ψ⁻¹ Λ) M⁻¹ (Λ' Ψ⁻¹) Y Y')
        # First piece: Σ_s y_s' Ψ⁻¹ y_s = Σ_{t,s} y[t,s]² / ψ[t]
        quad_a = sum(y .* (Ψinv_diag .* y))
        # Second piece: V = ΛTΨinv * Y is K × n; tr(M⁻¹ V V').
        V      = ΛTΨinv * y                            # K × n
        quad_b = tr(M_inv * (V * V'))
        quad   = quad_a - quad_b
        loglik = -0.5 * (n * p * log(2π) + n * logdetΣ + quad)
        return loglik, ΛTΨinv, M_inv, β
    end

    local Λ_final = Λ
    local ψ_final = ψ
    local loglik  = -Inf

    for iter in 1:max_iter
        # Log-likelihood + Woodbury pieces at the CURRENT parameters.
        # Evaluating before the M-step means we measure log-lik at the
        # output of the previous M-step (or at the initial values on
        # iter == 1), so the sequence is monotone non-decreasing.
        loglik, ΛTΨinv, M_inv, β = _loglik_woodbury(Λ, ψ)

        if iter > 1 && abs(loglik - loglik_prev) < tol
            return (Λ, ψ, loglik, iter, true)
        end
        loglik_prev = loglik

        # E-step sufficient statistics (aggregated over s).
        # E[η_s | y_s]      = β y_s
        # E[η_s η_s' | y_s] = I − β Λ + β y_s y_s' β'
        # ⇒ S_yη = Σ_s y_s (β y_s)' = S_yy β'
        #   S_ηη = n (I − β Λ) + β S_yy β'
        S_yη = S_yy * β'                              # p × K
        S_ηη = n .* (I - β * Λ) + β * S_yy * β'       # K × K
        S_ηη = Symmetric(0.5 .* (S_ηη + S_ηη'))       # symmetrise (numerical)

        # M-step (closed form for both Λ and ψ).
        Λ_new = S_yη / S_ηη                            # p × K
        # ψ_new[t] = (S_yy[t,t] - Λ_new[t,:] · S_yη[t,:]) / n
        ψ_new = (diag(S_yy) .- vec(sum(Λ_new .* S_yη, dims = 2))) ./ n
        ψ_new .= max.(ψ_new, eps())

        Λ = Λ_new
        ψ = ψ_new

        Λ_final = Λ
        ψ_final = ψ
    end

    # Reached max_iter without meeting tol. Evaluate one final
    # log-lik at the last (Λ, ψ) so the return value is consistent
    # with the parameters being returned.
    loglik_final, _, _, _ = _loglik_woodbury(Λ_final, ψ_final)
    return (Λ_final, ψ_final, loglik_final, max_iter, false)
end

end  # @eval gllvmTMB
