# Ultra-plan — honest-0.7 with Destination B headline (frozen gllvmTMB 0.7.0)

**Date:** 2026-09-14  
**Platform:** Cursor (Composer orchestration; read-only Phases 0–2)  
**Authority:** `/ultra-plan` + `~/shinichi-brain/skills/ultra-plan/SKILL.md` · Cursor adapter  
**Status:** **STOP AT G0** — plan only; no Phase 3 execution in the planning chat. After approval, hand off via `/goal` (`LOOP/GOAL.md`).

---

```
🎯 GOAL
Solo platform: Cursor (this session). Lane claim: planning/docs only —
  `docs/dev-log/plans/2026-09-14-honest-070-destination-b-ultraplan.md`, `LOOP/ultra-plan.md`
  pointer refresh. Do NOT touch foreign Cursor engine lanes (16 live on shared Dropbox checkout;
  Shannon preflight 2026-09-14).
Deliverable: Earned-evidence path to *honest* true parity vs frozen gllvmTMB 0.7.0
  (`b4d5fee64def88bc768dda1f1f77c29b295edd86`) for Destination B’s **admitted** 32-row scope
  (plus programme fences in `true-parity-decision-map.md`), then a **joint maintainer decision**
  on whether `Project.toml` may move toward `0.7.0` — not a marketing bump, not “Arc 0 wrappers = done.”
HEADLINE: Close the **DestB numerical + scope ledger** (dispositions or receipts on every reconciled
  row; `FINAL-REVIEW` last) while finishing the **7-cell covariance grid** beyond thin Arc 0 scaffolds
  where Rose requires it — only then is a version proposal honest.
IN PARALLEL (post-G0): LOOP grid arcs (#14–#15 kernel dep/latent if not already on main); T13/T14/T15
  mechanical second-order hygiene; advisory Frozen-R smoke (#323) on Codex/Totoro; capability-status
  promotion passes (Rose) separate from Arc 0 merges.
DEFER:
  - `Project.toml` version bump, General registration, public “0.7 shipped” wording.
  - Full Core070 497-row ledger re-campaign (superset of DestB; track via programme map, not this headline).
  - gllvmTMB engine surgery; two-directional qualification claim (T1).
  - S4 probe until recorder is fetchable **and** maintainer authorises.
  - Realistic-size grid + real-data T4/T7 until compute + gllvmTMB #1236 gates clear.
DISCIPLINE: verify=ledger gates + `Pkg.test()` / named parity cells before any claim promotion ·
  compute=Totoro-first (D-50; D-139 estimate before campaigns) · closure=joint decision note +
  Rose/Fisher sign-off on DestB-admitted rows, then maintainer-only version decision.
```

**ARC PROGRAM:** N/A (no Arc Card). Operational tracker: `LOOP/arcs.md`, immutable fence: `LOOP/GOAL.md`.  
**Do not confuse:** overnight **honest-0.7 covariance Arc 0 grid** (15 cells, thin Gaussian wrappers) ≠ **Destination B gates** (32-row scope, B1/S3b/S4, `API-BOUNDARY`, `FINAL-REVIEW`).

---

## Phase 0.2 — Lane preflight (Shannon)

**Command:** `~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"`

**Verdict (2026-09-14):** **FOREIGN LANE ACTIVE (cursor direct-to-main)** — 16 lanes live; shared Dropbox checkout with 17 branch switches / 16 uncommitted paths; **this plan slice does not claim engine files.**

**STATE LINE:** PLATFORM: Cursor | ON BRANCH: planning-only (read `origin/main`) | LANE: ultra-plan G0 docs | OTHER LANES: many cursor `cursor/*-070-20260914` + main-direct commits.

