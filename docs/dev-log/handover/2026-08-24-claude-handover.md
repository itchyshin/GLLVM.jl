# Session Handoff → Claude: GLLVM.jl post-#262 honesty wave (2026-08-24)

**Meta:** 2026-08-24 (MDT) · **from** Cursor · **to** Claude (fresh session, no
inherited chat context) · authored under
`~/shinichi-brain/protocols/handover-skill.md` (`TARGET = claude`,
`AUTHOR = cursor`), content template `~/shinichi-brain/protocols/handoff.md`,
and `~/.claude/skills/handover-to-claude/SKILL.md`.

You are **Claude**, picking up GLLVM.jl in a brand-new session. You inherit
**no** context from the Cursor chat that wrote this file. The committed
repository document is authoritative. Read `AGENTS.md` first, then this file,
then reconcile against live `git` / `gh` before you touch anything.

**Lane this file was written from:** `PLATFORM: cursor` ·
`ON BRANCH: handover/2026-08-24-claude` (cut from `origin/main` @ `c5b72310`) ·
`LANE: docs-only 2026-08-24 Claude handover` ·
`OTHER LANES: cursor+#254 (cursor/handover-20260818, OPEN — leave alone) ·
worktree×99 historical · local-scratch sibling lanes (merged or parked) ·
Dropbox checkout PROTECTED`.

**Unpushed warning (loud):** this handover branch is **local-only until
Shinichi pushes**. The next session that clones from `origin` cannot see this
file until `git push -u origin handover/2026-08-24-claude` and a PR. Do **not**
push unless Shinichi asks. Do **not** auto-merge.

---

## Critical Context — read these six or you will go wrong

