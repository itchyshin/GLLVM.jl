# GLLVM twin ultra-plan — arcG coverage + D-220 proof (Cursor orchestrator)

**Authored:** 2026-09-04 · Ada consolidator · revised after Julia-lane close + Shinichi update  
**Worktrees:** JL `@ 9ed4181c` (ahead 1, level with `origin/main` `5518d98d`) · R `@ 5784dab65` (**merged** `origin/main` through `495cde24d` @ 2026-09-04 hygiene)  
**Status:** **STOP AT G0 — plan approved here; execution via `/goal` stub below**

---

```
🎯 GOAL
Solo platform: Cursor (this twin orchestrator chat)
Deliverable: ONE arc — coverage harness that can see latent scores, D-220 Cell-1 proof locally, then the authorized arcG ordination_uncertainty() coverage campaign on Totoro, with results landed in-repo (not chat)
HEADLINE: R: harness design (local, unbounded) → Cell-1 real fit → arcG grid (~5.0 core-h CEILING for fits only, 9×500 fits on Totoro)
IN PARALLEL: Fill LOOP/GOAL both repos · JL: standby (parity harness available; no Julia fit required for arcG)
DEFER: --r-ref + Core070 D3 rebind (after campaign unless Cell-1 blocked) · MSPL D-157 park · bulk hygiene (633 unpushed / 91 worktrees) · foreign R lanes (report-only; stay out)
DISCIPLINE: harness-before-Totoro · verify=object-level (see §Traps) · compute=ControlMaster ~/.ssh/cm-* (D-64, no fresh Duo) · ≤150 cores (D-143) · STOP if measured *fit* cost departs ~5.0 core-h ceiling (D-139) · results=dev/gapclose/arcG/ + check-log + PR · closure=G0 then /goal
```

---

## PRIORITY STACK (NOW)

Numbered by importance for **this milestone** — campaign is authorized; do not re-ask.

