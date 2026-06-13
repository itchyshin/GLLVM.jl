# Cross-lineage coevolution kernel (PGLLVM "two lineages", phase C0).
#
# Julia mirror of gllvmTMB::make_cross_kernel (R/kernel-helpers.R). Builds the
# block relatedness matrix
#
#     K* = [ A_H    C_HP ;
#            C_HP'  A_P  ]
#
# for the cross-lineage coevolution prototype, where A_H, A_P are within-lineage
# correlation matrices and C_HP = rho * L_H * W̃ * L_P' is the cross-lineage
# bridge induced by the association matrix W (L L' = A; W̃ = W spectrally scaled
# so K* stays positive semidefinite). Within-lineage null is rho = 0:
# K* = blockdiag(A_H, A_P), Γ = 0.
#
# The kernel feeds the existing Gaussian phylo path: pass K* as Σ_phy to
# fit_gaussian_gllvm on the stacked, block-NA two-lineage response. The
# coevolution estimand is Γ = Λ_H Λ_P' (host-trait × partner-trait loadings),
# sliced post-fit.
#
# References:
#   - Hadfield & Nakagawa 2010 JEB appendix (the Σ_phy entry point)
#   - Manceau, Lambert & Morlon 2017 Syst Biol (coevolving traits across
#     interacting lineages; the block-kernel basis)

using LinearAlgebra

"""
    make_cross_kernel(A_H, A_P, W; rho = 0.5, eps = 1e-8)
        -> Symmetric{Float64, Matrix{Float64}}

Build the cross-lineage relatedness kernel `K*` for the C0 coevolution
prototype. `A_H` and `A_P` are the within-lineage correlation matrices (host
first, partner second); `W` (`size(A_H,1) × size(A_P,1)`) is the host–partner
association matrix. `rho ∈ [-1, 1]` is the bridge strength: larger `|rho|` puts
more covariance in the off-diagonal host–partner block. The returned matrix is
correlation-scaled (unit diagonal), symmetric, and positive semidefinite, with
the host block first and the partner block second — ready to pass as `Σ_phy` to
`fit_gaussian_gllvm`.

`A_H` and `A_P` must be symmetric, positive semidefinite, and have unit
diagonal. `eps` is a positive numerical floor used when taking symmetric square
roots and scaling a near-zero `W`.

This mirrors `gllvmTMB::make_cross_kernel` so the R and Julia twins build the
identical `K*`.

# Examples
```julia
julia> A_H = [1.0 0.3 0.1; 0.3 1.0 0.2; 0.1 0.2 1.0];

julia> A_P = [1.0 0.25; 0.25 1.0];

julia> W = [1.0 0.0; 0.5 0.0; 1.0 0.25];

julia> K = make_cross_kernel(A_H, A_P, W; rho = 0.4);

julia> size(K), all(≈(1.0), diag(K))
((5, 5), true)
```
"""
function make_cross_kernel(A_H::AbstractMatrix, A_P::AbstractMatrix,
                           W::AbstractMatrix; rho::Real = 0.5, eps::Real = 1e-8)
    isfinite(rho) ||
        throw(ArgumentError("`rho` must be one finite number."))
    abs(rho) <= 1 || throw(ArgumentError(
        "`rho` must lie in [-1, 1]; the cross block is spectrally scaled, so " *
        "|rho| <= 1 keeps the block kernel positive semidefinite."))
    (isfinite(eps) && eps > 0) ||
        throw(ArgumentError("`eps` must be one positive finite number."))

    AH = _cross_kernel_as_matrix(A_H, "A_H")
    AP = _cross_kernel_as_matrix(A_P, "A_P")
    Wm = _cross_kernel_as_matrix(W, "W"; square = false)

    _cross_kernel_check_correlation(AH, "A_H", eps)
    _cross_kernel_check_correlation(AP, "A_P", eps)

    n_H = size(AH, 1)
    n_P = size(AP, 1)
    (size(Wm, 1) == n_H && size(Wm, 2) == n_P) || throw(ArgumentError(
        "`W` must be size(A_H,1) × size(A_P,1) = $(n_H) × $(n_P); " *
        "got $(size(Wm, 1)) × $(size(Wm, 2))."))

    L_H = _cross_kernel_symmetric_sqrt(AH, eps)
    L_P = _cross_kernel_symmetric_sqrt(AP, eps)

    sv = svdvals(Wm)
    spectral_norm = isempty(sv) ? 0.0 : sv[1]
    W_scaled = Wm ./ max(spectral_norm, eps)
    C_HP = rho .* (L_H * W_scaled * transpose(L_P))

    n = n_H + n_P
    K = zeros(Float64, n, n)
    K[1:n_H, 1:n_H] = AH
    K[(n_H + 1):n, (n_H + 1):n] = AP
    K[1:n_H, (n_H + 1):n] = C_HP
    K[(n_H + 1):n, 1:n_H] = transpose(C_HP)
    K = (K + transpose(K)) ./ 2
    @inbounds for i in 1:n
        K[i, i] = 1.0
    end

    min_eig = minimum(eigvals(Symmetric(K)))
    (isfinite(min_eig) && min_eig >= -1e-6) || throw(ArgumentError(
        "Cross-lineage kernel is not positive semidefinite " *
        "(minimum eigenvalue $(min_eig)). Lower `rho` or rescale `W`."))

    Symmetric(K)
end

function _cross_kernel_as_matrix(x, arg::AbstractString; square::Bool = true)
    m = Matrix{Float64}(x)
    all(isfinite, m) ||
        throw(ArgumentError("`$arg` must contain only finite, non-missing values."))
    (!square || size(m, 1) == size(m, 2)) ||
        throw(ArgumentError("`$arg` must be square."))
    m
end

function _cross_kernel_check_correlation(A::AbstractMatrix, arg::AbstractString,
                                         eps::Real)
    maximum(abs, A - transpose(A)) <= sqrt(eps) ||
        throw(ArgumentError("`$arg` must be symmetric."))
    maximum(abs, diag(A) .- 1) <= sqrt(eps) || throw(ArgumentError(
        "`$arg` must be correlation-scaled with unit diagonal; " *
        "scale the relatedness matrix before calling `make_cross_kernel`."))
    min_eig = minimum(eigvals(Symmetric((A + transpose(A)) ./ 2)))
    (isfinite(min_eig) && min_eig >= -1e-6) || throw(ArgumentError(
        "`$arg` must be positive semidefinite (minimum eigenvalue $(min_eig))."))
    nothing
end

function _cross_kernel_symmetric_sqrt(A::AbstractMatrix, eps::Real)
    F = eigen(Symmetric((A + transpose(A)) ./ 2))
    vals = max.(F.values, eps)
    F.vectors * Diagonal(sqrt.(vals)) * transpose(F.vectors)
end
