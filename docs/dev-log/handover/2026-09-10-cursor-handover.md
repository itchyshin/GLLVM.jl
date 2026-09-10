# Session Handoff: B1 fixed-point marginal-curvature contract → Cursor

Meta: 2026-09-10 · from Codex · target Cursor · repository worktree
`/private/tmp/destination-b-b1-integration-20260910`

You are **Cursor**, picking up a narrowly bounded B1 protocol lane. You inherit
no chat context. The repository, this document, and live Git state outrank this
summary if they disagree.

## Critical Context

This is **not** a fitting or curvature-result handoff. The B1 evaluator is
`PRE_RUN_ONLY` and fail-closed because no canonical frozen capture RDS exists.
The only allowed future work is a separately approved capture-materialization
step; a curvature evaluation needs another fresh approval after that step.

The current coordination board has multiple live lanes. Do not edit the
`AGENTS.md` snapshot or replace the board pointer: that would orphan siblings.
Read `docs/dev-log/coordination-board.md` before selecting any work.

## Mission Control

| Repo / lane | Branch / head at handoff drafting | What shipped | Next by leverage |
|---|---|---|---|
| GLLVM.jl B1 protocol | `codex/destination-b-b1-integration-20260910` @ `dd2ab502` | Static, fail-closed marginal-curvature contract and 22/22 verifier suite | Explicitly authorize capture materialization, or stop. No model run by default. |
| S4 cross-lane reference | commit `97214679c` (cross-lane identifier; not present in this worktree object database) | S4 replay record | Treat replay as **unqualified**; rehydrate and verify its own lane before any inference or replay action. |

## What Was Accomplished

- `dd2ab502` (`test: seal B1 marginal-curvature pre-run contract`) landed the
  B1 TOML/Markdown protocol, future evaluator, static Julia verifier, focused
  test registration, check-log entry, and after-task record.
- The focused static command passed **22/22** and the standalone verifier
  passed. Independent review is PASS for the **pre-run contract only**.
- The protocol pins source/data/formula/raw coordinates and TMB provenance,
  requires one future `obj$fn(theta_star)` then one `TMB::sdreport` with
  `par.fixed = theta_star`, and limits success output to `cov.fixed`, `pdHess`,
  and `gradient.fixed`.
- The canonical capture RDS/data/map hash fields deliberately read
  `UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION`; `execution_ready = false`.
  The evaluator rejects before `readRDS`, `obj$fn`, or `sdreport` while they are
  unresolved.
- No numerical run was performed in the protocol, repair, closure, or handoff
  slice.

## Current Working State

- **Working:** static verifier and focused test pass at `dd2ab502`; the check
  log and after-task record explain the boundary.
- **Blocked by authority:** no canonical capture RDS was materialized. Do not
  invent its SHA-256, data/map hashes, or DLL identity.
- **Not working / HOLD:** the prior direct-Hessian diagnostic remains
  unqualified HOLD. TMB rejected its observed-Hessian interface for random
  effects; no Hessian, eigenpairs, or projections exist, and no retry is
  authorized.

## Key Decisions, Approvals, and Boundaries

1. A previous user authorization permitted one direct B1 diagnostic only. It
   produced the unqualified direct-Hessian HOLD; its no-retry rule remains
   binding.
2. `dd2ab502` is only a static/pre-run implementation. It grants no permission
   to load R/TMB, materialize a capture, call `obj$fn`, `sdreport`, a fitter,
   optimizer, restart, Julia fit, or package action.
3. **Separate approval required:** Cursor may materialize the canonical capture
   RDS only after explicit user authority for that exact action. It may
   construct/intercept the frozen `MakeADFun` input solely to serialize the
   capture, must not run `fn`/`gr`/`he`/`sdreport`, dispatch an optimizer or
   restart, overwrite a receipt, or alter data/source/formula/vector/tolerances.
4. After materialization, record actual RDS-byte, serialized-data,
   serialized-map, and resolved-loaded-DLL SHA-256 values; update the protocol
   and evaluator pins in a reviewed static-only revision. A separate fresh
   authorization is still required before any marginal-curvature evaluation.
5. S4 `97214679c` is a cross-lane commit reference and its replay is
   unqualified. It is not a B1 result and does not expand B1 authority.

## Landing State

