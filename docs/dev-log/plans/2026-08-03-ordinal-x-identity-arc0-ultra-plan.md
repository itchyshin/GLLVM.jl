# Ultra Plan — Ordinal+X cutpoint / identity Arc 0 (Phases 0–2 only)

```
🎯 GOAL
PLATFORM = Cursor (solo). Deliverable = ACCEPTED (or explicitly rejected-with-fence)
Ordinal+X cutpoint/identity decision note under docs/dev-log/decisions/, mirroring
docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md — docs-only;
NO engine, NO Ordinal+X light RCall, NO ADEMP in this arc. HEADLINE = lock twin
default for Ordinal under shared site-X (per-trait cutpoints / τ₁ convention /
covariate path identity) before any fit_ordinal_*_cov work. IN PARALLEL (cheap):
(1) recon twin gllvmTMB ordinal_probit τ₁=0 + K−2 free log-spacings + formula/X
surface on fresh tip; (2) recon Julia fit_ordinal_* + bridge “no covariate kernel”
+ shared vs per-trait cutpoint fitters. DEFER/FENCE: Ordinal+X engine; X_lv;
ADEMP/coverage; Phylo Model A; dual-PR of fix/gamma-x-grouped-cov Arc2 tip;
Dropbox protected checkout writes; git add -A; push without ask; “full family
parity”; silent no-X Option B flip; force-merge #177 while Julia CI red.
Contigent Landing (Gamma push/PR + merge #177 when green) is OUTSIDE this GOAL
unless Shinichi re-scopes in Phase 0.4 Q1. DISCIPLINE: verify = decision cites
twin file:line + Rose fence + no src/; compute = laptop (no Totoro/DRAC —
docs-only); closure = after-task + check-log + STOP — next engine arc only after
acceptance. After G0 approval: hand to /goal in a FRESH chat (do NOT Phase-3 in
the planning chat).
```

**ARC PROGRAM:** size · recommended Arc 0 ≈ **90 min (60–120)** · outcome =
Ordinal+X identity decision doc only · under-run → stop (do not invent engine) ·
closeout = board pointer + Actuals on Arc Card ·
file: `docs/dev-log/plans/2026-08-03-ordinal-x-identity-arc-card.md`.

**Plan-mode note (once):** this Cursor Multitask session is **not** in client
Plan mode; Phases 0–2 remain **read-only** here. Phase 3 / decision-doc body /
push / merge are **not** executed in this planning turn.

**Phase 0.3b two-bar (AGENT-INFERRED):** Settings → Usage was **not** opened in
this subagent turn. Use MODEL-ROUTING (2026-08-01 Cursor row): **Cursor Models**
= Composer 2.5 / Grok 4.5; **Other Models** = ≥$400 API (on-demand off). Owner:
glance both bars before `/goal`. Plan table routes scout → Cursor Models;
judgment/prose → Other Models; orchestration/verify → hand off Claude Opus if
needed.

---

## Context (orient)

Lane: GLLVM.jl after **Gamma+X Arc 1–2 LOCAL DONE** (unpushed) → next
**capability** = Ordinal+X Arc 0 (identity). Parallel OWED landings remain gated.

