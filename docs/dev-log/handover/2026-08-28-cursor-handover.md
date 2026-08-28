# Handover: Claude → Cursor, 2026-08-28 (full-parity ultracode campaign, day close)

You are a fresh **Cursor** agent picking up the GLLVM.jl full-parity campaign.
You inherit **no chat context** — this document plus the repository ARE the
state. Read `AGENTS.md` first (mission, rules, review roles), then this file,
then reconcile against live git before acting. Classify every item below as
OWED / DONE / RETRACTED / PROTECTED against what you actually find.

## GOAL STATUS — NOT COMPLETE (read this before claiming anything)

The standing goal is *"GLLVM.jl at full capability parity with the gllvmTMB
0.7.0 twin — correctness debt cleared at the root, the 17-cell parity ladder
closed, the capability ledger honest, and the package releasable."*

**Achieved:** the HEADLINE only — the Fisher-vs-observed Laplace fault class
is structurally dead (census `KNOWN_OPEN` empty). Plus the ledger honesty
pass on the curvature table.

**NOT achieved, and this session did not claim otherwise:**
- The **parity ladder is NOT closed.** 13/17 paid; cells 12/13 are *measured
  with cause* but explicitly NOT paid; student (9) and tweedie (6) are
  untouched estimator/defect gaps.
- The **package is NOT releasable.** Arcs 3, 4 and 6 are open (covariance
  grid, cross-validation, `@formula` categoricals, random slopes, StatsAPI
  methods, orphaned tests, claim reconciliation, version bump, Rose
  pre-publish audit). Estimated ~1–3 weeks of work remains.
- Several **maintainer decisions are pending** (listed under Next Immediate
  Steps) and gate parts of that remainder.

This handover is a **platform transfer mid-goal**, not a completion report.
Continue the goal; do not treat any of the above as done.

## Critical Context

- **Goal (maintainer-set):** GLLVM.jl at full capability parity with the
  gllvmTMB 0.7.0 twin — correctness debt cleared at the root, the 17-cell
  parity ladder closed, the capability ledger honest, the package releasable.
