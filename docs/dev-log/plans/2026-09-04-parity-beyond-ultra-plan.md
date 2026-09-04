# Parity & beyond — ultra-plan (Phase 0–2, STOP AT G0)

**Authored:** 2026-09-04 · Ada consolidator · folds JL scout `083cf7e7` + R scout `6441a2df`  
**Worktrees:** JL `@ 25380642` (`cursor/lane-gllvm-twin-20260904`) · R twin `@ 9ecf2ca4d` (ahead of `origin/main` `495cde24d` on arcG)  
**Status:** **G0 LOCKED — Option A + Ada defaults (2026-09-04).** Execution started; `.unlazy/parity-claim-closeout/` armed.

---

```
🎯 GOAL
Solo platform: Cursor (one orchestrator chat, both repos)
Deliverable: ONE chosen destination from the decision map below — not all three
HEADLINE: Core070 programme CLOSED (FREE=0) ≠ true parity; bridge is live but narrow; 0.7.1 is R-only delta
DONE (measured): ledger 505 = 292 bound + 213 dispositioned · reverse-parity R lane closed · D3 decided · arcG Totoro grid run locally in R twin
G0 BLOCKS: Shinichi picks destination (A/B/C) + signs D1–D2/D4–D6 + pre-auth envelope (--r-ref, push, campaigns)
DEFER: .unlazy gate ledger (created after G0) · MSPL D-157 park · foreign R lanes · bulk unpushed triage
DISCIPLINE: frozen oracle stays b4d5fee6 (0.7.0) until re-freeze gate · verify objects not reports · Totoro via ControlMaster only after G0
```

---

## Honest answers (Shinichi's three questions)

### 1. Did we finish 0.7 complete parity?

**No — partial.**

| Layer | Verdict | Evidence |
|---|---|---|
| **Core070 programme (ledger accounting)** | **DONE** | `python3 tools/core070_ledger_counts.py docs/dev-log/core070/required-source-case-map.json` → `REQUIRED=505 BOUND=292 DISPOSITIONED=213 FREE=0` (JL scout `083cf7e7`; merged on main `5518d98d`) |
| **True parity (maintainer definition)** | **NOT DONE** | Six destination gates in `docs/dev-log/core070/true-parity-decision-map.md` unmet: second-order contract unsigned (D1–D2); 122 rows `BLOCKED_NEEDS_JULIA_SURFACE`; real-data workflows not run; grouping levels (`unit`/`unit_obs`/`cluster`/`cluster2`) not paired; AGHQ policy rows 0/39 receipted; `--r-ref` asymmetry unpatched |
| **Export reconciliation** | **77 forward gaps genuinely owed** | `python3 tools/parity_ledger.py` @ frozen `b4d5fee6` → `FORWARD=77` (0 untracked); 85 Julia-ahead accounted |

**Plain language:** The spreadsheet is closed. The claim "R workflows run identically through Julia against 0.7.0" is not yet defensible.

### 2. R–Julia bridge — all models runnable in R and Julia via R?

**No — narrow one-way bridge only.**

| Direction | Status | Scope |
|---|---|---|
| **R → Julia** (`gllvmTMB(..., engine = "julia")`) | **Live, gated, `partial`** | 11 families in `.GLLVM_JULIA_BRIDGE_FAMILIES`; unit-tier `latent(d=K)` + no-latent; no phylo/spatial/animal/kernel/iSDM/traits formula; mixed-family vector partial; structured tiers refused. Register: `JUL-01` / `JUL-01A` = `partial`. PR **#1236** (expansion) still open |
| **Julia → R** (`RCall.jl` parity tests) | **Opt-in, CI advisory-red** | `test/parity/` harness exists; `ENV["GLLVM_PARITY_TESTS"]=="1"` gate; not default CI |
| **"All models via R"** | **FALSE as stated** | Means: subset of cross-sectional reduced-rank models through JuliaCall, not full gllvmTMB surface (formula grid, SPDE, iSDM, multinomial+structure, column_coef family, etc.) |

Ledger join reports **CLOSURE PASS** (48 matched / 32 R-only / 32 Julia-only) but **without `--r-ref`** the R side reads working tree — quiet false-pass risk under one lane (D-220 caveat 1).

### 3. Lots new in R 0.7.1 — what's the twin debt?

**Oracle stays frozen at 0.7.0 (`b4d5fee6`).** R `DESCRIPTION` = **0.7.1 RC** on `origin/main` (`495cde24d`); **not tagged/released**; ~244 commits since oracle (R scout `6441a2df`). Gap sheet: `docs/dev-log/core070/gllvmtmb-071-gap-sheet.md`.

