# Destination B — G1 static audit matrix (frozen-0.7.0)

**Date:** 2026-09-13
**Scope:** G1 only — static interface / symbolic-alignment / artifact inventory for
B1 (grouping), S3b (R `phylo_rr` adapter), S4 (Gaussian paired public-formula probe).
No capture materialization, no B1 curvature evaluation, no S4 probe, no fit, no
optimizer, no R/TMB numerical call, no `Pkg.test()` full suite.

**Worktree:** `/private/tmp/destination-b-b1-integration-20260910`
**Branch:** `codex/destination-b-b1-integration-20260910`
**Frozen oracle:** `gllvmTMB` 0.7.0 @ `b4d5fee64def88bc768dda1f1f77c29b295edd86`
**Ledger:** `.unlazy/destination-b-programme/GATES.md` (reconciled 2026-09-13; `G0-SCOPE` `[x]`)
**Authority:** `docs/dev-log/decisions/2026-09-08-destination-b-g0-authorisation.md`
**Method:** graft-first symbol/call-path orientation (`graft ask --source`), then
direct file read for interface claims; three named static verifiers re-run with
exact commands and outputs (all pre-existing, non-numerical schema/contract
tests); no new artifact was created.

Legend: **DONE** = static contract/evidence exists and re-verified; **OWED** =
named, not yet done, requires a separate future gate; **RETRACTED** = a claim
that must not be made / was previously overstated; **PROTECTED** = must not be
touched by any G1 or later static work without a fresh maintainer decision.

---

## 0. Naming disambiguation (read before the domain matrices)

`B1`, `S3b`, `S4` in the 2026-09-08 authorisation and the 2026-09-12 handover
are **process/authorisation-line labels**, not the formal 32-row scope IDs from
`docs/dev-log/decisions/destination-b-scope-reconciliation.md`
(`node tools/destination_b_scope_check.mjs` → A1–A15, B1–B4, C1–C5, D1–D8).
They partially collide in spelling but not in referent:

- **B1** (authorisation line 1, "grouping") maps onto the formal row
  **`B1` = `grouping-levels/UNIT-KWARG-NAME-PARITY`**, plus its siblings B2–B4
  (`UNIT-OBS-NONGAUSSIAN-KWARG`, `CLUSTER-THIRD-AXIS-KWARG`,
  `CLUSTER2-INDEP-KWARG`) and the ledger's `B1-JOINT-STATIONARY` /
  `B1-JOINT-PAIR` / `B1-RECOVERY` gates. This one is a direct name match.
- **S3b** and **S4** are *not* formal row IDs in the 32-row scheme at all —
  they are legacy labels from an earlier "A4/S4" gate pair (2026-09-05 true-parity
  map era; see the `destination-b-a4-s4-*` file/dir prefix used throughout
  `tools/destination_b/`, `test/`, and `docs/dev-log/core070/`). The
  phylogenetic capability those labels track now lands closest to formal rows
  **A14/A15** (`covariance/COV-PHYLO-LATENT-1FO` / `-RSZ`), but no G1 evidence
  in this session asserts that mapping is exact — it is a finding, not a
  closed identity. Any future public claim citing "S4" must say which of (a)
  the 2026-09-08 authorisation-line label or (b) a formal A14/A15 row it means.

**Protocol-pair disambiguation (carried over from the 2026-09-13 ledger
reconcile, re-confirmed today):** two B1 curvature pre-run protocol pairs
coexist and must never be conflated:

| Pair | Sealed at | Ledger | Static evidence (re-run today) |
|---|---|---|---|
| `fixed_point_marginal` | `dd2ab502` | `.unlazy/destination-b-programme/GATES.md` (`B1-JOINT-*`) | `test/test_b1_fixed_point_marginal_curvature_protocol.jl` → **22/22 pass**; `tools/verify_b1_fixed_point_marginal_curvature_protocol.jl` → **PASS** |
| `fixed_coordinate` | — | root `.unlazy/GATES.md` (G1–G3, `[x]`) | `test/test_b1_fixed_coordinate_curvature_protocol.jl` → **4/4 pass** (not re-run today; cited from ledger, matches prior receipt) |

