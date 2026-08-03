# Ultra Plan — Gamma+X dispersion identity (Phases 0–2 only)

```
🎯 GOAL
PLATFORM = Cursor (solo). Deliverable = ACCEPTED (or explicitly rejected-with-fence)
Gamma+X dispersion-identity decision note under docs/dev-log/decisions/, mirroring
docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md — docs-only;
NO engine, NO Gamma+X light RCall cells in this arc. HEADLINE = lock twin default
for Gamma under shared site-X (per-trait α vs retain shared/bridge Option B) before
any fit_gamma_*_cov work. IN PARALLEL (cheap): (1) recon twin gllvmTMB Gamma
log_phi_gamma / disp.group / formula shape on fresh origin/main; (2) recon Julia
bridge+fit_gllvm Gamma no-X/X routes + Option B check-log. DEFER/FENCE: Ordinal+X;
X_lv; ADEMP/coverage; Phylo Model A; Dropbox protected checkout writes; git add -A;
push without ask; “full family parity”; merging #177 inside this goal unless
explicitly re-scoped as a landing gate only. DISCIPLINE: verify = decision cites
twin file:line + Rose fence + no src/; compute = laptop (no Totoro/DRAC);
closure = after-task + check-log + STOP — next engine arc only after acceptance.
After G0 approval: hand to /goal (do NOT Phase-3 in the planning chat).
```

**ARC PROGRAM:** size · recommended Arc 0 ≈ **90 min (60–120)** · outcome =
Gamma+X identity decision doc only · under-run → stop (do not invent engine
work) · closeout = board pointer + Actuals on Arc Card.

**Plan-mode note (once):** this Cursor session is **not** in client Plan mode;
Phases 0–2 remain **read-only** here. Phase 3 / decision-doc body-as-done /
merges are **not** executed in this planning turn.

**Phase 0.3b two-bar (AGENT-INFERRED):** Settings → Usage was not opened in this
subagent turn. Use MODEL-ROUTING (2026-08-01): Cursor Models = Composer 2.5 /
Grok 4.5; Other Models = ≥$400 API (on-demand off). Owner: glance both bars
before `/goal`. Plan table routes scout → Cursor Models; judgment/prose → Other
Models; orchestration/verify → hand off Claude Opus if needed.

---

## Context (orient)

Lane: GLLVM.jl after NB2/Beta+X Arc 1–2 close → next = **Gamma+X Arc 0
(identity)**.

