# Destination B — source-attested tree own-optimum alignment

**Status:** implementation contract for one private, tree-only diagnostic.  It
does not qualify A4/S4, open the R `phylo_rr` route, compute intervals, or
assert parity at independently obtained optima.

## Purpose

The retained `raw-frozen-r-02.rds` record is a source-attested, declared-point
R marginal-objective record.  It deliberately does not retain an R optimiser
result.  Its fixed-coordinate Julia cross-evaluation is therefore a transport
identity check, not an own-optimum comparison.  This slice adds two *separate*
own-optimum diagnostics on the same immutable tree input:

1. an R-only source-attested diagnostic, and
2. a native Julia-only diagnostic.

Neither runner may start from the other engine's parameters or label a result
as paired evidence.  The R-only receipt records no Julia result; the Julia-only
receipt records `r_own_optimum_status = "unavailable"` rather than fabricating
one.

## Symbolic contract

For trait \(t=1,2,3\) and observation \(i=1,\ldots,16\), the tree row uses

\[
y_{ti} \sim N(\eta_{ti},\sigma_\epsilon^2), \qquad
\eta_{ti}=\beta_t+\lambda_t g_{a(i)}, \qquad
g\sim N(0,Q^{-1}).
\]

Here \(a(i)\) maps the repeated 16-observation species labels to the 14-node
augmented tree system.  The tree precision \(Q\) already carries scale 4;
there is no second scaling or inversion.  The latent rank is one,
`mode = :barelowrank`, `residual_mode = :shared`, and
\(\sigma^2_{phy}=1\).  All 14 augmented nodes remain in the precision system,
so internal nodes are marginalised by the model rather than discarded.

## Alignment table

| Symbol / fact | Frozen R construction | Native Julia construction | Immutable binding | Evidence retained | Not asserted |
| --- | --- | --- | --- | --- | --- |
| \(Y\) | three traits by 16 observations | same decoded response matrix | response SHA `a096e8a4…197373c2` | input identity | simulation recovery |
| \(\beta\) | `0 + trait` | default trait-intercept initialisation | three-coordinate order | optimiser output | signed cross-engine equality |
| \(\lambda\) | `phylo_latent(..., d = 1, unique = FALSE)` | `phylo_rank=1`, `phylo_mode=:barelowrank` | rank one; three loadings | optimiser output | loading sign equality |
| \(g\) | TMB random block `g_phy` | `PrecisionPhy` sparse system | 14 nodes, repeated map | marginal objective | conditional/joint objective substitution |
| \(Q\) | inherited canonical tree precision | admitted unchanged precision payload | scale 4; log determinant `15.706819081565975`; no ridge | map/precision diagnostics | a second rescale |
| \(\sigma_\epsilon\) | Gaussian residual scale | shared residual scale | one scalar log-SD coordinate | optimiser output | interval feasibility |
| R optimum | `gllvmTMB(..., engine = "tmb")`, own default start | not used as input by Julia | source pin/build/DLL chain | R-only receipt | paired parity |
| Julia optimum | not used as input by R | `fit_gllvm(...; phylo=PrecisionPhy(...))`, own default start | source-attested raw lineage plus Julia source hashes | Julia-only receipt | R optimum comparison |

R's declared coordinate order is
`[b_fix[1:3], log_sigma_eps, theta_rr_phy[1:3]]`; Julia's is
`[beta[1:3], lambda[1:3], log_sd_residual_shared]`.  The fixed-point
permutation is documented only for its separate matched-point check.  It is
forbidden as an own-optimum start or as a signed-loading comparison.

## Required source and input identity

- frozen gllvmTMB source pin:
  `b4d5fee64def88bc768dda1f1f77c29b295edd86`;
- fresh R build receipt SHA:
  `ecb2bf37e4bc5ec4cbe60be777f9e46c4b7812387ee381e71077609872254b8a`;
- actual loaded R DLL SHA:
  `5d8a9c43b725911452716d4462e655a974c06274925bdee0f1b0c9abec399fe1`;
- raw lineage RDS SHA:
  `63c087dad7c4d3cdcaffa349d732fbee721c25e69abd2ca2f1db5d0a349fe599`;
- fixture, tree reference, and precision-source SHA values:
  `089f87d0…bf097549`, `08c2c0f8…4ddf4bd7`, and
  `ab01ee47…a0429170` respectively;
- repeated `species_id = rep(1:8, each = 2)`, augmented tip map
  `[13,6,11,8,12,7,10,9]` (zero based), 14 augmented nodes, and no ridge.

The older legacy tree receipt and its historic DLL hash are not valid evidence
for this source-attested slice.

## Diagnostic gates

Each independently fitted engine must retain its own finite marginal NLL,
converged optimiser status, gradient norm at most \(10^{-5}\), a positive
definite observed marginal curvature object, and a finite positive minimum
Hessian eigenvalue.  It must also show that a direct objective re-evaluation
agrees with the retained optimum objective.

There is deliberately **no** tolerance for a difference between R's and
Julia's independently obtained optima.  Such a tolerance has not been
predeclared, and rank-one loading signs are indeterminate.  A future paired
evidence decision would need both own-optimum records plus its own separately
approved comparison contract.

## Receipt boundary and sizing

Both receipt schemas are permanently labelled
`*_own_optimum_unqualified`, `qualified = false`, and
`public_formula_admission = "closed"`.  They contain no interval, recovery,
coverage, public formula, or dense/pedigree conclusion.

Before the first live optimum run, execute a five-iteration tree-only sizing
cell with one BLAS thread, no `sdreport`/interval calculation, and a 300-second
supervisor.  Retain stage timing and failure output.  Estimate the full
single-run cost from that result; if it exceeds 30 minutes or reaches the cap,
stop and obtain separate approval before a full run or compute routing.