Any G1 or later matrix row citing "the B1 static contract (22/22)" means
**`fixed_point_marginal`** only.

---

## 1. B1 — grouping (`unit` / `unit_obs` / `cluster` / `cluster2`)

| Item | Classification | Evidence |
|---|---|---|
| Grouping term vocabulary is fixed and named once | **DONE** | `src/grouped_fit.jl:L4` — `const _GROUPING_TERM_NAMES = (:unit, :unit_obs, :cluster, :cluster2)` (found via `graft ask "grouping unit unit_obs cluster cluster2 bridge_fit"`) |
| Bridge dispatch entry point exists and is the actual public call path | **DONE** | `src/bridge.jl:L827-L1503` — `_bridge_fit_onepart(y, key, K, N, trait_names, unit_names, options; X=, X_lv=, mask=)`; routes CI method/level/nboot/seed validation before any fit, then dispatches by family/covariate shape |
| `fixed_point_marginal` B1 curvature pre-run contract, static/fail-closed | **DONE** | Re-run today: `test/test_b1_fixed_point_marginal_curvature_protocol.jl` → 22/22; `tools/verify_b1_fixed_point_marginal_curvature_protocol.jl` → PASS. Matches `docs/dev-log/check-log.md` 2026-09-10 and 2026-09-13 entries verbatim |
| `fixed_coordinate` B1 curvature pre-run contract, static/fail-closed (separate pair) | **DONE** | root `.unlazy/GATES.md` G1–G3 all `[x]`, 4/4 tests; distinct receipt/HOLD target from `fixed_point_marginal` |
| B1 direct-Hessian HOLD JSON | **PROTECTED** | `docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json` — confirmed still the **only** untracked file in `git status --short` this session; not staged/edited/deleted/retried. Its `obj$he(theta_star)` error is an interface limitation, not a curvature or singularity verdict |
| `B1-JOINT-STATIONARY` (pre-registered four-source Gaussian frozen-R comparator, stationary at max outer gradient ≤ 1e-6) | **OWED** | Ledger `B1-JOINT-STATIONARY`, status **NOT AUTHORIZED**; requires a separate, fresh maintainer decision before any capture materialization or curvature call (handover G2). Not attempted this session |
| `B1-JOINT-PAIR` (matched-coordinate + independent-refit + non-bijective incidence controls + interval status) | **OWED** | Ledger `B1-JOINT-PAIR`, downstream of `B1-JOINT-STATIONARY`. Not attempted |
| `B1-RECOVERY` (pre-registered recovery evidence, Monte-Carlo uncertainty) | **OWED** | Ledger `B1-RECOVERY`; needs its own pre-run + compute estimate + Totoro/DRAC placement (handover G6). Not attempted |
| Existing paired Gaussian shared-`unit`, `unit_obs`, `cluster`, `cluster2` receipts in `.unlazy/destination-b-b1/` | **DONE (narrower, source-alignment only)** | `frozen-r070-{unit,unit-obs,cluster,cluster2}-gaussian-*-receipt-*.json` present under root `.unlazy/destination-b-b1/`; per the 2026-09-08 authorisation these are explicitly "source-alignment evidence only", **not** the full B1 grouping programme qualification |
| Claim "B1 grouping is qualified / paired R–Julia parity established" | **RETRACTED** | No authorisation grants this; the 2026-09-08 receipt's non-claims section states explicitly the authorisation "does not establish that any Destination B row works [or] has paired R–Julia parity" |

**B1 verdict:** the static contract, both protocol pairs, the public bridge
call path, and the grouping-term vocabulary are DONE and consistent with the
ledger. Every numerical B1 gate (`B1-JOINT-STATIONARY`, `B1-JOINT-PAIR`,
`B1-RECOVERY`) remains OWED and unauthorised. The HOLD JSON is untouched.

