# Destination B: joint Gaussian phylogeny and ordinary grouping contract

**Status:** implementation preparation only. This records the exact
Gaussian target and an independent dense oracle for a future internal joint
consumer. It adds no source implementation, public API, bridge admission,
fit result, recovery result, or non-Gaussian capability.

## Scope and ordering

Let `Y` be `p x n` (traits by observations) and define `y = vec(Y)` in Julia
column-major order: for observation `i`, trait entries `1:p` are consecutive.
Thus the observation-residual covariance is

```
R = I_n kron Psi,       Psi = Diagonal(psi),       psi_t > 0.
```

The current `PrecisionMultivariateFit` interface accepts this `p x n` form,
then transposes only at its sparse-kernel boundary
(`src/precision_multivariate_fit.jl:62-88`). The joint contract retains the
native ordering above, rather than silently borrowing the grouped kernel's
internal vector order. `D` is consequently an `n*p x q` complete mean design
in the same order, and the exact model is

```
y = D beta + A_phy f + W_group b + e,
e ~ N(0, R),
[f; b] ~ N(0, blockdiag(I_k kron Q^-1, I_m)).
```

Here `Q` is the admitted `PrecisionPhy.Q`, `k` is the number of active
phylogenetic fields, and `m` is the total ordinary grouped-effect dimension.
Equivalently, the latent prior precision is

```
P = blockdiag(I_k kron Q, I_m).
```

This is the requested `blockdiag(I_fields kron Q, I)` form. The first joint
slice fixes `sigma2_phy = 1`, as does the current multivariate fitter; a free
phylogenetic overall scale must not be added alongside free loadings or
phylogenetic unique variances.

## Phylogenetic block

For `a = phy.n_aug`, let `S_phy` be the `n x a` selection matrix with

```
S_phy[i, phy.species_aug_id[species_id[i]]] = 1.
```

`species_id` is observation-to-tip, while `species_aug_id` is the admitted
unique tip-to-augmented-node map. Repeated observations therefore repeat the
same row of `S_phy`; unobserved ancestors remain in `Q` and in every field of
`f`, rather than disappearing from the prior.

Let `L` be `p x r`, `U_phy` be a nonnegative length-`p` vector, and form

```
F = [L  Diagonal(sqrt(U_phy[active]))],
k = r + count(U_phy_t > 0).
```

The low-rank and unique phylogenetic columns both share the same augmented
`Q`. Let `K_(n,p)` map `vec(Y')` to `vec(Y)`; then, with field-major,
node-within-field `f`,

```
A_phy = K_(n,p) * (F kron S_phy).
```

This explicitly resolves the otherwise easy-to-miss ordering mismatch:
`I_k kron Q` indexes field blocks with augmented nodes inside each block,
whereas `vec(Y)` is observation blocks with traits inside each block. The
equivalent observed covariance is

```
V_phy = (S_phy * Q^-1 * S_phy') kron (L*L' + Diagonal(U_phy)).
```

`U_phy` is **not** `psi`: it is a phylogenetically correlated trait-specific
source and remains in `A_phy f`. `psi` is independent observation residual
noise and remains in `R`. Zero `U_phy` entries create no field, just as in
`src/precision_multivariate.jl:90-95`; they must not change the phylogenetic
stored-logdet multiplier.

## Ordinary independent grouped blocks

For every ordinary source `s`, existing `GroupingTerm` selection is restricted
to `mode=:indep, common=false`. Let `Z_s` be its `n x g_s` sparse incidence
and `v_s = exp.(2 .* eta_s)` be its trait-specific natural variances. Define

```
b_s ~ N(0, I_(g_s*p)),
W_s = Z_s kron Diagonal(sqrt(v_s)),
W_group = [W_1 ... W_S],
m = sum_s g_s*p.
```

The `b_s` order is group-within-source, then trait; it gives

```
V_group = sum_s (Z_s * Z_s') kron Diagonal(v_s).
```

This is the same independent trait covariance represented by
`_grouped_term_unpack` in `src/grouped_fit.jl:125-165`, but it cannot be
evaluated by the existing grouped-only likelihood after a phylogenetic term is
added. The future joint assembler, not either existing standalone kernel, owns
the horizontal concatenation and one joint marginalization.

Combining the blocks gives the only target covariance for this slice:

