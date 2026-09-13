# GOAL — Destination B frozen-0.7.0 · G1 static audit only (IMMUTABLE for this run)

Re-read this file at the top of every arc, before anything else.

## Mission
Produce a row-by-row DONE / OWED / RETRACTED / PROTECTED matrix for B1
(grouping), S3b (R `phylo_rr` adapter), S4 (Gaussian paired public-formula
probe) against the frozen-0.7.0 Destination B programme, using only static
interface / symbolic-alignment / artifact inventory. Nothing numerical.

## Headline
G0 (ledger reconciliation) is already done (`.unlazy/destination-b-programme/`,
`G0-SCOPE` `[x]`). This run is G1 only, then a hard STOP for a named G2 ask.

## Checkout / branch / oracle
- Worktree: `/private/tmp/destination-b-b1-integration-20260910`
- Branch: `codex/destination-b-b1-integration-20260910`
- Oracle: `gllvmTMB` 0.7.0 @ `b4d5fee64def88bc768dda1f1f77c29b295edd86`
- Ledger: `.unlazy/destination-b-programme/` (gitignored; reconciled 2026-09-13)
- Plan: `docs/dev-log/plans/2026-09-13-destination-b-g0-ultraplan.md`
- Handover: `docs/dev-log/handover/2026-09-12-cursor-handover.md`
- Commit tip includes `efeeaf11` (reconcile docs)

## Invariants (never violate, even to finish faster)
- Never push, merge, or publish — human gates. Land work on this branch only.
- Verification means reading the LOG and inspecting the ARTEFACT, never the exit code.
- Static-only: no capture materialization, no B1 curvature evaluation, no S4
  probe, no fit, no optimizer, no R/TMB numerical call, no `Pkg.test()` full
  suite — unless a *named*, individually-justified static-only verifier is
  required, and even then treat its output with the same scrutiny as §4 of
  the G1 matrix (self-correction section) demands.
- Never touch
  `docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json`
  (the B1 HOLD JSON) — never stage, edit, delete, or retry it.
- No twin (R) testing. No push. No merge. No `AGENTS.md` snapshot edit. No
  bleed into PR #314's files.
- Stage by name; never `git add -A`; never stage the HOLD JSON or `.unlazy/`
  if doing so would track secrets — `.unlazy/` stays gitignored.
- Query the second brain first for durable decisions
  (`search_notes` with `search_all_projects: true`); this worktree is one
  branch, not the memory.
- Graft-first for symbol/call-path orientation (`graft ask --source`,
  `graft callers`, `graft skeleton`) before grepping/opening files by hand.
  A graft hit is a source pointer, not runtime/statistical proof.

## Pre-authorisation (this run)
- Routine scoped local reads, graft queries, named static-only verifier
  commands (explicitly justified, one at a time), local commits, and the
  checks named in the goal: CONTINUE without re-asking.
- Optional remote authority: none. No push, no draft PR.
- Must stop: any numerical B1/S4 call; any fit/optimizer/R-TMB invocation;
  merge/release/public claim; credentials; destructive out-of-boundary work;
  new compute/cost; reopening G0.

## Out of scope (the fence)
- Capture materialization, B1 curvature, S4 probe, fit, optimizer, R/TMB
  numerical call, `Pkg.test()` full suite (unless a static-only verifier is
  explicitly needed and named, per above).
- The protected HOLD JSON — untouched, always.
- Twin (R) testing, push, merge, `AGENTS.md` snapshot edit, PR #314 bleed.
- G2 and anything past it — separate decision.

## Definition of done (this goal)
1. `LOOP/` scaffolded and committed (or ready to commit with named paths).
2. G1 matrix written under `docs/dev-log/` (named path):
   `docs/dev-log/2026-09-13-destination-b-g1-audit-matrix.md`.
3. check-log + after-task for G1.
4. Explicit STOP message: G2 yes/no required, addressed to Shinichi.
