# R + Julia Bridge Drift Gates

Date: 2026-07-03

Follow-up status, 2026-07-03: the required drift-gate test now exists in the
paired `gllvmTMB` clean worktree at commit `73af9258`, with focused live-path
coverage added in `tests/testthat/test-julia-bridge-live-capabilities.R`. With
`GLLVM_JL_PATH` pointed at this `GLLVM.jl` checkout, the live comparator found
68 drift rows and zero unregistered rows. This is a registered-drift result,
not bridge parity completion.

Second follow-up, 2026-07-03: the selected-profile bridge slice routes no-X
profile CI payloads locally for Gaussian, Poisson, Binomial, NB2, Beta, and
Gamma. The paired live drift test now reports 62 registered drift rows and zero
unregistered rows. Ordinal profile CI, masks, fixed-effect X, mixed-family
vectors, source-specific `lv`, and `unique=` parity remain gated.

Third follow-up, 2026-07-03: paired `gllvmTMB` commit `96028892` routes named
post-fit R `confint(..., method = "profile", parm = ...)` selections into the
Julia bridge `ci_parm` option and adds mocked plus live JuliaCall checks. This
hardens the selected-profile transport path. At that step, the live drift count
remained 62 registered rows and zero unregistered rows.

Fourth follow-up, 2026-07-03: paired `gllvmTMB` commit `fa70b50d` routes
ordinary binomial `cbind(successes, failures)` responses through the R Julia
bridge as success-count `Y` plus trial-count `N` matrices. The live drift test
now reports 61 registered rows, zero unregistered rows, and zero cbind drift
rows. `GJL-GATE-CBIND-BINOMIAL` remains active for non-binomial cbind rows,
invalid cbind counts, and cbind rows combined with separate weights.

Fifth follow-up, 2026-07-03: local `GLLVM.bridge_fit` routes Gaussian
fixed-effect `X` point fits plus Gaussian `X` Wald/profile/bootstrap CI payloads
through the native Gaussian engine. The paired live drift test now reports 57
registered rows and zero unregistered rows, with no Gaussian
`fixed_effect_X` / `ci_x_*` drift rows. Non-Gaussian `X`, masks, mixed-family
vectors, source-specific `lv`, and `unique=` parity remain gated.

Sixth follow-up, 2026-07-04: paired `gllvmTMB` commit `2b233f1f` narrowed the R
capability ledger to the same seven one-part family rows as local
`GLLVM.bridge_capabilities()` and removed the advertised mixed-family vector,
NB1, Ordinal probit, mask, and non-Gaussian `X` admissions. Follow-up
`gllvmTMB` commit `ecde980d` registers the retained-payload postfit simulation
mismatch as `GJL-GATE-POSTFIT-SIMULATE-DRIFT`. At that step, the live
comparator reported 9 drift rows, all gated, and zero unregistered rows. This
is a truth-contract reduction, not full bridge parity.

Seventh follow-up, 2026-07-04: paired `gllvmTMB` commit `fbb0e9be` re-admits
ordinary binomial `cbind(successes, failures)` rows in the current narrowed R
ledger, but only for complete no-X binomial rows marshalled as success-count
`Y` plus trial-count `N`. The live comparator now reports 8 drift rows, all
gated, and zero unregistered rows: six postfit-simulation rows plus Ordinal
Wald CI and Ordinal residual semantics. This is a bridge-transport closure, not
R/Julia parity completion.

Eighth follow-up, 2026-07-04: local `GLLVM.jl` adds `simulate_response` for
conditional in-sample response draws from Gaussian, Poisson, Binomial, NB2,
Beta, and Gamma fits, and `GLLVM.bridge_capabilities()` now reports
`postfit_simulate = true` for those six non-ordinal rows. Ordinal response
simulation remains gated. After the paired R expectation refresh, the live
comparator reports 2 drift rows, both registered: Ordinal Wald CI and Ordinal
residual semantics.

Ninth follow-up, 2026-07-04: the paired `gllvmTMB` ordinal drift-closure slice
admits GLLVM.jl `ordinal` no-X Wald CI payloads and reconstructs
response/Pearson ordinal-score residuals from retained category probabilities.
Ordinal profile/bootstrap CIs, `ordinal_probit()` bridge admission, Ordinal
simulation, masks, mixed-family rows/CIs, non-Gaussian fixed-effect `X`,
source-specific `lv`, and `unique=` parity remain gated. The configured live
bridge file now passes 798/798 and the live comparator reports 0 drift rows and
0 unregistered rows.

## Purpose

This note records the expected drift between the current R-side
`gllvmTMB` bridge ledger and the local `GLLVM.jl` branch
`bridge_capabilities()` surface. Drift is not automatically bad: during the
v1.0 arc it is acceptable only when it is named, scoped, and gated.

## Surfaces Compared

- R side: `gllvmTMB::gllvm_julia_capabilities()` from
  `/Users/z3437171/Dropbox/Github Local/gllvmTMB/R/julia-bridge.R`
  and the focused drift tests from the clean worktree
  `/private/tmp/gllvmtmb-v1-contract-drift-20260703`.
- Julia side: `GLLVM.bridge_capabilities()` from
  `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/src/bridge.jl`
  on branch `claude/jl-bridge-capabilities-20260619`.

## Confirmed Surface Counts

