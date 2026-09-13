# After-task: Destination B frozen-0.7.0 — G1 static audit (B1/S3b/S4)

**Date:** 2026-09-13
**Lane:** `codex/destination-b-b1-integration-20260910` (worktree
`/private/tmp/destination-b-b1-integration-20260910`)
**Platform:** Cursor (Ada persona), running the `/goal` arc-loop adapter
**Authority:** Shinichi's "G1 yes" via `/goal`, scoped exactly to G1 (static
audit only), no G2 authorisation

## Scope

Produce a row-by-row DONE / OWED / RETRACTED / PROTECTED matrix for three
Destination B domains — **B1** (grouping), **S3b** (R `phylo_rr` bridge
adapter), **S4** (Gaussian paired public-formula probe) — against the frozen
`gllvmTMB` 0.7.0 oracle (`b4d5fee64def88bc768dda1f1f77c29b295edd86`), using
only static interface inventory, symbolic alignment, and artifact review.
No capture materialization, no B1 curvature evaluation, no S4 probe, no
fit, no optimizer, no R/TMB numerical call, no `Pkg.test()` full suite.

## What landed

1. **`LOOP/` scaffold** — `LOOP/GOAL.md`, `LOOP/arcs.md`,
   `LOOP/checkpoint.md` written for this run's binding goal; `LOOP/ultra-plan.md`
   overwritten with a copy of the approved plan
   (`docs/dev-log/plans/2026-09-13-destination-b-g0-ultraplan.md`). The
   pre-existing `LOOP/` directory in this worktree carried unrelated content
   from an earlier, different lane (an "Option A parity closeout" goal); it
   was overwritten, not merged, because it was a stale template/wrong-subject
   artifact, not live state for this run.
2. **G1 matrix** —
   `docs/dev-log/2026-09-13-destination-b-g1-audit-matrix.md`. Row-by-row
   classification: **16 DONE / 7 OWED / 4 RETRACTED / 1 PROTECTED** across
   B1 (6/3/1/1), S3b (4/1/2/0), S4 (6/3/1/0).
3. **Naming disambiguation, written down for the first time this session:**
   the authorisation-line labels "S3b" and "S4" are *not* the formal 32-row
   scope IDs (`A1–A15, B1–B4, C1–C5, D1–D8`); they are legacy "A4/S4" labels
   from the 2026-09-05 true-parity map era. "B1" does happen to name-match
   the formal row `B1 = grouping-levels/UNIT-KWARG-NAME-PARITY`. This
   matters because a future public claim citing "S4" without saying which of
   (a) the authorisation label or (b) a formal row (closest: A14/A15,
   `covariance/COV-PHYLO-LATENT-*`) it means would be ambiguous.
