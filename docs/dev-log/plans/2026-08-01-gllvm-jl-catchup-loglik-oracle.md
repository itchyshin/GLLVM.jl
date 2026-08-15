# Ultra-plan — GLLVM.jl catch-up: light gllvmTMB logLik oracle

**Date:** 2026-08-01  
**Orchestrator:** Ada (Cursor session)  
**Mode:** Phases 0–2 complete · **G0 awaiting Shinichi approval** · Phase 3 not started  
**Plan file:** `docs/dev-log/plans/2026-08-01-gllvm-jl-catchup-loglik-oracle.md`  
**Brain baseline:** `docs/release/2026-08-01 GLLVM.jl R-Julia parity restart baseline.md` (shinichi-brain)

---

```
🎯 GOAL
Solo platform: Cursor (this lane). After G0, execute via /goal in a fresh Cursor chat — do not grow the planning chat into Phase 3. HANDS TO another surface only if a later slice truly needs live R/Julia toolchain isolation the Cursor workbench cannot provide; do not invent Codex as default executor.

Deliverable: From GLLVM.jl origin/main (05210eca tip at plan time) paired with gllvmTMB origin/main (cee55a07), land live light oracle cells that compare marginal log-likelihood / packed objective vs gllvmTMB (primary), with optional light CRAN gllvm cross-check. Fix parameterization mismatches that block “same model” agreement. Keep bridge/API coding only as needed for transport. Fence ADEMP, coverage, Totoro/DRAC campaigns, and public structured-source claims.

HEADLINE: Make the first live Gaussian gllvmTMB logLik parity cell green on origin/main (validate/replace the DRAFT RCall scaffold in test/parity/), then extend one-part family cells only where the model is the same.

IN PARALLEL (cheap): (a) branch/worktree hygiene from origin/main; (b) inventory open correctness blockers #132/#133/#148/#129 vs family cell order; (c) bridge transport smoke (JuliaCall / opt-in RCall) without heavy fits.

DEFER / FENCE: ADEMP recovery grids · empirical coverage campaigns · Totoro/DRAC · Takahashi/selected-inverse as default next · two-part/ZI family claims · promoting ledger rows to “covered” from n_drift=0 alone · any work based on stale fork claude/jl-bridge-capabilities-20260619 · R engine surgery in gllvmTMB (bridge/JuliaCall only).

DISCIPLINE: Verify = fixed-seed tiny cells, compare logLik/objective first (rotation-invariant); no silent tolerance widening; no push without explicit instruction; stage by name; after each meaningful slice update check-log + after-task; Rose before any public parity claim. Compute = local tiny smokes only (Totoro/DRAC N/A this arc). Closure = green Gaussian cell + ordered family cells or explicit blocked-by-issue receipts + Melissa reconcile.
```

---

## Context (one screen)

- **Code first:** most engine/bridge surface already on `origin/main`; this arc is live numerical oracle + same-model blockers, not a greenfield port.
- **Ledger ≠ parity:** session + brain baseline state a 2026-08-01 live probe on worktrees `/tmp/gllvmjl-parity-restart-20260801` (`05210eca`) × `/tmp/gllvmtmb-parity-restart-20260801` (`cee55a07`) → `n_drift=0`, `unregistered=0`. **Scout caveat:** durable in-repo `n=0` after-task/check-log evidence is dated **2026-07-04**, not 2026-08-01 — re-run the drift probe on main tips in `/goal` A0 and record it before treating today as ledger-clean. Zero ledger drift still does **not** mean logLik agreement.
- **Scaffold exists:** `test/parity/` opt-in RCall suite; Gaussian cell is **DRAFT**, never live-validated (`test/parity/README.md`).
- **Working checkout hazard:** Dropbox tree is still on stale fork `claude/jl-bridge-capabilities-20260619` @ `6694f43d` (**137 ahead / 290 behind** `origin/main`) — restart base is **`origin/main` only**.
- **Twin R checkout hazard:** gllvmTMB Dropbox tree is on `claude/profile-coverage-remeasure-20260718` (R 0.6 coverage lane) — do not mix that lane into Julia logLik work; use `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07` or a fresh main worktree.
- **Mission Control:** curated `status/gllvmTMB.json` `next_safe_action` remains R 0.6 / coverage-decision focused — do **not** overwrite that focus; Julia twin next action = this plan path (PROPOSE MC tweak only).

