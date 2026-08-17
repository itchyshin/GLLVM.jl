# Session Handoff → Cursor: GLLVM.jl surface-admit era close (2026-08-17)

**Meta:** 2026-08-17 (MDT) · **from** Cursor · **to** Cursor (fresh session, no
inherited chat context) · authored under
`~/shinichi-brain/protocols/handover-skill.md` (`TARGET = cursor`,
`AUTHOR = cursor`), content template `~/shinichi-brain/protocols/handoff.md`.

You are **Cursor**, picking up GLLVM.jl in a brand-new chat. You inherit **no**
context from the session that wrote this file. Everything you need is below or
linked from below. Read `AGENTS.md` first, then this file, then reconcile against
live `git` / `gh` before you touch anything.

---

## Critical Context — read these five or you will go wrong

1. **The Dropbox checkout is PROTECTED.** `/Users/z3437171/Dropbox/Github Local/GLLVM.jl`
   sits on the stale branch `claude/jl-bridge-capabilities-20260619` with ~25
   uncommitted paths that are **not yours**. Never commit, stage, or check out
   there. All work happens in a fresh `.worktrees/<lane>` cut from `origin/main`.
2. **Mac-light.** This machine does **not** run the full `Pkg.test()` suite. Local
   verification = one focused test file. The full suite is **GitHub CI on a PR**.
   Anything heavier (coverage, ADEMP, parity campaigns) is **Totoro or DRAC**, and
   only when Shinichi sizes and asks for it.
3. **Never invent a twin `gllvmTMB` Δ.** A numerical parity number may only be
   quoted if a live paired run produced it. For families the twin does not have
   (`.valid_family` ids 0–16), and for estimators Julia does not implement (AGHQ),
   *any* Δ would be fabricated. This fence has held all week — keep it.
4. **Never `gh pr merge --auto`.** Merge only after **full** Julia + Documenter
   SUCCESS, with `gh pr merge N --merge`.
5. **Lane pre-flight before you claim anything.** This repo runs many concurrent
   lanes (11 live at the last census). Run
   `~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"`
   and state the line it asks for before your first commit.

---

## Goals / mission (the durable "why")

GLLVM.jl is the Julia twin of R's `gllvmTMB`: **as capable as the twin, and
faster**. The Gaussian + phylogenetic path is the headline speed result (~340×
per-fit median on single-σ² Gaussian fits, machine-precision agreement on that
grid). The current programme is *capability breadth*, not speed: closing the
Julia↔twin gap family by family, surface by surface, each behind an Identity
lock before any engine code.

Durable ledger of that gap: `docs/design/capability-status.md` (Julia MC ledger)
and `docs/dev-log/plans/2026-08-16-gllvmtmb-capability-gap.md` (the twin gap
sheet). The gap sheet's headline still holds: **family count is no longer the
gap** — Julia admits more distinct response families than the twin, and
`multinomial` is the single remaining family-shaped twin hole. The real gaps have
moved to (a) surface reachability, (b) estimator breadth (AGHQ, CV), and
(c) covariance-grammar depth.

---

## What Was Accomplished (verified live with `gh` / `git`, not recalled)

