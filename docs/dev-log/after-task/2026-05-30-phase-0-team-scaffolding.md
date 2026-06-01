# After-task — Phase 0: Team & memory scaffolding

**Date:** 2026-05-30
**Phase:** 0 (Team & memory scaffolding)
**Author:** Ada (orchestrator), with the W0 drafting fan-out + Rose audit.
**Reference plan:** `/Users/z3437171/.claude/plans/users-z3437171-downloads-gllvm-jl-rocke-mighty-sundae.md`

## Goal

Stand up the multi-agent team, doctrine, routines, and cross-session memory
for GLLVM.jl — mirroring the gllvmTMB/drmTMB discipline (the drmTMB template
specifically: tighter scope, leaner doctrine), adapted to Julia. No engine
code touched. The team must be load-bearing for Phase 1.1 within 24 hours.

## Implemented

Drafted via Workflow W0 (24 artifacts, parallel fan-out, then Rose audit):

- **`AGENTS.md`** (178 lines, within the ≤200 cap). Sections: project
  identity, design rules, convention-change cascade, 16-perspective standing
  review table (14 personas + Karpinski + Hopper), phase-state snapshot,
  pre-publish gate, merge authority, Definition of Done, routines &
  robustness, hard boundaries, Engine Quality Battery (Workflow Q).
- **11 Codex agents** under `.codex/agents/`: documentation-writer,
  landscape-scout, literature-curator, documenter-editor (was pkgdown-editor),
  reproducibility-engineer, reviewer, simulation-tester, systems-auditor,
  julia-engineer (was tmb-engineer), user-tester, r-julia-translator (new).
- **8 project-local skills** under `.agents/skills/`: add-family,
  add-simulation-test, after-task-audit, figure-visual-audit,
  prose-style-review, julia-likelihood-review (was tmb-likelihood-review),
  julia-package-development (new — no R analog), r-julia-translator (new).
- **`tools/julia-checkpoint.jl`** — recovery-checkpoint helper (Julia analog
  of drmTMB's `tools/codex-checkpoint.R`). Pure-stdout; reads hard boundaries
  from AGENTS.md; never writes/commits.
- **`.claude/settings.local.json`** — narrow read-only Bash allowlist
  (gitignored; stays local, not committed — correct for a *.local.json).
- **`docs/dev-log/after-task/`** and **`docs/dev-log/decisions/`** — audit
  trail and decision-log directories (`.gitkeep` placeholders).

Memory patches (outside the repo — not part of this commit):

- `~/.claude/memory/memory_summary.md` — new "GLLVM.jl (Julia port)" section.
- `~/.claude/memory/MEMORY.md` — new Task Group (preferences / reusable
  knowledge / failures), drmTMB-structured.
- `~/.codex/memories/memory_summary.md` — new GLLVM.jl date-block.
- `~/.codex/memories/MEMORY.md` — new Task Group with 5 tasks + keywords.

## Files changed (in this repo / this commit)

- `AGENTS.md` (new)
- `.codex/agents/*.toml` (11 new)
- `.agents/skills/*/SKILL.md` (8 new)
- `tools/julia-checkpoint.jl` (new)
- `docs/dev-log/after-task/.gitkeep`, `docs/dev-log/decisions/.gitkeep` (new)
- `docs/dev-log/after-task/2026-05-30-phase-0-team-scaffolding.md` (this file)

## Checks run

- **julia-checkpoint.jl runs**: `~/.juliaup/bin/julialauncher --project=.
  tools/julia-checkpoint.jl` → renders the full checkpoint (branch `main` @
  `6a0d090`, hard boundaries, files-in-flight, recovery template). ✓
- **TOML validity**: Rose audit confirmed all 11 `.codex/agents/*.toml`
  parse with name + description + developer_instructions. ✓
- **YAML frontmatter**: all 8 `SKILL.md` files have valid `name` +
  `description` frontmatter. ✓
- **JSON validity**: `settings.local.json` passes `json.load`. ✓
- **Checkpoint script parse**: `Meta.parseall` → 26 top-level expressions,
  no errors. ✓

## Consistency audit (Rose)

- Verdict: **BLOCKERS → resolved.** 23/24 artifacts OK on first pass.
- **One HIGH blocker, now fixed:** AGENTS.md hard-boundary text named the
  private collaborator and transcribed the literal `.gitignore` guard
  patterns (which embed the surname) — inside the rule that forbids exactly
  that, in a file checked into the public repo. Reworded to refer obliquely
  ("one collaborator's name, recorded only in private notes… consult the
  private notes; do not transcribe them here").
- **Post-fix scan:** private-provenance guard pattern scan across all
  `*.md`/`*.toml`/`*.jl`/`*.json` (excluding `.git/`) -> **CLEAN**. The
  `.gitignore` guard patterns remain (pre-existing; glob ignores must
  literally contain the substring to match — out of scope to change here).

## What did not go smoothly

- The name-leak blocker is a good catch and a reminder: doctrine files that
  *describe* a redaction rule can themselves violate it. Future audits should
  always grep the public tree for the forbidden token, not just check that
  the rule exists.

## Known limitations / next actions

- `.claude/settings.local.json` is gitignored, so it is not version-tracked.
  Intentional (local permissions). If the team wants a shared baseline, add a
  committed `.claude/settings.json` later.
- Optional gllvmTMB-only skills (rose-pre-publish-audit, stop-checkpoint,
  article-tier-audit) deliberately deferred — added when work demands them
  (rose-pre-publish-audit becomes mandatory at the v0.2.0 tag).
- **Next:** Phase 1.0 — add RCall.jl to `test/Project.toml`, create
  `test/parity/test_gaussian_parity.jl` (gated `GLLVM_PARITY_TESTS=1`). Then
  Phase 1.1 — promote the O(p) node-frame gradient via Workflow Q (the first
  load-bearing engine slice; uses the tiered Haiku/Sonnet/Opus model
  assignment).

## Model-tiering note (standing, per maintainer 2026-05-30)

Workflows from here assign models by task difficulty: **Haiku** for
mechanical/well-specified nodes (run-and-report, pattern scans, template
wiring, validity checks), **Sonnet** for moderate-judgment coding/review
(prototype ports, docstrings, pattern-following tests, JET/Allocs/Aqua
interpretation), **Opus** (orchestrator) for architecture, hard
numerical-correctness calls, adversarial-panel verdicts, and the Rose
pre-publish gate. Don't delegate what's cheaper to do in-hand.
