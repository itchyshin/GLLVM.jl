# Ultra Plan — Gamma+X engine Arc 1 (`fit_gamma_gllvm_grouped_cov`)

> **Phases 0–2 only.** Plan artifacts for G0 approval. **Do NOT execute Phase 3 /
> engine code in this planning chat.** After G0 → hand to `/goal`.

```
🎯 GOAL
PLATFORM = Cursor (solo for planning; execute via /goal after G0 — hand live
Julia verify / long arc-loop to Claude Opus or Codex Sol if the session grows).
DELIVERABLE = Engine Arc 1 implementing the LOCKED Gamma+X identity
(docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md): export
fit_gamma_gllvm_grouped_cov + GammaGroupedCovFit (per-group/per-trait shape α
+ shared site-X γ), route bridge X and @formula+X for gamma through that path,
keep fit_gllvm_cov(...; family=Gamma()) as shared-α + X opt-in, ship Julia-only
identity tests (G=1+fisher ≈ shared cov; constant-αvec marginal), docs cascade
+ check-log + after-task + Rose fence. HEADLINE = close the twin gap under X for
Gamma the same way #175 closed it for NB2/Beta — without claiming light RCall
parity. IN PARALLEL (cheap): (1) re-cite twin log_phi_gamma file:line on fresh
gllvmTMB origin/main; (2) map #175 call-sites to Gamma analogues
(grouped_dispersion / bridge / formula / confint / tests). DEFER/FENCE: light
RCall Gamma+X Arc 2; no-X Option B flip; Ordinal+X; X_lv; ADEMP/coverage; Phylo
Model A; “full family parity”; Dropbox checkout writes
(claude/jl-bridge-capabilities-20260619 PROTECTED); git add -A; push without
ask; merging or conflict-resolving #177 inside this goal (fence check-log/board
hunks that collide with #177). DISCIPLINE: no silent rtol widen · verify =
printed identity/test tallies · compute = laptop (Totoro only if smoke needs
it; no DRAC) · stage by path · after-task + Rose before claim · STOP at Arc 1 —
Arc 2 is a separate /goal.
After G0 approval: hand to /goal (do NOT Phase-3 in the planning chat).
```

**ARC PROGRAM:** size · recommended Arc 0 ≈ **3.5 h (2.5–4.5)** · outcome =
`fit_gamma_gllvm_grouped_cov` + identity + bridge/formula + docs · under-run →
optional docs polish only (do **not** start RCall Arc 2) · closeout = Actuals on
Arc Card + Melissa light reconcile.

**Plan-mode note (once):** this Cursor subagent turn is **not** in client Plan
mode; Phases 0–2 remain **read-only except plan-file writes**. Phase 3 / `src/`
edits are **not** executed here.

**Phase 0.3b two-bar (AGENT-INFERRED):** Settings → Usage was not opened in this
subagent turn. Use MODEL-ROUTING (2026-08-01): Cursor Models = Composer 2.5 /
Grok 4.5; Other Models = ≥$400 API (on-demand off). Owner: glance both bars
before `/goal`. Scout → Cursor Models; judgment/prose → Other Models;
orchestration/verify/HPC → hand off Claude Opus / Codex Sol.

---

## Context (orient)

| Fact | Evidence at plan-write (2026-08-03) |
| --- | --- |
| Identity Arc 0 DONE locally | `docs/gamma-x-identity-20260803` @ `b657b27e` (+ `8af4f00f`); worktree clean |
| Decision LOCKED | `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md` — **per-trait α + shared site-X** under X; no-X Option B = named follow-up |
| Mirror engine | #175 MERGED (`2846d9da`) — `fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov` |
| #177 | OPEN, `mergeable=CONFLICTING` — **out of scope**; fence shared docs |
| Dropbox checkout | `claude/jl-bridge-capabilities-20260619` · **PROTECTED** |
| Prefer write path for **this** plan | gamma identity worktree `docs/dev-log/plans/` (clean) |
| Prefer execute path after G0 | **fresh** `fix/gamma-x-grouped-cov-20260803` off `origin/main` (or post-identity-PR main) — not the docs branch long-term; never Dropbox |

