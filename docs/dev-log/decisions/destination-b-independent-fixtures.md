# Destination B independent deterministic fixtures

Date: 2026-09-07
Status: test oracle; not a fitted-model or capability claim

`test/fixtures/destination_b_reference.jl` is intentionally independent of the
Destination B builders.  It assembles small dense Gaussian covariance matrices
entry-by-entry from fixed labels and constants; it neither imports a grouped
kernel nor calls a precision-payload adapter, objective, optimiser, or fit.

The grouping fixture has eight deliberately re-ordered observations.  Its
`unit` labels are unequal (`g1` and `g3` occur three times, `g2` and `g4` once),
and `unit_obs` is the conjunction of the unit and observation labels.  The
single `crossedcluster` label set crosses the unit grouping.
`diagonalcluster2` deliberately repeats its labels.  Its covariance is
diagonal across *traits*, not observations: matching labels share a same-trait
effect across observations, while cross-trait covariance from this source is
zero.  This distinguishes it from an observation-residual term.

The corrected grouping fixture is two-trait and has exactly four sources:
`unit`, nested `unit_obs`, `crossedcluster`, and `diagonalcluster2`.  Its first
three natural trait covariance matrices are respectively
`[0.64 0.12; 0.12 0.49]`, `[0.36 -0.08; -0.08 0.25]`, and
`[0.25 0.05; 0.05 0.16]`; cluster2 variances are `[0.49, 0.31]`; the residual
variance is 0.21 for both traits.  These are natural-scale targets, not
log-standard-deviations or transformed optimiser coordinates.  The corrected
dense-Cholesky NLL is `15.477822651708259`.

The ancestor/precision fixture uses a complete known five-node covariance,
maps five observations to nodes `[3, 1, 3, 4, 2]`, and retains the repeated
node-3 mapping. Node 5 is retained in the precision/covariance but is not an
observation node, so it is an actual unobserved ancestor. Its trait-loading
rows are `[1.0, 0.2]` and `[-0.4, 0.7]`,
with natural phylogenetic scale 1.4 and residual SDs 0.3 and 0.5.  For response
matrix `Y` (`n_observation × n_trait`), both the response and covariance use
Julia's column-major `vec(Y)` order: index `(observation i, trait s)` is
`i + (s - 1) * n_observation`.  Thus the dense entry is
`scale * C[node_i,node_j] * dot(L[s,:], L[t,:]) + I(i=j,s=t) * residual_sd[s]^2`.
The corresponding fixed dense-Cholesky NLL is `8.771113846727065`.

The fixture API also provides seeded, independent Gaussian draws.  These are
for deterministic input/oracle checks only: no recovery campaign, fit, or
interval qualification is asserted here.

## Correction record

The initial scalar fixture (now replaced before cross-check qualification) was
invalid: it treated `cluster2` as an independent observation diagonal and its
four-node precision case observed every node. Its old grouping NLL,
`9.90255405355653`, is therefore not evidence and must not be compared with a
Destination B kernel. The current two-trait/four-source and five-node fixture
is a replacement specification, not a tolerance change or an adjustment to
match either builder.
