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
hardens the selected-profile transport path, but the live drift count remains
62 registered rows and zero unregistered rows.

## Purpose

This note records the expected drift between the current R-side
`gllvmTMB` bridge ledger and the local `GLLVM.jl` branch
`bridge_capabilities()` surface. Drift is not automatically bad: during the
v1.0 arc it is acceptable only when it is named, scoped, and gated.

## Surfaces Compared

- R side: `gllvmTMB::gllvm_julia_capabilities()` from
  `/Users/z3437171/Dropbox/Github Local/gllvmTMB/R/julia-bridge.R`
  and the focused drift tests from the clean worktree
  `/private/tmp/gllvmtmb-v1-contract-drift-20260703` at `96028892`.
- Julia side: `GLLVM.bridge_capabilities()` from
  `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/src/bridge.jl`
  on branch `claude/jl-bridge-capabilities-20260619` at `fc8af22c`.

## Confirmed Surface Counts

| Surface | Rows | Key boundary |
|---|---:|---|
| R `gllvm_julia_capabilities()` | 10 | Includes NB1, ordinal-probit, and a narrow mixed-family vector row. |
| Julia `bridge_capabilities()` | 7 | Local no-X one-part rows only; omits NB1, ordinal-probit, and mixed-family vector. |
| R gate registry | 20 | `GJL-GATE-*` rows describe R-side deliberate refusals. |

## Expected Drift Rows

| Drift | Direction | Status | Gate / owner | Why allowed for now |
|---|---|---|---|---|
| NB1 family row | R broader than local Julia | `partial` / branch drift | Hopper | R bridge ledger has NB1 rows; local Julia `bridge_fit` family table does not. Needs branch reconciliation before public twin parity. |
| Ordinal-probit row | R broader than local Julia | `partial` / branch drift | Hopper + Fisher | R bridge ledger includes `ordinal_probit`; local Julia `bridge_fit` has `ordinal` only. Per-trait/probit labels and CI semantics need reconciliation. |
| Mixed-family vector row | R broader than local Julia | `point-only` / `guarded` | `GJL-GATE-MIXED-COMPONENTS` + Rose | R admits complete balanced no-X/no-mask/no-CI mixed vectors; local Julia rejects family vectors outright. |
| Fixed-effect `X` | R broader than local Julia | `partial` / branch drift | `GJL-GATE-X-FAMILY`, `GJL-GATE-X-DESIGN` | R routes complete one-part `X` rows for selected families. Local Julia rejects `X`; no local parity claim. |
| Missing-response masks | R broader than local Julia | `partial` / branch drift | `GJL-GATE-MASK-X` for mask+X | R routes selected no-X mask rows. Local Julia has no mask argument. |
| No-X profile CI | resolved for local non-ordinal no-X rows | `partial` | Fisher + Hopper | Local Julia `bridge_fit` now routes profile payloads for Gaussian, Poisson, Binomial, NB2, Beta, and Gamma; Ordinal profile CI remains unavailable through the bridge and no mask/X/mixed/source-specific profile claim follows. |
| No-X bootstrap CI | R broader than local Julia except Gaussian | `partial` / `guarded` | Fisher | R ledger can route selected rows; local Julia routes bootstrap only for Gaussian. Bootstrap remains secondary. |
| Masked CI | R broader than local Julia | `partial` / `guarded` | `GJL-GATE-MASK-X-CI` | R no-X masked CI payloads are selected-row partial; local Julia has no masks. |
| Fixed-effect-X CI | R broader than local Julia | `partial` / `guarded` | `GJL-GATE-X-CI` | R selected complete-response X CI rows are partial; local Julia has no X. |
| `cbind` binomial / trial matrix | Local Julia broader than R | `guarded` | `GJL-GATE-CBIND-BINOMIAL` | Julia accepts trial matrix `N`; R bridge still rejects two-column `cbind(successes, failures)` marshaling. |
| Ordinal Wald CI | Local Julia broader than R ledger | `guarded/partial` | Fisher | Local Julia reports Wald CI for `OrdinalFit`; R ledger keeps per-trait ordinal CI endpoints gated. Must not promote broad ordinal CI parity. |
| Ordinal residuals | Local Julia broader than R ledger | `guarded` | `GJL-GATE-ORDINAL-RESIDUAL` | Local Julia capability says residuals exist for local fit objects; R bridge deliberately rejects ordinal response/Pearson residual semantics. |
| Postfit simulate | R broader for non-ordinal retained payload rows; local Julia bridge says false | `partial` / branch drift | Grace + Hopper | R reconstructs conditional simulations from retained payloads for selected rows; local Julia `bridge_capabilities()` reports no post-fit response simulator. |

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

The live-path follow-up in
`tests/testthat/test-julia-bridge-live-capabilities.R` now asserts that the
current local `GLLVM.bridge_capabilities()` surface produces 62 registered drift
rows, including the NB1, ordinal-probit, mixed-family vector, binomial cbind,
and ordinal CI rows. The old six no-X profile-CI drift rows are resolved for
local non-ordinal no-X bridge rows. The same file also checks the R post-fit
selected-profile `parm` transport against the local Julia bridge. Any future
bridge widening that changes this surface must update the R gate registry, this
matrix, or both before it can be treated as v1.0 parity evidence.
