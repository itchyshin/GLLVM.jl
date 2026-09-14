# After-task: Destination B frozen-0.7.0 — G2 closeout (B1 close-as-limit, S3b evidence, S4 hold, draft PR)

**Date:** 2026-09-13
**Lane:** `codex/destination-b-b1-integration-20260910` (worktree
`/private/tmp/destination-b-b1-integration-20260910`)
**Platform:** Cursor (Ada persona)
**Authority:** Shinichi's explicit instruction: "run DestB all the way to
finish, make the decisions autonomously," naming the recommended path as
four numbered points (B1 close-as-limit; S4 hold; open draft PR, no merge;
S3b ledger update with fencing).

## Scope

Close out the three open Destination B lines left by the prior G1 audit
(`46ec66d8`) and G2 numerical session (`ce46bebf`), per the maintainer's
four explicit decision points, with no new numerical work:

1. **B1** → close-as-limit (not redesign). No retry.
2. **S4** → hold. No probe.
3. **Draft PR** to `main` from this branch. No merge, no force-push.
4. **S3b** → update ledger to reflect the 97/97 adapter-consumer evidence,
   narrowly fenced.

## What landed

1. **Decision doc** —
   `docs/dev-log/decisions/2026-09-13-destination-b-b1-close-as-limit.md`.
   Documents both B1 HOLD receipts (`fixed_coordinate`'s `obj$he()` error;
   `fixed_point_marginal`'s `MakeADFun` map-length error) as confirmed
   interface limits of reconstructing a frozen R TMB capture outside
   `gllvmTMB::gllvmTMB()`'s own pipeline. Explicitly not a curvature or
   singularity verdict about GLLVM.jl. Explicitly not a redesign or retry.
2. **G2 closeout note** —
   `docs/dev-log/2026-09-13-destination-b-g2-closeout.md`. Single record
   covering all three lines' final disposition for this session, with a
   summary table and pointers.
3. **Ledger update** — `.unlazy/destination-b-programme/GATES.md`
   (gitignored, not committed):
   - `B1-JOINT-STATIONARY`, `B1-JOINT-PAIR`: `STATUS` changed from
     `NOT AUTHORIZED` to `CLOSED — INTERFACE LIMIT (2026-09-13)`, citing the
     decision doc. Checkbox left `[ ]` (unqualified — this is a closure, not
     a pass) with an explicit "no retry without a fresh, separate decision
     naming a different reconstruction strategy" note.
   - `B1-RECOVERY`: unchanged (`NOT AUTHORIZED`; was always downstream and
     never reached; explicit note that closing the two gates above does not
     open this one).
   - `S3B-CONSUMER`: checkbox flipped to `[x]`, `STATUS: QUALIFIED
     (adapter/test-only scope)`, `EVIDENCE`: today's 97/97 run
     (`test/test_destination_b_adapter_consumer.jl`, recorded in `ce46bebf`
     / the 2026-09-13 G2 after-task). Explicit fencing text added inline:
     NOT B1 Wald, NOT full Destination B done, NOT S4.
   - `S4-PUBLIC-FORMULA`: unchanged (`NOT AUTHORIZED`; recorder
     `97214679c` re-confirmed absent this session via `git cat-file -t`,
     exit 128 — identical result to the G1 matrix's own check).
4. **check-log.md** — entry appended for this closeout session.
5. **LOOP/checkpoint.md** — updated to record the closeout state and name
   what remains after this PR.
6. **Draft PR** — opened from `codex/destination-b-b1-integration-20260910`
   to `main`, `--draft`, not merged. See PR URL in the closing chat message.

## What did NOT happen (per explicit fence)

- No third B1 attempt; no capture-reconstruction redesign implementation.
- No S4 probe; the recorder absence was re-confirmed, not rehydrated.
- No merge of the draft PR; no force-push.
- No HOLD JSON was staged, edited, or presented as "fixed" — both remain
  retained FAILED receipts, byte-identical to how the prior sessions left
  them (verified by `git status --short` before and after this session,
  see Verification below).
- No twin (R) test-lane file was touched.
- No edit to `AGENTS.md`'s snapshot pointer.
- No edit to PR #314's (`cursor/codex-handover-20260907`) lane files.
- No `git add -A` / `git add .` — every stage is by explicit named path.
- No numerical check, fit, optimizer, R/TMB call, or `Pkg.test()` run.

## Verification

- `git cat-file -t 97214679c` re-run this session: `fatal: Not a valid
  object name 97214679c`, exit 128 — matches the G1 matrix's own citation
  exactly; the S4 recorder absence is not stale-cited, it was re-checked.
- `git status --short` before this session's own commit showed exactly two
  entries: the pre-existing protected HOLD JSON
  (`fixed-coordinate-curvature-diagnostic-20260910.json`, untracked by
  design) and a local `graft/` build-cache directory (untracked local
  artifact from `graft ask`/`graft build` orientation calls in this
  worktree, not a deliverable, not staged). Neither the HOLD JSON nor the
  newer `fixed-point-marginal-curvature-diagnostic-20260913.json` (already
  committed in `ce46bebf`) was touched by this session's edits.
- The `S3B-CONSUMER` ledger flip is evidence-based, not invented: it cites
  the exact test file, exact pass count (97/97), and exact commit
  (`ce46bebf`) where that run's console output was captured and recorded in
  `docs/dev-log/check-log.md` and the prior after-task. No new test run
  occurred in this closeout session.
- Lane preflight (`~/shinichi-brain/tools/lane_preflight.sh`) run at session
  start named this exact branch as the intended lane and flagged PR #314 as
  a foreign lane not touched by this session. A 4-hour lease was claimed on
  `docs/dev-log/`, `LOOP/`, `.unlazy/destination-b-programme/`, and
  `ENGINE-GATES.md` (the last unused — `ENGINE-GATES.md` covers an
  unrelated Wave2 engine-gates topic and was read but not edited).

## Definition of done — checked against Shinichi's four decision points

1. B1 close-as-limit, documented, no retry — **done** (decision doc above).
2. S4 held, recorder absence noted — **done** (closeout note + ledger,
   re-confirmed via `git cat-file`).
3. Draft PR opened, not merged — **done** (see chat message for URL).
4. S3b ledger updated with fencing — **done** (ledger `S3B-CONSUMER` entry
   above).

## What is left after this PR

- **B1 marginal-curvature**: a redesigned reconstruction strategy (e.g.
  capturing `parList()`/`last.par` structure, or reconstructing via
  `gllvmTMB`'s own internal builder instead of a bare `MakeADFun` call) is
  the only path back to `B1-JOINT-STATIONARY`/`B1-JOINT-PAIR`, and needs its
  own fresh, separate maintainer decision before any implementation.
- **S4 probe**: blocked on (a) a fresh authorisation and (b) rehydrating the
  recorder object `97214679c` from its owning (cross-)lane into this
  worktree — a physical prerequisite independent of authority.
- **`B1-RECOVERY`**: unreachable until B1's curvature line reopens.
- **`API-BOUNDARY`** / **`FINAL-REVIEW`**: unreachable until the above.
- **This PR itself**: review and merge decision is Shinichi's; it is opened
  as `--draft` and will not self-merge.
