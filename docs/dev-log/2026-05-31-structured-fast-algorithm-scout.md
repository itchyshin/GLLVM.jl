# Structured Fast-Algorithm Scout: The 100x Lane

Date: 2026-05-31
Branch: `codex/non-gaussian-fitter-gradients`
Scope: planning memo after the non-Gaussian gradient slice and two public-source
scout passes. Only public sources are used here.

## Verdict

The current non-Gaussian gradient work makes ordinary dense-Laplace fitting much
faster, but the realistic 100x target is the structured path: phylogenetic,
animal-model, spatial, and crossed structured effects. The reason is simple:
`gllvmTMB` and `glmmTMB` are already fast TMB engines. To surprise people, GLLVM.jl
must do less linear algebra per likelihood evaluation, not only write faster
Julia around the same dense algebra.

The strongest next direction is:

1. move non-Gaussian structured fits into sparse precision / node / operator
   space;
2. warm-start and cache every inner Laplace mode and symbolic factorization;
3. profile nuisance blocks where the model gives a stable PIRLS-like solve;
4. add scalable determinant backends only after the exact small reference is
   verified.

This complements, rather than replaces, the design in
`docs/superpowers/specs/2026-05-31-nongaussian-structured-dependence-design.md`.
That spec gives the correct joint-Laplace / Schur-complement spine. This memo
sets the fast-algorithm priority inside that spine.

## Why 20x Is Good And 100x Needs Structure

The completed dense non-Gaussian gradient slice already reports:

- 21.5x and 26.8x Julia/R speedups on small Binomial and Poisson fits;
- 7.8x and 9.6x on medium Binomial and Poisson fits;
- 10.8x and 25.6x on large Binomial and Poisson fits;
- over 100x for the Poisson gradient itself against the original finite-difference
  gradient on a medium cell.

That is a meaningful win because the R comparator is not slow baseline code. It
is a mature TMB-backed implementation. The remaining path to 100x end-to-end is
not "more ForwardDiff"; it is changing the structured latent-field cost from
dense covariance algebra toward sparse or matrix-free precision algebra.

## Algorithm Shape

Introduce a structured Laplace operator abstraction around the Hessian block

```text
H(u, theta) = Q_struct(theta) + B' W(u, theta) B
```

where `Q_struct` is the structured latent precision and `B` maps latent nodes or
structured effects to observations. Backends should expose only the operations
the optimizer and Laplace correction need:

- `mul!(y, H, x)` for matrix-free Hessian-vector products;
- exact or approximate `ldiv!` for Newton / PCG steps;
- exact or approximate `logdet(H)`;
- selected inverse diagonals or stochastic trace probes for gradient trace terms;
- mode residual diagnostics so cached modes cannot silently go stale.

The first exact target should be the tree-node precision path, because
`src/node_gradient.jl` already proves the O(p) node-frame idea for the Gaussian
phylo-unique case. The structured non-Gaussian path should reuse the same
principle: do not materialise a dense species covariance when the model has a
sparse node precision.

## Ranked Lanes

### Lane A: Sparse Precision Joint Laplace

Build the Poisson-log structured prototype in the node frame:

```text
eta_ts = beta_t + (Lambda z_s)_t + u_t
u ~ N(0, sigma2 * Sigma_phy)
z_s ~ N(0, I_K)
```

Use the Schur-complement factorisation in the structured-dependence spec:
site-local `K x K` blocks for `z_s`, plus a species/node block for `u`. The
acceptance test is not a speed claim first. It is exact agreement with a dense
small-p reference and finite-difference gradient agreement before any large-p
benchmark.

Why this can be 100x: for tree / pedigree / SPDE precision matrices, the
structured solve can scale with sparse-factor or matrix-vector cost instead of
with a dense `p x p` covariance.

### Lane B: Warm Inner Modes And Symbolic Factor Reuse

The current dense path already has `Zcache` for canonical Binomial and Poisson.
Structured models need the same idea more aggressively:

- carry `z_s` modes across optimizer probes;
- carry `u` modes across optimizer probes;
- reuse sparse symbolic factorizations when the sparsity pattern is fixed;
- record inner Newton and PCG iteration counts in benchmarks.

This is likely the fastest low-risk bridge from 20x to larger end-to-end wins,
because optimizer-heavy non-Gaussian fits spend a lot of time rediscovering
nearby latent modes.

### Lane C: Profile Stable Nuisance Blocks

For canonical Poisson and Binomial, experiment with profiling or partially
profiling `beta` at fixed loadings / structured parameters via a PIRLS-like
solve, then finish with exact Laplace ML. This borrows the useful lesson from
lme4, MixedModels.jl, and TMB profiling, but keeps the final objective unchanged.

Acceptance criterion: fewer outer iterations and same final log-likelihood
surface, not merely a faster approximate estimator.

### Lane D: Kronecker And Kronecker-Sum Operators

For balanced crossed structures, use exact algebra:

```text
Q = Q_species kron I + I kron Q_site
```

