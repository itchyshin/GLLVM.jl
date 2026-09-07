# After Task: M3-PHY-S3-ANIMAL pedigree Ainv fixture

**Date:** 2026-09-07
**Owner:** Cursor/Ada
**PR:** (this branch)
**Branch:** `cursor/m3-phy-s3-animal-20260907`
**Worktree:** `~/local-scratch/lanes/GLLVM.jl-m3-phy-s3-animal-20260907`
**Base:** `origin/main` `5d1c9a6c` (#312)

## Goal

Second design fixture: 12-individual pedigree / sparse `Ainv` as raw
triplets, admitted via the PrecisionPhy path, replayed (and fit)
against the existing dense animal/`A` path. Prepares “animal green”
before later kernel work. Diagnostic only.

## Implemented

`admit_phylo_precision_payload` now accepts `n_aug ≥ n_leaves` so a
tip-only or ancestor-augmented pedigree precision can land. The
12-id `animal-keyword.R` example is assembled in the test as Henderson
`A` + Quaas `Ainv` triplets (not a production parser). Replay is
against dense `A` / `relatedness_cov`. A 10-tip ancestor map keeps
the full 12×12 precision. `fit_phylo_gaussian` and the S3-FIT
`bridge_fit` consume hook work on the admitted payload. This does
not lift the R `phylo_rr` gate.

## Mathematical Contract

Univariate Gaussian
`y ~ N(μ·1, σ²_eps I + σ²_phy A)`, with `A` the Henderson numerator
relationship and `Q = Ainv` the Quaas precision. For tip-only animal,
`n_aug = p` and `Σ_phy_unit = Q⁻¹ = A`. Unphenotyped ancestors keep
the full `Q`; the phenotyped covariance is the marginal block
`A[tips,tips] = (Q⁻¹)[tips,tips]`. Subsetting `Ainv` would condition
on the dropped nodes. No new inversion in `src/`.

## Files Changed

`src/`

- `src/bridge.jl` — admit `n_aug ≥ n_leaves`
- `src/phylo_precision.jl` — constructor notes for animal sizes

`test/`

- `test/test_phylo_precision_animal.jl` — new fixture
- `test/test_bridge_phylo_precision.jl` — DIM case is now `n_aug < n_leaves`
- `test/runtests.jl` — `_shard_include` the new file

`docs/`

- `docs/dev-log/core070/phylo-transport-s3-animal-fixture.md`
- `docs/dev-log/plan-actual/2026-09-07-m3-phylo-s3-animal.md`
- `docs/dev-log/after-task/2026-09-07-m3-phy-s3-animal.md` — this report
- `docs/dev-log/check-log.md` — append

## Tests Added

`test/test_phylo_precision_animal.jl` (43 assertions):

- Henderson `A` × Quaas `Ainv` residual 0; F = 0
- admit tip-only `n_aug = n_leaves = 12`
- `n_aug < n_leaves` still DIM
- matched-parameter nll vs dense `A` at three `(σ²_phy, σ²_eps, μ)`
- ancestor map `n_leaves = 10` vs `A[tips,tips]`; subsetted Ainv disagrees
- `fit_phylo_gaussian` + `bridge_fit` consume hook

S3a remains 78/78. S1 remains 22/22. S3-FIT remains 13+17.

## Benchmark Numbers

N/A — 12-individual diagnostic fixture. No hot-path claim.

## R-Parity Verdict

Parity: N/A — change does not touch the public parity surface. No live R
engine call. Frozen-field meanings and the pedigree example cite
gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86` as
documentation only. This is not a v0.true-parity claim.

## JET / Allocs / Aqua Verdicts

- JET: not run locally — CI Julia shards are the gate
- Allocs: N/A — no inner-loop change claimed
- Aqua: not run locally — no `Project.toml` change

## Checks Run

Worktree `~/local-scratch/lanes/GLLVM.jl-m3-phy-s3-animal-20260907`:

```text
~/.juliaup/bin/julialauncher --project=. -e \
  'using Test, GLLVM; include("test/test_phylo_precision_animal.jl")'
# phylo transport S3-ANIMAL: pedigree Ainv fixture | 43 / 43
# exit 0

~/.juliaup/bin/julialauncher --project=. -e \
  'using Test, GLLVM; include("test/test_bridge_phylo_precision.jl")'
# phylo transport S3a: Julia precision payload | 78 / 78
# exit 0

~/.juliaup/bin/julialauncher --project=. -e \
  'using Test, GLLVM; include("test/test_fit_phylo.jl"); include("test/test_phylo_precision.jl"); include("test/test_shard_selection.jl")'
# 13+17 / 22 / 43
# exit 0
```

TDD: first run failed
`GJL-GATE-PHYLO-PAYLOAD-DIM: n_aug (12) must equal 2*n_leaves-2 (22)`.
Admit relaxation is the green. No Totoro. No R cpp. No `Pkg.test()`
in this closeout sitting (CI shards).

## Consistency Audit

`rg` on the new after-task, receipt, and plan-actual:

- `true-parity|v0.true-parity` — fenced as not claimed
- `phylo_rr` — gate not lifted
- `340.?x|machine precision` — not used as a public speed/parity claim

README, CLAUDE.md, and capability-status rows were not edited.

## GitHub Issue Maintenance

No issue action. Diagnostic S3-ANIMAL closeout only.

## What Did Not Go Smoothly

1. Fresh worktree needed `Pkg.instantiate()` (Optim missing).
   `Project.toml` / `Manifest.toml` were not committed.
2. The named R example has F = 0. The design sketch said F > 0.
   Recorded honestly; the two-parent Mendelian branch still runs.
3. Subagent cannot `move_agent_to_root`; work stayed in the named
   worktree by absolute path.

## Team Learning

When a DIM gate is written for trees only (`n_aug == 2p − 2`), the
next fixture that is *supposed* to be a different size will fail for
the wrong reason. Prefer `n_aug ≥ n_leaves` plus the log-det checksum.

## Remaining Risks

- CI Julia shards + Documenter not settled at write time. Merge waits
  for those greens; Frozen R advisory fail is accepted.
- No production pedigree parser. A later slice that wants one must
  not silently invert `A` on both sides.

## Known Limitations

- Diagnostic-only. Does not claim v0.true-parity, recovery, coverage,
  or performance.
- Does not lift the R `phylo_rr` gate.
- NB2 A11 remains **partial**.
- No two-part families; no large-p non-Gaussian structured dependence.

## Next Command

Wait for Documenter + Julia shards green, then merge. Do **not** start
R `phylo_rr` S3b. Kernel work waits on this animal-green diagnostic.

## Rose Verdict

Rose verdict: PASS WITH NOTES — S3-ANIMAL locally 43/43 + S3a 78/78 +
S1 22/22 + S3-FIT 13+17 green and fenced diagnostic-only; public
parity is not claimed; F = 0 on the named example is stated; full
suite left to CI.
