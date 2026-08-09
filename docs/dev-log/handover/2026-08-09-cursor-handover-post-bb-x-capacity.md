# Session Handoff: Post-#196 / mid-#197 capacity programme snapshot (Cursor)

**Meta:** 2026-08-09 · from Cursor (docs-snapshot session) · to **Cursor** (fresh chat)  
**Repo:** GLLVM.jl · `origin/main` @ `6aa8e0cb` (Merge #196)  
**This branch:** `docs/post-bb-x-capacity-handover-20260809`  
**This worktree:** `.worktrees/gllvmjl-docs-post-bb-x-handover-20260809`  
**Authoring constraint:** docs snapshot only — **do not** implement S2/S3 in the chat that wrote this file.

You are **Cursor**, picking up the post-#192 / post-#196 R–Julia light-parity capacity
programme. You inherit **no chat context**. Rehydrate from files + live git, then
classify every next step `OWED` / `DONE` / `RETRACTED` / `PROTECTED` before acting.

---

## Critical Context

1. **S1 is MERGED.** [#196](https://github.com/itchyshin/GLLVM.jl/pull/196) → `main`
   @ `6aa8e0cb` (2026-08-08). Binomial species-XB light logLik Δ abs ≈ **1.322e-9**
   (seed=49, rtol 1e-6). Gaussian species-XB **skipped** (no Laplace
   `fit_gllvm_speciescov` path). Do **not** redo S1.
2. **S2 is OPEN, not yet on `main`.** [#197](https://github.com/itchyshin/GLLVM.jl/pull/197)
   `feat/betabinomial-grouped-ci-20260808` @ `8112e533` — BetaBinomial grouped(_cov)
   `_family_ci` + lift `_bridge_ci_guard_betabinomial`. Pushed; CI **pending** at
   snapshot cut. **S2 ≠ DONE until #197 MERGED.**
3. **S3 ZIP+X Identity is still unlanded.** No decision file on `main`. Do **not**
   start ZIP engine. Packaging A: wait PR2 merge-on-green → S3 docs-only → STOP.
4. **G0 is LOCKED** — plan
   `docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md` (+ arc card).
   Do **not** re-plan. Do **not** arc-create.
5. **Board / AGENTS / check-log / LOOP were NOT edited by this handover**
   (multi-lane check). #197 **already owns those files**. `main` copies are stale
   (still “S1 landing / waiting PR1”). #197’s copies say “S2 landing / waiting PR2.”
   Treat leftover “waiting PR1” text on `main` as **fiction**.
6. **Worktree collision (gotcha).** The first handover WT
   `.worktrees/gllvmjl-post-bb-x-capacity-handover-20260809` was **retargeted** by a
   sibling to `feat/betabinomial-grouped-ci-20260809` with **dirty uncommitted**
   S2-shaped edits (duplicate of #197). Do **not** commit that stray branch. This
   docs PR lives on a **second clean** WT (path above).
7. **Dropbox checkout is PROTECTED** —
   `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` on
   `claude/jl-bridge-capabilities-20260619`. Never write there. New work =
   `.worktrees/` only.

---

## Goals / mission

Finish the locked post-#192 capacity programme: (1) Species-XB Binomial light cell
**(DONE via #196)**; (2) BetaBinomial grouped / grouped_cov `confint` + lift
`_bridge_ci_guard_betabinomial` **(PR2 #197 OPEN — merge-on-green)**; (3) ACCEPTED
ZIP+X Identity Arc 0 — **docs-only**, no ZIP engine, no ZIP light RCall. Then
board closeout → **STOP**.

Fence: ≠ full family parity ≠ ADEMP ≠ Tweedie+X ≠ ZIP engine ≠ Phylo #127 ≠
full species-B cohort ≠ silent rtol widen ≠ analytic OH for BB grouped CI.

---

## Plans / roadmap (beyond immediate)

After this programme closes: next ladder family / ZIP engine only via **fresh**
arc-creation + new G0. Parked Phylo Model A (#127) — do not orphan, do not resume
here. Twin gllvmTMB ZIP remains cut from 0.2.0 — Identity must stay Julia-forward /
twin-asymmetric.

---

## What Was Accomplished (programme chain through this snapshot)

| Landing | Evidence |
|---|---|
| BetaBinomial+X Identity Arc 0 | #191 @ `d5d61cb7` |
| BetaBinomial+X engine + light | #192 @ `f56befc1`; Δ abs ≈1.50e-8 (seed=49) |
| Post-#192 board/handover hygiene | #193 @ `2f07ad37` |
| Capacity programme G0 + ultra-plan | #194 @ `49056186` |
| Goal-handover → `/goal` | #195 @ `d7f852df` |
| **S1 Species-XB Binomial** | **#196 @ `6aa8e0cb`**; Δ abs ≈ **1.322e-9**; Gaussian skipped |
| S1 after-task + Rose | `docs/dev-log/after-task/2026-08-08-species-xb-binomial.md` — PASS WITH NOTES |
| **S2 BB grouped CI (not on main)** | **#197 OPEN** @ `8112e533`; after-task on that branch `docs/dev-log/after-task/2026-08-09-betabinomial-grouped-ci.md`; focused tests claimed (capabilities 130, grouped_disp 131, mask 89, confint_family 163, bridge_x 248). Full `Pkg.test()` / CI **pending**. |
| Owner G0 locks | programme=yes; Binomial required / Gaussian optional; ZIP+X Identity docs-only; merge-on-green; packaging A |
| This docs snapshot | this file (board/AGENTS **not** edited — #197 owns them) |

CI on #196 merge: **CI success** + **Documenter success** (2026-08-08).  
CI on #197: **pending** at handover cut (Documenter + Julia 1.10/1 matrix).

---

## Current Working State

- **Working:** `origin/main` @ `6aa8e0cb` (#196 MERGED, CI green). S1 complete.
  Binding plan on `main`. LOOP kit on `main` is **stale** (checkpoint still says
  waiting PR1). LOOP on the #197 branch is updated (waiting PR2).
- **In progress:** [#197](https://github.com/itchyshin/GLLVM.jl/pull/197) S2 —
  pushed, CI running, **not merged**. Sibling stray
  `feat/betabinomial-grouped-ci-20260809` dirty in the hijacked handover WT —
  **do not land**.
- **In progress (this PR):** docs-only Cursor handover. No `src/` change.
- **Not working / blocked:** S3 not started (correct until #197 merges). `main`
  board/AGENTS drift vs #197 (known; skipped here).

---

## Active-Lane-Split (carried in this doc — board/AGENTS skipped)

Rehydrate via **this table + live `gh pr list`**, not a single orphaned START HERE.
On `main`, `coordination-board.md` is stale. On #197 it is updated to “S2 landing”
and will become canonical **if/when #197 merges**. This handover must not overwrite
#197’s board/AGENTS.

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **This handover (docs snapshot)** | landing | `docs/post-bb-x-capacity-handover-20260809` from `origin/main` @ `6aa8e0cb` · WT `.worktrees/gllvmjl-docs-post-bb-x-handover-20260809` | **this file** | Snapshot + resume prompt only |
| **S2 BB grouped CI** | **PR #197 OPEN** | `feat/betabinomial-grouped-ci-20260808` @ `8112e533` (pushed); WT `.worktrees/gllvmjl-betabinomial-grouped-ci-20260808`; after-task on branch | #197 + LOOP checkpoint (S2 local DONE / wait PR2) | S2 engine/CI/tests + board/AGENTS/check-log on that PR. **Do not duplicate.** |
| **Stray S2-09 dirty tree** | **CARRIED-OVER / discard** | `feat/betabinomial-grouped-ci-20260809` dirty inside `.worktrees/gllvmjl-post-bb-x-capacity-handover-20260809` (hijacked first handover WT) | none | Duplicate S2 edits. Do **not** commit or PR. |
| **Post-#192 capacity programme (S1)** | **MERGED** #196 | `main` @ `6aa8e0cb` | after-task `2026-08-08-species-xb-binomial.md` | S1 done. |
| **Post-#192 ultra-plan G0** | **MERGED** #194 | `main` @ `49056186` | `docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md` | Binding G0. Closed. |
| **Goal handover** | **MERGED** #195 | `main` @ `d7f852df` | `docs/dev-log/handover/2026-08-07-cursor-handover-post-bb-x-goal.md` | Superseded as execute pointer by **this** file + #197 + live git |
| **BetaBinomial+X engine** | **MERGED** #192 | `main` @ `f56befc1` | after-task `2026-08-05-betabinomial-x-engine-arc12.md` | Closed. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed | `docs/dev-log/handover/2026-06-30-codex-handover.md` | Do not orphan. **PROTECTED** here. |
| **Dropbox checkout (stale fork)** | **PROTECTED** | `claude/jl-bridge-capabilities-20260619` | — | Never write. |

**Other lanes' rolling deferred menus (carry-forward, do not drop):** Phylo #127
parked; ZIP/ZINB/hurdle **engine**; Tweedie+X; ADEMP/coverage; full species-B
cohort; Takahashi O(p) selinv as default next; foreign unpushed branches
(ignore).

---

## Key Decisions & Rationale

- Handover → ultra-plan G0 (#194) → `/goal` execute (#195/#196/#197). **Do not re-interview G0.**
- Packaging **A**: serial S1 → merge → S2 → merge → S3 → merge → STOP.
- Species-XB: Binomial required; Gaussian optional under-run — **skipped** on S1
  (honest; no speciescov Gaussian Laplace path).
- BB CI mirrors NB1/Beta `_family_ci`; thread trials `N` (data, not on fit); FD
  Hessian (BB Laplace has no OH); lift `_bridge_ci_guard_betabinomial` after Julia
  confint smoke. #197 deletes the guard; BB joins `_BRIDGE_MASK_CI_FAMILIES`.
- ZIP+X Identity = docs-only; twin ZIP cut — no fake twin Δ.
- Tweedie+X rejected as Identity default (twin fail-loud).
- Multi-lane: #197 already edits `AGENTS.md`, `coordination-board.md`,
  `check-log.md`, LOOP. This handover **skips** those files so a single pointer
  cannot orphan the S2 PR. After #197 merges, S3 closeout owns the next pointer
  refresh (point past this programme).
- Identity-before-engine remains load-bearing (#174 / #185 / #191 / S3).

---

## Landing State

`tools/handoff_gate.sh` on the old S1 WT (pre-handover): **GATE FAIL** — many
unpushed commits on **foreign** branches (gamma-x, phylo, fam-zip, codex/*,
formula specs, Dropbox checkout branch, …). Same class as prior handovers:
**CARRIED-OVER / ignore**. Not this lane. Do not rebase or delete.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `main` @ `6aa8e0cb` (#196 S1) | y | y | #196 MERGED | **LANDED** |
| Ultra-plan + arc card (#194) | y | y | #194 MERGED | **LANDED** |
| Goal handover (#195) | y | y | #195 MERGED | **LANDED** |
| S2 `feat/betabinomial-grouped-ci-20260808` @ `8112e533` | y | y | **#197 OPEN** | **CARRIED-OVER (await merge-on-green)** — why: CI pending; not on `main`. Resume: `gh pr view 197`; merge when green. |
| Stray `feat/betabinomial-grouped-ci-20260809` dirty | n | n | none | **CARRIED-OVER / discard** — why: duplicate S2 in hijacked WT. Resume: do not commit; leave or reset only if you own that WT and #197 is the real S2. |
| This handover: `docs/post-bb-x-capacity-handover-20260809` | y (this PR) | with this PR | this PR | **landing with handoff** |
| Foreign unpushed branches (gate FAIL list) | mixed | n | — | **CARRIED-OVER / ignore** |
| Dropbox checkout | mixed / stale | n | — | **PROTECTED** — never write |
| Stale S1 WT `.worktrees/gllvmjl-post-bb-x-capacity-20260808` | n/a | n/a | merged | **CARRIED-OVER / GC later** |

---

## Files Created / Modified

**This handover PR (only):**

- `docs/dev-log/handover/2026-08-09-cursor-handover-post-bb-x-capacity.md` (this file)

**Explicitly not modified (multi-lane — #197 owns them):**

- `docs/dev-log/coordination-board.md`
- `AGENTS.md`
- `docs/dev-log/check-log.md`
- `lanes/post-bb-x-capacity-20260807/LOOP/*`
- any `src/` / `test/`

**Prior / sibling files the next session must read:**

- Binding plan `docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md`
- Arc card `docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme-arc-card.md`
- LOOP on **#197 branch** (not stale `main`): `lanes/post-bb-x-capacity-20260807/LOOP/`
- S1 after-task `docs/dev-log/after-task/2026-08-08-species-xb-binomial.md` (on `main`)
- S2 after-task `docs/dev-log/after-task/2026-08-09-betabinomial-grouped-ci.md` (**on #197 only** until merge)
- Prior execute handover `docs/dev-log/handover/2026-08-07-cursor-handover-post-bb-x-goal.md`

---

## Next Immediate Steps (classify against **live git** before acting)

| # | Step | Class | Notes |
|---|---|---|---|
| 0 | Fresh Cursor: read `AGENTS.md` + **this file**; `git fetch`; `gh pr list`; compare to `origin/main` | **OWED** (rehydrate) | Always. #197 may have merged since this snapshot. |
| 1 | Merge **this** handover PR when Documenter green | **OWED** (human / docs self-merge) | One new file; low conflict with #197. **Prefer leave open** until Documenter green; do not merge if CI red. |
| 2 | Watch / merge **#197** on CI green (S2) | **OWED** (programme) | Do **not** start a second S2. If #197 already MERGED → mark **DONE**. If CI red → fix on `feat/betabinomial-grouped-ci-20260808` only. |
| 3 | Continue `/goal` **S3** ZIP+X Identity docs-only → PR3 → merge-on-green | **OWED** | After #197 merged (preferred). Fresh `.worktrees/` from `origin/main`. Zero `src/` ZIP engine in the S3 diff. |
| 4 | Board START HERE + AGENTS snapshot + check-log + Actuals + LOOP → **STOP** | **OWED** | Ride PR3 or tiny docs closeout. #197 already moved pointers to “S2 landing”; S3 closeout must move them **past** this programme. |
| 5 | Re-plan / `/ultra-plan` / `/arc-creation` for this programme | **RETRACTED** | G0 locked #194. |
| 6 | Redo S1 Binomial species-XB / Gaussian under-run | **DONE** / skip | #196; Gaussian explicitly skipped. |
| 7 | Re-implement S2 `_family_ci` / guard lift | **DONE on #197 branch** / **OWED merge** | Do not rewrite. Merge or fix CI only. |
| 8 | Land stray `feat/betabinomial-grouped-ci-20260809` | **RETRACTED** | Duplicate of #197. |
| 9 | ZIP / ZINB / hurdle **engine**, ZIP bridge X, ZIP light RCall | **PROTECTED** | STOP. Fresh G0 only. |
| 10 | Write Dropbox checkout `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` | **PROTECTED** | Stale cherry-pick. |
| 11 | ADEMP / coverage campaign | **PROTECTED** | Out of programme. |
| 12 | Tweedie+X Identity or engine | **PROTECTED** | Twin fail-loud; rejected default. |
| 13 | Resume Phylo Model A PR #127 | **PROTECTED** | Parked; do not orphan; do not resume here. |
| 14 | `git add -A` / `git add .` | **PROTECTED** | Stage by name only. |

**Primary OWED after rehydrate:** if #197 still open → wait/merge-on-green → S3 → closeout → STOP.  
**Primary OWED if #197 has landed:** S3 ZIP+X Identity docs-only → closeout → STOP.  
**Do not re-plan. Do not arc-create. Do not start ZIP engine.**

---

## Blockers / Open Questions

- **#197 CI** is the open gate for S2. Snapshot cut: all checks **pending**. Do not
  claim S2 green without `gh pr view 197 --json state,mergeable,statusCheckRollup`
  (or equivalent).
- **Multi-lane:** stray dirty `feat/betabinomial-grouped-ci-20260809` can confuse
  `git worktree list`. Detector: that WT’s branch name ≠ `docs/post-bb-x-…`.
- `main` LOOP checkpoint still says “waiting PR1” — fiction; #197 branch is truth
  until merge.
- None blocking G0. Merge-on-green was pre-approved for programme landings once
  PRs exist and CI is green.

---

## Gotchas & Failed Approaches

- **Worktree hijack:** creating `.worktrees/gllvmjl-post-bb-x-capacity-handover-20260809`
  on a docs branch, then a sibling `git checkout -b feat/…` inside it, silently
  retargeted the WT. Always `git branch --show-current` + `git status` after
  `worktree add` before committing. This PR used a **second** clean WT
  `.worktrees/gllvmjl-docs-post-bb-x-handover-20260809`.
- `gh pr merge` can exit non-zero on a local `main` worktree conflict while still
  merging remotely — verify with `gh pr view --json state,mergedAt,mergeCommit`.
- VitePress fails on unresolved Documenter `@ref` left as `./@ref` — prefer plain
  backticks for ambiguous multi-method refs.
- Twin ZIP cut from gllvmTMB 0.2.0 — do not invent a twin Δ for ZIP Identity.
- Never widen rtol. Never `git add -A`. Never write the Dropbox checkout.
- Ignore foreign unpushed branches; do not rebase or delete them in this lane.
- S1 WT `.worktrees/gllvmjl-post-bb-x-capacity-20260808` is **not** the S2
  workspace. S2 WT is `.worktrees/gllvmjl-betabinomial-grouped-ci-20260808`.
- `fit_gllvm_speciescov` is Laplace non-Gaussian only — Gaussian species-XB skip
  was correct, not a miss.
- Two concurrent Julia `Pkg.test()` processes GC-thrash a 16 GB VM — single-process
  only (Cloud / small hosts).
- `handoff_gate.sh` will keep FAIL-ing on foreign unpushed branches; declare them
  CARRIED-OVER / ignore rather than landing the whole estate.
- #197 after-task / board / AGENTS exist **only on that branch** until merge —
  `origin/main` will not show them yet.

---

## How to Resume (Cursor)

**Environment**

- Working directory: a **`.worktrees/`** checkout. For S3: fresh WT from
  `origin/main` **after #197 merges** (or from `6aa8e0cb` only if #197 still
  open and you are **not** touching S2 files). Do **not** use the Dropbox
  protected tree. Do **not** reuse the hijacked
  `gllvmjl-post-bb-x-capacity-handover-20260809` WT (it is on stray S2-09).
- Julia: `~/.juliaup/bin/julialauncher` (or `julia` if on PATH). Compat ≥ 1.10.
- S2 verify (if fixing #197 CI): focused tests named in the S2 after-task; then
  `Pkg.test()` if claiming programme-green. Parity env not required for S2/S3.
- Safe verify:  
  `git fetch origin && git log -1 --oneline origin/main && gh pr list --repo itchyshin/GLLVM.jl --state all --limit 12 && gh pr view 197 --repo itchyshin/GLLVM.jl`
- Never stage: Dropbox checkout files; `.worktrees/` contents; foreign branches;
  stray S2-09 dirty files; another agent’s uncommitted work.

**Read order**

1. `AGENTS.md` (`main` may be stale; #197 branch has S2 snapshot)
2. **This handover**
3. Binding plan `docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md`
4. `gh pr view 197` + S2 after-task on that branch
5. LOOP `lanes/post-bb-x-capacity-20260807/LOOP/{GOAL,checkpoint,ultra-plan}.md`
   (prefer #197 branch)
6. `docs/dev-log/coordination-board.md` (prefer #197 branch; compare to split above)

**Who does what next**

- **Cursor (fresh agent):** rehydrate → classify → execute only **OWED** (merge
  watch #197, then S3 docs-only). Live Julia toolchain available.
- **S2 sibling / #197 author:** owns BB grouped CI until merge.
- **Claude:** prose/Rose fence for S3 Identity if routed there.
- **Codex:** not required for remaining rungs (S3 is docs).
- **Human:** merge this docs PR when Documenter green; merge #197 on green; then
  S3 PR.

**One-command paste (human’s authenticated Cursor chat):**

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-09-cursor-handover-post-bb-x-capacity.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

Optional `/goal` paste after #197 merges (not a re-plan):

```text
/goal

Execute the remaining LOCKED post-#192 capacity rung in
docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md.
Rehydrate first from docs/dev-log/handover/2026-08-09-cursor-handover-post-bb-x-capacity.md.
S1 (#196) DONE. S2 (#197) should be MERGED — verify live git before acting.
Order: S3 ZIP+X Identity docs-only → merge → board closeout → STOP.
Do not re-plan. Do not arc-create. Fences: ≠ ZIP engine ≠ ADEMP ≠ Tweedie+X ≠ Phylo #127 ≠ git add -A ≠ Dropbox tree.
```

---

## Mission control

| Field | Value |
|---|---|
| Repo | `itchyshin/GLLVM.jl` |
| `origin/main` | `6aa8e0cb` — Merge #196; CI + Documenter green |
| Open programme PR | [#197](https://github.com/itchyshin/GLLVM.jl/pull/197) S2 @ `8112e533` (CI pending) |
| This branch | `docs/post-bb-x-capacity-handover-20260809` |
| What shipped on `main` | S1 Binomial species-XB Δ≈1.322e-9; G0 locked; BB+X engine #192 |
| What this PR ships | Durable Cursor handover only |
| Board / AGENTS | **skipped** (#197 owns them) — split lives in this doc |
| Plan by leverage | Merge #197 on green → S3 Identity docs → closeout STOP |
| Rose fence | snapshot ≠ S2 on main ≠ S3 done ≠ ZIP engine ≠ full family parity ≠ ADEMP |
