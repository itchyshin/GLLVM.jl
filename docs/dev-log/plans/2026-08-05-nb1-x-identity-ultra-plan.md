# Ultra Plan — NB1+X dispersion identity Arc 0 (Phases 0–2 only)

```
🎯 GOAL
PLATFORM = Cursor (solo). Deliverable = ACCEPTED (or explicitly rejected-with-fence)
NB1+X dispersion-identity decision note under docs/dev-log/decisions/, mirroring
docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md and the
Gamma+X identity note — docs-only; NO engine, NO NB1+X light RCall, NO ADEMP.
HEADLINE = lock twin default for NB1 under shared site-X (per-trait φ vs retain
shared) before any fit_nb1_*_cov work. Theme = R–Julia parity (continue light
gllvmTMB track after Ordinal+X #181). IN PARALLEL (cheap): (1) recon twin
gllvmTMB NB1 / nbinom1 / negative.binomial1 φ packing + formula/X surface;
(2) recon Julia fit_nb1_* + bridge “nb1 no covariate kernel” + grouped no-X
default. DEFER/FENCE: NB1+X engine; X_lv; ADEMP/coverage; Phylo Model A; Gamma
no-X Option B flip; Tweedie/ZIP/+X; Dropbox protected writes; git add -A; push
without ask; “full family parity”. DISCIPLINE: verify = decision cites twin
file:line + Rose fence + no src/; compute = laptop; closure = after-task +
check-log + board/AGENTS snapshot + STOP — next engine arc only after
acceptance. After G0: hand to /goal (fresh chat preferred); do NOT Phase-3 in
this planning turn.
```

**ARC PROGRAM:** size · recommended Arc 0 ≈ **75 min (60–100)** · outcome =
NB1+X identity decision doc only · under-run → stop (do not invent engine) ·
closeout = board pointer + Actuals ·
file: `docs/dev-log/plans/2026-08-05-nb1-x-identity-arc-card.md`.

**Plan-mode note (once):** Phases 0–2 remain **read-only** here. Phase 3 /
decision-doc body-as-done is **not** executed in this planning turn.

**Phase 0.3b two-bar (AGENT-INFERRED):** Settings → Usage not opened this cloud
turn. MODEL-ROUTING (2026-08-01): Cursor Models = Composer/Grok; Other Models =
≥$400 API (on-demand off). Scout → Cursor Models; judgment/prose decision body
→ Other Models; owner glance bars before `/goal`.

---

## Context (orient)