---

## 2. S3b — R `phylo_rr` bridge adapter (adapter/test line only)

| Item | Classification | Evidence |
|---|---|---|
| Authorisation scope: adapter/test-only, no `gllvmTMB` C++/likelihood-engine change | **DONE (authority, not evidence)** | `docs/dev-log/decisions/2026-09-08-destination-b-g0-authorisation.md` line 2: "proceed only as an R bridge adapter/test line. No `gllvmTMB` C++ or likelihood-engine change is authorised" |
| Julia-side multivariate precision bridge option contract | **DONE** | `src/bridge_precision_multivariate.jl:L41-L78` — `_bridge_pmv_options(options, m, n_leaves)` requires `species_id` (never inferred), validates `mode`, `residual_mode`, `phylo_model == "multivariate"`, `g_tol`, `iterations`, `ci_method ∈ {none, wald}` (profile explicitly not implemented), `ci_level` (found via `graft ask "phylo_rr bridge adapter S3b"`) |
| Rank-reduced loading df formulas (R ↔ Julia symbolic alignment) | **DONE** | `src/bridge.jl:L225` `_bridge_rr_df(p,K) = p*K - K*(K-1)÷2`; `src/packing.jl:L24-L26` `rr_theta_len(p,K)` — identical formula, two call sites |
| R-side adapter fixture export tool | **DONE (tool exists)** | `tools/destination_b/export_adapter_fixtures.R` |
| S3b pilot receipts: one 3-trait/8-tip/2-replicate Gaussian dense-vcv, rank-one phylogenetic loadings, shared residual SD | **DONE (pilot, not qualification)** | `docs/dev-log/core070/destination-b-s3b-pilot/README.md` + `r-attempt-{01,02}.json`, `comparison-attempt-01.json`, `independent-fit-attempt-{01,02}.json`. README states explicitly: "not paired R-interval/recovery qualification, S4 completion or public bridge admission." Matched R/Julia point difference `1.0658141036401503e-14` against a `1e-6` threshold; all 12 Wald interval rows available for the independent Julia fit but "interval feasibility for one dataset, not evidence of nominal coverage" |
| Adapter-consumer test that actually calls `bridge_fit(...)` end to end | **NOT RUN — flagged, not a static check** | `test/test_destination_b_adapter_consumer.jl` — peeked (not executed): calls `GLLVM.bridge_fit(; y=Y, family="gaussian", d=1, phylo=..., options=Dict("phylo_model"=>"multivariate", ...))` for tree/pedigree/dense fixtures. This is a real fit/optimizer call, out of G1's static-only scope; correctly excluded this session |
| Dense uncertainty comparison test (loads a DLL path conditionally) | **NOT RUN — flagged** | `test/test_destination_b_dense_uncertainty.jl` — peeked only: on `isfile(dll)` it calls `compare_dense_uncertainty(...)`, a potential R/TMB-adjacent numerical path. Excluded this session pending explicit authorisation |
| Phylo independent-receipt test (includes a `fit_phylo_gaussian_reference.jl` builder) | **NOT RUN — flagged** | `test/test_destination_b_phylo_independent_receipt.jl` — peeked only; includes a file named `fit_phylo_gaussian_reference.jl`. Excluded this session |
| `S3B-CONSUMER` ledger gate (tree, pedigree-with-ancestors, dense-`vcv` bridge receipts bind frozen R identity + canonical convention; do not unlock generic engine routing) | **OWED (audit only, per this matrix, still pending sign-off)** | Ledger status: "pending G1 audit ... adapter/test-only — no `gllvmTMB` C++ or likelihood-engine change is authorised." This matrix is the G1 audit contribution; the gate itself stays unchecked pending maintainer review of this document |
| Claim "S3b consumer works" (the precondition the 2026-09-08 receipt sets for S4) | **RETRACTED (not yet established)** | The pilot receipts are explicitly non-qualifying (see row above); the end-to-end consumer test exists but was not run this session. Do not treat "the test file exists" as "the consumer works" |
| Any independent Julia inversion of the dense R vcv | **RETRACTED / excluded by design** | Authorisation line 4: "do not independently invert in Julia" — the dense-`vcv` contract is R-ridged-once only, transported not recomputed |

