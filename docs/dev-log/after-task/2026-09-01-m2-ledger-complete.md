# After-task report — M2 ledger completion (Core 0.7.0 + AGHQ programme)

Date: 2026-09-01 · Lane: codex/core070-aghq-20260830 (Claude, per the committed
2026-08-31 handover takeover) · Goal: every one of the 533 required manifest rows
at PASS/PARTIAL/BLOCKED on fresh receipts.

## 1. What was asked
Finish M2: 533 required rows in
`docs/dev-log/core070/required-source-case-map.json` each accounted on receipts;
decision-gated rows surfaced as PARTIAL-pending-decision, never absorbed; no
push/merge/release/DRAC without approval; checkpoint per batch.

## 2. What was done
Waves 3–4 of the receipt campaign (waves 1–2 preceded this stretch):
namespace-1/2, aghq controls, inference-remainder, fit-input-2, family-links
batches built (ultracode agent fan-out), executed on Totoro through pinned
contract→runner→strict-verifier pipelines, receipts pulled/tarballed/sha-bound;
covariance and family areas closed by receipted triage/audit where the plans
themselves show unauthored or unresolved cases.

## 3. Outcome
**533/533 accounted (commit 9dc51244): 222 bound + 311 receipted dispositions**
(142 BLOCKED_NEEDS_JULIA_SURFACE, 44 BLOCKED_SPEC_DEFECT, 99
PARTIAL_PENDING_DECISION_RECLASSIFY, 22 OPEN_QUESTION, 4
PARITY_DEFECT_PENDING_DECISION). Mechanical audit: 0 free rows, 0 dangling
receipt paths.

## 4. Evidence
Per-batch tarball sha256 recorded in each row's evidence and in
`LOOP/core070-checkpoint.md` (wave3: ns1 d3550349, ns2 942ea792; wave4: aghq
057c3e11, inference 6f555f4d, fit-input 767cc80c, family-links c5dd4780).
Verifier lines: CORE070_NAMESPACE_{1,2}, CORE070_AGHQ_CONTROL,
CORE070_INFERENCE_REMAINDER, CORE070_FIT_INPUT_2 — all *_VERIFIED with
negative controls; family-links receipt is deliberately FAIL (see §6).

## 5. Defects found and repaired en route (batch specs, never gates)
- ns2 wide-consistency compared `gllvmTMB_wide` (default `unique`) to the
  `unique=FALSE` oracle — wrong-model (19 vs 15 df, gap 6.38); repaired to a
  matched default-unique reference (measured ~1e-8, tol 1e-6, justified in-code).
- ns2 paired-fit tolerance miscalibrated at authoring (1e-6 vs the 1e-4
  precedent) — calibrated with in-code justification; contract never previously
  accepted, so not a widening.
- inference batch fixture single-tier while R's icc CI needs two tiers; repair
  revealed Julia's `TwoLevelFit` has **no CI surface** → 4 rows honestly BLOCKED.
- family-links coef comparison read `coef()` semantics wrong (R returns b_fix
  only) and serialized Inf→null silently; repaired with loud fail_reasons.

## 6. New confirmed cross-engine findings (surfaced, not absorbed)
- **Binomial cloglog likelihood disagreement**: at R's fitted coordinates
  Julia's objective is −309.9947 vs R's −307.8958 (identity Δ 2.099); probit on
  the identical transport agrees to 6.6e-12; no saturation either side.
  Dispositioned PARTIAL_PARITY_DEFECT_PENDING_DECISION; repair leaf recommended
  (probe: `tools/probe_famlinks_identity.jl`, fixture seed 81012).
- Frozen R engine silently drops `kernel_latent(..., unique=TRUE)` on 2+ named
  tiers (bit-identical logLik to the plain fit) — receipted in the fit-input-2
  contract with a wrong-model negative control.
- (Wave 2, restated) nobs n-vs-p·n defect remains pending decision.

## 7. What this does NOT cover
No SE/curvature comparisons; no recovery/coverage claims; PARTIAL/BLOCKED rows
are honest ledger states, not passes — 142 rows await Julia surfaces, 44 await
case authoring, 125 await maintainer decisions. "Ledger complete" ≠ "parity
complete". The family-links batch receipt is status=FAIL by design (its cloglog
case is a real defect); the probit binding cites results.tsv inside the
retained tarball, with the caveat recorded in the row evidence.

## 8. Boundaries honored
No push, merge, release, or DRAC launch. Frozen oracle untouched. No tolerance
of any previously accepted contract changed. Protected lanes untouched.

## 9. Next
Maintainer decision queue (125 rows + nobs + cloglog leaf + A6 + ZI trio),
missing-surface engineering track, lane landings (this branch + the R-side
bridge lane), then M3 (performance/Documenter) and the beyond-parity arc.

## 10. Perspectives
Ada (orchestration), Gauss/Curie (batch builders via agents), Fisher (CI
routing), Hopper (R↔Julia semantics), Rose (audit dispatched below).

## 11. Rose verdict
Pending — audit dispatched at close; verdict to be appended.

## 11a. Rose verdict (round 1, 2026-09-01): NOT OK — two blockers, both since fixed

Recount, arithmetic, tolerance discipline, overclaim check: clean. Blockers:
(A) all 9 masks-known bound rows cited a preservation_sha256 matching no file
— corrected to the real tarball (3df7de88…) + results (6604a1ff…) hashes;
the retained verifier re-passed during the audit. (B) 7 covariance bound rows
cited only covariance-modes-evidence.json (status …NATIVE_FITS_UNPAID) —
repointed to covariance-mode-fits-evidence.json /
covariance-formula-evidence.json / public-r-bridge-programme-evidence.json,
which carry the executed PASS receipts. Also fixed: check-log.md backfilled
for waves 3–4 (rule #7 had been violated), AGENTS.md phase snapshot updated.
Residual caveat Rose noted and this report keeps: ledger-complete ≠ parity;
stale-tally drift is a recurring failure mode in this repo — the mechanical
audit script should hash-check evidence pointers next time, not just
path-check them (this round's audit only proved paths existed).