---

## Phase 0.25 — Prior-work sweep RECEIPT (gate)

| Surface | Evidence cited | Finding | Call |
|---|---|---|---|
| **repo git** | `git status -sb`; `git rev-parse --short HEAD` → `6694f43d`; `git rev-list --left-right --count origin/main...HEAD` → behind=290 ahead=137; `bash ~/shinichi-brain/tools/branch_drift_check.sh` → **DRIFTED 290 behind**; `git worktree list` shows `/tmp/gllvmjl-parity-restart-20260801` @ `05210eca`; scout `[landscape-scout](61510174-9fac-4a0d-b1c4-2b3f227d8dee)` (completed) | Stale fork is not a resume base; main tip + restart worktree already exist; `test/parity/` present; `codex/v1-bridge-clean-20260703` is **same SHA as `origin/main`** (`05210eca`) — optional clean tip alias; `docs/dev-log/v1-contract/` is on the stale-fork checkout (baseline: absent from main — confirm on `/tmp` main worktree in A0) | **resume main worktree / new branch from `origin/main`** — **do not resume** `claude/jl-bridge-capabilities-20260619` for engine work |
| **twin gllvmTMB** | `git -C …/gllvmTMB status -sb`; `origin/main=cee55a07`; worktree `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`; `tests/testthat/test-julia-bridge.R` + `R/julia-bridge.R` drift helpers; Dropbox branch is R coverage lane (606 behind main) | Bridge ledger machinery + JuliaCall tests live on main; R Dropbox checkout is wrong lane for this arc | **reuse** main twin worktree + bridge transport; **co-opt** existing `test-julia-bridge.R` for transport smoke; no R engine surgery |
| **brain** | MCP `search_notes` query `"GLLVM.jl R-Julia parity restart logLik oracle catch-up"` + `"R-Julia parity restart baseline"` with `search_all_projects: true`; `read_note` project=`shinichi-brain` title `2026-08-01 GLLVM.jl R-Julia parity restart baseline`; also hits on per-trait dispersion / ordinal cuts specs | Baseline filed 2026-08-01; D-94 Julia sequenced behind R; parameterization debt documented (#132/#133/#148/#129 open via `gh issue view`) | **reuse** restart baseline + catch-up bar already agreed; **build-the-gap** = live logLik cells + same-model fixes |
| **Verdict** | — | Genuine gap is **live numerical logLik/objective parity** and **parameterization blockers**, not ledger rows and not rebuilding bridge from the stale fork | **reuse scaffold + main code · resume from origin/main worktrees · build live oracle cells + triage #132/#133/#148 (defer #129 unless it blocks logLik)** |

**External prior art (Phase 0.5):** NotebookLM grounded search **OFFERED, not run** — this arc is twin-implementation parity, not a novelty claim. Ask Shinichi below if he wants a scoped NotebookLM pass on NB2/Beta/ordinal parameterizations vs gllvm/gllvmTMB docs.

---

## Phase 0.3 — Live model roster (+ 0.3b Cursor two-bar)

| Item | Status |
|---|---|
| Volatile roster | `memory/MODEL-ROUTING.md` Cursor side refreshed **2026-08-01**: Cursor Models = Composer 2.5 + Grok 4.5; Other Models = ≥$400 API (Auto Cost / Claude / GPT); on-demand off |
| Settings → Usage (live) | **UNVERIFIED this session** — no programmatic Settings→Usage read; continue with MODEL-ROUTING capture (~1% Cursor Models · ~0% Other Models at 2026-08-01 screenshot) and route using both bars on purpose |
| Dispatch available | Cursor Task subagents: Composer bar for scout; Auto/Claude bar for judgment; `/goal` for arc execution after G0 |
| Codex Luna note | Not the solo executor. Scout this planning pass used Cursor Composer explore (`composer-2.5-fast`). If a later HANDS TO Codex occurs, use `codex-tier-run.sh` for Luna — not native |

---

## WHAT THE BRAIN ALREADY KNOWS

- Restart tips + ledger probe + “do not use stale jl-bridge fork” — baseline note 2026-08-01.
- Capability ledger zero-drift ≠ fit-level parity.
- Opt-in `test/parity/` DRAFT Gaussian RCall cell; rotation-invariant quantities only (logLik, Σ_y, σ_eps).
- Open same-model landmines: #132 NB2 φ granularity, #133 ordinal cuts, #148 Beta φ, #129 CI scale (+ #128 H² denom, related).
- Catch-up bar (this chat): code first; light gllvmTMB logLik oracle; no ADEMP/coverage/Totoro-DRAC; tiny local checks OK.
- MC board for gllvmTMB is R 0.6 decision-focused — leave it.

## WHAT SHINICHI TOLD US (this session)

- Ultra-plan Phases 0–2 only; stop at G0; paste-ready `/goal` for post-approval.
- PLATFORM = Cursor; solo GOAL platform = Cursor.
- Restart base = `origin/main`, not stale fork.
- Light oracle = gllvmTMB marginal logLik/objective primary; light gllvm OK.
- Fence ADEMP/coverage/structured-source public claims.
- Agents just refreshed (state 3) — do not re-emit stubs.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Hopper — DRAFT RCall cell may call CRAN gllvm API shape, not gllvmTMB; extractor fields (logL vs logLik) are the first live-fail mode · matters because a “red” cell can be transport not numerics · recommend validate call shape against gllvmTMB main first · Q: primary oracle path = RCall-from-Julia or JuliaCall-from-R? · default: RCall opt-in suite for Julia-owned cells + reuse R test-julia-bridge for transport
  Gauss  — #132/#148/#133 are model-identity bugs; Binomial/Poisson likely same-model without those fixes · recommend order: Gaussian → Binomial/Poisson → dispersion/cutpoint fixes before NB2/Beta/Ordinal claims · Q: align Julia to per-trait φ or gate those families? · default: align Julia to R public surface
  Fisher — logLik oracle ≠ CI oracle; #129 is inference-scale · recommend defer #129 from this arc unless it contaminates objective · Q: keep CI out? · default: yes, defer
  Rose   — n_drift=0 must not be narrated as parity done; fence claim language · recommend after-task claim guard on every cell · Q: none if fence holds · default: fence holds
  Ada    — synthesis: main-based lane; Gaussian headline; Bin/Pois next; param fixes before NB2/Beta/Ordinal; defer CI/#129; MC propose-only
```

## ADA'S RECOMMENDATION

Approve this plan. Execute post-G0 via `/goal` on a **fresh Cursor chat**, branching from `origin/main` (prefer `/tmp/gllvmjl-parity-restart-20260801` or a new worktree — not the stale Dropbox fork). Primary success = live Gaussian logLik cell vs gllvmTMB; then Binomial + Poisson; then fix #132/#148/#133 before claiming those families.

## DECISIONS LOCKED (from session + brain)

- Restart = `origin/main` tips above.
- Oracle = gllvmTMB logLik/objective; light gllvm optional.
- No ADEMP / coverage / Totoro-DRAC this arc.
- No push without explicit instruction.
- No Phase 3 in the planning chat.

## QUESTIONS STILL OPEN (≤3 — Phase 0.4)

**Q1 — Family order after Gaussian**  
**QUESTION:** After the Gaussian logLik cell is live, land Binomial+Poisson cells next (likely same-model), or jump straight into #132/#148/#133 engine alignment?  
**WHY NOW:** Determines first `/goal` arcs and fan-out.  
**TEAM VIEW:** Gauss/Hopper prefer Bin/Pois cells first.  
**RECOMMENDATION:** Gaussian → Binomial → Poisson logLik cells, then serialization of #132/#148/#133 before NB2/Beta/Ordinal cells.  
**IF YOU DO NOT MIND:** Use the recommendation.  
**WHAT CONTINUES:** Lane setup + Gaussian cell validation are safe either way.

**Q2 — Dispersion / cutpoint alignment direction**  
**QUESTION:** For #132/#148 (and #133), align Julia engine to R’s per-trait / cutpoint contract, or keep Julia scalar/shared and permanently gate “same model” claims?  
**WHY NOW:** Load-bearing twin contract; affects weeks of engine work.  
**TEAM VIEW:** Gauss — align to R public surface.  
**RECOMMENDATION:** Align Julia toward R (per-trait φ; ordinal location contract), with decision notes under `docs/dev-log/decisions/`.  
**IF YOU DO NOT MIND:** Align to R; gate family oracle cells until landed.  
**WHAT CONTINUES:** Gaussian/Bin/Pois cells proceed without waiting.

**Q3 — #129 CI scale in or out**  
**QUESTION:** Keep #129 (Wald vs profile σ_phy scale) inside this arc, or fence it to a follow-on inference slice?  
**WHY NOW:** Scope creep vs Fisher’s logLik-first bar.  
**TEAM VIEW:** Fisher/Rose — out unless it blocks objective.  
**RECOMMENDATION:** Fence #129 (and #128 H²) outside this logLik arc.  
**IF YOU DO NOT MIND:** Fence out.  
**WHAT CONTINUES:** logLik cells unaffected.

**Phase 0.5 offer (not a blocker):** Want a grounded NotebookLM pass on NB2/Beta/ordinal parameterization vs gllvmTMB docs before the alignment slices? Reply yes/no; default = **no** (twin code + issues suffice).

---

## ARC PROGRAM

Mode: **size** (value-ranked rungs; not a fixed wall-clock box).  
Recommended total: ~1–2 Cursor `/goal` sessions (or one long session with fresh-chat handovers).

| Arc | Intent | ~time | Gate |
|---|---|---|---|
| A0 | Lane from `origin/main` + twin main worktree; abandon stale fork for edits; **re-run** `.gllvm_julia_capability_drift` probe and write today's n/unregistered into check-log | 15–40 min | OPEN if Dropbox checkout still on stale fork |
| A1 | Live-validate Gaussian logLik oracle (`test/parity/`) | 1–3 h | OPEN on first green claim |
| A2 | Binomial + Poisson fixed-seed logLik cells | 1–2 h | — |
| A3 | #132 / #148 dispersion alignment (Julia→R) | 3–8 h | OPEN — API/param change |
| A4 | #133 ordinal location/cuts alignment | 3–8 h | OPEN — API/param change |
| A5 | NB2 / Beta / Ordinal logLik cells after A3/A4 | 1–3 h | claim fence |
| Close | check-log + after-task + Rose claim audit + Melissa reconcile | 30–60 min | — |

Under-run: stop after A1–A2 with explicit blocked receipts for A3+.

---

## SLICE TABLE

Bar key: **Cursor Models** = Composer 2.5 / Grok 4.5 · **Other Models** = Auto Cost / pinned Claude/GPT · **hand off** = only if needed later.

| ID | Slice | Member | Model + effort | Bar | ~time | Deps | Detail / output |
|---|---|---|---|---|---|---|---|
| S0 | RECON (mechanical) | landscape-scout | Composer 2.5 · low | Cursor Models | 15m | — | Done in planning; refresh if tips move. Map: main SHAs, parity paths, issue list |
| S1 | Lane bootstrap from `origin/main` | Ada + julia-engineer | Auto Cost · med | Other Models | 20–40m | S0 | New branch/worktree; **do not edit** stale fork; re-run capability-drift probe on main tips; record SHAs + n_drift in check-log |
| S2 | Gaussian live RCall/gllvmTMB call-shape fix | Hopper (r-julia-translator) | Auto Cost / pinned mid · med–high | Other Models | 1–2h | S1 | Rewrite DRAFT bits in `test/parity/test_gaussian_parity.jl` against live gllvmTMB; primary = logLik |
| S3 | Tiny fixed-seed Gaussian logLik cell green | Curie + Gauss | Auto Cost · med | Other Models | 1h | S2 | Opt-in `GLLVM_PARITY_TESTS=1`; tighten tolerances only with evidence |
| S4 | Bridge transport smoke (JuliaCall) | Hopper | Composer 2.5 · low–med | Cursor Models | 30–45m | S1 | From gllvmTMB main worktree: focused `test-julia-bridge` / setup smoke — no heavy fits |
| S5 | Binomial + Poisson logLik cells | Hopper + Curie | Auto Cost · med | Other Models | 1–2h | S3 | New parity tests; same rotation-invariant rule |
| S6 | #132 NB2 φ alignment design→impl | Gauss + Noether | pinned Claude/GPT · high | Other Models | 3–6h | S5 + Q2 | Per-trait vs scalar; decision note + tests; **gate** until approved direction |
| S7 | #148 Beta φ alignment | Gauss | Auto Cost · high | Other Models | 2–4h | S6 pattern | Mirror NB2 contract |
| S8 | #133 ordinal cuts/location | Gauss + Fisher | pinned · high | Other Models | 3–6h | Q2 | Same-model prerequisite for ordinal cell |
| S9 | NB2/Beta/Ordinal logLik cells | Curie + Hopper | Auto Cost · med | Other Models | 1–2h | S6–S8 | Only after same-model fixes |
| S10 | Claim fence + docs honesty | Rose (systems-auditor) | Auto Cost · med | Other Models | 30–45m | S3+ | README/AGENTS/check-log: ledger≠parity; no coverage/ADEMP claims |
| S11 | MECHANICAL-VERIFY | landscape-scout / reproducibility-engineer | Composer 2.5 · low | Cursor Models | 20–30m | S3–S10 | Commands ran, artifacts non-empty, SHAs recorded, opt-in tests invoked |
| S12 | Judgment verify | Rose + Fisher | pinned · high | Other Models | 30–45m | S11 | Adversarial: same estimand? tolerances honest? |
| S13 | RECONCILE | Melissa | Auto Cost · med | Other Models | 20–30m | Close | `docs/dev-log/plan-actual/2026-08-01-gllvm-jl-catchup-loglik-oracle.md` |

**PARALLEL:** {S4 ∥ S2} after S1; {S10 drafting} anytime after S3.  
**SEQUENTIAL:** S1→S2→S3→S5→(S6→S7→S8)→S9→S11→S12→S13.

---

## FAN-OUT BUDGET

- checkpoint=`gllvm-jl-catchup-loglik-20260801`
- new children ≤6 per batch; typical batch: 1 scout + 2–3 build + 0–1 ceiling review
- scout=yes (Composer) · build=majority · ceiling=Rose/Fisher at claim gates only
- reuse child ids across repair loops

## LUNA SUITABILITY

**yes (Cursor scout bar)** — RECON + MECHANICAL-VERIFY on Composer/Grok.  
(Codex Luna N/A unless HANDS TO Codex later; then `--require-scout` on tiered CLI.)

## ULTRA EFFORT

**no** (default).

## SEARCH

Inline repo/brain only. NotebookLM tier-b **offered** (see Q Phase 0.5); not run.

## CONTEXT BRAKE / COMPACTIONS / LANE

- parent input: planning session — hand off to `/goal` fresh chat after G0  
- **LANE RECEIPT after G0:** `START A FRESH TASK` — use paste-ready `/goal` prompt below  
- D-43 panel: only if promoting a public “parity done” claim (default: not this arc’s close)

## REVIEW (plan critique — before execution)

- **Rose:** Sweep receipt present and non-vacuous — **PASS** (four surfaces + citations). Claim fence must survive execution.  
- **Gauss/Hopper:** Decomposition matches landmines; Gaussian-first is correct; do not claim NB2/Beta/Ordinal before param fixes.  
- **Fisher:** Keep CI/#129 out unless objective blocked.

## VERIFY

1. `git rev-parse --short HEAD` on lane = descendant of `origin/main` (not stale fork).  
2. Opt-in parity run shows Gaussian logLik agreement with cited numbers.  
3. Twin SHAs recorded; no ADEMP/coverage language introduced.  
4. Open issues #132/#133/#148 either fixed with tests or explicitly blocked.  
5. Rose judgment pass before any README/board claim upgrade.

## RECONCILE

Melissa row **required** at meaningful close → `docs/dev-log/plan-actual/2026-08-01-gllvm-jl-catchup-loglik-oracle.md`.

## ESTIMATE

- Wall-clock to A1–A2: ~half day  
- Through A3–A5: multi-day if alignment chosen  
- Agents/batches: 3–5 batches · fits **one `/goal` arc-loop with fresh-chat handovers**, not one unbounded planning chat  
- Compute: **local tiny only** — Totoro/DRAC **N/A** (fenced)

## Mission Control (PROPOSE ONLY — vault write)

Do **not** overwrite R 0.6 `next_safe_action`. Optional curated note addendum:

> Julia twin next_safe_action (secondary): execute approved plan `GLLVM.jl/docs/dev-log/plans/2026-08-01-gllvm-jl-catchup-loglik-oracle.md` from `origin/main` logLik oracle catch-up — does not displace R coverage decision.

---

## Post-G0 — hand off to `/goal` (do not start Phase 3 here)

Paste-ready prompt is in the orchestrator return contract / below.

---

## G0

**Awaiting Shinichi approval.** No Phase 3 started. Reply with approvals / “use your judgment” on Q1–Q3 (+ optional NotebookLM yes/no), then paste the `/goal` prompt into a **fresh Cursor chat**.
