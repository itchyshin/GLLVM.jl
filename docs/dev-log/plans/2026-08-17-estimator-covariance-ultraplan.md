# Ultra-plan — GLLVM.jl estimators + covariance grammar (catch up, then go beyond)

**Date:** 2026-08-17
**Orchestrator:** Ada (Cursor session; Phases 0–2 only)
**Mode:** G0 APPROVED 2026-08-17 — Q1/Q2/Q3 as recommended; first `/goal` = wait #251 + A4(2) only
**Plan file:** this path, on worktree `.worktrees/gllvmjl-aghq-stage1b-20260817`
**Plan mode:** this session **cannot** toggle Cursor Plan mode. Phases 0–2 stayed
read-only except this one new file. Do not treat that as Plan-mode activation.

Family count is already past the twin. Catch-up = **estimators + covariance
grammar**, not another family admit.

---

```
🎯 GOAL
Solo platform: Cursor (this session — `session_ownership.sh` printed PLATFORM: Cursor). After G0, execute via /goal in a fresh Cursor chat on the Stage-1b worktree. Do not grow this planning chat into Phase 3. HANDS TO Codex/Claude only for live R, HPC, or a merge Shinichi explicitly assigns; do not invent Codex as default executor.

Deliverable: A bounded programme that (1) waits for PR #251 to land on origin/main without this lane merging it, (2) implements AGHQ A4(2) Stage-1b per-site Liu–Pierce adaptation on the existing Arc Card, then (3) walks A4(3) gate → A4(4) loop → A4(5) honesty, then (4) the cheapest covariance chip `none × dep()`, then (5) a CV Identity lock. Ledger AGHQ rows stay `missing` until a later promote Shinichi names.

HEADLINE: Land #251 (sibling may merge only if fully green) then A4(2) Stage-1b — extend `aghq_stage1a_loglik_site` for k>1; keep the k=1 Laplace golden; no public `aghq=`.

IN PARALLEL (cheap, read-only while #251 CI runs): RECON of #251 checks + main tip; twin AGHQ/CV file cite from gllvmTMB origin/main; none×dep / CV surface inventory (no src).

DEFER / FENCE: multinomial campaign · coverage certificate (Totoro/DRAC only if Shinichi sizes it) · Tweedie T2–T5 / Tweedie `fit_gllvm` admit · public `aghq=` until A4.5 · ledger promote of either AGHQ row · stub `aghq=` · `_gauss_hermite` rename · invented twin Δ · `aghq_ridge` · twin Laplace k=1 skip · merge of #247 · writes in the Dropbox checkout · a second Stage-1b branch · arc-creation of a new Stage-1b card.

DISCIPLINE: verify = Mac-light focused tests + k=1 still ≡ Laplace + Rose claim fence (rows stay `missing`) · compute = local tiny until Shinichi sizes Totoro/DRAC · closure = A4(2) PR ready after #251 is on main; later rungs each STOP for their own Identity/gate; Melissa reconcile at programme close.
```

**ARC PROGRAM:** existing Stage-1b Arc Card — mode **size** · recommended **90 min** implementation (range 60–120; ceiling 2 h once `src/` unlocked) · Arc 0 **done** (docs lock + Hopper pin; `src/` gated). Pointer:
`.worktrees/gllvmjl-aghq-stage1b-20260817/docs/dev-log/plans/2026-08-17-aghq-stage1b-arc.md`
Lock: `docs/dev-log/decisions/2026-08-17-aghq-stage1b-adapt.md`.
This GOAL is the programme; the card is A4(2) only. Do not replace GOAL with the card. Do not invent another card via `/arc-creation`.

---

## Phase 0.2 — Lane preflight (Shannon)

Command (absolute path):

```sh
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
```

**VERDICT (pasted, 2026-08-17):** `** FOREIGN LANE ACTIVE (direct-to-main) **`
plus **9 live cursor lanes** besides this session. `origin/main` had 16 commits
in the last 12 h (7 non-merge straight to main). Coordination board is
**COMMITTED to origin/main** (reaches other lanes). Dropbox checkout is on
`claude/jl-bridge-capabilities-20260619` (PROTECTED).

