# Destination B — G2 closeout (frozen-0.7.0): B1 closed-as-limit, S3b consumer evidence landed, S4 held

**Date:** 2026-09-13
**Worktree:** `/private/tmp/destination-b-b1-integration-20260910`
**Branch:** `codex/destination-b-b1-integration-20260910`
**Authority:** Shinichi's "run DestB all the way to finish, make the
decisions autonomously, use the recommended path" instruction (this
session), applying the four named decision points to the state left by the
2026-09-13 G1 static audit (`46ec66d8`) and G2 lines 1+2 numerical session
(`ce46bebf`).
**Frozen R oracle:** `gllvmTMB` 0.7.0 @ `b4d5fee64def88bc768dda1f1f77c29b295edd86`.

This note is the single closeout record for the three open lines this
programme carried after `ce46bebf`. It does not re-run any numerical check;
it records the maintainer-directed disposition of each line and points to
the evidence already on disk.

## Disposition summary

| Line | Disposition | Evidence |
|---|---|---|
| B1 marginal-curvature (`B1-JOINT-STATIONARY`, `B1-JOINT-PAIR`) | **CLOSED — INTERFACE LIMIT.** No retry, no redesign this run. | Both HOLD receipts (`fixed-coordinate-curvature-diagnostic-20260910.json`, `fixed-point-marginal-curvature-diagnostic-20260913.json`); decision doc `docs/dev-log/decisions/2026-09-13-destination-b-b1-close-as-limit.md` |
| S3b end-to-end adapter consumer (`S3B-CONSUMER`) | **Evidence landed, narrowly fenced.** Gate's adapter-consumer criterion is met by today's 97/97 run; ledger updated accordingly with explicit non-claims. | `test/test_destination_b_adapter_consumer.jl` → 97/97 PASS (2026-09-13, recorded in `ce46bebf`); ledger update in this commit |
| S4 public-formula probe (`S4-PUBLIC-FORMULA`) | **HELD.** Not authorised this session; recorder `97214679c` confirmed absent from this worktree's object database. | `git cat-file -t 97214679c` → exit 128 (re-confirmed both in the 2026-09-13 G1 matrix and again for this closeout, see below) |

## 1. B1 — closed as a confirmed interface limit

See `docs/dev-log/decisions/2026-09-13-destination-b-b1-close-as-limit.md`
for the full record. In brief: two independent out-of-pipeline `MakeADFun`
reconstruction attempts against the frozen 0.7.0 TMB/DLL binding both
failed before reaching `obj$fn()`/`TMB::sdreport()` — the first at
`obj$he(theta_star)`, the second one step earlier, inside the reconstruction
call itself (`"A map factor length must equal parameter length"`). Neither
receipt is a curvature or singularity verdict about GLLVM.jl; both are
interface limits of rebuilding a frozen R capture outside `gllvmTMB`'s own
fitting pipeline. `B1-JOINT-STATIONARY` and `B1-JOINT-PAIR` move from
`NOT AUTHORIZED` to `CLOSED — INTERFACE LIMIT` in
`.unlazy/destination-b-programme/GATES.md` (this commit). `B1-RECOVERY`
stays `NOT AUTHORIZED` (was always downstream and never reached).

## 2. S3b — adapter-consumer evidence landed (fenced)

`test/test_destination_b_adapter_consumer.jl` ran end-to-end in the prior
G2 session (`ce46bebf`) and passed **97/97** against frozen R-derived
fixtures for the tree, pedigree-with-ancestors, and dense-`vcv` cases — the
exact three fixture classes the `S3B-CONSUMER` gate names. The gate's own
criterion text ("Tree, pedigree-with-ancestors and dense-`vcv` bridge
receipts bind the frozen R identity, canonical precision/node/scale/logdet
convention, and do not unlock generic engine routing") is satisfied by this
run: matched point estimates, log-likelihoods, and all 12 named Wald
interval endpoints per fixture, against the frozen R identity, with the
adapter/test-only scope boundary intact (no `gllvmTMB` C++ or
likelihood-engine change; no independent Julia inversion of the dense R
`vcv`).

Per Shinichi's explicit instruction, `S3B-CONSUMER` is updated in the ledger
to reflect this — **narrowly fenced**:

- This **is**: the adapter/test-only consumer path working end-to-end for
  three named fixture classes, for the first time this worktree has ever
  run that test.
- This **is not**: B1 Wald inference (B1 stays closed-as-limit, above), the
  S4 probe (separate line, held below), or "Destination B done" (30 of the
  reconciled 32 rows, plus `B1-RECOVERY`, `API-BOUNDARY`, and
  `FINAL-REVIEW`, are untouched by this evidence).
- This does **not** authorise generic bridge routing, a public capability
  promotion, or any change to the standing public wording ("experimental
  partial R-to-Julia bridge, not 0.7 parity").

## 3. S4 — held, not probed

No S4 probe ran in this session or any prior session on this branch. Two
independent barriers apply, and neither is removed by this closeout:

1. **Authority.** Shinichi's instruction for this session explicitly names
   "S4 → HOLD. Do not authorize or run probe." No fresh authorisation is
   granted here.
2. **Physical.** The S4 recorder object `97214679c` remains absent from
   this worktree's git object database. Re-confirmed for this closeout:

   ```sh
   $ git cat-file -t 97214679c
   fatal: Not a valid object name 97214679c
   ```

   (exit 128 — identical result to the 2026-09-13 G1 matrix's own check).
   Its owning lane would need to be rehydrated into this worktree before a
   probe could even be attempted, independent of any authority question.

`S4-PUBLIC-FORMULA` stays `NOT AUTHORIZED` / HOLD in the ledger, unchanged
by this closeout beyond a cross-reference to this note.

## What this closeout does NOT do

- It does not run any new numerical check, capture, fit, optimizer, R/TMB
  call, or `Pkg.test()` full suite.
- It does not retry either B1 attempt or design a new reconstruction
  strategy.
- It does not run or authorise the S4 probe.
- It does not merge anything to `main` — a draft PR is opened separately
  (see the after-task report for this closeout) and stays unmerged.
- It does not touch `AGENTS.md`'s snapshot pointer, PR #314's lane files, or
  any twin (R) test-lane file.
- It does not stage the protected HOLD JSONs as "fixed" — both remain
  retained FAILED receipts.

## Pointers

- Decision: `docs/dev-log/decisions/2026-09-13-destination-b-b1-close-as-limit.md`
- Prior matrix: `docs/dev-log/2026-09-13-destination-b-g1-audit-matrix.md`
- Prior after-task (numerical G2): `docs/dev-log/after-task/2026-09-13-destination-b-g2-b1-s3b.md`
- This closeout's after-task: `docs/dev-log/after-task/2026-09-13-destination-b-close-as-limit.md`
- Ledger: `.unlazy/destination-b-programme/GATES.md` (gitignored)
- LOOP checkpoint: `LOOP/checkpoint.md`
