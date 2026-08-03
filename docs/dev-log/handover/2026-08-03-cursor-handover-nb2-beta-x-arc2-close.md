# Session Handoff: NB2/Beta+X Arc 2 close-out → Gamma+X Arc 0 (Cursor)

Meta: 2026-08-03 ~06:24 MDT · from Cursor (Ada) · target Cursor · AUTHOR=cursor · context N/A

You are Cursor, picking up GLLVM.jl after the **NB2/Beta+X Arc 1–2 marathon**
(#172–#177). You inherit **no chat context**. Read files, then classify every
item below `OWED` · `DONE` · `RETRACTED` · `PROTECTED` and execute **only
OWED**.

Sibling handovers / lanes (do not orphan — read the board, not just this doc):

- Multi-lane board: `docs/dev-log/coordination-board.md` (**rehydrate
  pointer**, Active-Lane-Split)
- Arc 1 engine (MERGED #175): `docs/dev-log/handover/2026-08-02-cursor-handover-nb2-beta-x-arc1.md`
- Arc 2 light RCall parity (PR #177 open, CI in progress at write time): `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md`
- Windows row-effect NA-budget hardening (PR #176 open, CI green): `docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md`
- Grouped one-group bug (MERGED #172): `docs/dev-log/after-task/2026-08-02-grouped-dispersion-one-group.md`
- MC Julia capability-status (MERGED #173): `docs/design/capability-status.md`
- Design Arc 0 (MERGED #174): `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md`
- X light logLik cohort 1 (MERGED #170): `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md`
- Default-route φ (MERGED #169): `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md`
- Phylo Model A deferred: `docs/dev-log/handover/2026-06-30-codex-handover.md`
- Dropbox stale checkout: **PROTECTED** (see Landing State)

## Mission-control summary

| Repo | Branch / tip | CI | Shipped | Next (leverage) |
|---|---|---|---|---|
| GLLVM.jl | `main` @ `9f5133a7` (#175) | green | Gate 0 (#172–#174) + Arc 1 engine (per-trait φ + shared site-X) | Land #177 when green; new arc = Gamma+X identity decision doc |
| GLLVM.jl | `parity/nb2-beta-x-arc2-20260802` (PR #177) | Documenter green, Julia CI in progress at write time | Arc 2: NB2+X/Beta+X light logLik, 34/34, full `Pkg.test` 5096/1/0 | Merge when Julia CI green (self-merge OK — test/docs only) |
| GLLVM.jl | `fix/windows-roweffect-na-budget-20260802` (PR #176) | **all green** (Documenter + 4× Julia CI) | Windows NA-iteration-budget flake hardening | Optional merge — not blocking, no content risk |

## Critical Context

1. **Wrong tree hazard:** Dropbox checkout
   `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` on
   `claude/jl-bridge-capabilities-20260619` is **PROTECTED / stale** — never
   write there (31 uncommitted files, 3 unpushed commits on HEAD, a stale
   `index.lock`; none of it belongs to this arc). Work only from a worktree
   off `origin/main`.
2. **Twin rule:** GLLVM.jl mirrors gllvmTMB on **API/capabilities**, not
   engine code. Bridge execution is **R→Julia only** (JuliaCall); RCall =
   opt-in oracle, gated by `GLLVM_PARITY_TESTS=1`.
3. **Arc 1 + Arc 2 both shipped:** public/bridge NB2/Beta+X routes to
   per-trait `fit_*_gllvm_grouped_cov` (Arc 1, on `main`); NB2+X/Beta+X now
   also have light gllvmTMB logLik oracle cells (Arc 2, PR #177, not yet on
   `main` — CI still running at handover time). **Do not claim "full family
   parity"** — the claim is narrowly "shared site-X light logLik under
   per-trait φ, twin to gllvmTMB `disp.group`."
4. **Rose fence (Arc 1+2):** ≠ full family parity; ≠ Gamma+X; ≠ Ordinal+X;
   ≠ species-specific XB; ≠ `X_lv`; ≠ shared-φ-Julia-vs-per-trait-R
   comparison; ≠ ADEMP/coverage; ≠ Phylo Model A.
5. **Two open PRs, unrelated content:** #177 (Arc 2 test+docs) and #176
   (Windows test-budget fix) touch disjoint files and can merge in either
   order or independently. Do not conflate their review.

## Goals / Mission

- Package: Julia twin of R `gllvmTMB` — honest parity, speed, no claim
  inflation.
- This arc (now closing): Gate 0 (#172–#174) → Arc 1 engine (#175) → Arc 2
  light RCall parity (#177) → Windows hardening (#176).
- Beyond: keep extending the light-logLik oracle cohort family-by-family
  (Gamma+X next, per Ada's recommendation below), each gated by its own
  identity-decision doc before engine/test work, per the Arc 0 pattern.

## Plans / Roadmap (beyond immediate next)

- **Ada's recommendation for the next arc: Gamma+X dispersion identity
  decision doc** (~1–2h), mirroring
  `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md` —
  decide per-trait-φ-vs-shared-φ-under-X for Gamma *before* any engine or
  parity-test work, the same Arc-0-first discipline that made NB2/Beta+X
  land clean. **START A FRESH TASK** for this (new chat, new worktree) — do
  not continue it in a resumed Arc-2-close session.
- After the Gamma+X identity doc lands, the natural follow-on arcs (each its
  own decision-doc-first cycle) are Ordinal+X, then the shared-φ-vs-per-trait
  comparison question that Arc 0 explicitly deferred.
- Fence #129/#128, ADEMP, coverage, Totoro/DRAC, X_lv unless a dedicated lane
  owns them.
- Phylo Model A redesign remains parked (sibling menu) — PR #127
  closed/parked, see `docs/dev-log/handover/2026-06-30-codex-handover.md`.

## What Was Accomplished (this marathon, #172→#177)

| Item | Result |
|---|---|
| Gate 0: #172 one-group Fisher identity | **MERGED** → `main` |
| Gate 0: #173 capability-status | **MERGED** → `main` |
| Gate 0: #174 NB2/Beta+X identity design (Arc 0) | **MERGED** → `main` |
| Arc 1 engine: `fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov` + bridge/formula routing | **MERGED** #175 → `main` @ `9f5133a7` |
| Arc 2: NB2+X/Beta+X light gllvmTMB logLik oracle cells (34/34 shared site-X cohort) | **PR #177 OPEN**, Documenter green, Julia CI in progress |
| Windows NA-iteration-budget hardening for row-effect NA/mask cells | **PR #176 OPEN**, all CI green (Documenter + macOS/ubuntu/windows/1.10) |

Detail: `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md`,
`docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md`,
`docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md`.

## Current Working State

- Working: `main` @ `9f5133a7` (Arc 1 merged); #176 fully green and
  mergeable; #177 Documenter green, 4× Julia CI matrix `IN_PROGRESS` at
  handover time (started ~11:41 UTC 2026-08-03).
- In progress: watch #177 Julia CI → merge when green (self-merge OK per
  AGENTS.md — test + docs only, no engine change, no tolerance widened).
- Not working / deferred: Gamma+X (no identity decision yet — this is the
  recommended next arc, not a blocker); Ordinal+X; `X_lv`; ADEMP/coverage.

## Key Decisions & Rationale

- Public/bridge default under X for NB2/Beta = **per-trait φ + shared site-X
  γ** (API B under X). Decision note on `main` via #174.
- Arc 2 parity cells use `group=collect(1:p)` (per-trait, bridge default) and
  **default `hessian=:observed`**, NOT `:fisher` — `:fisher` forcing was only
  for the Arc 1 identity tests vs the shared `fit_gllvm_cov` path, a
  different estimand than the R-oracle comparison Arc 2 makes.
- Arc 2 DGP repair: both NB2+X and Beta+X first-draw DGPs hit genuine
  Heywood-like per-trait boundary failures (not numerical noise). Repaired
  by adjusting seed/`n`/loading magnitude — **rtol stayed fixed at `1e-6`**,
  per the no-silent-tolerance-widening rule.
- #176 is test-only (restores the fitter-default `iterations=500` cap that
  #175's Windows runner needs for the Poisson row-effect NA/mask cells) —
  no likelihood/parameterisation change, so it is a straightforward
  self-mergeable hardening PR, independent of #177.

## Landing State

Gate (`~/shinichi-brain/tools/handoff_gate.sh`, since this repo has no
in-repo copy) run against every worktree touched by this marathon. **FAIL**
on pre-existing noise (below); the two branches this handover actually cares
about are both clean vs their own remote tips.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `parity/nb2-beta-x-arc2-20260802` (+ this handover + board update) | y | y (pushed with this commit) | [#177](https://github.com/itchyshin/GLLVM.jl/pull/177) open | **LANDED** on feature branch; await Julia CI → merge |
| `fix/windows-roweffect-na-budget-20260802` | y | y | [#176](https://github.com/itchyshin/GLLVM.jl/pull/176) open | **LANDED**; all CI green; optional merge, no rush |
| `main` @ `9f5133a7` (#172/#173/#174/#175) | y | y | merged | **LANDED** |
| `.worktrees/gllvmjl-nb2-beta-x-grouped-cov-20260802` — stray duplicate `docs/dev-log/plans/2026-08-02-nb2-beta-x-arc2-ultra-plan.md` (byte-identical to the version already committed on `parity/nb2-beta-x-arc2-20260802` @ `9f5844ee`) | n/a | n/a | none | **RESOLVED this session** — deleted as pure duplicate cruft, nothing lost |
| `.worktrees/gllvmjl-nb2-beta-x-identity-20260802` (detached HEAD @ `b0672446`) — modified `lanes/nb2-beta-x-api-b-x-20260802/LOOP/checkpoint.md` | n | n/a | none (lane's PR #174 already merged) | **CARRIED-OVER** — stale local-only LOOP status note from the already-closed Arc 0 identity lane; superseded by the merged #174 and this handover. Resume: safe to discard (`git checkout -- <path>`) or ignore; not required reading. |
| `.worktrees/gllvmjl-catchup-loglik-20260801` — modified `lanes/default-route-phi-landing-20260801/LOOP/checkpoint.md` + untracked `docs/dev-log/plans/scratch/2026-08-01-worktree-attach.md` | n | n/a | none (lane's PR #169 already merged) | **CARRIED-OVER** — stale local-only LOOP scratch from the already-closed default-route-φ lane. Resume: safe to discard; not required reading. |
| Dropbox `claude/jl-bridge-capabilities-20260619` (31 uncommitted, 3 unpushed on HEAD + 26 unpushed on other local branches, stale `index.lock`) | n | n | none | **PROTECTED / CARRIED-OVER** — never write; leave alone. Pre-existing drift from long before this marathon. Report the stale `index.lock` to Shinichi; do **not** `rm` it (harness blocks `.git` deletions). |
| ~15 other long-stale local-only feature branches in this repo's `.git` (`fam-zip`, `two-part-spec`, `viz-plots2`, `codex/p2-r-bridge`, etc. — visible to `handoff_gate.sh` as "N unpushed on other branches" because all worktrees share one object store) | n/a | n | none | **PRE-EXISTING, OUT OF SCOPE** — not touched by this marathon; do not attempt to land or triage as part of this handover. |

For every `CARRIED-OVER` row above: the resume command is "ignore it" — none
of it gates the Next Immediate Steps below.

## Files Created / Modified (Arc 2 vs `origin/main` @ `9f5133a7`)

```
docs/design/capability-status.md
docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md
docs/dev-log/check-log.md
docs/dev-log/coordination-board.md
docs/dev-log/plan-actual/2026-08-02-nb2-beta-x-arc2.md
docs/dev-log/plans/2026-08-02-nb2-beta-x-arc2-ultra-plan.md
lanes/nb2-beta-x-arc2-20260802/LOOP/GOAL.md
lanes/nb2-beta-x-arc2-20260802/LOOP/arcs.md
lanes/nb2-beta-x-arc2-20260802/LOOP/checkpoint.md
lanes/nb2-beta-x-arc2-20260802/LOOP/ultra-plan.md
test/parity/README.md
test/parity/parity_helpers.jl
test/parity/test_x_covariate_parity.jl
docs/dev-log/handover/2026-08-03-cursor-handover-nb2-beta-x-arc2-close.md  (this file)
AGENTS.md  (phase snapshot pointer)
```

Windows-hardening PR #176 (separate branch, disjoint files):

```
docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md
docs/dev-log/check-log.md
docs/dev-log/coordination-board.md
test/test_missing_response_extra.jl
```

## Next Immediate Steps (OWED only after classify)

1. **Rehydrate:** read `AGENTS.md`, this doc, `docs/dev-log/coordination-board.md`;
   `git fetch origin`; confirm current tip of `main` and CI state of #176/#177
   (`gh pr view 176 177 --json state,mergeable,statusCheckRollup`).
2. **Land #177 when Julia CI is green** (self-merge OK — test + docs only,
   no engine change, no tolerance widened; do not force-merge if red —
   diagnose first). Optionally also merge #176 (already fully green;
   independent, no rush).
3. **Then STOP — start a fresh chat + fresh worktree** for the Gamma+X
   dispersion identity decision doc (Ada's recommendation, ~1–2h), mirroring
   `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md`.
   Do **not** begin Gamma+X engine or parity-test work before that decision
   doc lands — that was the exact discipline that made NB2/Beta+X land clean
   across #172–#177.
4. **Never** write the Dropbox PROTECTED checkout; never `git add -A`.

## Blockers / Open Questions

- #177 Julia CI (macOS/ubuntu/windows/1.10-ubuntu) was still `IN_PROGRESS` at
  handover-write time — wait, don't force-merge red.
- No open question blocks the Gamma+X identity-doc arc; it can start as soon
  as a fresh session is available.

## Gotchas & Failed Approaches

- Comparing the grouped default (`hessian=:observed`) to shared Fisher is a
  different Laplace objective (#172 lesson) — Arc 1 identity cells force
  `:fisher`; Arc 2 R-oracle cells must use the **default** `hessian`
  (`:observed`) instead — do not copy-paste the identity test's hessian
  choice into a parity cell.
- Bridge tests must oracle against `fit_*_grouped_cov` for NB/Beta, not
  `fit_gllvm_cov`, after the Arc 1 route flip.
- Documenter deploy can flake on the `gh-pages` push race; re-run the
  Documenter job before treating it as a content failure (#172 lesson).
- A first-draw DGP that "converges" can still be wrong: Arc 2 hit two
  genuine Heywood-like per-trait boundary failures that needed a DGP
  repair, not a looser tolerance — read the printed Δ logLik, not just the
  exit code / `converged` flag.

## How to Resume (Cursor live env)

Preferred working directory after both PRs merge — cut a **fresh** worktree
from post-merge `origin/main` for the Gamma+X identity-doc arc (do not reuse
this Arc 2 worktree; it is closed):

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin
git worktree add ".worktrees/gllvmjl-gamma-x-identity-<date>" -b \
  docs/gamma-x-identity-<date> origin/main
```

While #176/#177 are still open, this Arc 2 worktree remains valid for
watching/merging them:

```text
/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-nb2-beta-x-arc2-20260802
```

Toolchain:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"   # julia was already on PATH in this session, but don't assume it
julia --project=. -e 'using Pkg; Pkg.instantiate()'
# focused smoke (Arc 2 parity, opt-in RCall oracle — needs local R + gllvmTMB)
GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl
# full CI-equivalent
julia --project=. -e 'using Pkg; Pkg.test()'
```

Do not stage: the Dropbox protected checkout's dirt, `.claude/preview/*`
churn, or the stale LOOP-checkpoint noise in the already-closed identity /
catchup worktrees (see Landing State — CARRIED-OVER rows). Stage by explicit
path only, never `git add -A`.

Classify then act only on OWED:

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-03-cursor-handover-nb2-beta-x-arc2-close.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
