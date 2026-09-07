# Phylo transport S3-ANIMAL — pedigree / sparse Ainv fixture (diagnostic only)

**status = diagnostic_only**

This receipt records a local Julia-side admission of a 12-individual
pedigree sparse `Ainv` as raw `PrecisionPhy` triplets, replayed against
the existing dense animal path (Henderson `A` / `relatedness_cov`).
It is **not a v0.true-parity claim**. It does not claim recovery,
coverage, or performance. NB2 A11 remains **partial**. The R `phylo_rr`
gate is not lifted.

## Pins

| Item | Value |
|---|---|
| Frozen oracle | gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86` (field meanings + pedigree example only) |
| Julia branch | `cursor/m3-phy-s3-animal-20260907` |
| Julia base | `origin/main` `5d1c9a6c` (#312 S3-FIT) |
| Fixture | `animal-keyword.R` examples, `i1`..`i12`, two founder pairs |
| Pedigree | founders `i1`–`i4`; progeny `i5`–`i12` of `(i1,i3)` and `(i2,i4)` |

No live 0.7.1 code, current R main, or R engine edit entered this receipt.
Henderson `A` and Quaas `Ainv` are assembled in the test only — not a
production pedigree parser.

This two-generation example has **F = 0** (unrelated founders). The
two-parent Mendelian branch still runs (`d_i = 0.5` for the eight
progeny). That is a property of the named R example, not a recovery
result.

## Payload (admitted)

| Field | Value |
|---|---|
| `n_leaves` | 12 |
| `n_aug` | 12 (tip-only animal; **not** tree `2p − 2 = 22`) |
| sparse nonzero count | 48 |
| `species_aug_id` (0-based wire) | `0:11` |
| `scale` | 1.0 |
| shipped `log_det` | 5.545177444479562 |
| recomputed `log_det` | 5.545177444479562 |
| checksum \|Δ\| | 0.0 (≤ 1e-8) |
| `Ainv A − I` residual | 0.0 |
| `max \|F\|` | 0.0 |

Field meanings follow frozen 0.7.0: `i,j,x` are 1-based `Ainv_phy_rr`
triplets. Admission now accepts `n_aug ≥ n_leaves` so a pedigree
precision can land without pretending to be a root-dropped tree.

## Matched-parameter replay vs dense Henderson A

Seed `20260907`; simulate from `σ²_phy A + σ²_eps I` at
`(1.2, 0.45, μ = 0.35)`. Existing animal helper
`relatedness_cov(A; jitter = 0)` returns `A`.

| `σ²_phy` | `σ²_eps` | `μ` | `nll` PrecisionPhy | `nll` dense A | abs Δ |
|---|---|---|---|---|---|
| 0.3 | 0.4 | 0.0 | 22.49981636019684 | 22.49981636019684 | 0.0 |
| 1.2 | 0.45 | 0.35 | 18.390458076449264 | 18.39045807644927 | 7.1e-15 |
| 2.5 | 0.8 | −0.2 | 20.015838128812337 | 20.015838128812337 | 0.0 |

All absolute/relative deltas ≤ 1e-8.

## Unphenotyped ancestors (full precision kept)

Drop founders `i1`,`i2` from the phenotype map (`n_leaves = 10`,
`n_aug = 12`). Replay versus the **marginal** block `A[tips,tips]`,
not a subset of `Ainv` (subsetting a precision would condition).

| `nll` PrecisionPhy | `nll` `A[tips,tips]` | abs Δ |
|---|---|---|
| 14.9054153901225 | 14.9054153901225 | 0.0 |

A deliberately subsetted 10×10 `Ainv` disagrees with that marginal
likelihood by more than `1e-4` (negative control in the test).

## Fit on the admitted payload

`fit_phylo_gaussian(::PrecisionPhy)` converges. This 12-individual
one-replicate draw collapses `σ²_eps` near the boundary
(`9.15e-7`). That is a small-sample property, **not** a recovery
result. Fitted `negll` still matches the dense-A nll at the same
parameters (abs Δ = 0 on the test). Interior matched-parameter nll
is the non-boundary oracle.

| Quantity | value |
|---|---|
| `μ` | 0.5221214902710599 |
| `σ²_phy` | 1.8155178558029699 |
| `σ²_eps` | 9.150351105081335e-7 |
| `negll` | 17.832956503867678 |
| `converged` | true |

`bridge_fit(; y, family="gaussian", phylo=payload)` returned the same
`negll` with `diagnostic_only = true`.

## Commands and exit status

Worktree: `~/local-scratch/lanes/GLLVM.jl-m3-phy-s3-animal-20260907`.

```text
~/.juliaup/bin/julialauncher --project=. -e 'using Test, GLLVM; include("test/test_phylo_precision_animal.jl")'
# exit 0; phylo transport S3-ANIMAL: pedigree Ainv fixture | 43 / 43

~/.juliaup/bin/julialauncher --project=. -e 'using Test, GLLVM; include("test/test_bridge_phylo_precision.jl")'
# exit 0; phylo transport S3a: Julia precision payload | 78 / 78

~/.juliaup/bin/julialauncher --project=. -e 'using Test, GLLVM; include("test/test_fit_phylo.jl"); include("test/test_phylo_precision.jl"); include("test/test_shard_selection.jl")'
# exit 0; 13+17 / 22 / 43
```

No Totoro/DRAC run. No R engine invocation.

## Scope fence

- No R `phylo_rr` S3b, no R cpp, no M2-R2, no NB2 A11 promotion.
- No production Henderson/Quaas parser in `src/`.
- status = diagnostic_only.
- not a v0.true-parity claim.
