# Destination B frozen-R Gaussian phylogenetic reference schema

## Purpose and boundary

`tools/destination_b/phylo_gaussian_reference.R` is a deterministic export
runner for one small frozen-R Gaussian cell: three traits, eight species,
two repeated observations per species, rank-one loadings-only phylogenetic
latent effect, and one shared observation residual SD. It is a paired
cross-evaluation input, not a fit qualification, bridge admission, or R engine edit.

The runner takes the private R library and an output directory as its two
positional arguments. It refuses to load a globally installed package, requires
gllvmTMB 0.7.0, requires the DLL path to lie under the supplied library, and
checks its SHA256 against the externally retained frozen-build receipt. The
source pin is recorded as
`b4d5fee64def88bc768dda1f1f77c29b295edd86`; version alone is insufficient
provenance. `sessionInfo()`, package path, library path, DLL path, and DLL hash
are emitted in JSON.

An optional final `--preflight-only` flag performs only namespace, version,
private-DLL-path, and DLL-hash validation; it never reaches tree construction
or fitting. A regular run refuses an output directory that already contains a
receipt or attempt record. Before fitting, it creates a text attempt log; on a
fit error it persists warnings and the error, and immediately after a returned
fit it saves the raw TMB data/maps/parameters and `fit$opt` before later
assertions. Thus a non-converged or later-rejected attempt remains inspectable.

## JSON contract

The schema version is `destination-b-phylo-gaussian-marginal-1`.

- `fixture` records seed, tree, names, tip order, species-then-replicate
  observation order, and every original long-format row's trait/observation
  matrix coordinates.
- `response.Y_traits_by_observations` is nested trait rows by observation
  columns. `response.data_sha256` hashes `as.double(c(Y))` as Float64,
  little-endian, column-major bytes; the exact encoding string is retained.
  JSON uses `digits=17`, followed by exact matrix/hash readback before atomic
  publication. A pre-fit probe showed that `digits=NA` changed the bits of
  `1/3` and `pi`; the hash check must not be weakened to accommodate that loss.
- `source_covariance` retains raw tip correlation `A_original`, ridged A,
  ridge operation/value, and both symmetric condition numbers.
- `precision` contains canonical `Q` read from
  `fit$tmb_data$Ainv_phy_rr`, node labels, zero-based tip and observation maps,
  and the explicit sign transport `log_det_Q = -log_det_A_phy_rr`. Scale is
  metadata only and is not reapplied by the consumer.
- `precision.engine_long_to_original_long_row_one_based` is the measured
  TMB-long-row permutation. The runner matches engine `y`, `trait_id`, and
  `species_id` against every original data row and refuses ambiguity rather
  than assuming the input ordering survived unchanged.
- `matched_theta` contains exactly `b_fix[3]`, `log_sigma_eps[1]`, and
  `theta_rr_phy[3]`, together with the **marginal**
  `fit$tmb_obj$fn(theta)`. No score vector is present because the Gaussian
  phylogenetic scores are integrated.
- `fitted_r` separately records optimizer parameters, its marginal objective,
  convergence/message/counts, available gradient, elapsed time, and every
  emitted warning. It is retained even when convergence is imperfect.
  Missing values use explicit JSON null, not an empty object. Attempt01's
  incorrect NULL encoding remains retained alongside the corrected attempt02;
  their numerical results are identical.

The runner asserts no ordinary latent, unique-variance, phylogenetic-score,
dispersion, or hidden phi block is active. It also verifies the canonical
engine Q equals `solve(A_original + 1e-8 I)` for this legacy dense-vcv cell.
It never reconstructs the historical `MakeADFun(random = NULL)` joint score.

## Consumer expectations

A Julia consumer must read the canonical Q and maps from the receipt, not
invert the retained A or reapply scale. It must preserve traits-by-observations
orientation and use the explicit long-row mapping. The matching Julia cell is
shared residual mode; the existing per-trait residual default is a different
model and cannot by itself qualify this reference.

The companion `compare_phylo_gaussian_reference.jl` checks exact schema keys,
the supplied frozen DLL hash, lossless response bytes, long-row/map bijections,
the original/ridged covariance and condition numbers, canonical precision and
determinant, active parameter blocks, and both marginal objective values.
Its dense-vcv scope requires n_aug=n_tips, canonical tip order and scale1; it
does not imply that ancestor-augmented pedigree or differently scaled tree
receipts have passed this schema. Validation checks A_ridged*Q=I without a
second inversion or rescaling. Absolute NLL tolerance remains1e-6.

Receipts record hashes of the input, DLL, checker and loaded fitting/admission
sources, and explicitly mark independent_julia_fit=false. Existing receipt
paths are refused. Synthetic adversarial tests are registered in the package
test runner; JSON3 is a test-only dependency. The actual first comparison and
both R attempts are retained under `docs/dev-log/core070/destination-b-s3b-pilot/`.
