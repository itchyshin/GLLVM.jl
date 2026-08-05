# Ultra Plan — NB1+X combined Arc 1+2 (engine + light RCall; Phases 0–2 only)

```
🎯 GOAL
PLATFORM = Cursor (solo). Deliverable = (A) fit_nb1_gllvm_grouped_cov implementing
ACCEPTED NB1+X identity (per-trait φ + shared site-X γ) with Julia identity tests
+ bridge/`@formula` routing; AND (B) one light gllvmTMB NB1+X logLik cell green
at rtol 1e-6 via nbinom1() + shared site-X. HEADLINE = finish the NB1 rung of
the R–Julia light-parity ladder in one larger programme (owner chose combined
Arc 1+2 over split chats). IN PARALLEL (cheap): refresh twin nbinom1 /
log_phi_nbinom1 cites; map #175/#178 grouped_cov call sites for surgical copy.
DEFER/FENCE: ADEMP/coverage; Phylo Model A; Gamma no-X Option B; Tweedie/ZIP/+X;
X_lv redesign; Dropbox protected writes; git add -A; push without ask; “full
family parity”; silent rtol widen; second family. DISCIPLINE: verify = identity
tallies + live Δ≤1e-6 (or honest OWED if R absent) + no claim inflation; compute
= laptop (RCall needs local R+gllvmTMB); closure = after-task + check-log +
board/AGENTS + STOP. After G0: hand to /goal (fresh chat preferred for ~4.5 h
execute); do NOT Phase-3 in this planning turn.
```

**ARC PROGRAM:** size · recommended **~4.5 h (3.5–6)** · outcome = NB1+X
engine + one light cell · under-run → stop after green (do not invent Tweedie) ·
closeout = board + Actuals ·
file: `docs/dev-log/plans/2026-08-05-nb1-x-engine-arc12-arc-card.md`.

**Plan-mode note (once):** Phases 0–2 remain **read-only** here. Phase 3 /
`src/` body is **not** executed in this planning turn.

**Phase 0.3b two-bar (AGENT-INFERRED):** Usage not opened this cloud turn.
MODEL-ROUTING (2026-08-01): scout/build → **Cursor Models**; judgment / OH
debug / Rose → **Other Models**. Owner: glance bars before long `/goal`.

---

## Context (orient)

| Fact | Evidence at plan-write (2026-08-05 ~12:14 UTC) |
| --- | --- |
| `origin/main` | `210de76d` = Merge #185 (NB1+X identity ACCEPTED) |
| Identity | `docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md` |
| Engine gap | no `fit_nb1_gllvm_grouped_cov`; bridge throws on nb1+X |
| Mirrors | NB2/Beta #175; Gamma #178 (engine+OH+light); Ordinal #180/#181 |
| Owner choice | Combined Arc 1+2 (A) — larger than identity-only |
| Open PRs | none at plan cut |
| Dropbox | PROTECTED |

---

## Phase 0.25 — Sweep receipt

| Surface | Evidence ran | Finding | Call |
| --- | --- | --- | --- |
| **repo git** | `git fetch`; tip `210de76d`; `gh pr list` empty; new branch `cursor/nb1-x-engine-arc12-fffd` | Identity on main; lane free | **build-the-gap** = engine+light |
| **decision** | #185 ACCEPTED API B under X | Unlocks Arc 1 | **resume** engine path named in decision |
| **src gap** | `rg` fit_nb1_*_cov / `_BRIDGE_X_FAMILIES` | grouped no-X exists; cov + bridge X missing | **implement** mirror of gamma/nb grouped_cov |
| **twin** | prior recon @ `5bf18ab3` (decision) | per-trait `log_phi_nbinom1` | **re-cite** at execute S0 |
| **brain** | shinichi-brain MCP unavailable | — | proceed on repo+twin fetch |
| **Verdict** | — | Combined programme is the gap; do not reopen identity | **build-the-gap** |

---

## WHAT THE BRAIN ALREADY KNOWS

- NB1+X identity ACCEPTED: per-trait φ + shared γ.
- Twin `nbinom1` fid 15 / `log_phi_nbinom1[n_traits]`.
- NB2/Beta/Gamma `*_grouped_cov` is the surgical template.
- Gamma Arc 2 needed **observed Hessian** default for TMB match — watch OH vs
  Fisher for NB1 light cell (identity may still use Fisher for G=1).
- Light RCall ≠ full family parity; rtol 1e-6.

## WHAT SHINICHI TOLD US