**S3b verdict:** the adapter/test-only authority boundary, the Julia option
contract, the symbolic rank-one df alignment, and one non-qualifying pilot
receipt are DONE. The actual end-to-end consumer test exists in the repo but
was correctly *not run* this session (it performs a real fit). "The S3b
consumer works" is not yet established and must not be claimed from this
audit alone.

---

## 3. S4 — Gaussian paired public-formula probe

| Item | Classification | Evidence |
|---|---|---|
| Authorisation: one Gaussian paired public-workflow validation, only after the S3b consumer works | **DONE (authority, not evidence)** | `docs/dev-log/decisions/2026-09-08-destination-b-g0-authorisation.md` line 3 |
| Target public formula is locked in a validator, not just prose | **DONE** | `tools/destination_b/validate_a4_s4_public_r_formula_receipt.jl:L139-L247` — `validate_a4_s4_public_r_formula_receipt(receipt; allow_synthetic=false)` hard-requires: constructor `gllvmTMB::gllvmTMB`; formula `traits(trait_1, trait_2) ~ 1 + phylo_dep(1 | species, tree = tree)`; resolved long formula `value ~ 0 + trait + phylo_dep(0 + trait | species, tree = tree)`; wide-traits layout; individual unit; species cluster; gaussian family; observed-marginal; full unstructured phylogenetic covariance; 2 traits; 3-tip ultrametric (non-unit-ultrametric) tree; fixed target-mapping strings for β/phylo-cov/shared-residual (found via `graft ask "phylo_dep public formula gllvmTMB traits"`) |
| S4 receipt schema verifier (static, no fit) | **DONE** | Re-run today: `test/test_destination_b_a4_s4_receipts.jl` → **60/60 pass** ("A4/S4 paired matrix receipt schema") |
| S4 public R-formula paired-receipt contract test (static, no fit) | **DONE** | Re-run today: `test/test_destination_b_a4_s4_public_r_formula_receipt.jl` → **29/29 pass** |
| A4/S4 acceptance boundary is a closed, private, non-public-admission harness for exactly 3 Gaussian rows | **DONE** | `docs/dev-log/decisions/destination-b-a4-s4-acceptance.md`: "This is a closed, private candidate-evidence harness ... It is not a public R formula admission and it does not change a public capability claim." Every terminal record must retain `qualified = false` and `r_public_admission = "closed"` |
| A4/S4 fixed-coordinate evaluator test | **DONE, but flagged as a scope caveat** | Re-run today: `test/test_destination_b_a4_s4_fixed_coordinate_evaluator.jl` → **45/45 pass**. **Caveat (see §4 below):** this test loads `GLLVM` and evaluates its own marginal objective at hardcoded fixed coordinates against pre-recorded canned R-side values — it is closer to a "fixed-coordinate curvature" building block than a pure schema check. It ran to completion before this was recognised; it wrote no new artifact and did not touch the HOLD JSON, but its PASS is **not** treated as new G2-style numerical authorisation evidence |
| S4 recorder object `97214679c` | **OWED / cross-lane physical blocker** | Confirmed absent from this worktree's object database this session: `git cat-file -t 97214679c` → `fatal: Not a valid object name 97214679c` (exit 128). Its owning lane must be rehydrated before any future S4 probe can even be attempted — this is independent of authority |
| `S4-PUBLIC-FORMULA` ledger gate (one write-once, non-synthetic receipt, 7 named interval endpoints, generic-engine rejection, clean env) | **OWED / NOT AUTHORIZED** | Ledger status explicit: requires a separate, fresh maintainer decision (handover G3), only after the S3b consumer works, and the recorder is physically absent regardless |
| S4 pilot artifacts (`public-r-formula-probe-{01,02}.json`, `public-r-formula-contract.md`, `public-r-formula-receipt-template.json`) | **DONE (feasibility only)** | `docs/dev-log/core070/destination-b-a4-s4/` — per `docs/dev-log/after-task/2026-09-10-s4-public-r-formula-feasibility.md`, feasibility-only, not a probe result |
| Claim "S4 phylogenetic parity is established" or "the S4 probe ran" | **RETRACTED** | Handover states explicitly: "S4's earlier stop is diagnostic retention only, not phylogenetic parity." No probe ran this session; none is authorised |