| Priority | Twin debt | Julia action |
|---|---|---|
| **P0 — blocks honest bridge/twin claims** | Formula/`traits()` grammar; iSDM surface; spatial SPDE; multinomial + structured dependence; `select_lv` / `ordination_uncertainty` **estimand differs** (R = joint precision; Julia = bootstrap+Procrustes); structured tiers (phylo/animal/spatial/kernel); mixed-family vector; column_coef / slope family (8 new exports + `column_data`) | Document as R-only or refuse in bridge; do **not** silently claim parity. Estimand decisions before any numeric compare |
| **P1 — doc/claim refresh** | Interval certification rewrite (profile → 3-cell Wald); `ψ_t` → `ψ_t²` total-variance fix | Update GLLVM.jl dev-log prose citing old "0.94 coverage floor" wording; re-pull any total-variance CI numbers if ever compared to 0.7.0 R |
| **P2 — defer until porting** | Column-coefficient/slope engines; mixed Gaussian+lognormal `sigma_eps` vectorization | Fresh R reference required when Julia starts those surfaces; no urgency for current Gaussian oracle |

Reverse-parity gap programme (ZI trio, `ordinal_logit`, `censored_poisson`, `select_lv`, etc.) **closed on R** separately — not part of forward qualification claim (T1 one-directional).

---

## Phase 0.6 route check

**Result: DECISION MAP required.** Three distinct destinations with different stopping conditions and Shinichi gates. Do not collapse to slices until destination is picked.

---

## Decision map (wayfinder)

### Destination options — pick ONE at G0

#### Option A — **True-parity claim closeout** ⭐ RECOMMENDED

**Stopping condition:** Shinichi can say, with retained receipts, that GLLVM.jl meets the **true-parity definition** in `true-parity-decision-map.md` against frozen gllvmTMB **0.7.0** — not merely ledger FREE=0.

