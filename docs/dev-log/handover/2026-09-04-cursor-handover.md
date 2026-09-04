# Handover → Cursor, 2026-09-04 — GLLVM.jl + gllvmTMB as ONE lane

You are **Cursor**, picking up **both** packages in a single orchestrator chat with a
multi-root workspace. You inherit no chat context. This file, `AGENTS.md`, and the current
git state are authoritative — in that order of reading, but the repo always wins on facts.

Authored by Claude Code (session `GLLVM.jl3`) after closing the Core 0.7.0 + AGHQ parity
programme. Its twin lane (`gllvmTMB1`, Claude) closed the reverse-parity gap programme the
same day and wrote its own handover; read both.

---

## 0. Mission

Take **gllvmTMB (R)** and **GLLVM.jl (Julia)** forward *together*, one plan and one LOOP,
instead of two lanes relaying decisions to each other. R owns public language, API and
docs; Julia owns engine truth.

The pattern is the **H² twin** arrangement Shinichi chose on 2026-09-02 — one orchestrator
chat, multi-root workspace, coordination through `LOOP/checkpoint.md` + a shared contract
file + brain search, explicitly *not* two peer lanes messaging each other. Brain note:
`shinichi-brain/docs/dev-log/handover/2026-09-02-h2-twin-one-lane-start-prompt`
("H² twin — one Cursor lane, both packages"). Read it before Phase 0; it carries the model
and push bindings, which are **not** repeated here as authority.

**Why this pair may fit it better than H² does.** The coupling is tighter — a live R↔Julia
bridge and a frozen-oracle parity harness needing both repos open at once — and the seam is
where things already stall: two owner decisions relayed between the lanes on 2026-09-02 (the
four grouping levels; bringing the ZI trio to R) sat unconfirmed for two days because they
moved by relay. They are D5 and D6 in the decision set below.