1. **`origin/main` tip is `c5b72310` (merge of #262).** The 2026-08-18 Cursor
   handover (#254) froze the world at `3d5acba0` (#253). That file is still
   useful as a dated prior; it is **not** current tip truth. Classify against
   `c5b72310`, not against #254's tip.
2. **#254 stays OPEN and is not yours.**
   https://github.com/itchyshin/GLLVM.jl/pull/254
   (`cursor/handover-20260818`). It owns `AGENTS.md`,
   `docs/dev-log/coordination-board.md`, and
   `docs/dev-log/handover/2026-08-18-cursor-handover.md`. Do **not** edit
   those files, rematch, merge, or close #254 unless Shinichi asks. Multi-lane
   check: a single `START HERE` pointer would orphan #254; rehydrate via the
   board's **Active-Lane-Split** *and* this file.
3. **AGHQ arcs 2 ∩ 3 ∩ 4 ∩ 5 are PARKED.** They serialize on
   `src/families/aghq_grid.jl` (+ AGHQ tests). G0 for the seven-arc ultra-plan
   is still unpaid. Do **not** open the next AGHQ engine chip. Both AGHQ
   ledger rows stay `missing`. No stub `aghq=` knob.
4. **Light RCall Δ for truncated_poisson is OWED, not invented.** Twin fid 10
   exists, so a number is legitimate — but only a live paired run may quote
   one. Same rule for lognormal (twin fid 3). `GLLVM_PARITY_TESTS` unset on
   the machines that shipped #259/#261.
5. **L47 `none × dep()` stays `planned` even after #262.** `fit_dep_gllvm` is
   a Gaussian `K = p` wrapper. There is **no** formula `dep()` /
   FunctionTerm / RE-grammar v2. Do **not** flip the ledger. The discarded
   L47 `implemented` flip on `cursor/none-dep-engine-20260818` is **RETRACTED**.
6. **The Dropbox checkout is PROTECTED.**
   `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` sits on
   `claude/jl-bridge-capabilities-20260619` @ **`9f8378aa`** with foreign
   dirty paths. Never commit, stage, or check out there. Cut work from
   `origin/main` into `local-scratch/lanes/` or `.worktrees/`.

---

## Goals / mission (the durable "why")

GLLVM.jl is the Julia twin of R's `gllvmTMB`: **as capable as the twin, and
faster**. Headline speed result: ~340× per-fit median on single-σ² Gaussian
fits, machine-precision agreement on that grid. The current programme is
*capability breadth* and *honest ledgers*, not speed: Identity lock before
engine; no invented twin Δ; no public knob that only errors.

Durable ledgers: `docs/design/capability-status.md` (Julia MC) and
`docs/dev-log/plans/2026-08-16-gllvmtmb-capability-gap.md` (twin gap sheet).
Family count is no longer the gap. Live remaining holes: surface reachability
(bridge / `@formula` / formula `dep()`), estimator breadth (AGHQ, CV),
covariance-grammar depth, and unpaid light-RCall cells.

---

## Plans / roadmap (beyond the immediate next steps)

Cite, do not rewrite. Do **not** execute these unless Shinichi redirects
after you finish OWED.

- **AGHQ campaign** (PARKED / serialize): Identity #248 · Stage-1a grid #251 ·
  Liu–Pierce adapt #252 · A4(3) eligibility #253 · honesty #255 ·
  affordability `_aghq_kd_bound` #256. Remaining A4(4) adaptation-loop /
  A4(5) report-honesty / public `aghq=` wait. Collision: arcs **2 ∩ 3 ∩ 4 ∩ 5**
  all own `src/families/aghq_grid.jl`. Seven-arc ultra-plan G0 is unpaid
  (see #254). **Do not write a second plan.**
- **L47 formula `dep()`** — later Rose promote + FunctionTerm, **not** this
  handover's next chip. Wrapper #262 does not earn `implemented`.
- **Tweedie `fit_gllvm` admit** — STOP (#234). T2–T5 unpaid. Engine health
  #236/#238 is not a surface.
- **Coverage certificate / ADEMP** — Totoro or DRAC, only when Shinichi sizes
  and asks.
- **Phylo Model A (#127)** — parked; do not orphan, do not reopen.
- Earlier leftover chips: REML `test_reml.jl` promote, mixed-family / `mi()`
  ledger-verify, `scalar()` covariance-mode row.

---

## What Was Accomplished (verified live with `gh` / `git`, not recalled)

`origin/main` tip at write: **`c5b72310`** (merge of #262).
`git log origin/main -8 --oneline` at write:

```
c5b72310 Merge pull request #262 from itchyshin/cursor/lane-none-dep-engine-20260818
e87cdc1f merge: rematch none-dep engine onto #261 tip
663e6f57 Merge pull request #261 from itchyshin/cursor/truncpois-nox-bridge-20260819
4958626b test: add Σ PSD gate and none-dep check-log tally
d6ea5c5f feat: none × dep Gaussian matrix fitter at K = p
3f6f114c feat(bridge): admit no-X truncated_poisson (twin fid 10)
d9bd69ca Merge pull request #257 from itchyshin/cursor/lane-parity-beyond-20260818
f0c9c26f fix(tests): qualify GLLVM.Multinomial after Distributions import
```

CI on `main` at write: Documenter SUCCESS + Julia CI SUCCESS for the #262
push (`32287449994` / `32287449986`, 2026-08-19T18:27:35Z). #261 CI also
SUCCESS.

### This programme wave (merged on `main`)

| PR | Merge SHA | What landed | After-task |
|---|---|---|---|
| #257 | `d9bd69ca` | **Multinomial FE softmax** (twin fid 16). Marker `Multinomial`, `η₁≡0`, pack `(K−1)(1+p)`, no LV, no TMB pseudo-rows. Ledger row stays `missing`. Name-clash fix: tests qualify `GLLVM.Multinomial`. | `2026-08-18-multinomial-engine.md` + `2026-08-18-multinomial-name-clash.md` |
| #258 | `7c21cc9c` | **truncated_nbinom2 Arc1b** per-trait `log_phi_truncnb2`. | `2026-08-18-truncated-nbinom2-arc1b.md` |
| #259 | `13ccb7d5` | **lognormal no-X bridge** (twin fid 3). Light RCall Δ still **OWED**. | `2026-08-18-lognormal-bridge.md` |
| #260 | `3cb62502` | **none × dep() Identity** (docs-only ACCEPTED). L47 not flipped. | `2026-08-18-none-dep-identity.md` |
| #261 | `663e6f57` | **truncated_poisson no-X bridge** (twin fid 10). Light RCall Δ still **OWED**. | `2026-08-19-truncpois-nox-bridge.md` |
| #262 | `c5b72310` | **none × dep() engine** — `fit_dep_gllvm` wraps `fit_gaussian_gllvm(Y; K = p)`. **No** formula `dep()`. L47 stays `planned`. | `2026-08-19-none-dep-engine.md` |

### Already on `main` before this wave (do not redo)

| PR | Merge SHA | What landed |
|---|---|---|
| #251 | `fc845404` | AGHQ Stage-1a live-pin grid + `k=1` Laplace golden |
| #252 | `17f4a415` | Liu–Pierce AGHQ adaptation (`k>1`) |
| #253 | `3d5acba0` | A4(3) fail-loud declared-kwargs gate |
| #255 | `81866b1a` | A4(3) declared-kwargs honesty |
| #256 | `70c2e95f` | A4(3) affordability `_aghq_kd_bound` (`k>1` ∧ `d>5`) |

#247 remains **CLOSED UNMERGED**. Do not reopen. Substance lives in
`docs/dev-log/handover/2026-08-17-cursor-handover.md`.

Ledger at `c5b72310` (counted live from `docs/design/capability-status.md`):
**56 `implemented` · 0 `partial` · 13 `planned` · 4 `missing` · 7 `rejected`.**
The four `missing`: multinomial / categorical (engine shipped, row not
promoted), simulation-validated coverage certificate, AGHQ estimator, Broad
AGHQ. L47 `none × dep` is among the 13 `planned`.

The AGHQ *note* under the estimator row still says “Julia has no `aghq`
symbol” probed at `51ffa320` — that sentence is **stale** after #251. Do
**not** silently rewrite it in this session; a ledger-honesty chip is a
separate Shinichi ask. Do **not** quote that stale sentence as current fact.

---

## Current Working State

- **Working:** `origin/main` @ `c5b72310`. #257–#262 (plus #251–#256, #258)
  are merged. Julia + Documenter CI green on the #262 push. This worktree
  (`/Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818`) was
  clean at gate time on `cursor/a43-honesty-20260818` @ `e87a2047` (already
  merged as #255); the handover was then cut onto `handover/2026-08-24-claude`
  from `origin/main`.
- **In progress:** **#254** OPEN — Cursor handover for the post-#253 AGHQ era.
  CI green (Julia matrix + Documenter). **Leave it.** This file does **not**
  refresh `AGENTS.md` or the coordination board (those paths are #254's).
- **Not working / blocked:**
  - **This handover is unpushed** until Shinichi pushes the branch.
  - **Stale `.git/index.lock`** (0 bytes, dated Aug 16 08:26) in the Dropbox
    checkout. Gate reports it; harness blocks `.git` deletions. **Shinichi
    clears it.** It does not block `local-scratch` / `.worktrees/` work.
  - **AGHQ 2 ∩ 3 ∩ 4 ∩ 5 PARKED** (serialize on `aghq_grid.jl`).
  - **TruncPois / lognormal light RCall Δ OWED** (not invented).

---

## Key Decisions & Rationale

| Decision | Where it lives | Why it must still hold |
|---|---|---|
| Identity-before-engine | `docs/dev-log/decisions/2026-08-*` series | Locks the estimand before code can drift it. |
| No invented twin Δ | gap-sheet reading rules + every after-task in this wave | Quote only a live paired run. Twin `.valid_family` ids 0–16; Julia-forward families have no twin cell. |
| No Tweedie `fit_gllvm` admit | `docs/dev-log/decisions/2026-08-16-tweedie-fit-gllvm-identity.md` (#234) | T2–T5 unpaid. Engine health ≠ surface. |
| No stub `aghq=` | `docs/dev-log/decisions/2026-08-17-aghq-identity.md` (#248) | An argument that only errors advertises a missing capability. VA `_gauss_hermite` ≠ AGHQ. |
| AGHQ 2 ∩ 3 ∩ 4 ∩ 5 serialize | #254 + `aghq_grid.jl` | One file, four arcs. PARKED until Shinichi unparks one owner. |
| L47 stays `planned` after #262 | #260 Identity + #262 after-task | Wrapper only; no formula `dep()`. Premature `implemented` flip discarded. |
| Multinomial ledger stays `missing` | #257 after-task | FE softmax is not a promoted twin-complete row. No LV. No bridge. No `@formula`. |
| #254 is not this lane | Shannon / D-87 / D-88 | Foreign-same-platform overlap. Shinichi's call, never resolved unilaterally. |
| Dropbox checkout never written | board Current Rule | Stale fork @ `9f8378aa`. |
| Rehydrate via Active-Lane-Split, not one pointer | handover-skill Step 4 multi-lane check | A single pointer orphans #254 or this file. |

Repo-level rules that bind you regardless: `AGENTS.md` §Design rules,
§Convention-change cascade, §Definition of Done, §Hard boundaries.

---

## Landing State — the git ledger

`~/shinichi-brain/tools/handoff_gate.sh .` run from
`/Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818` on
2026-08-24 (then on `cursor/a43-honesty-20260818`; working tree clean):

**GATE FAIL** — 36 unpushed commits on other local branches. Nothing this
session authored was left uncommitted. Every failure is declared below.

Abbreviated gate body (full list of 20 stale branches is in the table):

```
XX   .                  cursor/a43-honesty-20260818  36 UNPUSHED on other branch(es);
       + 8a699242 feat(families): admit no-X COMPoisson through fit_gllvm
       + 4994649c docs: checkpoint W1-admit order + Wave2 engine ownership truth
       + 133df634 chore(agents): install Shannon, the lane coordinator
       … (historical commits; not this session)
       ^ chore/worktree-house-rule, codex/lv-bridge-xlv-20260625,
         codex/lv-predictor-c1-20260625, codex/p2-r-bridge (6),
         codex/phylo-poisson-s2-runner-reland-20260703 (6),
         codex/phylo-xlv-modela-ci-20260630 (4),
         codex/runtime-gradient-default, cursor/compoisson-nox-rebase-20260816,
         cursor/parallel-family-catchup-20260815, docs-families,
         docs/gamma-x-identity-20260803 (2), fam-zip,
         fix/gamma-x-grouped-cov-20260803 (4),
         fix/nb2-beta-x-grouped-cov-20260802, formula-slopes-spec,
         nongaussian-structured-spec, shannon-install, two-part-spec, viz-plots2
GATE FAIL -- 1 of 1 repo(s) have UNLANDED state.
```

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` @ `c5b72310` (#257–#262 + #251–#256) | y | y | all merged | **LANDED** |
| This handover: `handover/2026-08-24-claude` | y (this commit) | **n** | none | **CARRIED-OVER until Shinichi pushes** |
| #254 `cursor/handover-20260818` @ `345b56cb` | y | y | [#254](https://github.com/itchyshin/GLLVM.jl/pull/254) **OPEN** | **CARRIED-OVER — leave alone** |
| Dropbox checkout `claude/jl-bridge-capabilities-20260619` @ `9f8378aa` (modified `.claude/preview/*`; untracked `.claude/agents/*`) | n | n | none | **PROTECTED — never land** |
| `.git/index.lock` (0 bytes, Aug 16 08:26) in the Dropbox checkout | n/a | n/a | none | **CARRIED-OVER — Shinichi only** |
| 36 unpushed commits across ~20 stale branches (gate list) | y (local) | n | none | **CARRIED-OVER** |
| ~99 historical worktrees (Dropbox `.worktrees/` + `.claude/worktrees/` + `local-scratch/lanes/`) | mixed | mixed | mixed | **CARRIED-OVER** |
| `local-scratch/lanes/GLLVM.jl-none-dep-engine-20260818` dirty (`capability-status.md` L47 flip + leftover `src/none_dep.jl`) | n | n | none | **RETRACTED / discarded** — #262 is the landed engine; do not revive the flip |
| `local-scratch/lanes/GLLVM.jl-aghq-a43-afford-20260818` untracked `docs/dev-log/evidence/` | n | n | none (#256 already merged) | **CARRIED-OVER** — do not land unprompted |
| #247 `cursor/overnight-surface-handoff-20260817` | y | y | [#247](https://github.com/itchyshin/GLLVM.jl/pull/247) **CLOSED UNMERGED** | **CARRIED-OVER** — do not reopen |
| Uncommitted seven-arc ultra-plan (cited by #254) | n | n | none | **CARRIED-OVER** — do not write a second plan |
| Phylo Model A #127 | n/a | n/a | closed/parked | **CARRIED-OVER** — do not orphan |

**Why each `CARRIED-OVER` is not landed, and how to resume it:**

- **This handover branch** — user rule: no push without explicit instruction.
  *Resume (Shinichi):*
  `git -C /Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818 push -u origin handover/2026-08-24-claude`
  then `gh pr create` from that branch. Human merges. Do not `--auto`.
- **#254** — stale relative to `c5b72310`, but it is the other live lane's
  artifact. *Resume:* only if Shinichi asks to merge, close, or rebase it.
  `gh pr view 254`. Do not pile this file onto that PR.
- **`.git/index.lock`** — *Resume:* Shinichi runs
  `rm "/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.git/index.lock"`.
  No agent.
- **36 unpushed stale branches** — abandoned or superseded June–August lanes.
  Pushing them now would resurrect superseded designs. *Resume, only if a
  specific one is wanted:*
  `git log --oneline origin/main..<branch>` first; do **not** bulk-push.
  Re-run: `~/shinichi-brain/tools/handoff_gate.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"`.
- **Historical worktrees** — most already merged. *Resume, if Shinichi asks
  for GC:* `git worktree prune` then remove by name. Not OWED.
- **Dirty `GLLVM.jl-none-dep-engine-20260818`** — leftover of the discarded
  L47 promote. *Resume:* do not. `git -C … restore` / leave it. #262 is
  truth.
- **Dirty `GLLVM.jl-aghq-a43-afford-20260818` `docs/dev-log/evidence/`** —
  untracked evidence after #256 merged. *Resume:* inspect only if Shinichi
  wants it archived; do not add it to a new PR unprompted.
- **#247** — closed unmerged 2026-08-17. Substance in the 2026-08-17 Cursor
  handover. *Resume:* cherry-pick only if Shinichi wants that overnight
  record on `main` as its own artifact.
- **Seven-arc ultra-plan** — uncommitted; G0 unpaid. *Resume:* land that
  one file if Shinichi wants it, after reading it. Path cited in #254.
- **#127** — parked redesign. *Resume:* read
  `docs/dev-log/handover/2026-06-30-codex-handover.md`. Do not reopen.

Anything not in this table does not exist as far as the next agent is
concerned.

---

## Next Immediate Steps — classified. Execute **OWED** only.

Per `~/shinichi-brain/protocols/handoff.md`: a handoff is a dated state
record, not an instruction to repeat work. At the start of the receiving
lane: run lane preflight, inspect `git status` and recent history, compare
this file with current canonical decisions, then classify every item
**OWED · DONE · RETRACTED · PROTECTED**. Execute only `OWED`.

### OWED — do these, in this order

1. **Lane preflight first (absolute path, not the repo name).**
   ```sh
   ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
   ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818"
   ```
   State the line it asks for. If a foreign or second-same-platform lane owns
   your intended files, stop. #254 is the other live Cursor lane.
2. **Confirm the tip and classify again.**
   ```sh
   git fetch origin
   git log origin/main -8 --oneline
   gh pr list --state open --limit 10
   gh run list --limit 3 --branch main
   ```
   Expect `c5b72310` or later. If `main` moved, re-classify this file against
   the new tip before acting. Do **not** merge #254. Do **not** reopen #247.
3. **truncated_poisson light RCall Δ — OWED, not invented.** Twin fid 10.
   After-task: `docs/dev-log/after-task/2026-08-19-truncpois-nox-bridge.md`.
   Only a live paired `GLLVM_PARITY_TESTS=1` RCall cell may quote a number.
   If this session cannot run the live twin, write the cell (or confirm the
   existing test hook) and **stop** — do not invent. Codex owns a live
   `gllvmTMB` fit if the compiler/RCall path is missing here.
4. **lognormal light RCall Δ — same rule.** Twin fid 3. After-task:
   `docs/dev-log/after-task/2026-08-18-lognormal-bridge.md`. Same “live or
   silent” fence.
5. **Stop.** Do not start AGHQ 2 ∩ 3 ∩ 4 ∩ 5. Do not flip L47. Do not open
   formula `dep()`. Do not Tweedie-admit. Do not stub `aghq=`. Do not
   refresh `AGENTS.md` / the coordination board (those are #254's files).
   Do not write a second ultra-plan.

### DONE — do not redo

#251, #252, #253, #255, #256, #257, #258, #259, #260, #261, #262, and the
earlier surface-admit / ZIB / ZIP+X / ZINB+X era listed in
`docs/dev-log/handover/2026-08-17-cursor-handover.md`. Overnight A4(3)
eligibility is paid. Honesty #255 is paid. Affordability half is paid.
Multinomial FE engine is paid (ledger still `missing`). none-dep Identity
+ wrapper are paid (L47 still `planned`).

### RETRACTED — do not propagate

- Premature L47 `implemented` flip on `cursor/none-dep-engine-20260818`.
- Renaming VA `_gauss_hermite` as AGHQ to flip a ledger token.
- A stub `aghq=` / `method = "AGHQ"` that only throws.
- Invented twin Δ for TruncPois, lognormal, multinomial, AGHQ, Tweedie, or
  any Julia-forward family.
- Phylo Model A public `lv` intervals (`rejected` for advertising).
- Non-Gaussian REML (`rejected`).
- Re-merging #247.

### PROTECTED — do not touch

- **#254** and its three files (`AGENTS.md`, `coordination-board.md`,
  `2026-08-18-cursor-handover.md`).
- **Dropbox checkout** @ `9f8378aa` and its dirty `.claude/preview/*` /
  untracked agent rosters.
- **`.git/index.lock`** — Shinichi only.
- **Tweedie `fit_gllvm` / `@formula` / bridge surface.**
- **`aghq_grid.jl`** while arcs 2 ∩ 3 ∩ 4 ∩ 5 are parked (serialize).
- **`AGENTS.md` / `CLAUDE.md`** edits beyond a Phase-state snapshot line,
  and `.codex/agents/*` / `.agents/skills/*` — maintainer approval.
  Snapshot refresh is skipped here because of the multi-lane check.
- **R `gllvmTMB` engine** — read-only reference. No surgery from this repo.

---

## Blockers / Open Questions

- **This handover is unpushed.** The receiving Claude session that starts
  from `origin` cannot read this file until Shinichi pushes. Open question
  for Shinichi: push + PR, or keep local?
- **#254 is still OPEN and stale vs `c5b72310`.** Merging it now would
  rewind the board's Active-Lane-Split to the post-#253 story. Open
  question for Shinichi: close #254 as superseded by this file, rebase
  #254 onto `c5b72310`, or leave it until you ask?
- **`.git/index.lock`** needs Shinichi.
- **AGHQ G0 unpaid.** The seven-arc ultra-plan is still a dated prior, not
  an execution order.
- **Stale AGHQ ledger note** (“no `aghq` symbol”) vs live `aghq_grid.jl`.
  Honesty chip only if Shinichi asks; not this file's OWED.

---

## Gotchas & Failed Approaches

- **`handoff_gate.sh` on this repo walks ~99 worktrees and can take minutes.**
  It is not hung. Repo-local `tools/handoff_gate.sh` does **not** exist;
  use `~/shinichi-brain/tools/handoff_gate.sh <abs-path>`.
- **`lane_preflight.sh` needs a path, not a repo name.**
  `lane_preflight.sh GLLVM.jl` prints `not a directory` and exits 0 — a
  silent no-op. Pass the absolute path.
- **Do not run two Julia processes at once.** ForwardDiff fitters allocate
  several GB; two concurrent `Pkg.test()` / fit processes GC-thrash and
  look hung. `Pkg.test()` is ~50 min (what CI runs). Focused
  `julia --project=. --startup-file=no test/test_<file>.jl` is the cheap
  local check.
- **Never `git add -A` / `git add .`.** Disjoint lanes edit in parallel.
  Stage by explicit path.
- **Never `gh pr merge --auto`.** Merge only after full Julia + Documenter
  SUCCESS, with `gh pr merge N --merge`, and only when Shinichi asks.
- **Two AGHQ grids exist in the twin.** `.gllvmTMB_aghq_grid` (live pin,
  probabilists') vs `.aghq_grid` (peer helper, physicists'). Julia
  `_gauss_hermite` is the physicists' VA rule. Confusing them changes the
  measure.
- **`"ordered"` on the bridge already means *ordinal*.** Do not reuse it
  for ordered-beta.
- **Multinomial vs `Distributions.Multinomial`.** Public marker stays
  `Multinomial`; tests must qualify `GLLVM.Multinomial` (#257 name-clash).
- **#262 is not formula `dep()`.** `git grep -n 'dep('` over `src/formula.jl`
  should still be empty of a FunctionTerm. `fit_dep_gllvm` ≠ L47 promote.
- **Force-push to rematch is forbidden.** Merge `origin/main` into the
  branch.

---

## Environment — Claude specifics

Assume nothing about the authoring Cursor terminal, credentials, or
extensions. Verify.

```sh
# 0. Julia is NOT reliably on PATH. juliaup lives here:
export PATH="$HOME/.juliaup/bin:$PATH"
julia --version                     # expect >= 1.10 (CI primary = 1.10)

# 1. Never work in the Dropbox checkout. Preferred roots:
#    /Users/z3437171/local-scratch/lanes/<lane>
#    or a fresh .worktrees/<lane> cut from origin/main
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818
git fetch origin
git checkout handover/2026-08-24-claude   # this file's branch, once pushed
# if the branch is not on origin yet, stay on a fresh worktree from origin/main
# and read this file from the local-scratch copy

# 2. Lane pre-flight BEFORE claiming files:
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
```

**Safe verification**

| Command | When |
|---|---|
| `julia --project=. --startup-file=no test/test_<file>.jl` | Cheap local check |
| `julia --project=. -e 'using Pkg; Pkg.test()'` | Full suite incl. Aqua/JET; **~50 min**; what CI runs; **never two at once** |
| `julia --project=. test/runtests.jl` | Core suite; skips Aqua/JET |
| `GLLVM_PARITY_TESTS=1` + RCall cell | Only when quoting a twin Δ |

**Do NOT stage these**

```
.claude/preview/index.html      .claude/preview/status.json
.claude/preview/sweep.json      .claude/preview/version.txt
.claude/agents/*.md             .cursor/agents/*.md
.codex/agents/*.toml            .codex/agents/tiers.tsv
.worktrees/**                   .claude/worktrees/**
.git/index.lock
docs/design/capability-status.md   # unless Shinichi asks; L47 stay planned
AGENTS.md                          # #254 owns this until that PR closes
docs/dev-log/coordination-board.md # #254 owns this until that PR closes
src/families/aghq_grid.jl          # PARKED serialize
```

Stage by explicit path. `git add -A` and `git add .` are forbidden.

**Merging:** `gh pr merge N --merge` after full Julia + Documenter SUCCESS.
Never `--auto`. Never push without Shinichi's instruction.

---

## Files Created / Modified — this handover

`git diff --name-only origin/main...handover/2026-08-24-claude` (this
commit):

| Path | Change |
|---|---|
| `docs/dev-log/handover/2026-08-24-claude-handover.md` | **new** — this file |
| `docs/dev-log/check-log.md` | append-only entry for this handover |

No `src/`, `test/`, `AGENTS.md`, `CLAUDE.md`, or
`docs/dev-log/coordination-board.md` path is touched. Multi-lane check:
#254 owns the snapshot files; refreshing them here would orphan that lane.

Engine PRs of the wave (#257–#262) are already on `main` with after-task
reports under `docs/dev-log/after-task/`.

---

## Mission control

| Repo | Branch / tip | CI | What shipped | Plan by leverage |
|---|---|---|---|---|
| **GLLVM.jl** | `main` @ `c5b72310` (#262). This file on `handover/2026-08-24-claude` (**unpushed**) | green on #262 push (Julia + Documenter) | #257 multinomial FE · #258 truncNB2 Arc1b · #259 lognormal no-X bridge · #260 none-dep Identity · #261 TruncPois no-X bridge · #262 `fit_dep_gllvm` | **1.** preflight · **2.** confirm tip · **3.** TruncPois light RCall Δ (live or silent) · **4.** lognormal light RCall Δ (live or silent) · **stop** |
| `gllvmTMB` (R twin) | read-only reference | — | `.valid_family` ids 0–16; AGHQ + CV shipped there | never engine-surgery from this repo; never invent a Δ |

Ledger at `c5b72310`: **56 implemented · 0 partial · 13 planned · 4 missing · 7 rejected.**
L47 planned. Multinomial missing. AGHQ missing. No public `aghq=`.

---

## How to Resume

Read in this order:

1. `AGENTS.md` (repo rules, Definition of Done, hard boundaries)
2. **this file**
3. `docs/dev-log/coordination-board.md` → **Active Lane Split** (multi-lane
   pointer; also read #254's
   `docs/dev-log/handover/2026-08-18-cursor-handover.md` as a dated prior)
4. `docs/design/capability-status.md` and
   `docs/dev-log/plans/2026-08-16-gllvmtmb-capability-gap.md`
5. Binding decisions: `2026-08-18-none-dep-identity.md`,
   `2026-08-18-multinomial-identity.md`,
   `2026-08-17-aghq-identity.md`,
   `2026-08-16-tweedie-fit-gllvm-identity.md`,
   `2026-08-15-truncated-poisson-identity.md`,
   `2026-08-15-lognormal-identity.md`
6. After-tasks for #257–#262 (paths in the table above)

Then reconcile with live state:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"
cd /Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818
git fetch origin
git log origin/main -8 --oneline
gh pr list --state open --limit 10
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
```

Then execute **OWED only**.

### One-command resume — paste this into a fresh Claude session in this repo

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-24-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

Interactive Claude CLI (human's own authenticated terminal; a child
`claude -p` from inside another session 401s):

```sh
claude "Rehydrate from docs/dev-log/handover/2026-08-24-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps."
```

### Which tool does what next

- **Claude** (you): rehydrate, classify, ledger-honest prose, and the
  TruncPois / lognormal light-RCall *cell* if you can run it. If you cannot
  run RCall, write the cell and stop.
- **Codex** owns a live `gllvmTMB` side-by-side fit / `R CMD check` if the
  Δ cell needs the compiler toolchain.
- **Cursor** already closed this wave's engine chips; do not reopen them.
- **Totoro / DRAC** own coverage / ADEMP. Never laptop-scale, only when
  Shinichi sizes and asks.