or equivalent Kronecker-sum operators. This is a separate exact fast path for
phylogeny x site, species x latent axis, spatial x time, and later bipartite
structures. The non-Gaussian diagonal weight `W` breaks the clean eigensystem in
general, so the prototype should start with matrix-free `mul!` and exact small
reference checks before claiming determinant speedups.

### Lane E: SPDE / GMRF Spatial Backend

Dense Matérn covariance is the wrong large-p representation. For spatial models,
the scalable exact-ish direction is a sparse GMRF precision from an SPDE or CAR
construction. This is the spatial sibling of the tree-node idea: keep the latent
field in precision form and let the likelihood curvature enter as a diagonal or
local additive term.

### Lane F: Vecchia / NNGP Approximation

For dense spatial covariance or dense column/species covariance where no exact
sparse precision exists, Vecchia / nearest-neighbor Gaussian process
approximations are the plausible large-p path. This lane must be labelled as an
approximation from day one. Its tests should report both likelihood error against
the dense reference and speed.

### Lane G: Low-Rank Plus Sparse Precision

GLLVM.jl already has low-rank-plus-diagonal algebra in
`src/lowrank_cholesky.jl`. The natural next generalisation is
low-rank-plus-sparse-precision, combining global latent factors with local
structured residual dependence.

## Determinant Strategy

Use three determinant tiers:

1. exact dense determinant for tiny references and debugging;
2. exact sparse Cholesky determinant for tree / pedigree / SPDE cases where fill
   stays acceptable;
3. stochastic Lanczos / Hutchinson determinant for matrix-free large-p cases,
   with fixed probes per fit and explicit error diagnostics.

The stochastic tier should not be the first implementation. It should enter only
after the exact dense and exact sparse references exist, because otherwise
benchmark speed and approximation error become tangled.

## Public Source Anchors

- TMB / Laplace AD baseline: Kristensen et al. 2016, Journal of Statistical
  Software, <https://doi.org/10.18637/jss.v070.i05>.
- glmmTMB speed baseline: Brooks et al. 2017, The R Journal,
  <https://journal.r-project.org/articles/RJ-2017-066/index.html>.
- INLA latent-Gaussian perspective: Rue, Martino and Chopin 2009,
  <https://doi.org/10.1111/j.1467-9868.2008.00700.x>.
- SPDE sparse spatial precision: Lindgren, Rue and Lindstrom 2011,
  <https://doi.org/10.1111/j.1467-9868.2011.00777.x>.
- Stochastic Lanczos trace/logdet: Ubaru, Chen and Saad 2017,
  <https://doi.org/10.1137/16M1104974>.
- NNGP spatial approximation: Datta et al. 2016,
  <https://doi.org/10.1080/01621459.2015.1044091>.
- General Vecchia framework: Katzfuss and Guinness 2021,
  <https://doi.org/10.1214/19-STS755>.

## Slice Order

1. **S0: instrumentation.** Count inner mode iterations, PCG iterations,
   factorizations, objective calls, and logdet calls in the dense non-Gaussian
   benchmark harness.
2. **S1: exact dense structured Poisson reference.** One family, small `p`,
   dense `S_u`, finite-difference outer gradient, dense-reference equality.
3. **S2: tree-node sparse precision Poisson.** Same likelihood as S1, but with
   node-frame precision and exact sparse determinant where feasible.
4. **S3: cached mode / symbolic reuse.** Make warm starts the default for the
   structured prototype and prove fewer inner iterations without changing the
   optimum.
5. **S4: analytic/envelope gradient.** FD-check to at most 1e-6 against the
   structured marginal.
6. **S5: determinant alternatives.** Compare exact sparse Cholesky, SLQ, and
   dense fallback on the same fitted surfaces.
7. **S6: gllvmTMB / glmmTMB / sdmTMB benchmark table.** Use fixed simulated data,
   small/medium/large cells, and report any slower cell as a named bottleneck.

## Team Assignments

- Ada: choose when S1 is ready to become the structured-performance PR.
- Gauss: own Schur complement, sparse solves, determinant correctness.
- Noether: keep the joint objective, mode equation, and envelope gradient aligned.
- Karpinski: enforce type stability, allocation discipline, and operator APIs.
- Fisher: own FD checks, log-likelihood equality, and benchmark interpretation.
- Curie: add ADEMP recovery cells after S1/S2 are stable.
- Hopper: maintain the R comparator scripts without adding R dependencies to
  package tests.
- Florence: turn real benchmark output into the speedup figure.
- Grace: record exact package versions and CI portability notes.
- Rose: audit every speed claim against measured evidence and public provenance.
- Shannon: keep this lane out of `src/sparse_phy_grad.jl` and `src/em_phylo.jl`.

## Rose Guardrail

Do not claim 100x end-to-end until a structured benchmark proves it. The honest
claim today is:

```text
Dense non-Gaussian gradients are now much faster, with measured end-to-end
speedups up to 25.6x versus the R comparator on the tested cells; the 100x
target belongs to the structured precision / operator path and remains a named
research-engineering lane.
```
