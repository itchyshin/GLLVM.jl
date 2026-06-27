# GLLVM.jl Agent Instructions

`GLLVM.jl` is a Julia implementation of the Gaussian + phylogenetic
Generalised Linear Latent Variable Model, built as a digital twin of R's
`gllvmTMB` engine at ~10× speed.

## Project identity

- Status: v0.3.0 development / integration tree — broad Gaussian, non-Gaussian,
  missing-data, structural-dependence, and bridge capability is present, but
  release/tag signoff remains gated by the issue ledger, R bridge parity, docs,
  and Rose audit.
- Headline result: ~340× per-fit median speedup over R/`gllvmTMB` on
  Gaussian fits, with log-likelihoods and point estimates matching R to
  machine precision.
- Phylogenetic representations: sparse (CHOLMOD), contrasts, edge-incidence;
  all return identical log-likelihoods to machine precision.
- Next milestone: finish-gap hardening for the R-Julia twin: reconcile #95/#94,
  keep runtime fixes (#91/#92/#96 and gradient defaults) accuracy-anchored, wire
  verified O(p) sparse-phylo gradients, validate the R bridge, and keep the
  public capability matrix honest.
- Reference design: `~/.claude/plans/users-z3437171-downloads-gllvm-jl-rocke-mighty-sundae.md`
  is the canonical roadmap.

## Design rules

1. Do not add a new response family without an ADEMP simulation-recovery
   test that exercises the new likelihood.
2. Do not add an exported function without a docstring (DocStringExtensions
   conventions).
3. Do not change a user-facing API without updating tutorials, reference
   docs, README, and tests **in the same PR**.
4. Do not change likelihood parameterisation without updating the
   corresponding math doc under `docs/dev-log/decisions/`.
5. Do not silently widen test tolerances. If a test breaks, fix the cause,
   not the tolerance.
6. Keep commits surgical: one concern per commit. Engineering changes,
   cosmetic renames, and chores stay in separate commits.
7. Every meaningful change updates `docs/dev-log/check-log.md`.
8. Every completed task closes with an after-task report under
   `docs/dev-log/after-task/YYYY-MM-DD-*.md` (Definition of Done below).
9. If code is ported from `gllvmTMB`, the comparison bench repo, or any
   external source, document provenance in `docs/dev-log/decisions/` or
   `inst/COPYRIGHTS` before treating the change as complete.

## Convention-change cascade

If a syntax change, argument rename, formula-grammar change, or extractor
rename ships, the same PR must atomically update: (a) docstrings, (b)
Documenter tutorials and reference pages, (c) tests, (d) README.md,
(e) any roadmap or status table referencing the old name. Partial cascades
are blockers at the Rose pre-publish gate.

## Standard commands

```sh
julia --project=. -e 'using Pkg; Pkg.test()' # full suite incl. Aqua/JET (what CI runs)
julia --project=. test/runtests.jl          # quick core suite (skips quality tools)
julia --project=docs docs/make.jl           # local Documenter build
gh run list --limit 3                       # confirm CI state
git status; git rev-parse --short HEAD      # evidence-first state check
```

## Standing review roles

These names are shorthand for recurring review perspectives. They do not run
continuously; the orchestrator launches them only for bounded tasks. Use the
canonical names in status updates; do not rename them.

| Name | Role | Owns / leads |
| --- | --- | --- |
| **Ada** | Orchestrator and maintainer voice | Phase planning, after-task review, final consistency audit |
| **Boole** | Julia formula and macro grammar | `StatsModels.jl` integration, `@formula`, user-facing API syntax |
| **Gauss** | Julia numerical engine | CHOLMOD, SparseArrays, ForwardDiff stability, Takahashi selected-inverse, `src/likelihood*.jl`, `src/sparse_phy*.jl` |
| **Noether** | Symbolic ↔ Julia API ↔ math kernel consistency | Closed-form Gaussian and (Phase 3) Laplace cross-layer correctness |
| **Darwin** | Ecology / evolution audience | Tutorial framing, applied use cases, phylogenetic signal interpretation |
| **Florence** | Scientific figure editor | CairoMakie.jl figures, Confidence Eye contract port |
| **Fisher** | Statistical inference | Profile / Wald / bootstrap CIs, identifiability, validation against R |
| **Pat** | Applied PhD-student tester | Quickstart readability, error messages, tutorial accessibility |
| **Jason** | Julia ecosystem scout | MixedModels.jl, Turing.jl, Phylo.jl, Distributions.jl — idioms and packages to reuse |
| **Curie** | Simulation and recovery testing | ADEMP recovery tests via `Test.jl` + `StableRNGs`, edge and malformed cases |
| **Emmy** | Julia package architecture | Multiple dispatch, types, exports, `Project.toml`, Aqua.jl, JET.jl |
| **Grace** | Julia CI and reproducibility | GitHub Actions matrix, Documenter.jl deploy, Pkg.jl registry hygiene |
| **Rose** ★ | Systems auditor | Pre-publish gate, claim-vs-evidence audit, README/CLAUDE.md drift detection — **the most important guardrail** |
| **Shannon** | Cross-team coordination | Branches, PRs, after-task coverage, file-overlap and lane checks |
| **Karpinski** | Julia-specialist | Type stability, dispatch, performance, sparse linalg, AD backends; `@code_warntype`, JET, Allocs.jl |
| **Hopper** | R↔Julia translator | API equivalence, idiom mapping, `gllvmTMB`↔`GLLVM.jl` parity tests via RCall.jl |

Full responsibility detail lives in §2 of the reference plan.

## Phase state snapshot

- **`latent(lv = ~ x)` X_lv CI build-out (in flight, 2026-06-27).** `main` @ `88f898b`
  carries #118 (Poisson X_lv), #119 (the `2f0` package-wide Wald-SE repair), #120
  (NB2 X_lv); #121 (Gamma X_lv) open. Held local/unpushed: Beta X_lv, X_lv recovery
  bench, and the full X_lv CI subsystem (`confint_lv_effects` — Wald + bootstrap, 6
  families, K≥1, native + bridge; `test_lv_ci` 106/106) plus the R-side admissions and
  the R CI reader (one major schema blocker for the maintainer). `START HERE:`
  `docs/dev-log/handover/2026-06-27-claude-handover.md`.
- **Phase 0 — Team and memory scaffolding (complete, 2026-05-30).** PR #1.
- **Phase 1.1 — O(p) node-frame gradient (complete, CI green cross-platform,
  2026-05-30).** PR #2; `src/node_gradient.jl` (+ wired `sparse_phy_grad.jl`);
  58 tests; full suite 491 pass; ~O(p) confirmed (35.7× vs `sparse_phy_grad`
  at p=2000).
- **Phase 1.0 — RCall.jl parity scaffold (DRAFT, committed).** Isolated
  `test/parity/`; R call shape pending live-R validation.
- **Phase 4 runtime gap fill (local, 2026-06-14).** #91 high-rate Poisson
  divergence, #92 phylo-signal Wald scale, #96 Laplace mode-finder safeguard,
  and the Gamma analytic-gradient default are fixed on the local integration
  branch with full `Pkg.test()` green. Still next: PR/issue reconciliation,
  bridge statistical parity, and the guarded O(p) sparse-phylo gradient wiring.

Update this snapshot after every after-task report.

## Pre-publish gate

Before any user-facing change reaches `main`, Rose runs a narrow audit:
README, CLAUDE.md, AGENTS.md, docs, and CHANGELOG are scanned against the
engine for stale claims, broken refs, and unsupported assertions. The
`rose-pre-publish-audit` skill drives this. It is mandatory before any
release/tag, registry action, or public capability promotion.

## Merge authority

- **Self-merge (low risk):** documentation, after-task reports, audits,
  test additions that don't widen tolerances, recovery checkpoints.
- **Maintainer approval required (high risk):** any API change, formula
  grammar change, likelihood parameterisation change, version bumps,
  `.codex/agents/*` or `.agents/skills/*` edits, AGENTS.md or CLAUDE.md
  edits beyond Phase-state snapshot updates.

## Definition of Done

A task is done only when **all** of these are present:

1. Implementation in `src/`.
2. Tests in `test/` exercising the change, passing under `Pkg.test()` (full,
   incl. quality tools) and `julia --project=. test/runtests.jl` (core).
3. Docstrings on every new exported symbol.
4. Worked example or reference entry in `docs/` if the change is
   user-facing.
5. Updated `docs/dev-log/check-log.md` entry.
6. After-task report at `docs/dev-log/after-task/YYYY-MM-DD-*.md`.
7. Rose audit verdict — explicit OK or list of remaining blockers.

## Routines and robustness

| Routine | Form |
| --- | --- |
| Evidence-first rehydration | `git status` + `git rev-parse --short HEAD` + `gh run list --limit 3` before assuming repo state |
| Pre-edit lane check | `gh pr list` + `git log --all --oneline --since="6 hours ago"` before editing AGENTS.md, CLAUDE.md, or shared design docs |
| Named-perspective reporting | Status reports speak as Ada and name which perspectives reviewed |
| Recovery checkpoint | `julia --project=. tools/julia-checkpoint.jl --goal "..." --next "..."` writes a snapshot under `docs/dev-log/recovery-checkpoints/` |
| Local checks before push | `Pkg.test()` clean (full, incl. Aqua/JET); local Documenter build clean if docs touched |
| Verify CI green | `gh run view` after every push, before claiming green |
| Confidence Eye contract | Pale CI region + darker outline + darker center mark + hollow point-estimate circle; Florence owns the CairoMakie.jl port |
| Cross-project learning | Routinely scan the sister/twin projects — **gllvmTMB** (our R twin; pkgdown + repo), **drmTMB** + **DRM.jl** (the DRM family) — at session start, before docs/API slices, and at phase boundaries. Port good ideas *and improve them*; share ours back. Log in the cross-pollination tracking issue (#13). |

## Hard boundaries

- **No engine surgery on R's `gllvmTMB`** from this repo. That R package
  is a read-only reference.
- **No push without an explicit instruction** from the maintainer. Always
  commit locally first; ask before pushing.
- **Never `git add -A`** or `git add .`. Stage by name only — disjoint
  agents may be editing in parallel.
- **Test commands:** `Pkg.test()` is the full suite (incl. Aqua/JET; what CI
  runs); `julia --project=. test/runtests.jl` is the quick core run. The old
  `can not merge projects` breakage is resolved — verified macOS + CI.
- The benchmark / comparison repo (`gllvmTMB-julia-bench/`) stays local
  and is intentionally separate from this repo.
- **Private-provenance rule.** One collaborator's name (recorded only in
  the maintainer's private notes) must never appear in any public artifact:
  READMEs, docstrings, tutorials, commit messages, CHANGELOG, Documenter
  pages, or this file. The edge-incidence representation cites Bolker's
  `phylog.rmd` only. `.gitignore` carries the guard patterns; consult the
  private notes for the specific name and patterns — do not transcribe
  them here.

## Engine Quality Battery

Every algorithm shipped in Phase 1 (and every family in Phase 3) passes
**Workflow Q** — seven parallel checks before merge:

1. **FD verification** — numerical-gradient check ≤ 1e-6.
2. **Cross-check** — vs reference implementation in repo ≤ 1e-8.
3. **R-parity** — vs `gllvmTMB` via RCall.jl ≤ 1e-6, gated by
   `ENV["GLLVM_PARITY_TESTS"] == "1"` (off by default in CI).
4. **JET.jl pass** — zero type instability in the hot path.
5. **Allocs.jl pass** — zero allocation in the inner loop.
6. **Aqua.jl pass** — project hygiene clean.
7. **Multi-shape** — balanced + caterpillar trees; p ∈ {100, 1000, 10000}.

Failure on any check kicks the algorithm back to draft. After the battery
passes, Florence renders a speedup plot vs `gllvmTMB`, an after-task audit
is written, and Rose signs off. Workflow Q is the keystone routine —
defined in §7 of the reference plan.
