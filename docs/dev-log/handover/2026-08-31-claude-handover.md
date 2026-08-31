# Session Handoff: Core 0.7.0 ordinary latent fit-health follow-up

Meta: 2026-08-31 · from Codex to Claude · isolated local lane

## Critical Context

You are Claude, picking up one bounded optimizer-health follow-up in GLLVM.jl.
The full Core + AGHQ programme is active and incomplete. Do not touch the main
checkout, R 0.7.1 `gllvmTMB_main`, article lanes, or foreign Cursor/Claude work.
The authoritative lane is `/private/tmp/GLLVM.jl-core070-aghq-20260830`, branch
`codex/core070-aghq-20260830`.

## Programme Goal and Approved Plan

**Goal:** bring GLLVM.jl to a verified, Julia-idiomatic implementation of the
approved gllvmTMB R 0.7.0 Core + callable Stage 1a AGHQ contract, frozen at
`b4d5fee64def88bc768dda1f1f77c29b295edd86`; then demonstrate scoped performance
improvements and produce executed, accurate and attractive Documenter pages.
The delivery target is a verified local integration candidate. Preserve the
separate R 0.7.1 `gllvmTMB_main` programme, article lanes and all foreign work.
Release, push, merge and destructive cleanup remain separate authorization gates.

The approved programme has three milestones:

1. **Preserve and establish trustworthy checks.** Census every worktree, branch,
   stash and private lane; archive and restore-test recoverable work; freeze the
   finite capability manifest; repair the parity harness and known phylogenetic,
   Tweedie and Student-t failures; close with Melissa, Noether and Rose review.
2. **Complete Core + AGHQ.** Qualify covariance sources/modes, formula and modifier
   grammar, latent/structured multinomial, data and fitted-object surfaces, the
   separate R bridge, and public Stage 1a AGHQ. Every required manifest row must be
   PASS, PARTIAL or BLOCKED with fresh evidence; a required missing row prevents a
   capability-complete claim.
3. **Performance, Documenter and reconciliation.** Benchmark only correctness-
   qualified models, optimize measured bottlenecks, execute tutorials, inspect the
   rendered site on desktop/mobile, refresh all lane dispositions, update and read
   back Mission Control, and obtain independent Melissa/domain/Rose verdicts.

Ultra Plan owns decomposition and coordination; Unlazy owns runnable leaf and
aggregate gates; Superpowers supplies TDD, systematic debugging, isolated
worktrees, code review and verification-before-completion. Shannon protects lane
ownership, Melissa reconciles actual model/effort/hours/scope, and Rose audits all
claims. Use Totoro for bounded qualification and DRAC arrays for pre-approved
large recovery, coverage and benchmark campaigns. Do not run on DRAC login nodes.
The original allowance was 120-215 aggregate agent-hours and remains an estimate,
not evidence of completion.

**Claude must begin by invoking Ultra Plan to reconcile this programme against the
current repository, retained receipts and Mission Control.** Replan remaining work
without erasing the frozen scope, preservation rules or evidence gates. The narrow
optimizer-health follow-up below is the next OWED slice, not permission to claim
that Milestone 1 or the wider programme is complete.

`COV-ORD-LATENT-BARE` is almost qualified. Frozen R, Julia formula and public
`engine="julia"` fits are healthy and all four routes agree within roughly 1e-7
or better. The direct native fit is the only red gate: `converged=false`, gradient
`1.6741e-6`, despite the frozen contract allowing a health-report ceiling of
`1e-4`; its requested optimizer target is `g_tol=1e-7`. Do not widen a tolerance
or drop the convergence requirement.

## What Was Accomplished

- Froze the p3/n18/K1 seven-coordinate invariant contract.
- Demonstrated public Gaussian explicit-`unique=false` bridge parity:
  delta log likelihood `5.01e-13`, loading-crossproduct `5.90e-8`.
- Demonstrated the formula route is healthy and same-model.
- Retained five Totoro attempts and classified every failure.
- Passed all eight negative controls and the shared-point dependency.

See `docs/dev-log/core070/latent-bare-model-evidence.json` and
`docs/dev-log/after-task/2026-08-31-core070-latent-bare-partial.md`.

## Current Working State

- Working: frozen R fit, Julia formula fit, public R bridge fit, invariant
  comparisons, negative controls and oracle checks.
- In progress: none; this Codex cycle is intentionally stopped.
- Blocked: direct native default-mean optimizer health only.

## Key Decisions & Rationale

- Compare `lambda*lambda'`, never signed loadings.
- Treat explicit `unique=false` public Gaussian transport as same-model. The
  separate default-unique bridge boundary still drops auto-Psi and is different.
- Diagnose BackTracking versus Hager-Zhang at an identical start before changing
  code. Formula's explicit mean design uses the latter and converged.