**Lane this plan claims:** `cursor/aghq-stage1b-20260817` only — worktree
`.worktrees/gllvmjl-aghq-stage1b-20260817`. Write surface for *this* G0 file:
`docs/dev-log/plans/2026-08-17-estimator-covariance-ultraplan.md`.

**Do not claim:** PR #251 files / `cursor/aghq-stage1a-20260817` · #247 ·
Dropbox checkout · `cursor/overnight-surface-handoff-20260817` · family no-X
lanes · `main-direct`. Concurrency is allowed; bleed-through is not (D-88).
If A4(2) `src/` and #251 still share `aghq_grid.jl`, **wait** — ownership is
Shinichi's call (D-87), not a unilateral rebase onto an open PR.

`STATE THIS LINE:` PLATFORM: cursor | ON BRANCH (Dropbox): `claude/jl-bridge-capabilities-20260619` | LANE: `cursor/aghq-stage1b-20260817` | OTHER LANES: cursor+#251, cursor+#247, main-direct, 7+ other cursor lanes

---

## Phase 0.25 — Prior-work sweep RECEIPT (gate)

| Surface | Evidence cited | Finding | Call |
|---|---|---|---|
| **repo git** | `git -C .worktrees/gllvmjl-aghq-stage1b-20260817 status -sb` → `## cursor/aghq-stage1b-20260817...origin/main [ahead 1]` (clean before this file); `rev-parse --short HEAD` → **`40b5b9ba`**; `branch_drift_check.sh` in that worktree → **1 ahead, 0 behind, ok**; `git worktree list` lists `.worktrees/gllvmjl-aghq-stage1b-20260817` @ `40b5b9ba`; `origin/cursor/aghq-stage1b-20260817` **absent** (not pushed); Dropbox `session_ownership.sh` → PLATFORM Cursor, 25 uncommitted preview/agent paths on the protected fork; `gh pr view 251` → **OPEN**, head `17857481`, Documenter SUCCESS, four Julia jobs **IN_PROGRESS** (CI `32035360864`); `gh pr view 247` → **OPEN**, leave unmerged | Stage-1b Arc Card + Hopper lock are **local-only** @ `40b5b9ba`. Stage-1a engine is **not on main**. Do not treat #251 as merged. Worktree LOOP/ is the **2026-08-01 logLik oracle kit** — not this programme | **resume** `cursor/aghq-stage1b-20260817` after `17857481` is on `origin/main`; **do not resume** the Dropbox fork; **do not** execute the frozen 2026-08-01 LOOP/ |
| **twin gllvmTMB** | `git -C "/Users/z3437171/Dropbox/Github Local/gllvmTMB" status -sb` + `rev-parse --short origin/main` → **`a8aa3b28`**; Dropbox twin HEAD `114a227e` on a cloud-agent branch (wrong write lane); `git ls-files 'R/aghq*' 'R/cv-*'` → `R/aghq-control.R`, `aghq-gate.R`, `aghq-auto-ridge.R`, `aghq-report.R`, `R/cv-internal.R`, `R/cv-metrics.R` still shipped. Identity already read these at `e3e813f4` | Twin has the estimator + CV surfaces Julia lacks. No invented Δ. Do not use the twin Dropbox branch as a write lane | **reuse / co-opt** twin files as read-only pins; **n/a** for R engine surgery |
| **brain** | MCP `search_notes` `search_all_projects: true` queries `"GLLVM.jl AGHQ Stage-1b estimator covariance catch-up gllvmTMB A4"` and `"GLLVM.jl covariance grammar none dep() CV Identity AGHQ ledger missing"`; hits: `dr21-gllvm-estimation-engines-distilled` (AGHQ is a benchmark, not a production engine at GLLVM scale); D-113 is **gllvmTMB 0.7** (EVA/AGHQ claims on the *R* twin), not a Julia promote; no vault decision flips Julia AGHQ rows off `missing` | In-repo Identity + Stage-1b lock are fresher than vault semantic hits. dr21 already harvested — do not re-research Liu–Pierce | **reuse** Identity / Hopper pin / dr21; **none** new brain decision to implement |
| **deterministic grep** | `grep -in "AGHQ\\|Stage-1b\\|A4(2)\\|public aghq" ~/shinichi-brain/memory/DECISIONS.md` → D-113 (R 0.7 programme) + drmTMB AGHQ notes; **no Julia Stage-1b decision**. `grep -in "AGHQ\\|Stage-1a\\|Stage-1b" ~/shinichi-brain/memory/AGENT_LOG.md` → drmTMB AGHQ runtime notes, not GLLVM.jl A4. `grep -in "AGHQ\\|Stage-1b\\|aghq=" ~/shinichi-brain/memory/OPEN_QUESTIONS.md` → **empty**. `grep -in "AGHQ\\|adaptive Gauss-Hermite\\|Liu-Pierce" ~/shinichi-brain/projects/deep-research/README.md` → **dr20 / dr21 / dr25** already filed | Semantic search + grep agree: Julia A4 campaign is repo-local (2026-08-17 decisions), not a vault D-number | **reuse** dr21; **do not** open a new dr-note unless Shinichi wants NotebookLM (offered below) |
| **Verdict** | — | Genuine gap is **A4(2) engine after #251**, then the rest of A4, then `none × dep()`, then CV Identity. Do not rebuild Stage-1a, the Arc Card, or family admits | **reuse** Identity + Stage-1a PR + Stage-1b card/lock + twin files · **resume** `cursor/aghq-stage1b-20260817` @ `40b5b9ba` · **build-the-gap** = A4(2) `src/` after #251, then sequential A4(3–5) → `none × dep()` → CV Identity |

