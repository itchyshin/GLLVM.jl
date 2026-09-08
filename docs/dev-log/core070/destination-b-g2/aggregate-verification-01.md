# Destination B G2 aggregate verification — 2026-09-07

## Scope

This is the current-head, bounded G2 receipt for four named grouping sources:
`unit`, `unit_obs`, `cluster`, and `cluster2`.  It verifies that they enter one
joint likelihood through the public Julia `fit_gllvm` route for Gaussian,
Poisson-log, Binomial-logit, Beta-logit, and NB2-log.

It is not a frozen-R comparison, a phylogenetic-formula admission, a recovery
or coverage campaign, a full-suite result, or a Destination B completion
claim.

## Identity and environment

| field | value |
| --- | --- |
| GLLVM.jl HEAD | `cc8b95b0` |
| working directory | `/private/tmp/destination-b-20260907-main` |
| Julia | `/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia` |
| test environment | `/private/tmp/destination-b-quality-g8dtHV` |
| numerical threads | `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=1` |
| fixed random source | direct `StableRNGs` dependency in the isolated test environment |

## Command and result

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  /Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia \
  --startup-file=no --project=/private/tmp/destination-b-quality-g8dtHV -e \
  'include("test/test_destination_b_joint_identification.jl"); include("test/test_destination_b_joint_poisson.jl"); include("test/test_destination_b_joint_other_families.jl"); include("test/test_destination_b_joint_nb2_replication.jl"); println("DESTINATION_B_G2_PASS")'
```

Exit status: `0`.

| route / fixture | assertions | elapsed |
| --- | ---: | ---: |
| Gaussian four-term identification | 63/63 | 12.3 s |
| Poisson-log four-source public fit | 46/46 | 4.8 s |
| Binomial-logit four-source public fit | 58/58 | 2.3 s |
| Beta-logit four-source public fit | 63/63 | 3.7 s |
| NB2-log four-source small fixture | 55/55 | 2.4 s |
| NB2-log four-source replicated fixture (`n=384`) | 61/61 | 2.0 s |

The focused set totals 346 passing assertions and prints
`DESTINATION_B_G2_PASS`.  The Gaussian fixture retains a
structural rank-one-plus-unique nonidentification warning and records its
unavailable intervals.  The n=96 NB2 fixture retains `:partial` intervals,
including explicitly unavailable near-boundary source targets.  The larger
NB2 fixture provides the separate interior information diagnostic; it does not
erase the smaller fixture.

## Adjacent mathematical anchor

The separate current-head command

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  /Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia \
  --startup-file=no --project=/private/tmp/destination-b-quality-g8dtHV -e \
  'include("test/test_destination_b_quadrature.jl"); println("DESTINATION_B_FOUR_FAMILY_QUADRATURE_PASS")'
```

exited `0`: 36/36 scalar quadrature anchor assertions in 3.9 seconds, followed
by `DESTINATION_B_FOUR_FAMILY_QUADRATURE_PASS`.  It independently anchors the
fixed-parameter Laplace kernels; it is not used as an R-parity substitute.

## Independent review

A fresh Sol review found no P0/P1 G2 blocker at `cc8b95b0`.  It verified that
all selected sources are assembled into one joint design/objective, that the
five named routes are bounded at public dispatch, and that the two deliberate
identification/boundary failures remain asserted.  It also confirmed that the
earlier marker-validation, saturation-status, and terminal-gradient defects
have current-source repairs.

## Boundary

G2 is checked only for the named grouping engine/interface scope above.  G3
(multivariate phylogeny and scoped R adapter paired evidence), G4 (broader
interval feasibility), G5 (recovery), G6 (final public/full regression), G7
(final independent reviews), and G8 (programme reconciliation) remain open.
