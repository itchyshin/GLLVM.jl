# Destination B precision-fit admission

## Decision

`PrecisionPhy` remains a permissive raw/diagnostic container, but each
public precision-fitting boundary will validate it once through
`_validate_precision_fit_input` and use the returned owned snapshot. The
validator checks `n_aug`/`n_leaves` and sparse-Q shape, 1-based unique tip
map, non-empty aligned labels, finite entries and metadata, positive scale,
explicit sparse symmetry, sparse positive definiteness, and the independent
`logdet(Q)` checksum using the existing `1e-8` transport tolerance.

Sparse symmetry is checked before wrapping Q in `Symmetric`; this prevents a
single supplied triangle from disguising an asymmetric input. Q itself—not a
later residual-augmented joint precision—must be positive definite, so a
well-conditioned augmented system cannot conceal an invalid phylogenetic
prior.

## Non-actions

The snapshot copies Q, map, and labels. It does not invert Q, build a dense
global covariance, or reapply `scale`: scale is positive checked metadata
whose effect is already present in the canonical Q. The raw constructor and
kernel diagnostics remain permissive for their existing structural tests.

## Tests

The admission test retains a non-unit-height tree and a three-individual
pedigree-style inverse-relationship bundle, and rejects wrong checksums,
asymmetric sparse Q, an indefinite Q even when a toy augmented system is PD,
maps, labels, scale, non-finite entries, and direct Q/metadata shape mismatch.
It establishes fitting-boundary input safety only; it does not admit an R
route, establish likelihood parity, or alter model parameterization.
