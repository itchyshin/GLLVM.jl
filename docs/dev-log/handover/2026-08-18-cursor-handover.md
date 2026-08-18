# Session Handoff → Cursor: GLLVM.jl post-#253 AGHQ era (2026-08-18)

**Meta:** 2026-08-18 (MDT) · **from** Cursor · **to** Cursor (fresh session, no
inherited chat context) · authored under
`~/shinichi-brain/protocols/handover-skill.md` (`TARGET = cursor`,
`AUTHOR = cursor`), content template `~/shinichi-brain/protocols/handoff.md`,
and `~/.claude/skills/handover-to-cursor/SKILL.md`.

You are **Cursor**, picking up GLLVM.jl in a brand-new chat. You inherit **no**
context from the session that wrote this file. Everything you need is below or
linked from below. Read `AGENTS.md` first, then this file, then reconcile against
live `git` / `gh` before you touch anything.

**Lane this file was written from:** `PLATFORM: cursor` ·
`ON BRANCH: cursor/handover-20260818` ·
`LANE: docs-only 2026-08-18 Cursor handover` ·
`OTHER LANES: cursor/a43-honesty-20260818 (local WIP, no PR) ·
claude/lane-overnight-a43-20260817 (post-merge close `580b5ae4`) ·
Dropbox checkout PROTECTED · Claude main-direct in last 12h`.

---

## Critical Context — read these six or you will go wrong

1. **The Dropbox checkout is PROTECTED.** `/Users/z3437171/Dropbox/Github Local/GLLVM.jl`
   sits on stale `claude/jl-bridge-capabilities-20260619` at **`9f8378aa`**.
   Scout: **nothing legitimate lives there.** Never commit, stage, or check out
   there. All work happens in a fresh worktree cut from `origin/main`.
