# Session Handoff: frozen-0.7.0 Destination B qualification plan -> Cursor

Meta: 2026-09-12 · from Codex · target Cursor · isolated worktree
`/private/tmp/destination-b-b1-integration-20260910` · branch
`codex/destination-b-b1-integration-20260910`

You are **Cursor**, taking over the frozen `gllvmTMB` 0.7.0 Destination B
qualification programme. You inherit no chat context. Read this document,
`AGENTS.md`, the coordination board, and live Git state before acting; those
sources outrank this summary if they disagree.

## Critical Context

Destination B is the **frozen `gllvmTMB` 0.7.0** qualification programme, not
a 0.7.1 claim. Its narrow headline is to clear the B1 grouping and S4
phylogeny **evidence blockers before** widening grouping or phylogeny work.
The frozen R qualification oracle is `gllvmTMB` 0.7.0 at
`b4d5fee64def88bc768dda1f1f77c29b295edd86`; the live R checkout reporting
0.7.1 is dirty and is not an oracle.

The planning proposal handed into this session has **not** itself authorized
numerical work. It expressly conditions G0/G1 start on maintainer approval.
Do not infer that approval from this handover. Every numerical B1 or S4 call
remains a separate, fresh, explicit maintainer decision.

## Goals / Mission

Deliver an approved, gate-driven plan that can qualify **only** the frozen-0.7.0
Destination B rows. Keep claims testable through Unlazy acceptance gates.

- Static contracts, public-interface inventory, and symbolic alignment may be
  prepared once G0 is expressly approved.
- Defer FRK, 0.7.1, broad coverage certification, releases, registration, and
  all unlisted capabilities.
- A successful B1 curvature call would still not establish B1 Wald inference:
  the retained point is nonstationary. S4's prior failure validates diagnostic
  retention only, not phylogenetic parity.

## Current Working State

- **Working:** B1 static contract at `dd2ab502`; focused static verifier is
  green (22/22). It is a pre-run protocol, not a result.
- **Working:** S4 failure retention is auditable at cross-lane commit
  `97214679c`, but that object is absent from this worktree. Its repaired
  runner must be rehydrated in its owning lane before a new probe.
- **Blocked by authority:** no capture materialization, B1 marginal-curvature
  evaluation, S4 probe, fit, optimizer/retry, R/TMB call, or recovery campaign
  is authorized.
- **Protected HOLD:** the prior B1 direct-Hessian JSON is untracked. Its
  `obj$he(theta_star)` error is an interface limitation, not a curvature or
  singularity verdict.

## Revised Gate Sequence (proposal awaiting approval)

| Gate | Work | Completion evidence |
|---|---|---|
| G0 | Create the Unlazy acceptance ledger; lock frozen oracle, protected files, and exclusions. | Reviewed gates; no numerical work. |
| G1 | Audit B1/S3b/S4 artifacts against actual public call paths and symbolic contracts. | Row-by-row `DONE` / `OWED` / `RETRACTED` / `PROTECTED` matrix. |
| G2 | B1 only: separately authorize capture materialization; review actual hashes; separately authorize one marginal-curvature attempt. | Immutable receipt limited to `cov.fixed`, `pdHess`, and `gradient.fixed`; no retry. |
| G3 | Rehydrate S4's failure recorder; separately authorize one no-fit probe. | Typed raw-output receipt, including environment failure. |
| G4 | Build/repair only Gaussian grouping and phylogenetic rows passing G1-G3. | Paired frozen-R/Julia evidence plus negative tests. |
| G5 | Add only named, defensible interval routes; report unavailable status where curvature/identifiability fails. | Retained diagnostics, not a blanket coverage claim. |
| G6 | Run targeted recovery only for accepted rows and retain failures. | Pre-run plus approval over 30 minutes; DRAC for campaigns. |
| G7 | Update capability documentation and obtain Rose/Fisher review. | Honest matrix, check-log, after-task report, and Unlazy re-verification. |

Planning and G0 ledger setup are estimated at under one working day once
approved. The programme remains roughly 6-10 weeks with parallel streams, or
10-14 weeks if B1 curvature needs redesign. A future B1 diagnostic is estimated
at 30 seconds with a 60-second hard stop, but is not authorized.

## Key Decisions and Rationale

1. **No scope drift.** Qualify frozen-0.7.0 Destination B rows only. Do not
   fold in 0.7.1, FRK, release, registration, blanket coverage, or unlisted
   capabilities.
2. **Static before numerical.** G0/G1 are the only proposed initial work.
   Fresh authority is needed for every B1/S4 numerical event.
3. **B1 boundary.** A future evaluator must refresh with `obj$fn(theta_star)`
   then use one pinned `TMB::sdreport(..., par.fixed = theta_star,
   getJointPrecision = FALSE, getReportCovariance = FALSE,
   skip.delta.method = TRUE)` only after separate approval. Retain
   `cov.fixed`, `pdHess`, and `gradient.fixed`; never retry.
4. **S4 boundary.** Its earlier run stopped before selected tests during the
   Julia dependency probe. That is diagnostic-only. Reserve and retain a typed
   failure namespace before any future explicitly approved probe.
