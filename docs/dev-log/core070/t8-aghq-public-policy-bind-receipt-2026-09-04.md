# T8 AGHQ public-policy bind receipt — 2026-09-04

**Status:** PASS — 14/14 rows bound via exported `gllvmTMB()` / `gllvmTMBcontrol()`.

**Machine receipt:** `aghq-public-policy-bind-receipt-2026-09-04.json`

**R engine:** gllvmTMB twin @ `1005cf12e` (`devtools::load_all` on source tree).

**Model contract:** Stage1a — `latent(..., unique=FALSE)`, single `z_B` block,
`aghq_ridge=Inf`, deterministic control (`n_init=1`, `init_jitter=0`, `se=FALSE`).

## Bound rows

| row | public anchor | observed |
|---|---|---|
| AGHQ-AUTO-K-BINOMIAL | `aghq="auto"`, binomial | used=TRUE, k=5 |
| AGHQ-AUTO-K-POISSON | `aghq="auto"`, poisson | used=TRUE, k=5 |
| AGHQ-AUTO-K-GAUSSIAN | `aghq="auto"`, gaussian | used=TRUE, k=5 |
| AGHQ-AUTO-K-NB2 | `aghq="auto"`, nbinom2 | used=TRUE, k=5 |
| AGHQ-AUTO-K-ORDINAL | `aghq="auto"`, ordinal_probit | used=TRUE, k=9 |
| AGHQ-AUTO-K-DELTA | `aghq="auto"`, delta_gamma | used=TRUE, k=5 |
| AGHQ-AUTO-K-TWEEDIE | `aghq="auto"`, tweedie | used=TRUE, k=9 |
| AGHQ-DEFAULT-OFF | `formals(gllvmTMBcontrol)$aghq` | FALSE |
| AGHQ-POLICY-OFF | `aghq=FALSE` | used=FALSE |
| AGHQ-POLICY-EXPLICIT | `aghq=3L` | used=TRUE, k=3 |
| AGHQ-POLICY-EXPLICIT-BYPASS-CUTOFF | `aghq=9L`, p=20 | used=TRUE, k=9 |
| AGHQ-POLICY-AUTO-ENFORCE-CUTOFF | `aghq="auto"`, p=20 | used=FALSE, reason∋cutoff |
| AGHQ-POLICY-TRAITS19 | `aghq="auto"`, p=19 | used=TRUE |
| AGHQ-POLICY-TRAITS20 | `aghq="auto"`, p=20 | used=FALSE (boundary dup) |

## Note — AUTO-K-DELTA k=5 vs frozen helper k=9

Public `delta_gamma()` reports family label `"binomial Gamma"`, so
`.aghq_start_index()` does not match the `delta_gamma` high-curvature tier.
The frozen helper oracle used `family=list(family="delta_gamma")` → k=9.
The bind records the **public fit** observation (k=5), not the helper string.

## Ledger

`python3 tools/core070_ledger_counts.py` → REQUIRED=497 **FREE=0**;
aghq BLOCKED_SPEC_DEFECT among these 14: **0**.
