# Core070 binomial trial/link oracle repair

## 1. Goal
Make the two existing parity helpers compare the requested binomial trials and link before adding required paired model cases.

## 2. Implemented
No-X and shared-X forward supplied N as R weights, expose binomial_link, preserve omitted-N weights=NULL and use shared pure input validation. Added source inventory binding, R argument capture and Julia pre-R preparation regressions. Updated catalogue/docstrings/parity README.

## 3a. Decisions and Rejected Alternatives
Repair both neighboring routes; do not change the species-X surface that has no trial/link options. Keep beta-binomial N requirement. Reject silently ignored N/nondefault links. Integer/exact-representation checks belong to this complete-data test oracle, not a rewritten R admission policy. No engine/tolerance/DGP change.

## 4. Files Touched
parity_helpers.jl, parity_trial_inputs.jl, test_parity_trial_inputs.jl, central runner, core070_binomial_transport.R, core070_verify_binomial_transport.py, aggregate evidence static inventory, scoped contract/evidence/catalogue/docs and execution records.

## 5. Checks Run
Original actual R blocks68pass/20fail; final127pass with default/common/varying trials and three links on two routes. Julia pure inputs56pass and actual function prefixes24pass. No RCall, TMB tape or fit. Actual process exits retained and source pinned. Aggregate evidence self-test PASS.

## 6. Tests of the Tests
Original source fails trial/link assertions. Six evidence negatives reject wrong counts, false fitted/embedding claims and corrupted receipt pins. Input tests reject shape mismatch, ignored options, invalid trials/successes and precision loss; nonmutation and ordering controls pass.

## 7a. Issue Ledger
Transport defect repaired at argument/preparation scope. Fitted binomial probit/cloglog and multi-trial parity remain unpaid; cloglog curvature/saturation needs its separate contract. Full finite catalogue not frozen; original Student/truncated-NB2 health and NB2 tighter-tolerance diagnosis outstanding.

## 8. Consistency Audit
Pure helper added to producer and aggregate verifier dependency inventories, preventing unbound input preparation. Existing fixtures and source engine untouched. Previous helper-bound results historical until replayed. Source catalogue pins updated with provenance; no new numerical PASS status.

## 9. What Did Not Go Smoothly
Comment claimed both count families forwarded weights while code forwarded only beta-binomial. A first repair used explicit ones for omitted-N binomial; final repair preserves original weights=NULL to avoid unrelated policy changes. All intermediate snapshots retained.

## 10. Known Residuals
No complete Julia-to-R embedding, installed-package fit, fullsuite, independent review or rendered documentation. R capture replaces only fitter/control endpoint to inspect arguments; Julia prefixes end before R startup. These are not successful fitted-model receipts. Remote old job UNKNOWN/socket absent, not restarted.

## 11. Team Learning
Keep complete-data trial validation and family choice together. Verify actual call payloads and source order with asymmetric sentinels, and preserve the semantics of omitted arguments.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ parity, public bridge qualification, recovery, performance or release. Rose NOT RUN; M1 PARTIAL. No new production child, push, merge, release, R0.7.1/article edits or cleanup.
