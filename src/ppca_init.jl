# Probabilistic PCA closed-form ML initialisation for the Gaussian GLLVM.
# Reference: Tipping & Bishop (1999) "Probabilistic Principal Component
# Analysis", J. R. Statist. Soc. B 61(3): 611-622, equations 8-11.
#
# Solves the pure problem y ~ N(0, Λ Λ' + σ² I) in CLOSED FORM via SVD,
# producing the EXACT ML estimates for Λ and σ² (no iteration). Used as
# the initialisation point for the more general LBFGS optimisation when
# the model has additional structure (W tier, diag RE, phy) — there the
# closed form is the right answer for the dominant Λ + σ² piece, leaving
# only a few LBFGS iterations to refine the smaller contributions.
#
# Wiring:
#   This file expects to be `include`d by `src/gllvmTMB.jl`; the
#   integration agent will add that include line and (optionally) export
#   `ppca_init`. Until then, the function is reachable inside the package
#   namespace as `gllvmTMB.ppca_init` once the include is in place. This
#   file exports nothing on its own.

using LinearAlgebra

"""
    ppca_init(y::AbstractMatrix, K::Integer; lower_tri::Bool = true) -> (Λ, σ_eps)

Closed-form PPCA initialisation. `y` is (p, n_sites). Returns `Λ` (p × K)
and `σ_eps` (positive scalar).

Implements the maximum-likelihood estimator of Tipping & Bishop (1999,
eqs. 8-11) for the model `y ~ N(0, Λ Λ' + σ² I)`. Let S = y y' / n,
with eigendecomposition S = U Λ_S U' and eigenvalues sorted in
descending order. Then

  σ̂² = (1/(p - K)) Σ_{k=K+1}^p Λ_S[k]
  Λ̂  = U_K (Λ_S[1:K] - σ̂² I)^{1/2}

where U_K is the leading p × K block of U. Negative residual eigenvalues
(Λ_S[k] < σ̂² for k ≤ K) are floored at zero, matching the standard
PPCA convention.

If `lower_tri = true` (default), rotate Λ so its top K × K block is
lower triangular with positive diagonals, matching the engine's
packing convention. The rotation is orthogonal, so Λ Λ' (and therefore
the model likelihood) is invariant — see `rotate_to_lower_triangular`.

For p ≤ K the closed-form PPCA solution is degenerate (no residual
eigenvalues to estimate σ² from); this implementation requires K < p.
"""
function ppca_init(y::AbstractMatrix, K::Integer; lower_tri::Bool = true)
    p, n = size(y)
    K ≥ 1 || throw(ArgumentError("K must be ≥ 1"))
    K < p || throw(ArgumentError("PPCA requires K < p; got K=$K, p=$p"))

    # Sample covariance (ML estimator uses n, not n - 1)
    S = (y * y') ./ n              # p × p

    # Symmetric eigendecomposition (Julia returns ascending eigenvalues)
    eig = eigen(Symmetric(S))
    λ = reverse(eig.values)        # descending
    U = reverse(eig.vectors, dims=2)

    # ML σ² is the mean of the (p - K) smallest eigenvalues
    σ²_hat = sum(λ[(K + 1):p]) / (p - K)
    σ_eps  = sqrt(max(σ²_hat, eps()))

    # ML Λ = U_K (Λ_K - σ² I)^{1/2}; floor negative residuals at zero
    Λ_K_minus = max.(λ[1:K] .- σ²_hat, 0.0)
    Λ_raw = U[:, 1:K] .* sqrt.(Λ_K_minus)'

    if lower_tri
        Λ = rotate_to_lower_triangular(Λ_raw)
        return Λ, σ_eps
    else
        return Λ_raw, σ_eps
    end
end

"""
    rotate_to_lower_triangular(Λ::AbstractMatrix) -> Matrix

Rotate a p × K loading matrix (p ≥ K) so its top K × K block is lower
triangular with positive diagonals — the canonical sign / orientation
used by the engine's packing convention. The rotation is orthogonal
(K × K), so Λ Λ' is preserved and any GLLVM likelihood depending only
on Λ Λ' is invariant.

Convention used here: QR-decompose Λ' (a K × p matrix). The thin Q
factor is K × K orthogonal; Q'·Λ' is upper-triangular in its first K
columns, so Λ·Q has a lower-triangular top K × K block. We then flip
the sign of any column whose new diagonal entry is negative, restoring
the positive-diagonal sign anchor used by `unpack_lambda`.

Note that this convention determines a sign per column but does NOT
fix the overall orientation when Λ Λ' has repeated eigenvalues. In
that degenerate case any rotation within the repeated-eigenvalue
subspace is equally valid; the QR pivoting choice is implementation-
defined.
"""
function rotate_to_lower_triangular(Λ::AbstractMatrix)
    p, K = size(Λ)
    p ≥ K || throw(ArgumentError(
        "rotate_to_lower_triangular requires p ≥ K; got p=$p, K=$K"))

    # QR of Λ' (K × p): F.Q is K × K orthogonal, F.R is K × p with the
    # top K × K block upper-triangular. Then Λ' = Q*R, so Λ = R'*Q', and
    # the rotated Λ' = Λ * Q = R' has a lower-triangular top K × K block.
    F = qr(transpose(Λ))
    Q = Matrix(F.Q)                # K × K orthogonal (thin form)
    Λ_rot = Λ * Q                  # p × K, top K × K is lower-triangular

    # Enforce positive diagonals (multiply column by -1 if needed). This
    # is also an orthogonal transformation (a sign flip), so Λ Λ' is
    # preserved.
    @inbounds for k in 1:K
        if Λ_rot[k, k] < 0
            @views Λ_rot[:, k] .*= -1
        end
    end

    # Zero out any tiny numerical residue in the strict-upper triangle
    # so the result matches the packing convention exactly.
    @inbounds for k in 1:K, i in 1:(k - 1)
        Λ_rot[i, k] = 0
    end

    return Λ_rot
end
