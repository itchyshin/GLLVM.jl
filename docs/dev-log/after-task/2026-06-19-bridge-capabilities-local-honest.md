# After-task — honest local `bridge_capabilities()` (J2)

Date: 2026-06-19 (Claude / Karpinski, autonomous overnight; coordinated from the
gllvmTMB R-bridge finish push). Branch `claude/jl-bridge-capabilities-20260619`
off `codex/non-gaussian-fitter-gradients` @ 1b42e35. **Un-pushed.** PR #101 / the
GLLVM.jl-integration tree never touched.

## Scope

The local engine's `bridge_fit` (the narrow R→Julia contract on this branch) had
no `bridge_capabilities()`, while the integration engine (#101 tree) exports one.
Added an HONEST `bridge_capabilities()` to the local `src/bridge.jl` so the local
engine carries a capability-introspection surface that reflects **local reality**,
not the wider integration table.

## Outcome

`src/bridge.jl` + `src/GLLVM.jl` (export): `bridge_capabilities()` returns a
NamedTuple matching the integration KEY names, valued for the narrow local
surface (7 families; no mixed-family row — `bridge_fit` rejects mixed outright):
- `fit_no_x` true (all); `fixed_effect_X` false (all, X throws);
  `missing_response` false (all, no mask argument exists);
- `cbind_binomial` true for binomial only (only binomial builds an `N` trial
  matrix);
- `ci_no_x_wald` true for all incl. ordinal (native `confint(::OrdinalFit)`);
  `ci_no_x_profile` false (returns `unsupported`); `ci_no_x_bootstrap` true for
  gaussian only (`fit isa GllvmFit`);
- `ci_mask_*` / `ci_x_*` false; postfit coef/fit_stats/summary/predict/residuals/
  ordination true; **`postfit_simulate` false (all)** — `src/simulate.jl` is a
  placeholder, no post-fit response simulator exists on this branch.

### Two deliberate honesty divergences from the integration table
1. **ordinal Wald = true** locally (integration marks it false): the local engine
   ships native `confint(::OrdinalFit)` and the bridge routes it (probe confirmed
   `status="ok"`, non-empty bounds).
2. **simulate = false** everywhere locally (integration advertises it for
   non-ordinal): the local engine has no post-fit simulator.
Reality wins over matching the shape.

## Checks

- `test/test_bridge_capabilities.jl` (new, wired into `runtests.jl`): pins the
  column key set and every honest value, plus a **behavioural cross-check** so the
  advertised flags cannot drift from reality — binomial+`N` fit succeeds; `X` and
  mixed-family `bridge_fit` throw; ordinal Wald returns `status="ok"`; poisson
  bootstrap stays `unsupported`.
- `julia --project=. test/runtests.jl` → exit 0; new testset 60/60; no
  regressions. Independently smoke-verified the exported honest values.

## Honest scope note

This is engine **contract-completeness** only. Because the gllvmTMB R bridge
targets the *wide* integration engine, R is broader than this narrow local engine
on X/mask/CI — so this does NOT make the local engine a clean R capability-drift
target. The value is that the local engine now advertises what it actually does.

## Follow-up

- Fold this `bridge_capabilities` export into the eventual reconciliation of the
  local engine with PR #101's wide engine (do not duplicate #101's X/mask/simulate
  on this branch).
- `postfit_simulate=false` is the honest flag until `src/simulate.jl` is
  implemented (or #101's simulate lands via reconciliation).