**External prior art (Phase 0.5):** NotebookLM grounded search **OFFERED, not run**.
dr21 already distilled VA/EVA/AGHQ/Laplace for GLLVMs. Hopper pin + Identity
already lock Liu–Pierce (no √2). Ask Shinichi below; default = **no**.

---

## Phase 0.3 — Live model roster + 0.3b two-bar

| Item | Status |
|---|---|
| Volatile roster | `memory/MODEL-ROUTING.md` Cursor side: Cursor Models = **Grok 4.5 + Composer 2.5**; Other Models = ≥$400 API (Auto Cost / Claude / GPT); on-demand **off**. Last durable bar reading **2026-08-16 morning**: Cursor Models **51%** · Other Models **66%** · Grok Bot weekly 4% (not a brain host). Prefer **Grok** on Agent slices while Other Models leads |
| Settings → Usage (live) | **UNVERIFIED this session** — no programmatic Settings → Usage read. Bar column is from **doctrine**, not a live meter |
| Dispatch | Scout / RECON / MECHANICAL-VERIFY → **Cursor Models** (Grok). Judgment / Rose / Fisher / prose → **Other Models**. Merge / live R / Totoro/DRAC → **hand off** (Claude Opus or Codex Sol) — not this Cursor parent |
| Codex Luna | Not the solo executor. If a later HANDS TO Codex occurs, use `codex-tier-run.sh` for Luna |

---

## Context (one screen)

- **Mission:** catch up with gllvmTMB in capability **and go beyond**. Families
  already past the twin (ZIP/ZINB/ZIB, hurdles, OrderedBeta, COM-Poisson, …).
  Remaining twin-shaped holes are **estimators** (AGHQ, CV) and **covariance
  grammar** (`none × dep()` first; `scalar()` / `*_slope()` later).
