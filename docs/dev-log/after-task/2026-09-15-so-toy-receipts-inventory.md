# Inventory — optional paired SO toy / light RCall receipts (PARTIAL native-Wald families)

**Date:** 2026-09-15  
**Repo:** GLLVM.jl (`main` tip inventory; Student-t fixed-ν Wald may still be on open [#367](https://github.com/itchyshin/GLLVM.jl/pull/367))  
**Scope:** Docs-only inventory. No engine edits.  
**Question:** For each holdout family now **PARTIAL (native Wald)**, what exists vs is still missing for (a) Julia `test_second_order_*_ci` smoke, (b) optional **paired second-order toy** (`tools/core070_second_order` cell and/or `GLLVM_PARITY_TESTS=1` SE Δ block in a second-order test, pattern: `test/test_second_order_tweedie_grouped_ci.jl`, `test/test_second_order_delta_followup.jl`), (c) **light RCall** first-order logLik cells (`test/parity/*`), (d) bridge admit notes where relevant.

**Authoritative holdout table:** `docs/dev-log/core070/second-order-holdouts-2026-09-04.md` (lines 43–49).

---

## Summary table

| Family | Native `second_order_*_ci` | Paired SO toy / R SE Δ | Light RCall (1st-order logLik) | Wald after-task (2026-09-15) |
| --- | --- | --- | --- | --- |
| **OrdinalPerTrait** | **EXISTS** | **MISSING** | **EXISTS** (per-trait ordinal) | **EXISTS** |
| **Lognormal** | **EXISTS** | **MISSING** | **EXISTS** | **EXISTS** |
| **TruncPois** | **EXISTS** | **MISSING** | **EXISTS** | **EXISTS** (with Lognormal+Trunc* PR #361) |
| **TruncNB2** | **EXISTS** | **MISSING** | **EXISTS** | **EXISTS** (with Lognormal+Trunc* PR #361) |
| **Multinomial FE** | **EXISTS** | **MISSING** | **EXISTS** (FE-only fid 16) | **EXISTS** |
| **Student-t fixed-ν** | **MISSING** | **MISSING** | **EXISTS** (fixed ν) | **MISSING** (Wald wiring on #367, not on `main`) |

---

## Per-family detail (paths)

### OrdinalPerTrait (`OrdinalPerTraitFit` / `OrdinalPerTraitCovFit`)

| Receipt type | Status | Path / note |
| --- | --- | --- |
| Native Wald CI smoke | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/test_second_order_ordinal_pertrait_ci.jl` (included from `test/runtests.jl`) |
| `core070_second_order` cell | **MISSING** | No entry in `tools/core070_second_order/cells.jl` (only batch-1 + delta/tweedie/cloglog families) |
| Paired SO test (`GLLVM_PARITY_TESTS`) | **MISSING** | No RCall / `common.jl` include in ordinal second-order test |
| Light RCall logLik parity | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/parity/test_ordinal_probit_parity.jl` (`fit_ordinal_gllvm_pertrait`; via `test/parity/runparity.jl`) |
| Bridge light Δ | **OWED** (not SO) | Bridge ordinal paths in `test/test_bridge_x.jl`, `test/test_ordinal_pertrait.jl`; CI lift blocked on foreign #357 |
| After-task | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/docs/dev-log/after-task/2026-09-15-ordinal-pertrait-wald-ci.md` |

### Lognormal (`LognormalFit`)

| Receipt type | Status | Path / note |
| --- | --- | --- |
| Native Wald CI smoke | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/test_second_order_lognormal_ci.jl` |
| `core070_second_order` cell | **MISSING** | — |
| Paired SO test | **MISSING** | — |
| Light RCall logLik parity | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/parity/test_lognormal_parity.jl`; historical run notes in `docs/dev-log/after-task/2026-08-24-lognormal-truncpois-parity-cells.md` |
| Bridge light Δ | **OWED** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/test_bridge_lognormal.jl` (`light RCall Δ still OWED`); golden in `test/test_bridge_capabilities.jl` |
| After-task | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/docs/dev-log/after-task/2026-09-15-lognormal-wald-ci.md` (covers Lognormal + Trunc*) |

### Truncated Poisson (`TruncatedPoissonFit` / TruncPois)

| Receipt type | Status | Path / note |
| --- | --- | --- |
| Native Wald CI smoke | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/test_second_order_truncpois_ci.jl` |
| `core070_second_order` cell | **MISSING** | — |
| Paired SO test | **MISSING** | — |
| Light RCall logLik parity | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/parity/test_truncated_poisson_parity.jl` |
| Bridge light Δ | **OWED** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/test_bridge_truncated_poisson.jl` |
| After-task | **EXISTS** | Same as Lognormal row (`2026-09-15-lognormal-wald-ci.md`) |

### Truncated NB2 (`TruncatedNegBin2Fit` / TruncNB2)

| Receipt type | Status | Path / note |
| --- | --- | --- |
| Native Wald CI smoke | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/test_second_order_truncnb2_ci.jl` |
| `core070_second_order` cell | **MISSING** | — |
| Paired SO test | **MISSING** | — |
| Light RCall logLik parity | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/parity/test_truncated_nbinom2_parity.jl` |
| Bridge light Δ | **MISSING** (no dedicated bridge test file) | No `test_bridge_truncated_nbinom2.jl`; trunc admit not in bridge parity slice searched |
| After-task | **EXISTS** | `2026-09-15-lognormal-wald-ci.md` |

### Multinomial FE (`MultinomialFit`, v1 no LV)

| Receipt type | Status | Path / note |
| --- | --- | --- |
| Native Wald CI smoke | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/test_second_order_multinomial_ci.jl` (no-X + +X Wald) |
| `core070_second_order` cell | **MISSING** | — |
| Paired SO test | **MISSING** | — |
| Light RCall logLik parity | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/parity/test_multinomial_parity.jl` (seed 57, FE-only; identity `docs/dev-log/decisions/2026-08-18-multinomial-identity.md`) |
| Bridge | **N/A / untouched** | Second-order test header: bridge untouched |
| After-task | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/docs/dev-log/after-task/2026-09-15-multinomial-wald-ci.md`, board tip `2026-09-15-true-parity-366-merged-board.md` |

### Student-t fixed-ν (`StudentTFit`, `nu` fixed)

| Receipt type | Status | Path / note |
| --- | --- | --- |
| Native Wald CI smoke | **MISSING** on `main` | No `test/test_second_order_studentt_ci.jl` in tree; `StudentTFit` not in `src/confint_family.jl` union grep on `main` |
| Open work | **IN FLIGHT** | [#367](https://github.com/itchyshin/GLLVM.jl/pull/367) branch `cursor/studentt-fixed-nu-wald-ci-a0ce` per `docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md` |
| `core070_second_order` cell | **MISSING** | Holdouts: `Student-t fixed-ν` = first-order parity only, no SO cell (`second-order-holdouts-2026-09-04.md` line 42) |
| Paired SO test | **MISSING** | — |
| Light RCall logLik parity | **EXISTS** | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/parity/test_studentt_parity.jl`; frozen oracle `NATIVE-10-STUDENT` in `docs/dev-log/after-task/2026-09-14-destb-g7-frozen-r-smoke-handoff.md` |
| Student-t free-ν | **OUT** (not this inventory) | No Wald / no SO pairing per holdouts §3 |
| After-task (Wald) | **MISSING** | No `2026-09-15-*student*` after-task on `main` |

---

## Reference pattern (what “paired SO toy EXISTS” looks like)

| Pattern | Path |
| --- | --- |
| Julia-only SO smoke + optional live R SE Δ | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/test_second_order_tweedie_grouped_ci.jl` |
| Delta follow-up batch (cells + smokes) | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/test/test_second_order_delta_followup.jl`, `tools/core070_second_order/cells.jl` (`delta_lognormal`, `delta_gamma`), `tools/core070_second_order/smoke_delta_*_eoo.jl` |
| Programme inventory (pre–native-Wald gap) | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/docs/dev-log/after-task/2026-09-14-second-order-parity-inventory.md` |

---

## Claim boundary

- **PARTIAL (native Wald)** = Julia `confint(...; method=:wald)` wired and smoke-tested; **≠** programme §7 second-order parity; **≠** paired R SE/vcov/Wald toy unless a row above says **EXISTS**.
- All six families in the summary table still lack a **paired SO toy** receipt in-repo as of this inventory.
- Bridge **CI** lift for several families remains gated on foreign #357 (see Wald after-tasks).

## Follow-up (optional, not started here)

1. Add `core070_second_order` cells + gated R blocks mirroring `tweedie_fixed` / `delta_*` once parameterization and twin SE routes are agreed.
2. Merge #367 and add `test/test_second_order_studentt_fixed_nu_ci.jl` + after-task.
3. Refresh `test/test_bridge_capabilities.jl` golden if bridge CI flags moved after native Wald (#361/#366).
