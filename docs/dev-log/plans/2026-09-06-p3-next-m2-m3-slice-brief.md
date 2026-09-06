# P3 next bounded M2/M3 slice — Julia phylo payload admission

**Date:** 2026-09-06  
**Programme:** `v0.true-parity` against frozen gllvmTMB 0.7.0  
**Parent plan:** `docs/dev-log/plans/2026-09-06-ultra-plan-true-parity-remainder.md`  
**References:** merged #291; draft #303; remainder #309 at `c422374c`; G0 on
#308, all nine answers **YES**.

## Decision

The exact next slice is **M3-PHY-S3a: Julia-side phylogenetic precision-payload
admission**. It is a small M2/M3 boundary slice: it prepares the native Julia
bridge payload needed for the phylo/animal/kernel transport path, without
starting matched-coordinate M2-R2.

The slice must:

1. accept and validate the already-canonical R-convention sparse precision
   bundle represented by `PrecisionPhy`;
2. expose a Julia-side bridge descriptor/payload containing sparse triplets,
   `n_aug`, tip map, node labels, `scale`, and the shipped log-determinant;
3. verify the independent log-determinant checksum and reject malformed
   dimensions, indices, tip maps, or non-finite values;
4. replay the payload through the existing sparse-phylo likelihood and compare
   it with the existing `AugmentedPhy` fixture at matched parameters.

This is **not** M2-R2, not a new estimand, and not a public parity claim.
The R-side `phylo_rr` gate lift and any gllvmTMB engine edit remain a later,
separately authorised slice. Kernel-specific `cross_kernel_rho` behaviour is
also out of scope; #291’s S3b split remains in force.

## Owned paths

The implementation lane may own only these GLLVM.jl paths after confirming
leases:

- `src/bridge.jl` — Julia descriptor/payload assembly and validation.
- `src/phylo_precision.jl` — only the minimal constructor/checker changes
  required by the payload contract; preserve the existing S1/S2 behaviour.
- `test/test_bridge_phylo_precision.jl` — red-first payload and replay tests.
- `docs/dev-log/core070/phylo-transport-s3a-julia-payload.md` — immutable
  evidence receipt.
- `docs/dev-log/plan-actual/2026-09-06-m3-phylo-s3a.md` — planned-versus-actual
  closeout.

This planning leaf owns only this brief. It does not edit those implementation
paths, `src/extractors.jl`, `gllvmTMB`, `docs/dev-log/check-log.md`, or any
active #297/#307 files. The `src/bridge.jl` lease must be rechecked after #307
is resolved; do not bypass a live lease.

## Oracle and evidence boundary

The oracle is **frozen gllvmTMB 0.7.0**, commit
`b4d5fee64def88bc768dda1f1f77c29b295edd86`. No live 0.7.1 code, current R
main, or 0.7.1 Class-1 surface may enter the receipt. The R twin remains
read-only for this slice.

The receipt must contain:

- oracle SHA, Julia HEAD, branch, and fixture identifier;
- payload dimensions, sparse nonzero count, `species_aug_id`, `scale`, and
  shipped/recomputed log-determinants;
- explicit malformed-input cases and their diagnostics;
- matched-parameter log-likelihoods for `PrecisionPhy` and `AugmentedPhy`,
  absolute/relative deltas, and finite/non-empty status;
- exact commands and exit status;
- `status = diagnostic_only`, with no promotion of NB2 A11 (it remains
  **partial**) and no true-parity, recovery, coverage, or performance claim.

Success is **PASS** only when the payload validates, the checksum is within
`1e-8`, the replay is finite and non-empty, and the matched log-likelihood
delta is at most `1e-8`. Any failure is a named **BLOCKED** receipt; do not
widen tolerances.

## Estimate and execution envelope

Estimate: **1–2 working days** for implementation, focused tests, and receipt;
no Totoro/DRAC run and no campaign. A local smoke should stay below 30
minutes. If the payload requires a new estimand, a bridge API decision, an R
change, or a longer compute run, stop and request a fresh G0 rather than
expanding this slice.

Dependencies:

- reuse the landed S1/S2 `PrecisionPhy` and `correlation` work;
- retain the frozen-0.7.0 transport design and second-order contract;
- wait for the `src/bridge.jl` lease to become available;
- keep #309’s NB2 A11 status **partial**.

## Unlazy additions for this leaf

Add these IDs under `.unlazy/true-parity-remainder-20260906/` only if they
are absent. Do not rewrite existing A/D or merge-queue gates:

- `M3-PHY-S3A-PAYLOAD-SCHEMA` — descriptor contains the complete precision
  bundle and uses the frozen field meanings.
- `M3-PHY-S3A-VALIDATION` — dimensions, indices, labels, tip map, finite
  values, and log-determinant checksum are checked with explicit failures.
- `M3-PHY-S3A-REPLAY` — the validated payload reaches the existing sparse
  likelihood and agrees with the matched `AugmentedPhy` fixture at `1e-8`.
- `M3-PHY-S3A-RECEIPT` — receipt is non-empty, command-backed, diagnostic-only,
  and records oracle/HEAD/status without promoting any ledger row.

Suggested gate files, if the local ledger requires one file per ID:

```text
.unlazy/true-parity-remainder-20260906/gates/m3-phy-s3a-payload-schema.md
.unlazy/true-parity-remainder-20260906/gates/m3-phy-s3a-validation.md
.unlazy/true-parity-remainder-20260906/gates/m3-phy-s3a-replay.md
.unlazy/true-parity-remainder-20260906/gates/m3-phy-s3a-receipt.md
```

## Stop conditions and handoff

The slice stops after the four gates and the diagnostic receipt. It does not
lift the R `phylo_rr` gate, add kernel cross-rho, implement grouping levels,
run realistic-size cells, repair NB2, merge any PR, or claim `v0.true-parity`.
The next possible slice is the separately reviewed R-side gate lift (S3b/S4);
it needs its own path ownership and authorization.

Definition of done for this brief: the implementation owner has this exact
scope, the four gate IDs are present or explicitly recorded as already
present, the receipt shape is fixed above, and no other lane's files are
claimed.