| Surface | Rows | Key boundary |
|---|---:|---|
| R `gllvm_julia_capabilities()` | 7 | Same one-part family rows as local Julia; NB1, ordinal-probit, masks, mixed-family vectors, and non-Gaussian `X` are gated. |
| Julia `bridge_capabilities()` | 7 | Local no-X one-part rows only; omits NB1, ordinal-probit, and mixed-family vector. |
| R gate registry | 20 | `GJL-GATE-*` rows describe R-side deliberate refusals; the current live R-vs-Julia capability drift table is empty. |

## Expected Drift Rows

| Drift | Direction | Status | Gate / owner | Why allowed for now |
|---|---|---|---|---|
| NB1 family row | no live drift after R ledger narrowing | `guarded` | Hopper | R parser can name NB1, but the current capability ledger does not admit it and live calls fail before Julia bridge admission. |
| Ordinal-probit row | no live drift after R ledger narrowing | `guarded` | Hopper + Fisher | R parser can name Ordinal probit, but the current capability ledger does not admit it and live calls fail before Julia bridge admission. |
| Mixed-family vector row | no live drift after R ledger narrowing | `guarded` | `GJL-GATE-MIXED-COMPONENTS` + Rose | R and local Julia both omit the mixed-family row from the capability ledger; direct family vectors fail loud. |
| Fixed-effect `X` | resolved for Gaussian; no non-Gaussian X drift after R ledger narrowing | `partial` / guarded | `GJL-GATE-X-FAMILY`, `GJL-GATE-X-DESIGN` | R and local Julia both advertise Gaussian `X` only. Poisson, Binomial, NB2, Beta, and Gamma `X` remain gated rather than drift rows. |
| Missing-response masks | no live drift after R ledger narrowing | `guarded` | `GJL-GATE-MASK`, `GJL-GATE-MASK-X` | R and local Julia both advertise no mask route. |
| No-X profile CI | resolved for local non-ordinal no-X rows | `partial` | Fisher + Hopper | Local Julia `bridge_fit` now routes profile payloads for Gaussian, Poisson, Binomial, NB2, Beta, and Gamma; Ordinal profile CI remains unavailable through the bridge and no mask/X/mixed/source-specific profile claim follows. |
| No-X bootstrap CI | no live drift after R ledger narrowing | `partial` / `guarded` | Fisher | R and local Julia both advertise bootstrap only for Gaussian. Bootstrap remains secondary. |
| Masked CI | no live drift after R ledger narrowing | `guarded` | `GJL-GATE-MASK-X-CI` | R and local Julia both advertise no mask CI route. |
| Fixed-effect-X CI | resolved for Gaussian; no non-Gaussian X-CI drift after R ledger narrowing | `partial` / guarded | `GJL-GATE-X-CI` | R and local Julia both advertise Gaussian `X` Wald/profile/bootstrap CI payloads only. |
| `cbind` binomial / trial matrix | no live drift after R cbind re-admission | `partial` / guarded | `GJL-GATE-CBIND-BINOMIAL` | R and local Julia both advertise ordinary binomial trial matrices for complete no-X rows. The R gate remains active for non-binomial cbind rows, invalid counts, cbind plus weights, and non-admitted combinations. |
| Ordinal Wald CI | no live drift after R ordinal-Wald admission | `partial` | Fisher + Hopper | R and local Julia both advertise no-X Wald CI for the current `ordinal` bridge row; Ordinal profile/bootstrap and `ordinal_probit()` remain gated. |
| Ordinal residuals | no live drift after R ordinal-score residual admission | `partial` | Fisher + Hopper | R reconstructs response/Pearson ordinal-score residuals from retained category probabilities. This is not a Dunn-Smyth/randomized residual claim and does not admit Ordinal simulation. |
| Postfit simulate | no live drift after local `simulate_response` routing | `partial` | Grace + Hopper | R and local Julia both advertise conditional in-sample simulation for the six non-ordinal one-part rows; Ordinal simulation remains gated on both sides. |

## Non-Drift Rows That Must Stay Locked

- Source-specific `lv = ~ env` remains fail-loud for phylo, spatial, animal,
  and kernel structural keywords.
- Mixed-family CIs remain blocked on both surfaces.
- Source-specific phylo Model A public grammar remains parked unless Shinichi
  explicitly authorizes exposure.
- Totoro/DRAC compute is outside this contract drift step.

## Required Next Test Shape

The first executable code-test slice now lives on the `gllvmTMB` side. It does
not try to make every boolean equal. It:

1. compare R and Julia capability row names and logical columns;
2. mark exact matches as OK;
3. mark expected drifts with gate IDs or branch-reconciliation labels;
4. fail on any unregistered drift;
5. report the compact drift table for Mission Control and after-task reports.

After the paired ordinal drift-closure refresh, the current live-path drift
check in `tests/testthat/test-julia-bridge.R` asserts that the local
`GLLVM.bridge_capabilities()` surface produces exactly 0 drift rows and zero
unregistered rows. The older family-row, mask, non-Gaussian `X`, non-Gaussian
`X` CI, mixed-family vector, cbind-binomial, postfit-simulation,
NB1/Ordinal-probit, Ordinal Wald CI, and Ordinal residual drifts are resolved by
narrowing, explicitly re-admitting, or implementing the local capability rather
than by claiming full parity. Any future bridge widening that changes this
surface must update the R gate registry, this matrix, or both before it can be
treated as v1.0 parity evidence.