2. **`origin/main` already has #251–#253.** Tip at write:
   **`3d5acba0`** (merge of #253). PR tip that went into that merge:
   **`06c3ef17`**. Do **not** treat A4(3) eligibility as unpaid. Overnight
   `/goal` A4(3) is **DONE**.
3. **A4(3) honesty follow-up is local WIP only.** Branch
   `cursor/a43-honesty-20260818` at
   `/Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818`.
   **No PR** (re-checked `gh pr list --state open` at write: empty).
   **CARRIED-OVER that branch.** #253 already paid eligibility; do not
   rewrite the lock as if honesty were still unpaid on `main`.
4. **Seven next arcs are proposed, not approved.** The Ada ultra-plan is
   **uncommitted** at
   `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-aghq-stage1b-20260817/docs/dev-log/plans/2026-08-18-seven-arcs-ultraplan.md`
   (**CARRIED-OVER**; do **not** write a second plan). **G0 answers are
   unpaid. Do not execute any of the seven arcs.** Arcs **2 ∩ 3 ∩ 4 ∩ 5**
   all own `src/families/aghq_grid.jl` + AGHQ tests → **serialize**.
5. **Mac-light.** Julia via `~/.juliaup/bin`. Local verify = one focused
   test file. Full suite = **GitHub CI on a PR**. Never `gh pr merge --auto`.
   Never `git add -A`.
6. **Lane pre-flight with the absolute path** before you claim files:
   `~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"`.
   `lane_preflight.sh GLLVM.jl` is a silent no-op.

---

## Goals / mission (the durable "why")

GLLVM.jl is the Julia twin of R's `gllvmTMB`: **as capable as the twin, and
faster**. The Gaussian + phylogenetic path is the headline speed result (~340×
per-fit median on single-σ² Gaussian fits, machine-precision agreement on that
grid). The current programme is *capability breadth*, not speed: closing the
Julia↔twin gap family by family, surface by surface, each behind an Identity
lock before any engine code.

Durable ledger: `docs/design/capability-status.md` and
`docs/dev-log/plans/2026-08-16-gllvmtmb-capability-gap.md`. Family count is no
longer the gap. The live estimator gap is AGHQ: Identity #248, Stage-1a grid
#251, Liu–Pierce adapt #252, A4(3) eligibility lock #253 — both AGHQ ledger
rows stay **`missing`**.

---

## Plans / roadmap (beyond the immediate next steps)

**Cite, do not rewrite.** The seven-arc ultra-plan lives (uncommitted) at:

`/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-aghq-stage1b-20260817/docs/dev-log/plans/2026-08-18-seven-arcs-ultraplan.md`

That file is **CARRIED-OVER** until it lands with this handover or a
follow-up docs PR. **Do not write a second plan.**

G0 answers are **unpaid** (defaults only; do **not** execute arcs):

| Q | Default (unpaid) |
|---|---|
| Q1 | This session = **none of the 7**. Later **2 → 3 → 4**; **5 waits**; 6/7 per Q2. |
| Q2 | **6 and 7 wait** (file-safe ≠ scientifically due). |
| Q3 | After arc 1, next `aghq_grid.jl` owner is **arc 2 then 3 then 4**. |

Collision that still binds regardless of G0: arcs **2 ∩ 3 ∩ 4 ∩ 5**
serialize on `src/families/aghq_grid.jl` + AGHQ tests.

Earlier leftover chips (not this programme's primary engine): Tweedie
`fit_gllvm` stays **STOP** (T2–T5 unpaid); multinomial; coverage
certificate on Totoro/DRAC; truncated_nbinom2 Arc1b; REML `test_reml.jl`.

---

## What Was Accomplished (verified live with `gh` / `git`, not recalled)

`origin/main` tip at write: **`3d5acba0`** (merge of #253).
`git log -8 --oneline origin/main` at write:

```
3d5acba0 Merge pull request #253 from itchyshin/claude/lane-overnight-a43-20260817
06c3ef17 docs(aghq): drop self-signed Rose PASS on A4(3) lock
8d663b99 docs(dev-log): pay #253 after-task without a self-signed Rose PASS
86ded2ef docs(aghq): A4(3) check-log + after-task; LOOP A0/A1/A2 done
b2d646fc docs(decisions): lock AGHQ A4(3) fail-loud gate (Identity-adjacent)
5b4d9666 test(aghq): lock A4(3) fail-loud `_aghq_stage1a_reject_extra` as the gate
b95f0282 lane(overnight-a43-20260817): scaffold LOOP/ kit
17f4a415 Merge pull request #252 from itchyshin/claude/lane-aghq-stage1b
```

| PR | Merge SHA | What landed |
|---|---|---|
| #251 | `fc845404` | **Stage-1a** live-pin grid + `k=1` ≡ Laplace golden |
| #252 | `17f4a415` | **A4(2)** Liu–Pierce adaptation (`k>1`) on that grid |
| #253 | `3d5acba0` (PR tip `06c3ef17`) | **A4(3)** eligibility lock — fail-loud `_aghq_stage1a_reject_extra`; **not** a TMB treewidth port |

Overnight `/goal` A4(3) is **DONE** (merged #253). Hopper still binds:

- Do **not** copy the TMB A4(4) `DATA_` freeze / `n_adapt` loop. Julia already
  re-solves mode + Cholesky at every site eval.
- A4(5) needs a public `aghq=` fitted-object surface. Identity §A3 **forbids
  a stub knob that only errors**.

### Opus MIXED on merged #253 (do not invent a new Δ)

Gate on `main` rejects **declared** extras (`phylo=true`, `row_effects=true`,
`mi=true`, free `s_B` / `unique_latent=true`, `use_lv_B=true`, multinomial).
It does **not** inspect the model. Omitted kwargs never fire the gate.
Affordability (`k^d` / `d ≤ 5`) is still **open**. `#253` `!isdefined`
absence tests record that the helper was **not invented**; they do **not**
close affordability. `false` is inconsistent on the declared-kwargs surface
(`row_effects=false` throws; `unique_latent=false` passes) — later engine,
not a rewrite of the landed lock.

Decision: `docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md`.
After-task: `docs/dev-log/after-task/2026-08-18-aghq-a43-gate.md`.
Tests: `test/test_aghq_gate.jl` (34/34 Mac-light on the overnight lane).

### Earlier era already on `main` (do not redo)

#205, #218, #220, #231, #234, #235, #236, #238, #241–#246, #248, #249, #250,
and **#247 MERGED** `724e297f` (2026-08-17T15:21:59Z). The 2026-08-17 handover
and #250 said #247 was closed unmerged; **live `gh` supersedes that** — the
overnight handoff file
`docs/dev-log/handover/2026-08-17-overnight-surface-handoff.md` **is on
`origin/main`**. Do **not** merge #247 (already merged). Do **not** reopen it.

CI on `main` at write (`gh run list --branch main --limit 4`):

| Run | Conclusion |
|---|---|
| #253 Documenter | **SUCCESS** |
| #253 CI (Julia) | **SUCCESS** (2h15m) |
| #252 Documenter + CI | **SUCCESS** |
| #251 Documenter + CI | **SUCCESS** |

Open PRs at write: **none** (`gh pr list --state open` empty; re-checked
after scout).

---

## Current Working State

- **Working:** `origin/main` @ `3d5acba0`. #251 Stage-1a, #252 A4(2), #253
  A4(3) eligibility are merged. Full Julia + Documenter CI green on that tip.
- **In progress:**
  - **Honesty follow-up** — local uncommitted WIP on
    `cursor/a43-honesty-20260818` (no PR). Four dirty paths; see Landing
    State. This is **CARRIED-OVER**, not unpaid #253.
  - **Seven-arc ultra-plan** — uncommitted at
    `.worktrees/gllvmjl-aghq-stage1b-20260817/docs/dev-log/plans/2026-08-18-seven-arcs-ultraplan.md`.
    **G0 answers unpaid.** Cite; do not write a second plan.
  - Overnight branch `claude/lane-overnight-a43-20260817` has one extra
    pushed commit `580b5ae4` (*close /goal — A4(3) landed as #253*) that is
    **not** on `main`. LOOP kit on `main` still reads as if #253 were open
    — stale; do not "fix" LOOP from this handover lane (honesty owns those
    files).
- **Not working / blocked:**
  - Stale `.git/index.lock` (0 bytes, Aug 16 08:26) in the Dropbox
    checkout. **Shinichi only.** Does not block worktree work.
  - Dropbox uncommitted preview/agents: **PROTECTED, never land.**

---

## Key Decisions & Rationale

| Decision | Where it lives | Why it must still hold |
|---|---|---|
| AGHQ stays `missing`; no stub knob | #248 `docs/dev-log/decisions/2026-08-17-aghq-identity.md` §A3 | An argument that can only error advertises a capability the package lacks. |
| Stage-1a live pin is `.gllvmTMB_aghq_grid` | #251 | Probabilists' nodes; VA `_gauss_hermite` is a different measure. |
| Liu–Pierce adapt is A4(2), not A4(4) | #252 | Site re-solve ≠ TMB freeze loop. |
| Fail-loud declared-kwargs is A4(3) **eligibility** | #253 | Twin warns+Laplace because it already has public `aghq=`. Julia throws. Affordability half still open. |
| Do not port TMB `.aghq_gate` / `spHess` / min-fill | Hopper pin, `R/aghq-gate.R` @ `b926f47f` | Julia AGHQ is a dense per-site `d × d` loadings-only `z_B` block. |
| Tweedie `fit_gllvm` admit = STOP | #234 | T2–T5 unpaid. Engine health (#236/#238) ≠ public surface. |
| Rehydrate via the board's Active-Lane-Split | handover-skill Step 4 multi-lane check | A single `START HERE` orphans the honesty sibling. |
| Identity-before-engine | `docs/dev-log/decisions/2026-08-1*` | Locks the estimand before code can drift it. |
| No invented twin Δ | gap-sheet reading rules | Quote a number only from a live paired run. |

Repo-level rules that bind you regardless: `AGENTS.md` §Design rules,
§Convention-change cascade, §Definition of Done, §Hard boundaries.

---

## Landing State — the git ledger

`handoff_gate.sh` verdict at write: **GATE FAIL — 1 of 1 repo(s) have UNLANDED
state** (25 uncommitted paths on the Dropbox checkout; 36 unpushed commits on
other branches; stale `index.lock`). Every gate item is declared below.
Nothing this handover authored is left undeclared.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` @ `3d5acba0` (#251–#253) | y | y | #251/#252/#253 merged | **LANDED** |
| #247 overnight surface-admit handoff | y | y | [#247](https://github.com/itchyshin/GLLVM.jl/pull/247) **MERGED** `724e297f` 15:21Z | **LANDED** — do not merge again |
| #249/#250 2026-08-17 Cursor handover + #247-disposition correction | y | y | merged | **LANDED** (their #247 "closed unmerged" sentence is **superseded**) |
| Overnight `/goal` close `580b5ae4` on `claude/lane-overnight-a43-20260817` | y | y (that branch) | none (post-merge close; #253 already on `main`) | **CARRIED-OVER** |
| **Honesty WIP** `cursor/a43-honesty-20260818` @ local-scratch, 4 dirty files, **no PR** | n | n | **none** | **CARRIED-OVER** |
| Ada seven-arc ultra-plan (uncommitted) `.worktrees/gllvmjl-aghq-stage1b-20260817/docs/dev-log/plans/2026-08-18-seven-arcs-ultraplan.md` | n | n | none | **CARRIED-OVER** — cite; do not write a second plan |
| This handover: `cursor/handover-20260818`, worktree `.worktrees/gllvmjl-cursor-handover-20260818` | this PR | this PR | open, **do not merge from the agent** | **this slice** |
| Dropbox checkout `claude/jl-bridge-capabilities-20260619` @ `9f8378aa` — preview/agents uncommitted | n | n | none | **PROTECTED — never land** |
| `.git/index.lock` (0 bytes, Aug 16 08:26) | n/a | n/a | none | **CARRIED-OVER — Shinichi only** |
| 36 unpushed commits across ~20 stale branches (gate listing) | y (local) | n | none | **CARRIED-OVER** |
| ~90 `.worktrees/` + `.claude/worktrees/` + local-scratch lanes | mixed | mixed | mixed | **CARRIED-OVER** |

**Why each `CARRIED-OVER` is not landed, and how to resume it:**

- **Honesty `cursor/a43-honesty-20260818`.** Local WIP only. Dirty paths
  (scout + this session):
  `LOOP/arcs.md`, `LOOP/checkpoint.md`,
  `docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md`,
  `test/test_aghq_gate.jl` (comment only on the absence tests).
  *Resume:*
  ```sh
  cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818
  git status -sb && git diff
  ```
  If the WIP is **ready**: named-path commit, push, `gh pr create` (honesty
  docs/comments only). If it is **not** ready: leave it and **wait G0**
  on the ultra-plan. Do **not** treat #253 as unpaid honesty.
- **Seven-arc ultra-plan.** Uncommitted at
  `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-aghq-stage1b-20260817/docs/dev-log/plans/2026-08-18-seven-arcs-ultraplan.md`
  (`??` on `cursor/aghq-stage1b-20260817`, behind `origin/main` by 22).
  *Resume:* read that path; land it with this handover or a follow-up
  docs PR. **Do not write a second plan.** G0 answers remain unpaid.
- **Overnight `580b5ae4`.** Close-out commit after #253 merged. Harmless
  if left off `main`. *Resume only if Shinichi wants LOOP on `main`
  refreshed from that commit:* inspect
  `git log --oneline origin/main..origin/claude/lane-overnight-a43-20260817`
  first. Do not open a second A4(3) PR.
- **`.git/index.lock`.** *Resume:* Shinichi runs
  `rm "/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.git/index.lock"`.
  No agent.
- **36 unpushed stale-branch commits.** Abandoned or superseded. Do **not**
  bulk-push. Gate output:
  `~/shinichi-brain/tools/handoff_gate.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"`
  (~5 min; walks every worktree).
- **Worktrees.** Harmless noise. GC only if Shinichi asks.
- **PROTECTED Dropbox paths.** Scout: nothing legitimate. Read-only.

---

## Next Immediate Steps — classified. Execute **OWED** only.

**Headline:** rehydrate; land honesty WIP `cursor/a43-honesty-20260818`
if ready; **do not** start 2–5 together; **wait G0** on the ultra-plan.

Per `~/shinichi-brain/protocols/handoff.md`: a handoff is a dated state record,
not an instruction to repeat work. Classify, then act.

### OWED — do these, in this order

1. **Rehydrate and confirm the tip / CI.**
   `git fetch origin main && git log -8 --oneline origin/main`
   `gh pr list --state open`
   `gh run list --branch main --limit 4`
   Expect `3d5acba0` or later. Re-check whether the honesty branch has grown
   a PR since this file was written. Read the Active-Lane-Split (every live
   row), then this file's Landing State.
2. **Land honesty WIP `cursor/a43-honesty-20260818` if it is ready.**
   Four dirty files, no PR. #253 already paid eligibility — do not rewrite
   the lock as unpaid. If the WIP is **not** ready, leave it.
3. **Do not start arcs 2–5 together. Wait G0 on the ultra-plan.**
   Cite
   `.worktrees/gllvmjl-aghq-stage1b-20260817/docs/dev-log/plans/2026-08-18-seven-arcs-ultraplan.md`
   — do not write a second plan. G0 answers are unpaid: this session =
   none of the 7; later 2 → 3 → 4; 5 waits; 6 and 7 wait (Q2 default);
   after arc 1 the next `aghq_grid.jl` owner is 2 then 3 then 4.
   Collision: 2 ∩ 3 ∩ 4 ∩ 5 serialize on that file. No 7-way `src/` fan-out.

### DONE — do not redo

#205, #218, #220, #231, #234–#236, #238, #241–#253, #247, #249, #250.
Stage-1a grid, A4(2) Liu–Pierce, A4(3) **eligibility** lock, overnight
`/goal` A4(3). Do not re-derive Hopper's pin. Do not re-port TMB
`.aghq_gate`.

### RETRACTED — do not propagate

- Renaming VA `_gauss_hermite` as AGHQ (#248 §A1/A2).
- A stub `aghq=` / `method = "AGHQ"` that only throws (#248 §A3).
- Copying the TMB A4(4) freeze / `n_adapt` loop (Hopper).
- Treating `#253` `!isdefined(_aghq_kd_bound)` as a closed affordability claim.
- Treating the 2026-08-17 handover's "#247 closed unmerged" sentence as live.
- Phylo Model A public `lv` intervals — `rejected` for advertising.
- Non-Gaussian REML — deliberately `rejected`.
- 7-way parallel `src/` without G0.

### PROTECTED — do not touch

- **Tweedie `fit_gllvm` / `@formula` / bridge surface admit** — shut until T2–T5
  are paid (#234).
- **Inventing a twin `gllvmTMB` light Δ.**
- **The Dropbox checkout** at `9f8378aa` and its uncommitted preview/agents.
- `.git/index.lock` — Shinichi clears it.
- **Honesty lane files** while that WIP is uncommitted, unless you are the
  session that owns `cursor/a43-honesty-20260818`.
- `AGENTS.md` / `CLAUDE.md` edits beyond a Phase-state snapshot line, and
  `.codex/agents/*` / `.agents/skills/*` — maintainer approval required.

---

## Blockers / Open Questions

- **G0 answers are unpaid.** Cite the uncommitted ultra-plan; do not
  execute arcs. Defaults: this session = none of the 7; later 2 → 3 → 4;
  5 waits; 6 and 7 wait; after arc 1 the next `aghq_grid.jl` owner is 2
  then 3 then 4.
- **Honesty WIP has no PR.** Next session decides land-vs-leave after
  reading the dirty diff. Collision: honesty touches the same decision +
  `test_aghq_gate.jl` comments that a later affordability slice will edit.
- **LOOP on `origin/main` is stale** (still says "#253 is open"). Honesty
  already has local LOOP edits. Do not race that lane.
- **`.git/index.lock`** needs Shinichi.
- **`capability-status.md` AGHQ prose** still says (from #248 era) that
  Julia has no `aghq` symbol under `src/` / `test/`. That sentence is
  stale after #251 (`src/families/aghq_grid.jl`). Both **status cells
  stay `missing`**. Fixing the prose is a honesty/docs chip, not a
  ledger promote.
- **Open question for Shinichi:** approve G0 on the seven-arc ultra-plan,
  or land honesty first and keep G0 for a later session?

---

## Gotchas & Failed Approaches

- **`handoff_gate.sh` on this repo takes ~5 minutes.** It walks ~90
  worktrees. It is not hung.
- **`lane_preflight.sh` needs the absolute path.**
- **Do not run `Pkg.test()` locally.** Mac-light. CI is the verifier.
- **Two AGHQ grids exist in the twin and they are not interchangeable.**
  `.gllvmTMB_aghq_grid` (live pin, probabilists') vs `.aghq_grid`
  (peer helper, physicists'). Julia's `_gauss_hermite` is the physicists' rule.
- **`false` ≠ omitted on the A4(3) helper.** Declared `row_effects=false`
  throws; omitted kwargs pass. Blast radius is zero today — nothing public
  calls the site evaluator — but a fitter that forgets to pass flags will
  silently skip the gate.
- **`LOOP/` on `main` is the overnight A4(3) kit**, not a fresh seven-arc
  plan. Do not resume A0–A3.
- **Never `git add -A` / `git add .`.**
- **Never `gh pr merge --auto`.** Merge only after full Julia + Documenter
  SUCCESS, with `gh pr merge N --merge`, and only when Shinichi asks.
- **Never force-push** to rematch a PR; merge `origin/main` into the branch.

---

## Environment — Cursor specifics

Assume nothing about extensions, credentials, or terminal state; verify.

```sh
# 0. Julia is NOT reliably on PATH. juliaup lives here:
export PATH="$HOME/.juliaup/bin:$PATH"
julia --version                     # expect >= 1.10

# 1. Never work in the Dropbox checkout. Cut a worktree from origin/main:
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main
git worktree add ".worktrees/gllvmjl-<lane>-20260818" -b "cursor/<lane>-20260818" origin/main
cd ".worktrees/gllvmjl-<lane>-20260818"

# 2. Lane pre-flight BEFORE claiming files (absolute path):
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
```

**Safe verification command (Mac-light).** One focused test file, never the full
suite:

```sh
julia --project=. --startup-file=no test/test_aghq_gate.jl
# neighbours: test/test_aghq_adapt.jl · test/test_aghq_grid.jl
```

The **full** suite is `julia --project=. -e 'using Pkg; Pkg.test()'` and runs
**only on GitHub CI via a PR**. Coverage / ADEMP / parity campaigns are
**Totoro** (fast CPU ≤100 cores) or **DRAC** (GPU / replicated), per
`~/shinichi-brain/projects/COMPUTE-PLAYBOOK.md`, and only when Shinichi asks.

**Do NOT stage these:**

```
.claude/preview/index.html      .claude/preview/status.json
.claude/preview/sweep.json      .claude/preview/version.txt
.claude/agents/*.md             .cursor/agents/*.md
.codex/agents/*.toml            .codex/agents/tiers.tsv
.worktrees/**                   .claude/worktrees/**
.git/index.lock
```

Stage by explicit path. `git add -A` and `git add .` are forbidden.

**Merging:** `gh pr merge N --merge` after full Julia + Documenter SUCCESS.
Never `--auto`. Never push without an explicit instruction from Shinichi —
except the handover branch itself, which must be pushed so the next session
can read it. **This handover PR must not be merged by the agent.**

---

## Files Created / Modified — this handover

`git diff --name-only origin/main...cursor/handover-20260818` (after commit):

| Path | Change |
|---|---|
| `docs/dev-log/handover/2026-08-18-cursor-handover.md` | **new** — this file |
| `docs/dev-log/coordination-board.md` | Active-Lane-Split refresh (handover + honesty + ultra-plan rows; no single orphaning `START HERE`) + dated Status |
| `AGENTS.md` | Phase-state snapshot prepend only — points at the board, not a single doc |

No `src/`, `test/`, `LOOP/`, or `CLAUDE.md` path is touched. Honesty's four
dirty files are **not** in this diff.

---

## Mission control

| Repo | Branch / tip | CI | What shipped | Plan by leverage |
|---|---|---|---|---|
| **GLLVM.jl** | `main` @ `3d5acba0` (#253; PR tip `06c3ef17`) | Julia + Documenter **SUCCESS** on #251/#252/#253 | #251 Stage-1a grid · #252 A4(2) Liu–Pierce · #253 A4(3) eligibility (declared-kwargs fail-loud). Honesty WIP **local, no PR**. Ultra-plan **uncommitted** (cite only). | **OWED:** rehydrate · land honesty if ready · do **not** start 2–5 together · **wait G0** |
| `gllvmTMB` (R twin) | read-only reference; Hopper pin `R/aghq-gate.R` @ `b926f47f` | — | Public `aghq=`; warn+Laplace on `tw>4` | never engine-surgery from this repo; never invent a Δ |

Both AGHQ ledger rows stay **`missing`**.

---

## How to Resume

Read in this order:

1. `AGENTS.md` (repo rules, Definition of Done, hard boundaries)
2. **this file**
3. `docs/dev-log/coordination-board.md` → **Active Lane Split** (the
   multi-lane pointer; read **every** live row, including the honesty
   sibling — never a single `START HERE` bullet)
4. `docs/design/capability-status.md` and
   `docs/dev-log/plans/2026-08-16-gllvmtmb-capability-gap.md`
5. Binding AGHQ locks, in order:
   `docs/dev-log/decisions/2026-08-17-aghq-identity.md` (#248)
   `docs/dev-log/decisions/2026-08-17-aghq-stage1a-grid.md` (#251)
   `docs/dev-log/decisions/2026-08-17-aghq-stage1b-adapt.md` (#252)
   `docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md` (#253)
6. Tweedie STOP: `docs/dev-log/decisions/2026-08-16-tweedie-fit-gllvm-identity.md`
7. Previous Cursor handover (superseded #247 sentence):
   `docs/dev-log/handover/2026-08-17-cursor-handover.md`

Then reconcile with live state:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"
git fetch origin main && git log -8 --oneline origin/main
gh pr list --state open
gh run list --branch main --limit 4
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
# honesty sibling (CARRIED-OVER):
git -C /Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818 status -sb
```

Then execute **OWED only**.

### One-command resume — paste this into a fresh Cursor agent in this repo

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-18-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

### Which tool does what next

- **Cursor** (you): rehydrate; land honesty WIP **if** ready; do **not**
  start arcs 2–5 together; **wait G0** on the cited ultra-plan. Do not
  write a second plan. This session executes **none** of the seven arcs.
- **Codex** owns live R-twin side-by-side (`gllvmTMB` fit, `R CMD check`,
  an RCall parity cell).
- **Claude** owns ultra-plan / G0 prose and Identity drafting where no
  compiler is required.
- **Totoro / DRAC** own coverage / ADEMP grids. Never laptop-scale, and
  only when Shinichi sizes and asks.
