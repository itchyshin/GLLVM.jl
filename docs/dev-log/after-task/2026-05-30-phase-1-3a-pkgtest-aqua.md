# After-task — Phase 1.3a: adopt Pkg.test + wire Aqua

**Date:** 2026-05-30
**Phase:** 1.3a (quality battery — first half; perf is the second half, next)
**Branch:** `phase-1-quality` (PR #3, stacked on #1 + #2)
**Author:** Ada/Opus orchestrator.
**Models used:** Opus (investigation, guidance edits, wiring, verification). Aqua
findings-first run + JET findings-first run done directly via Bash temp envs.

## Goal

Resolve the test-environment fork (local `--project=.` vs CI `Pkg.test`) so
test-only quality tools (Aqua, JET) can be wired cleanly, then wire the quality
battery. Maintainer decision: investigate the Pkg.test breakage first; adopt it
if it works; quality battery this round, perf next.

## Implemented

- **Investigation result:** `Pkg.test()` **works** (passed locally; CI already
  uses `julia-actions/julia-runtest` = Pkg.test). The CLAUDE.md "can not merge
  projects" note was **stale** — root `Project.toml` has no conflicting
  `[extras]`/`[targets]`, and GLLVM is not self-listed in `test/Project.toml`,
  so the modern test-env merge is clean.
- **Guidance updated** (maintainer-approved): CLAUDE.md + AGENTS.md now name
  `Pkg.test()` the canonical full suite (incl. quality tools; what CI runs) and
  `julia --project=. test/runtests.jl` the quick core run. AGENTS.md phase
  snapshot refreshed.
- **Aqua wired always-on:** `test/Project.toml` gains Aqua; `test/test_quality.jl`
  runs `Aqua.test_all(GLLVM; ambiguities=false)` under Pkg.test and skips
  gracefully (`@test_skip` + info) under the bare core run where Aqua is absent.

## Checks run

| Check | Result |
|-------|--------|
| `Pkg.test()` (full) | ✅ "tests passed" — quality 10/10, node-frame 58/58, full suite green |
| `julia --project=. test/test_quality.jl` (core env) | ✅ Aqua skips gracefully, exit 0 |
| Aqua categories | ✅ unbound params, undefined exports, project/test-project consistency, stale deps, compat bounds (4/4), piracy, persistent tasks |
| CI (PR #3) | ⏳ verified at close (see below) |

## JET — findings-first, deferred (honest scope correction)

JET was run findings-first (temp env) on the hot paths. It surfaced **real
type-instabilities**, NOT a clean green:

- `takahashi_diag(::CHOLMOD.Factor)` infers as `Any`.
- CHOLMOD `Factor \ Vector` triggers runtime dispatch.
- The `Any` cascades through `grad_node_perspecies` (src/node_gradient.jl:329–345).

These are **correctness-neutral** (tests pass; cross-platform CI green on #2) —
performance targets, not bugs. Per the "no silent tolerance widening" rule, JET
is NOT wired as a fake-green or perpetually-skipped check. It wires green in the
**perf round** after the instabilities are fixed (fixing `takahashi_diag`'s
return type should clear most of the cascade).

## Definition of Done

1. Implementation — wiring in `test/` + guidance (no `src/` change). ✅
2. Tests pass under `Pkg.test()` (full) and core run (skip). ✅
3. Docstrings — n/a (no new exported symbol). ✅
4. Docs — guidance in CLAUDE.md/AGENTS.md. ✅
5. check-log — (this repo uses after-task reports; check-log deferred). ⚠
6. After-task report — this file. ✅
7. Rose audit — pending pre-tag; routine slice, self-merge-eligible per AGENTS.md. ⏳

## Next actions (Phase 1.3 perf half)

- Fix the JET-flagged type-instabilities: annotate/stabilise `takahashi_diag`'s
  return type; address the CHOLMOD `\` dispatch in the per-species path. Then
  wire JET always-on (green) + add Allocs (zero-alloc inner loop).
- Integrate **Takahashi O(p) selected-inverse** into `sparse_phy_grad.jl`
  (currently O(p²)).
- Proper **BenchmarkTools** O(p) sweep at p ∈ {100, 500, 1000, 5000, 10000};
  Florence renders the speedup plot (Confidence Eye band) for `docs/benchmarks.md`.

## Branch-stacking note (for the maintainer)

Branches stack: #1 (phase-0) ← #2 (op-node engine) ← phase-1-quality (#3:
parity + 1.3a). Merge order #1 → #2 → #3; each PR's diff auto-reduces as the
one below lands. Once #1 + #2 are on main, the remaining work can rebase to
thin PRs off main.
