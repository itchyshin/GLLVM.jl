# Frozen pedigree precision precursor

`precision-reference.json` was exported without fitting by
`tools/destination_b/pedigree_precision_reference.R` from the preserved private
gllvmTMB0.7.0 build at b4d5fee64def88bc768dda1f1f77c29b295edd86.
SHA256:c428e369e6fb554cc4b9bb03f250418d0d51474ba86e01d1be9c7c7301e615ee.

The fixed pedigree retains12individuals including4unobserved founders and
related-parent matings. The independent Julia fixture constructs each animal
as a sum of independent Mendelian innovations, rather than calling the R
relationship builder or inverting the transported precision. Test5526 passed
22assertions in3.6s, including actual multivariate marginal objective agreement
and negative controls for ancestor conditioning, map swaps and orientation.

An initial R equality check encountered determinant-factor cache metadata;
all matrix entries were exactly unchanged. Canonical sparse storage and labels
are now checked exactly, with no floating-point tolerance adjustment. Initial
Julia diagnostic-call namespace/orientation mistakes were retained in the
execution ledger and corrected from the documented low-level interface.

No fitted pairing, intervals, recovery or public bridge admission follows from
this precursor. See `../../decisions/destination-b-pedigree-alignment.md` for
the fixed model and remaining gates. Independent external review is pending
explicit transmission permission.