| # | What | Why it ranks here | Blocks what | Effort |
|---|---|---|---|---|
| **1** | **R:** `git merge origin/main` in twin worktree | **DONE** 2026-09-04 → `5784dab65` (#1264–#1267) | Harness, Cell-1, campaign script | — |
| **2** | **R:** **Coverage harness design** — reach latent scores for coverage comparison | **DONE** 2026-09-04 — `dev/gapclose/arcG/coverage-harness.R` uses `extract_latent_scores()` | Cell-1, Totoro | — |
| **3** | **R:** Cell-1 proof — `load_all` + **one real arcG fit cell** through harness | **DONE** 2026-09-04 — Cell-1 PASS (3 seeds, 40×1 dims, cov machinery numeric); receipt `dev/gapclose/arcG/coverage-results.md` | Totoro launch | — |
| **4** | **R:** Dispatch full arcG coverage grid to Totoro | **NEXT** — `run-grid-totoro.sh` prepared; cm-totoro socket live; await parent "Totoro go" | Evidence for ordination_uncertainty() coverage | **~5 core-h** |
| **5** | **R:** Land results under `dev/gapclose/arcG/` + append `docs/dev-log/check-log.md` + open **PR** (reporting contract) | Shinichi reads the **repo**, not chat; a PR implies push of a results branch | Maintainer review, register update | **hours** (post-campaign) + **Shinichi:** push-for-PR gate (#2 below) |
| **6** | **BOTH (later):** `--r-ref` joint contract + Core070 D3 (`loading_profile` estimand) | Ledger integrity gap (R reads working tree; D3 blocks last rebind row) — **does not block harness, Cell-1, or arcG** | Trustworthy joint `CLOSURE: PASS`; final ledger rebind | **hours** + **Shinichi decisions** |
| **7** | **Inherited mess / foreign lanes** — stay out; report-only | 21 foreign R lanes still live; 633 unpushed / 91 worktrees are triage, not blockers | Nothing on the critical path | **report-only** |

### If we only do three things

1. **Merge R main** into the twin worktree (pick up #1264+#1265).  
2. **Build the coverage harness** (latent-score path visible) **and prove one real R fit** through it (`load_all` + Cell-1 — not a skip).  
3. **Run the arcG grid on Totoro** and land results in `dev/gapclose/arcG/` with a PR.

Everything else waits. Do **not** treat “~5 core-h” as the whole job — harness design is local work upstream of Totoro.

---

## HOW FAR FROM PARITY

### Already closed (on mains — cite shas)

| Claim | Evidence |
|---|---|
| **Core 0.7.0 + AGHQ parity programme** | GLLVM.jl `2524b787` → main `5518d98d` (PR #279); ledger 505 required = **292 bound + 213 dispositioned**; suite 13,327 pass |
| **Reverse parity gap programme (R)** | gllvmTMB gap-close #1239–#1258 landed; main through `65301cf62` (#1264 pre-run) and **`ff29fba5e`** (#1265 lane-close handover) |
| **Prior lanes CLOSED** | gllvmTMB PR **#1265** "Status of this repo for the incoming lane"; Julia handover PR #279; **both repos are this Cursor twin's now** |
| **arcG design + pre-run** | #1260 design; #1264 pre-run merged; §9a on main: sparse solve **non-factor** (640 RHS cols = 18 ms); grid **~5.0 core-h ceiling**; design defect fixed (`n_traits=4` not 8 at largest measured cell) |

### Not yet true *in this Cursor lane*

| Gap | Meaning |
|---|---|
| **`devtools::load_all` never proven here** | ~~Trap #1~~ **DONE** 2026-09-04 — Cell-1 via `load_all` 3.2 s |
| **Coverage harness not built** | ~~**DONE** 2026-09-04** — `coverage-harness.R` + Cell-1 PASS |
| **Capability proof (step 5)** | **DONE** 2026-09-04 — `load_all` + Cell-1 harness end-to-end |
| **arcG campaign never dispatched** | **NEXT** — Totoro batch prepared (`run-grid-totoro.sh`); not submitted |
| **Paired R↔Julia cell not run here** | Julia harness exists (`test/parity/`); not required for arcG but still owed for full twin-bridge proof |

### Joint-contract / estimand debt (does not block arcG)

| Item | Status |
|---|---|
| **`--r-ref`** | R `parity_ledger.R` reads **working tree**; Julia pins `--ref` — quiet `CLOSURE: PASS` risk under one lane |
| **Core070 D3** | ✅ **DECIDED 2026-09-04** — renamed to `loading_profile_exploratory` + shim; ledger row reclassified (`26819554` slice) |
| **Core070 D1–D2, D4–D6** | Unsigned; gate deeper ledger hardening and phylo/grouping surfaces |
| **Five verification traps** | See §Traps below — verify the **object**, not the report about it |

### Campaign / scale — explicitly NOT the parity gap

The **authorized arcG grid** (9 cells × 500 seeds = 4,500 fits) is **coverage evidence** for `ordination_uncertainty()`, not proof that Core 0.7.0 engine parity was never done. Pre-run resolved cost; campaign is **GO** — do not conflate "campaign not run" with "parity never done."

**Verdict (one sentence):** Harness + Cell-1 **DONE** in twin worktree @ `afe161781`; **Totoro 9×500 grid is NEXT** (batch prepared, await "Totoro go").

---

## WHAT THE BRAIN ALREADY KNOWS (D-220 etc.)

| Decision / artefact | Lock (use as given) |
|---|---|
| **D-220** (accepted 2026-09-04) | One **Cursor orchestrator lane** holds **both** gllvmTMB + GLLVM.jl; campaigns on **Totoro** via ControlMaster; **Cell-1 proof-first inside the arc** (load_all + one real fit before bulk dispatch). Default **no push** — ask once at G0 for results PR. |
| **Campaign authorization** (Shinichi 2026-09-04 update) | arcG coverage **re-confirmed GO** to this lane; **do not re-ask**; clean Totoro start |
| **D-157** | MSPL B1 **PARK** — no undraft #1077 without new Design + tests + explicit G0 |
| **D-139** | Estimate always; pre-run **DONE** (#1264, §9a); **STOP and re-report** if measured campaign cost departs from **~5.0 core-h ceiling** |
| **D-143** | Totoro **≤150 cores** unless explicit per-run yes |
| **D-64** | Reuse live **ControlMaster** `~/.ssh/cm-*`; fresh SSH triggers Duo |
| **D-50** | Sim/recovery campaigns on **Totoro/DRAC**, never GHA artifacts |
| **Frozen oracle** | `b4d5fee64def88bc768dda1f1f77c29b295edd86` (gllvmTMB 0.7.0) — JL pinned in `tools/parity_ledger.py:44`; R working-tree read is the integrity gap (`--r-ref` deferred) |
| **Prior lane CLOSED** | R main `ff29fba5e` (#1265 + #1264); Julia main `5518d98d` (#279) |
| **H² twin pattern** | `shinichi-brain/docs/dev-log/handover/2026-09-02-h2-twin-one-lane-start-prompt.md` — cite spend **RULE** not stale % |
| **Mission Control** | `/p/gllvmTMB/` covers both repos; focus predates D-220 — **report-only** |

**Core070 maintainer decision set** (`docs/dev-log/core070/maintainer-decision-set-2026-09-03.md`): **D3 DECIDED/implemented 2026-09-04**; D1–D2, D4–D6 unsigned.

---

## Phase 0.25 sweep receipt

One line per surface — Phase 0 checkpoints + main tip re-read 2026-09-04 (post-#1265).

| Surface | Command / source | Receipt |
|---|---|---|
| **JL git** | `git status -sb`; `git log -3` | Worktree clean; `@ 9ed4181c` ahead 1 (LOOP scaffold); `origin/main` = **`5518d98d`** (PR #279) — **level, no merge needed** |
| **JL preflight** | `lane_preflight.sh GLLVM.jl-gllvm-twin-20260904` | No foreign lane (12h); coord board committed ✅ |
| **R git** | `git status -sb`; `git log origin/main -1` | Twin `@ 5784dab65` merged; `origin/main` tip **`495cde24d`** (#1267 handover addendum) |
| **R preflight** | `lane_preflight.sh gllvmTMB-gllvm-twin-20260904` | FOREIGN LANE ACTIVE (21 lanes) — **stay out**; twin proceeds in worktree only |
| **Prior lane close** | `gh pr view 1265`; handover #1265 | **CLOSED** — repo free for incoming Cursor lane |
| **Brain D-220** | `DECISIONS.md` L7954+ | Accepted 2026-09-04; campaign transport locks |
| **Mission Control** | `curl …/p/gllvmTMB/status.json` | Live; focus stale vs D-220 — not edited |
| **arcG pre-run §9a** | `origin/main:dev/gapclose/arcG/coverage-design.md` | 640 RHS = 18 ms; fit dominates 4–27×; **~5.0 core-h ceiling**; `n_traits=4` design fix; raw CSV on main |
| **Campaign state** | Prior lane handover | Prepared locally only; **never Totoro**; no partial results |
| **LOOP kit** | `9ed4181c` / `4580e7f10` | Scaffolded; placeholders remain — fill at G0+ |

---

## Phase 0.6 route check

**Destination (one sentence):** arcG coverage campaign complete with per-cell results under `dev/gapclose/arcG/`, check-log entry, and PR — preceded by coverage harness (latent scores visible) and Cell-1 `load_all` + one real fit receipt in this lane.

**Route knowable:** YES — all three Phase 0.6 checks pass. Campaign authorized; pre-run resolved cost; slices have concrete outputs.

**Knowable now (no Shinichi block):**

- Merge R `origin/main` before first R edit.
- Harness: reach latent scores for coverage comparison (reimplement-local is expected if no accessor; see gate #6).
- Cell-1: one arcG grid cell locally **through harness** (smallest — e.g. `n_units=40, d=1, n_traits=4` per `coverage-design.md` §4).
- Totoro dispatch: existing campaign script path under `dev/gapclose/arcG/`; log per-fit timings (§9a qualification #1).
- D-139 halt rule: if aggregate measured **fit** cost **>** ~5.0 core-h ceiling → STOP, re-report, do not silently continue (harness/prep time excluded).

**Decide-with-Shinichi (not campaign re-asks):**

| Item | Why it waits |
|---|---|
| Approve **this plan** | G0 gate #1 |
| **Push results branch for PR** | Default local-only (D-220); PR requires explicit yes — gate #2 |
| Foreign R lanes — non-interference | Confirm twin stays in worktree; gate #3 |
| **`--r-ref` + Core070 D1–D6** | After campaign; gate #4–#5 |
| **Latent-score accessor vs local reimplement** | Public API change if accessor; gate #6 |

**Route map:**

```
[G0: this plan] ──► merge R main ──► harness design (latent scores)
                                        │
                                        ▼
                              Cell-1 (load_all + 1 real fit via harness)
                                        │
                                        ▼
                              Totoro arcG grid (~5 core-h fits only)
                                        │
                                        ▼
                         dev/gapclose/arcG/ + check-log + PR
                                        │
                    (later) ──► --r-ref + Core070 D3 rebind
```

---

## SLICE TABLE

Bar = **Cursor Models** (Composer/Grok) unless Shinichi names Other Models. Totoro dispatch = hand off to shell/ControlMaster, not Cursor parent long-run.

| Tag | Slice | Member | Model | Bar | Time | OWNS | Deps |
|---|---|---|---|---|---|---|---|
| **R:** | S0 — Merge `origin/main` | Gauss | Composer | Cursor Models | 5 min | `gllvmTMB` twin worktree only | G0 #1 |
| **R:** | S1 — Coverage harness (latent-score path) | Hopper + Gauss | Grok | Cursor Models | hours (unbounded) | `dev/gapclose/arcG/` harness scripts | S0; G0 #6 if accessor |
| **R:** | S2 — Cell-1 proof (`load_all` + 1 real fit via harness) | Gauss + Fisher | Grok | Cursor Models | 30–60 min | R twin; `dev/gapclose/arcG/` (timing receipt) | S1 green |
| **R:** | S3 — Totoro campaign dispatch | Fisher + Grace | Composer | hand off | ~5 core-h (fits only) | `dev/gapclose/arcG/*` results | S2 green |
| **R:** | S4 — Results + check-log + PR | Ada + Rose | Composer | Cursor Models | 1–2 h | `dev/gapclose/arcG/`, `docs/dev-log/check-log.md` | S3; G0 #2 for push |
| **BOTH:** | S5 — Fill LOOP programme | Ada | Composer | Cursor Models | 30 min | `LOOP/*` both worktrees | G0 |
| **BOTH:** | S6 — `--r-ref` + oracle pin (later) | Hopper + Rose | Grok | Cursor Models | 2–4 h | `tools/parity_ledger.*` | G0 #4; post-S4 |
| **RESEARCH:** | S7 — Core070 D1–D6 brief | Fisher | Composer | Cursor Models | 1 h | `docs/dev-log/core070/*` drafts | G0 #5; post-S4 |
| **RESEARCH:** | S8 — Foreign lane census | Shannon | Composer | Cursor Models | 15 min | read-only reports | G0 #3 |

**Out of scope:** MSPL parked PRs; bulk push/delete; Mission Control edits; vault commits (D-37).

---

## SERIAL vs PARALLEL

```
SERIAL (critical path):
  G0 approve plan
    → S0 merge R main
      → S1 coverage harness (BLOCKS Cell-1 + Totoro)
        → S2 Cell-1 proof via harness (BLOCKS Totoro)
          → S3 Totoro arcG grid (~5 core-h fits only)
            → S4 results + PR

PARALLEL (safe alongside S1 or post-G0):
  S5 Fill LOOP (both repos)     — no shared globs with S0–S2 if LOOP only
  S8 Foreign lane census        — read-only

PARALLEL (after S4):
  S6 --r-ref                    — independent of arcG results
  S7 Core070 decision brief     — read-only drafts

NEVER PARALLEL:
  S0–S4 with foreign lane branch edits
  Two Totoro campaigns
  S6 ledger tool edits during S3 (same R tree)
```

---

## Arc sequence (one arc — not two)

### Phase A — Coverage harness (local, mandatory gate)

1. **R:** `git merge origin/main` → `ff29fba5e`.
2. **R:** Design harness to reach **latent scores** for coverage comparison. `ordination_uncertainty()` returns uncertainty intervals but **does not expose scores** in the form the harness needs — prior lane spent **>15 min reading source, zero fits**.
3. **Path choice (G0 gate #6):** reimplement score extraction locally in campaign scripts (**expected default**) **or** add a small public accessor on `ordination_uncertainty()` (**cleaner; public-API change → maintainer call**).
4. **Receipt:** Harness can extract/compare scores on a toy fit object; object-level check (fit fields / extracted matrix), not script `DONE` lines.

**Exit:** Harness sees latent scores; gate #6 resolved if accessor route chosen.

### Phase B — Cell-1 proof (local, mandatory gate)

1. **R:** `devtools::load_all(".")` — TMB DLL compiles; document in `LOOP/checkpoint.md`.
2. **R:** Run **one real arcG cell through harness** — full fit + coverage path (not `skip_on_cran`, not installed package). Set `NOT_CRAN=true`. Pick smallest cell per design §4.
3. **Receipt:** Timing line in `dev/gapclose/arcG/` or checkpoint; traps #1–#2 checked; verify fit object fields directly.

**Exit:** Real fit completes; logLik/convergence recorded; Cell-1 ≠ skip; harness exercised end-to-end.

### Phase C — arcG coverage campaign (Totoro, authorized)

1. Attach via **ControlMaster** (`~/.ssh/cm-*`, D-64); cap **≤150 cores** (D-143).
2. Run full grid: **9 cells × 500 seeds = 4,500 fits** per `dev/gapclose/arcG/coverage-design.md`.
3. Log **per-fit stage timings** (§9a qualification — do not trust interpolation alone).
4. **D-139 halt:** if measured aggregate **fit** cost **departs from ~5.0 core-h ceiling** → STOP, write interim report, re-ask (fit cost only — harness/prep excluded; not campaign authorization).

**Exit:** Raw + aggregated results under `dev/gapclose/arcG/`; coverage tables per design §8.

### Phase D — Land + report (repo, not chat)

1. Commit results + analysis scripts to results branch (stage by path).
2. Append `docs/dev-log/check-log.md` with exact commands and pass/fail tallies.
3. Open **PR** (requires G0 push gate #2).
4. Update `LOOP/checkpoint.md` both repos.

### Phase E — Joint contract (deferred unless Cell-1 blocked)

- Implement `--r-ref` on R ledger tool; pin frozen oracle at ref.
- Bring Core070 D1–D6 to Shinichi; D3 unblocks last rebind row.
- Optional: one paired R↔Julia parity cell for full bridge proof.

**Next milestone:** arcG results PR merged (or maintainer-reviewed) **and** Cell-1 receipt on file. D3/`--r-ref` = following milestone.

---

## VERIFICATION / TRAPS

**Unifying rule (Shinichi):**

> Verify against the object, never the report about it — and treat a number that improves for no reason as a bug.

All five traps are the same failure mode: **a cheerful signal about the wrong thing.** When a check passes, ask **what object it actually touched**.

| # | Shape (Shinichi) | Trap | Object-level acceptance check |
|---|---|---|---|
| **1** | **skip-DONE** | **`NOT_CRAN` / installed package** — `skip_on_cran()` or `testthat::test_file()` skips while printing `DONE`; tests run against installed package, not worktree | Count **actual fits/tests run**; **`devtools::load_all(".")` first**; inspect fit object with non-NA `logLik` from this session |
| **2** | **merge-that-didn't** | **Watcher cheers "VERIFIED…MERGED"** when PR is still open or unmerged | **`gh pr view <n>`** — read `state`, `mergedAt`, `headRefName`; mergedAt must be non-null if claiming merge |
| **3** | **count-below-ceiling-from-unparseable** | **Conflict-marker silent skip** — unparseable R files dropped from abort counts | **Parse each counted file**; a falling abort count with unparseable inputs is a bug |
| **4** | **CI-green-with-skipped-check** | **CI shard SKIPPED** — docs-only fast-pass green without running checks | Read **step conclusions** in the workflow run; green badge alone fails on `R/`/`src/` touches |
| **5** | **watcher-wrong-PR** | **Watcher script targets wrong PR** — output looks authoritative for a different change | Confirm **`gh pr view <n>`** uses the PR number for *this* branch/slice; never trust script output alone |

**Slice binding:** every slice exit criterion above must pass an **object-level** check — fit object fields, `gh pr view` output, file parse success, CI step conclusions — **not** watcher scripts, `DONE` lines, or aggregate counts alone.

---

## REPORTING CONTRACT (binding)

Results go **into the repo, not chat**:

1. **Results section** under `dev/gapclose/arcG/` (raw CSV, aggregates, analysis script outputs per design §8).
2. **`docs/dev-log/check-log.md`** append with commands run and tallies.
3. **PR** on a named results branch — Shinichi reads there.

Chat summaries are pointers only, not the evidence surface.

---

## PRE-AUTHORISED AFTER G0

Shinichi G0 on **this plan** unlocks:

| Action | Allowed | Notes |
|---|---|---|
| `git merge origin/main` on R twin | ✅ **DONE** | `5784dab65` (2026-09-04) |
| `devtools::load_all` + capability proof (step 5) | ✅ **DONE** | 2026-09-04 — 29.8 s compile + 1.0 s fit; conv=0; accessor deferred |
| `devtools::load_all` + Cell-1 real fit (arcG harness) | ⏳ | After harness slice |
| Coverage harness design (local) | ✅ | Unbounded local prep; prior lane >15 min, zero fits |
| Totoro arcG dispatch via ControlMaster | ✅ | **Campaign authorized** — ≤150 cores; ~5.0 core-h ceiling **for fits only** |
| Public accessor `extract_latent_scores()` | ✅ **DONE** | 2026-09-04 — Shinichi G0 gate #6; design note implemented |
| Public accessor on `ordination_uncertainty()` | ✅ **DONE** | Separate export `extract_latent_scores()` (not `ordination_uncertainty()` API change) |
| Edit `LOOP/*` both repos | ✅ | |
| Append `docs/dev-log/check-log.md` | ✅ | Stage by path |
| Write under `dev/gapclose/arcG/` | ✅ | Results contract |
| `git commit` on twin branches | ✅ | Local |
| `git push` + PR | ⚠️ | **G0 gate #2 only** — default local-only |
| Implement `--r-ref` | ⚠️ | G0 gate #4; after campaign |
| Touch foreign R lane branches/PRs | ❌ | Report only |
| MSPL parked PR edits | ❌ | D-157 |
| Vault `write_note` | ❌ | D-37 |

**Lease:** `tools/lane_lease.sh --claim <repo-id>` before write.

---

## OPEN GATES for Shinichi

*(Campaign authorization removed — re-confirmed GO. Do not re-ask arcG.)*

1. **Approve this plan** — one arc: harness → Cell-1 → Totoro arcG → results PR  
2. **Push policy for results PR** — may this lane push a named results branch when green? (default was local-only; PR implies push needed)  
3. **Foreign R lanes (21 live)** — confirm twin proceeds in worktree without touching them  
4. **`--r-ref` joint contract** — approve implementation spec **after** campaign (handover §4)  
5. **Core070 D1–D2, D4–D6** — unsigned; **D3 DONE** (2026-09-04: `loading_profile_exploratory` rename + ledger reclass)  
6. **Latent-score path: reimplement-local vs public accessor** — ✅ **DONE 2026-09-04** — Shinichi locked **accessor — go**; `extract_latent_scores()` implemented in R twin worktree.

---

## TEAM RAISED

| Voice | Raise |
|---|---|
| **Ada** | Prior lanes closed; plan is one arc per Shinichi update. **Harness before Cell-1 before Totoro** — do not treat ~5 core-h as whole job. STOP at G0 for plan + push + accessor gates. |
| **Rose** | Results must land in-repo per contract; verify object not report (§Traps). `--r-ref` still needed before trusting joint ledger — defer, do not skip forever. |
| **Fisher** | §9a ~5.0 core-h is **fit compute only**; harness is unbounded local work (prior lane >15 min, zero fits). Log per-fit timings in campaign. D-139 halt is fit-cost-only. |
| **Gauss** | R twin merged through #1267 — OK to edit after plan G0. Harness must reach latent scores; `ordination_uncertainty()` gap is the real blocker, not 640-RHS solve. |
| **Hopper** | arcG is R-only evidence; Julia standby. Full R↔Julia paired cell remains owed for bridge proof — after campaign or in parallel with Phase D. |

---

## STOP AT G0 — do not execute

This document is the **G0 artefact**. No merge, harness work, `load_all`, Totoro dispatch, or `/goal` until Shinichi approves **gate #1** (and **#2** before push/PR; **#6** before public accessor).

---

## /goal stub (after G0)

Paste after Shinichi approves gates **#1**, **#2** (push for results PR), and **#6** if accessor route:

```
/goal GLLVM twin arcG: merge R main, build coverage harness (latent scores), Cell-1 load_all + one real arcG fit via harness, dispatch full arcG coverage grid on Totoro (~5.0 core-h ceiling for fits only), land results in dev/gapclose/arcG/ + check-log + PR. Worktrees: R /Users/z3437171/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904 @ cursor/lane-gllvm-twin-20260904 (merge origin/main first → ff29fba5e); JL /Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904 @ cursor/lane-gllvm-twin-20260904 (standby). READ: docs/dev-log/plans/2026-09-04-gllvm-twin-ultra-plan.md; dev/gapclose/arcG/coverage-design.md §9a. DISCIPLINE: harness-before-Totoro; D-220 Cell-1 inside arc; D-64 ControlMaster ~/.ssh/cm-* (no fresh Duo); D-143 ≤150 cores; D-139 STOP if fit cost > ~5.0 core-h ceiling; NOT_CRAN=true; verify object not report (§Traps). VERIFY: harness sees scores; load_all + one real fit receipt; 4500 fits; results under dev/gapclose/arcG/; check-log append; PR opened. DEFER: --r-ref + Core070 D3 until post-campaign. FOREIGN LANES: do not touch.
```