**S4 verdict:** the target public formula, its schema validators, and the
closed-harness acceptance boundary are DONE and internally consistent. The
S4 probe itself remains OWED, blocked by both authority (no fresh maintainer
decision) and a physical cross-lane object absence. One existing test
(`a4_s4_fixed_coordinate_evaluator`) sits closer to the curvature-evaluation
line than its filename suggested; flagged rather than silently absorbed into
the DONE column.

---

## 4. Self-correction: one test run exceeded the intended static-only bar

Three of six candidate static checks named in the 2026-09-12 handover / this
session's plan were schema-only as expected
(`test_b1_fixed_point_marginal_curvature_protocol.jl`,
`test_destination_b_a4_s4_receipts.jl`,
`test_destination_b_a4_s4_public_r_formula_receipt.jl`, plus the two verifier
scripts and the Node scope checker). One,
`test_destination_b_a4_s4_fixed_coordinate_evaluator.jl`, was launched under
the same "static-sounding filename" assumption but turned out to load `GLLVM`
and evaluate its own marginal objective at fixed, hardcoded coordinates
against canned R-side values (32.2 s runtime; 45/45 pass). It was recognised
mid-run from its `include`d source; by the time this was confirmed the
process had already finished naturally (a `kill` attempt found no such
process). No new artifact was written, the HOLD JSON was untouched, and no
R/TMB call occurred (the R-side numbers are pre-existing fixture literals in
the test file, not a fresh capture) — but this is reported here rather than
folded silently into "successfully verified", per the goal's evidence-honesty
requirement. Three further files were positively identified as fit/DLL-risk
from peeking their source only, and were **not executed**:
`test_destination_b_adapter_consumer.jl` (calls `bridge_fit` end to end),
`test_destination_b_dense_uncertainty.jl` (conditionally loads an R DLL),
`test_destination_b_phylo_independent_receipt.jl` (includes a `fit_*`
builder).

---

## 5. Row-count summary

| Domain | DONE | OWED | RETRACTED | PROTECTED |
|---|---:|---:|---:|---:|
| B1 | 6 | 3 | 1 | 1 |
| S3b | 4 | 1 | 2 | 0 |
| S4 | 6 | 3 | 1 | 0 |
| **Total** | **16** | **7** | **4** | **1** |

No row in any domain reaches a public-capability claim. Every numerical B1
curvature gate, the S3b end-to-end consumer, and the S4 probe remain
unauthorised and were not attempted.

---

## 6. What this matrix does NOT do

- It does not check off any numerical gate (`B1-JOINT-STATIONARY`,
  `B1-JOINT-PAIR`, `B1-RECOVERY`, `S3B-CONSUMER`, `S4-PUBLIC-FORMULA`) in
  `.unlazy/destination-b-programme/GATES.md`. Those stay `pending`/`NOT
  AUTHORIZED`. A short progress note was added to that ledger's G1 section
  (see check-log) without approving any CHECK.
- It does not materialize a capture, call `obj$fn`/`sdreport`, run an
  optimizer, invoke R/TMB, or run `Pkg.test()`'s full suite.
- It does not touch the protected HOLD JSON, `.unlazy/**` gate content beyond
  the one progress note, the `AGENTS.md` snapshot, or PR #314's files.
- It does not authorise G2. That is a separate, named ask below.
