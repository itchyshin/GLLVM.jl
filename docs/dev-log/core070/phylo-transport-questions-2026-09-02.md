# Phylo transport — the four sub-questions, brought to the maintainer (2026-09-02)

**Status: QUESTIONS FOR DECISION — no code.** Maintainer decision round2-3 #7 made phylo
transport the next engine track and required the conversion design to be *reviewed before any
code*. The design is committed at `phylo-transport-design.md` (recommendation: hybrid — trees
pass as topology into `make_phy`; pedigree / sparse `Ainv` / dense `vcv=` pass as R's already
canonical sparse precision bundle with explicit `scale` and `log_det` checksums; Julia adds a
`PrecisionPhy` consumer and a unit-height mode; no new inversion anywhere). This note restates
its §5 open questions with one recommendation and one safe default each, so a single reply
closes the review. Nothing below is implemented under any answer until the maintainer replies.

Reviewer lenses used: Noether (symbolic ↔ API consistency), Fisher (estimand), Gauss (numerics),
Hopper (R accessor semantics; all R citations are to the frozen 0.7.0 readback).

## Q1 — Estimand convention for native Julia fits

R ships the *correlation* form of C: the fit path hard-codes `correlation = TRUE`, scales the
precision by tree height, and σ²_phy absorbs the raw scale (`phylo-tree-precision.R:223,227`).
Julia's `AugmentedPhy` uses raw branch lengths, so σ²_phy differs from R's by exactly `height`
while the joint-optimum logLik can still agree — the silent scale drift the design names.

- **Recommendation:** add `correlation::Bool` to `augmented_phy` / `make_phy`, **opt-in
  (`false` by default) for native fits**, with the bridge **always** setting `true`. Parity
  forces it on bridge fits either way; a default flip would change every existing native
  user's σ²_phy by a tree-dependent factor without warning.
- **Why not default `true`:** it is a breaking estimand change for native users, and the
  package has no deprecation cycle for a numerical convention yet.
- **Safe default if no reply:** opt-in.

## Q2 — Dense `vcv=` admission over the bridge

The only genuine C→Q inversion anywhere is R's own dense fallback: `Aphy + diag(1e-8)` then
dense `solve()` (`fit-multi.R:3843-3852`), O(p³) and fragile for near-singular C (star
phylogenies, duplicated tips, highly inbred pedigrees). The hybrid design keeps that inversion
on the R side, executed once, and ships the resulting bundle.

- **Recommendation:** **admit** the dense path in S3 (it produces the same canonical bundle),
  but have the R adapter **compute and ship the condition number of C** alongside the bundle,
  and have Julia **warn above a threshold** (κ > 1e8 as a starting point) instead of the
  current silent 1e-8 jitter. The `log_det` checksum already in the design catches a
  mismatched bundle; the condition number tells the user *why* a fit is fragile.
- **Why not a hard gate first:** it would refuse fits R itself accepts, which is a parity
  regression in the R-adapter direction.
- **Safe default if no reply:** admit with the warning.

## Q3 — Kernel scope

`kernel_*` rides the same `phylo_rr` rewrite as phylo/animal (`brms-sugar.R:3293`) but carries
`.cross_kernel_rho` extras (`fit-multi.R:3527-3549`) that phylo/animal do not.

- **Recommendation:** **split** kernel into its own slice **S3b**, sequenced after S3 lands
  with phylo + animal green. Bundling would put a second estimand surface (cross-kernel ρ)
  into the first parity leaf and blur its verdict.
- **Cost of splitting:** the three `FIT-MODE-KERNEL-*` cells stay R-ADAPTER-BLOCKED one slice
  longer (3 of the 13 cells the design converts).
- **Safe default if no reply:** split.

## Q4 — Non-ultrametric trees

R's `correlation = FALSE` exists in `phylo-tree-precision.R` but the fit path hard-codes
`TRUE` and gates on ultrametricity within `sqrt(eps)·scale` (`phylo-tree-precision.R:140-146`).
Julia's `AugmentedPhy` has no ultrametric gate at all.

- **Recommendation:** **defer** with a named gate, `GJL-GATE-PHYLO-NONULTRAMETRIC`, raised by
  the bridge when a supplied tree fails the ultrametric check; native Julia keeps accepting
  non-ultrametric trees in `correlation = false` mode (current behaviour, unchanged). Parity
  can only be claimed on the surface R actually fits.
- **Why not support now:** there is no R fit to pair against, so any Julia-side result would
  be Julia-beyond and would need its own ADEMP recovery evidence — a separate track.
- **Safe default if no reply:** defer with the named gate.

## Compute-target question raised alongside (not a phylo question)

**Q0 — ZI-trio ADEMP campaign on Totoro instead of a DRAC array.** Decision #12 approved a DRAC
array; today Narval has no live ControlMaster socket (MFA needed, D-64 forbids forcing it) and
Nibi is under a full-cluster maintenance reservation until 2026-09-03 08:00. The same worker
(`tools/core070_zi_ademp_chunk.jl`, same 240-chunk cell map) runs on Totoro under GNU parallel
at ≤120 cores behind a D-139 pre-run. **Recommendation:** Totoro now; Nibi tomorrow only as
fallback. **Safe default:** proceeds under the approved plan; the evidence, not the scheduler,
is what #12 asked for.

## What happens after the reply

Answers feed `phylo-transport-design.md` §4 slices S1–S4 unchanged in order (PrecisionPhy
consumer → scale alignment → bridge payload + gate lift → paired parity leaf). No slice starts
before the reply. Related: `bridge-coverage-matrix.md` §R-ADAPTER-BLOCKED,
`required-source-case-map.json` (the 121 `BLOCKED_NEEDS_JULIA_SURFACE` rows).