**Recon (file paths — load-bearing):**

| Surface | Path / cite |
| --- | --- |
| NB2 grouped_cov shape | `src/families/grouped_dispersion.jl` — `NBGroupedCovFit`, `fit_nb_gllvm_grouped_cov` (~L266–380): θ=`[β; γ; pack(Λ); log r…]`, `O=_build_offset(X,γ)`, `hessian=:observed` default / `:fisher` for identity |
| Beta grouped_cov | same file ~L609–671 `fit_beta_gllvm_grouped_cov` |
| Gamma no-X grouped | same file ~L871+ `fit_gamma_gllvm_grouped` — already has `offset=` into `gamma_grouped_marginal_loglik_laplace` |
| Shared cov Gamma | `src/families/covariates.jl` `_cov_has_disp(::Gamma)=true`; `fit_gllvm_cov` |
| Bridge X | `src/bridge.jl` ~L1115–1135 — NB2/Beta → grouped_cov; **Gamma falls through** to `fit_gllvm_cov` |
| Formula X | `src/formula.jl` ~L113–120 — same split |
| Identity tests | `test/test_nb_beta_x_identity.jl` (G=1+fisher ≈ `fit_gllvm_cov`) |
| Twin | `gllvmTMB` `src/gllvmTMB.cpp` `PARAMETER_VECTOR(log_phi_gamma)` + fid-4 per-trait `exp(log_phi_gamma(t))`; `R/fit-multi.R` “Ordinary Gamma … per-trait log_phi_gamma”; disp.group-style collapse still possible on twin |

---

## Phase 0.25 — Sweep receipt (gate; evidence-cited)

| Surface | Evidence ran | Finding | Call |
| --- | --- | --- | --- |
| **repo git** | `git status -sb` (gamma wt clean on `docs/gamma-x-identity-20260803`); `git rev-parse` → `b657b27e`; `git log -15`; `git worktree list`; `bash ~/shinichi-brain/tools/branch_drift_check.sh` → **2 ahead / 0 behind** `origin/main`; `gh pr view 175/177`; `git show --stat 2846d9da` | Identity ACCEPTED locally; #175 pattern on main; **no** `fit_gamma_gllvm_grouped_cov` yet; #177 conflicting (docs) | **resume** identity decision · **build-the-gap** = Gamma grouped_cov engine · **do not** merge #177 here |
| **twin / sister** | local `gllvmTMB` `rg` `log_phi_gamma` / Ordinary Gamma on `src/gllvmTMB.cpp` + `R/fit-multi.R` (tip `ab49638b` / `origin/main` `19e9cedd`; decision cited older `840d1da8` — **re-cite at execute**) | Ordinary Gamma remains **per-trait** `log_phi_gamma` length `n_traits` | **co-opt** twin as estimand oracle; no engine surgery on R |
| **brain** (`search_all_projects: true`) | MCP `search_notes` hybrid: (1) `gamma X dispersion identity grouped_cov`; (2) `NB2 Beta fit_grouped_cov Arc 1 gamma log_phi_gamma`; (3) `gamma-x dispersion identity Arc 0 per-trait alpha` | Hits: 2026-06-16 Option B / cutpoints spec; NB2/Beta identity fence; Gamma shared bridge parity; **no** prior Gamma+X engine attempt beyond the locked decision + after-task “next = engine Arc 1” | **reuse** #175 pattern + locked decision · **gap** = Gamma `*_grouped_cov` + routing + identity |
| **Verdict** | — | Genuinely new = one-family #175 mirror for Gamma under X. Do not rebuild NB2/Beta. Do not flip no-X Option B. Do not land #177. | **build-the-gap** = engine Arc 1 only |