5. **Multi-lane safety.** The coordination board is the cross-lane entrypoint.
   Do not edit the single `AGENTS.md` snapshot pointer from this lane; it
   would orphan sibling handovers.

## What Was Accomplished

- Preserved the narrow B1 pre-run contract and its no-call/no-retry boundary.
- Recorded the updated frozen-0.7.0 gate plan for Cursor without converting
  the proposal into approval.
- Ran lane preflight and the handoff landing gate. The gate found local-only
  work and one protected untracked HOLD; both are declared below.

## Landing State

`handoff_gate.sh` reports this branch as 85 commits ahead of `origin/main`,
with one untracked protected file and many unrelated local branches. No push,
merge, deletion, or rewrite is authorized by this handover.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| Destination B lane `codex/destination-b-b1-integration-20260910` | yes | no | none | **CARRIED-OVER** -- 85 local commits; preserve the isolated worktree. Resume: `cd /private/tmp/destination-b-b1-integration-20260910 && git status -sb && git log --oneline -12`. |
| B1 static contract `dd2ab502` | yes | no | none | **CARRIED-OVER** -- static/pre-run evidence only; no numerical authority. Resume: `git show --stat dd2ab502`. |
| S4 recorder `97214679c` | yes in another lane | no | none | **CARRIED-OVER / CROSS-LANE** -- absent from this object database; rehydrate its owning lane before touching S4. |
| `docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json` | no | no | none | **PROTECTED / CARRIED-OVER** -- untracked direct-Hessian HOLD. Never stage, edit, delete, or retry it. |
| This handover document | yes after local commit | no | none | **CARRIED-OVER** -- commit locally only unless the maintainer separately authorizes a push. |

**FINDINGS-OF-RECORD: none.** No vault write is authorized by this lane.

## Files Created / Modified

- `docs/dev-log/handover/2026-09-12-cursor-handover.md` -- this updated
  Cursor handover only.

No `AGENTS.md` snapshot change is included: the multi-lane rule requires the
shared coordination board to remain the pointer.

## Cursor Rehydration and First Classification

Run these commands before editing anything:

```sh
cd /private/tmp/destination-b-b1-integration-20260910
bash ~/shinichi-brain/tools/lane_preflight.sh .
git status -sb
git log --oneline -12
sed -n '1,220p' AGENTS.md
sed -n '1,260p' docs/dev-log/handover/2026-09-12-cursor-handover.md
sed -n '1,220p' docs/dev-log/coordination-board.md
```

Then classify against live state:

| Classification | Item |
|---|---|
| **OWED** | Ask the maintainer whether to approve G0. Without approval, do not create a ledger or start G1. |
| **DONE** | B1 static contract/verifier (22/22), earlier Cursor handover, and this updated gate-plan record. |
| **RETRACTED** | Any 0.7.1 parity claim; B1 Wald qualification from the HOLD; S4 parity from the failed probe; automatic retry/replay. |
| **PROTECTED** | Frozen R oracle `b4d5fee…`; B1 HOLD JSON; `.unlazy/**`; unrelated lanes; the `AGENTS.md` snapshot; files outside explicit leases. |

## Toolchain and Safe Verification

Cursor must not assume inherited extensions, terminal configuration, R/TMB
libraries, credentials, or chat. Until G0 is explicitly approved, use read-only
rehydration only. If G0 is approved, it is static ledger work only; do not
invoke R/TMB, a fitter, optimizer, recovery simulation, or `Pkg.test()`.

For the existing B1 contract, safe static checks are:

```sh
cd /private/tmp/destination-b-b1-integration-20260910
julia --startup-file=no --history-file=no --project=. test/test_b1_fixed_point_marginal_curvature_protocol.jl
julia --startup-file=no --history-file=no --project=. tools/verify_b1_fixed_point_marginal_curvature_protocol.jl
git diff --check
```

Never stage the protected HOLD JSON, `.unlazy/**`, unrelated lane files, or an
unapproved capture RDS. Never use `git add -A` or `git add .`.

## Gotchas and Failed Approaches

- The direct B1 `obj$he(theta_star)` error does not say the Hessian is singular
  and cannot establish intervals or parity.
- `getJointPrecision = TRUE` targets joint conditional precision, not the
  requested marginal outer curvature.
- A capture object was transient only; do not invent an RDS path, capture hash,
  data/map hash, DLL identity, or success receipt.
- The S4 record must be retained even when the environment fails before
  selected tests; an empty namespace is not evidence.

## Next Immediate Steps

1. Rehydrate and classify the live lane.
2. Ask the maintainer for explicit G0 authorization. Do not infer it from this
   handover or the planning screenshot.
3. If G0 is approved, create the Unlazy acceptance ledger, lock the frozen
   oracle/protected files/exclusions, and stop for review before G1.
4. If G1 is then approved, perform only static B1/S3b/S4 interface,
   symbolic-alignment, and artifact inventory.
5. Treat every numerical B1/S4 action as a new separate decision.

## How to Resume

Start a fresh Cursor agent in the isolated worktree and paste:

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-12-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