**Evidence-first repo head (local):** `cd07f224` on `cursor/kernel-latent-070-20260914` (0 ahead, 2 behind `origin/main`).  
**`origin/main` HEAD:** `23fd0496` (docs handoff #335); merges include #318 DestB closeout, #321 LOOP, #324–#334 Arc 0 grid.  
**CI (sample):** Documenter + pages green on recent main pushes (`gh run list --limit 3`, 2026-09-14).

---

## Phase 0.25 — Prior-work sweep receipt (mandatory)

| Surface | Evidence command | Finding | Call |
|---|---|---|---|
| **Repo git state** | `git status -sb`; `git log origin/main --oneline -15`; `bash ~/shinichi-brain/tools/branch_drift_check.sh` | `origin/main` advanced through DestB #318 merge + 7 Arc 0 PRs; local checkout foreign/busy; drift 0 ahead / 2 behind | **Resume** from `LOOP/checkpoint.md` + `origin/main`, not stale 2026-09-13 “#318 unmerged” narrative |
| **Twin / sister** | `gh pr view 318 --json state,mergedAt`; gllvmTMB `git branch -a \| grep s4`; `git log codex/destination-b-s4-phylo-dep-formula-20260910 -1` | #318 **MERGED** 2026-09-14T02:17:35Z; S4 recorder commit `97214679c` exists **locally** on gllvmTMB branch, **`branch not on origin`** | **Reuse** frozen oracle pin; **coordinate** gllvmTMB push before S4 |
| **Brain** | MCP `search_notes` query `"GLLVM.jl Destination B honest 0.7 parity frozen gllvmTMB b4d5fee"` `search_all_projects: true`; `grep -in "destination b\|destb\|honest.0.7" ~/shinichi-brain/memory/AGENT_LOG.md \| tail -15` (empty tail); vault MEMORY/raw_memories hits | DestB = true parity vs **frozen 0.7.0**, not 0.7.1; version = parity level (D-183 family) | **Reuse** `docs/dev-log/decisions/2026-09-13-honest-070-parity-aim.md` |
| **Repo docs/code** | `graft ask "Destination B scope B1 S3b S4 honest 0.7 parity" --source`; `git show origin/main:Project.toml \| head -5`; `test -f test/test_destination_b_adapter_consumer.jl` | G1/G2 closeout + G1 matrix on main; `version = "0.3.0"`; S3b consumer test file present (52 lines in tree; run receipt 97/97 in closeout) | **Reuse** DestB artefacts; **build gap** on remaining scope rows |
| **Deterministic log** | `grep -in "PR #318" docs/dev-log/check-log.md \| tail -5` | Merge + board updates recorded | **Resume** post-#318 programme |

**Verdict:** **Reuse + resume** — DestB G0/G1/G2 landed on main; honest-0.7 **Arc 0 grid mostly merged**; genuine gaps = DestB rows 5–7 (`B1-RECOVERY`, `API-BOUNDARY`, `FINAL-REVIEW`), S4 (held), capability **promotion** vs **planned** ledger drift, second-order T-items, joint decision note, version fence.

---

## Already done — live verification (cite)

| Claim | Live evidence (2026-09-14) |
|---|---|
| DestB G0 reconcile + G1 matrix | On `origin/main`: `docs/dev-log/2026-09-13-destination-b-g1-audit-matrix.md`, `docs/dev-log/decisions/2026-09-08-destination-b-g0-authorisation.md`, `tools/destination_b_scope_check.mjs` (graft: `destination_b_scope_check.mjs`) |
| B1 **closed-as-limit** | `docs/dev-log/decisions/2026-09-13-destination-b-b1-close-as-limit.md`; `docs/dev-log/2026-09-13-destination-b-g2-closeout.md` §1 |
| S3b **97/97** | Closeout §2 + `test/test_destination_b_adapter_consumer.jl` on main (adapter/test-scope fence explicit) |
| Closeout **#318 on main** | `gh pr view 318` → `state: MERGED`, `mergedAt: 2026-09-14T02:17:35Z`; check-log merge entries |
| Overnight Arc 0 wrappers | `LOOP/arcs.md` #9–#13 **done** on main (#324–#331); #14–#15 kernel dep/latent **next** (checkpoint: #334 merged kernel_latent @ `cd07f224` / main `9cb279e5`) |
| **LOOP #321** | `LOOP/checkpoint.md`: PR #321 **MERGED** |
| S4 **held**; recorder unpushed | g2-closeout §3; gllvmTMB `97214679c` on local branch only (`origin/codex/destination-b-s4-phylo-dep-formula-20260910` **absent**) |
| Advisory R smoke **OWED #323** | `gh issue view 323` → OPEN, title advisory Frozen R 0.7.0 smoke |
| **Project.toml still 0.3.0** | `git show origin/main:Project.toml` → `version = "0.3.0"` |

**Stale narrative guard:** `LOOP/ultra-plan.md` (2026-09-13) still describes #318 as unmerged — **superseded by this plan + `LOOP/arcs.md`**.

---

## Phase 0.6 — Route check (mandatory, in writing)

1. **Destination in one sentence?** Yes — see 🎯 GOAL: honest true parity for DestB admitted rows vs frozen 0.7.0, then joint version decision.
2. **Slice list full of “depends what we decide”?** No — remaining work is **sequenced execution** with **three maintainer G0 questions** (B1 permanence, S4 push/probe, compute host). Paused slices are named, not TBD-shaped.
3. **Every slice has a concrete output path?** Yes — receipts, ledger rows, PR merges, issue close, or decision markdown under `docs/dev-log/`.

**Route:** **Knowable → Phase 1 decomposition below.** (Not a wayfinder decision map refresh — `true-parity-decision-map.md` already exists; this plan **executes** its DestB headline subset.)

---

## WHAT THE BRAIN ALREADY KNOWS

- **Frozen oracle:** gllvmTMB 0.7.0 @ `b4d5fee64def88bc768dda1f1f77c29b295edd86` (DestB + core070 tooling pins; graft constants under `tools/destination_b/`).
- **Version semantics:** D-183 family — Julia version signals **parity earned**, not R release calendar (`docs/dev-log/decisions/2026-09-13-honest-070-parity-aim.md`).
- **Claim direction:** T1 one-directional (R workflow → Julia); reverse list is gllvmTMB lane (`true-parity-decision-map.md`).
- **S4 blocker:** Recorder commit local-only in gllvmTMB; probe **NOT AUTHORIZED** without push + fresh sign-off.
- **Harness vs true parity:** `docs/src/gllvmtmb-parity.md` — Arc 0 / bridge smoke ≠ DestB `FINAL-REVIEW`.

## WHAT SHINICHI TOLD US (durably recorded)

- Do **not** bump to 0.7 yet; **earn** parity first (2026-09-13 decision doc).
- DestB session: B1 close-as-limit, S3b evidence, **S4 HOLD** (g2-closeout authority block).
- Cursor Ultra: prefer **Cursor Models (Composer)** for bounded slices; hand heavy R/compute to Codex/Totoro when executing.

## TEAM RAISED (compact)

```
TEAM RAISED
  Fisher — DestB B1 closed-as-limit is a valid *disposition* but weakens second-order grouping
    evidence · matters for whether B1-RECOVERY is required before FINAL-REVIEW · recommend
    permanent accept + explicit “no Wald from frozen capture” fence · Q: see G0 Q1 · default: accept limit
  Rose   — Arc 0 merges leave capability-status.md at `planned` while code exists · public claim
    drift if promoted early · recommend promotion only with test receipt + scope boundary per cell ·
    default: docs pass before `implemented`
  Gauss  — Kernel/spatial/dep Arc 0 paths are Gaussian-scaffold or fail-loud · non-Gaussian dep rows
    remain future · recommend label Arc 0 honestly in promotion · default: no `implemented` without family scope
  Ada    — Sequence: finish LOOP grid → DestB API-BOUNDARY/FINAL-REVIEW → second-order T13–T15 hygiene →
    optional B1-RECOVERY if Fisher insists → joint decision note → *then* ask for 0.7.0 bump
```

## ADA'S RECOMMENDATION

Treat **Destination B** as the **gating headline** for any future `0.7.0` version talk: the programme completes when (a) all **32-row DestB scope** items are receipted or maintainer-dispositioned, (b) **`FINAL-REVIEW`** passes with Rose/Fisher, (c) honest-0.7 **covariance grid** has no silent `planned` cells *for the 0.7 decision* (either promoted with evidence or explicitly waived in the joint note), and (d) a **single joint decision markdown** attaches the evidence table — **without** editing `Project.toml` in the same PR.

Continue **LOOP** for the 15-cell grid (execution tracker); use **`.unlazy/honest-070-destb/`** for post-G0 gate receipts on DestB + promotion slices.

## DECISIONS LOCKED (do not re-litigate without Shinichi)

- Oracle stays **0.7.0** until second-order contract + re-freeze gate (T2).
- **No** `Project.toml` bump in this programme until joint decision after FINAL-REVIEW.
- **No** S4 probe without authorisation + fetchable `97214679c`.
- **No** gllvmTMB engine edits from GLLVM.jl lane.
- B1 **CLOSED — INTERFACE LIMIT** recorded 2026-09-13 (pending G0 Q1 permanence).
- T1 one-directional claim; T3 second-order scope (SE + vcov block + Wald endpoints).

## QUESTIONS STILL OPEN (≤3 for Shinichi — Phase 0.4)

See **Phase 0.4 G0 packet** below (exactly three).

## PRE-AUTHORISED AFTER G0 ENVELOPE

```
PRE-AUTHORISED AFTER G0: scoped edits on a named branch/worktree; routine local commands;
  focused tests (`julia --project=. test/runtests.jl` subsets, DestB test files, LOOP docs);
  local commits by path; graft/brain queries; gh read-only; checkpoint updates under LOOP/ and
  docs/dev-log/check-log.md.
OPTIONAL REMOTE AUTHORITY: push a named feature branch; open **draft** PR — never merge/release.
MUST STOP: Project.toml version change; S4 probe; gllvmTMB engine edits; public capability promotion /
  README parity claims; merge to main; Totoro/DRAC campaigns without D-139 estimate + compute-routing skill;
  edits to files owned by foreign live lanes (preflight list) without Shinichi ownership call.
```

---

## Phase 0.4 — G0 questions for Shinichi (max 3, with recommendations)

### Q1 — Accept B1 **closed-as-limit** permanently for DestB?

- **WHY NOW:** `FINAL-REVIEW` must treat B1 as settled or reopen expensive R capture work.
- **TEAM VIEW:** Fisher — disposition is scientifically honest; recovery cannot run on frozen out-of-pipeline rebuild. Rose — ensure no doc implies Julia curvature failure.
- **RECOMMENDATION:** **Accept permanently** for DestB; keep `B1-RECOVERY` **NOT AUTHORIZED** unless you explicitly reopen grouping Wald evidence later.
- **IF YOU DO NOT MIND:** Accept limit; proceed to API-BOUNDARY/FINAL-REVIEW with B1 rows frozen.
- **WHAT CONTINUES:** API-BOUNDARY static work; LOOP grid; T13–T15.

### Q2 — Authorize pushing gllvmTMB **S4 recorder** + later **S4 probe**?

- **WHY NOW:** Probe is blocked physically (`97214679c` not on remote) and by authority (held).
- **TEAM VIEW:** Rose — probe is narrow but public-formula sensitive; push is read-only reference repo **coordination**, not engine surgery. Fisher — probe is evidence for A14/A15 mapping, not full DestB alone.
- **RECOMMENDATION:** **Authorize push only** (gllvmTMB branch to origin) in G0; **defer probe authorisation** to a second explicit yes after push verified (`git cat-file -t 97214679c` in GLLVM.jl worktree).
- **IF YOU DO NOT MIND:** No push, no probe; S4 stays **HELD** through FINAL-REVIEW with documented blocker.
- **WHAT CONTINUES:** All non-S4 DestB rows; honest-0.7 grid.

### Q3 — **Totoro vs DRAC** for recovery / realistic-size cells (B1-RECOVERY if reopened, T4 grid)?

- **WHY NOW:** D-50 + compute-routing skill require host at scope time; B1-RECOVERY and T4 are blocked without it.
- **TEAM VIEW:** Gauss — Julia ForwardDiff fits are RAM-heavy; prefer Totoro interactive smoke then Slurm array. Fisher — multi-seed recovery needs stable fleet.
- **RECOMMENDATION:** **Totoro first** for smoke + D-139 sizing; **DRAC (nibi)** for large parallel grids once `--time` sized from `seff` (SLURM doc).
- **IF YOU DO NOT MIND:** Totoro-only; defer DRAC until a campaign justifies queue wait.
- **WHAT CONTINUES:** Non-compute slices (docs, static API-BOUNDARY, T13 flip, advisory smoke scoping).

---

## Phase 1–2 — Slice table (post-G0 execution via `/goal`)

**Estimate:** ~3–5 Cursor sessions (Composer slices) + 1 Codex/Totoro session for #323 smoke + optional 1 compute session (B1-RECOVERY **if** reopened) · **does not fit one chat** · hand off at each LOOP arc merge.

**SCOUT SUITABILITY:** yes — recon on capability-status vs `src/` exports, DestB row checker, ledger drift (Composer / Cursor Models).

| ID | Slice | Bar | Member · model | Dep | Output |
|---|---|---|---|---|---|
| R0 | Rehydrate LOOP checkpoint from `origin/main`; refresh `LOOP/GOAL.md` checkboxes (#318 done) | Cursor Models | Ada · Composer | — | `LOOP/checkpoint.md`, updated GOAL checks |
| G1 | **API-BOUNDARY** (32-row DestB): static boundary audit vs `destination_b_scope_check.mjs` | Cursor Models | Hopper+Rose · Composer | R0 | `docs/dev-log/after-task/…-destb-api-boundary.md` |
| G2 | **Capability promotion pass**: align `docs/design/capability-status.md` with Arc 0 merges (7 cells) — Rose fence per cell | Other Models | Rose · Auto Cost review | G1 | PR docs-only or combined with engine follow-ups |
| G3 | **LOOP #14–#15** kernel dep/latent (if not complete on main): Arc 0 or fail-loud + tests | Cursor Models | Julia-engineer · Composer | R0 | Merged PR + LOOP arc done |
| G4 | **T13** `mi()` row flip with test receipt | Cursor Models | Emmy · Composer | — | capability row + check-log |
| G5 | **T14** NB2 Wald NaN (F1/F2/F3 subset per decision) | Cursor Models | Fisher+Gauss · Composer | — | fix + test + decision note |
| G6 | **T15** knife-edge fixture audit (list first) | Cursor Models | Curie · Composer | — | `docs/dev-log/…-t15-fixture-audit.md` |
| G7 | **Advisory Frozen R smoke** (#323) — NB2 + Student-t gradient health | hand off | Codex/Terra · gllvmTMB read-only build | G0 Q3 host | Issue comment + dev-log; optional CI advisory green |
| G8 | **B1-RECOVERY** (optional) | hand off | Curie · Totoro/DRAC | G0 Q1 reject limit **or** Q3 | Campaign receipt or N/A disposition |
| G9 | **S4**: push recorder (gllvmTMB) → fetch → probe **if** Q2 probe yes | hand off | Hopper · Codex | G0 Q2 | gllvmTMB push + DestB S4 receipt or HOLD update |
| G10 | **FINAL-REVIEW** DestB + honest-0.7 programme | Other Models | Rose+Fisher · Auto Cost / pinned | G1,G2,G3,G4–G6,G7,G8,G9 | Sign-off memo + `docs/dev-log/decisions/…-joint-070-decision.md` |
| G11 | **Joint 0.7.0 decision note** (proposal only — **no** version bump) | Other Models | Ada · Auto Cost | G10 | `docs/dev-log/decisions/…-joint-070-version-proposal.md` |
| V1 | **MECHANICAL-VERIFY**: scope script + focused tests | Cursor Models | Curie · Composer | each batch | gate EVIDENCE lines |
| RC | **Melissa reconcile** plan vs actual | Other Models | Melissa · medium | G11 | `docs/dev-log/plan-actual/2026-09-14-honest-070-destb.md` |

**FAN-OUT BUDGET (post-G0):** checkpoint=`honest-070-destb` · new children ≤6/batch · ceiling 1 (Rose/Fisher panel at G10) · reuse LOOP serialisation for grid arcs.

**REVIEW (plan critique):** Rose — sweep receipt present; FINAL-REVIEW not before API-BOUNDARY. Fisher — B1 disposition consistency.

---

## Phase 2.5 — Unlazy ledger sketch

**Scope directory:** `.unlazy/honest-070-destb/` (add to `.gitignore` before first run — run state, not deliverable)

**`GATES.md` header sketch:**

```markdown
OWNS: docs/design/capability-status.md, docs/dev-log/**, LOOP/**, test/test_destination_b*.jl
SCOPE: honest-0.7 programme — DestB headline + covariance grid promotion + joint version proposal (no Project.toml edit)
```

**Example leaves:**

| Leaf | Gate | CHECK (sketch) | EXPECT |
|---|---|---|---|
| `leaf-g1-api-boundary` | 32-row scope identity | `node tools/destination_b_scope_check.mjs` | exit 0 |
| `leaf-g2-cap-promote` | phylo_dep row matches test | `rg phylo_dep docs/design/capability-status.md` + named test file | Rose checklist PASS |
| `leaf-g10-final-review` | No free DestB rows in closeout matrix | read `g1-audit-matrix` + closeout vs ledger | maintainer sign-off attached |
| `leaf-g11-version-proposal` | Project.toml unchanged | `rg '^version = "0.3.0"' Project.toml` | match; proposal doc exists |

Full templates: `~/shinichi-brain/skills/unlazy/templates/`.

---

## DEFER (explicit)

- Core070 full ledger 497-row bind (parallel track; not DestB headline).
- 0.7.1 oracle re-freeze (T2).
- Spatial/slopes engines before phylo transport default (decision map out-of-scope).
- gllvmTMB T11 API-alignment collisions (R lane).
- Real-data T7 until gllvmTMB #1236 merged.
- Public registration / release tagging.

---

## Paste-ready `/goal` prompt (after G0 approval)

```
/goal GLLVM.jl honest-0.7 Destination B — execute approved ultra-plan

READ FIRST (immutable):
- LOOP/GOAL.md
- docs/dev-log/plans/2026-09-14-honest-070-destination-b-ultraplan.md
- LOOP/arcs.md + LOOP/checkpoint.md
- origin/main (rehydrate; do not trust 2026-09-13 #318-unmerged notes)

G0 ANSWERS (paste Shinichi replies):
- Q1 B1 closed-as-limit: <accept permanent | reopen recovery>
- Q2 S4: <push only | push+probe | hold>
- Q3 Compute: <Totoro | DRAC | Totoro then DRAC>

HEADLINE: DestB API-BOUNDARY → capability promotion (Rose) → LOOP grid finish → T13–T15 → #323 smoke (Codex) → FINAL-REVIEW → joint version *proposal* (NO Project.toml bump).

LANE: claim via lane_lease; Shannon preflight; foreign cursor lanes on Dropbox — do not bleed.

STOP: version bump, S4 without Q2, engine edits on gllvmTMB, merge without green CI.
```

---

## Routing receipt (Cursor two-bar)

**Phase 0.3b:** Owner to glance Settings → Usage for Cursor Models vs Other Models before dispatch (not machine-readable here). Plan assigns **Composer** to scout/build rows, **Other Models** to Rose/Fisher gates, **hand off** for R smoke and S4 push.

**PREFLIGHT:** Shannon verdict pasted §Phase 0.2.

**LANE:** CONTINUE HERE after G0 in a **fresh `/goal` chat** — not Phase 3 in this planning thread.

---

*Plan author: Ada (Cursor). Rose plan-review: sweep receipt attached; block execution until G0 answers recorded in check-log.*
