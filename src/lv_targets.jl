# Internal truth targets for predictor-informed latent-score diagnostics.

function _center_columns(X::AbstractMatrix)
    Xc = Matrix{Float64}(X)
    Xc .-= mean(Xc; dims = 1)
    return Xc
end

"""
    _eta_realized_lv_effects(X_lv, Z_truth, Lambda) -> p × q matrix

Internal diagnostic target for Phylo Model A canaries. `X_lv` is the realised
site design (`n × q`), `Z_truth` is the realised latent-score truth (`n × K`),
and `Lambda` is the trait loading matrix (`p × K`). The returned matrix is the
trait-by-predictor least-squares slope of the noiseless latent-mediated trait
surface `Z_truth * Lambda'` on centred `X_lv`.

This is a finite-sample eta-scale target for diagnostics only. It deliberately
does not use observed responses.
"""
function _eta_realized_lv_effects(X_lv::AbstractMatrix,
                                  Z_truth::AbstractMatrix,
                                  Lambda::AbstractMatrix)
    n, q = size(X_lv)
    size(Z_truth, 1) == n || throw(ArgumentError(
        "Z_truth rows ($(size(Z_truth, 1))) must match X_lv rows ($n)"))
    p, K = size(Lambda)
    size(Z_truth, 2) == K || throw(ArgumentError(
        "Z_truth columns ($(size(Z_truth, 2))) must match Lambda columns ($K)"))

    Xc = _center_columns(X_lv)
    rank(Xc) == q || throw(ArgumentError(
        "centered X_lv must have full column rank $q to define B_eta_realized"))

    eta = Matrix{Float64}(Z_truth) * transpose(Matrix{Float64}(Lambda))
    etac = _center_columns(eta)
    slopes = Xc \ etac
    return Matrix(transpose(slopes))::Matrix{Float64}
end