- **Already true — do not re-do:** Stage-1a grid + k=1 golden = PR **#251**
  https://github.com/itchyshin/GLLVM.jl/pull/251 @ `17857481`. Independent
  review PASS (69/69). Documenter green. Four Julia jobs still **IN_PROGRESS**
  at plan time (CI https://github.com/itchyshin/GLLVM.jl/actions/runs/32035360864).
  A sibling may merge **only if fully green**. This lane does **not** merge.
- **Already true — do not re-do:** Stage-1b Arc Card + Hopper pin committed
  **locally** @ `40b5b9ba` (not pushed). Liu–Pierce
  `z_ij = ẑᵢ + Lᵢ^{-T} uⱼ` (no √2); extend `aghq_stage1a_loglik_site`; keep
  k=1 template; do not port twin Laplace skip.
- **Protected:** Dropbox checkout. #247 leave unmerged. Tweedie STOP. No stub
  `aghq=`. No `_gauss_hermite` rename. No invented twin Δ. Coverage = Totoro/DRAC
  only if Shinichi sizes it.
- **Ledger:** both AGHQ rows stay `missing`. `none × dep()` is `planned`.
  Cross-validation has **no Julia ledger row** (gap sheet: twin shipped,
  Julia `crossval` absent).
- **LOOP/ hazard:** files under this worktree's `LOOP/` belong to the
  **2026-08-01 logLik oracle** (DONE). After G0, `/goal` must scaffold a
  **new** LOOP for *this* programme — do not re-run that frozen GOAL.

---

## WHAT THE BRAIN ALREADY KNOWS

- D-113 is the **R** 0.7 AGHQ/EVA programme — not a Julia ledger promote.
- dr21: AGHQ is a literature **benchmark**, not a competing production engine
  at GLLVM scale; no standalone AGHQ variance-component bias result for GLLVMs.
- Julia AGHQ Identity (2026-08-17, #248) + Stage-1b lock (local `40b5b9ba`)
  already name A4(1–5), forbid stub knobs, and pin the live grid.
- Catch-up bar from the 2026-08-17 Cursor handover: after Stage-1a, leftovers
  are unstructured `dep()`, CV, coverage on Totoro/DRAC.
- Compute default: ask "Totoro or DRAC?" at scope time; this programme's
  HEADLINE is Mac-light.

## WHAT SHINICHI TOLD US (this session)

- Ultra-plan Phases 0–2 only; STOP at G0; no Phase 3 here.
- PLATFORM = Cursor; solo platform = Cursor.
- Big aim: catch up **and go beyond**; catch-up = estimators + covariance grammar.
- Do not implement Stage-1b `src/`; do not merge PRs; do not edit the Arc Card,
  check-log, coordination-board, `src/`, or AGENTS.md.
- Prefer leave this plan **uncommitted** so he approves first.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Fisher — k>1 tests are not a capability claim; k=1 ≡ Laplace is a template identity · a green A4(2) suite must not flip AGHQ rows or advertise quadrature-fitted models · keep both rows `missing` through A4(5) · Q: after A4(2) green, still missing? · default: yes
  Rose   — public `aghq=` before A4.5 is the EVA-honesty failure (an argument that can only error, or that silently mixes engines) · #251 is OPEN; do not narrate Stage-1a as merged · fence #247, Tweedie, Dropbox, invented Δ · Q: none if fence holds · default: fence holds
  Gauss  — Hopper pin is the map; extend `aghq_stage1a_loglik_site`, do not fork a third grid or port `aghq_ridge` / twin k=1 skip · `none × dep()` is a different likelihood (unstructured trait cov, no LV) — not an AGHQ file · Q: one worktree forever vs cut new branches per rung? · default: this worktree for A4(2) only; new branches after
  Ada    — HEADLINE is land #251 then A4(2). The programme names A4(3–5) → none×dep → CV Identity as sequential leftovers, each with its own STOP. This chat writes the plan only.
```

## ADA'S RECOMMENDATION

Approve this plan. After G0, paste the `/goal` prompt below into a **fresh**
Cursor chat opened on
`.worktrees/gllvmjl-aghq-stage1b-20260817`. Arc 0 of that run = **wait/watch
#251** (do not merge). When `origin/main` contains `17857481`, rebase this
branch and execute the existing Stage-1b Arc Card (Rungs 1–2). STOP after the
A4(2) PR is ready. Do **not** smash A4(3–5), `none × dep()`, and CV into the
same 90-minute card.

## DECISIONS LOCKED (session + repo)

- Restart base = `origin/main`, never the Dropbox fork.
- #251 merge is **not** this lane; sibling only if fully green.
- Hopper A4(2) pin: Liu–Pierce, no √2, extend-not-fork, keep k=1 template.
- Ledger AGHQ rows stay `missing`. No public `aghq=` until A4.5.
- #247 leave unmerged. Tweedie STOP. No invented twin Δ.
- Coverage / Totoro/DRAC only if Shinichi sizes it.
- No Phase 3 in the planning chat. This file is now G0-locked (Q1/Q2/Q3 as recommended).

## QUESTIONS LOCKED (G0 APPROVED 2026-08-17 — as recommended)

**Q1 — How far does the first `/goal` run go?**
**LOCKED:** First `/goal` = wait #251 + A4(2) only. STOP when A4(2) is
PR-ready. Do **not** continue into A4(3) in this LOOP. Then
`START A FRESH TASK` for A4(3). Programme order stays binding.

**Q2 — Parallel docs while `src/` waits?**
**LOCKED:** Sequential. No disjoint worktree for A4(3) Identity or CV
Identity. Cheap IN PARALLEL stays read-only recon, not a second Identity PR.

**Q3 — After A4(5), first leftover chip?**
**LOCKED:** After A4(5) (a *later* `/goal`), first leftover = `none × dep()`
then CV Identity. `scalar()` / `*_slope()` stay later. Multinomial and
coverage stay DEFER. Not this run.

---

## Phase 1–2 — Decomposition

**SEARCH:** none this G0 (NotebookLM offered; default no)
**SLICES:** S0 RECON → S1 wait/#251 → S2 A4(2) build → S3 A4(2) review →
S4 A4(3) → S5 A4(4) → S6 A4(5) → S7 none×dep → S8 CV Identity →
S9 MECHANICAL-VERIFY → S10 Rose → S11 RECONCILE
**PARALLEL:** {S0} while S1 waits; later leftover recon only if Q2 = yes
**SEQUENTIAL:** S2←S1←#251 on main; S3←S2; S4←S3; S5←S4; S6←S5; S7←S6
(or after HEADLINE if Q3 moves it); S8←S7; S9–S11 at each meaningful close
**FAN-OUT:** 0 producer children in *this* chat. After G0: 1 scout (S0) +
1 build (S2) + 1 review (S3) for HEADLINE. Later rungs are new checkpoints.
**FAN-OUT BUDGET:** checkpoint=`estimator-cov-g0` · new children=0/6 this
chat · scout=1 after G0 · build=1 · ceiling=0 (Rose S10 is Other Models,
not a second Sol child unless Shinichi hands off)
**SCOUT SUITABILITY:** yes — S0 RECON + S9 MECHANICAL-VERIFY
**ULTRA EFFORT:** no
**CONTEXT BRAKE:** parent input=unknown · fresh-task trigger=after G0
(`/goal` in a new chat)
**COMPACTIONS:** parent=0 · children max=0 this chat · boundary=open
**LANE RECEIPT:** `START A FRESH TASK` after G0 approval · reason=Cursor
ultra-plan must not become the execution thread · next-task prompt=below
**AUTO-REVIEW:** guardian calls unknown · action=none this chat
**D-43 PANEL:** milestone=not this G0 · status=not fired · fire once when
A4(2) claims "done" (2 build + 1 ceiling; not in the planning chat)
**MODELS:** see table (Cursor Bars from doctrine)
**ESTIMATE:** HEADLINE ~2–4 h wall-clock after #251 is green (external wait
unbounded) · 1 `/goal` session for A4(2) · **programme needs handoff**
(A4(3–5) + none×dep + CV ≈ 2–4 working days sequential, no coverage)
**ARC ACTUALS:** Stage-1b card Actuals already record Arc 0 ~20 min; Rungs
1–close unused until #251
**PREFLIGHT:** Shannon verdict above; lane claimed `cursor/aghq-stage1b-20260817`
**REVIEW (plan, before run):** Rose + Gauss — receipt is evidence-cited;
HEADLINE does not merge #251; Hopper pin not re-derived
**VERIFY:** S9 + S10 · **CONSOLIDATE:** A4(2) after-task + check-log (execution
chat, not this file's job)
**RECONCILE:** Melissa required at A4(2) close and at programme close →
`docs/dev-log/plan-actual/2026-08-17-estimator-covariance.md`

### Slice table

| ID | Slice | Member | model+effort | Bar | time | files | dep |
|---|---|---|---|---|---|---|---|
| S0 | **RECON** — refresh #251 checks, `origin/main` tip, worktree rebase readiness, twin `R/aghq-*.R` + `R/cv-*.R` SHAs | Shannon / landscape-scout | Grok 4.5 · low | **Cursor Models** | 15 min | read-only: `gh pr view 251`, `gh run view 32035360864`, twin `origin/main` | none |
| S1 | Wait for #251 fully green; **do not merge**. If a sibling merges, `git fetch` + rebase `cursor/aghq-stage1b-20260817` onto `origin/main` containing `17857481` | Ada | Grok · low (watch) | **hand off** merge itself (sibling / Shinichi) | external | no `src/` until unlock | S0 |
| S2 | A4(2) Stage-1b — execute existing Arc Card Rungs 1–2: extend `aghq_stage1a_loglik_site`; `test/test_aghq_adapt.jl` Mac-light | Gauss / julia-engineer | Grok 4.5 · medium (bounded IDE) | **Cursor Models** | 60–90 min | `src/families/aghq_grid.jl` (or Stage-1a file once on main); `test/test_aghq_adapt.jl` | S1; Hopper pin; **no** new engine file |
| S3 | A4(2) claim fence + Hopper-pin audit (k=1 still golden; no skip; no ridge; no `aghq=`; rows `missing`) | Rose + Hopper | Auto Cost / pinned Claude · medium | **Other Models** | 20 min | tests + decision notes (read); after-task in execution chat | S2 |
| S4 | A4(3) structural gate — Identity first, then engine; twin `R/aghq-gate.R` read-only (Hessian sparsity / treewidth; hard exclusions) | Gauss + Hopper | Grok build / Other Models Identity | **Cursor Models** then **Other Models** | own arc (~2–4 h) | new decision + later gate code; **new branch** | S3; Q1 STOP default |
| S5 | A4(4) adaptation loop + convergence verdict ≠ Optim relative f-change; **do not** port twin fit-time k=1→Laplace skip | Gauss | Grok · medium | **Cursor Models** | own arc | AGHQ eval loop only | S4 |
| S6 | A4(5) report honesty (`used`, `k`, engine label) so AIC/print cannot mix Laplace and AGHQ. **Earliest** moment a public `aghq=` is discussable — still not this HEADLINE | Hopper + Rose | Auto Cost · medium | **Other Models** | own arc | report/print surfaces | S5 |
| S7 | Cheapest covariance: `none × dep()` Identity then engine (unstructured trait cov, no LV). Not on the AGHQ worktree | Gauss | Grok · medium | **Cursor Models** | own arc (mid-term) | new branch; `fit` / formula / tests; ledger `planned`→only after tests | S6 (or Q3) |
| S8 | CV Identity — lock twin `R/cv-*.R`; no `crossval=` stub; no ledger invent | Ada + Hopper | Auto Cost · low | **Other Models** | ~1–2 h docs | new decision note; capability-status row if Rose agrees | S7 |
| S9 | **MECHANICAL-VERIFY** — focused test tally, `rg -n aghq src test`, k=1 golden still present, #251 SHA on main, no stub knob | landscape-scout | Grok · low | **Cursor Models** | 15 min | CI logs + test output | each close; HEADLINE after S2 |
| S10 | Rose verdict before any public estimator/covariance claim | Rose | Auto Cost / Claude · medium | **Other Models** | 15 min | after-task + capability-status | S9 |
| S11 | **RECONCILE** (Melissa) — plan vs actual on six axes | Melissa | Auto Cost · low–medium | **Other Models** | 15 min | `docs/dev-log/plan-actual/2026-08-17-estimator-covariance.md` | S10 at A4(2) close and programme close |

### Hopper A4(2) pin (do not re-derive — cited from the lock)

```
z_ij = ẑᵢ + Lᵢ^{-T} uⱼ          # no √2
log Lᵢ = aghq_logdet(i) + logsumexpⱼ(logwⱼ + inner_ll(i,j))
```

Extend `aghq_stage1a_loglik_site`. Reuse Laplace cache `A = Λ'WΛ + I`.
Do not port twin 1e-8 eigenvalue floor / `aghq_ridge`. At k=1 keep evaluating
the template (`u = 0`). Fail-loud: `_aghq_stage1a_reject_extra`.

### Success checks (HEADLINE)

- `origin/main` contains `17857481` (merged by a sibling or Shinichi — not this lane).
- Focused `test/test_aghq_adapt.jl` green; k=1 still matches Laplace.
- Both AGHQ ledger rows still `missing`.
- No public `aghq=`; no `_gauss_hermite` call; no twin Δ; no #247 merge.
- Dropbox checkout untouched.

---

## Phase 0.5 — NotebookLM (offer once)

Want a grounded NotebookLM pass on Liu–Pierce / AGHQ-at-GLLVM-scale before
A4(2) `src/`? **Ada default: no** — Identity, Hopper pin, and dr21 already
cover it. Findings would be triage, not authority. Do not run it from this chat.

---

## After G0 — paste-ready `/goal` (do not run here)

```
/goal

Execute the APPROVED estimator+covariance ultra-plan. Do not re-plan.

PLATFORM: Cursor
WORKTREE: /Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-aghq-stage1b-20260817
BRANCH: cursor/aghq-stage1b-20260817
PLAN: docs/dev-log/plans/2026-08-17-estimator-covariance-ultraplan.md
ARC CARD (A4(2) only): docs/dev-log/plans/2026-08-17-aghq-stage1b-arc.md
LOCK: docs/dev-log/decisions/2026-08-17-aghq-stage1b-adapt.md

Scaffold a NEW LOOP/ for this programme (do not execute the 2026-08-01 logLik LOOP already in this worktree).

HEADLINE only unless Shinichi answered Q1 = continue:
1. Watch PR #251 (17857481). Do NOT merge. Sibling may merge only if fully green
   (Documenter already SUCCESS; four Julia jobs must be green).
   CI: https://github.com/itchyshin/GLLVM.jl/actions/runs/32035360864
2. When origin/main contains 17857481: fetch, rebase this branch, then Arc Card
   Rungs 1–2 (extend aghq_stage1a_loglik_site; test/test_aghq_adapt.jl).
3. Hopper pin: z_ij = ẑᵢ + Lᵢ^{-T} uⱼ (no √2). Keep k=1 template. Do not port
   twin Laplace skip or aghq_ridge. No public aghq=. Ledger rows stay missing.

FENCE: Dropbox checkout · #247 · Tweedie T2–T5 · stub aghq= · _gauss_hermite
rename · invented twin Δ · coverage unless Shinichi sizes Totoro/DRAC ·
multinomial · ledger promote · second Stage-1b branch.

STOP after A4(2) PR-ready (Ada Q1 default). Then START A FRESH TASK for A4(3).
```

---

## Commit posture

G0 approved; lock this file on `cursor/aghq-stage1b-20260817` by named path.
Do not `git add -A`. Do not push. Execution workspace after `lane_launch` is
`~/local-scratch/lanes/GLLVM.jl-aghq-stage1b` on `claude/lane-aghq-stage1b`.

**G0 APPROVED. First `/goal` STOP = A4(2) PR-ready.**
