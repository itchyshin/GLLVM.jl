# Session Handoff: Destination B evidence spine -> Codex

Meta: 2026-09-12 · from Codex · target Codex · worktree
`/private/tmp/destination-b-b1-integration-20260910`

You are **Codex**, continuing Destination B in a fresh lane.  Read this file,
`AGENTS.md`, the coordination board, and live Git state before acting.  This
document supersedes the 2026-09-10 Cursor handoff only for the B1 evidence
spine; it does not claim ownership of other lanes.

## Critical Context

Destination B is **not qualified**.  Public language remains “experimental
partial R-to-Julia bridge”, never 0.7 parity.  FRK remains parked at
gllvmTMB#1275; do not widen to 0.7.1, a coverage campaign, release, registry,
push, or merge.

The B1 fixed-point marginal-curvature evaluator is deliberately
`PRE_RUN_ONLY` and fail-closed.  It cannot read a capture or call TMB until a
separately authorized, content-addressed canonical capture exists.  The prior
direct-Hessian result is a protected HOLD, not a failed or passing curvature
result.

## Mission and Roadmap

The approved programme is to qualify actual grouping and phylogenetic models
with retained paired evidence and feasible intervals.  Gate new capability
expansion behind two evidence questions:

1. Resolve the S4 Julia environment probe with retained raw output; its
   previous replay did not reach either selected test.
2. Establish whether B1 has usable **marginal** fixed-coordinate curvature.

Until those gates are resolved, do not expand non-Gaussian grouping or make
interval/parity claims.

## What Was Accomplished

| Lane / branch | State | Evidence |
|---|---|---|
| B1 protocol `codex/destination-b-b1-integration-20260910` | Local-only checkpoint | `dd2ab502` seals an evaluator, TOML/Markdown contract, verifier and 22/22 static test. |
| B1 Codex handoff | Local-only checkpoint | `672ab025` is the prior Cursor handoff. |
| S4 failure retention | Cross-lane local commit | `97214679c` repairs only early Julia-probe failure retention; focused contract test: 11 tests / 83 expectations. |

The direct B1 diagnostic made one `fn`, one `gr`, and one `he` attempt.  TMB
returned “Hessian not yet implemented for models with random effects”.  It
produced no observed Hessian, eigenpairs, projections, or interval evidence.

## Current Working State

- **Working:** the B1 static contract verifies `PRE_RUN_ONLY`, one future
  `obj$fn(theta_star)` followed by one `TMB::sdreport(..., par.fixed =
  theta_star, getJointPrecision = FALSE, getReportCovariance = FALSE,
  skip.delta.method = TRUE)`, no optimizer, and exact success fields
  `cov.fixed`, `pdHess`, `gradient.fixed`.
- **Blocked by explicit authority:** canonical capture materialization.  It is
  a one-time frozen-object serialization only; it must not call `fn`, `gr`,
  `he`, `sdreport`, a fitter, optimizer, or restart.
- **Protected:** `docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json`
  is untracked.  Never stage, edit, delete, or retry it.
- **S4:** the repaired runner still needs a fresh, separately approved no-fit
  Julia probe using a new output namespace.  Do not treat the old replay as
  evidence.

## Key Decisions and Rationale

- The next B1 curvature target is marginal outer-Laplace fixed-effect
  curvature, not conditional joint precision.  `getJointPrecision = TRUE` is
  explicitly out of scope.
- A canonical capture was never written by the original direct-Hessian run.
  Do not invent a path, data/map hash, or DLL hash.  The evaluator rejects
  `UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION` before `readRDS` or `MakeADFun`.
- Exact source/data/formula/vector and runtime TMB/DLL provenance are required
  before the later curvature diagnostic.  The later diagnostic requires new
  approval even after capture materialization.
- The coordination board records multiple lanes.  Do not refresh a singleton
  `AGENTS.md` snapshot pointer or overwrite other handovers.

## Landing State

`handoff_gate.sh` reports local-only commits and the protected untracked HOLD.
No push was authorized.  A new Codex worktree must have access to this local
branch; a fresh clone cannot see these commits until the maintainer explicitly
authorizes a push.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| `codex/destination-b-b1-integration-20260910` @ `dd2ab502`, `672ab025` | yes | no | none | **CARRIED-OVER** — local checkpoint. Resume: `git checkout codex/destination-b-b1-integration-20260910 && git log --oneline -6`. |
| `docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json` | no | no | none | **CARRIED-OVER / PROTECTED** — direct-Hessian HOLD. Resume: `git status --short -- docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json`. |
| This handoff | yes after commit | no | none | **CARRIED-OVER** — local-only; do not push without explicit maintainer approval. |

**FINDINGS-OF-RECORD: none** — no vault write was authorized.

## Files to Read

- `docs/dev-log/handover/2026-09-10-cursor-handover.md`
- `docs/dev-log/after-task/2026-09-10-b1-fixed-point-marginal-curvature-pre-run.md`
- `docs/dev-log/protocols/b1-fixed-point-marginal-curvature-audit.{toml,md}`
- `tools/destination_b/b1_fixed_point_marginal_curvature_evaluator.R`
- `docs/dev-log/coordination-board.md`

## Next Immediate Steps

1. Run the rehydration commands below and classify each item as `OWED`,
   `DONE`, `RETRACTED`, or `PROTECTED`.
2. Ask for explicit authorization before capture materialization.  If granted,
   write only the canonical capture RDS and actual RDS/data/map/DLL hashes;
   make no numerical call and no fit.
3. Review and statically verify the materialization-pin update.
4. Ask again before one bounded marginal-curvature diagnostic.  Its protocol
   estimate is 30 seconds and hard-stop is 60 seconds.
5. Keep S4 separate: request approval for one no-fit Julia probe only after
   confirming the repaired runner and a new output target.

## Gotchas and Failed Approaches

- Direct `obj$he(theta_star)` is unsupported with active random effects.  It
  was an interface limitation, not a non-PD Hessian verdict.
- A prior S4 replay failed before tests; its raw probe output was not retained.
  `97214679c` fixes future failure retention only.
- Do not use a capture's self-reported fingerprints.  Compute hashes from the
  actual RDS bytes, serialized data/map, and DLL used by `MakeADFun`.
- Do not run `Pkg.test()`, broad recovery, or a coverage campaign in this
  checkpoint.  Static verification is the only safe command without approval.

## Codex Rehydration and Safe Commands

```sh
cd /private/tmp/destination-b-b1-integration-20260910
bash ~/shinichi-brain/tools/lane_preflight.sh .
git status -sb
git log --oneline -8
sed -n '1,260p' AGENTS.md
sed -n '1,300p' docs/dev-log/handover/2026-09-12-codex-handover.md
sed -n '1,220p' docs/dev-log/coordination-board.md
julia --startup-file=no --history-file=no --project=. test/test_b1_fixed_point_marginal_curvature_protocol.jl
julia --startup-file=no --history-file=no --project=. tools/verify_b1_fixed_point_marginal_curvature_protocol.jl
git diff --check
```

Do not stage the HOLD JSON, `.unlazy/**`, unrelated lane files, or a capture
RDS before explicit materialization authority.  Never use `git add -A` or
`git add .`.

## How to Resume

Read `AGENTS.md` and `docs/dev-log/handover/2026-09-12-codex-handover.md`.
Run the handover rehydration steps, reconcile them with the current git state,
then continue only the OWED Next Immediate Steps.
