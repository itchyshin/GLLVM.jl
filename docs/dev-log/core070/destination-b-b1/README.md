# Destination B, B1 — frozen R 0.7.0 unit-Gaussian receipt

This directory contains one reproducible, source-pinned reference receipt only.
Run `tools/destination_b/b1_unit_gaussian_reference.R --help` for the full
contract. The receipt script verifies the frozen source commit and DESCRIPTION
version before loading, and refuses to use an unmarked library build.

Scope: one deterministic `n_site = 4`, `n_replicate = 2`, `n_trait = 2`
Gaussian fit (eight observation cells) with
`latent(0 + trait | site, d = 1, unique = FALSE)`.  The runner archives the
exact frozen Git object on every invocation and, for an empty explicit library,
installs it with `R CMD INSTALL --preclean`; a pre-existing library is reused
only when its retained marker and installed shared-library hash match.  The
receipt records both archive and installed shared-library SHA-256 values.

Non-claims: Julia parity; recovery; interval validation; B1 qualification; and
public bridge admission.
