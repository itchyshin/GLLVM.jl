# Destination B: multivariate precision consumer contract

**Status:** implementation contract for the first Julia-only kernel; not a
fitting route, interval result, or `phylo_rr` parity claim.

## Frozen object and coordinate system

The R-side adapter supplies a previously admitted `PrecisionPhy` payload:
`Q`, native **precision** `log_det = log|Q|`, `scale`, and the 1-based
`species_aug_id`.  `Q` is already the canonical root-dropped augmented
precision, including the R-side unit-height scaling when `scale != 1`.
This kernel never rebuilds a tree, inverts a supplied dense covariance, or
applies `scale` a second time.

The frozen R C++ normaliser's `log_det_A_phy_rr` is `log|Q^-1|`, hence it is
`-log|Q|`.  The bridge must make that sign conversion explicitly before it
constructs `PrecisionPhy`; direct unnegated transport is a rejected adapter
contract, not a kernel option.

For `m` response rows (which may repeat species), `d` traits, `a` augmented
nodes, and rank `r`, let `S` be the `m x a` selector encoded by
`species_id` followed by `species_aug_id`, let `L` be the `d x r` trait
loading matrix, let `U` be an optional nonnegative diagonal phylogenetic
variance, and let `psi` be positive independent observation residual
variances. The kernel input is the already residualized, zero-mean matrix
`z = y - mean`; it does not fit or remove means. Let `J = {t : U_t > 0}`
and `k = |J|`; exact zero entries are omitted rather than instantiated as
zero latent fields. The model is

```
[g_k; h_t] ~ N(0, sigma2_phy Q^-1),          k = 1,...,r; t in J
y_i | g,h ~ N(L g[node(species_id[i]), :] + Diagonal(sqrt(U))h[node(species_id[i]), :],
              Diagonal(psi)),                i = 1,...,m.
```

The phylogenetic trait covariance is `L L' + Diagonal(U)`; `U` is the
R-side `phylo_diag`/`Psi_phy` companion and shares the phylogenetic
precision, not the independent observation residual. The complete observed
covariance is `kron(L L' + Diagonal(U), A_leaf) +
kron(Diagonal(psi), I_m)` in Julia's trait-major `vec(Y)` ordering. The
positive `psi` term makes repeated-observation covariance nonsingular. `g`
and `h` retain all ancestors; they are marginalised in one sparse augmented
solve.

## Exact sparse marginal

With `E_J` the `d x k` trait-selection matrix, conceptually
`F = [L, E_J Diagonal(sqrt(U[J]))]` has `s = r + k` active fields.
Writing `P = I_s kron (Q / sigma2_phy)`, `R = Diagonal(psi) kron I_m`, and
`A = F kron S` in Julia's column-major `vec(z)` order, form only

```
H = P + A' R^-1 A,
b = A' R^-1 vec(z).
```

The returned log density is

```
-1/2 [ m*d*log(2*pi) + m*sum(log(psi)) - log|P| + log|H|
      + vec(z)'R^-1vec(z) - b'H^-1b ],
log|P| = s * (log_det - a*log(sigma2_phy)).
```

For numerical stability, the implementation evaluates the displayed Schur
quadratic through the posterior mode `u_hat = H^-1b`: its prior precision
quadratic plus its observation-residual precision quadratic.  This is
algebraically identical but avoids subtracting two very large, nearly equal
terms when the signal is large and `psi` is small.

`H` is assembled as a sparse block precision using only the mapped observed
nodes; its `L'L` low-rank block, `L`--unique cross blocks, and diagonal
unique blocks are added directly. No dense `F`, `Diagonal(sqrt(U))`, or
`F'R^-1F` is materialised. `cholesky(Symmetric(H))` both retains the
unobserved ancestors and marginalises them. A dense `m*d` covariance exists
only in the tiny independent test oracle.

## Cost boundary

The assembled sparse system has `a*s` rows, with `s = r + count(U > 0)`.
The implementation builds only the `r x r` low-rank information block,
`r x count(U > 0)` cross entries, and diagonal unique entries before sparse
assembly. It makes no performance claim: a later benchmark must record system
dimension, `nnz(H)`, Cholesky fill, allocations/memory, and elapsed time on
the intended sparse shapes before this kernel is described as scalable.

## Symbolic alignment

| Symbol | R/Julia transport | Kernel construction | Test oracle | Scope |
| --- | --- | --- | --- | --- |
| `Q, log|Q|, scale` | admitted `PrecisionPhy` (adapter negates R's covariance log-det) | `P`; stored precision `log_det`; scale is metadata already applied to `Q` | non-unit scale fixture, double-scale negative contrast | source, not re-derived |
| `species_id`, `species_aug_id` | response-row species then 1-based Julia node map | selector locations in `H` and `b` | retained-ancestor dense reference; swapped/duplicate map tests | repeated observations share one factor row |
| `g,h` | phylogenetic factor and active unique states | all `a*s`, `s=r+count(U>0)`, coordinates retained in `H` | marginal dense covariance | no optimiser |
| `L` | low-rank `phylo_rr` trait factor | leaf-local `F' Diagonal(psi)^-1 F` blocks | `L L'` phylogenetic covariance term | rank >= 1 |
| `U` | optional `phylo_diag` / `Psi_phy` companion | `F = [L Diagonal(sqrt(U))]` | `Diagonal(U)` phylogenetic covariance term | nonnegative; explicit zero permits low-rank-only |
| `psi` | Gaussian observation residual | `R^-1` and `m*sum(log psi)` | independent repeated-observation covariance term | strictly positive |
| `sigma2_phy` | scalar phylogenetic factor scale | `Q / sigma2_phy`, prior determinant | dense `A P^-1 A'` | strictly positive |

## Gates

The pure Julia test must compare the sparse result to a hand-built dense
reference only on a two-species/three-trait fixture with two retained
ancestors, a non-unit applied scale, and `r = 2`. It must reject a duplicate
node map and non-positive scale, retain a unique-only and partially-zero-`U`
case, and be invariant to joint trait or observation/species permutations.
Changing stored `log_det` by `delta` shifts the result by exactly
`s*delta/2`; this is checked both with `U = 0` and with active `U`. The
nonzero-mean fixture is passed only after explicit residualization. Treating
`scale` as an extra multiplier or swapping a valid map must disagree with the
frozen dense reference. Those are transport/kernel guards, not evidence that
the adapter, a fit, or the R model is admitted.

Source boundary: Destination B execution programme, 2026-09-07;
`gllvmTMB` 0.7.0 frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86`.
