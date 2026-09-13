# Checkpoint — Destination B frozen-0.7.0 G2 lines 1+2 (B1 curvature + S3b)

GOAL: see `LOOP/GOAL.md` (that file is the G1-scoped goal, now closed; this
checkpoint documents the follow-on G2 session Shinichi separately
authorised — "G2 lines 1+2" = B1 curvature + S3b consumer; push authorised;
S4/line 3 explicitly NOT authorised).

STATE (2026-09-13, G2 session): pushed the branch (new `origin/codex/destination-b-b1-integration-20260910`,
carrying the 88 pre-existing local commits). Materialized the B1
`fixed_point_marginal` capture for real (trace-intercept `MakeADFun`, zero
optimizer calls, hashes computed not invented) and ran the ONE authorised
`TMB::sdreport` evaluation attempt — **result: FAILED**
(`"A map factor length must equal parameter length"`, thrown one step before
`obj$fn`/`sdreport` inside the bare `MakeADFun` reconstruction). Retained
honestly at
`docs/dev-log/core070/destination-b-b1/fixed-point-marginal-curvature-diagnostic-20260913.json`
— now **PROTECTED**, same as the earlier `fixed_coordinate` HOLD; **no
retry occurred and none should without a fresh maintainer decision**. Ran
the S3b end-to-end adapter consumer
(`test/test_destination_b_adapter_consumer.jl`) for the first time this
worktree — **97/97 PASS** (Julia 1.10.0, macOS 26.6.2 arm64) — in an
isolated ephemeral env so `Project.toml`/`Manifest.toml` were not touched.

PRIOR STATE (G1, closed 2026-09-13 at `46ec66d8`): G1 matrix written and
integrated (16 DONE / 7 OWED / 4 RETRACTED / 1 PROTECTED across B1/S3b/S4);
Unlazy ledger has a G1 progress note with no gate checked off.

ARCS DONE (verified):
- LOOP/ scaffold written (this commit-to-be).
- B1/S3b/S4 graft-first orientation — verified by reading the cited
  `graft ask --source` output and the source lines it pointed at.
- Three named static verifiers re-run and their console output read (not
  just exit code): `test_b1_fixed_point_marginal_curvature_protocol.jl`
  22/22, `verify_b1_fixed_point_marginal_curvature_protocol.jl` PASS,
  `test_destination_b_a4_s4_receipts.jl` 60/60,
  `test_destination_b_a4_s4_public_r_formula_receipt.jl` 29/29,
  `destination_b_scope_check.mjs` → `SCOPE_HISTORY_AND_NEGATIVE_CONTROLS_PASS`.
- One test, `test_destination_b_a4_s4_fixed_coordinate_evaluator.jl`,
  self-corrected and flagged in the matrix §4 (ran to completion, 45/45,
  before its numerical nature was recognised from its own `include`d
  source; no new artifact, HOLD untouched).
- Three fit/DLL-risk test files positively identified from source peek only
  and NOT executed: `test_destination_b_adapter_consumer.jl`,
  `test_destination_b_dense_uncertainty.jl`,
  `test_destination_b_phylo_independent_receipt.jl`.
- `git cat-file -t 97214679c` → exit 128, confirming the S4 recorder is
  absent from this object database.
- HOLD JSON confirmed as the only untracked file in `git status --short`
  throughout the session.

ARC IN PROGRESS: closing check-log.md + after-task report, then committing
LOOP/ + the matrix + those two by explicit path.

NEXT: none within this goal — after the commit, STOP and ask Shinichi for
G2 authorisation (a separate, named decision covering: capture
materialization, B1 curvature evaluation, and/or the S4 probe).

OPEN GATES (need human): **G2** — every numerical B1/S4 gate
(`B1-JOINT-STATIONARY`, `B1-JOINT-PAIR`, `B1-RECOVERY`, `S3B-CONSUMER`
end-to-end run, `S4-PUBLIC-FORMULA`) stays NOT AUTHORIZED until Shinichi
gives a fresh, separate decision. The S4 probe is additionally blocked by
the physically-absent recorder `97214679c` regardless of authority.

TRUTH LIVES IN:
- `docs/dev-log/2026-09-13-destination-b-g1-audit-matrix.md` (the matrix).
- `.unlazy/destination-b-programme/GATES.md` (gitignored; G1 progress note).
- `docs/dev-log/check-log.md` (this session's entry).
- `docs/dev-log/after-task/2026-09-13-destination-b-g1-static-audit.md`.
- Branch `codex/destination-b-b1-integration-20260910` @ tip after this
  session's commit (see that commit's hash once landed).

RESUME: read `LOOP/GOAL.md` → this file → the matrix doc → the check-log
entry dated 2026-09-13 (G1 audit). Do not re-run G1; it is closed. Do not
start any numerical work without a fresh, explicit G2 message from
Shinichi naming exactly which of {B1 curvature, S3b end-to-end consumer
run, S4 probe} is authorised.