| Fact | Evidence at plan-write (2026-08-03) |
| --- | --- |
| #175 Arc 1 MERGED | `9f5133a7` on `origin/main` |
| #176 Windows NA-budget MERGED | `0e241215` · `gh pr view 176` → MERGED |
| #177 Arc 2 OPEN | `mergeable=CONFLICTING` (DIRTY vs main after #176); Documenter green; Julia CI matrix still pending/queued |
| Mirror identity | on `main`: `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md` |
| Dropbox checkout | `claude/jl-bridge-capabilities-20260619` · **PROTECTED** · 137 ahead / 348 behind main |
| Prefer write path | Arc2 worktree for **this** plan artifact (because #177 not merged); execution worktree = fresh off `origin/main` after merges |
| Ada prior rec | identity doc only (~1–2h); no engine until accepted |

Handover (prefer over chat):  
`.worktrees/gllvmjl-nb2-beta-x-arc2-20260802/docs/dev-log/handover/2026-08-03-cursor-handover-nb2-beta-x-arc2-close.md`

---

## Phase 0.25 — Sweep receipt (gate; evidence-cited)

| Surface | Evidence ran | Finding | Call |
| --- | --- | --- | --- |
| **repo git** | `git fetch origin main`; `git log --oneline origin/main -15`; `git worktree list`; `git stash list`; `bash ~/shinichi-brain/tools/branch_drift_check.sh` on Dropbox branch (137 ahead / 348 behind); Arc2 wt `parity/nb2-beta-x-arc2-20260802` @ `c27633f3` = 4 ahead / 3 behind main (ok ≤20); `gh pr view 176/177` | #176 merged; #177 open+conflicting+CI pending; no Gamma+X identity branch/doc yet; Dropbox PROTECTED | **resume nothing for Gamma+X** — **build-the-gap** (new docs lane). Land #177 is separate OWED |
| **twin / sister** | local `gllvmTMB` @ `/Users/z3437171/Dropbox/Github Local/gllvmTMB`; `rg` on `src/gllvmTMB.cpp` (`log_phi_gamma`, fid 4) + `R/fit-multi.R` (“Ordinary Gamma (fid 4) has per-trait log_phi_gamma shape”) + warmstart `rep(0.0, n_traits)` | Twin ordinary Gamma is **per-trait shape** in current TMB surface — tension with Julia bridge **shared** Gamma Option B | **co-opt twin as oracle**; identity doc must reconcile, not ignore |
| **brain** (`search_all_projects: true`) | MCP `search_notes` hybrid: (1) `Gamma dispersion Gamma+X bridge parameterisation GLLVM`; (2) `Gamma shared bridge parity per-trait dispersion under X` | Hits: `2026-06-16-nb1-gamma-bridge-parameterisation-audit`, `2026-06-16-gamma-shared-bridge-parity` (Option B shared), `2026-06-16-julia-per-trait-dispersion-cutpoints-spec`, NB2/Beta+X identity fence on Gamma, handover next=Gamma+X | **reuse** Option B history + **reuse** NB2/Beta Arc 0 pattern; **gap** = Gamma+X (and consistency with no-X bridge) not yet decided |
| **Verdict** | — | Genuinely new = **Gamma+X identity decision** (docs). Do not rebuild NB2/Beta engine. Do not treat 2026-06-16 Option B as automatically final under X without re-cite against current twin. | **build-the-gap** = Arc 0 decision doc only |

External novelty / “first to do X”: **not claimed** — no `/notebook` required for this internal twin-identity lock (offer remains open in Phase 0.5).

---

## WHAT THE BRAIN ALREADY KNOWS

- NB2/Beta public default under X = **per-trait φ + shared site-X** (API B under X); ACCEPTED #174; engine #175; light cells #177 (pending merge).
- That same decision **explicitly fenced Gamma+X**: “Gamma no-X default is still shared / bridge-special; do not silently flip Gamma here.”
- 2026-06-16 Gamma bridge audit → **Option B**: Julia bridge no-X Gamma uses **one shared grouped shape** (`group = fill(1, p)`) to avoid false per-trait Gamma parity vs then-oracle scalar CV; per-trait `fit_gamma_gllvm_grouped` remains available.
- `fit_gllvm` still routes `Gamma()` → shared `fit_gamma_gllvm`; grouped is opt-in (`disp_group`).
- `fit_gllvm_cov` already supports `Gamma()` with **shared** scalar α (covariates.jl `_cov_has_disp(::Gamma)`).
- No `fit_gamma_gllvm_grouped_cov` in tree yet (NB2/Beta analogue exists post-#175).
- Twin gllvmTMB TMB surface allocates **per-trait** `log_phi_gamma` for ordinary Gamma — this is the load-bearing tension the identity doc must resolve.

## WHAT SHINICHI TOLD US

- Invoked **/arc-creation** then **/ultra-plan**; wants **plan for approval only** (Phases 0–2); do **not** execute Phase 3 this turn.
- Prefer Arc Card + Ultra Plan artifacts on disk in a safe worktree (not Dropbox dirt).
- Ada recommendation already on record in handover: Gamma+X identity doc ~1–2h; no engine until accepted.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Hopper — Twin gllvmTMB ordinary Gamma looks per-trait (log_phi_gamma length n_traits)
           · matters because Julia bridge Option B is shared · recommend cite live twin
           main in the decision, not memory of 2026-06-16 alone · Q: is today’s twin
           public default still “shared CV” anywhere, or always per-trait? · default if
           judgment: treat current TMB per-trait as twin target under X unless R API
           forces scalar.
  Fisher — Estimand mismatch risk (shared-α Julia vs per-trait R) is exactly why
           NB2/Beta fenced light cells · recommend same Arc-0-first discipline · Q: none
           beyond twin confirm · default: no light cell until identity + engine.
  Rose   — Claim surface must stay narrow · forbid “full family parity” and silent
           Gamma no-X flip in the same PR as X · recommend Rose fence paragraph in doc ·
           Q: should no-X bridge Option B flip in the same decision or stay deferred? ·
           default if judgment: decide X default + state no-X consistency rule; prefer
           one decision note, two explicit subsections (no-X vs +X).
  Gauss  — Engine shape later should mirror fit_*_grouped_cov · do not design θ packing
           in Arc 0 beyond a one-paragraph preferred path · Q: none · default: “preferred
           surgical path” stub like #174, implementation in Arc 1.
  Ada    — Synthesis: Arc 0 docs-only; recommend per-trait+X as twin default IF twin
           confirm holds; keep shared+X as opt-in; reconcile Option B honestly.
```

## ADA'S RECOMMENDATION

1. **Arc 0 only** (~90 min): write `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`.
2. **Recommended decision (provisional, for Shinichi to lock):** public/twin default for Gamma **with shared site-X** = **per-trait shape α_t + shared γ**, twin to gllvmTMB `log_phi_gamma` / disp.group spirit; shared-α + X remains opt-in via `fit_gllvm_cov` / single group.
3. **No-X bridge Option B:** do **not** silently rewrite in engine this arc; the decision doc should either (a) schedule a consistent no-X flip as a **named follow-up**, or (b) explicitly retain shared no-X bridge with a documented twin caveat — Shinichi chooses (Q2).
4. **No engine / no parity cells** until the doc is ACCEPTED.
5. **#177:** not part of Arc 0 content; treat as **landing gate** — prefer cut Gamma worktree from `origin/main` after #177 merges (rebase conflict is docs/board only).

## DECISIONS LOCKED (from prior arcs; do not reopen)

- NB2/Beta+X = per-trait φ + shared site-X (API B under X).
- Light RCall rtol = `1e-6` (no silent widen).
- Twin rule: API/capabilities mirror; no engine surgery on gllvmTMB.
- Dropbox `claude/jl-bridge-capabilities-20260619` = PROTECTED.
- Never `git add -A`; no push without ask.
- Fences: Ordinal+X, X_lv, ADEMP/coverage, Phylo Model A, full-family-parity claim.

## QUESTIONS STILL OPEN (Phase 0.4 — max 3)

See §Phase 0.4 below — these need Shinichi (or “use your judgment”) before `/goal` treats the decision body as writable-to-acceptance.

---

## Phase 0.4 — Questions for Shinichi

**QUESTION 1** · Twin default for Gamma **under shared site-X**  
**WHY NOW** · Twin TMB shows per-trait `log_phi_gamma`; Julia X path is shared via `fit_gllvm_cov`; without a lock, any Gamma+X cell would be false parity.  
**TEAM VIEW** · Hopper/Fisher/Ada lean per-trait+X (API B under X), shared opt-in.  
**RECOMMENDATION** · Accept **per-trait α + shared site-X** as public/twin default under X.  
**IF YOU DO NOT MIND** · Use that recommendation.  
**WHAT CONTINUES** · Plan artifacts only until you approve G0.

**QUESTION 2** · No-X Gamma bridge Option B (shared group) — same decision note?  
**WHY NOW** · Leaving no-X shared while +X becomes per-trait recreates the NB2/Beta inconsistency that #174 fixed — unless explicitly documented as intentional.  
**TEAM VIEW** · Rose: two subsections in one note; prefer named follow-up over silent flip.  
**RECOMMENDATION** · One decision note with **+X lock now** and a **named no-X consistency follow-up** (do not flip bridge in Arc 0).  
**IF YOU DO NOT MIND** · That split.  
**WHAT CONTINUES** · Arc 0 docs stay docs-only.

**QUESTION 3** · Landing gate for the docs PR worktree  
**WHY NOW** · #177 is CONFLICTING vs main after #176; CI still pending.  
**TEAM VIEW** · Shannon/Ada: do not block planning; block execution worktree cut on post-#177 main when possible.  
**RECOMMENDATION** · Approve plan now; `/goal` waits to cut `docs/gamma-x-identity-*` from `origin/main` **after #177 merges** (or rebase #177 first). Parallel docs-only PR from current main is OK if you say so.  
**IF YOU DO NOT MIND** · Wait for #177 green+merged (or conflict-resolved) before cutting the identity worktree.  
**WHAT CONTINUES** · Background workers may still merge #177; this plan does not merge it.

---

## Phase 0.5 — Grounded search offer

Want a NotebookLM / Ranga pass on Gamma dispersion parameterisations (CV vs shape, gllvm vs TMB history)? **Optional** — not required to lock an internal twin-identity note. Reply yes/no; default = **skip**.

---

## Phase 1 — Decompose (post-receipt)

| ID | In → Out | Dep | Parallel? |
| --- | --- | --- | --- |
| S0 | Live #177/#176 + main tip → landing-gate note in checkpoint | — | with S1 |
| S1 | Twin gllvmTMB Gamma φ surface cite sheet (file:line) | — | with S0 |
| S2 | Julia Gamma routes map (fit_gllvm / grouped / cov / bridge Option B) | — | with S0/S1 |
| S3 | Draft decision doc (mirror #174 structure) | S1,S2 + Q1–Q2 answers | seq |
| S4 | Rose fence + board/START HERE pointers + check-log line | S3 | seq |
| S5 | Mechanical verify (links, no src/, fence grep) | S4 | seq |
| S6 | Melissa reconcile plan-vs-actual (light) | S5 | seq |

**PARALLEL:** {S0, S1, S2}  
**SEQUENTIAL:** S3 ← (S1,S2,Q*) · S4 ← S3 · S5 ← S4 · S6 ← S5

---

## Phase 2 — SLICE TABLE (runnable by a colleague)

| Slice | Member | Model + effort | Bar | Dispatch | Time | Detail (files) | Dep |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **RECON S0** landing gate | landscape-scout / Ada | Composer 2.5 · low | **Cursor Models** | Cursor Agent | 10m | `gh pr view 177/176`; `git fetch`; record merge/CI | — |
| **RECON S1** twin Gamma cite | Hopper | Grok 4.5 or Auto Cost · medium | **Cursor Models** (or Other if Auto) | Cursor Agent | 15m | `gllvmTMB` `src/gllvmTMB.cpp`, `R/fit-multi.R`, warmstart; write cite bullets into decision draft appendix | — |
| **RECON S2** Julia Gamma map | Gauss (scout) | Composer 2.5 · low | **Cursor Models** | Cursor Agent | 15m | `src/families/{gamma,fit_gllvm,covariates,grouped_dispersion}.jl`, `src/bridge.jl`, check-log Option B | — |
| **BUILD S3** decision doc | Ada + Noether | Auto Cost / pinned Claude · high | **Other Models** | Cursor Agent or hand Claude | 45m | `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md` | S1,S2,Q1–2 |
| **BUILD S4** board + fence cascade | Rose (bounded) | Auto Cost · medium | **Other Models** | Cursor Agent | 15m | `docs/dev-log/coordination-board.md`, START HERE / handover pointer, check-log | S3 |
| **MECH-VERIFY S5** | systems-auditor / Rose-mech | Composer 2.5 · low | **Cursor Models** | Cursor Agent | 10m | no `src/` diff; fence strings present; links resolve; cite twin | S4 |
| **VERIFY S6** claim gate | Rose | Claude Opus · high | **hand off** | Claude | 15m | claim-vs-evidence; OK or blockers | S5 |
| **RECONCILE** | Melissa | Auto Cost · medium | **Other Models** | Cursor Agent | 10m | `docs/dev-log/plan-actual/2026-08-03-gamma-x-identity.md` | S6 |

**FAN-OUT:** ≤4 producer children at `/goal` start (S0–S2 parallel, then S3); ceiling Rose once at close.  
**LUNA SUITABILITY (Codex analog):** yes for RECON/MECH-VERIFY — on Cursor map to Composer/Grok.  
**ULTRA EFFORT:** no.  
**ESTIMATE:** ~90–120 min wall-clock · fits one `/goal` session · needs fresh worktree.  
**SEARCH:** none required (Phase 0.5 optional NotebookLM).  
**REVIEW (plan, before run):** Rose confirms this Phase 0.25 receipt is non-vacuous ✓; Fisher/Hopper ok with twin-cite requirement.  
**VERIFY:** decision ACCEPTED text + no engine + Rose OK.  
**CONSOLIDATE:** decision path + after-task `docs/dev-log/after-task/2026-08-03-gamma-x-identity.md` + Arc Card Actuals.  
**RECONCILE:** Melissa required (meaningful close).

**After G0 approval:** **do not Phase-3 in this planning chat.** Hand to `/goal` with the paste-ready prompt below.

---

## OWED classification (handover → this plan)

| Item | Class | Note for this plan |
| --- | --- | --- |
| Land #177 when CI green | **OWED** (separate) | Landing gate for preferred worktree; not Arc 0 content |
| Merge #176 | **DONE** | `0e241215` |
| Arc 1 #175 | **DONE** | on main |
| Gamma+X identity doc | **OWED** (this arc) | plan ready; execution after G0 |
| Gamma+X engine / parity | **OWED later** | fenced until identity ACCEPTED |
| Dropbox checkout | **PROTECTED** | never write |
| Ordinal+X / X_lv / ADEMP / Phylo A | **PROTECTED / DEFERRED** | fence |

---

## Explicit stop

Phases 0–2 complete at this artifact. **No merges, no decision-doc body treated as done, no engine.**

---

## Paste-ready `/goal` prompt (for Shinichi after approval)

```text
/goal

PLATFORM = Cursor. Solo. Execute approved Ultra Plan:
docs/dev-log/plans/2026-08-03-gamma-x-identity-ultra-plan.md
Arc Card:
docs/dev-log/plans/2026-08-03-gamma-x-identity-arc-card.md

Outcome (Arc 0 only, ~90 min): write and land (local commit; push only if I ask)
docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md
mirroring docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md.

Locked answers from G0 (fill after Shinichi replies):
- Q1 Gamma+X default: <per-trait+X | retain-shared | other>
- Q2 no-X Option B: <named follow-up | flip in same note | retain with caveat>
- Q3 worktree gate: <wait #177 merge | cut from current origin/main now>

Hard fences: no src/ engine; no Gamma+X RCall cells; no Ordinal+X; no X_lv;
no ADEMP/coverage; no Phylo Model A; no Dropbox protected writes; no git add -A;
no “full family parity”.

Landing: prefer fresh worktree
.git worktree add ".worktrees/gllvmjl-gamma-x-identity-20260803" \
  -b docs/gamma-x-identity-20260803 origin/main
after #177 is merged (or as Q3 directs). Rehydrate twin gllvmTMB cites first.
Close with check-log + after-task + Rose fence + Melissa plan-actual.
STOP after Arc 0; do not start engine Arc 1.
```
