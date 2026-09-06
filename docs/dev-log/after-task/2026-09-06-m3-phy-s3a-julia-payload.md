# After Task: M3-PHY-S3a Julia precision-payload

**Date:** 2026-09-06
**Owner:** Cursor/Ada
**PR:** [#310](https://github.com/itchyshin/GLLVM.jl/pull/310)
**Branch:** `cursor/m3-phy-s3a-20260906`
**Worktree:** `~/local-scratch/lanes/GLLVM.jl-m3-phy-s3a-20260906`
**Tip at this report:** merge of `origin/main` (includes #307 `f9e7c710`) onto `e509d15a`

## Goal

Admit the frozen `PrecisionPhy` bundle as a JuliaCall-flat payload, validate it
with named gates, and replay it against the S1 `AugmentedPhy` fixture. Diagnostic
only.

## Implemented

`phylo_precision_payload` packs a `PrecisionPhy` into a flat NamedTuple
(`i,j,x,n_aug,n_leaves,species_aug_id,node_labels,scale,log_det`).
`admit_phylo_precision_payload` reconstructs `PrecisionPhy` after checking
dimensions, 1-based triplet indices, the 0-based tip map, labels, finiteness,
and a 1e-8 log-det checksum. Public names live in `src/bridge.jl` (moved there
after the #307 `bridge.jl` lease expired). This does not lift the R `phylo_rr`
gate and does not call `bridge_fit`.

## Mathematical Contract

The admitted object is the Hadfield & Nakagawa (2010) augmented-state sparse
phylogenetic precision, already canonical as `PrecisionPhy` / `AugmentedPhy`.
The new work is the wire schema and checksum, not a new likelihood. Replay
compares `gaussian_marginal_loglik_sparse_phy` on the admitted payload versus
the S1 `AugmentedPhy` fixture at matched parameters.

## Files Changed

`src/`

- `src/bridge.jl` — payload pack / admit / named gates
- `src/phylo_precision.jl` — pointer comment; constructors unchanged
- `src/GLLVM.jl` — export the two public names

`test/`

- `test/test_bridge_phylo_precision.jl` — schema, admit, malformed gates, replay
- `test/runtests.jl` — `_shard_include` for the new file

`docs/`

- `docs/src/api.md` — list the two names
- `docs/dev-log/core070/phylo-transport-s3a-julia-payload.md` — diagnostic receipt
- `docs/dev-log/plan-actual/2026-09-06-m3-phylo-s3a.md` — plan vs actual
- `docs/dev-log/after-task/2026-09-06-m3-phy-s3a-julia-payload.md` — this report

## Tests Added

`test/test_bridge_phylo_precision.jl` (78 assertions):

- schema and reconstruct — compares the admitted Q to the independent
  `PrecisionPhy` constructor
- malformed input — six named `GJL-GATE-PHYLO-PAYLOAD-*` tags
- replay — likelihood vs `AugmentedPhy` at three σ²_phy points, abs/rel Δ = 0

S1 regression `test/test_phylo_precision.jl` remains 22/22.

## Benchmark Numbers

N/A — no hot-path change. Admission is a one-shot pack/validate around the
existing sparse-phylo kernel.

## R-Parity Verdict

Parity: N/A — change does not touch the public parity surface. No live R
engine call. Frozen-field meanings cite gllvmTMB 0.7.0
`b4d5fee64def88bc768dda1f1f77c29b295edd86` as documentation only. This is not
a v0.true-parity claim.

## JET / Allocs / Aqua Verdicts

- JET: not run locally — CI Julia shards are the gate
- Allocs: N/A — no inner-loop change
- Aqua: not run locally — no `Project.toml` change

## Checks Run

Worktree `~/local-scratch/lanes/GLLVM.jl-m3-phy-s3a-20260906`, after merging
`origin/main` (post-#307):

```text
~/.juliaup/bin/julialauncher --project=. -e \
  'using Test, GLLVM; include("test/test_bridge_phylo_precision.jl"); include("test/test_phylo_precision.jl")'
# phylo transport S3a: Julia precision payload | 78 pass / 78 / 3.6s
# phylo transport S1: PrecisionPhy consumer    | 22 pass / 22 / 0.0s
# exit 0
```

No Totoro. No R cpp. No `Pkg.test()` in this closeout sitting.

## Check-log note (not appended to check-log.md)

`docs/dev-log/check-log.md` was **not** appended. Live lease
`cursor:GLLVM.jl` still holds that path (plus `test/test_bridge_sources.jl`,
`test/test_kernel_latent_unique_bridge.jl`, and the #307 after-task). Claim
attempt `LANE_ID=cursor-m3-phy-s3a-aftertask-20260906` was **REFUSED**. The
note that would have been appended:

```text
## 2026-09-06 — M3-PHY-S3a Julia precision-payload (#310)

- Local (post-#307 merge): test_bridge_phylo_precision.jl **78/78**;
  test_phylo_precision.jl **22/22**.
- Replay vs AugmentedPhy: abs/rel Δ = 0 at σ²_phy ∈ {0.3, 1.0, 2.5}.
- Diagnostic only. No true-parity claim. R phylo_rr not lifted.
- check-log append deferred: #307 lease still held this path.
```

## Consistency Audit

`rg` on the new after-task, receipt, and plan-actual:

- `true-parity|v0.true-parity` — fenced as not claimed
- `phylo_rr` — gate not lifted
- `340.?x|machine precision` — not used as a public speed/parity claim

README, CLAUDE.md, and capability-status rows were not edited.

## GitHub Issue Maintenance

No issue action. This is the authorised S3a closeout of #310, not an issue
close.

## What Did Not Go Smoothly

1. `src/bridge.jl` was leased by #307 at the start, so the first commits put
   the API in `src/phylo_precision.jl` and moved it later.
2. check-log remains leased by the #307 identity even after #307 merged at
   `f9e7c710`. This report carries the check-log note instead of bypassing
   the refusal.
3. A local rebase onto post-#307 `main` was undone in favour of a merge
   commit so the branch could be pushed without `--force`.

## Team Learning

When two Cursor lanes share `check-log.md`, put the check-log note in the
after-task and say so. Do not wait on `--gc` of a live lease.

## Remaining Risks

- CI on the post-#307 merge + this after-task has not settled at the time of
  writing. Merge of #310 waits for Documenter + Julia shards; Frozen R
  advisory fail is accepted.
- Thin `bridge.jl` wrappers beyond the landed admit/pack are not a separate
  follow-up; the API already lives there.
- R `phylo_rr` S3b is **not authorised**.

## Known Limitations

- Diagnostic-only. Does not claim v0.true-parity, recovery, coverage, or
  performance.
- Does not lift the R `phylo_rr` gate.
- NB2 A11 remains **partial**.
- No two-part families; no large-p non-Gaussian structured dependence.

## Next Command

`gh pr ready 310 &&` wait for Documenter + Julia green, then
`gh pr merge 310 --merge`. Do **not** start R `phylo_rr` S3b.

## Rose Verdict

Rose verdict: PASS WITH NOTES — S3a Julia admission is locally 78/22 green
and fenced diagnostic-only; check-log was not appended because the #307
lease refused that path; public parity is not claimed.