- No release, push, merge, destructive cleanup, DRAC campaign or full suite.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---:|---|
| GLLVM.jl `codex/core070-aghq-20260830` (commit recorded after this document) | yes | no | none | CARRIED-OVER |

**CARRIED-OVER reason:** local integration lane; the maintainer has not authorized
a push, merge or release. Resume in the existing local lane. The handoff gate also
reports the programme-wide Unlazy ledgers as unmet because the approved programme
is still active; this document does not relabel them complete or abandoned.

FINDINGS-OF-RECORD: the repo evidence and this committed handover are the durable
record; no brain-vault finding was written.

Closure receipts:

- GLLVM.jl evidence commit: `239dbd238cbd8c50df9109ce08a15f6702307aa7`
  (local only, unpushed).
- Restore-tested checkpoint:
  `/Users/z3437171/local-scratch/preservation/core070-execution-20260831-165253-latent-bare`;
  the Git bundle and five-attempt tarball passed SHA-256 and readback checks.
- Mission Control commit: `761222e` in the local-only Shinichi repository.
  Canonical server verification passed and `/p/gllvmTMB/status.json` returned HTTP
  200 containing both `239dbd23` and `PARTIAL_DIRECT_NATIVE_FIT_HEALTH_UNPAID`.
- Noether's independent final review approved this PARTIAL handover with no
  actionable P0-P3 findings.

## Files Created / Modified

- `docs/dev-log/core070/latent-bare-model-contract.json`
- `docs/dev-log/core070/latent-bare-model-leaf.md`
- `docs/dev-log/core070/latent-bare-model-evidence.json`
- `tools/core070_latent_bare_model.R`
- `tools/core070_latent_bare_model.jl`
- `tools/core070_verify_latent_bare_model.py`
- `test/test_core070_latent_bare_contract.py`
- `docs/dev-log/after-task/2026-08-31-core070-latent-bare-partial.md`
- `docs/dev-log/handover/2026-08-31-claude-handover.md`
- `docs/dev-log/check-log.md`

## Next Immediate Steps

1. Run lane preflight and classify this handover's requests as `OWED`, `DONE`,
   `RETRACTED`, or `PROTECTED`.
2. Reproduce the direct default-mean source fit and an explicit trait-intercept X
   fit from one identical parameter vector. Record objective, gradient, line-search
   and stopping reason.
3. Decide whether the default-mean path should use the existing Hager-Zhang policy.
   If yes, use TDD: preserve the red attempt05, add a narrow regression, make the
   minimal optimizer-selection repair, and rerun the exact frozen gate on Totoro.
4. Ask Codex or another live-toolchain lane to run the Totoro replay if Claude's
   environment cannot execute Julia/RCall. Do not claim PASS from pure review.

## Blockers / Open Questions

Does the BackTracking line search stop because of objective roundoff on this
default-mean parameterization, as the explicit-design source path previously did?
This must be demonstrated, not assumed.

## Gotchas & Failed Approaches

- Keep parent `LD_PRELOAD` only until R starts; unset it before `julia_setup` because
  JuliaCall adds its own child preload.
- Use both retained Manifests: a parity Manifest for RCall and a root package
  Manifest for GLLVM dependencies.
- Call `gllvm_julia_setup(jl_path=<current lane>)`; `JULIA_PROJECT` alone does not
  set the public R bridge path.
- Import `Distributions` before using `Normal()` in the Julia runner.
- Attempts01-05 are retained under `.unlazy/core070-aghq/latent-bare-model-0*`.

## Mission Control

| Repo | Branch/main | CI / evidence | What shipped | Plan by leverage |
|---|---|---|---|---|
| GLLVM.jl | `codex/core070-aghq-20260830` local | latent-bare PARTIAL; wider programme draft | exact bridge parity plus optimizer blocker | diagnose identical-start line search, then one live replay |
| gllvmTMB 0.7.0 | frozen `b4d5fee...` | oracle before/after PASS | read-only reference | do not edit |
| gllvmTMB 0.7.1 | separate protected lane | unchanged | none | preserve |

## How to Resume

```sh
cd /private/tmp/GLLVM.jl-core070-aghq-20260830
python3 /Users/z3437171/Dropbox/Github\ Local/Shinichi/tools/lane_preflight.sh .
git status --short
git log -3 --oneline
python3 test/test_core070_latent_bare_contract.py
```

Then read the evidence and after-task report above. The current strict verifier is
expected to fail until the direct native fit-health gate passes:

```sh
PYTHONPATH=tools python3 tools/core070_verify_latent_bare_model.py \
  --state .unlazy/core070-aghq/latent-bare-model-05 --self-test
```

Read AGENTS.md and docs/dev-log/handover/2026-08-31-claude-handover.md. Run the
handover rehydration steps, reconcile them with the current git state, then
continue only the OWED Next Immediate Steps.
