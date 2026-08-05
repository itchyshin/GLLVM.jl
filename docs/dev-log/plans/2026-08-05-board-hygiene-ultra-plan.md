# Ultra Plan — Post-#181 board / snapshot hygiene (Phases 0–2 only)

```
🎯 GOAL
PLATFORM = Cursor (solo). Deliverable = truthful post-#181 Active-Lane-Split +
AGENTS.md phase-state snapshot + check-log entry, then STOP. HEADLINE = clear the
false “push/PR Ordinal+X Arc 2” OWED after Merge #181 @ a92c5040; START HERE =
await owner pick / no active capability OWED. Docs-only. NO src/; NO test/; NO
parity cells; NO capability-matrix promotion; NO invented next family/+X arc;
NO Phylo Model A reopen; NO remote branch GC unless re-scoped; NO Dropbox
protected-checkout writes; NO git add -A; NO “full family parity” claim.
DISCIPLINE: verify = greps show no stale “LOCAL DONE (no push)” / “push/PR
Ordinal+X Arc 2” on live pointers + no src/ dirty; compute = laptop; closure =
after-task + Arc Card Actuals + STOP. After G0: hand to /goal (fresh chat
preferred); do NOT Phase-3 in this planning turn.
```

**ARC PROGRAM:** size · recommended Arc 0 ≈ **25 min (15–40)** · outcome =
board + AGENTS snapshot + check-log truthful + STOP · under-run → stop (do not
invent next capability) · closeout = after-task + Actuals ·
file: `docs/dev-log/plans/2026-08-05-board-hygiene-arc-card.md`.

**Plan-mode note (once):** Phases 0–2 remain **read-only** here. Phase 3
(board/AGENTS body edits as done) is **not** executed in this planning turn.
Plan PR #183 currently holds the Arc Card only.

**Phase 0.3b two-bar (AGENT-INFERRED):** Settings → Usage was **not** opened in
this cloud turn. Use MODEL-ROUTING (2026-08-01): **Cursor Models** = Composer /
Grok; **Other Models** = ≥$400 API (on-demand off). Owner: glance both bars
before `/goal`. This arc is docs pointer hygiene — default entire execute path
to **Cursor Models** (low).

---

## Context (orient)

Lane: GLLVM.jl after X/covariate light-logLik cohort through Ordinal+X Arc 2
**already merged**; live board/AGENTS still describe a push/PR OWED that no
longer exists.

| Fact | Evidence at plan-write (2026-08-05 ~11:40 UTC) |
| --- | --- |
| `origin/main` | `a92c5040` = Merge #181 |
| #181 | MERGED 2026-08-04 · Ordinal+X Arc 2 light logLik |
| #170–#180 | MERGED earlier (board rows mostly already “MERGED”) |
| Open PRs | only **#183** (this plan lane: Arc Card) |
| Stale board row | Ordinal+X Arc 2 still “**LOCAL DONE** (no push yet)” |
| Stale START HERE | “push/PR Ordinal+X Arc 2 tip … @ `b6cf71f5`” |
| Stale AGENTS | “Next Cursor lane — push/PR Ordinal+X Arc 2” |
| CI on #181 merge | completed success (CI + Documenter) |
| Dropbox checkout | `claude/jl-bridge-capabilities-20260619` · **PROTECTED** |
| Arc Card | `docs/dev-log/plans/2026-08-05-board-hygiene-arc-card.md` @ `fd83e64d` |

Authoritative live pointer today should be the board — currently lying.
Historical handovers (Gamma close 2026-08-03, etc.) stay historical.

---

## Phase 0.25 — Sweep receipt (gate; evidence-cited)

| Surface | Evidence ran | Finding | Call |
| --- | --- | --- | --- |
| **repo git** | `git fetch origin main`; `git rev-parse --short origin/main` → `a92c5040`; `git log --oneline origin/main -3` shows Merge #181; branch `cursor/board-hygiene-arc-fffd` @ `fd83e64d` (Arc Card only); `git status -sb` clean vs origin tip of plan branch | Main tip already post-#181; hygiene content **not** written yet | **resume** = apply board/AGENTS/check-log edits on this docs lane (or rebase onto main); **not** a new capability |
| **gh PRs / CI** | `gh pr view 181` → MERGED; `gh pr list --state open` → only #183 plan PR; `gh run list --limit 3` → #181 merge CI was green; #183 Documenter success / CI in progress (plan-only) | No open X-stack OWED PR; push/PR Ordinal Arc 2 is **DONE** | **build-the-gap** = pointer truth only |
| **stale greps** | `rg` on `AGENTS.md` + `coordination-board.md` for `push/PR Ordinal`, `LOCAL DONE (no push`, `b6cf71f5`, `START HERE` | Hits confirm stale START HERE + Next Cursor lane + LOCAL DONE row | **must edit** those three surfaces (+ check-log/after-task) |
| **twin / sister** | not required for pointer hygiene | N/A | **skip** |
| **brain** | shinichi-brain MCP **unavailable** in this cloud run (`GetMcpTools` pattern search empty) | Cannot cite vault DECISIONS/AGENT_LOG this turn | **proceed on repo evidence**; if local vault later contradicts, amend board note — do not invent vault facts |
| **Verdict** | — | Genuinely owed = **docs pointer catch-up**. Do not invent next family arc. Do not GC remotes unless Q2 yes. | **build-the-gap** = hygiene Arc 0 |

