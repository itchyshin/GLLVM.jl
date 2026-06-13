# Block-NA cross-lineage coevolution — the realistic data structure where host
# species measure only host traits and partner species only partner traits.
#
# This is the faithful block-NA companion to fit_coevolution_gaussian (the
# complete-data Kronecker fitter). The observed data is the two diagonal
# trait×species blocks:
#   Y_HH (T_H × n_H)  — host traits for host species,
#   Y_PP (T_P × n_P)  — partner traits for partner species,
# and d = [vec(Y_HH); vec(Y_PP)] is jointly Gaussian with the 2×2 block-of-
# Kroneckers covariance
#   M = [ A_H ⊗ Σ_HH     K_HP ⊗ Γ   ;
#         K_HPᵀ ⊗ Γᵀ   A_P ⊗ Σ_PP ]
# where Σ_T = Λ Λᵀ + σ² I (T×T trait covariance), Σ_HH/Σ_PP/Γ are its host/partner/
# cross blocks, A_H = K*[host,host], A_P = K*[partner,partner], K_HP = K*[host,
# partner]. The coevolution Γ = (Λ Λᵀ)[host_traits, partner_traits] is identified
# from the cross block K_HP ⊗ Γ — i.e. from how host-species host-traits covary
# with partner-species partner-traits across the phylogenetic bridge. (M verified
# to equal the selection of observed cells from the full K* ⊗ Σ_T to 0.)
#
# Smallest slice: a direct cholesky of M (O((T_H n_H + T_P n_P)³)) — exact, fine
# for moderate sizes; a Schur/Woodbury fast path is a perf follow-on. See
# docs/dev-log/2026-06-13-coevolution-kronecker-design.md.

using LinearAlgebra

# The 2×2 block-of-Kroneckers observed covariance.
function _blockna_cov(Σ_T::AbstractMatrix, A_H, A_P, K_HP, T_H::Int, T_P::Int)
    T = T_H + T_P
    Σ_HH = Σ_T[1:T_H, 1:T_H]
    Σ_PP = Σ_T[(T_H + 1):T, (T_H + 1):T]
    Γ = Σ_T[1:T_H, (T_H + 1):T]
    M12 = kron(K_HP, Γ)
    return [kron(A_H, Σ_HH) M12; M12' kron(A_P, Σ_PP)]
end

# params = [vec(Λ) (T*d), log σ]
function _coevolution_blockna_nll(params, d_obs, A_H, A_P, K_HP, T::Int, T_H::Int, T_P::Int, d::Int)
    Λ = reshape(@view(params[1:(T * d)]), T, d)
    σ2 = exp(2 * params[T * d + 1])
    Σ_T = Λ * Λ' + σ2 * I
    M = _blockna_cov(Σ_T, A_H, A_P, K_HP, T_H, T_P)
    chol = cholesky(Symmetric(M))
    dim = length(d_obs)
    return 0.5 * (dim * log(2π) + logdet(chol) + dot(d_obs, chol \ d_obs))
end

"""
    fit_coevolution_blockna(Y_HH, Y_PP, A_H, A_P, K_HP; d, ...) -> NamedTuple

Fit the block-NA cross-lineage coevolution model by maximum likelihood, where
`Y_HH` (`T_H × n_H`) are host traits for host species, `Y_PP` (`T_P × n_P`) are
partner traits for partner species, and `A_H`, `A_P`, `K_HP` are the host/partner/
cross blocks of the species kernel `K* = make_cross_kernel(...)`. Recovers the
coevolution `Γ = (Λ Λᵀ)[1:T_H, (T_H+1):T]` from the realistic data structure where
each lineage measures only its own traits.

Returns a NamedTuple with `Λ` (`T × d`, `T = T_H + T_P`, host block first), `σ`,
`logLik`, `converged`. Slice `Γ` from `Λ Λᵀ`.
"""
function fit_coevolution_blockna(Y_HH::AbstractMatrix, Y_PP::AbstractMatrix,
                                 A_H::AbstractMatrix, A_P::AbstractMatrix,
                                 K_HP::AbstractMatrix; d::Integer,
                                 g_tol::Real = 1e-8, iterations::Integer = 1000)
    T_H, n_H = size(Y_HH)
    T_P, n_P = size(Y_PP)
    T = T_H + T_P
    (size(A_H) == (n_H, n_H) && size(A_P) == (n_P, n_P) && size(K_HP) == (n_H, n_P)) ||
        throw(ArgumentError("A_H/A_P/K_HP must be n_H×n_H / n_P×n_P / n_H×n_P."))
    d ≥ 1 || throw(ArgumentError("d must be ≥ 1."))

    d_obs = vcat(vec(Y_HH), vec(Y_PP))

    # warm start: block-diagonal trait covariance (cross Γ starts ≈ 0, L-BFGS finds it).
    S_HH = Symmetric((Y_HH * (Symmetric(A_H) \ Y_HH')) ./ n_H)
    S_PP = Symmetric((Y_PP * (Symmetric(A_P) \ Y_PP')) ./ n_P)
    S = zeros(T, T)
    S[1:T_H, 1:T_H] = S_HH
    S[(T_H + 1):T, (T_H + 1):T] = S_PP
    E = eigen(Symmetric(S))
    idx = sortperm(E.values, rev = true)
    σ0 = sqrt(max(Statistics.mean(E.values[idx[min(d + 1, T):end]]), 1e-2))
    Λ0 = E.vectors[:, idx[1:d]] .* sqrt.(max.(E.values[idx[1:d]] .- σ0^2, 1e-2))'

    params0 = vcat(vec(Λ0), log(σ0))
    nll(θ) = _coevolution_blockna_nll(θ, d_obs, A_H, A_P, K_HP, T, T_H, T_P, d)
    res = Optim.optimize(nll, params0, Optim.LBFGS(),
                         Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :forward)
    θ = Optim.minimizer(res)
    Λ = reshape(θ[1:(T * d)], T, d)
    σ = exp(θ[T * d + 1])
    return (Λ = Λ, σ = σ, logLik = -Optim.minimum(res), converged = Optim.converged(res))
end
