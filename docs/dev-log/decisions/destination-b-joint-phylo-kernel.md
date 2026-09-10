# Destination B joint phylogenetic plus ordinary Gaussian kernel

**Status:** evaluation-only internal kernel. It neither fits parameters nor
opens a public/bridge route, supplies a signal extractor, or qualifies recovery,
intervals, or coverage.

## Symbolic alignment

| Symbol | Kernel input / assembly | Fixed fixture oracle | Evaluation output |
| --- | --- | --- | --- |
| `y = vec(Y - mean)` | `residualizedY`, stacked observation-major by trait | `vec(response) - mean` | Gaussian log likelihood |
| `R = I_n kron Diagonal(psi)` | repeated diagonal residual precision | `residual_covariance` | normalizer and stable residual quadratic |
| `P_phy = I_k kron Q` | sparse phylogenetic prior from admitted `PrecisionPhy.Q` | `prior_precision` upper block | `k * phy.log_det` |
| `A_phy` | sparse rows directly assembled from field/node coordinates to observation/trait rows | `A_phy` | shared repeated-species fields |
| `P_group = I` | sparse identity over grouped coordinates | `prior_precision` lower block | no prior log-determinant term |
| `W_s = Z_s kron Diagonal(sqrt(v_s))` | existing `grouped_trait_design` for each independent source | `W_group` | ordinary crossed-group contribution |
| `J = P + A'R^-1A` | one sparse joint CHOLMOD precision | augmented fixture construction | log determinant and posterior mode |

The exact target is

```
ell = -1/2 { np log(2pi) + logdet(R) - logdet(P) + logdet(J) + q },
q = (y - A m)'R^-1(y - A m) + m'P m,  m = J^-1 A'R^-1 y.
```

`Q` already includes its admitted scale. The kernel therefore uses
`k * phy.log_det` exactly once and never rescales `Q` by `phy.scale`. Positive
entries of `U_phy` add fields; zero entries add neither field nor determinant
multiplier. Ordinary sources are deliberately restricted to supplied
independent trait variances; covariance-factor parameterisation and fitting
are outside this slice.

## Diagnostics and limits

The evaluator fails closed for malformed phylogenetic maps, dimensions,
non-finite values, non-positive residual or ordinary variances, and a
non-positive-definite joint precision. It does not make an identification
claim: covariance-basis aliasing affects fitting and inference, whereas a
fixed parameter covariance still defines this evaluation kernel.

The determinant, scale, and map sensitivity checks deliberately construct raw
`PrecisionPhy` values with altered fields. They demonstrate the evaluator's
determinant transport and map consumption; they are not successful payload
validation. Canonical payload admission remains the separate
`admit_phylo_precision_payload` contract.

The focused fixed-parameter fixture is estimated below one minute. It checks
the predeclared dense NLL anchor `8.59559088480814`, map/determinant/scale
transport, no-group reduction to the existing phylogenetic kernel, zero and
partially active `U` field accounting, and one or two shared ordinary-group
prior sources.
