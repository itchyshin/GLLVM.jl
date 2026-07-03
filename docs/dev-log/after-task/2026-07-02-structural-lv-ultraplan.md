# After-task report: structural LV ultra-plan

Date: 2026-07-02
Task: plan the structural-dependence latent-argument truth matrix across
`gllvmTMB` and `GLLVM.jl`

## Goal

Create a compact but runnable ultra-plan for the next LV arc before any new
compute, source-specific `lv` exposure, or bridge/API widening.

## Files changed

- `docs/dev-log/decisions/2026-07-02-structural-dependence-lv-truth-matrix-ultraplan.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-structural-lv-ultraplan.md`

## Evidence used

- `gllvmTMB/R/brms-sugar.R` source-specific `lv` guard.
- `gllvmTMB/tests/testthat/test-canonical-keywords.R` fail-loud source guard.
- `gllvmTMB/R/julia-bridge.R` and `test-julia-bridge.R` bridge capability gates.
- `GLLVM.jl/src/bridge.jl`, `test_bridge_capabilities.jl`, and
  `test_bridge_mixed.jl` bridge matrix behavior.
- Existing phylo Model A evidence-freeze notes from 2026-07-01.

## Tests / checks

Plan-only documentation change. Run after edits:

```sh
git diff --check
```
## R-parity verdict

No R or Julia parity behavior changed. The plan explicitly requires
`gllvm_julia_capabilities()` and `GLLVM.bridge_capabilities()` reconciliation
before any claim changes.

## Rose verdict

OK for planning. The plan keeps the public story as guarded/parked/point-only:
source-specific `lv = ~ env` remains fail-loud, mixed-family vectors remain
point/postfit only, and non-Gaussian/source-specific LV requires a separate
derivation and ADEMP gate.

## Remaining risks

- The structural random-slope evidence rows are close enough to source-specific
  `lv` wording that future dashboard/docs edits could accidentally overclaim.
- Julia mixed-family CI requests currently return an empty unavailable payload
  with a "not routed" note, while the R bridge fails earlier with a named gate;
  the next bridge slice should decide whether that drift is acceptable.

## Next command

```sh
git diff --check
```