Lane: GLLVM.jl after X-cohort through Ordinal+X (#170–#181) + board hygiene
(#183/#184). START HERE was idle; owner chose **R–Julia parity** next →
**NB1+X identity Arc 0**.

| Fact | Evidence at plan-write (2026-08-05 ~12:00 UTC) |
| --- | --- |
| `origin/main` | `13d97b13` (Merge #184) |
| Open PRs | none at plan cut (this plan branch opens next) |
| NB2/Beta+X identity | ACCEPTED #174; engine #175; light #177 |
| Gamma+X identity | ACCEPTED; engine+light #178 |
| Ordinal+X | identity #179; engine #180; light #181 |
| NB1 no-X | `fit_gllvm` → `fit_nb1_gllvm_grouped` (per-species φ) |
| NB1 +X | bridge **ArgumentError** — “no covariate kernel” / documented follow-up |
| `*_grouped_cov` for NB1 | **absent** (NB2/Beta/Gamma have it) |
| Dropbox checkout | PROTECTED |
| `/ask-brain` | shinichi-brain MCP **unavailable** this cloud run |

Authoritative mirrors:  
`docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md`  
`docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`  
Board: `docs/dev-log/coordination-board.md`

---

## Phase 0.25 — Sweep receipt (gate; evidence-cited)

| Surface | Evidence ran | Finding | Call |
| --- | --- | --- | --- |
| **repo git** | `git fetch origin main`; tip `13d97b13`; `gh pr list --state open` empty; branch `cursor/nb1-x-identity-arc0-fffd` | Idle main; no competing open PR | **build-the-gap** = new docs lane |
| **Julia routes** | `rg` `fit_nb1_*` / bridge nb1 / formula cov routing | no-X grouped default live; +X kernel missing; formula routes NB2/Beta/Gamma cov only | **gap** = identity + later engine |
| **bridge / tests** | `src/bridge.jl` nb1 follow-up strings; `test/test_bridge_x.jl` throws on nb1+X; no NB1 in `test_x_covariate_parity.jl` | X parity correctly fenced today | **do not** invent light cell in Arc 0 |
| **twin / sister** | local gllvmTMB path **not mounted** in this cloud VM | Cannot cite live twin file:line this turn | **execute S0 must** open twin (or Hopped cite from known prior) before ACCEPTED body |
| **brain** | MCP catalog = `cursor-cloud` only | Vault unavailable | **proceed on repo evidence**; amend if vault contradicts |
| **Verdict** | — | Genuinely new = **NB1+X identity decision**. Do not start `fit_nb1_*_cov` here. | **build-the-gap** = docs Arc 0 |

External novelty: **not claimed** — no `/notebook` required (offer in 0.5).

---

## WHAT THE BRAIN ALREADY KNOWS

_(repo-local; vault MCP unavailable)_

- Public twin default under shared site-X for NB2/Beta/Gamma = **per-trait
  dispersion + shared γ** (API B under X).
- Ordinal under X = per-trait cutpoints + shared γ (different estimand).
- NB1 no-X public path already per-species via `fit_nb1_gllvm_grouped`.
- Bridge explicitly lists nb1 as X follow-up — load-bearing gap.
- Light RCall ≠ full family parity; rtol 1e-6; no silent widen.
- Phylo Model A parked; Dropbox PROTECTED.

## WHAT SHINICHI TOLD US

- After hygiene STOP, asked what next → wants **R–Julia parity**.
- Ada recommended NB1+X identity; owner invoked **`/arc-creation`** then
  **`/ultra-plan`** for NB1+X identity Arc 0 (typos `/arc-creatoin`,
  `/ulttra-plan` normalized).
- Plan for approval only this turn.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Hopper — Twin NB1 surface naming varies (nb1 / nbinom1 / negative.binomial1);
           must cite live packing (per-trait vs scalar) before locking API B.
           Rec: S0 twin recon mandatory · Default if judgment: expect per-trait
           like NB2 if TMB allocates log_phi_nbinom1[p] (confirm, don’t assume).
  Fisher — Estimand mismatch risk identical to NB2+X pre-#174 · Rec: Arc 0
           first; no light cell until engine · Default: per-trait+X if twin
           confirms.
  Rose   — Claim must stay “identity lock” · forbid full family parity · Rec:
           fence Gamma Option B / Tweedie/ZIP in same PR · Default: one family.
  Ada    — NB1+X identity as capability Arc 0 for R–Julia parity ladder.
  Noether — NB1 φ is linear-variance scale (Var=μ(1+φ)); document scale map vs
           NB2 1/r so Arc 1 doesn’t mis-pack.
```

## ADA'S RECOMMENDATION

1. **Arc 0 only (~75 min):** write
   `docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md`.
2. **Provisional decision (for Shinichi to lock):** public/twin default for NB1
   **with shared site-X** = **per-trait φ_t + shared γ**, twin to gllvmTMB
   disp.group spirit **if S0 confirms per-trait**; shared-φ + X remains opt-in.
3. **No engine / no parity cells** until ACCEPTED.
4. **No-X:** already per-trait grouped — likely **no Option-B-style flip**;
   decision should state that honestly (contrast Gamma).
5. After acceptance: fresh chat for engine Arc 1 (`fit_nb1_gllvm_grouped_cov`).

## DECISIONS LOCKED (not reopened)

- NB2/Beta/Gamma under X = per-trait disp + shared γ (ACCEPTED).
- Ordinal under X = per-trait cutpoints + shared γ (ACCEPTED).
- Light RCall rtol = `1e-6`.
- Twin rule: API/capabilities mirror; no engine surgery on gllvmTMB.
- Dropbox PROTECTED; never `git add -A`; no push without ask.
- Board idle until this lane takes START HERE.

## QUESTIONS STILL OPEN (Phase 0.4 — at most 3)

### Q1 — NB1 default under shared site-X?
**QUESTION:** Lock **per-trait φ + shared γ** as twin-facing default under X
(API B under X), contingent on S0 twin confirm?  
**WHY NOW:** Determines Arc 1 scope.  
**TEAM VIEW:** Hopper/Fisher/Ada lean yes if twin per-trait.  
**RECOMMENDATION:** **Yes**, with explicit “if twin confirms; else stop and
rewrite.”  
**IF YOU DO NOT MIND:** Use that.  
**WHAT CONTINUES:** Plan only until G0.

### Q2 — No-X NB1 consistency subsection?
**QUESTION:** Treat no-X as already aligned (grouped default) with only a short
consistency subsection, or open a second decision about shared `fit_nb1_gllvm`
vs grouped?  
**WHY NOW:** Avoid Gamma-style Option B confusion.  
**TEAM VIEW:** Ada — short subsection; no flip needed.  
**RECOMMENDATION:** **Short subsection; retain current no-X grouped default.**  
**IF YOU DO NOT MIND:** That.  
**WHAT CONTINUES:** Docs-only.

### Q3 — Take START HERE immediately?
**QUESTION:** May this docs lane set board START HERE to NB1+X identity now
(parallel to execute), or wait until G0 `/goal`?  
**WHY NOW:** Board is idle; avoid false OWED before approval.  
**TEAM VIEW:** Shannon — set START HERE in execute S3 after G0.  
**RECOMMENDATION:** **Wait for G0 `/goal`** to move START HERE.  
**IF YOU DO NOT MIND:** Wait.  
**WHAT CONTINUES:** Plan PR may exist without claiming active OWED.

---

## Phase 0.5 — Grounded search offer

NotebookLM on NB1 vs NB2 variance functions / gllvm history? **Default: no**
(internal twin lock). Say yes if wanted.

---

## Phase 1 — Decompose

| ID | Slice | In → Out | Deps |
| --- | --- | --- | --- |
| S0 | RECON twin NB1 φ + X/formula | twin tip → `docs/dev-log/plans/scratch/nb1-x-twin-recon.md` | — |
| S1 | RECON Julia NB1 routes + bridge X gap | src → `docs/dev-log/plans/scratch/nb1-x-julia-recon.md` | — |
| S2 | Draft identity decision (mirror NB2/Beta) | S0+S1 → `docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md` | S0, S1, Q1–Q2 |
| S3 | Board + START HERE + AGENTS snapshot + check-log | decision → pointers | S2 |
| S4 | MECHANICAL-VERIFY | links; no `src/`; fence phrases | S2, S3 |
| S5 | Rose claim/fence review | OK / blockers | S4 |
| S6 | After-task + Arc Card Actuals | closure | S5 |
| S7 | Melissa RECONCILE (light) | plan vs actual | S6 |

**PARALLEL:** {S0, S1}  
**SEQUENTIAL:** S2 ← S0∧S1; S3 ← S2; … → S7

**Stop rule:** If S0 shows twin NB1 under X is scalar-only, S2 becomes
**retain-shared + named expansion** — do not force API B.

---

## Phase 2 — SLICE TABLE

| Slice | Member | Model + effort | Bar | Dispatch | Time | Detail | Dep |
| --- | --- | --- | --- | ---: | --- | --- | --- |
| S0 RECON twin | Hopper | Composer/Grok · low–med | **Cursor Models** | agent | 15–20 min | nbinom1 / negative.binomial1 packing + X | — |
| S1 RECON Julia | Gauss/Emmy | Composer · low–med | **Cursor Models** | agent | 15–20 min | fit_nb1_*, bridge X gap, formula | — |
| S2 Draft decision | Ada+Noether | Auto Cost / Claude · med–high | **Other Models** | `/goal` parent | 35–45 min | Mirror NB2 identity; honest φ scale | S0,S1 |
| S3 Board pointers | Ada | Composer · low | **Cursor Models** | agent | 5–10 min | board + AGENTS snapshot | S2 |
| S4 MECHANICAL-VERIFY | Grace | Composer · low | **Cursor Models** | agent | 5–10 min | greps; no src/ | S2,S3 |
| S5 Rose | Rose | Auto Cost · high | **Other Models** | judgment | 10–15 min | fence + claim | S4 |
| S6 After-task | Ada | Auto Cost · med | **Other Models** | parent | 10 min | after-task + Actuals | S5 |
| S7 RECONCILE | Melissa | Auto Cost · low–med | **Other Models** | agent | 10 min | plan-actual | S6 |

**FAN-OUT:** S0∥S1 · scout=2 · build=0 · ceiling=0–1 (Rose)  
**ULTRA EFFORT:** no  
**SEARCH:** none (default)  
**ESTIMATE:** ~75–100 min · one `/goal` session  
**VERIFY:** S4 + S5  
**CONSOLIDATE:** decision + board + after-task  
**COMPUTE:** laptop only — twin recon needs local/gllvmTMB access (cloud may
lack R twin; if so, mark S0 OWED with Hopped cites or run S0 on desktop)

---

## Rose plan-review (decomposition — Ada-as-Rose; no execution)

**Receipt check:** Phase 0.25 cites git/gh/rg; twin path and brain honestly
marked unavailable. **PASS** with note: S0 twin cites are a **hard gate** before
ACCEPTED status.

**Critique:**
1. Correct to Arc-0-first (bridge already throws on nb1+X).
2. Correct to fence Gamma Option B and other families.
3. Risk: cargo-culting API B without twin confirm — stop rule present.
4. Risk: cloud execute without gllvmTMB — must not fake file:line cites.
5. Do **not** expand S2 into `fit_nb1_*_cov` stubs.

**Verdict:** OK after G0 + Phase 0.4 (or “use your judgment”).
**Do not Exit into execution in this planning chat.**

---

## ASK PERMISSION TO START

This Ultra Plan stops at Phase 2. **No Phase 3.**

### Paste-ready permission question

> Shinichi — Ultra Plan Phases 0–2 for **NB1+X dispersion identity Arc 0** are
> written (~75 min, docs-only, mirror NB2/Beta/Gamma; theme = R–Julia parity).
> `main` @ `13d97b13` idle. Bridge already fences nb1+X. Twin path not mounted
> in this cloud VM — execute S0 must cite live gllvmTMB (or Hopped prior) before
> ACCEPTED.
>
> **May I start?** If yes, please answer:
> 1. **NB1 under X default?** per-trait φ + shared γ if twin confirms (Ada default)
> 2. **No-X subsection?** short / already aligned (Ada default) vs reopen shared vs grouped
> 3. **START HERE?** move on `/goal` execute (Ada default) vs leave idle until merge
>
> Saying **yes + use your judgment** starts `/goal` that drafts
> `docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md` only (no
> engine, no RCall cell).

### Paste-ready `/goal` kickoff (after G0)

```
/goal NB1+X dispersion identity Arc 0 (docs-only)
PLATFORM=Cursor. Branch: cursor/nb1-x-identity-arc0-fffd or
docs/nb1-x-identity-20260805 from origin/main @ 13d97b13.
Plan: docs/dev-log/plans/2026-08-05-nb1-x-identity-ultra-plan.md
Arc Card: docs/dev-log/plans/2026-08-05-nb1-x-identity-arc-card.md
Deliverable:
docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md
Fence: no src/; no NB1+X RCall; no ADEMP; no Phylo Model A; no Gamma Option B
flip; no Tweedie/ZIP; no push unless asked; no full family parity.
Verify: Rose fence + twin file:line (hard gate). Close: after-task + board +
Actuals + STOP.
```