`origin/main` tip at write: **`1dafee68`** (merge of #248).

| PR | Merge SHA | What landed |
|---|---|---|
| #234 | `7b45ba04` | **Tweedie no-X `fit_gllvm` Identity — STOP verdict** + engine-health gate |
| #235 | `497be1c4` | Bridge fix: no-X ZIP arm made reachable (`fit.link`) |
| #236 | `cb3c8716` | Tweedie health: `fit_tweedie_gllvm` stops advertising false convergence (G-a…G-d) |
| #238 | `e0eabb6f` | Tweedie health: same for `fit_tweedie_gllvm_grouped` |
| #241 | `5bd236dc` | **COM-Poisson** no-X `fit_gllvm` surface admit |
| #242 | `fce43de4` | **Hurdle-NB** Identity (docs-only; tag-payload `r`) |
| #243 | `104ec5a7` | **Beta-hurdle** Identity (docs-only; tag-payload `φ`) |
| #244 | `07a01ede` | **Hurdle-NB** no-X surface admit (focused 24/24, 22.7 s) |
| #245 | `320c83b1` | **Beta-hurdle** no-X surface admit |
| #246 | `51ffa320` | **Ordered-beta** no-X surface admit (focused 36/36, 11.5 s) |
| #248 | `1dafee68` | **AGHQ estimator Identity** — `missing`, *not* a surface admit |

Earlier in the same era (already on main before this stretch): the overnight
catch-up #205–#220 sequence and the day/night surface admits, including

| PR | Merge SHA | What landed |
|---|---|---|
| #205 | `d827fd81` | Capability catch-up post-#204: truncated_poisson + ledger honesty |
| #218 | `ccc9807b` | **ZIB** no-X admitted through `fit_gllvm` |
| #220 | `f627d0ae` | **ZIB** no-X through `@formula` (bridge fenced) |
| #231 | `5c589dc3` | **ZIB** no-X on the bridge, with a required shared scalar trials count |

### The two locks worth restating

**Tweedie (#234, reinforced by #236/#238).** The `fit_gllvm` surface admit is
**STOP**. #236 and #238 fixed the *engine health* problem the Identity named —
both `fit_tweedie_gllvm` and `fit_tweedie_gllvm_grouped` no longer advertise
false convergence — but the **surface stays shut**. Gates T2–T5 are unpaid. Do
**not** open a Tweedie `fit_gllvm` / `@formula` / bridge admit.

**AGHQ (#248).** `docs/dev-log/decisions/2026-08-17-aghq-identity.md`. Both AGHQ
ledger rows stay `missing`. Locked findings, in the order you will need them:

- Julia has **no** `aghq` symbol under `src/` or `test/`. VA `_gauss_hermite`
  (`src/families/variational.jl`) is an **ELBO** quadrature — *not* AGHQ. Do not
  rename it to flip a ledger token.
- The twin's shipped surface is four internal modules (`R/aghq-control.R`,
  `aghq-gate.R`, `aghq-auto-ridge.R`, `aghq-report.R`) behind one public control
  knob, `gllvmTMBcontrol(aghq = FALSE | <int> | "auto")`, self-described as
  **opt-in and experimental**.
- The pin a Julia engine must twin is **Stage 1a only**: quadrature over the
  between-unit reduced-rank latent `z_B`, loadings-only. `.gllvmTMB_aghq_grid`
  in `R/fit-multi.R` is the **live** grid (probabilists' nodes,
  `logw_j = Σ_m log w_{j_m} + (d/2) log 2π + ½ u_j'u_j`). `.aghq_grid` in
  `R/aghq-control.R` is a peer helper on physicists' nodes — **not** the pin.
- **`k = 1` reproduces Laplace exactly.** That is the first golden test, not a
  capability claim.
- No stub `aghq=` knob that only errors. No twin Δ (there is no Julia engine to
  produce one).

### Near-parity ledger, counted live at `1dafee68`

`docs/design/capability-status.md`: **58 `implemented`**, **3 `partial`**,
**13 `planned`** rows, **4 `missing`** rows. The four `missing`:

| Row | Note |
|---|---|
| multinomial / categorical | the only remaining family-shaped twin gap; needs Identity → likelihood → engine → test, a campaign not an admit |
| Simulation-validated coverage certificate (broad grid) | compute campaign (Totoro/DRAC), not a code arc |
| AGHQ estimator | locked `missing` by #248 |
| Broad AGHQ (Julia) | locked `missing` by #248 |

The 13 `planned` rows are dominated by covariance-grammar depth —
`none × dep()` (unstructured trait covariance without LV), `phylo_dep()`,
`animal_dep()` / `animal_latent()`, `spatial_dep()`, the whole `kernel_*` source,
keyworded random slopes, uncorrelated slopes, `mi()`, mixed-family response, and
bridge structured-source parity. Cross-validation is a fifth sibling gap tracked
in the gap sheet (§3) rather than as its own ledger row.

---

## Current Working State

- **Working:** `origin/main` @ `1dafee68`. All of #234–#248 above are merged. The
  no-X surface-admit sequence (COM-Poisson → Hurdle-NB → Beta-hurdle →
  Ordered-beta) is complete and the ZIB three-surface arc (`fit_gllvm` #218 →
  `@formula` #220 → bridge #231) is complete.
- **In progress:** **#247** — `docs: overnight surface-admit handoff (2026-08-17)`,
  docs-only, branch `cursor/overnight-surface-handoff-20260817`. `MERGEABLE`, but
  `mergeStateStatus: UNSTABLE`: Documenter, `documenter/deploy`,
  `Julia 1.10 - ubuntu-latest`, and `Julia 1 - macOS-latest` are all **SUCCESS**;
  `Julia 1 - ubuntu-latest` and `Julia 1 - windows-latest` were still
  **IN_PROGRESS** at write time (that CI matrix has been running ~90 min/job on
  this tip). See the Landing State ledger for its disposition and resume command.
- **Not working / blocked:** nothing in the engine. Two housekeeping items:
  - **Stale `.git/index.lock`** (zero bytes, dated Aug 16 08:26) in the Dropbox
    checkout. The handoff gate reports it and refuses to remove it; the harness
    blocks `.git` deletions. **Shinichi clears this**, no agent. It does not block
    worktree work.
  - The coordination board's **Active-Lane-Split** was last refreshed 2026-08-15
    and its `START HERE (Cursor)` bullet still points at the capability-catch-up
    STOP. This handover updates it; if you find it stale again, that is the
    pointer to fix.

---

## Key Decisions & Rationale

| Decision | Where it lives | Why it must still hold |
|---|---|---|
| Tweedie `fit_gllvm` admit = STOP | `docs/dev-log/decisions/2026-08-16-tweedie-fit-gllvm-identity.md` (#234) | T2–T5 unpaid. Engine health (#236/#238) fixed convergence honesty; it did **not** earn the public surface. |
| AGHQ stays `missing`; no stub knob | `docs/dev-log/decisions/2026-08-17-aghq-identity.md` (#248) | An argument that can only error advertises a capability the package lacks. VA GH ≠ AGHQ. |
| Identity-before-engine for every family | the `docs/dev-log/decisions/2026-08-1*` series | Locks the estimand and the tag-payload contract before code can drift it. |
| Tag-payload markers are inert | #242 / #243 / #246 Identities | `HurdleNB(10.0)`, `BetaHurdle(5.0)`, `OrderedBeta(-1.0, 1.0, 10.0)` carry defaults that are **never read** and never become inits. Tag-inertness is tested. |
| No twin Δ for Julia-forward families | gap sheet reading rules | The twin's `.valid_family` has no ZI, hurdle, ordered-beta, COM-Poisson, or censored-Poisson entry. |
| Bridge execution is R→Julia via JuliaCall; RCall is an opt-in oracle | coordination board Current Rule | Keeps parity tests off the CI critical path (`GLLVM_PARITY_TESTS`). |
| Rehydrate via the board's Active-Lane-Split, not one `START HERE` bullet | coordination board Current Rule + handover-skill Step 4 multi-lane check | A single pointer orphans the other live lanes. |

Repo-level rules that bind you regardless: `AGENTS.md` §Design rules,
§Convention-change cascade, §Definition of Done, §Hard boundaries.

---

## Landing State — the git ledger

`handoff_gate.sh` verdict at write: **GATE FAIL — 1 of 1 repo(s) have UNLANDED
state** (25 uncommitted paths; 36 unpushed commits across other branches). Every
one of those items is **pre-existing debris from earlier sessions on the protected
checkout**, not work this session produced. Each is declared below. Nothing this
session authored is left undeclared.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` @ `1dafee68` (#234–#248 era) | y | y | all merged | **LANDED** |
| #247 `cursor/overnight-surface-handoff-20260817` (docs-only) | y | y | [#247](https://github.com/itchyshin/GLLVM.jl/pull/247) open | see disposition below |
| This handover: `cursor/handover-20260817`, worktree `.worktrees/gllvmjl-cursor-handover-20260817` | y | y | PR opened → merged to `main` | **LANDED** |
| Dropbox checkout `claude/jl-bridge-capabilities-20260619` — 25 uncommitted paths (`.claude/preview/*` modified; `.claude/agents/*`, `.cursor/agents/*`, `.codex/agents/*` untracked) | n | n | none | **PROTECTED — never land** |
| `.git/index.lock` (0 bytes, Aug 16 08:26) in the Dropbox checkout | n/a | n/a | none | **CARRIED-OVER — Shinichi only** |
| 36 unpushed commits across 20 stale branches (`codex/p2-r-bridge` 6, `codex/phylo-poisson-s2-runner-reland-20260703` 6, `fix/gamma-x-grouped-cov-20260803` 4, `codex/phylo-xlv-modela-ci-20260630` 4, `docs/gamma-x-identity-20260803` 2, + 15 branches × 1) | y (local) | n | none | **CARRIED-OVER** |
| ~85 `.worktrees/` + `.claude/worktrees/` checkouts from prior lanes | mixed | mixed | mixed | **CARRIED-OVER** |

**Why each `CARRIED-OVER` is not landed, and how to resume it:**

- **`.git/index.lock`** — a zero-byte stale lock. The handoff gate reports but
  never removes it, and the agent harness blocks `.git` deletions. *Resume:*
  Shinichi runs `rm "/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.git/index.lock"`.
  No agent should attempt it. It does not block `.worktrees/` work.
- **36 unpushed commits on 20 stale branches** — abandoned or superseded
  exploratory lanes from June–August (Codex phylo/bridge experiments, Gamma+X
  grouped-cov, spec branches). Their content either landed via a different PR or
  was retired by a later Identity. Pushing them now would resurrect superseded
  designs. *Resume, only if a specific one is wanted:*
  `git -C "/Users/z3437171/Dropbox/Github Local/GLLVM.jl" log --oneline origin/main..<branch>`
  to inspect first; do **not** bulk-push. Full gate output is reproducible with
  `~/shinichi-brain/tools/handoff_gate.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"`
  (~5 min; it walks every worktree).
- **The ~85 worktrees** — one per historical lane, most already merged. Harmless
  but noisy. *Resume, if Shinichi asks for GC:*
  `git -C "/Users/z3437171/Dropbox/Github Local/GLLVM.jl" worktree prune` then
  remove merged-branch worktrees by name. Not OWED; do not do it unprompted.
- **PROTECTED Dropbox uncommitted paths** — agent-roster and preview files from
  other tools' sessions. They are **not** to be landed by any lane. Treat as
  read-only.

### #247 disposition

Docs-only, one file
(`docs/dev-log/handover/2026-08-17-overnight-surface-handoff.md`), Documenter
green, three of five Julia jobs green. If you find it **still open**, that means
the last two CI jobs had not reported when this handover landed:

```sh
gh pr view 247 --json mergeable,mergeStateStatus,statusCheckRollup \
  --jq '{m:.mergeStateStatus, c:[.statusCheckRollup[]|{n:(.name//.context),s:(.conclusion//.state//.status)}]}'
# all SUCCESS  ->
gh pr merge 247 --merge          # NEVER --auto
```

If it reads `DIRTY` against `origin/main`, rematch by merging `origin/main`
**into** the PR branch — **no force-push**.

---

## Next Immediate Steps — classified. Execute **OWED** only.

Per `~/shinichi-brain/protocols/handoff.md`: a handoff is a dated state record,
not an instruction to repeat work. Classify, then act.

### OWED — do these, in this order

1. **Confirm the tip and close #247.** `git fetch origin main` and check
   `git log -3 --oneline origin/main`; expect `1dafee68` or later (later, if this
   handover's own PR and/or #247 landed). Then run the #247 block above: merge on
   full green with `gh pr merge 247 --merge`, or rematch if dirty. Also confirm
   the tip's own CI is green before starting engine work.
2. **AGHQ Stage-1a `/arc-creation` — grid + `k = 1` golden test.** This is the
   next real slice, and it is **not** a family admit and **not** a surface admit.
   Scope, straight from #248 §A4 item (1):
   - a new symbol implementing the **live** `.gllvmTMB_aghq_grid` convention —
     probabilists' (standard-normal) nodes, three-term
     `logw_j = Σ_m log w_{j_m} + (d/2) log 2π + ½ u_j'u_j`, with the sanity
     identity `Σ_j exp(logw_j) φ_d(u_j) = 1`;
   - a golden test that **`k = 1` matches the existing dense Laplace marginal**;
   - it must **not** call `_gauss_hermite` and relabel it — different measure,
     different integral;
   - Stage 1a only: single loadings-only `z_B` block, fail-loud otherwise;
   - **out of this arc:** per-site adaptation, the structural gate, the
     adaptation loop, report honesty, `aghq_ridge`, any public `aghq=` knob, any
     ledger promotion, any twin Δ. Both AGHQ ledger rows stay `missing` until an
     engine + test exist.

   Run `/arc-creation` first — #248 explicitly says the engine campaign is unpaid
   and must not start without a fresh arc card.
3. **Near-parity leftovers**, in cost order, only after (1)–(2) or if Shinichi
   redirects:
   - **unstructured `dep()`** (`none × dep`, trait covariance without LV) — the
     cheapest of the 13 `planned` covariance-grammar rows and the natural entry
     to the `*_dep()` family;
   - **cross-validation** — the twin ships `R/cv-internal.R` + `R/cv-metrics.R`;
     Julia has no `crossval` symbol. A campaign, Identity-first;
   - **coverage certificate** — the broad simulation-validated grid. This is a
     **compute campaign on Totoro or DRAC**, not a laptop arc, and not to be
     started without Shinichi sizing it.
   - Cheaper opportunistic chips already scoped in the gap sheet §5, if you want a
     short slice instead: `test_reml.jl` to unblock a REML ledger promote; the
     mixed-family and `mi()` ledger-verify Rose pass; the `scalar()` covariance-mode
     ledger row.

### DONE — do not redo

Every row in the two tables under *What Was Accomplished*: #205, #218, #220,
#231, #234, #235, #236, #238, #241, #242, #243, #244, #245, #246, #248 — all
merged with the SHAs shown. The no-X surface-admit sequence is closed. The ZIB
three-surface arc is closed. The AGHQ Identity is written; do not re-derive it.

### RETRACTED — do not propagate

- Renaming VA `_gauss_hermite` as AGHQ to flip a ledger token (#248 §A1/§A2).
- A stub `aghq=` / `method = "AGHQ"` argument that only throws (#248 §A3).
- Phylo Model A public `lv` intervals — `rejected` for advertising.
- Non-Gaussian REML — deliberately `rejected`.

### PROTECTED — do not touch

- **Tweedie `fit_gllvm` / `@formula` / bridge surface admit** — shut until T2–T5
  are paid (#234). #236/#238 fixed engine health only.
- **Inventing a twin `gllvmTMB` light Δ** — for any Julia-forward family, or for
  AGHQ, where no Julia engine exists to produce a number.
- **The Dropbox checkout** `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` on
  `claude/jl-bridge-capabilities-20260619`, and its 25 uncommitted paths.
- `.git/index.lock` — Shinichi clears it.
- `AGENTS.md` / `CLAUDE.md` edits beyond a Phase-state snapshot line, and
  `.codex/agents/*` / `.agents/skills/*` — maintainer approval required.

---

## Blockers / Open Questions

- **#247's last two CI jobs.** Not a blocker for engine work; the merge is
  mechanical once they report. Handled by OWED step 1.
- **`.git/index.lock`** needs Shinichi. Agents cannot clear it.
- **AGENTS.md `## Phase state snapshot` is badly stale** — it still describes
  Phase 0 / 1.1 (node-frame gradient, Takahashi swap) while `main` is deep in the
  family-breadth programme. No recent lane has touched it (last `AGENTS.md`
  commit is the ZINB+X era), and rewriting it is a maintainer-approval change.
  **Open question for Shinichi:** rewrite that block to describe the current
  programme, or delete it and let the coordination board's Active-Lane-Split be
  the sole pointer? This handover refreshes the board only.
- **11 live lanes at the last census.** Concurrency is fine; bleed-through is
  not. If your intended files overlap another lane, surface it to Shinichi — it
  is his call, not yours.

---

## Gotchas & Failed Approaches

- **`handoff_gate.sh` on this repo takes ~5 minutes.** It walks ~85 worktrees.
  It is not hung. Run it in the background and do other reads meanwhile.
- **`lane_preflight.sh` needs a path, not a repo name.** `lane_preflight.sh GLLVM.jl`
  prints `not a directory` and exits 0 — a silent no-op that looks like a pass.
  Pass the absolute path.
- **Do not run `Pkg.test()` locally.** Mac-light. It is not the verification
  route here; CI is.
- **Two AGHQ grids exist in the twin and they are not interchangeable.**
  `.gllvmTMB_aghq_grid` (live pin, probabilists') vs `.aghq_grid`
  (peer helper, physicists'). Julia's `_gauss_hermite` is the physicists' rule.
  Confusing them silently changes the measure.
- **`"ordered"` on the bridge already means *ordinal*.** Do not reuse the token
  for ordered-beta.
- **`OrderedBeta` include order matters.** `families/ordered_beta.jl` must be
  included **before** `families/fit_gllvm.jl` (#246).
- **Never `git add -A` / `git add .`.** Disjoint lanes are editing in parallel.
- **Never force-push** to rematch a PR; merge `origin/main` into the branch.

---

## Environment — Cursor specifics

Assume nothing about extensions, credentials, or terminal state; verify.

```sh
# 0. Julia is NOT reliably on PATH. juliaup lives here:
export PATH="$HOME/.juliaup/bin:$PATH"
julia --version                     # expect >= 1.10

# 1. Never work in the Dropbox checkout. Cut a worktree from origin/main:
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main
git worktree add ".worktrees/gllvmjl-<lane>-20260817" -b "cursor/<lane>-20260817" origin/main
cd ".worktrees/gllvmjl-<lane>-20260817"

# 2. Lane pre-flight BEFORE claiming files (absolute path, not the repo name):
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
```

**Safe verification command (Mac-light).** One focused test file, never the full
suite:

```sh
julia --project=. --startup-file=no test/test_<family>.jl
```

The **full** suite is `julia --project=. -e 'using Pkg; Pkg.test()'` and runs
**only on GitHub CI via a PR**. Anything larger — coverage grids, ADEMP campaigns,
R-parity sweeps — is **Totoro** (fast CPU ≤100 cores) or **DRAC** (GPU / replicated
campaigns), per `~/shinichi-brain/projects/COMPUTE-PLAYBOOK.md`, and only when
Shinichi asks.

**Do NOT stage these** (they belong to other tools' sessions or are generated):

```
.claude/preview/index.html      .claude/preview/status.json
.claude/preview/sweep.json      .claude/preview/version.txt
.claude/agents/*.md             .cursor/agents/*.md
.codex/agents/*.toml            .codex/agents/tiers.tsv
.worktrees/**                   .claude/worktrees/**
.git/index.lock
```

Stage by explicit path. `git add -A` and `git add .` are forbidden.

**Merging:** `gh pr merge N --merge` after full Julia + Documenter SUCCESS.
Never `--auto`. Never push without an explicit instruction from Shinichi — except
the handover branch itself, which must be pushed so the next session can read it.

---

## Files Created / Modified — this handover

`git diff --name-only origin/main...cursor/handover-20260817`:

| Path | Change |
|---|---|
| `docs/dev-log/handover/2026-08-17-cursor-handover.md` | **new** — this file |
| `docs/dev-log/coordination-board.md` | Active-Lane-Split row + `START HERE (Cursor)` pointer + dated Status entry |

No `src/`, `test/`, `AGENTS.md`, or `CLAUDE.md` path is touched. The two engine
PRs of the era (#236, #238) and the six admits (#241–#246) are already on `main`
with their own after-task reports under `docs/dev-log/after-task/`.

---

## Mission control

| Repo | Branch / tip | CI | What shipped | Plan by leverage |
|---|---|---|---|---|
| **GLLVM.jl** | `main` @ `1dafee68` (+ this handover) | green on tip; #247 two jobs pending at write | #234 Tweedie STOP + #236/#238 health · #235 ZIP bridge fix · #241–#246 four no-X surface admits + two Identities · #248 AGHQ Identity | **1.** close #247 · **2.** AGHQ Stage-1a grid + `k=1` golden (arc-creation first) · **3.** near-parity leftovers: `none × dep()`, CV, coverage on Totoro/DRAC |
| `gllvmTMB` (R twin) | read-only reference @ `e3e813f4`, v0.6.0 | — | AGHQ + CV shipped there; `.valid_family` ids 0–16 | never engine-surgery from this repo; never invent a Δ |

Ledger at `1dafee68`: **58 implemented · 3 partial · 13 planned · 4 missing.**

---

## How to Resume

Read in this order:

1. `AGENTS.md` (repo rules, Definition of Done, hard boundaries)
2. **this file**
3. `docs/dev-log/coordination-board.md` → **Active Lane Split** (the multi-lane
   pointer; never a single `START HERE` bullet)
4. `docs/design/capability-status.md` (the ledger) and
   `docs/dev-log/plans/2026-08-16-gllvmtmb-capability-gap.md` (the twin gap sheet)
5. `docs/dev-log/decisions/2026-08-17-aghq-identity.md` (#248 — the next arc's
   binding constraints) and `docs/dev-log/decisions/2026-08-16-tweedie-fit-gllvm-identity.md`
   (#234 — the STOP you must not break)
6. `docs/dev-log/handover/2026-08-17-overnight-surface-handoff.md` (the sibling
   lane's overnight record, carried forward here)

Then reconcile with live state:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main && git log -5 --oneline origin/main
gh pr list --state open
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
```

Then execute **OWED only**.

### One-command resume — paste this into a fresh Cursor agent in this repo

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-17-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

### Which tool does what next

- **Cursor** (you): the AGHQ Stage-1a grid + `k = 1` golden test is a bounded
  multi-file Julia slice with a focused local test — a good Cursor arc. So is the
  #247 close.
- **Codex** owns anything needing the live R twin side-by-side (a real
  `gllvmTMB` fit, `R CMD check`, an RCall parity cell) — Codex runs that
  toolchain natively.
- **Claude** owns prose, ledger-honesty Rose passes, and Identity drafting where
  no compiler is required.
- **Totoro / DRAC** own the coverage certificate and any replicated ADEMP grid.
  Never laptop-scale, and only when Shinichi sizes and asks.
