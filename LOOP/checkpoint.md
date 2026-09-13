# Checkpoint — Destination B frozen-0.7.0 G2 closeout (B1 close-as-limit, S3b evidence, S4 held)

GOAL: see `LOOP/GOAL.md` (G1-scoped goal, closed). Then G2 lines 1+2
(B1 curvature + S3b consumer), closed at `ce46bebf`. This checkpoint
documents the follow-on **G2 closeout** session: Shinichi's "run DestB all
the way to finish, make the decisions autonomously" instruction, applying
his four named decision points to the state left by `ce46bebf`.

STATE (2026-09-13, closeout session): no new numerical work ran. Applied
four maintainer-directed dispositions:

1. **B1 → CLOSED — INTERFACE LIMIT.** Both HOLD receipts
   (`fixed_coordinate`'s `obj$he()` error, `fixed_point_marginal`'s
   `MakeADFun` map-length error) documented together as two confirmations
   of the same class of limit — a frozen 0.7.0 R TMB capture does not
   reconstruct through a bare, out-of-pipeline `MakeADFun()` call. Decision:
   `docs/dev-log/decisions/2026-09-13-destination-b-b1-close-as-limit.md`.
   No retry, no redesign implemented this session. Ledger
   `B1-JOINT-STATIONARY`/`B1-JOINT-PAIR` moved `NOT AUTHORIZED` →
   `CLOSED — INTERFACE LIMIT (2026-09-13)` (checkbox stays `[ ]` — closure,
   not a pass). `B1-RECOVERY` unchanged (downstream, never reached).
2. **S4 → HELD.** No probe run or authorised. Re-confirmed
   `git cat-file -t 97214679c` → exit 128 (recorder absent). Ledger
   `S4-PUBLIC-FORMULA` unchanged (`NOT AUTHORIZED`).
3. **S3b ledger update, fenced.** `S3B-CONSUMER` flipped `[x]` /
   `QUALIFIED (adapter/test-only scope)` on the strength of the prior
   session's 97/97 `test_destination_b_adapter_consumer.jl` run (`ce46bebf`
   — no new test ran this session). Explicit inline fence: NOT B1 Wald, NOT
   full Destination B done, NOT S4.
4. **Draft PR** opened `codex/destination-b-b1-integration-20260910` →
   `main`, `--draft`, not merged, no force-push.

ARCS DONE (verified):
- Lane preflight + 4h lease claimed on
  `docs/dev-log/`, `LOOP/`, `.unlazy/destination-b-programme/`,
  `ENGINE-GATES.md` (last unused/unrelated topic, read-only).
- `git cat-file -t 97214679c` re-run → exit 128, matches G1 matrix citation.
- `git status --short` checked before this session's commit: only the
  pre-existing protected HOLD JSON (untracked by design) and a local
  `graft/` build-cache dir (untracked, not staged, not a deliverable).
- Decision doc, closeout note, after-task, check-log entry all written.
- `.unlazy/destination-b-programme/GATES.md` updated (gitignored, not
  committed to git, but the disk file itself now reflects all four
  dispositions above).

ARC IN PROGRESS: committing the tracked deliverables by explicit path,
pushing, opening the draft PR.

NEXT: none within this closeout goal. STOP after PR is open. Any further
Destination B work (B1 redesign, S4 rehydration+probe, PR merge) needs a
fresh, separate, named maintainer decision.

OPEN GATES (need human): B1 redesign strategy (if any); S4 recorder
rehydration + fresh authorisation; PR #<see chat> review/merge decision.

TRUTH LIVES IN:
- `docs/dev-log/decisions/2026-09-13-destination-b-b1-close-as-limit.md`.
- `docs/dev-log/2026-09-13-destination-b-g2-closeout.md`.
- `docs/dev-log/after-task/2026-09-13-destination-b-close-as-limit.md`.
- `.unlazy/destination-b-programme/GATES.md` (gitignored).
- `docs/dev-log/check-log.md` (this session's entry, dated 2026-09-13).
- Branch `codex/destination-b-b1-integration-20260910` @ tip after this
  session's commit (see the after-task's commit hash once landed).

RESUME: read `LOOP/GOAL.md` → this file → the G2 closeout note → the
check-log entry dated 2026-09-13 (closeout). Do not re-open B1 or S4
without Shinichi naming exactly which reopens (redesign strategy for B1;
recorder rehydration + fresh probe authorisation for S4).
