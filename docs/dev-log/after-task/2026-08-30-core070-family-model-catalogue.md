# Core070 family smoke contract reconciliation

## 1. Goal
Replace misleading generic model metadata with the actual existing fixture contracts and expose missing parity obligations.

## 2. Implemented
Source-bound catalogue of17 smoke models, exact seeds/dimensions, dispersion/link/identification, R and native calls, source hashes, Student/Tweedie subcases and seven open obligation groups. Corrected existing master obligation rows without changing their IDs or the DRAFT status.

## 3a. Decisions and Rejected Alternatives
Do not freeze the full contract from smoke coverage. Do not alter original fixtures or likelihood tolerances to match a document. Multinomial is fixed-effects only, n400/C4/K0. NB2 currently uses rtol1e-3; project1e-6 acceptance still needs diagnosis. Probit/cloglog and multi-trial binomial need actual paired cases.

## 4. Files Touched
docs/dev-log/core070/family-model-catalogue.json and .md; frozen-r070-contract.toml; README.md in that folder; this report, check-log and LOOP checkpoint. Runtime audit scripts/receipt under .unlazy/core070-aghq/family-model-catalogue.

## 5. Checks Run
Source catalogue verification PASS:17 unique IDs equal the required smoke ID set, all fixture/helper hashes match, master calls/dimensions agree, draft and unpaid interface statuses retained. Literal NB2 assertion and fixed multinomial dimensions checked. No Julia/R numerical command, fit or campaign. git diff --check clean.

## 6. Tests of the Tests
No new automated test suite for documentation-only reconciliation. Source pins plus direct reads ground these records; they do not independently establish semantic completeness. No fabricated scientific evidence or reviewer verdict.

## 7a. Issue Ledger
Seven open groups: probit, cloglog, NB2 tighter parity, binomial trials transport, finite model variants, structured multinomial, health/interface qualification. The generic helper accepts N but supplies weights only to betabinomial; current Bernoulli smoke remains valid in its scope. Correct binomial transport before extending trials evidence.

## 8. Consistency Audit
Corrected generic seed/dimension descriptions, NB2/Beta actual native routes, family-specific parameterization and the false latent multinomial R call. Preserved every implementation/test byte. Master revision change requires new bound receipts for later programme acceptance; historical receipts remain archived.

## 9. What Did Not Go Smoothly
Source catalogue and tests had drifted: generic p5/n60/K1 descriptions hid actual fixtures; 17 family IDs obscured19 admitted family/link descriptors. Broad source admission and individual fitted-model qualification must remain separate.

## 10. Known Residuals
Full finite model contract still DRAFT_INCOMPLETE_NOT_FROZEN. No new fit health, covariance, AGHQ, formula, embedding, recovery, performance, fullsuite or docs rendering evidence. Totoro socket absent at turn start; prior remote job state UNKNOWN, not restarted. Independent review unpaid.

## 11. Team Learning
Record the exact model behind each case ID before counting passes. A same-named family can differ in trials, dispersion grouping or latent structure; branch-specific argument forwarding must be inspected.

## 12. Cross-Product Coverage
This does NOT cover full Core/AGHQ parity or complete family qualification. Rose NOT RUN; M1 PARTIAL. No engine/API/tolerance/R-lane edits, new production child, push, merge, release or destructive cleanup.
