# Destination B — grouped Gaussian kernel contract

Status: bounded internal kernel contract; not an exported fitting route or a
qualification claim.

## Model and coordinate order

For `Y` with `p` traits and `n` units, columns are units and traits vary fastest
under `r = vec(Y - beta)`.  Each source `s` has a sparse `n × q_s` incidence
matrix `Z_s`, a direct `p × k_s` loading matrix `L_s`, and independent latent
scores `a_s ~ N(0, I_(q_s k_s))`.  Sources are independent.  An optional
non-negative trait-unique variance vector `d_s` is represented by appending
only the nonzero columns of `diag(sqrt(d_s))` to `L_s`; its zero entries do not
create a ridge. Call this augmented loading `L_s^*`. The Gaussian observation model is

```math
vec(Y) = vec(beta) + \sum_s (Z_s \otimes L_s^*)a_s + e,
\qquad e \sim N(0, \sigma_\epsilon^2 I_{pn}).
```

Thus the marginal covariance is

```math
V = \sigma_\epsilon^2 I_{pn} +
    \sum_s (Z_s Z_s^\mathsf{T}) \otimes (L_s^* L_s^{*\mathsf{T}}).
```

The factor kernel must not assemble `V`.  With `W = [Z_1 \otimes L_1^* \;
\cdots \; Z_S \otimes L_S^*]`, it evaluates the sparse random-effect
precision

```math
K = I + W^\mathsf{T}W/\sigma_\epsilon^2,
\quad h = W^\mathsf{T}r/\sigma_\epsilon^2,
```

and returns

```math
-2\ell = pn\log(2\pi) + pn\log(\sigma_\epsilon^2) + \log|K|
       + r^\mathsf{T}r/\sigma_\epsilon^2 - h^\mathsf{T}K^{-1}h.
```

`W` and `K` are sparse (`SparseMatrixCSC` / CHOLMOD) and have random-factor
dimension `sum(q_s*k_s^*)`, never response dimension `p*n`.  This admits bare
rank-one `p ≥ 3` blocks without diagonal jitter.  The former SPD-covariance
convenience call is only a full-rank Cholesky factorisation into this direct
factor representation; it is not the parameterisation of the latent model.

For the quadratic form, the implementation evaluates the equivalent
posterior-mode expression `||r - W u||²/sigma_eps² + ||u||²`, where
`u = K^{-1}h`, rather than subtracting `r'r/sigma_eps² - h'K^{-1}h`. The latter
loses all useful digits at small residual SD and large grouped signal.

## Symbolic alignment

| Symbol | Julia kernel coordinate | deterministic fixture | asserted quantity | truth |
| --- | --- | --- | --- | --- |
| `Y, beta, r` | `Y`, `beta`, `vec(Y .- beta)` | fixed 2-trait, 4-unit matrix | dense quadratic term | explicit matrix arithmetic |
| `Z_s` | sparse incidence matrices | shared and crossed two-level factors | row/source permutation invariance | same marginal model |
| `L_s` | direct rank-one loading matrices | bare rank-one `p=3` blocks | trait cross-covariances | explicit block covariance |
| `d_s` | optional unique variances | one positive and one zero coordinate | no automatic diagonal ridge | explicit block covariance |
| `sigma_eps` | scalar residual SD | fixed positive value | `pn log(2pi)` and determinant constants | independently assembled dense `V` |
| `K, h` | sparse random-factor precision | no fitted parameters | exact marginal NLL | dense small-fixture oracle |

## Boundaries

This contract accepts complete finite Gaussian data and fixed covariance inputs
only.  It does not fit parameters, estimate intervals, support missing data, or
wire formula/bridge/public APIs.  An incidence source may be shared or crossed;
this is a property of its rows and does not imply an accepted grouping label or
any broader grouping capability.

The factor kernel takes native `Float64` inputs for CHOLMOD's sparse solve and
rejects other scalar types rather than silently converting and losing parameter
derivatives.  It makes no automatic-differentiation or finite-difference claim:
future sparse-factor derivative support needs a separately specified and tested
CHOLMOD derivative contract.