The pre-write landing gate reported this branch as unpushed with one pre-existing
untracked file and reported unrelated unpushed branches. Nothing is pushed, and
**no push is permitted without a new explicit instruction**.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| B1 static contract: `codex/destination-b-b1-integration-20260910` @ `dd2ab502` | yes | no | none | **CARRIED-OVER** — local branch only; do not push. Resume: `git checkout codex/destination-b-b1-integration-20260910 && git log --oneline -8`. |
| B1 pre-run ancestors: `a5ef6781`, `b317b2d8`, `579196da`, `0832e51e`, `e18b77c6`, `47ecfcf5` | yes | no | none | **CARRIED-OVER** — local evidence/protocol history on the same branch; do not bulk-push. Resume: `git log --oneline dd2ab502^..dd2ab502`. |
| `docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json` | no | no | none | **CARRIED-OVER / PROTECTED** — the prior direct-Hessian HOLD. Resume: `git status --short -- docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json`; never stage, edit, delete, or retry it. |
| This handoff commit | yes after this document is committed | no | none | **CARRIED-OVER** — local-only by current no-push rule. Resume: `git status -sb && git log --oneline -3`. |

**FINDINGS-OF-RECORD: none** — vault write is not authorized.

## Files Created / Modified

Committed B1 contract files at `dd2ab502`:

- `docs/dev-log/protocols/b1-fixed-point-marginal-curvature-audit.toml`
- `docs/dev-log/protocols/b1-fixed-point-marginal-curvature-audit.md`
- `tools/destination_b/b1_fixed_point_marginal_curvature_evaluator.R`
- `tools/verify_b1_fixed_point_marginal_curvature_protocol.jl`
- `test/test_b1_fixed_point_marginal_curvature_protocol.jl`
- `test/runtests.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-09-10-b1-fixed-point-marginal-curvature-pre-run.md`
- This handoff: `docs/dev-log/handover/2026-09-10-cursor-handover.md`

## Cursor Rehydration and First Classification

Run this before changing anything:

```sh
cd /private/tmp/destination-b-b1-integration-20260910
bash ~/shinichi-brain/tools/lane_preflight.sh .
git status -sb
git log --oneline -12
sed -n '1,260p' AGENTS.md
sed -n '1,260p' docs/dev-log/handover/2026-09-10-cursor-handover.md
sed -n '1,180p' docs/dev-log/coordination-board.md
```

Classify before acting:

| Classification | Item |
|---|---|
| **OWED** | Obtain explicit capture-materialization authority, then only prepare a no-numerical materialization plan. Without that authority, stop. |
| **DONE** | `dd2ab502` static B1 protocol/verifier/test contract; 22/22 static result. |
| **RETRACTED** | Treating the direct-Hessian HOLD or S4 replay as qualified curvature/inference evidence; any automatic replay or retry. |
| **PROTECTED** | The untracked B1 HOLD JSON, all other lanes on the coordination board, `AGENTS.md` snapshot, `.unlazy/**`, and any unrelated untracked/modified files. |

## Toolchain and Safe Verification

Assume no inherited Cursor extensions, terminal state, credentials, R library, or
TMB capability. The only safe verification while authority is absent is static:

```sh
cd /private/tmp/destination-b-b1-integration-20260910
julia --startup-file=no --history-file=no --project=. test/test_b1_fixed_point_marginal_curvature_protocol.jl
julia --startup-file=no --history-file=no --project=. tools/verify_b1_fixed_point_marginal_curvature_protocol.jl
git diff --check
```

Do not run `Rscript`, `TMB::sdreport`, `gllvmTMB`, a fit, `Pkg.test()`, or the
full test runner here: each could exceed the authorized static-only scope.

Never stage: the HOLD JSON above, `.unlazy/**`, unrelated lane files, or any
new capture RDS until the user explicitly approves its materialization and
review path. Never use `git add -A` or `git add .`.

## Gotchas and Failed Approaches

- A capture object was only transiently intercepted by the earlier direct
  diagnostic; no canonical RDS exists. Do not forge a path or hash.
- Capture-supplied fingerprints are not trustworthy. The future evaluator must
  hash actual RDS bytes, data/map serializations, and the DLL loaded for
  `MakeADFun`.
- `getJointPrecision = FALSE` targets marginal outer-Laplace fixed-effect
  curvature, not conditional random-effect joint precision.
- The static evaluator intentionally cannot execute with unresolved capture
  pins. That is the correct fail-closed behavior, not an error to work around.

## Next Immediate Steps

1. Rehydrate and classify the ledger above against live Git state.
2. **Do not run a model.** Ask the user for explicit, one-time authority if
   they want the frozen capture materialization described in the approval
   boundary.
3. If authority is not granted, make no further B1 change. If granted, create
   only a narrow materialization plan first; preserve all no-fit/no-optimizer
   and no-clobber boundaries.

## How to Resume

Start a fresh Cursor agent in this worktree and paste:

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-10-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