External novelty claim: **not claimed** — no `/notebook` required (Phase 0.5 offer remains open).

---

## WHAT THE BRAIN / REPO ALREADY KNOWS

- Gamma+X twin default **LOCKED**: per-trait α + shared site-X; shared-α + X = opt-in; no-X Option B = named follow-up only.
- NB2/Beta+X engine pattern exists and is proven (#175): grouped Laplace + `_build_offset` + bridge assemble + formula dispatch + identity tests.
- `fit_gamma_gllvm_grouped` already supports `offset=` — cov path should thread `O = Xγ` the same way NB/Beta do.
- Bridge/formula still send Gamma+X to shared `fit_gllvm_cov`.
- Light RCall for Gamma+X is **fenced** until this engine + identity greens (then Arc 2).
- #177 is a parallel OWED on NB2/Beta Arc 2 docs conflicts — not content of this goal.

## WHAT SHINICHI TOLD US

- Approved: Arc Creation + Ultra Plan **Phases 0–2 only** for **next arc after** Gamma+X identity.
- Deliverable = plan artifacts; show ultra-plan for **G0 approval**; **no** Phase 3 / engine code this turn.
- RCall Arc 2 **not** in this arc unless clearly split and deferred (we defer).
- Fences as listed in the GOAL block; #177 out of scope.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Gauss  — Mirror fit_nb/beta_gllvm_grouped_cov surgically in grouped_dispersion.jl;
           reuse gamma_grouped_marginal_* + offset · matters: least-new-surface path ·
           recommend one fitter + GammaGroupedCovFit · Q: analytic Gamma grad under X?
           · default if judgment: keep FD/LBFGS like current grouped Gamma / NB cov;
           do not open analytic-gradient redesign in Arc 1.
  Hopper — Bridge/formula must route gamma like NB2/Beta under X or twin default stays
           false · recommend _bridge_assemble_grouped_cov extend Union{…, GammaGroupedCovFit}
           · Q: none · default: full #175 routing, not fitter-only.
  Fisher — Identity before any RCall · G=1+fisher ≈ fit_gllvm_cov; constant αvec check ·
           recommend new test_gamma_x_identity.jl (or extend nb_beta file) · Q: none ·
           default: no Arc 2 cells in this PR.
  Rose   — Claim: “Gamma+X public/bridge path = per-trait α + shared γ” only after green
           identity · forbid full-family / Option B / #177 merge claims · recommend fence
           check-log append that does not try to resolve #177 conflict hunks · Q: docs PR
           for identity first? · default: engine PR may include already-ACCEPTED decision
           if identity not yet on main; prefer separate docs PR when easy.
  Emmy   — Export + docstring + runtests include; Aqua/JET via Pkg.test before claim ·
           recommend match #175 file set · Q: none.
  Ada    — Synthesis: 3.5h size-mode Arc 1 = full one-family #175 mirror; defer Arc 2 +
           Option B + #177; fresh engine worktree after G0.
```

## ADA'S RECOMMENDATION

1. **Scope = full one-family #175 mirror** (fitter + export + confint adapters +
   bridge + formula + identity tests + docs). **Defer** light RCall Arc 2.
2. **Do not** flip no-X Option B / `fit_gllvm` Gamma default in this PR.
3. **Fresh** `fix/gamma-x-grouped-cov-20260803` worktree for execution; plan
   files may live on the identity wt.
4. **#177:** leave alone; if check-log/board edits collide, append a **new dated
   section** or minimal pointer rather than resolving the conflict PR.
5. **Landing:** identity docs PR can land separately; engine PR cites the
   ACCEPTED decision (include the decision file only if still not on `main`).

## DECISIONS LOCKED (do not reopen)

- Per-trait α + shared site-X = twin default under X (API B).
- Shared-α + X = opt-in via `fit_gllvm_cov`.
- No-X Option B = named follow-up (not this arc).
- Light RCall rtol = `1e-6` (Arc 2 later; no silent widen ever).
- Twin rule: API/capabilities mirror; no gllvmTMB engine surgery.
- Dropbox protected checkout; no `git add -A`; no push without ask.
- Fences: Ordinal+X, X_lv, ADEMP/coverage, Phylo Model A, full-family-parity, #177.

## QUESTIONS STILL OPEN (Phase 0.4 — max 3)

**QUESTION 1** · Worktree / base for execution  
**WHY NOW** · Identity is ACCEPTED locally (`docs/gamma-x-identity-20260803`) but
may not be on `main` yet; #177 still dirties shared docs.  
**TEAM VIEW** · Rose/Ada: prefer fresh `fix/…` off `origin/main`; bundle
decision note only if docs PR not merged.  
**RECOMMENDATION** · Cut `fix/gamma-x-grouped-cov-20260803` from
`origin/main`; if identity doc absent, cherry-pick / include the ACCEPTED
decision file in the engine PR. Do not build engine on Dropbox.  
**IF YOU DO NOT MIND** · That recommendation.  
**WHAT CONTINUES** · Plan-only until G0.

**QUESTION 2** · Arc 1 scope breadth  
**WHY NOW** · Could ship fitter+identity only and leave bridge/formula for a
rung — but then public twin default under X stays false until routing lands.  
**TEAM VIEW** · Hopper/Ada: full #175 routing in the same arc (one family).  
**RECOMMENDATION** · Full mirror for Gamma (fitter + bridge + formula + CI
adapters + identity + docs); **no** RCall cells.  
**IF YOU DO NOT MIND** · Full mirror.  
**WHAT CONTINUES** · Arc 2 stays a separate `/goal`.

**QUESTION 3** · Analytic Gamma gradient under X?  
**WHY NOW** · Shared Gamma recently defaults analytic Laplace gradient; grouped
cov NB path uses FD LBFGS.  
**TEAM VIEW** · Gauss: do not redesign AD in Arc 1.  
**RECOMMENDATION** · Match NB/Beta grouped_cov (FD/`autodiff=:finite` LBFGS);
leave analytic-grad under X as a later perf follow-up.  
**IF YOU DO NOT MIND** · FD path for Arc 1.  
**WHAT CONTINUES** · Reversible; not a public API fork.

---

## Phase 0.5 — Grounded search offer

Want a NotebookLM / Ranga pass on Gamma shape vs CV / gllvm history? **Optional** —
not required to implement an internal twin of existing `log_phi_gamma`. Default =
**skip**.

---

## Phase 1 — Decompose (post-receipt)

| ID | In → Out | Dep | Parallel? |
| --- | --- | --- | --- |
| S0 | Landing gate: identity-on-main? #177 status; cut engine wt | — | with S1 |
| S1 | Twin re-cite sheet (file:line on current gllvmTMB main) | — | with S0 |
| S2 | #175 → Gamma call-site map (files + Union types) | — | with S0/S1 |
| S3 | Implement `GammaGroupedCovFit` + `fit_gamma_gllvm_grouped_cov` | S2 | seq |
| S4 | Export + confint adapters + bridge assemble Union | S3 | seq |
| S5 | Formula + bridge X route `gamma` | S4 | seq (or with S4 if careful) |
| S6 | Identity tests + wire `runtests.jl` | S3 | after S3; can overlap S4/S5 |
| S7 | Docs cascade + surgical check-log (fence #177) | S5,S6 | seq |
| S8 | Mechanical verify (tallies, no rtol widen, fence grep) | S7 | seq |
| S9 | Rose claim gate + after-task | S8 | seq |
| S10 | Melissa reconcile | S9 | seq |

**PARALLEL:** {S0, S1, S2} then build chain.  
**SEQUENTIAL:** S3 ← S2 · S4/S5/S6 ← S3 · S7 ← S5,S6 · S8 ← S7 · S9 ← S8 · S10 ← S9

---

## Phase 2 — SLICE TABLE (runnable by a colleague)

| Slice | Member | Model + effort | Bar | Dispatch | Time | Detail (files) | Dep |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **RECON S0** landing / wt | landscape-scout / Ada | Composer 2.5 · low | **Cursor Models** | Cursor Agent | 15m | `gh pr` identity/#177; `git fetch`; cut `fix/gamma-x-grouped-cov-20260803` | — |
| **RECON S1** twin cite | Hopper | Grok 4.5 / Auto Cost · medium | **Cursor Models** or **Other Models** | Cursor Agent | 15m | `gllvmTMB` `log_phi_gamma` / fit-multi; note line drift vs decision | — |
| **RECON S2** #175 map | Gauss (scout) | Composer 2.5 · low | **Cursor Models** | Cursor Agent | 20m | Diff `2846d9da` file list → Gamma analogues | — |
| **BUILD S3** fitter | Gauss / julia-engineer | Composer 2.5 or Terra · high | **Cursor Models** (or hand Codex) | `/goal` Agent | 90m | `src/families/grouped_dispersion.jl` | S2 |
| **BUILD S4** export+CI | Emmy + Fisher | Composer 2.5 · medium | **Cursor Models** | `/goal` Agent | 35m | `src/GLLVM.jl`, `src/confint_family.jl` | S3 |
| **BUILD S5** bridge+formula | Hopper | Composer 2.5 · medium | **Cursor Models** | `/goal` Agent | 35m | `src/bridge.jl`, `src/formula.jl` | S4 |
| **BUILD S6** identity tests | Curie / Fisher | Composer 2.5 · medium | **Cursor Models** | `/goal` Agent | 40m | `test/test_gamma_x_identity.jl` (+ `runtests.jl`); update `test_bridge_x.jl` oracle | S3 |
| **BUILD S7** docs fence | Rose (bounded) + Ada | Auto Cost · medium | **Other Models** | Cursor Agent | 25m | response-families, capability-status, gllvmtmb-parity; **surgical** check-log/board (avoid #177 conflict hunks) | S5,S6 |
| **MECH-VERIFY S8** | systems-auditor | Composer 2.5 · low | **Cursor Models** | Cursor Agent | 20m | identity + bridge_x + formula tallies; fence strings; no rtol widen | S7 |
| **VERIFY S9** claim gate | Rose | Claude Opus · high | **hand off** | Claude | 20m | claim-vs-evidence; OK or blockers | S8 |
| **RECONCILE** | Melissa | Auto Cost · medium | **Other Models** | Cursor Agent | 10m | `docs/dev-log/plan-actual/2026-08-03-gamma-x-engine.md` | S9 |

**FAN-OUT:** ≤4 producer children early (S0–S2 parallel); then serial build (or 2 builders if disjoint files). Ceiling Rose once at close.  
**LUNA SUITABILITY:** yes for RECON/MECH-VERIFY → Composer/Grok on Cursor.  
**ULTRA EFFORT:** no.  
**ESTIMATE:** ~3.5 h wall-clock · one `/goal` session (or hand Codex for live Julia) · needs **fresh engine worktree**.  
**SEARCH:** none required.  
**REVIEW (plan, before run):** Rose confirms Phase 0.25 receipt non-vacuous ✓; Gauss ok with FD LBFGS default.  
**VERIFY:** identity tests + targeted bridge/formula; full `Pkg.test()` before merge claim.  
**CONSOLIDATE:** after-task `docs/dev-log/after-task/2026-08-03-gamma-x-grouped-cov.md` (date may slip).  
**RECONCILE:** Melissa required (meaningful engine close).  
**FAN-OUT BUDGET:** checkpoint=`gamma-x-engine-arc1` · new children ≤6 · scout 0–1 · build 2–4 · ceiling ≤1.  
**CONTEXT BRAKE / COMPACTIONS / LANE:** after Arc 1 close → `LANE: START A FRESH TASK` for Arc 2 RCall.

### Execute-phase notes (fences for whoever runs `/goal`)

1. **Never** write the Dropbox checkout `claude/jl-bridge-capabilities-20260619`.
2. **Never** `git add -A` / `git add .`; stage by path.
3. **Do not** merge, rebase-as-goal, or “clean up” #177 inside this arc. If
   `docs/dev-log/check-log.md` or `coordination-board.md` conflict with #177,
   prefer a **new dated append** / pointer file over resolving #177’s hunks.
4. **Do not** add Gamma+X RCall cells or flip no-X Option B.
5. **Do not** claim full family parity / ADEMP / Ordinal+X / Phylo Model A / X_lv.
6. Push / PR only when Shinichi asks.
7. Identity checks must use `hessian=:fisher` for G=1 vs `fit_gllvm_cov` (same
   spirit as #172 / #175); public/bridge default stays `hessian=:observed`.

---

## Members plan-review (before execution)

| Lens | Verdict on this plan |
| --- | --- |
| **Rose** | Phase 0.25 receipt cites commands/queries ✓; claim surface correctly defers Arc 2 / Option B / #177. Blocker if execute tries to “also land #177.” |
| **Gauss** | Decomposition matches #175; FD LBFGS default is correct for Arc 1. |
| **Hopper** | Routing slices present — good; fitter-only would be incomplete twin. |

---

## `/goal` handoff block (paste after G0)

```text
/goal Gamma+X engine Arc 1 — fit_gamma_gllvm_grouped_cov

PLATFORM: Cursor (or hand Codex for live Julia). Read first:
- docs/dev-log/plans/2026-08-03-gamma-x-engine-ultra-plan.md
- docs/dev-log/plans/2026-08-03-gamma-x-engine-arc-card.md
- docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md

WORKTREE: cut fresh
  .worktrees/gllvmjl-gamma-x-grouped-cov-20260803
  -b fix/gamma-x-grouped-cov-20260803 origin/main
(If identity decision not on main yet, include/cherry-pick the ACCEPTED decision note.)

DO:
1. Implement fit_gamma_gllvm_grouped_cov + GammaGroupedCovFit mirroring
   fit_nb/beta_gllvm_grouped_cov (#175 / grouped_dispersion.jl).
2. Route bridge X + @formula+X for gamma; keep fit_gllvm_cov shared-α opt-in.
3. Identity tests (G=1+fisher ≈ fit_gllvm_cov; constant αvec); update bridge_x oracles.
4. Docs cascade + surgical check-log; after-task; Rose fence.
5. Verify with printed tallies; no rtol widen.

FENCE: no RCall Arc 2; no Option B flip; no Ordinal+X/X_lv/ADEMP/Phylo Model A;
no full-family-parity claim; no Dropbox writes; no git add -A; no push without ask;
do not merge #177; avoid resolving #177 conflict hunks in check-log/board.

STOP when Arc 1 green + after-task written. Next separate /goal = Gamma+X light RCall Arc 2.
```

---

## G0 approval phrase

Reply exactly (or equivalent):

> **G0 approved — run Gamma+X engine Arc 1 via `/goal` (full #175 mirror for Gamma; no RCall; fence #177).**

Or: **“use your judgment”** on Q1–Q3 → Ada defaults above apply, then same `/goal` handoff.

---

## Short skim summary (for Shinichi before opening the file)

- **What:** Engine Arc 1 only — `fit_gamma_gllvm_grouped_cov` = per-trait α + shared site-X, twin to `log_phi_gamma` / #175.
- **Not:** RCall Arc 2, Option B flip, #177 merge, Dropbox writes.
- **Time:** ~3.5 h (2.5–4.5), inferred from one-family fraction of #175.
- **Pattern:** copy NB2/Beta grouped_cov θ packing + offset + bridge/formula route.
- **Verify:** Julia identity tests first; no rtol widen.
- **Next after land:** separate Gamma+X light RCall `/goal`.