External novelty: **not claimed** — no `/notebook`.

---

## WHAT THE BRAIN ALREADY KNOWS

_(repo-local; vault MCP unavailable this run)_

- X cohort through Ordinal+X Arc 2 is on `main` via #170–#181.
- Rose fence for light RCall cells remains: ≠ full family parity ≠ ADEMP.
- Phylo Model A stays parked (`docs/dev-log/handover/2026-06-30-codex-handover.md`).
- Dropbox stale checkout stays PROTECTED.
- Board is the multi-lane rehydrate pointer; orphaned START HERE bullets mislead.

## WHAT SHINICHI TOLD US

- Asked to resume → found latest handover stale vs git; recommended hygiene + STOP.
- Confirmed workflow name **`/arc-creation`** (not `/arc-create`).
- Invoked **`/ultra-plan` this arc** — plan for approval only (this document).

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Shannon — Board/AGENTS disagree with gh merge #181 · matters because agents
            rehydrate from START HERE and invent push work · Rec: idle START HERE
            after hygiene · Q: any other real OWED? Default: only #183 plan PR.
  Rose    — Must not promote capability-status or claim “full parity” while
            cleaning pointers · Rec: fence in after-task · Q: rewrite historical
            handovers? Default: no — leave historical.
  Ada     — Hygiene then STOP; next capability needs a fresh /arc-creation after
            owner pick · Rec: do not smuggle family arc into this PR.
  Grace   — Optional remote-branch GC is separate; cancel-in-progress risk if
            thrashing docs while unrelated CI runs · Rec: single docs PR, stage
            by name.