- Wants R–Julia parity; finished NB1 identity #185.
- Identity felt quick; chose **(A) combined NB1+X Arc 1+2** as larger next arc.
- Invoked plan path (this Ultra Plan) before execute.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Gauss  — Mirror fit_gamma_gllvm_grouped_cov / fit_nb_gllvm_grouped_cov; reuse
           nb1_grouped_marginal + Xγ offset · Rec: one family only · Default: copy
           Gamma shape, swap NB1(φ) markers.
  Hopper — Light cell must call gllvmTMB nbinom1() + same shared-X formula as
           X cohort · Rec: extend fit_gllvmtmb_parity_loglik_x · Default: :nb1.
  Fisher — Keep identity (Fisher/G=1) separate from R-oracle (likely observed
           Hessian) · Rec: do not widen rtol · Default: Gamma Arc 2 lesson.
  Rose   — Combined arc OK if fence stays one family + light cell ≠ full parity ·
           Rec: explicit stop after green · Q: board #185 tick? Default: fold 10m.
  Ada    — Programme Arc 1+2; STOP after NB1 rung; next family = fresh arc-creation.
```

## ADA'S RECOMMENDATION

1. Approve G0 for **combined NB1+X Arc 1+2** (~4.5 h).
2. Sequence: engine+identity → bridge/formula → light cell → docs → STOP.
3. Fold optional **#185 MERGED** board tick into orient (10 min).
4. If R absent: ship engine+scaffold; mark live oracle OWED (do not fake Δ).
5. Do **not** start Tweedie/ZIP in the same `/goal`.

## DECISIONS LOCKED

- NB1+X identity ACCEPTED (#185).
- Light rtol = 1e-6; no silent widen.
- Twin rule; Dropbox PROTECTED; no `git add -A`; no push without ask.
- Combined programme = owner re-scope of former split Arc 1 then Arc 2.

## QUESTIONS STILL OPEN (Phase 0.4 — at most 2)

### Q1 — Observed Hessian default for NB1 grouped+X Laplace?
**QUESTION:** For the **R-oracle** path, default `hessian=:observed` (Gamma Arc 2
lesson) while identity G=1 uses `:fisher` vs shared cov?  
**WHY NOW:** Prevents false “parity failure” from OH/Fisher mismatch.  
**TEAM VIEW:** Fisher/Hopper — yes, mirror Gamma.  
**RECOMMENDATION:** **Yes** — OH default on R-facing grouped+X; Fisher for
identity cells.  
**IF YOU DO NOT MIND:** Use that.  
**WHAT CONTINUES:** Plan only until G0.

### Q2 — Worktree / branch naming?
**QUESTION:** Execute on cloud `cursor/nb1-x-engine-arc12-fffd` or cut
`fix/nb1-x-grouped-cov-20260805` from `origin/main`?  
**WHY NOW:** Landing hygiene.  
**TEAM VIEW:** Shannon — either; content > name.  
**RECOMMENDATION:** Continue **cloud branch** / or `fix/…` if desktop; one PR.  
**IF YOU DO NOT MIND:** Use current `cursor/nb1-x-engine-arc12-fffd`.  
**WHAT CONTINUES:** Single PR for engine+light+docs.

---

## Phase 0.5 — Grounded search offer

NotebookLM on NB1 vs NB2? **Default: no.**

---

## Phase 1 — Decompose

| ID | Slice | In → Out | Deps |
| --- | --- | --- | --- |
| S0 | Orient + optional #185 board tick + twin re-cite | tip → LOOP/checkpoint notes | — |
| S1 | Map #175/#178 grouped_cov call sites | src → scratch call-site map | — |
| S2 | Implement `fit_nb1_gllvm_grouped_cov` + type + exports | S1 → src | S1 |
| S3 | Bridge X + formula + CI adapters | S2 → bridge/formula/confint as needed | S2 |
| S4 | Julia identity tests | S2 → `test/test_nb1_x_identity.jl` | S2 |
| S5 | MECHANICAL-VERIFY engine | tallies; FD if required; no rtol widen | S3, S4 |
| S6 | Parity helper `:nb1` / `nbinom1()` + `@testset` | S5 → parity tests | S5 |
| S7 | Live RCall cell | S6 → Δ @ 1e-6 (or OWED) | S6 |
| S8 | Docs cascade + board + check-log | S7 → docs | S7 |
| S9 | After-task + Rose + Actuals + STOP | closure | S8 |

**PARALLEL:** S0∥S1  
**SEQUENTIAL:** S2←S1; S3∥S4←S2; S5←S3∧S4; S6←S5; S7←S6; S8←S7; S9←S8  
**Hard stop:** after S5 red, do not start S6–S7.

---

## Phase 2 — SLICE TABLE

| Slice | Member | Model | Bar | Time | Detail | Dep |
| --- | --- | --- | ---: | --- | --- | --- |
| S0 Orient | Ada/Shannon | Composer | Cursor Models | 20–30m | #185 tick; twin SHA refresh | — |
| S1 Call-site map | Gauss | Composer | Cursor Models | 20–30m | gamma/nb grouped_cov map | — |
| S2 Engine | Gauss | Composer/Grok | Cursor Models | 90–120m | fit_nb1_gllvm_grouped_cov | S1 |
| S3 Bridge/formula | Emmy/Hopper | Composer | Cursor Models | 40–50m | _BRIDGE_X_FAMILIES + formula | S2 |
| S4 Identity tests | Curie | Composer | Cursor Models | 35–45m | G=1 Fisher; const φvec | S2 |
| S5 Verify engine | Grace/Gauss | Composer | Cursor Models | 20–30m | tallies; no src thrash | S3,S4 |
| S6 Helper+cell | Hopper/Curie | Composer | Cursor Models | 35–50m | parity_helpers + testset | S5 |
| S7 Live RCall | Curie | Composer | Cursor Models | 25–40m | GLLVM_PARITY_TESTS=1 | S6 |
| S8 Docs/board | Ada | Composer | Cursor Models | 20–30m | capability/parity fence | S7 |
| S9 Rose+close | Rose/Ada | Auto Cost | Other Models | 15–20m | after-task; STOP | S8 |

**FAN-OUT:** S0∥S1; later S3∥S4 · scout=2 · build=1 (S2) · ceiling=1 (Rose)  
**ULTRA EFFORT:** no (default); escalate only if OH/identity stuck  
**ESTIMATE:** ~4.5–6 h wall-clock · may need one compact `/goal` or two sessions
with checkpoint · **prefer fresh chat for execute**  
**VERIFY:** S5 + S7 + S9  
**COMPUTE:** laptop; R+gllvmTMB for S7

---

## Rose plan-review (Ada-as-Rose; no execution)

**Receipt:** Phase 0.25 cites main tip #185 + src gap. **PASS.**

**Critique:**
1. Combining Arc 1+2 is owner-approved scope — OK if hard-stop after S5 red.
2. Must not smuggle Tweedie/ZIP “while we’re here.”
3. OH vs Fisher split is load-bearing (Gamma lesson).
4. Board still may say #185 “open” — fold tick into S0.
5. Cloud may lack R — honest OWED beats fake green.

**Verdict:** OK after G0 + Q1–Q2 (or judgment). **No Phase 3 this turn.**

---

## ASK PERMISSION TO START

### Paste-ready permission question

> Shinichi — Ultra Plan Phases 0–2 for **NB1+X combined Arc 1+2** (~4.5 h:
> `fit_nb1_gllvm_grouped_cov` + one `nbinom1`+X light logLik @ 1e-6). Identity
> #185 already on `main` @ `210de76d`. Fence: one family; ≠ full parity; no
> ADEMP/Phylo/Gamma Option B.
>
> **May I start?** If yes:
> 1. **OH default on R-facing path?** yes (Ada default) / no
> 2. **Branch?** continue `cursor/nb1-x-engine-arc12-fffd` (Ada default) / cut `fix/nb1-x-grouped-cov-20260805`
>
> **yes + use your judgment** → fresh `/goal` execute (prefer new chat).

### Paste-ready `/goal` kickoff

```
/goal NB1+X combined Arc 1+2 (engine + light RCall)
PLATFORM=Cursor. Branch: cursor/nb1-x-engine-arc12-fffd from origin/main @ 210de76d.
Plan: docs/dev-log/plans/2026-08-05-nb1-x-engine-arc12-ultra-plan.md
Arc Card: docs/dev-log/plans/2026-08-05-nb1-x-engine-arc12-arc-card.md
Decision: docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md
Deliverable: fit_nb1_gllvm_grouped_cov + bridge/formula + identity tests +
one nbinom1+X light logLik @ rtol 1e-6.
Fence: no ADEMP; no Phylo Model A; no Gamma Option B; no Tweedie/ZIP; no full
family parity; no rtol widen; no second family.
Verify: identity tallies + Δ; Rose fence. Close: after-task + board + STOP.
```
