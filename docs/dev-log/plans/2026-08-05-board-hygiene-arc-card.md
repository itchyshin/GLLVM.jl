# ARC CARD — Post-#181 board / snapshot hygiene

**Status:** **LOCAL DONE** — G0 approved (Q1=idle START HERE, Q2=yes remote
GC); execute on `cursor/board-hygiene-arc-fffd` / PR #183. Awaiting merge.

**Mode:** size  
**Requested outcome:** not quantified — make Active-Lane-Split + `AGENTS.md`
phase snapshot tell the truth after Ordinal+X Arc 2 landed as **#181**, then
**STOP** with no invented next capability arc.  
**Mechanism authority:** docs-only edits to coordination board, `AGENTS.md`
phase-state snapshot, check-log (+ after-task). Explicit exclusions: no `src/`;
no parity cells; no capability-matrix promotion; no Phylo Model A reopen; no
new family/+X identity/engine/RCall arc; no Dropbox-protected-checkout writes;
no `git add -A`; no push without ask; no “full family parity” claim; no silent
START-HERE that invents work.  
**Recommended arc:** **25 minutes** (range **15–40 min**)  
**Time contract:** ceiling ~45 min (outcome-first; under-run → stop)  
**Estimate confidence:** **inferred** (docs pointer catch-up; analogues =
post-merge board conflict fixes 2026-08-03, Ordinal identity S3 board pointer)  
**Arc 0 outcome:** board + `AGENTS.md` snapshot + check-log agree that #170–#181
X/cohort stack (through Ordinal+X Arc 2) is **MERGED** on `main`; START HERE =
**await owner pick / no active OWED**; Rose fence restated.  
**State transition:** stale “push/PR Ordinal+X Arc 2” pointer → honest idle
board. **No metric change.**  
**Executable rung and evidence:** edit three surfaces against live `gh` +
`origin/main` tip; mechanical verify no `src/`; after-task + Actuals; STOP.

### Alternatives reconciled (plan-write 2026-08-05)

| Candidate | Verdict | Why |
| --- | --- | --- |
| **(a) Keep stale START HERE** | **Reject** | `main` @ `a92c5040` already includes Merge #181; CI green. Pointer lies. |
| **(b) Hygiene Arc 0 (this)** | **Ada-default** | Smallest true work; clears false OWED before any new lane. |
| **(c) Invent next family/+X arc now** | **Out of scope** | Needs owner pick + fresh `/arc-creation`; hygiene must not smuggle it. |
| **(d) Branch/worktree GC** | **Fence unless asked** | Remote tips for merged PRs may linger; deleting branches is optional and separate from pointer truth. |

### Capacity ladder

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 15–40 min | Board + AGENTS snapshot + check-log truthful; START HERE idle | After G0 via `/goal` |
| Integrate/close | 5–10 min | after-task + Arc Card Actuals + Rose OK | Always |
| Next programme | — | Owner-named capability (or continued STOP) | Fresh chat + `/arc-creation` |

### Budget (Arc 0)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 5 | Confirm `origin/main` tip, #181 MERGED, open PR list empty of X stack |
| Core | 10–15 | `coordination-board.md` Active-Lane-Split + Current Rule; `AGENTS.md` “Next Cursor lane” |
| Verify | 5 | Grep stale “LOCAL DONE (no push)” / “push/PR Ordinal+X Arc 2”; no `src/` |
| Closeout | 5–10 | check-log line + after-task + Actuals; STOP |
| **Total** | **~25–40** | |

**In scope:**
- `docs/dev-log/coordination-board.md` — Ordinal+X Arc 2 → **MERGED #181**;
  clear push/PR START HERE; Status bullet for #181 merge
- `AGENTS.md` — Phase state snapshot “Next Cursor lane” → idle / await pick
  (snapshot update only; no skill/agent edits)
- `docs/dev-log/check-log.md` — one hygiene catch-up entry
- `docs/dev-log/after-task/2026-08-05-board-hygiene.md` — DoD closeout

**Not in this arc:** any `src/` or `test/` change; capability-status promotion;
CLAIDE/README claim rewrite beyond what board/AGENTS already imply; deleting
remote branches; Phylo Model A; new parity/engine work; handover rewrite of
historical Gamma/Ordinal close notes (leave as historical).

**Evidence used (plan-write):**
- `git rev-parse --short HEAD` → `a92c5040` on `main` (Merge #181)
- `gh pr view 181` → MERGED 2026-08-04; title Ordinal+X Arc 2 light logLik
- `gh run list` → CI + Documenter success on #181 merge
- Stale pointers: `docs/dev-log/coordination-board.md` still “LOCAL DONE (no
  push yet)” + START HERE push/PR; `AGENTS.md` “Next Cursor lane — push/PR
  Ordinal+X Arc 2”
- Latest formal handover file still
  `docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md`
  (historical; do not treat as live START HERE)
- Dropbox `claude/jl-bridge-capabilities-20260619` remains **PROTECTED**

**Risk branch:** If an open PR or unpushed tip still owns real OWED work, stop
and reclassify on the board — do not mark idle. If Shinichi wants hygiene
bundled with a named next capability, **split**: finish hygiene STOP first, or
re-scope via a second `/arc-creation`.

**Done when:** board + AGENTS snapshot + check-log agree #181 is merged; START
HERE does not invent push/PR or a new family arc; after-task + Rose OK; agent
**STOPs**.

**First action (after G0):** cut docs lane from current `origin/main`:

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"   # or cloud /workspace
git fetch origin
git checkout -b docs/board-hygiene-20260805 origin/main
# cloud agent branch template if executing there:
# git checkout -b cursor/board-hygiene-20260805-fffd origin/main
```

### Actuals (complete at close)

**Recommended / actual:** 25 / ~20 · **Rungs completed:** Arc 0 (S0–S6 + Q2 GC)  
**Under-run event:** none material — `/ask-brain` unavailable in cloud (noted)  
**Result:** LOCAL DONE on PR #183 · **Next arc:** STOP until owner `/arc-creation`

---

**HAND TO ULTRA PLAN:** done —
`docs/dev-log/plans/2026-08-05-board-hygiene-ultra-plan.md` (Phases 0–2).
G0 executed in this chat after “1 yes 2 yes”.
