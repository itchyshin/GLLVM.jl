# Three original family formula cases in the required runner

The required runner now registers these original model cases separately from
family smoke and public R-bridge qualification:

| Case | Native prerequisite in the same run | Model |
| --- | --- | --- |
| CORE070-FAMILY-02-LOG-FORMULA-INTERFACE | NATIVE-03-POISSON | seed44, p5/n60/K2, log link |
| CORE070-FAMILY-07-LOGIT-FORMULA-INTERFACE | NATIVE-08-BETA | seed45, p5/n60/K1, per-trait precision, observed curvature |
| CORE070-FAMILY-11-LOG-FORMULA-INTERFACE | NATIVE-12-TRUNCATED-NB2 | seed58, p5/n120/K1, explicit per-trait size and observed curvature |

Each runs y~1 with wide data and a complete long table in reversed row order.
All fitted coordinates and log-likelihoods must match the same-run native fit
within absolute tolerance 1e-10. The native fit must match the coordinates in
its R comparison/health report. Original data hashes and R continuation policies
are unchanged; formula-only selection without the matching native ID fails.
No gradient is invented for the formula fit: the receipt explicitly links its
identical coordinates to the native health computation.

Truncated-NB2 fits do not retain a hessian field. Its fixture explicitly passes
hessian=:observed and labels that value as requested control, not stored metadata.
This remains a fitted-object reporting limitation for later coverage work.

Replay: .unlazy/core070-aghq/family-formulas-02/ (first failed attempt retained
at family-formulas-01). Current evidence: family-formulas-evidence.json.
Run python3 tools/core070_verify_family_formulas.py --self-test for source,
receipt, numerical and negative-control checks. Historical seven-case receipts
are not current evidence after the runner/manifest changes.

The source contract remains DRAFT_INCOMPLETE_NOT_FROZEN. The contract files retain
their pre-run specification state; the separate immutable evidence files record
execution outcomes. Ten executable links cover five family facts partially;
710 other nonexcluded source facts remain unmapped. Native plus formula coverage
does NOT establish public R-bridge, all variants, inference, recovery, performance
or complete-family parity.
