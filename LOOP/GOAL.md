# GOAL — core070 overnight lane (IMMUTABLE — re-read at the top of EVERY arc)
Read this first, every cycle. Auto-compact eats messages, not this file. Unsure after a compaction?
Re-read THIS, then LOOP/checkpoint.md, then continue.

## Mission
Run the GLLVM.jl lane `codex/core070-aghq-20260830` (worktree
`/private/tmp/GLLVM.jl-core070-aghq-20260830`) autonomously from 2026-09-02 23:15Z until
2026-09-03 11:00Z (05:00 MDT), landing, with receipts: T14 (NB2 boundary fix set F1–F3, suite
green, pushed, CI verdict read); CI sharding + coverage-off on routine runs; second-order receipts
(SE, fixed-effect vcov block, Wald endpoints) on every paired harness cell, both engines; the T5
paired re-runs with re-binds on passing receipts; the realistic-size pre-run (T4) on Totoro and its
full grid as a Nibi array queued to start when maintenance lifts; phylo transport S1–S2 red-first
under the accepted Q1–Q4 defaults; docs cascade (Fisher-retained list, ZI-trio Julia-beyond note,
"what parity does not mean" section, mi() row on a test receipt); design notes for T12 grouping
levels and T8 AGHQ; then the after-task report, Rose audit, Melissa reconcile, and a Claude
handover for the morning. Finish line = LOOP/arcs.md every arc DONE or honestly DEFERRED with reason,
`.unlazy/core070-overnight/` gates met or ABANDONED with reason, ≤3 pushes used, handover written.

## Headline
Second-order parity receipts on all paired cells: the largest evidence hole in the programme
(every cell ran se=FALSE until today). Everything else is sequenced around not breaking that.

## Invariants (never violated, even after compaction)
- ONE lane, this worktree, this branch. Never touch gllvmTMB/, DRM.jl/, drmTMB/, other lanes' files,
  `.unlazy/core070-aghq` legacy ledgers, or the main GLLVM.jl checkout.
- Oracle stays frozen gllvmTMB 0.7.0 `b4d5fee6`. Qualification claim is one-directional R→Julia.
  Capabilities tracked both ways (vault D-204). No parity claim beyond the receipts.
- No tolerance/gate widening ever. A red result opens a diagnosis, never an edit of the check.
- Compute: Totoro ≤120 cores total (D-143 cap 150; leave headroom), threads pinned to 1; every
  run >30 min gets a pre-run and a written estimate (D-139); a run that overruns its estimate is
  re-reported in checkpoint.md, not hidden. DRAC = Nibi only (queue with `--time` sized from the
  Totoro pre-run + margin, D-201), never a fresh login, never a Duo prompt (D-64).
- Pushes: at most THREE overnight (after T14 green, after the second-order batch, at handover).
  Each push cancels any in-flight CI run on the branch — push only when no run is wanted alive.
- Ledger/status flips only on a retained paired receipt; every flip listed in the morning report.
  Dispositions needing judgment (BLOCKED_SPEC_DEFECT, AGHQ policy rows) untouched.
- Children do the heavy work (Haiku recon/mechanical, Sonnet build/review); the conductor stays lean;
  pass `model` explicitly; ≤6 new children per checkpoint; no Opus/Fable children without a reason.
- Stage by name; one concern per commit; check-log entry per meaningful change; never `git add -A`.

## Authoritative WHAT -> LOOP/ultra-plan.md (detail wins there; this file wins on what must never be lost)

## Definition of done
LOOP/arcs.md: every arc DONE (verified by log/artifact) or DEFERRED with a reason and a resume line;
`.unlazy/core070-overnight/gates/*.md` all MET or ABANDONED with reason; after-task report passes
`closeout.py check`; Rose verdict recorded; Melissa plan-actual filed; handover
`docs/dev-log/handover/2026-09-03-claude-handover.md` written; final push done; lease released.

## Pre-authorisation (Shinichi, 2026-09-02 ~23:05Z, AskUserQuestion)
Up to 3 pushes; CI.yml sharding + coverage off on routine runs; phylo Q1–Q4 defaults accepted
(opt-in correlation=true with bridge forcing it; dense vcv admitted with condition-number warning;
kernel split to its own slice; non-ultrametric deferred behind `GJL-GATE-PHYLO-NONULTRAMETRIC`);
re-bind rows on passing paired receipts and flip mi() to implemented on a test receipt; arcs:
second-order receipts, T5 re-runs, T4 realistic-size, ZI + scoreboard docs, design notes, close.
Routine: scoped edits, tests, Totoro/Nibi runs inside the compute invariant, local commits.

## Must stop for
Merge of any PR; any release/registration; any public claim beyond receipts; credentials; deleting
anything outside this worktree; a 4th push; compute beyond the invariant; a surprise that
contradicts the plan (bring it back to G0 in checkpoint.md as PAUSED, continue other arcs).
