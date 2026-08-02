# Default-route φ landing — Ultra Plan (Phases 0–2)

Meta: 2026-08-02 ~05:00 MDT · PLATFORM=Cursor · Ada · **read-only through G0** · no Phase 3 · no push · no PR · no commit from this planning pass.

Prior Cursor plans consolidated (do not silently rebuild a different arc):

- `~/.cursor/plans/default-route-phi_landing_e5e505f4.plan.md`
- `~/.cursor/plans/default-route_phi_landing_f2c49ca1.plan.md`
- Handover: `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md`

---

```
🎯 GOAL
Solo platform: Cursor. After G0, execute via /goal in a FRESH chat from the φ
worktree — do not grow the planning chat into Phase 3; do not use the Dropbox
stale fork as write base.

Deliverable: Land local COMPLETE branch parity/default-route-phi-20260801
(HEAD 5f1dfe77 or later tip-align) by pushing upstream and opening a PR to
main with Rose claim fence. No auto-merge. No φ reimplementation.

HEADLINE: Maintainer-authorized push + PR for default-route NB2/Beta per-trait
φ (API B) + light logLik 63/63 evidence already on disk.

IN PARALLEL (cheap): tip/SHA stamp consistency (board/handover still cite
ccd55f1f while HEAD is 5f1dfe77); optional parity re-smoke.

DEFER / FENCE: X/covariate cells; test_grouped_dispersion.jl:61 bug lane;
#129/#128; ADEMP; coverage; Totoro/DRAC; full-family-parity claims; rewriting
or splitting catch-up history; Dropbox claude/jl-bridge fork; staging attach
scratch; merge.

DISCIPLINE: Verify PR exists + fence wording; no silent tol widen; stage by
name; no push without G0 authorization; no merge unless separately asked.
Compute = local only (landing). Closure = PR URL + Melissa landing note.
```

---

## Arc Card summary

| Field | Value |
|---|---|
| **Mode** | size |
| **Requested outcome** | Remote branch + open PR carrying COMPLETE local tip; claim fence in body; **no merge** |
| **Mechanism authority** | Write only in φ worktree; stage by name; push/PR only after G0; no auto-merge; no φ reimplementation; no Dropbox stale-fork edits |
| **Recommended arc** | **30–60 min** (25–90 if optional parity re-smoke) |
| **Time contract** | Ceiling ~60 min for landing; outcome-first stop if push denied |
| **Estimate confidence** | Measured (handover has resume commands + PR body draft; tip stable overnight) |
| **Arc 0 outcome** | `git push -u` + `gh pr create` with Rose fence |
| **State transition** | local COMPLETE unpushed → GitHub branch + open PR (still unmerged) |
| **Executable evidence** | PR URL; `gh pr view`; head SHA = local tip; fence text present |

### Capacity ladder

| Order | Budget | Outcome | Done when |
|---|---:|---|---|
| Arc 0 | 10–15m | Worktree preflight + tip/SHA reconcile | HEAD on `parity/default-route-phi-20260801`; only protected untracked attach scratch |
| Rung 1 | 10–20m | Push + open PR to `main` | PR URL live; no merge |
| Rung 2 | 10–20m | Optional parity re-smoke + tip stamp if still citing `ccd55f1f` | 63/63 or skip receipt; pointers consistent |
| Close | 5–10m | Melissa landing note | `plan-actual` or check-log landing line |
| **Total** | **~45–60m** | | |

**In scope:** landing only (push+PR+claim fence).  
**Not in this arc:** φ code; X-cells; grouped-dispersion bug; merge; Dropbox fork.  
**Risk branch:** If G0 does not authorize push → stop after preflight; return unused capacity.  
**First action (post-G0):** `cd` worktree → `git status -sb && git rev-parse --short HEAD`.

`HAND TO ULTRA PLAN: landing arc · ~45–60 min · push+PR to main · no merge · worktree-only · G0 must include push authorization.`

---

## Live tip / PR status (refreshed 2026-08-02)

