# Arc 1 Gate 0: Profile-First Source-Specific LV Truth Lock

Date: 2026-07-03

## Decision

Start the next LV arc as a profile-first source-specific LV exposure-decision
arc, not as public grammar exposure and not as new large compute.

The working target is to decide whether source-specific structural
`lv = ~ env` can be exposed, narrowed, or parked for v1. The uncertainty engine
is profile-LR selected-entry evidence. Bootstrap remains secondary diagnostic
only.

## Current State

- PR #165 merged after the local Poisson selected-entry canary fix at head
  `2fdd7a6`; GitHub recorded merge commit `8617ba1`.
- Documenter was green on the refreshed head before merge.
- The GitHub Julia matrix was still reporting in-progress jobs at Gate 0
  closeout time; treat any late CI failure as a follow-up fix, not as evidence
  for source-specific `lv` exposure.
- No Totoro, DRAC, or other large compute is active from this Gate 0 note.
- No source-specific R grammar, bridge route, public fitter, or package API has
  been widened.

## Gate 0 Verdict

Gate 0 is a truth-lock gate:

- source-specific `phylo_latent(..., lv = ~ env)`,
  `spatial_latent(..., lv = ~ env)`,
  `animal_latent(..., lv = ~ env)`, and
  `kernel_latent(..., lv = ~ env)` remain fail-loud / blocked;
- the old population-`B_lv` phylo route remains negative/parked;
- `B_eta_realized` is a changed, realized/design-conditional eta-scale
  diagnostic target, not a rescue label for old `B_lv`;
- `alpha_lv` is an axis/access-effect component and diagnostic input, not the
  interval target for this arc;
- `pd_hessian` and optimizer-convergence aggregates are route-quality fields,
  not the scientific gate for selected-entry S1 truth inclusion;
- mixed-family vectors remain point/postfit only, with no `X`, no `X_lv`, no
  masks, no missing responses, and no CIs;
- profile/bootstrap bridge transport for `X_lv` is not admitted;
- spatial/phylo `unique=` parity is a separate R/TMB-first lane and does not
  unblock source-specific `lv`.

## Evidence Inputs

Four Ultra-Plan audit lanes wrote the starting evidence for this arc:

- `docs/dev-log/audits/2026-07-03-arc1-profile-estimand-audit.md`
- `docs/dev-log/audits/2026-07-03-arc1-bridge-grammar-audit.md`
- `docs/dev-log/audits/2026-07-03-arc1-compute-test-plan.md`
- `docs/dev-log/audits/2026-07-03-arc1-rose-claim-audit.md`

Their consensus is:

- internal closeout wording is allowed;
- public widening is blocked;
- bridge/ledger truth can be clarified without new grammar;
- local evidence is route/canary evidence only;
- Totoro is diagnostic-only;
- DRAC/Nibi is the only claim-bearing denominator;
- Mission Control needs label cleanup around `active_work`, `partial`, dense
  source strings, and stale unconditional CI language.

## Minimal Next Sequence

1. Poll the late PR #165 CI jobs after merge.
   - If green, record the final status.
   - If red, inspect the failed job and patch only the failing surface.
2. Refresh the operating
   truth:
   - record current PR state and commit;
   - keep `ready = 0`, `active = 0`, `queued = 0` unless compute is truly
     running;
   - do not use `active_work` as the visible label for inactive historical or
     guarded rows.
3. Gate 1 local/profile hardening:
   - use focused `test/test_phylo_*_xlv.jl` tests only at first;
   - require finite endpoints, MLE bracketing, truth inclusion, finite LR below
     cutoff, and constrained error below tolerance;
   - do not promote `pd_hessian` to the scientific gate.
4. Gate 2 Totoro diagnostic only after explicit authorization.
5. Gate 3 DRAC claim evidence only after Gate 1 and Gate 2 are clean and the
   manifest is predeclared.

## Stop Rules

Stop before exposure or public wording if any text says or implies:

- source-specific LV support;
- partial support for source-specific LV;
- ready to expose source-specific grammar;
- bootstrap rescue;
- old population-`B_lv` recovery;
- mixed-family CI support;
- bridge profile/bootstrap `X_lv` transport;
- pooled Totoro/DRAC denominators.

Stop compute escalation if the selected-entry target, source/family, entries,
host denominator, pass/fail rule, and rollback rule are not all written before
the run.

## Current Claim

Arc 1 has started. Its current claim is:

> Internal profile-first source-specific LV decision work is underway. Public
> source-specific `lv = ~ env` support remains blocked. No new compute is
> running.
