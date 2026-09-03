# Gaussian covariance modes: numerical reference contract

Subsequent native fitted evidence: [ordinary fixed residual](source-fixed-residual-contract.md)
and [remaining seven mode shapes](covariance-mode-fits-contract.md). The report
below remains the original fixed-parameter qualification, with its original data.

The frozen R reference b4d5fee64def88bc768dda1f1f77c29b295edd86 admits all nine
prepared models below. Eighteen fixed-parameter marginal likelihood and gradient
checks pass against an independent dense Gaussian calculation. This closes a
reference-model specification gap, not Julia fitted-mode parity. Full manifest
remains DRAFT_NOT_FROZEN. Evidence: [retained results](covariance-modes-evidence.json).

For observed rows o,v with trait t and source group g:

```
V[o,v] = sigma_eps^2 * I[o=v] + C_effective[g[o],g[v]] * U[t[o],t[v]].
U_indep = diag(s_1^2,s_2^2,s_3^2)
U_common = s^2 I_3
U_dep = L L'
```

A common variance does not create cross-trait covariance. A deliberately wrong
shared draw, U=s²11', fails all six common-mode point checks. A shifted fixed
mean also fails equality at every point. Gaussian normalization constants are
included. Raw L packs the three diagonal entries first, then below-diagonal
entries column by column, without exponentiating the diagonal.

| Stable case ID | Free covariance coordinates | R parameterization | Residual scale | Random block |
|---|---:|---|---|---|
| MODE-ORD-INDEP | 3 | log SD per trait | fixed near zero | s_B |
| MODE-ORD-COMMON | 1 | tied log SD | fixed near zero | s_B |
| MODE-ORD-DEP | 6 | raw lower-triangular L | free | z_B |
| MODE-ANIMAL-INDEP | 3 | raw diagonal loadings, off-diagonals fixed zero | free | g_phy |
| MODE-ANIMAL-COMMON | 1 | log variance | free | p_phy |
| MODE-ANIMAL-DEP | 6 | raw lower-triangular L | free | g_phy |
| MODE-KERNEL-INDEP | 3 | raw diagonal loadings, off-diagonals fixed zero | free | g_phy |
| MODE-KERNEL-COMMON | 1 | tied raw diagonal loadings | free | g_phy |
| MODE-KERNEL-DEP | 6 | raw lower-triangular L | free | g_phy |

Every case includes three free fixed trait means. The actual R calls are frozen
in test/parity/fixtures/core070_covariance_modes.R; they use Gaussian responses,
0+trait fixed effects, ordinary site grouping or animal/kernel species grouping.
All models see the same deterministic data: 18 sites, three traits, six repeated
structured-source groups. This is not a random recovery fixture. Animal and
kernel paths share the same nonidentity matrix; their agreement checks two
admission paths, not two independent covariance challenges.

For dense A/K inputs the frozen preparation adds 1e-8 to the input diagonal
before inversion: effective C = (0.7I+0.3J)+1e-8I. This is asserted at the original
1e-12 matrix tolerance and included in the likelihood; it is not hidden by a
larger tolerance. Relevant executed branches are R/fit-multi.R:3860–3865 and
3963–3966. This result does not extend to sparse Ainv, pedigree or augmented-tree
preprocessing, which take different branches. The first point run stopped at
this distinction after six ordinary points; its process exit1 remains required
history. The corrected run changed the adapter assertion, not the model,
points, numerical tolerance or frozen source.

Ordinary per-row diagonal effects suppress Gaussian residual scale to
max(0.001*sd(y),1e-6), preserving that fixed value exactly. See frozen
R/fit-multi.R:5611–5648. ORD-DEP does not suppress it: a continuum of U and sigma²
can produce the same U+sigma²I in this observation-level fixture. Therefore its
pointwise PASS is not evidence of separate variance identification. Likewise,
column-sign flips leave LL' invariant; only positive-diagonal points were tested.
A future Julia adapter must preserve and diagnose the contract rather than
silently substituting an identifiable but different model.

## What this binds and what remains

The nine IDs now have exact R calls, fixed coordinates, source/trait/group order,
parameter transforms, residual maps, objective constants and acceptance rules.
They refine the ordinary/animal/kernel mode facts in covariance-admission-subset.
Native fitted functions, formula covariance terms and public R-bridge mappings
remain UNIMPLEMENTED_OR_UNQUALIFIED for these exact contracts. The internal
Gaussian source evaluator currently accepts only one/two rank-one sources; it
must not be relabelled as these full-rank or independent modes. A native adapter
must not conflate log variance, log SD and raw signed loadings.

Still required: other ranks, source scales/orderings, sparse Ainv/trees/pedigrees,
spatial models, unique companions, slopes, masks, known covariance, non-Gaussian
crossings, fitting/postfit/inference, recovery and all public interfaces. No
optimizer ran, no production Julia or frozen R source changed, and no full
obligation or parity cell is promoted. Noether's bounded review supports the
pointwise calculation and these qualifications; it is not programme sign-off.
