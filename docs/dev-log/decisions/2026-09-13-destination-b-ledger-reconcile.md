# Destination B frozen-0.7.0 ledger reconcile — decision record

**Date:** 2026-09-13
**Status:** committed candidate — Shinichi has not yet said "commit"; this
file is written but intentionally left untracked pending his word.
**Gate this closes:** DestB-G0(frozen) static ledger work, per
`docs/dev-log/plans/2026-09-13-destination-b-g0-ultraplan.md`.

## What was decided

Shinichi answered the ultraplan's Plan-G0 question with **"1 — Reconcile"**:
update the existing `.unlazy/destination-b-programme/GATES.md` ledger in
place to match the frozen-0.7.0 framing, rather than opening a second,
parallel ledger for the re-scoped G0–G7 sequence proposed in the 2026-09-12
handover.

## Why reconcile-over-new-scope

The ultraplan's Phase 0.25 prior-work sweep found the acceptance ledger was
**not missing** (finding F2): `.unlazy/destination-b-programme/GATES.md`
already existed with 8 gates (`G0-SCOPE`, `B1-JOINT-STATIONARY`,
`B1-JOINT-PAIR`, `B1-RECOVERY`, `S3B-CONSUMER`, `S4-PUBLIC-FORMULA`,
`API-BOUNDARY`, `FINAL-REVIEW`), all pending. Opening a second,
frozen-0.7.0-labelled ledger for the same programme would have produced two
ledgers tracking one programme — exactly the failure mode an acceptance
ledger exists to prevent. Reconciling in place keeps one authoritative
ledger, preserves the existing gate ids (nothing was renamed), and layers the
handover's G0–G7 sequence on top via an explicit mapping table rather than a
parallel numbering.

## What changed in the ledger

`.unlazy/destination-b-programme/GATES.md` (gitignored; not committed by
this change) now carries:

1. A locked-facts block: the frozen oracle hash
   `b4d5fee64def88bc768dda1f1f77c29b295edd86`, the protected B1 HOLD JSON
   path, the `.unlazy/**` / `AGENTS.md` snapshot / PR #314 protections, and
   the exclusion list (FRK parked, no 0.7.1, no blanket coverage, no
   releases).
2. An explicit **NOT AUTHORIZED** block naming B1 marginal-curvature
   evaluation and the S4 probe as requiring their own separate, fresh
   maintainer decisions — nothing in this reconcile grants numerical
   authority.
3. A handover-G0–G7-to-existing-gate mapping table, so a future reader does
   not need to hold two gate ladders in their head at once.
4. A resolution of finding **F4** (two B1 curvature protocol pairs coexist):
   the "22/22" pre-run contract the 2026-09-12 handover cites is
   `fixed_point_marginal` (sealed at `dd2ab502`), re-verified statically
   today at 22/22 pass and PASS respectively. The separate `fixed_coordinate`
   pair, gated by the root `.unlazy/GATES.md`, is a different, older contract
   for the same protected HOLD file and must not be conflated with the
   "22/22" citation.
5. Pointers to the four related narrower ledgers already in the tree
   (`destination-b-b1-stationary-reference`, `b1-balanced-complete-crossed-pre-run`,
   `totoro-t4-p6-grid`, and the root `fixed_coordinate` ledger) — read for
   context, not edited by this reconcile.

The only gate whose checkbox moved is `G0-SCOPE`, flipped from pending to
`[x]` on the strength of `node tools/destination_b_scope_check.mjs` re-run
today (`SCOPE_HISTORY_AND_NEGATIVE_CONTROLS_PASS`, exactly 32 rows, correct
oracle hash) — a static, non-numerical scope-identity check, not a model or
parity result. Every other gate stayed pending; several gained an explicit
`STATUS: NOT AUTHORIZED` annotation but no checkbox moved.

## What did not happen

- No capture materialization, `obj$fn`/`sdreport` call, optimizer, fit,
  R/TMB invocation, or `Pkg.test()` full-suite run.
- No B1 marginal-curvature evaluation and no S4 probe.
- The protected HOLD JSON
  (`docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json`)
  was not staged, edited, deleted, or retried — confirmed untouched by
  `git status` before and after this session.
- No hash, RDS path, or numerical result was invented; every EVIDENCE line
  added to the ledger reflects a command actually run in this session.
- No commit was made. `.unlazy/destination-b-programme/GATES.md` is
  gitignored and untracked by design; this decision note itself is written
  but not `git add`ed or committed, per Shinichi's instruction to write the
  file without committing it.
- `AGENTS.md`'s snapshot pointer was not touched. PR #314's lane files were
  not touched.

## What is still owed

- **G1** (audit B1/S3b/S4 artifacts against actual public call paths and
  symbolic contracts) is the next gate, and needs its own maintainer
  approval before starting — this reconcile does not grant it.
- Whether Destination B gets a coordination-board row (finding F3 from the
  ultraplan) remains open and separate.
- Whether to commit this decision note (and the ultraplan itself, which is
  currently untracked) is Shinichi's call, asked explicitly at hand-back.