Concrete end state:
1. D1–D2, D4–D6 signed (D3 already decided → `loading_profile_exploratory`).
2. `--r-ref` implemented on R ledger side; joint `CLOSURE: PASS` trustworthy under one lane.
3. Second-order contract published with signed tolerances; 20+22 cells re-verified under contract.
4. At least one real-data workflow per qualified family through `engine = "julia"` (after #1236 merge or scoped subset Shinichi names).
5. Grouping-level design signed (D5/D6); phylo transport Q1–Q4 answered before S3/S4 code.
6. `docs/src/gllvmtmb-parity.md` states what parity does **not** mean.

**Why recommend:** Ledger accounting is done; the remaining gap is **decisions + trust infrastructure + evidence**, not a mystery feature list. Everything else (bridge expansion, 0.7.1 catch-up) hangs off honest claim boundaries.

**Effort:** Multi-week; mostly local + selective Totoro cells (D-139); no full surface port.

#### Option B — **Bridge expansion first**

**Stopping condition:** Named P0 bridge surfaces (`JUL-01` rows) promoted from `partial` → `covered` for structured tiers + mixed-family + PR #1236 admissions; one paired R↔Julia cell receipt per new admission.

Concrete end state:
1. PR #1236 merged (maintainer authority).
2. `engine = "julia"` admits phylo/spatial or mixed-family (whichever Shinichi prioritizes).
3. `gllvm_julia_capabilities()` drift = 0 for admitted rows.
4. Paired cell through `test/parity/` or bridge integration tests.

**Why not default:** Expands surface before estimand/tolerance contract is signed — risks partial promotions that Rose would downgrade. Good **after** Option A gates 1–3, or if Shinichi explicitly prioritizes user-facing bridge over claim publication.

#### Option C — **0.7.1 twin ledger refresh (doc-only track)**

**Stopping condition:** Twin debt doc current; no stale 0.7.0 coverage claims in GLLVM.jl; 0.7.1 P0/P1/P2 table signed; oracle pin unchanged unless Shinichi triggers re-freeze.

Concrete end state:
1. `gllvmtmb-071-gap-sheet.md` reviewed and signed.
2. Rose scan of interval-certification citations in Julia docs.
3. New 0.7.1 exports classified in ledger (R-only vs future Julia vs intentionally excluded).

**Why not default:** Necessary hygiene but **does not close parity or bridge**. Best as a **parallel doc slice** inside Option A, not a standalone goal.

### Decisions so far

| Decision | Answer | Recorded |
|---|---|---|
| Core070 ledger programme | FREE=0; programme **closed** | main `2524b787` / `5518d98d`; JL scout |
| True parity definition | Fixture + real-workflow + second-order + grouping + reverse list | `true-parity-decision-map.md` |
| Qualification direction | One-way R → Julia against **0.7.0** | T1; vault D-204 |
| Oracle pin | Stay `b4d5fee6` through second-order contract | T2; 0.7.1 does not invalidate Gaussian likelihood oracle |
| D3 loading_profile | Rename Julia → `loading_profile_exploratory` | Decided 2026-09-04 |
| One Cursor lane both repos | D-220 accepted 2026-09-04 | vault `DECISIONS.md` |
| Reverse parity (R gap-close) | **Closed** on R main | R scout; #1239–#1258 |
| arcG coverage campaign | Totoro grid **run** in R twin (`9ecf2ca4d`); results landing = separate arc | Prior twin plan; not parity proof |

### Not yet specified (fog)

- **Which Option A real-data repo first** (urbanisation_map vs avian_trait_scales) — decide-with-Shinichi.
- **T8 AGHQ:** 22 `BLOCKED_SPEC_DEFECT` rows — in claim or reclassify? Default: reclassify unreachable.
- **T9 promotion authority:** Rose draft PR vs maintainer sentence per row flip.
- **T10 phylo Q1–Q4:** no maintainer reply yet.
- **T14 NB2 Wald NaN:** fixture degeneracy — F1/F2/F3 subset?
- **PR #1236 merge timing** relative to Option A vs B.
- **Push policy** for results branches (D-220 default: ask at G0).

### Out of scope

- Full Julia port of 0.7.1 column_coef / slope family (P2 until explicit arc).
- Two-directional qualification claim (Julia → R as owed work).
- MSPL programme (D-157 PARK); foreign R lanes (#981/#1065/#1070/#1077, rand-slope, iJSDM).
- CRAN / Julia General registration.
- Re-freezing oracle at 0.7.1 now (T2 defer).
- Bulk push/delete 633 unpushed gllvmTMB branches / 91 worktrees.

---

## Phase 0–2 sweep receipt

| Surface | Command / source | Receipt |
|---|---|---|
| **JL preflight** | `lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"` | **FOREIGN LANE ACTIVE** (main-direct + 91 worktrees); twin worktree clean |
| **R preflight** | `lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/gllvmTMB"` | **FOREIGN LANE ACTIVE** (24 lanes; #1268 arcG PR open); duplicate design IDs |
| **JL twin git** | `git rev-parse --short HEAD` @ twin | `25380642`; branch `cursor/lane-gllvm-twin-20260904` |
| **R twin git** | `git rev-parse --short HEAD` @ R twin | `9ecf2ca4d`; `DESCRIPTION` Version **0.7.1** |
| **R origin/main** | `git log -1 --oneline origin/main` | `495cde24d` (#1267 handover addendum) |
| **Core070 counts** | `python3 tools/core070_ledger_counts.py docs/dev-log/core070/required-source-case-map.json` | `FREE=0`; 122 `BLOCKED_NEEDS_JULIA_SURFACE` |
| **Parity ledger** | `python3 tools/parity_ledger.py` | @ `b4d5fee6`: FORWARD=77, REVERSE=85 |
| **Brain D-220** | vault `DECISIONS.md` L7954+ | One Cursor lane; Totoro transport locks |
| **Mission Control** | `/p/gllvmTMB/` | Covers both repos; focus predates D-220 — report-only |
| **JL scout** | checkpoint `083cf7e7` | Programme ≠ true parity; bridge gated; oracle frozen |
| **R scout** | checkpoint `6441a2df` | 0.7.1 RC untagged; P0 bridge gaps; CLOSURE PASS sans `--r-ref` |

**Lane statement:** `PLATFORM: cursor | ON BRANCH: cursor/lane-gllvm-twin-20260904 | LANE: parity-beyond ultra-plan (read-only Phase 0–2) | OTHER LANES: foreign active both repos — worktree-only edits`

---

## OPEN GATES for G0

| # | Gate | Ask Shinichi |
|---|---|---|
| **G0-1** | **Destination pick** | **A** (true-parity closeout) · **B** (bridge expansion) · **C** (0.7.1 doc refresh only) — or A+C hybrid |
| **G0-2** | **Sign D1–D2, D4–D6** | Tolerances (D1), cond(H) scaling (D2), AGHQ reclassify (D4), grouping levels (D5), ZI trio + grouping relay (D6). D3 done |
| **G0-3** | **Pre-auth envelope** | (a) Implement `--r-ref` on R ledger? (b) Push results branch when ready? (c) Totoro campaigns >30 min — which cells pre-approved? (d) PR #1236 merge authority if Option B |

**`.unlazy` ledger:** Created **after G0 approval** — do not invent gate files until destination is locked.

---

## Autonomous vs must-stop (post-G0)

### Cursor can run unattended (after G0, within chosen destination)

- Local `python3 tools/parity_ledger.py` / `core070_ledger_counts.py` / ledger rebind scripts.
- Julia `Pkg.test()` / `test/runtests.jl` on touched slices.
- R `devtools::test()` on bridge files in **twin worktree only** (not foreign lanes).
- Doc/dev-log updates, check-log append, after-task drafts.
- `--r-ref` implementation (both repos, surgical) once G0-3(a) yes.
- D3 follow-through verification (`loading_profile_exploratory` grep + test).
- Rose-style consistency scans (read-only).
- arcG results landing + PR prep **if** push pre-authorized at G0.

### Must STOP for Shinichi

- Any **API / estimand / formula grammar** change (Boole gate).
- **D1–D6** defaults vs recommendations — only maintainer signs tolerances and grouping design.
- **Campaigns >30 min** or departing D-139 cost ceiling — estimate + pre-run + explicit yes.
- **Merge PR #1236** or any public API/export change on gllvmTMB.
- **Push / release / tag 0.7.1**.
- **Re-freeze oracle** at 0.7.1+.
- **Foreign lane file overlap** — if lease refused, surface to Shinichi (D-87).
- **Promotion** of register row from `partial` → `covered` on user-facing claim.

### Hand to checklist (not Cursor parent long-run)

- Totoro dispatch (`run-grid-totoro.sh`, ControlMaster `~/.ssh/cm-*`, D-64).
- Full `R CMD check` / 3-OS CI interpretation.
- Live JuliaCall bridge runs requiring local R+Julia install paths.

**Bar routing:** Cursor Models (Composer/Grok) for scout/build/doc; Other Models only if Shinichi names for judgment slices; Totoro/R CMD on shell checklist.

---

## Phase 2 slice sketch (Option A — activates only after G0-1 = A)

| # | Slice | Output | Blocked by |
|---|---|---|---|
| S1 | Sign + commit second-order contract | `second-order-parity-contract.md` signed; check-log | G0-2 D1–D2 |
| S2 | Implement `--r-ref` | `gllvmTMB/tools/parity_ledger.R` patch; joint CLOSURE re-run | G0-3(a) |
| S3 | D4 AGHQ disposition batch | 8 reclassify + 14 bind receipts | G0-2 D4 |
| S4 | D5/D6 grouping design doc | `t12-grouping-levels-design.md` signed | G0-2 D5–D6 |
| S5 | Real-data workflow cell #1 | One Ayumi-scale repo end-to-end via bridge | G0-1 + #1236 scope |
| S6 | Rose scan + parity page update | `docs/src/gllvmtmb-parity.md` boundary statement | S1–S5 |
| S7 | arcG results land (if not done) | `dev/gapclose/arcG/` + PR | G0-3(b)(c) |

Option B replaces S4–S5 with #1236 merge + paired bridge cells. Option C replaces S1–S6 with gap-sheet sign-off + doc Rose scan only.

---

## Paste-ready `/goal` stub (AFTER G0 — fill destination)

```
/goal parity-beyond-20260904
Platform: Cursor · one lane · worktrees:
  JL: ~/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
  R:  ~/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904

DESTINATION: [A|B|C from G0-1 — default A if Shinichi says "proceed"]

DONE WHEN:
- [A] true-parity-decision-map.md gates 1–7 evidenced + D1–D6 signed + --r-ref live
- [B] JUL-01 promoted for named P0 surfaces + paired cells receipted
- [C] 0.7.1 gap sheet signed + stale coverage prose fixed

FIRST SLICE: [S1|S2|C-doc per destination]

G0 LOCKS (do not re-ask):
- Oracle: b4d5fee64def88bc768dda1f1f77c29b295edd86
- D-220: one lane; Totoro ControlMaster; ≤150 cores; no GHA campaigns
- D-157: MSPL park
- Push: [yes/no from G0-3(b)]

STOP IF: foreign lane lease refused · D-139 cost breach · estimand question without maintainer answer

PLAN: docs/dev-log/plans/2026-09-04-parity-beyond-ultra-plan.md
```

---

## Relationship to sibling plan

`docs/dev-log/plans/2026-09-04-gllvm-twin-ultra-plan.md` covers the **arcG ordination_uncertainty coverage campaign** — a **coverage-evidence arc**, not parity closure. If Shinichi picks **Option A**, arcG results land as **S7** (supporting evidence for EXT-38 estimand documentation), not as proof of Core070 engine parity. Do not merge the two goals without explicit G0.

---

*Phase 0–2 complete. No code edits. No Totoro. No push. Waiting for Shinichi G0.*