| Fact | Evidence at plan-write (2026-08-03 ~16:17 UTC / ~10:17 MDT) |
| --- | --- |
| Preferred worktree | `.worktrees/gllvmjl-gamma-x-arc2-20260803` |
| Branch tip | `parity/gamma-x-arc2-20260803` @ `064b7bf0` (handover) |
| Drift vs `origin/main` | `branch_drift_check.sh`: **8 ahead, 0 behind** (ok ≤20) |
| `origin/main` | `0e241215` (#176 merged) |
| Gamma stack | LOCAL DONE identity+engine+Arc2 OH+light cell; **not on origin** |
| Duplicate tip | `fix/gamma-x-grouped-cov-20260803` @ `bcd48513` — **CARRIED-OVER**; do not dual-PR |
| #177 | OPEN · MERGEABLE · Documenter **green** · Julia matrix **IN_PROGRESS** (4 jobs pending) |
| Mirror identity | Gamma ACCEPTED: `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md` |
| Dropbox checkout | `claude/jl-bridge-capabilities-20260619` · **PROTECTED** |
| Ada prior rec | Ordinal+X identity doc only (~1–2h); no engine until ACCEPTED |

Authoritative handover:  
`docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md`  
Board: `docs/dev-log/coordination-board.md`

---

## Phase 0.25 — Sweep receipt (gate; evidence-cited)

| Surface | Evidence ran | Finding | Call |
| --- | --- | --- | --- |
| **repo git** | `git status -sb`; `git rev-parse --short HEAD` → `064b7bf0`; `git log --oneline -12`; `git worktree list`; `git stash list`; `bash ~/shinichi-brain/tools/branch_drift_check.sh` → `parity/gamma-x-arc2-20260803` **8 ahead / 0 behind** `origin/main`; `gh pr view 177 --json …`; `gh pr checks 177`; `gh pr list --limit 8` | Gamma tip clean local; unpushed; #177 only open PR; Doc green; Julia 4× pending; no Ordinal+X identity doc yet (`ls docs/dev-log/decisions/*ordinal*` = phylo-ordinal LV notes, not +X identity) | **resume nothing for Ordinal+X** — **build-the-gap** (new docs lane). Landings = separate OWED (push gate + CI wait) |
| **twin / sister** | local `gllvmTMB` @ `/Users/z3437171/Dropbox/Github Local/gllvmTMB` @ `ab49638b`; `rg` ordinal_probit / tau_1 / n_ordinal_cuts / extract_cutpoints on `src/gllvmTMB.cpp`, `R/fit-multi.R`, `man/ordinal_probit.Rd` | Twin public ordinal = **`ordinal_probit` fid 14**; **τ₁ = 0 fixed**; **K−2 free** log-spacings **per trait**; tidy `effect="cutpoint"` | **co-opt twin as oracle**; identity doc must lock Julia↔twin cutpoint + X-path gap (Julia bridge: ordinal **no covariate kernel yet**) |
| **brain** (`search_all_projects: true`) | MCP `search_notes` hybrid: (1) `Ordinal+X ordinal cutpoint dispersion identity Gamma+X GLLVM`; (2) retry attempted for land/push (tool flake on 2nd call — first call retained) | Hits: `2026-05-18-cross-package-count-inference-scout` (gllvmTMB τ₁=0); `2026-06-16-julia-per-trait-dispersion-cutpoints-spec`; `2026-06-16-engine-julia-draft-landing` (per-trait ordinal cutpoint parity ≠ DRM); Gamma/NB2+X fences Ordinal+X | **reuse** cutpoint convention notes + **reuse** Gamma/NB2 Arc 0 pattern; **gap** = Ordinal+**X** identity decision not written |
| **deterministic log/history greps** | `grep -in … AGENT_LOG.md` (ordinal/gamma-x/#177/cutpoint) → **no Ordinal+X / gamma-x land hits** in recent tail (GLLVM mentions are board hygiene); `grep -in … DECISIONS.md` → **no Ordinal+X identity decision**; D-114 is Meta-interaction push (different repo); `grep … OPEN_QUESTIONS.md` → gllvmTMB open/public notes, not Ordinal+X; `grep -rin … journal/` (incl. `journal/2026-08*.md`) → **no Aug hits** for ordinal+x / gamma-x-arc2 / #177; `grep … projects/deep-research/README.md` → GLLVM/JSDM + NB2-vs-OLRE etc., **no Ordinal+X identity research entry** | Ordinal+X identity is **not** already decided in vault ledgers; do not rebuild Gamma stack | **build-the-gap** = Arc 0 decision doc only |
| **Verdict** | — | Genuinely new = **Ordinal+X identity decision** (docs). Do not rebuild Gamma engine. Do not dual-PR `fix/` Arc2 tip. Do not treat merge #177 as this arc while CI pending. | **build-the-gap** = docs Arc 0; landings = permission-gated side OWED |

External novelty / “first to do X”: **not claimed** — no `/notebook` required for this internal twin-identity lock (offer remains open in Phase 0.5).

---

## WHAT THE BRAIN ALREADY KNOWS

- NB2/Beta+X and Gamma+X public defaults under shared site-X = **per-trait dispersion + shared γ** (API B under X); Gamma ACCEPTED 2026-08-03; engine+Arc2 local-done on preferred tip.
- Those decisions **explicitly fenced Ordinal+X** — do not silently expand the fence.
- Twin `ordinal_probit`: τ₁=0 fixed for identifiability; K−2 free cutpoints per trait (log-spacings); not the same packing as Julia’s shared-cutpoint `_unpack_cutpoints` / unconstrained increments (must be cited carefully).
- Julia no-X: `fit_gllvm(::Ordinal)` → `fit_ordinal_gllvm_pertrait` (per-trait cutpoints match native bridge target); shared-cutpoint `OrdinalFit` kept as Julia-side comparator.
- Julia +X: bridge documents ordinal/nb1 as **no covariate kernel yet** (`src/bridge.jl`); this is the load-bearing gap the identity doc must name before any engine.
- Phylo-ordinal structural-LV decision notes (2026-07-02) exist — **orthogonal**; do not confuse with Ordinal+X site-covariate identity.
- Push policy: no push without explicit ask; D-114 is a different-repo push decision (do not cargo-cult).

## WHAT SHINICHI TOLD US

_(empty until Phase 0.4 answers — planning turn only)_

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Hopper — Twin ordinal_probit uses τ₁=0 + K−2 free per-trait log-spacings;
           Julia per-trait packing differs in parameterisation. Matters for
           any future light RCall cell. Rec: identity doc must table both
           packings and state which is the twin target under X. Q: accept
           per-trait cutpoints + shared site-X γ as the default when an X
           path exists? Default if “use your judgment”: yes, mirror Gamma
           API-B-under-X, with explicit packing map.
  Rose   — Landings still OWED (Gamma unpushed; #177 CI pending). Claiming
           “next capability” while landings hang is fine for a docs arc, but
           must not erase the OWED row. Rec: Ordinal Arc 0 as capability;
           ask push/PR as Q1; never dual-PR fix/ tip. Q: land Gamma now?
           Default if “use your judgment”: Ordinal docs-first this arc;
           landings wait for explicit ask / CI green (do not invent push).
  Noether — Cutpoint identity ≠ dispersion φ; Ordinal has no Gamma-like α.
           Rec: title the decision “cutpoint / ordinal identity under X”,
           not “dispersion identity”. Default: follow Gamma template sections
           but rename the estimand honestly.
  Ada    — Choose (c) Ordinal+X identity as the planned capability Arc 0;
           hold (b) behind Q1; hold (a) as CI watch not force-merge.
```

## ADA'S RECOMMENDATION

Plan and (after G0) execute **Ordinal+X identity Arc 0 (docs-only)** as the next
capability arc. Ask Shinichi whether to insert **Gamma push/PR** (and merge #177
when green) as a **contigent Landing pre-rung**; default if he does not mind =
**do not push in this arc** — keep landings OWED and start Ordinal docs in a
fresh `/goal` chat after G0.

## DECISIONS LOCKED (from prior arcs — not reopened here)

- Gamma+X under X = per-trait α + shared γ (ACCEPTED).
- Gamma Arc 2 OH default = observed Hessian on grouped Laplace.
- Preferred land tip = `parity/gamma-x-arc2-20260803` (not `fix/` duplicate).
- Dropbox `claude/jl-bridge-capabilities-20260619` = PROTECTED.
- No push without explicit ask.

## QUESTIONS STILL OPEN (Phase 0.4 — at most 3)

### Q1 — Land Gamma stack now?
**QUESTION:** Should this programme’s first executable action be push/PR
`parity/gamma-x-arc2-20260803` (and merge #177 when Julia CI green), before
Ordinal identity?  
**WHY NOW:** Both are OWED; push is approval-gated; CI is the only live blocker
for #177.  
**TEAM VIEW:** Rose — ask explicitly; Hopper — landings orthogonal to Ordinal
docs.  
**RECOMMENDATION:** If you want the board clean first → **yes, Landing Arc 0**.
If you want the next capability started → **no, Ordinal identity** (Ada default
for this Ultra Plan).  
**IF YOU DO NOT MIND:** **No push in this arc** — proceed Ordinal identity after
G0; leave Gamma tip local until you say “push”.  
**WHAT CONTINUES:** Plan artifact stays; no Phase 3 until G0.

### Q2 — Ordinal+X default shape (when X path exists)?
**QUESTION:** Should the decision lock **per-trait cutpoints + shared site-X γ**
as the twin-facing default (analogous to Gamma/NB2 API B under X), with Julia’s
current “no covariate kernel” named as the engine gap?  
**WHY NOW:** Determines Arc 1 scope after acceptance.  
**TEAM VIEW:** Hopper — yes with packing map; Noether — call it cutpoint identity
not dispersion.  
**RECOMMENDATION:** **Yes** — per-trait cutpoints + shared γ; cite τ₁=0 twin
convention and Julia packing translation.  
**IF YOU DO NOT MIND:** Use Ada recommendation (yes).  
**WHAT CONTINUES:** Recon slices can draft the table either way.

### Q3 — Parallel docs vs wait for landings?
**QUESTION:** May Ordinal identity draft on a fresh `docs/…` branch from today’s
`origin/main` @ `0e241215` while Gamma tip remains unpushed, or wait until Gamma
PR / #177 land so the decision rides a clean main tip?  
**WHY NOW:** Worktree / rebase hygiene; avoids orphaning the decision behind an
unmerged stack.  
**TEAM VIEW:** Rose — parallel docs OK if fenced; Shannon — prefer post-#177 main
if wait is short.  
**RECOMMENDATION:** Prefer **wait for #177 green+merge** if CI finishes soon;
otherwise **parallel docs from `origin/main`** with board note that Gamma land is
still OWED.  
**IF YOU DO NOT MIND:** **Parallel docs from `origin/main`** after G0 (don’t
block identity on CI wall-clock).  
**WHAT CONTINUES:** Watch #177 without force-merge.

---

## Phase 0.5 — Grounded search offer

Want a NotebookLM `/notebook` sweep on ordinal threshold models / cutpoint
identifiability under multivariate LVMs first? **Default: no** (internal twin
lock; prior-art novelty not claimed). Say yes if you want tier-(b) search.

---

## Phase 1 — Decompose (gated by receipt above)

| ID | Slice | In → Out | Deps |
| --- | --- | --- | --- |
| S0 | RECON twin ordinal_probit + X/formula surface | twin tip → `docs/dev-log/plans/scratch/ordinal-x-twin-recon.md` | — |
| S1 | RECON Julia ordinal routes + bridge X gap | src → `docs/dev-log/plans/scratch/ordinal-x-julia-recon.md` | — |
| S2 | Draft identity decision (mirror Gamma sections) | S0+S1 → `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md` | S0, S1 |
| S3 | Board + START HERE + check-log pointer | decision → board/AGENTS snapshot lines | S2 |
| S4 | MECHANICAL-VERIFY | links resolve; no `src/` dirty; fence phrases present | S2, S3 |
| S5 | Rose claim/fence review | decision → brief OK / blockers | S4 |
| S6 | After-task + Arc Card Actuals | closure artifact | S5 |
| S7 | Melissa RECONCILE | plan vs actual → `docs/dev-log/plan-actual/2026-08-03-ordinal-x-identity.md` | S6 |

**PARALLEL:** {S0, S1}  
**SEQUENTIAL:** S2 ← S0∧S1; S3 ← S2; S4 ← S3; S5 ← S4; S6 ← S5; S7 ← S6

**Contigent Landing (only if Q1 = yes):** L1 push/PR Gamma preferred tip; L2 merge
#177 iff `gh pr checks` all green — else stop and report. Not part of Ordinal
GOAL unless re-scoped.

---

## Phase 2 — SLICE TABLE (runnable by a colleague)

| Slice | Member | Model + effort | Bar | Dispatch | Time | Detail | Dep |
| --- | --- | --- | --- | --- | ---: | --- | --- |
| S0 RECON twin | Hopper (scout) | Composer 2.5 / Grok · low–med | **Cursor Models** | Cursor Task / agent | 15–20 min | gllvmTMB ordinal_probit τ₁, packing, formula/X | — |
| S1 RECON Julia | Gauss/Emmy scout | Composer 2.5 · low–med | **Cursor Models** | Cursor Task / agent | 15–20 min | fit_ordinal_*, bridge no-X/X gap, shared vs per-trait | — |
| S2 Draft decision | Ada+Noether | Auto Cost / Claude Sonnet–Opus · med–high | **Other Models** | `/goal` parent or judgment agent | 40–50 min | Mirror Gamma identity sections; honest estimand name | S0,S1 |
| S3 Board pointers | Ada | Composer · low | **Cursor Models** | agent | 5–10 min | coordination-board + START HERE | S2 |
| S4 MECHANICAL-VERIFY | Grace/scout | Composer/Grok · low | **Cursor Models** | agent | 5–10 min | greps: fence phrases; no src/; links | S2,S3 |
| S5 Rose plan+claim review | Rose | Auto Cost / Claude · high | **Other Models** | judgment agent | 10–15 min | fence + claim vs evidence | S4 |
| S6 After-task | Ada+Rose | Auto Cost · med | **Other Models** | parent | 10 min | after-task + Actuals | S5 |
| S7 RECONCILE | Melissa | Auto Cost / Sonnet · low–med | **Other Models** | agent | 10 min | plan-actual receipt | S6 |

**FAN-OUT:** 2 scout children in parallel (S0∥S1), then sequential judgment.  
**FAN-OUT BUDGET:** checkpoint=`ordinal-x-id-arc0` · new children ≤4/6 · scout=2 ·
build=0 (docs) · ceiling=0–1 (Rose only if claim gate) · reuse on repair.  
**LUNA SUITABILITY:** yes for S0/S1/S4 if routed via Codex tiered CLI; on Cursor,
Composer/Grok fills the scout bar.  
**ULTRA EFFORT:** no (default).  
**SEARCH:** none required (NotebookLM offered, default decline).  
**ESTIMATE:** ~90–120 min wall-clock · fits 1 `/goal` session · handoff if context
compacts.  
**ARC ACTUALS:** complete on Arc Card at close.  
**REVIEW (plan, this turn):** Rose-as-Ada brief below.  
**VERIFY:** S4 mechanical + S5 Rose.  
**CONSOLIDATE:** decision doc + board + after-task.  
**RECONCILE:** Melissa required (meaningful close).  
**COMPUTE:** laptop only — ask Totoro vs DRAC **only if** a later arc adds
parity/heavy runs (not this Arc 0).

---

## Rose plan-review (decomposition — Ada-as-Rose; no execution)

**Receipt check:** Phase 0.25 present and non-vacuous — each surface cites
command/query (git/drift/gh; twin rg; MCP search_notes; deterministic greps).
**PASS** for entering Phase 1 in a later execute session.

**Critique:**
1. Correct to **not** make merge #177 the Arc 0 while Julia CI is pending —
   force-merge would be claim inflation.
2. Correct to keep Gamma push **behind Q1** — push without ask violates hard
   boundary.
3. Risk: naming the file “dispersion-identity” would mislabel Ordinal — plan
   already prefers **cutpoint-identity**; keep that.
4. Risk: drafting Ordinal+X while Gamma tip is unpushed is fine for docs, but
   board must keep the OWED landing row visible (S3).
5. Do **not** expand S2 into engine stubs or light cells “while we’re here.”

**Verdict:** decomposition OK to run after G0 + Phase 0.4 answers. **Do not Exit
into execution in this planning chat.**

---

## ASK PERMISSION TO START

This Ultra Plan stops at Phase 2. **No Phase 3.** No push, merge, `src/` edit, or
decision-doc body-as-done until Shinichi explicitly approves.

### Paste-ready permission question

> Shinichi — Ultra Plan Phases 0–2 for **Ordinal+X cutpoint/identity Arc 0** are
> written (docs-only, ~90 min, mirror Gamma identity; fence engine / ADEMP /
> Phylo Model A / dual-PR Gamma). #177 Documenter is green; Julia CI still
> IN_PROGRESS (not force-merging). Gamma tip `parity/gamma-x-arc2-20260803` @
> `064b7bf0` remains **unpushed** (OWED).
>
> **May I start?** If yes, please answer:
> 1. **Landing first?** push/PR Gamma now / wait / use your judgment (Ada default =
>    wait — Ordinal docs first)
> 2. **Ordinal default under X?** per-trait cutpoints + shared γ (Ada default = yes)
> 3. **Base tip?** parallel docs from `origin/main` now / wait for #177 merge (Ada
>    default = parallel docs from main)
>
> Saying **yes + use your judgment** starts a **fresh `/goal` chat** that drafts
> `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md` only (no
> engine, no push).

### Paste-ready `/goal` kickoff (after G0)

```
/goal Ordinal+X cutpoint/identity Arc 0 (docs-only)
PLATFORM=Cursor. Worktree: cut fresh
.worktrees/gllvmjl-ordinal-x-identity-20260803 from origin/main
(or as answered in Q3). Plan:
docs/dev-log/plans/2026-08-03-ordinal-x-identity-arc0-ultra-plan.md
Arc Card:
docs/dev-log/plans/2026-08-03-ordinal-x-identity-arc-card.md
Deliverable:
docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md
Fence: no src/; no Ordinal+X RCall; no ADEMP; no Phylo Model A; no dual-PR
fix/gamma-x tip; no push unless Q1 granted; no force-merge #177.
Verify: Rose fence + twin file:line cites. Close: after-task + board + Actuals.
```
