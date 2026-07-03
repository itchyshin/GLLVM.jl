# R + Julia Bridge Drift Gates

Date: 2026-07-03

## Purpose

This note records the expected drift between the current R-side
`gllvmTMB` bridge ledger and the local `GLLVM.jl` branch
`bridge_capabilities()` surface. Drift is not automatically bad: during the
v1.0 arc it is acceptable only when it is named, scoped, and gated.

## Surfaces Compared

- R side: `gllvmTMB::gllvm_julia_capabilities()` from
  `/Users/z3437171/Dropbox/Github Local/gllvmTMB/R/julia-bridge.R`
  on branch `codex/r-bridge-grouped-dispersion` at `5d15209e`.
- Julia side: `GLLVM.bridge_capabilities()` from
  `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/src/bridge.jl`
  on branch `claude/jl-bridge-capabilities-20260619` at `b093dc16`.

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
| No-X profile CI | R broader than local Julia | `partial` / `guarded` | Fisher + Hopper | R ledger can route profile payloads for selected rows; local Julia `bridge_fit` returns unsupported profile payloads. |
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

The next code-test slice should not try to make every boolean equal. It should:

1. compare R and Julia capability row names and logical columns;
2. mark exact matches as OK;
3. mark expected drifts with gate IDs or branch-reconciliation labels;
4. fail on any unregistered drift;
5. print a compact drift table for Mission Control and after-task reports.

This belongs in a focused test/doc slice before any bridge widening.