**CONFIRMED DIRECTLY — this is no longer a relay.** Shinichi told *both* lanes himself on
2026-09-04, recorded with his verbatim words as **vault `D-220`** (*"we want to move to Cursor -
together with GLLVM.jl - and run one lane in Cursor"*). Verified in
`~/shinichi-brain/memory/DECISIONS.md` by this session.

**D-220 also settles campaigns, which this handover would otherwise have left open.** Simulations
and campaigns move with the lane — because they never ran *inside* the agent anyway: the heavy work
runs on **Totoro over SSH** and the session only writes scripts, dispatches, and reads results.
That is transport, not model capability. Four conditions ride along: reach Totoro through the
**existing ControlMaster socket** (a fresh login triggers Duo — D-64), keep the core cap at **150**
(D-143), GitHub Actions stays barred for campaigns (D-50), and D-139 governs (estimate first,
pre-run anything over 30 minutes).

**Honest caveat.** The H² one-lane arrangement is days old and no outcome is recorded. You are
inheriting a design Shinichi chose, not a result anyone has measured.

---

## 1. Mission control

| Repo | main | CI | What shipped | Next by leverage |
|---|---|---|---|---|
| **GLLVM.jl** | `4d57cb29` | **8/8 Julia shards + Documenter green**; frozen-R smoke advisory-red by design | Core 0.7.0 + AGHQ parity merged (`2524b787`, merge commit). Ledger 505 required = 292 bound + 213 dispositioned, 0 free. Suite 13327 pass / 0 fail. Second-order receipts on 20 paired + 22 realistic-size cells. | The six decisions in §5; then `--r-ref`; then phylo S3/S4 |
| **gllvmTMB** | `72ed68b5` | R-CMD-check green | Reverse-parity gap programme closed: ZI trio (`zi_poisson`/`zi_nbinom2`/`zi_binomial`), `ordinal_logit()`, `censored_poisson()`, `select_lv()` + `anova()` with chi-bar p-values, `ordination_uncertainty()`. 50-seed recovery campaign for `ordinal_logit` + `censored_poisson` landed (#1258, #1259). | Its own handover: `docs/dev-log/handover/2026-09-03-claude-handover.md` on its main |

Both lanes reported ready. Neither has any in-flight work.

---

## 2. Landing state ledger (the gate FAILED — read this, it is inherited, not ours)

`tools/handoff_gate.sh` fails on **both** repos. **None of it is this session's work**, which
is 100 % landed on `origin/main` in both.

| Repo | Unlanded | Whose | Disposition |
|---|---|---|---|
| GLLVM.jl | 25 uncommitted in the main Dropbox checkout (on branch `claude/jl-bridge-capabilities-20260619`): `.claude/preview/*` modifications and untracked `.claude/agents/*.md` | pre-existing at session start | **CARRIED-OVER** — not mine to commit; triage before that checkout is used |
| GLLVM.jl | 51 unpushed commits across **27** branches (June–August; Claude, Codex and Cursor lanes) | prior lanes | **CARRIED-OVER** — needs an owner-by-owner sweep, not a bulk push |
| gllvmTMB | 3 uncommitted | pre-existing, not that lane's | **Untracked cruft, not unlanded work** — two empty worktree-metadata dirs (`.codex/worktrees/`, `.worktrees/`) and one stray `LOOP/README.md` |
| gllvmTMB | **633** unpushed on old `agent/*` and `tmp/*` branches | prior lanes | **CARRIED-OVER** — local-only, never pushed, and the `agent/*` family's named artifacts are gone from main. That is *"stale by evidence"*, **not** "abandoned" — do not upgrade the phrasing |
| gllvmTMB | 8 open PRs | various | **Report dates and states; do NOT report liveness.** #981/#1065/#1070/#1077 (2026-08-17) are MSPL work under a **signed PARK — vault `D-157`**: deliberately not moving, which is *not* the same as stale, and calling them ambiguous would misrepresent a decision. #1198 (2026-08-20) is DIRTY/conflicting. #1209 (2026-08-25). **#1236 (2026-09-01) is the julia-bridge expansion — the one that most concerns the Julia side.** #1238 (2026-09-02) is a parked iJSDM handover |

**Do not bulk-push or bulk-delete any of it.** Some `/private/tmp/gllvm*` paths are still
*registered worktrees* of these repos (confirmed by the gllvmTMB lane), so size is not a
safe deletion signal. A single lane holding both repos is the first thing well placed to
triage this properly — but it is a task to be given, not assumed.

**FINDING-OF-RECORD:** the `tools/parity_ledger.R` ref asymmetry (§4). vault-note:
**`D-220` caveat 1**, written by the gllvmTMB lane and verified present by this session. It carries
the concrete `--r-ref` fix and applies the same reasoning to the frozen oracle, so the finding is no
longer branch-only and survives both lanes ending.

---

## 3. The two invariants that get WEAKER under one lane

This is the substantive risk in the whole move, and it is why §4 exists.

1. **`AGENTS.md`: "No engine surgery on R's `gllvmTMB` from this repo. That R package is a
   read-only reference."** Today that holds *structurally* — the Julia lane simply does not
   have the R repo checked out. One lane holding both **removes the structural guard and
   leaves only a sentence in a prose file.**
2. **The frozen oracle is `b4d5fee64def88bc768dda1f1f77c29b295edd86` (gllvmTMB 0.7.0).**
   Parity is qualified against *that build*. If one agent can move both sides of the
   comparison, the comparison stops meaning anything.

An invariant that says "do not touch" is weaker than a check that reads at a pinned ref.
Which is exactly the next section.

---

## 4. FIRST TECHNICAL TASK — `parity_ledger.R` pins the two sides asymmetrically

Reported by the gllvmTMB lane; **independently verified against `origin/main` by this
session** rather than taken on trust.

In `gllvmTMB/tools/parity_ledger.R`:

- **Julia side** (~line 65): `git -C <GLLVM.jl> show <ref>:docs/design/capability-status.md`
  — pinned; `--ref` defaults to `origin/main`.
- **R side** (lines 36, 81): `R_LEDGER_PATH <- file.path(ROOT, "docs", "design",
  "capability-status.md")` then `readLines(R_LEDGER_PATH)` — **the working tree, no ref.**

Harmless while one agent holds one repo. **Under one lane it is exactly the hazard in §3:**
an uncommitted edit to the R ledger silently moves one side of the comparison while Julia
stays pinned, and `CLOSURE: PASS` still prints. The failure is quiet, and it favours
whichever side is easier to edit.

**Proposed fix** (neither lane made it — it is a joint-contract change and Shinichi's call):
give the R side a `--r-ref` defaulting to `origin/main`, resolved the same way Julia already
is, so **neither** side can be moved by a working-tree edit. Comparing a branch then has to
be said out loud. Apply the same reasoning to the frozen oracle: read it at a pinned ref
rather than trusting a prose invariant.

---

## 5. Blockers / open questions — SIX DECISIONS WAITING ON SHINICHI

`docs/dev-log/core070/maintainer-decision-set-2026-09-03.md` (on GLLVM.jl main). Each has a
recommendation and a stated default if unanswered.

| # | Question | Recommendation |
|---|---|---|
| D1 | Sign the second-order SE / vcov / Wald tolerances? | Sign as drafted — receipts sit two orders *inside* them |
| D2 | Whose `cond(H)` does the scaling use? (858 Julia vs 14 138 R on the same cell) | R's, both recorded — it is a parameterisation difference, not a curvature one |
| D3 | `loading_profile` estimand scope — R profiles a *confirmatory* fit, Julia an *exploratory* one | Rename ours `_exploratory`; the collision is the name, not the mathematics. **The only one blocking a ledger row.** |
| D4 | T8 AGHQ rows | Bind 14; reclassify the 8 that no public R fit can reach |
| D5 | T12 grouping levels `unit`/`unit_obs`/`cluster`/`cluster2` | R names verbatim, diagonal-only, sequenced after phylo, aliased onto the row structs |
| D6 | The two relayed items | Confirm or correct — **neither lane has acted on them** |

D4, D5 and D6 span both repos. They are the natural first work for a single lane, and the
reason the arrangement was proposed.

---

## 6. Files created / modified by this session

All landed on `origin/main`:

- `.github/workflows/CI.yml` — 4-way shard matrix × 2 Julia versions; coverage behind `workflow_dispatch`; `cancel-in-progress` only for PRs; markdown-only `paths-ignore` (`4d57cb29`)
- `AGENTS.md` — Phase state snapshot moved to the merged state (`f94ac388`)
- `docs/dev-log/check-log.md` — merge entry with the gate, the conflict resolution, and a "what this does NOT claim" paragraph (`f94ac388`)
- `docs/dev-log/handover/2026-09-02-claude-handover.md`, `2026-09-03-claude-handover.md` — CLOSED banners (`f94ac388`)
- `docs/dev-log/core070/maintainer-decision-set-2026-09-03.md` — the six decisions (in `2524b787`)
- The parity merge itself, `2524b787`, carries 1562 changed files from the lane
- This file + the `AGENTS.md` pointer edit, on branch `handover/2026-09-04-cursor`

---

## 7. Environment Cursor needs (assume nothing from the authoring session)

**Working directories** — create both worktrees, add BOTH to one Cursor workspace:

```sh
bash ~/shinichi-brain/tools/lane_launch.sh GLLVM.jl  gllvm-twin-20260904
bash ~/shinichi-brain/tools/lane_launch.sh gllvmTMB  gllvm-twin-20260904
```

**Julia** (`julia` may not be on PATH; the maintainer's binary is `~/.juliaup/bin/julialauncher`):

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. test/runtests.jl                     # quick core suite
julia --project=. -e 'using Pkg; Pkg.test()'           # full, incl. Aqua/JET — what CI runs
GLLVM_TEST_SHARD=1/4 julia --project=. test/runtests.jl # one shard (~1/4 of 13327 tests)
```

Safe verification command for a docs-only change: none needed — CI now skips markdown.

**R** — the parity harness needs a real toolchain. Two traps that cost the gllvmTMB lane real
time; a lane that has not hit them **will report green on nothing**:

- `testthat::test_file()` silently runs the **installed** package, not your checkout. Use
  `devtools::load_all()` first.
- `skip_on_cran()` makes an entire file skip while testthat still prints `DONE`. Set
  `NOT_CRAN=true`.
- Since the CI sharding change, **a green check may mean `check-r-package` was SKIPPED** via a
  fast-pass path. On a source change, green proves nothing until you read the step conclusions.
- **A conflict marker makes an R file unparseable, and the bare-abort counter silently skips it** —
  so the count comes out *below* its ceiling and reads as a pass. A falling count is not a win.

**Files you must not stage:** `.claude/preview/*`, untracked `.claude/agents/*.md`,
`.unlazy/**` (git-ignored by design), `test/Project.toml` if a `Pkg.develop(path=".")` in the
test env modified it (revert it). **Never `git add -A` or `git add .`** — disjoint lanes edit
in parallel.

**Push policy:** GLLVM.jl `AGENTS.md` says *no push without an explicit instruction*. The H²
note makes the same binding for a Cursor lane, plus: ask once at G0 whether this run may push
named branches, default local-only.

---

## 8. Gotchas from this session (do not re-learn these)

- **GitHub can silently deliver no `pull_request` event** for a push — `actions/runs?head_sha=`
  returns 0 while status is operational. Work around with `gh workflow run CI.yml --ref <branch>`.
- **A merged-looking PR may have been reopened.** #278 was closed at 12:33Z and merged at
  12:48Z; its merge **silently reverted PR #275's action bumps** (checkout v6→v4, setup-julia
  v3→v2, codecov v6→v4) because that branch predated them. Restored in `84b7fef2`. Check what
  a merge *removes*, not only what it adds.
- **`count("_shard_include(\"", ...)` over a file counts its own expression** — an off-by-one.
  The header now counts indented call sites only; keep every call site indented or it
  under-reports.
- **A destructive-command guard blocks `rm -rf` and `git branch -D`** regardless of sandbox
  overrides. Do not decompose a command to slip past it — surface it to Shinichi.
- **`git checkout -- <path>` is guarded too**; `git show HEAD:<path> > <path>` restores a file.
- **Scripted regex edits across docstring blocks are dangerous.** A greedy `"""..."""` match
  commented out a public struct here, twice. Verify exact line ranges first.
- **Julia `1.10` vs `1` differ on last-ulp literals.** Use `≈ ... rtol=1e-12`, not `==`.
- **Documenter `checkdocs=:missing_docs` rejects docstrings on internal helpers.** This repo's
  convention is zero docstringed internals — use `#` comment blocks.
- The **frozen-R CI smoke is advisory-red by design** (`continue-on-error: true`,
  `docs/dev-log/core070/ci-oracle-reproducibility-finding.md`). It is not a regression.

---

## 9. Next immediate steps — NARROW; do these and nothing else

1. **Lane preflight in both repos** (`~/shinichi-brain/tools/lane_preflight.sh <repo>`), then
   reconcile this handover against actual git state and classify every item here as
   **OWED / DONE / RETRACTED / PROTECTED**. Do not act before that classification exists.
2. **Confirm the single-lane arrangement with Shinichi directly.** It reaches you relayed, and
   a relayed decision on this exact pair has already sat two days unconfirmed. The gllvmTMB
   lane said the same and is right.
3. **Prove the R/TMB capability before committing any campaign to this lane** (§7): compile the
   TMB DLL from a clean checkout, `devtools::load_all()`, fit one paired cell. Cursor is a lane,
   not a capability tier (`protocols/welcome-cursor`); holding the lane grants nothing.
4. **Take the §4 `--r-ref` question to Shinichi** before any joint work touches either ledger.
5. **Bring the six decisions** (§5), starting with D5/D6 — the cross-repo ones the seam dropped.

Anything beyond this is not owed by this handover.

---

## 10. How to resume

```sh
cd <the GLLVM.jl worktree>
~/shinichi-brain/tools/lane_preflight.sh .
git status -sb && git log --oneline -8
gh run list --branch main --workflow CI.yml --limit 3
```

Then paste into a fresh Cursor agent in the repository:

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-04-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

This document is committed on `handover/2026-09-04-cursor` and is the authoritative copy;
this session's chat is not.