| Item | Live evidence |
|---|---|
| Authoritative worktree | `.worktrees/gllvmjl-catchup-loglik-20260801` |
| Branch | `parity/default-route-phi-20260801` |
| **Tip SHA** | **`5f1dfe77`** (`5f1dfe770c961822f1336d880bf15d5ad166747d`) |
| vs `origin/main` (`05210eca`) | **34 ahead / 0 behind**; `main` is ancestor |
| Upstream tracking | **none** (`fatal: no upstream`) |
| Remote branch | **absent** (`git ls-remote --heads` empty) |
| **PR** | **none** — `gh pr list --head parity/default-route-phi-20260801 --state all` → `[]` |
| Worktree dirty | only `?? docs/dev-log/plans/scratch/2026-08-01-worktree-attach.md` (**PROTECTED**) |
| Dropbox root | STALE/PROTECTED `claude/jl-bridge-capabilities-20260619` @ `6694f43d` — never write |
| Twin | `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07` |
| Parity log | `/tmp/default-route-phi-parity.log` still shows NB2/Beta default-path cells |

**Verdict:** Landing is **not** done overnight. Primary OWED remains push+PR. Do **not** re-scope to a different next OWED.

---

## Phase 0.25 sweep RECEIPT

| Surface | Evidence | Finding | Call |
|---|---|---|---|
| **repo git** | `git worktree list`; φ `git status -sb` → clean except attach scratch; HEAD `5f1dfe77`; `git rev-list --left-right --count origin/main...HEAD` → `0 34`; `branch_drift_check.sh` → `34 ahead, 0 behind`; Dropbox root still `6694f43d` on `claude/jl-bridge-capabilities-20260619`; `gh pr list --head … --state all` → `[]`; `git ls-remote --heads origin parity/default-route-phi-20260801` empty | Lane COMPLETE locally; **landing gap = unpushed / no PR** | **resume φ worktree**; ignore Dropbox fork |
| **twin gllvmTMB** | `git -C /tmp/gllvmtmb-parity-restart-20260801 rev-parse --short` → `cee55a07`; parity log present with NB2 Δ≈−2.50e-4, Beta Δ≈+5.97e-9 | Oracle partner intact; no R surgery | **reuse** read-only |
| **brain** | MCP `search_notes` query `"default-route-phi OR per-trait phi NB2 Beta fit_gllvm landing"` with `search_all_projects: true` (hybrid) | Hits are older NB/phi parameterisation audits (e.g. nb1-gamma bridge, m3-3a known-phi); **no conflicting parked decision** against API B landing | **reuse** locked API B + in-repo handover as authority |
| **Verdict** | — | Genuine gap = **GitHub landing**, not rebuild | **build-the-gap = push+PR only** |

External NotebookLM: **off** (landing, not novelty claim).

### OWED / DONE / PROTECTED (vs live state)

1. **OWED (primary, approval-gated):** push `parity/default-route-phi-20260801` + open PR to `main` (no auto-merge). **Still OWED — PR does not exist.**
2. **DONE:** API B φ default; cascade; live parity 63/63; LOOP `STATE=COMPLETE`; catch-up logLik @ `def576c6` (ancestor).
3. **OWED (deferred — not this arc):** X/covariate light logLik cells.
4. **OWED (deferred — separate bug lane):** `test_grouped_dispersion.jl:61`.
5. **PROTECTED:** Dropbox stale fork; attach scratch; #129/#128; ADEMP/coverage/Totoro-DRAC; “full family parity”; closed catch-up LOOP overwrite; Phylo Model A sibling; history rewrite/split.

---

## Phase 0.3 / 0.3b — live roster + two bars

- PLATFORM = **Cursor** (this session).
- MODEL-ROUTING (2026-08-01): Cursor Models = Composer 2.5 / Grok 4.5; Other Models = Auto Cost / Claude / GPT (≥$400 API; on-demand off).
- Settings → Usage live meters: **UNVERIFIED this session** (cannot read the UI bars from tools). Glance before `/goal` dispatch.
- Scout/mechanical → **Cursor Models**; push/PR judgment + Rose fence → **Other Models**.

