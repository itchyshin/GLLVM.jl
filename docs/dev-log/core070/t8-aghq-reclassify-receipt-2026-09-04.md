# T8 AGHQ reclassify receipt — 2026-09-04 (Option A S3, D4 DEFAULTED)

Decision: D4 DEFAULTED 2026-09-04 (`maintainer-decision-set-2026-09-03.md`) — reclassify 8
unreachable helper-contract rows; bind the 14 public-fit rows in a follow-on slice.

## Rows reclassified (8)

| source_id | reason (short) |
|---|---|
| `aghq/AGHQ-POLICY-BAD-COLUMNS` | Hand-truncated gate; never from real fit |
| `aghq/AGHQ-POLICY-BAD-DIMENSION` | Forces q=NA; d_B always integer in production |
| `aghq/AGHQ-POLICY-BAD-TRAITS` | Forces n_traits=NA |
| `aghq/AGHQ-POLICY-EMPTY-GATE` | Empty gate; z_B always present when eligible |
| `aghq/AGHQ-POLICY-MISSING-GATE` | gate_table=NULL |
| `aghq/AGHQ-POLICY-NO-QUADRATURE` | route=laplace unreachable under z_B eligibility |
| `aghq/AGHQ-POLICY-SITES-INDEPENDENT` | n forced; production passes NA |
| `aghq/AGHQ-POLICY-UNRESOLVED-WIDTH` | treewidth=NA |

Full rationale: `t8-aghq-policy-rows-proposal.md` table.

## Ledger counts (after)

```sh
python3 tools/core070_ledger_counts.py docs/dev-log/core070/required-source-case-map.json
```

```
REQUIRED=497 (was 505)  BOUND=292  DISPOSITIONED=205  FREE=0
XTAB aghq BLOCKED_SPEC_DEFECT=14   # bindable remainder
```

REQUIRED dropped by 8; **FREE=0 invariant holds** among remaining required rows.

## Not done in this slice

**14 bindable rows** remain `BLOCKED_SPEC_DEFECT` until same-model public-fit receipts land
(`t8-aghq-bind-next-slice.md`). No bind claims without executable receipts.
