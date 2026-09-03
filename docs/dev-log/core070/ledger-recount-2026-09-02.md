# Ledger Recount — 2026-09-02

## Full counting output

```
TOTAL=769 REQUIRED_CORE=379 COMPAT_ADAPTER=126 REJECTED=182 INTENTIONALLY_EXCLUDED=82
REQUIRED_DEF=A row is 'required' if its classification is either 'required_core' or 'compatibility_adapter'.
REQUIRED=505 BOUND=285 DISPOSITIONED=220 FREE=0
DISP BLOCKED_NEEDS_JULIA_SURFACE=121
DISP BLOCKED_SPEC_DEFECT=44
DISP PARTIAL_PARITY_DEFECT_PENDING_DECISION=8
DISP PARTIAL_PENDING_DECISION_OPEN_QUESTION=47
XTAB aghq BLOCKED_SPEC_DEFECT=22
XTAB aghq None=7
XTAB covariance BLOCKED_NEEDS_JULIA_SURFACE=11
XTAB covariance BLOCKED_SPEC_DEFECT=11
XTAB covariance None=17
XTAB data None=28
XTAB family None=21
XTAB family PARTIAL_PENDING_DECISION_OPEN_QUESTION=1
XTAB fit-input BLOCKED_NEEDS_JULIA_SURFACE=3
XTAB fit-input None=6
XTAB fit-input PARTIAL_PENDING_DECISION_OPEN_QUESTION=2
XTAB inference BLOCKED_NEEDS_JULIA_SURFACE=1
XTAB inference None=63
XTAB isdm None=20
XTAB masks-known None=9
XTAB namespace BLOCKED_NEEDS_JULIA_SURFACE=64
XTAB namespace None=71
XTAB namespace PARTIAL_PARITY_DEFECT_PENDING_DECISION=1
XTAB namespace PARTIAL_PENDING_DECISION_OPEN_QUESTION=26
XTAB postfit BLOCKED_NEEDS_JULIA_SURFACE=41
XTAB postfit BLOCKED_SPEC_DEFECT=11
XTAB postfit None=30
XTAB postfit PARTIAL_PARITY_DEFECT_PENDING_DECISION=4
XTAB postfit PARTIAL_PENDING_DECISION_OPEN_QUESTION=14
XTAB postfit-policy BLOCKED_NEEDS_JULIA_SURFACE=1
XTAB postfit-policy None=13
XTAB postfit-policy PARTIAL_PARITY_DEFECT_PENDING_DECISION=3
XTAB postfit-policy PARTIAL_PENDING_DECISION_OPEN_QUESTION=4
```

## Definition of required

**A row is 'required' if its classification is either 'required_core' or 'compatibility_adapter'.**

Evidence: `LOOP/core070-checkpoint.md:2090` states "LEDGER: 505 required = 285 bound + 220 dispositioned," and line 2086 documents the reclassification reducing from 533 to 505 via "83 rows reclassified out per verified proposals." The computation 379 (required_core) + 126 (compatibility_adapter) = 505 confirms this exact definition.

## Reconciliation: 505 / 379 / 769 and subgroup counts

**The scout's count of 769 total rows is correct.**

**The scout's breakdown by classification is correct:**
- 379 required_core
- 126 compatibility_adapter (implicitly part of "required" per the definition above)
- 182 rejected
- 82 intentionally_excluded
- Total: 769 ✓

**The handover's claim of 505 required rows is correct.**

The apparent contradiction arises from the scout reporting 379 required_core as a separate line without summing to the handover's inclusive total. The scout's raw statement "379 required_core" is accurate; the scout did not explicitly state the compatibility_adapter count as a separate row, so the 505 total (379 + 126) is deterministic from the ledger JSON but was not surfaced in the scout's summary prose. No contradiction exists in the ledger itself.

**Bound / dispositioned subgroup reconciliation:**

| Source | REQUIRED | BOUND | DISPOSITIONED | FREE |
|--------|----------|-------|---------------|------|
| Handover | 505 | 285 | 220 | 0 |
| Current recount | 505 | 285 | 220 | 0 |
| Match | ✓ | ✓ | ✓ | ✓ |

**Disposition subgroup reconciliation:**

| Name | Handover | Recount | Match |
|------|----------|---------|-------|
| BLOCKED_NEEDS_JULIA_SURFACE | 121 | 121 | ✓ |
| PARTIAL_PENDING_DECISION_OPEN_QUESTION | 47 | 47 | ✓ |
| BLOCKED_SPEC_DEFECT | 44 | 44 | ✓ |
| PARTIAL_PARITY_DEFECT_PENDING_DECISION | 8 | 8 | ✓ |

All counts reproduce exactly. The ledger is deterministic and consistent.