---

## WHAT THE BRAIN ALREADY KNOWS

- No newer vault decision overrides local COMPLETE + push gate.
- Older twin notes discuss per-trait φ / known-φ diagnostics; they do not redefine this landing.
- In-repo handover + after-task are the authority for claim fence and resume commands.

## WHAT SHINICHI TOLD US

- Arc already sized: landing only from φ worktree; push + open PR to `main`; no merge; no φ reimplementation.
- Dropbox root is STALE/PROTECTED.
- Plan mode: Phases 0–2 read-only; stop at G0; do not commit/push from planning.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Rose   — Claim fence must stay light-logLik / default-route only · overclaiming full family parity · fence body from handover · keep fence · use judgment = fence as-written
  Grace  — No upstream + empty remote · push is the irreversible step · need G0 auth · recommend push+PR after yes · default = wait
  Hopper — Twin @ cee55a07 + parity log intact · no R surgery · reuse oracle · question none · default = reuse
  Ada    — Gap is landing not code; PR absent overnight; recommend G0 authorize push+PR now
```

## ADA'S RECOMMENDATION

Approve push + PR to `main` (no merge) from the φ worktree at `5f1dfe77`. Prefer tip-stamp docs or PR-body SHA correction so board/handover stop citing `ccd55f1f`. Optional parity re-smoke if twin still at `cee55a07`.

## DECISIONS LOCKED

- Write base = φ worktree only.
- PR **base = `main`** (includes catch-up commits; **no rebase/split** unless Shinichi later asks).
- No auto-merge.
- Claim fence from handover (light logLik only).
- Optional OWED #3/#4 stay deferred.
- Do not reopen φ routing.
- After G0: **START A FRESH TASK** via `/goal` (do not Phase-3 in planning chat).

## QUESTIONS STILL OPEN

See Phase 0.4 below (≤2).

---

## Phase 0.4 — G0 questions (≤2)

**Q1 — Push authorization (blocks Rung 1)**  
**QUESTION:** Authorize `git push -u origin HEAD` + `gh pr create --base main` now (no merge)?  
**WHY NOW:** Landing is the sole primary OWED; tip stable; PR still absent.  
**TEAM VIEW:** Grace/Rose/Ada — yes after explicit auth; fence from handover.  
**RECOMMENDATION:** Yes.  
**IF YOU DO NOT MIND:** Approve push+PR, no merge.  
**WHAT CONTINUES:** Nothing irreversible until you answer; plan artifact already written.

**Q2 — Tip stamp hygiene**  
**QUESTION:** OK to add a tiny docs commit (or correct pointers in PR description only) so board/checkpoint/handover cite `5f1dfe77` instead of `ccd55f1f`?  
**WHY NOW:** Live HEAD is `5f1dfe77`; several docs still say `ccd55f1f`.  
**RECOMMENDATION:** Prefer PR body + one docs tip-stamp commit if pointers still lag; no engine edits.  
**IF YOU DO NOT MIND:** tip-stamp commit allowed.  
**WHAT CONTINUES:** Landing can proceed with PR-body SHA note even if tip-stamp deferred.

---

## SLICE TABLE (post-G0 `/goal` only)

| ID | Slice | Member | Model+effort | Bar | Dispatch | ~time | Deps | Output |
|---|---|---|---|---|---|---:|---|---|
| S0 | RECON tip/PR empty | landscape-scout | Composer low | Cursor Models | Cursor Agent | 5–10m | — | Confirm HEAD, no PR (refresh if tips move) |
| S1 | Worktree preflight | Ada | Auto Cost med | Other Models | Cursor Agent | 10m | S0 | `status`; handoff_gate rows; protected scratch left unstaged |
| S2 | Push + PR create | Grace + Rose | Auto Cost / pinned | Other Models | Cursor Agent | 15–25m | S1 + **G0 push yes** | PR URL; body with 63/63 + fence |
| S3 | Optional parity re-smoke | Curie | Composer/Auto | Cursor or Other | Cursor Agent | 15–25m | S1 | 63/63 log or skip receipt |
| S4 | Tip pointer consistency | Ada | Composer low | Cursor Models | Cursor Agent | 10m | S2 | board/checkpoint cite live tip |
| S5 | MECHANICAL-VERIFY | reproducibility-engineer | Composer low | Cursor Models | Cursor Agent | 10m | S2 | `gh pr view` non-empty; head SHA matches |
| S6 | Rose claim fence | systems-auditor | Auto Cost med | Other Models | Cursor Agent | 10m | S2 | PR body claim OK / blockers |
| S7 | RECONCILE | Melissa | Auto Cost med | Other Models | Cursor Agent | 10m | Close | `docs/dev-log/plan-actual/2026-08-02-gllvm-default-route-phi-landing.md` |

**PARALLEL:** {S3 ∥ S2} after S1 if smoke desired.  
**SEQUENTIAL:** S1 → S2 → S5 → S6 → S7.  
**FAN-OUT BUDGET:** checkpoint=`default-route-phi-landing-20260801` · ≤3 children · scout yes · no Sol/Opus ceiling unless Rose blocks claim.  
**LUNA SUITABILITY:** yes — S0/S5 on Composer (Cursor Models).  
**ULTRA EFFORT:** no.  
**SEARCH:** none (landing).  
**ESTIMATE:** ~45–60 min · fits one `/goal` session · planning chat must not execute.  
**REVIEW (plan):** Rose — receipt non-vacuous; Grace — push gate clear.  
**VERIFY:** `gh pr view` + head SHA; optional 63/63.  
**LANE RECEIPT after G0:** `START A FRESH TASK` via `/goal` below.

### Resume commands (from handover; tip SHA updated)

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-catchup-loglik-20260801"
git status -sb && git rev-parse --short HEAD   # expect parity/default-route-phi-20260801 @ 5f1dfe77

# ONLY after explicit maintainer G0:
git push -u origin HEAD
gh pr create --base main --head parity/default-route-phi-20260801 \
  --title "feat: default-route NB2/Beta per-trait φ (API B)" \
  --body "$(cat <<'EOF'
## Summary
- Public `fit_gllvm(NB/Beta)` defaults to per-trait φ (`disp_group=:species`).
- Light gllvmTMB logLik oracles 63/63 on that default path (NB2 Δ≈−2.5e-4, Beta Δ≈6e-9).
- Named shared-φ fitters retained; Rose fence: light logLik only, not full family parity.
- Tip at open: 5f1dfe77 (docs tip-align after COMPLETE engine tip ccd55f1f).

## Test plan
- [ ] `GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl` → 63/63
- [ ] Confirm claim fence in PR body (not full family parity)
- [ ] Do not auto-merge

EOF
)"
# Do NOT gh pr merge unless maintainer explicitly asks.
```

---

## Paste-ready `/goal` (after G0 — fresh Cursor chat)

```text
/goal Land GLLVM.jl default-route φ: from worktree
`.worktrees/gllvmjl-catchup-loglik-20260801` on `parity/default-route-phi-20260801`
@ 5f1dfe77 (or later tip), after G0 push authorization, push -u and open PR to
main (no merge) using the handover PR body + Rose fence. Do not reopen φ code.
Do not edit Dropbox stale fork. Leave
`docs/dev-log/plans/scratch/2026-08-01-worktree-attach.md` untracked.
Optional: tip-stamp docs still citing ccd55f1f → 5f1dfe77; optional re-smoke
GLLVM_PARITY_TESTS=1 → 63/63. Close with check-log/plan-actual landing note.
Plan: docs/dev-log/plans/2026-08-01-gllvm-default-route-phi-landing-ultra-plan.md
```

---

## G0 ask (Shinichi)

Reply with:

1. **Approve landing** — “push + PR to main, no merge” (or deny → stop).  
2. Tip-stamp docs commit: yes/no (default **yes**).  

Until then: **no Phase 3**, no push, no engine edits, no commit of this plan file unless you ask. After approval, paste the `/goal` block into a **fresh** Cursor chat with cwd = the φ worktree.