4. **Protocol-pair disambiguation re-confirmed:** `fixed_point_marginal`
   (sealed `dd2ab502`, 22/22, the ledger's `B1-JOINT-*` target) is distinct
   from `fixed_coordinate` (root `.unlazy/GATES.md`, separate 4/4 receipt).
   Any "B1 static contract (22/22)" citation means `fixed_point_marginal`
   only.
5. **S4 recorder absence re-confirmed physically, not just cited:**
   `git cat-file -t 97214679c` returned `fatal: Not a valid object name
   97214679c` (exit 128) in this worktree.
6. **Unlazy ledger progress note** added to
   `.unlazy/destination-b-programme/GATES.md` (gitignored) summarising G1
   without moving any gate.
7. **check-log.md** entry (2026-09-13, "Destination B frozen-0.7.0 G1 static
   audit") with full command/output evidence.

## Method

Graft-first, per the standing `/graft-bridge` rule for this checkout: `graft
ask "<question>" --source` located every public call path and symbolic
contract cited in the matrix (`_bridge_fit_onepart`, `_GROUPING_TERM_NAMES`,
`_bridge_pmv_options`, `_bridge_rr_df`/`rr_theta_len`,
`validate_a4_s4_public_r_formula_receipt`) before any manual grep or file
open. `graft ask` auto-detected and copied its graph from the main Dropbox
`GLLVM.jl` checkout without needing a hand-built cache or `graft init` in this
worktree (`~4 × 10,000+ tokens saved` per the tool's own accounting across
four queries — see chat transcript for exact per-call figures). Every graft
hit was treated as a source pointer only, then verified by reading the cited
lines directly. Three parallel scouts were offered by Shinichi but not
spawned as separate subagents: the total read-only surface (a dozen graft
queries plus a handful of file peeks) was small enough that running the
domains sequentially inside one conductor context, then integrating, cost
less than dispatching, tracking, and merging three separate agents would
have. The *output shape* — bullet matrix rows with file-path citations,
integrated into one document — matches what three scouts would have
returned.

Five static verifiers named in the handover/plan were re-run and their
console output read directly (not just exit code):
`test_b1_fixed_point_marginal_curvature_protocol.jl` (22/22),
`verify_b1_fixed_point_marginal_curvature_protocol.jl` (PASS),
`destination_b_scope_check.mjs` (`SCOPE_HISTORY_AND_NEGATIVE_CONTROLS_PASS`),
`test_destination_b_a4_s4_receipts.jl` (60/60),
`test_destination_b_a4_s4_public_r_formula_receipt.jl` (29/29).

## Self-correction (honesty-over-agreement; do not read past this)

One additional file, `test_destination_b_a4_s4_fixed_coordinate_evaluator.jl`,
was launched under the same "matches the schema-test naming pattern"
assumption as the five above. Partway through its 32-second run its
`include`d source (`tools/destination_b/a4_s4_fixed_coordinate_evaluator.jl`)
was read and showed it loads `GLLVM` and evaluates the package's own marginal
objective at fixed, hardcoded coordinates against pre-recorded canned
R-side numbers (a matched-point style check). This is closer to the "B1
curvature" / "S4 probe" family this goal is fenced against than to a pure
schema verifier, even though the actual numbers are static fixtures, not a
fresh R capture, and it wrote no new artifact. A `kill` was attempted on
recognising this; the process had already exited (45/45 pass) by the time
the kill command ran. This is reported plainly in the matrix (§4) and here,
rather than folded silently into the "successfully re-verified" list, per
this repo's verification-before-completion and honesty-over-agreement
guards. **Its PASS is not treated as new numerical authorisation evidence
and does not move any gate.**

Three further files were positively identified as fit/DLL-risk purely by
reading their source (never executed):
`test_destination_b_adapter_consumer.jl` (calls `GLLVM.bridge_fit` end to end
on tree/pedigree/dense fixtures — a real optimizer call),
`test_destination_b_dense_uncertainty.jl` (conditionally loads and calls
against an R DLL path), `test_destination_b_phylo_independent_receipt.jl`
(includes a file named `fit_phylo_gaussian_reference.jl`).

## What did NOT happen

- No capture materialization, `obj$fn`/`sdreport` call, optimizer run, or
  live R/TMB invocation via any of the four flagged/excluded test files
  above.
- No `Pkg.test()` full-suite run.
- The B1 HOLD JSON
  (`docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json`)
  was never staged, edited, deleted, or retried — confirmed as the only
  untracked file in `git status --short` throughout the session.
- No gate in `.unlazy/destination-b-programme/GATES.md` was checked off.
  `B1-JOINT-STATIONARY`, `B1-JOINT-PAIR`, `B1-RECOVERY`, `S3B-CONSUMER`,
  `S4-PUBLIC-FORMULA` remain exactly pending / NOT AUTHORIZED.
- No push, merge, `AGENTS.md` snapshot edit, or touch of PR #314's files.
- No `git add -A` / `git add .` — every stage in this closing commit is by
  explicit named path.

## Verification

- Every re-run static verifier's console output was read directly (pasted
  above and in check-log.md), not inferred from exit code alone.
- The HOLD JSON's untouched status was checked by `git status --short`
  before and after this session's work, not assumed.
- The S4 recorder's absence was checked by `git cat-file -t`, not assumed
  from the handover's prose alone.
- This report itself is the "own-the-verifier" step for the self-correction
  above: a fresh look at the evaluator's `include`d source, not the agent
  that ran it deciding on its own that the run was fine.

## Definition of done — checked against the binding goal

1. `LOOP/` scaffolded — **done** (this session; content matches this run's
   goal, not a stale prior lane's).
2. G1 matrix under `docs/dev-log/` — **done**
   (`docs/dev-log/2026-09-13-destination-b-g1-audit-matrix.md`).
3. check-log + after-task for G1 — **done** (this report; check-log entry
   dated 2026-09-13).
4. Explicit STOP message with a named G2 ask — **see below**.

## STOP — G2 ask (separate decision, not answered by this session)

G1 is closed. Three named lines remain **OWED** and require Shinichi's own,
fresh, separate authorisation before any of them may be attempted (each is
independently gate-able; approving one does not imply the others):

1. **B1 curvature** — capture materialization + one marginal-curvature
   attempt on the `fixed_point_marginal` pair (`B1-JOINT-STATIONARY` →
   `B1-JOINT-PAIR`). Estimated ≤ 30 s per the protocol's own hard-stop
   contract, but the maintainer's own compute-routing question ("Totoro or
   DRAC?") still applies if this becomes a campaign rather than one probe.
2. **S3b end-to-end consumer** — actually running
   `test_destination_b_adapter_consumer.jl` (a real `bridge_fit` call on the
   existing tree/pedigree/dense fixtures). Per the 2026-09-08 authorisation
   this stays an adapter/test line only — no `gllvmTMB` C++ or
   likelihood-engine change would be in scope even if authorised.
3. **S4 probe** — one Gaussian paired public-workflow validation call, only
   after (2) is authorised and shown to work, **and** only once the S4
   recorder `97214679c` is rehydrated from its owning (cross-)lane — that
   part is a physical blocker independent of any authority Shinichi grants.

Nothing in this session infers approval for any of the three. If Shinichi
says yes to one, name which one explicitly; this lane will not infer scope
from a general "go ahead."