```

## ADA'S RECOMMENDATION

1. Approve G0 for **hygiene Arc 0 only** (~25 min).
2. Edit board + AGENTS snapshot + check-log; write after-task; update Arc Card
   Actuals; **STOP**.
3. Do **not** name a next family/+X arc in START HERE.
4. Branch GC default **no** unless Q2 grants it.
5. Execute on the existing plan branch `#183` / `cursor/board-hygiene-arc-fffd`
   (already from post-#181 main) — or rename to `docs/board-hygiene-20260805`
   if you prefer docs/ prefix; content > name.

## DECISIONS LOCKED (not reopened)

- #181 MERGED = Ordinal+X Arc 2 landed.
- No push without explicit ask (this cloud plan PR already pushed as plan
  artifact; execute remains gated by G0).
- Never `git add -A`.
- Dropbox PROTECTED.
- Light RCall ≠ full family parity.
- Phylo Model A parked / do not orphan.

## QUESTIONS STILL OPEN (Phase 0.4 — at most 2)

### Q1 — START HERE wording after hygiene?
**QUESTION:** After clearing the false push/PR OWED, should START HERE say
**(A)** “idle — await owner pick / no active capability OWED” or
**(B)** a named next arc you choose now?  
**WHY NOW:** Determines whether hygiene stays pure STOP or smuggles scope.  
**TEAM VIEW:** Ada/Rose — (A).  
**RECOMMENDATION:** **(A) idle**.  
**IF YOU DO NOT MIND:** Use (A).  
**WHAT CONTINUES:** Plan only until G0.

### Q2 — Remote branch GC in the same PR?
**QUESTION:** Also delete merged remote heads
(`parity/ordinal-x-arc2-20260803`, etc.) in this arc?  
**WHY NOW:** Optional cleanup vs pointer truth; GC is irreversible-ish ops.  
**TEAM VIEW:** Grace/Ada — separate unless you want it.  
**RECOMMENDATION:** **No** — pointer hygiene only.  
**IF YOU DO NOT MIND:** Skip GC.  
**WHAT CONTINUES:** Hygiene PR stays docs-only.

---

## Phase 0.5 — Grounded search offer

NotebookLM / prior-art search? **Default: no** (internal board truth). Say yes
only if you want it.

---

## Phase 1 — Decompose

| ID | Slice | In → Out | Deps |
| --- | --- | --- | --- |
| S0 | RECON open OWED vs `gh`/`main` | tip + PR list → confirm idle claim safe | — |
| S1 | Edit `coordination-board.md` | stale Arc 2 row + START HERE + Status → MERGED #181 / idle | S0 |
| S2 | Edit `AGENTS.md` phase snapshot | “Next Cursor lane” → idle / await pick (+ #181 MERGED bullet) | S0 |
| S3 | check-log + after-task | hygiene entry + `2026-08-05-board-hygiene.md` | S1, S2 |
| S4 | MECHANICAL-VERIFY | greps: no stale push/PR Ordinal LOCAL-DONE; `git diff --name-only` ⊆ docs/AGENTS; no `src/` | S1–S3 |
| S5 | Rose claim/fence | OK / blockers (no capability promotion) | S4 |
| S6 | Arc Card Actuals + PR body | closeout; STOP | S5 |

**PARALLEL:** S1 ∥ S2 after S0  
**SEQUENTIAL:** S3 ← S1∧S2; S4 ← S3; S5 ← S4; S6 ← S5

---

## Phase 2 — SLICE TABLE

| Slice | Member | Model + effort | Bar | Dispatch | Time | Detail | Dep |
| --- | --- | --- | --- | ---: | --- | --- | --- |
| S0 RECON | Shannon | Composer · low | **Cursor Models** | agent | 3–5 min | `gh pr list`; confirm only #183 open | — |
| S1 Board | Ada/Shannon | Composer · low | **Cursor Models** | agent | 8–12 min | Active-Lane-Split + Current Rule + Status | S0 |
| S2 AGENTS snapshot | Ada | Composer · low | **Cursor Models** | agent | 5–8 min | Phase state snapshot only | S0 |
| S3 check-log + after-task | Ada | Composer · low | **Cursor Models** | agent | 5–8 min | DoD docs | S1,S2 |
| S4 MECHANICAL-VERIFY | Grace | Composer/Grok · low | **Cursor Models** | agent | 3–5 min | greps + path allowlist | S3 |
| S5 Rose | Rose | Auto Cost · med | **Other Models** | judgment (or Ada-as-Rose if short) | 5 min | fence: no claim inflation | S4 |
| S6 Actuals + STOP | Ada | Composer · low | **Cursor Models** | parent | 3–5 min | Arc Card Actuals; update #183 | S5 |

**FAN-OUT:** S1∥S2 only · scout=1 (S0) · build=0 · ceiling=0–1 (Rose)  
**ULTRA EFFORT:** no  
**SEARCH:** none  
**ESTIMATE:** ~25–40 min · one `/goal` session  
**VERIFY:** S4 + S5  
**CONSOLIDATE:** board + AGENTS + check-log + after-task  
**RECONCILE:** light (optional Melissa one-pager; skip if under-run)  
**COMPUTE:** laptop only

---

## Rose plan-review (decomposition — Ada-as-Rose; no execution)

**Receipt check:** Phase 0.25 cites `git`/`gh`/`rg`; brain MCP honestly marked
unavailable. **PASS** for a docs hygiene arc.

**Critique:**
1. Correct to treat push/PR Ordinal Arc 2 as **DONE**, not still OWED.
2. Correct to fence inventing the next family arc in START HERE.
3. Risk: editing historical handover files “for consistency” — **out of scope**;
   would rewrite history without need.
4. Risk: bundling remote branch deletes — keep behind Q2 default no.
5. Do **not** touch `docs/design/capability-status.md` in this arc.

**Verdict:** decomposition OK after G0 + Phase 0.4 (or “use your judgment”).
**Do not Exit into execution in this planning chat.**

---

## ASK PERMISSION TO START

This Ultra Plan stops at Phase 2. **No Phase 3.**

### Paste-ready permission question

> Shinichi — Ultra Plan Phases 0–2 for **post-#181 board/snapshot hygiene** are
> written (~25 min, docs-only). `origin/main` @ `a92c5040` already has Merge
> #181; board/AGENTS still say push/PR Ordinal+X Arc 2. Only open PR is plan
> #183 (Arc Card).
>
> **May I start?** If yes, please answer:
> 1. **START HERE after?** idle await-pick (Ada default) / name a next arc now
> 2. **Remote branch GC in same PR?** no (Ada default) / yes
>
> Saying **yes + use your judgment** starts `/goal` that edits board + AGENTS
> snapshot + check-log + after-task only, then STOPs (no `src/`, no new
> capability).

### Paste-ready `/goal` kickoff (after G0)

```
/goal Post-#181 board / snapshot hygiene (docs-only)
PLATFORM=Cursor. Branch: cursor/board-hygiene-arc-fffd (PR #183) or
docs/board-hygiene-20260805 from origin/main @ a92c5040.
Plan: docs/dev-log/plans/2026-08-05-board-hygiene-ultra-plan.md
Arc Card: docs/dev-log/plans/2026-08-05-board-hygiene-arc-card.md
Deliverable: truthful coordination-board.md + AGENTS.md phase snapshot +
check-log + docs/dev-log/after-task/2026-08-05-board-hygiene.md
Fence: no src/; no test/; no capability-status promotion; no invented next
family/+X arc; no Phylo Model A; no remote GC unless Q2=yes; no git add -A.
Verify: greps clear stale push/PR Ordinal LOCAL-DONE; Rose fence. Close: Actuals
+ STOP.
```
