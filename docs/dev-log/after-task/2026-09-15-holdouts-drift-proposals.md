# Audit and proposed updates: second-order holdouts doc vs merged main

Date: 2026-09-15  
Auditor: Subagent search and consistency review  
Target file: `docs/dev-log/core070/second-order-holdouts-2026-09-04.md`  
Baseline: `origin/main` @ `c459751bf` (including merged #355, #356, #361, #362, #364, #365, #366, #368, #369, #370) and open PR #367

## Summary of findings

The holdouts document was partially updated across PRs #356 (Tweedie grouped), #361 (Lognormal/Truncated), #362 (Ordinal per-trait), and #366 (Multinomial FE). Several rows and summary counts remain stale or out of sync with current repository reality.

### Stale items identified

1. **Summary counts line (line 33):**
   - Current text: `OUT 7 · PARTIAL 5 · NOT ATTEMPTED 1`
   - Reality on `main`: `OUT 5 · PARTIAL 10 · NOT ATTEMPTED 0`
   - Cause: Summary arithmetic was not recalculated when Tweedie moved from NOT ATTEMPTED to PARTIAL (#356), Lognormal/TruncPois/TruncNB2 were split into three PARTIAL rows (#361), and Multinomial was split from BB shared-phi (#366).

2. **Table 1: Student-t row (line 10):**
   - Current text: `Student-t ν | Nonlinear boundary; Wald SE pathology (panel finding 4) | Batch 1 excluded`
   - Reality: Fails to distinguish fixed nu from free nu. Fixed nu has verified logLik parity and native Wald in PR #367. Free nu remains held out due to boundary pathology.

3. **Table 1: Delta-lognormal, Delta-Gamma row (line 13):**
   - Current text: `In _CIFit but not reached in 20-cell window | Follow-up batch`
   - Reality: The follow-up batch was attempted in PR #347 (`test/test_second_order_delta_followup.jl` and `smoke_delta_*_eoo.jl`). Paired D1 comparison failed because Julia defaults to shared scalar dispersion while R estimates per-trait dispersion. A decision is pending maintainer acceptance of option A (`accept delta dispersion A`).

4. **Table 1: Realistic Gaussian grid row (line 15):**
   - Current text: `Julia confint reports σ + Λ SEs; R pairs trait intercept t1…tp | Estimand mismatch`
   - Reality: The estimand mismatch was resolved on 2026-09-04 by the intercept-X patch, and 8/8 realistic Gaussian cells pass SE D1 (max rel delta SE beta = 2.2e-5). Table 2 reflects this repair, but Table 1 was left in its pre-repair state.

5. **Table 2: Student-t fixed-nu row (line 42):**
   - Current text: `Student-t fixed-ν | PARTIAL | First-order logLik parity exists; not in batch-1 or 20-cell SO window | Parity fixtures; no core070_second_order cell`
   - Reality in PR #367: `StudentTFit` fixed nu is wired into `_FamilyFit` and `_family_ci` (29/29 tests pass in `test/test_second_order_studentt_ci.jl`). Once merged, status becomes `PARTIAL (native Wald)`.

6. **Table 2: Student-t free-nu row (line 41):**
   - Current text: Reason cites `StudentTFit ∉ _CIFit`.
   - Reality in PR #367: `StudentTFit` is added to `_FamilyFit` / `_CIFit`, and `_family_ci` explicitly throws an `ArgumentError` when `fit.estimated_nu == true`.

7. **Table 2: Delta-lognormal, Delta-Gamma row (line 48):**
   - Current text: Reason cites `absent from 20-cell window`.
   - Reality: Second-order cells exist in `tools/core070_second_order/`; comparison is blocked on dispersion parameterisation alignment (Julia shared vs R per-trait), documented in `decisions/2026-09-15-delta-dispersion-alignment-pending.md`.

## Proposed exact row edits

Do not apply directly to `docs/dev-log/core070/second-order-holdouts-2026-09-04.md` while Ada is refreshing the board post-#367. Integrate these edits during the post-#367 board synchronization.

### Edit A: Summary line (line 33)

```markdown
<<<<
**Summary:** OUT **7** · PARTIAL **5** · NOT ATTEMPTED **1** (plus batch-1 NB2 noted below; Multinomial FE now PARTIAL)
====
**Summary:** OUT **5** · PARTIAL **10** · NOT ATTEMPTED **0** (plus batch-1 NB2 noted below; Student-t fixed-ν and Multinomial FE now PARTIAL)
>>>>
```

### Edit B: Table 1 updates (lines 10, 13, 15)

```markdown
<<<<
| Student-t ν | Nonlinear boundary; Wald SE pathology (panel finding 4) | Batch 1 excluded |
====
| Student-t fixed-ν | First-order logLik parity; native Wald in `_FamilyFit` (2026-09-15, fixed ν only) | Native fixed-ν Wald wired; paired SO cell not attempted |
| Student-t free ν | Nonlinear boundary; Wald SE pathology (panel finding 4) | Excluded; `_family_ci` throws ArgumentError |
>>>>

<<<<
| Delta-lognormal, Delta-Gamma | In `_CIFit` but not reached in 20-cell window | Follow-up batch |
====
| Delta-lognormal, Delta-Gamma | Julia shared scalar dispersion vs R per-trait dispersion (PR #347 measured FAIL) | Decision pending: `accept delta dispersion A` |
>>>>

<<<<
| Realistic Gaussian grid | Julia `confint` reports σ + Λ SEs; R pairs trait intercept `t1…tp` | **Estimand mismatch** — not a tolerance failure |
====
| Realistic Gaussian grid | Intercept-`X` patch cleared estimand mismatch (2026-09-04) | Repaired: 8/8 cells pass SE D1; outside toy batch-1 |
>>>>
```

### Edit C: Table 2 updates (lines 41, 42, 48)

```markdown
<<<<
| Student-t ν (free) | OUT | Wald SE pathology at ν boundary (§3); `StudentTFit` ∉ `_CIFit`; no SO pairing | Contract §3 lines 120–123; `src/confint_family.jl:44-45` |
| Student-t fixed-ν | PARTIAL | First-order logLik parity exists; not in batch-1 or 20-cell SO window | Parity fixtures; no `core070_second_order` cell |
====
| Student-t ν (free) | OUT | Wald SE pathology at ν boundary (§3); `_family_ci` rejects `estimated_nu=true`; no SO pairing | Contract §3 lines 120–123; `test/test_second_order_studentt_ci.jl` |
| Student-t fixed-ν | **PARTIAL (native Wald)** | `StudentTFit` ∈ `_FamilyFit` + `_family_ci` when `estimated_nu == false` (2026-09-15); shared + species σ; no paired SO toy cell yet; bridge untouched | `test/test_second_order_studentt_ci.jl`; `src/confint_family.jl` |
>>>>

<<<<
| Delta-lognormal, Delta-Gamma | OUT | `DeltaLogNormalFit`/`DeltaGammaFit` ∈ `_CIFit` but absent from 20-cell window | `second-order-batch-2026-09-03.md` cell list |
====
| Delta-lognormal, Delta-Gamma | OUT (paired SO) / PARTIAL (native Wald) | SO wiring landed in PR #347; D1 comparison fails on dispersion parameterisation (Julia shared vs R per-trait); pending decision A | `after-task/2026-09-15-second-order-delta-followup.md`; `decisions/2026-09-15-delta-dispersion-alignment-pending.md` |
>>>>
```
