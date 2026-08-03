# NB2/Beta+X Arc 2 — light RCall parity cells — Ultra Plan

> **Status at authoring time (2026-08-02 ~12:15 MDT):** [#175](https://github.com/itchyshin/GLLVM.jl/pull/175)
> (Arc 1 engine) is **OPEN, not merged** — `mergeable=MERGEABLE`, Documenter
> **SUCCESS**, Julia 1.10/1-ubuntu/macOS/windows **IN_PROGRESS**. This plan is
> **written for execution immediately after #175 merges to `main`**. Do not
> start Arc 2 execution against the Arc 1 branch/worktree — cut a fresh
> worktree from post-merge `origin/main` (see GOAL block).
>
> This planning chat stayed **read-only through Ultra Plan Phase 2**: no
> `src/` edits, no test edits, no PR, no merge of #175, no Arc 2 execution.

```text
🎯 GOAL
PLATFORM = Cursor (a fresh session picks this up after #175 merges — do not run
Arc 2 in this planning chat; hand off via /goal below).
DELIVERABLE = NB2+X and Beta+X light gllvmTMB logLik parity cells green at
rtol 1e-6 in test/parity/test_x_covariate_parity.jl, using the Arc 1
fit_nb_gllvm_grouped_cov / fit_beta_gllvm_grouped_cov fitters (group=1:p,
default hessian=:observed — no engine changes expected).
HEADLINE = Close the twin gap Arc 0/Arc 1 opened: shared site-X parity cells
now exist for Gaussian/Binomial/Poisson (#170) and per-trait+X now fits in
Julia (#175) — Arc 2 is the last step that proves the two agree against the
live gllvmTMB oracle.
IN PARALLEL = confirm #175 merged + fresh worktree · refresh/reuse R twin lib
at /tmp/R-gllvmtmb-x-parity-20260802 · extend parity_helpers.jl family switch.
DEFER = Gamma+X; Ordinal+X; species-specific XB; X_lv; ADEMP/coverage;
Phylo Model A; shared-φ-vs-per-trait-R comparisons; "full family parity"
claims; any Dropbox-checkout writes; git add -A; push without instruction.
DISCIPLINE = rtol 1e-6 fixed (no silent widen) · verify by reading the printed
Δ logLik, not exit codes · light cells run on laptop/Totoro (no DRAC/large
grid) · stage by explicit path · after-task + check-log + board + Rose fence
required before calling this closed.
```

**ARC PROGRAM:** Arc Creation mode = **size**. Recommended arc = **2–3 hours**
(one multi-file implementation with a repair loop and checkpoint), confidence
**inferred** (direct analogue: cohort-1 X parity after-task
`docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md` — same shape,
3 cells, new infra from scratch, no exact timing recorded; Arc 2 is lighter —
2 cells, infra + R twin lib already exist, no engine changes expected). No
fixed-capacity request from Shinichi; size mode chosen per mission instruction.

---

## Phase 0.25 — Prior-work sweep receipt (evidence-cited; gate for Phase 1)

| Surface | Evidence (command / query run) | Finding | Call |
|---|---|---|---|
| **repo git state** | `git fetch origin`; `git status -sb` (worktree `dd1d66b6` on `fix/nb2-beta-x-grouped-cov-20260802`, clean vs its own remote tip); `git worktree list` (12 GLLVM.jl worktrees incl. this Arc 1 lane, an Arc 0 identity worktree `gllvmjl-nb2-beta-x-identity-20260802` detached at `b0672446`, the x-covariate-light-loglik lane, and many `.claude/worktrees/agent-*` locked lanes unrelated to this task); `gh pr view 175 --json state,mergeable,statusCheckRollup` → `state=OPEN, mergeable=MERGEABLE, Documenter=SUCCESS, Julia 1.10/1-ubuntu/macOS/windows=IN_PROGRESS` | Arc 1 engine (`fit_nb_gllvm_grouped_cov`/`fit_beta_gllvm_grouped_cov`, default `group=1:p`, default `hessian=:observed`, bridge+formula routed) is implemented and tested (14/14 identity, 201/201 bridge, 11/11 formula) but **not yet on `main`** | **resume-after-merge**: this plan is the correct next arc, but its first executable step is "confirm #175 merged", not code edits today |
| **twin / sister repos** | Checked `gllvmTMB` local checkouts under `~/Dropbox/Github Local/gllvmTMB` (read-only reference, not touched) and the parity R-lib cache: `ls /tmp` shows `R-gllvmtmb-x-parity-20260802/gllvmTMB` (installed 2026-08-02 06:24, from the cohort-1 X lane) plus `gllvmTMB-910ebd54.tar.gz` and several other `/tmp/gllvmtmb-*` scratch checkouts from sibling lanes (docfix, r3-profile, logit-arm — unrelated, not reused) | A working gllvmTMB install for the shared-X formula (`value ~ 0 + trait + x + latent(...)`) already exists at the exact path `parity_helpers.jl` defaults to (`GLLVM_PARITY_R_LIBS` default). No fresh R build is structurally required, only a freshness check at execution time | **reuse** the existing twin lib; re-verify its SHA/date at execution start rather than reinstalling by default |
| **twin / sister — R formula shape for NB2/Beta dispersion** | Read `test/parity/parity_helpers.jl` `fit_gllvmtmb_parity_loglik` (no-X): R family objects `gllvmTMB::nbinom2()` / `gllvmTMB::Beta()` already default to **per-trait** dispersion (`log_phi_nbinom2[p]`, per docstring and #132/#148 lessons) — the same per-trait behaviour Arc 1 implements in Julia with `group=1:p` | The no-X helper's family switch is the exact pattern to extend for `fit_gllvmtmb_parity_loglik_x` (shared-X + per-trait dispersion); no new R-side dispersion machinery needed | **reuse** the no-X family-switch pattern; extend it into the X helper |
| **brain** (`search_all_projects: true`) | `search_notes("NB2 Beta X grouped dispersion Arc 2 RCall parity gllvmTMB", search_all_projects=true)` and `search_notes("Arc 2 light RCall parity NB2 Beta per-trait dispersion twin identity", search_all_projects=true)` | No decision beyond what already lives in-repo (`docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md`, the Arc-1 LOOP kit, the two after-task reports); no conflicting prior lock, no evidence Arc 2 was already attempted or abandoned elsewhere | **none found beyond repo docs** — repo is the load-bearing source here, not the vault |
| **Verdict** | — | Genuinely new work = (a) extend `parity_helpers.jl`'s shared-X R helper to accept `:negbinomial`/`:beta`, (b) two new `@testset` cells in `test_x_covariate_parity.jl` calling `fit_nb_gllvm_grouped_cov`/`fit_beta_gllvm_grouped_cov` with `group=collect(1:p)` (default hessian, matching the bridge default — **not** `hessian=:fisher`, which was only for the Arc-1 *identity* tests vs shared `fit_gllvm_cov`), (c) one live oracle run + evidence capture, (d) close-out docs. No engine (`src/`) changes are expected. | **build-the-gap** (small; infra and engine already exist) |

**Gate cleared:** receipt is non-vacuous (each row cites the command/query run); Phase 1 decomposition below is licensed.

---

## Phase 0.3 / 0.3b — model roster + Cursor two-bar note

This is a Cursor-authored plan for a small, mostly single-agent execution arc — not a
large multi-agent fan-out. Two-bar glance: judgment/synthesis work (this planning
chat) belongs on **Other Models**; the execution `/goal` below is a bounded
Cursor Agent slice, appropriate for **Cursor Models**, with the live-R verification
step flagged for a careful read rather than blind trust in exit codes.

---

## Phase 1 — Decomposition (slices)

| # | Slice | Input | Output | Dependency |
|---|---|---|---|---|
| S0 | Confirm #175 merged; fresh worktree from post-merge `origin/main` | `gh pr view 175`; `git fetch origin` | New worktree `.worktrees/gllvmjl-nb2-beta-x-arc2-20260802` on branch `parity/nb2-beta-x-arc2-20260802` | none (blocks S1+) |
| S1 | Verify/refresh R twin lib | `/tmp/R-gllvmtmb-x-parity-20260802` | Confirmed fresh gllvmTMB install (SHA recorded) or refreshed one | S0 |
| S2 | Extend `parity_helpers.jl` shared-X R helper for NB2/Beta | `fit_gllvmtmb_parity_loglik_x` (G/Bin/Pois only) | Same function accepting `:negbinomial`/`:beta`, per-trait dispersion, shared `+x` slope | S0 |
| S3 | Add NB2+X and Beta+X cells to `test_x_covariate_parity.jl` | S2 + Arc 1's `fit_nb_gllvm_grouped_cov`/`fit_beta_gllvm_grouped_cov` | 2 new `@testset` blocks, `group=collect(1:p)`, default `hessian=:observed`, rtol 1e-6 | S1, S2 |
| S4 | Live run + evidence capture | `GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl` | Log with Δ logLik per cell (pattern: `docs/dev-log/x-covariate-parity-full-20260802.log`) | S3 |
| S5 | Repair loop (only if a cell fails / R warns) | S4 log | DGP fix (mirror Binomial seed/loading lesson) or diagnosis, re-run | S4 (conditional) |
| S6 | Docs close-out | S4/S5 evidence | Updated `test/parity/README.md` fence, `docs/design/capability-status.md`, `docs/dev-log/check-log.md`, coordination board, after-task at `docs/dev-log/after-task/2026-08-0X-nb2-beta-x-arc2-parity.md` | S4 |
| S7 | Rose verdict + Melissa reconcile | S6 | Explicit OK/blockers; `docs/dev-log/plan-actual/<date>-nb2-beta-x-arc2.md` | S6 |

**Parallelizable:** S1 can run alongside S2 (independent). **Sequential:** S0→{S1,S2}→S3→S4→(S5)→S6→S7.

---

## Phase 2 — Slice table (member · model · Bar · time · dep)

| Slice | Member | Model / effort | Bar | Dispatch | Time | Dep |
|---|---|---|---|---|---|---|
| S0 | Ada | Cursor default agent, low effort | Cursor Models | native/explicit | 10 min | none |
| S1 | Gauss | Cursor default agent, low effort | Cursor Models | native/explicit | 10 min | S0 |
| S2 | Hopper | Cursor default agent, medium effort | Cursor Models | native/explicit | 30 min | S0 |
| S3 | Curie | Cursor default agent, medium effort | Cursor Models | native/explicit | 30 min | S1, S2 |
| S4 | Gauss | Cursor default agent, medium effort (live R run — read the log, don't trust exit code) | Cursor Models | native/explicit | 20 min | S3 |
| S5 | Curie | Cursor default agent, medium effort | Cursor Models | native/explicit | 0–30 min (conditional) | S4 |
| S6 | Rose | Other Models (Claude/GPT judgment) | Other Models | hand off | 20 min | S4/S5 |
| S7 | Melissa | Other Models, low-medium effort | Other Models | hand off | 10 min | S6 |

No Luna/Haiku-suitable slice here: every step touches live RCall output or a
family-specific likelihood formula and needs build-tier judgment, not
mechanical scanning. **LUNA SUITABILITY: no — every slice reads/interprets a
live statistical fit or edits a likelihood-comparison test; none is bounded
mechanical scanning.**

**Fan-out budget:** 0 new sub-agent children required beyond the single `/goal`
executor picking this plan up (S0–S5 are one continuous Cursor agent thread;
S6/S7 are the standard closer/reconciler hand-off, not new child agents in the
ultra-plan sense).

**Estimate:** ~2–2.5 hours wall-clock, one Cursor session (no multi-agent fan-out
needed), fits in one `/goal` run. If #175's Julia CI is still red when Arc 2
starts, S0 blocks and the arc returns to a short diagnosis note rather than
proceeding.

---

## DEFER fence (explicit)

- **No** Gamma+X default flip.
- **No** Ordinal+X, species-specific XB, `X_lv`.
- **No** ADEMP / coverage certificates.
- **No** Phylo Model A.
- **No** shared-φ-Julia-vs-per-trait-R comparisons (wrong estimand — Arc 0 decision).
- **No** claim of "full family parity" — only "NB2/Beta + shared site-X light
  logLik under per-trait φ, twin to gllvmTMB `disp.group`" (per the Arc 0 decision's
  Rose fence).
- **No** Dropbox protected-checkout writes (`~/Dropbox/Github Local/GLLVM.jl` on
  `claude/jl-bridge-capabilities-20260619`).
- **No** `git add -A` / `git add .` — stage by explicit path only.
- **No** push without instruction; PR open is fine, merge needs maintainer sign-off
  per the repo's self-merge rule (test/identity-only changes may self-merge per
  AGENTS.md, but confirm before merging a parity-claim PR).
- **No** merging #175 from this or the executing session — treat its merge as
  external evidence to poll, not an action to take.

**Totoro or DRAC?** Not needed. This is 2 light logLik cells (p=5, n≈30–80,
K=2) — laptop/Totoro-class compute is fine, matching the cohort-1 precedent.
Ask again only if the plan later grows into a broad grid.

---

## Members plan-review (before execution)

**Rose** — Scope check: the plan correctly refuses to start before #175 merges,
correctly restates the Arc 0 estimand fence (per-trait Julia vs per-trait R,
not shared-vs-per-trait), and correctly keeps the claim narrow ("light logLik",
not "parity"). One risk: if #175's CI finishes red, this plan must not silently
proceed on the still-open branch — S0 must hard-block. **Verdict: plan is
soundly fenced; proceed after #175 merge confirmation.**

**Hopper** — R↔Julia translation check: the R-side change (S2) is genuinely
small — `gllvmTMB::nbinom2()` / `gllvmTMB::Beta()` already default to per-trait
dispersion, so the shared-X formula only needs the family switch widened, not a
new formula shape. The Julia call must use `group=collect(1:p)` (per-trait, the
bridge default) and **default `hessian` (`:observed`)**, not `:fisher` — Arc 1's
`:fisher` forcing was only for the shared-`fit_gllvm_cov` identity comparison,
which is a different estimand than the R oracle comparison here. **Verdict:
technically sound; flag the hessian choice explicitly in the S3 brief so it
isn't copy-pasted from the identity test by mistake.**

**Fisher** (statistical inference, consulted for the rtol/DGP judgment) —
The cohort-1 Binomial cell needed a DGP repair once (Heywood/runaway-loading
warning at seed 421/n=30 → fixed with seed 431/n=80, milder loadings). NB2 and
Beta likelihoods have their own instability modes (NB2: near-zero counts +
strong loadings; Beta: μ near 0/1 boundary). Budget the S5 repair slot for
real, and do not widen rtol from 1e-6 if a cell is merely slow to converge —
fix `n_init`/starting values instead. **Verdict: keep the repair reserve; do
not treat it as optional.**

---

## LANE RECEIPT

`LANE: START A FRESH TASK` — this planning chat stops at Phase 2 (G0). The
next action is a **new** Cursor session/worktree, cut only after #175 shows
`MERGED` on `main`. Do not continue Arc 2 implementation in this chat.

---

## Paste-ready `/goal` prompt for post-merge execution (fresh Cursor session)

```text
/goal

You are Cursor executing NB2/Beta+X Arc 2 (light RCall parity cells) for GLLVM.jl.

REHYDRATE FIRST:
1. Read docs/dev-log/coordination-board.md and confirm PR #175 shows MERGED
   (gh pr view 175 --json state,mergedAt). If not merged, STOP and report —
   do not proceed on the open branch.
2. Read docs/dev-log/plans/2026-08-02-nb2-beta-x-arc2-ultra-plan.md (this
   plan) in full before editing anything.
3. Read docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md
   for the twin-identity fence (per-trait Julia vs per-trait R only).

SETUP:
4. Fetch origin; cut a fresh worktree from post-merge origin/main:
   git worktree add "../gllvmjl-nb2-beta-x-arc2-20260802" -b \
     parity/nb2-beta-x-arc2-20260802 origin/main
5. Verify the R twin lib at /tmp/R-gllvmtmb-x-parity-20260802/gllvmTMB is
   present and usable (or reinstall gllvmTMB @ fresh origin/main gllvmTMB SHA
   if stale/missing) — record the SHA used.

IMPLEMENT (slices S2-S4 from the ultra-plan):
6. Extend test/parity/parity_helpers.jl's fit_gllvmtmb_parity_loglik_x to
   accept family ∈ (:gaussian, :binomial, :poisson, :negbinomial, :beta),
   using gllvmTMB::nbinom2() / gllvmTMB::Beta() (per-trait dispersion by R
   default — same family-switch pattern as the no-X fit_gllvmtmb_parity_loglik).
7. Add two new @testset cells to test/parity/test_x_covariate_parity.jl:
   "NB2 + shared X (q=1)" and "Beta + shared X (q=1)", mirroring the existing
   Gaussian/Binomial/Poisson cells. Julia side calls
   fit_nb_gllvm_grouped_cov(Y; X=X, K=K, group=collect(1:p)) /
   fit_beta_gllvm_grouped_cov(Y; X=X, K=K, group=collect(1:p)) — DEFAULT
   hessian (:observed), NOT hessian=:fisher (that was only for the Arc 1
   identity tests vs shared fit_gllvm_cov, a different estimand).
   rtol = 1e-6 fixed, no silent widen. If a DGP produces an R warning
   (runaway loading / Heywood case, cf. the Binomial lesson in
   docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md), repair
   the seed/loadings/n, not the tolerance.

VERIFY:
8. Run: GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl
   Read the printed Δ logLik per cell — do not trust exit code alone. Both
   new cells must show Pass at rtol 1e-6.
9. Run the full non-R suite too: julia --project=. -e 'using Pkg; Pkg.test()'
   to confirm no regression.

CLOSE:
10. Update test/parity/README.md fence (NB2+X/Beta+X now green; still not
    full family parity), docs/design/capability-status.md, check-log.md,
    coordination-board.md.
11. Write after-task at
    docs/dev-log/after-task/2026-08-0X-nb2-beta-x-arc2-parity.md (Rose
    verdict format, cite the Δ logLik numbers).
12. Melissa-style plan-vs-actual note at
    docs/dev-log/plan-actual/2026-08-0X-nb2-beta-x-arc2.md.
13. Stage by explicit path (never git add -A). Commit locally. Do NOT push
    or open a PR without asking the maintainer first.

FENCES (do not cross):
- No Gamma+X, no Ordinal+X, no X_lv, no ADEMP/coverage, no Phylo Model A.
- No shared-φ-Julia-vs-per-trait-R comparison.
- No claim of "full family parity."
- No writes to ~/Dropbox/Github Local/GLLVM.jl (protected stale checkout).
- No git add -A. No push without instruction.

If #175 is not yet merged when you start, stop after step 1 and report status
only — do not create the worktree or touch test files.
```

---

## RECONCILE

`RECONCILE: Melissa (Sonnet/Terra, effort low)` — deferred to the executing
session's close-out (S7 above); not run in this planning-only chat since no
execution happened here to reconcile against.

## VERIFY (this planning chat)

- Sweep receipt evidence is cited (commands/queries run) — see Phase 0.25 table.
- No `src/`, `test/`, or docs edits made in this chat; only this plan file was
  written. `git status` in the worktree should show exactly one new file
  (`docs/dev-log/plans/2026-08-02-nb2-beta-x-arc2-ultra-plan.md`) beyond the
  pre-existing modified files already listed in the session's starting
  `git_status`.