- **Lane:** branch `claude/lane-beyond-20260824` on origin (PR #273 open).
  The authoring worktree was
  `/Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824` (local branch
  name `hessian-kwarg-20260827`; it intentionally trails origin/main and
  pushes go via cherry-pick onto origin/main — see Gotchas).
- **PROTECTED — never work in** `/Users/z3437171/Dropbox/Github Local/GLLVM.jl`
  (stale June fork). The twin at
  `/Users/z3437171/Dropbox/Github Local/gllvmTMB` is READ-ONLY (no engine
  surgery, ever).
- **Live roadmap (maintainer-requested pointer): "Road to 0.7.0 Parity"**
  — https://claude.ai/code/artifact/36d36919-654d-4d63-b21e-b09165003795 —
  refreshed at this handover (arc chips, parity-cell strip, decision gates).
  The durable in-repo twin of that page is
  `docs/dev-log/plans/2026-08-27-roadmap-to-completion.md`.
- **Arc position:** Arc 1 CLOSED
  (curvature fault class: census `KNOWN_OPEN` empty), Arc 2 CLOSED, Arc 3 in
  progress (delta `:shared` mode shipped; live parity Δ + student-ν remain),
  Arc 5 started (AGHQ Slice 0 done). Arcs 4, 6 not started.

## What Was Accomplished (2026-08-28, this session)

All on PR #273 (12 commits, origin tip `31c3d7cc` at writing):

1. **Arc-2 mop-up**: Gaussian PosDef sentinel screen (`_fit_verdict` at both
   return sites); CMP `compoisson_logz` Shmueli asymptotic past 80% of the
   term cap (+ Int-args `InexactError` regression fix); all ten two-part
   fitters expose `hessian` (honest no-op scope documented —
   TWOPART_KNOWN_OPEN).
2. **JuliaCall runtime repair** (unblocks the Codex bridge gate AND
   parity-in-CI): R-embedded Julia segfaulted on Totoro because system
   libunwind binds over Julia's own. Fix (demonstrated both 1.10.10/1.12.6):
   `LD_PRELOAD=$HOME/.julia/juliaup/julia-<V>/lib/julia/libunwind.so.8` when
   launching R. Full diagnosis:
   `docs/dev-log/compute/2026-08-28-juliacall-embedding-diagnosis.md`.
3. **Maintainer decision batch** (`docs/dev-log/decisions/2026-08-28-arc-decision-batch.md`)
   — READ IT; it re-scopes the campaign: Tweedie+probit flips YES; delta twin
   identity = MODE; AGHQ UNPARKED; L47 none×dep PROMOTE (still undone — OWED);
   non-Gaussian REML and delta latent-scale advertising STAY REJECTED.
   Still fenced: Tweedie fit_gllvm ADMIT (STOP #234 — the flip ≠ the admit).
4. **Grouped fit structs record `hessian`** + adapters rebuild the fit's own
   objective (8 structs, 16 sites, `test_grouped_hessian_consistency.jl`).
5. **TweedieED + Binomial-probit curvature flips → the fault class CLOSES.**
   Probit proven globally concave (Pratt 1981; BigFloat endpoint check) — the
   "sign-changing" premise was refuted. Tweedie's series is μ-free so the
   closed form is exact. FD-verified ≤2.5e-7.
6. **AGHQ unpark Slice 0**: curvature selector threaded into `aghq_grid.jl`
   (was unconditional Fisher, drifted vs 9 families' `:observed` defaults);
   `:fisher`-pinned bit-identical; k=1 ≡ Laplace at 1e-10 for all nine.
   Internal only — NO public `aghq=` surface.
7. **Delta `predictor = :shared` twin-identity mode** (packing change only,
   kernel untouched; offset threads to BOTH parts under `:shared`, matching
   `gllvmTMB.cpp:1401`): `docs/dev-log/decisions/2026-08-28-delta-shared-predictor-identity.md`.
8. **Ledger honesty**: `capability-status.md`'s curvature table was ~4 flips
   stale — corrected; the census test is the machine-checked source of truth.

Suite evidence (Totoro): run A (tree `dc1ee936`) **6955 / 0 fail / 4 broken**,
exit 0; run B (tree `db3b90ad` = grouped + flips) **6997 / 0 / 4**, exit 0,
84m39s. run C (tree `8b1448ab` = + AGHQ Slice 0 + delta `:shared`) **7062 / 0 / 4**,
exit 0, 85m20s — **GREEN, landed after the handover was first written; every
commit on PR #273 now has full-suite coverage.**

## Current Working State

- **PR #273** OPEN at origin tip `31c3d7cc` (12 commits) + the parity commit
  `6c471352` and this handover to push. Documenter + deploy **pass**; the four
  Julia matrix jobs were still queued/running at handover — CHECK THEM
  (`gh pr checks 273`) before any merge. **The maintainer merges; never
  auto-merge, never `--auto`.**
- **Live parity Δ for delta cells 12/13: MEASURED — honest mismatch, model
  difference.** Twin fits PER-TRAIT delta dispersion, Julia shared scalar:
  Δ logLik −1.92 (lognormal) / −2.57 (gamma), commit `6c471352`. Cells NOT
  marked paid. NEW MAINTAINER DECISION: per-trait dispersion variant on the
  Julia delta fitters, or reclassify the cells with this record as evidence.
  (Also: installed twin is 0.7.1, not 0.7.0 — recorded, not substituted.)
- Working tree at writing: clean except this handover + the `AGENTS.md`
  snapshot bullet (both committed by this handover's own commit).

## Landing State ledger (CARRIED-OVER items — declared, not landed)

- ~~Totoro full suite run C~~ **RESOLVED before session close: 7062 pass /
  0 fail / 4 expected-broken, exit 0, 85m19.9s (tree `8b1448ab`).** Tally
  stamped into the check-log. No carried-over suite work remains.

- `viz-plots2` branch: 1 unpushed commit `aa19b773` (Florence Plots.jl
  extension, predates this arc). WHY: unrelated lane, not this session's work.
  Resume: `git checkout viz-plots2 && git log origin/viz-plots2..viz-plots2`.
- `hessian-kwarg-20260827` local branch carries `b667337b` (CI push:[main]
  trim) which CANNOT be pushed: OAuth token lacks `workflow` scope. WHY:
  only the maintainer can fix — `gh auth refresh -s workflow -h github.com`.
  Until then every push must EXCLUDE it (the cherry-pick route below).
- Totoro artifacts (all `snakagaw@totoro`, ControlMaster socket
  `~/.ssh/cm-snakagaw@totoro...`): `~/GLLVM.jl-mopup` (suite checkout),
  `~/GLLVM.jl-pin-00a2d7b7` (byte-exact bridge-gate engine pin — Codex needs
  it; do NOT delete), `~/jcall-diag-depot`, `~/jcall-*.{R,log}`,
  `~/gllvm-*-suite.log`. Fir/Rorqual partial dirs
  (`/project/def-snakagaw/snakagaw/{GLLVM.jl-lane,julia_depot}`) await the
  maintainer's deletion.
- FINDINGS-OF-RECORD: the twin df-CI off-by-one bug (df profile CIs report
  df−1; upstream report DRAFTED in
  `docs/dev-log/decisions/2026-08-28-studentt-parameterisation.md`, posting
  needs the maintainer's go) · the JuliaCall libunwind diagnosis (committed
  doc, see #2 above).

## Key Decisions & Rationale

See `docs/dev-log/decisions/2026-08-28-arc-decision-batch.md` (the campaign
re-scope) and `2026-08-28-delta-shared-predictor-identity.md` (identity +
supersession of the 2026-08-25 brief's named-fitter shape). Standing:
estimator quality beats reported-loglik accuracy where they conflict
(decision A); GP-1 keeps Fisher BY DECISION; cloglog is an intrinsic
saturation pathology, not a weight bug.

## Files Created / Modified (session diff = PR #273, 30 files)

src: `fit.jl` · `confint_family.jl` · `families/{aghq_grid,beta_binomial,
beta_hurdle,binomial,com_poisson,grouped_dispersion,tweedie,twopart}.jl`
tests: `runtests.jl` · `test_{aghq_grid,com_poisson,curvature_census,
delta_shared_predictor(new),grouped_dispersion_tweedie_nb1,
grouped_hessian_consistency(new),hessian_kwarg,laplace_curvature_contract,
tweedie_grouped_engine_health,twopart_hessian_kwarg(new)}.jl`
docs: `CHANGELOG.md` · `docs/design/capability-status.md` ·
`docs/dev-log/check-log.md` · `docs/src/{response-families,gllvmtmb-parity}.md` ·
`docs/dev-log/{compute,decisions}/2026-08-28-*.md` (3 new) · `.gitignore`
plus this handover and the after-task report.

## Next Immediate Steps (narrow; run lane preflight FIRST)

1. **Verify PR #273's Julia matrix jobs** (`gh pr checks 273`) — the only
   item left unconfirmed at close; Documenter + deploy passed and all three
   Totoro suites are green (6955 / 6997 / 7062, all exit 0).
2. **If the maintainer says merge #273** (their call): `gh pr merge 273 --merge`
   on green. Never `--auto`.
3. **L47 none×dep promote** (decision batch gate 6, OWED, small):
   `src/none_dep.jl` works (39/39); promotion = ledger row + docs cascade.
4. **Parity-in-CI keystone** (the honest-parity gap): promote `test/parity/`
   into an opt-in CI job using the libunwind fix for any R↔Julia embedding.
   Codex's bridge-gate spec + `docs/dev-log/compute/2026-08-28-*.md` are the
   references.
5. **Student-ν estimator** (parity cell 9): adjudicated plan in
   `docs/dev-log/plans/2026-08-28-three-arc-designs.md`; NOTE the twin df-CI
   bug when comparing intervals.
6. Then Arc 4 per the structured-dependence sequencing: `spatial_dep` →
   kernel-source grammar → large-p non-Gaussian determinant path (design-first,
   maintainer sign-off before build).

**Needs a maintainer decision (do NOT decide):** delta cells 12/13 closure
shape (per-trait dispersion vs reclassify — see commit `6c471352`) ·
AGHQ Slices 2–4 (outer adaptation loop, report honesty, public `aghq=` knob) ·
posting the upstream df-CI bug report · merge word for #273 · any
covariance-grammar identity choices in Arc 4.

## Blockers / Open Questions

- CI `workflow`-scope refresh (maintainer-only, see ledger).
- Codex holds the gllvmTMB side of the bridge gate; engine pin
  `00a2d7b7` / tree `8a243605` is immutable for it. Do not move or reuse
  `~/GLLVM.jl-pin-00a2d7b7` on Totoro.

## Gotchas / Failed Approaches (hard-won; do not re-learn)

- **Push mechanics:** the local branch cannot fast-forward push (carries the
  unpushable CI commit). Route: `git worktree add --detach <tmp> origin/main`,
  cherry-pick the new commits, `git push origin <sha>:refs/heads/claude/lane-beyond-20260824`.
  NEVER pipe cherry-pick through `tail` (a masked conflict shipped a partial
  chain once — check exit codes explicitly).
- **Suites:** full `Pkg.test()` runs on Totoro (~85 min), NOT locally: rsync
  the tree to `~/GLLVM.jl-mopup`, run via a scp'd script with
  `$HOME/.juliaup/bin/julia` (bare `julia` is not on non-interactive PATH
  there), `OPENBLAS_NUM_THREADS=4`, `≤150 cores total for snakagaw` (D-143).
  Heredoc-over-ssh silently writes EMPTY files — always write locally,
  `scp`, verify byte count. `pgrep -f "Pkg.test"` matches itself; use
  `ps ax | grep "[j]ulia"`.
- **Suite tallies are per-TREE claims**: stamp a tally only on entries whose
  content the rsynced tree actually contained (two near-misses this session).
- **Check-log prepends can swallow the previous entry's heading** (happened
  once — verify `grep "^## " | head` after any prepend).
- Never `git add -A`/`-u`; stage by name. One Julia process locally.
  No tolerance widening, ever. Test oracles must consult `_default_hessian`,
  never hardcode a weight.
- The Mac's R parity env: `GLLVM_PARITY_TESTS=1`,
  `GLLVM_PARITY_R_LIBS=/Users/z3437171/Library/R/arm64/4.6/library`.

## How to Resume (Cursor)

Working dir: a fresh checkout of `claude/lane-beyond-20260824` (or the lane
worktree above if it survives). Julia ≥1.10 via `~/.juliaup/bin/julialauncher`.
Quick verify: `julia --project=. test/runtests.jl` (core) — full suites go to
Totoro. Never stage: `campaigns/curvature_adjudication/prerun_out/`, any
`.claude/preview/*` churn, foreign untracked files.

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-28-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

## Mission-control table

| repo | branch vs main | CI | shipped today | next by leverage |
|---|---|---|---|---|
| GLLVM.jl | PR #273 (16 commits) open | Documenter ✅ · suites 6955/6997/7062 all ✅ · Julia matrix: CHECK | fault class CLOSED · AGHQ Slice 0 · delta `:shared` mode · JuliaCall fix · decision batch | merge #273 → L47 promote → parity-in-CI → student-ν → Arc 4 |
