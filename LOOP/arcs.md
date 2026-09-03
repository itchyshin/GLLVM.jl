# arcs — core070 overnight (status-marked; gates flagged)

| id | arc | depends | gate | status |
|---|---|---|---|---|
| A1 | T14 land: Totoro suite green at 85918fe9 → check-log → push #1 → CI watch; red = diagnose only | — | push #1 (pre-authorised) | IN PROGRESS |
| A2 | CI.yml: shard suite into parallel jobs; coverage off on routine; full matrix+coverage on workflow_dispatch; rides push #1 if ready, else push #2 | — | pre-authorised | TODO |
| A3 | Second-order receipts batch: all paired harness cells (Gaussian, Poisson, Binomial, Beta, NB2 + any receipted bridge families), both engines, Totoro; SE/vcov/Wald per contract draft; receipts + `second-order-batch-2026-09-03.md`; tolerances measured, not gated | A1 | — | TODO |
| A4 | T5 paired re-runs on Totoro: postfit-policy-batch-01 (nobs rows) + extract_* batch (communality/correlations/proportions/Omega); re-bind rows whose verifier passes; report | A1 | ledger flips pre-authorised | TODO |
| A5 | T4 realistic-size: Totoro pre-run one cell per family (Gaussian/Poisson/NB2, p=20,n=500), both engines, timing + cond(H); size the grid p∈{20,50}×n∈{500,2000}; queue the grid on Nibi as an array with `--time` = pre-run × margin (starts 08:00 EDT); Totoro fallback ≤2 h | A3 | D-139 estimate written | TODO |
| A6 | Phylo transport S1: `PrecisionPhy` consumer (red-first: R-convention precision for the 8-tip fixture equals AugmentedPhy path ≤1e-8 after scale alignment); S2: `correlation::Bool` + ultrametric check on augmented_phy/make_phy (red-first: σ²_phy scales by height, logLik invariant) | — | Q1–Q4 defaults accepted | TODO |
| A7 | Docs cascade: stale Fisher-retained list in docs/src/gllvmtmb-parity.md; ZI-trio Julia-beyond note + small-n limitation in docs/src; "what parity does NOT mean" section; mi() row → implemented with pasted test receipt | — | — | TODO |
| A8 | Design notes: T12 grouping levels (unit/unit_obs/cluster/cluster2 mapping + required rows proposal); T8 AGHQ policy-row reclassification proposal | — | — | TODO |
| A9 | Push #2 after A3/A4 (and A2 if not already) — one push, CI watch | A3,A4 | push #2 | TODO |
| A10 | Close: after-task report (closeout.py PASS), Rose audit, Melissa plan-actual, handover 2026-09-03, push #3, lease release, `LANE:` line | all | push #3 | TODO |

Order of execution: A1 → (A2 ∥ A7 ∥ A8 while suite runs) → A3 → A4 → A5 → A6 → A9 → A10.
Batch barriers (checkpoint + consider rolling): after A1, after A4, after A6.