```
V = V_phy + V_group + R
  = A * P^-1 * A' + R,       A = [A_phy W_group].
```

For a complete Gaussian response, the exact marginal likelihood may be
evaluated from the augmented precision `J = P + A'R^-1A` as

```
ell = -1/2 { n*p*log(2pi) + logdet(R) - logdet(P) + logdet(J)
             + (y-D beta)' V^-1 (y-D beta) }.
```

Production must evaluate the quadratic in a posterior-mode-stable form, as
the current phylogenetic and grouped kernels do; the dense `V` expression is
only the independent small-fixture oracle.

## Scale and determinant transport

`PrecisionPhy.Q` already contains its applied `scale`; the joint assembler
must not multiply or divide by `phy.scale` again. With fixed
`sigma2_phy = 1`, its phylogenetic prior contribution is

```
logdet(P_phy) = k * phy.log_det,
```

where `phy.log_det = logdet(Q)`. The canonical R payload names
`log_det_A_phy_rr` for the covariance determinant, so the adapter boundary
must use `phy.log_det = -log_det_A_phy_rr`; this contract never transports the
unnegated R value. The independent ordinary `b` prior has log determinant
zero. A future free `sigma2_phy` extension would require
`k * (phy.log_det - a*log(sigma2_phy))`, but it is expressly outside this
fixed-scale slice.

## Existing ownership and admission boundary

| Concern | Current owner | Future joint responsibility |
| --- | --- | --- |
| Admitted `Q`, tip map, scale and `logdet(Q)` | `src/phylo_precision.jl` | consume unchanged; no inversion or tree rebuilding |
| Sparse phylogenetic fields, `L`, `U_phy`, `psi`, ancestors | `src/precision_multivariate.jl` | retain all augmented nodes and reuse its field semantics |
| Complete mean layout and fixed-scale multivariate packing | `src/precision_multivariate_fit.jl` | preserve its `p x n` input and complete mean design |
| `GroupingTerm`, incidence construction, independent `v_s` packing | `src/grouped_fit.jl` | accept only explicit independent ordinary sources in this first joint slice |
| Dense oracle | `test/fixtures/destination_b_joint_phylo_grouping.jl` | test-only; never route production through dense `V` |

No existing file currently combines these sources. A future internal joint
Gaussian implementation needs a new coordinator and dedicated tests; it must
not change the standalone phylogenetic or grouped model meaning by stealth.
The bridge remains diagnostic-only, the public R `phylo_rr` admission remains
closed, and the R phylogenetic signal estimand remains unadmitted.

## Identification and inference limits

The covariance components must be distinguished before fitting. In particular,
for each trait pair the phylogenetic basis
`S_phy*Q^-1*S_phy'` can be aliased or nearly aliased with an ordinary
`Z_s*Z_s'`; repeated tip observations make that risk especially concrete. An
ordinary identity incidence can also overlap an observation-residual basis.
The fixed mean `D` can be rank deficient independently of covariance
identification. Finally, reduced-rank `L` has its usual rotation and
loading/unique trade-offs; a latent-plus-unique target is not made identifiable
merely by including another grouped source.

Accordingly, evaluation must fail closed on invalid maps, nonpositive `psi`,
and malformed incidence dimensions. A fixed-parameter covariance remains
well-defined even when its components are aliased; the future fitter and
inference admission must diagnose covariance-basis aliasing rather than claim
separately identified components. It must report sources separately: phylogenetic `U_phy`,
ordinary grouped `v_s`, and observation residual `psi` must never be folded
into one variance or signal summary. This contract does not define an R-style
signal extractor, a profile interval, a coverage guarantee, or a non-Gaussian
joint Laplace model.

## Independent reference fixture

`test/fixtures/destination_b_joint_phylo_grouping.jl` supplies a deterministic
two-trait, five-observation dense oracle. It has a four-node precision with two
retained but directly unobserved ancestors, a two-tip map, repeated tip
observations, rank-one `L`, explicit positive `U_phy`, trait-specific positive
`psi`, and one three-level crossed ordinary group. It returns both the direct
covariance expression and the equivalent augmented-precision construction,
plus the exact dense Gaussian NLL. Future tests must require those two
covariances and their NLLs to agree before comparing a sparse joint consumer.

The fixture check is a fixed 10-by-10 Cholesky calculation, estimated below
one minute. It is a structural oracle, not a fit, recovery, or qualification
run.
