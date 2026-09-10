# Destination B G0 decision packet — pending owner response

**Status:** `RESOLVED 2026-09-08 — scope authority recorded in
docs/dev-log/decisions/2026-09-08-destination-b-g0-authorisation.md`.
This packet remains the decision aid; the separate authorization record binds
only the five stated lines. It does not alter the frozen R reference, promote
a capability, or change the public bridge claim.

## Why G0 is required

The authoritative handover is retained at Git object `3915680e`:
`docs/dev-log/handover/2026-09-07-codex-handover.md`. It says that Destination
B is paused at G0, has no named no-G0 Julia leaf, and requires Shinichi's
direct answer on grouping B1, R `phylo_rr` S3b, S4, dense `vcv`, and FRK.
An apparently green diagnostic is explicitly not a substitute for that answer.

The user-facing status must remain narrower than a general parity claim:

- Frozen target: `gllvmTMB` 0.7.0 at
  `b4d5fee64def88bc768dda1f1f77c29b295edd86`.
- True parity: not established. The public bridge evidence matrix records
  9 PASS, 13 blocked, and 68 untested cells; PASS includes tested refusals.
- `engine = "julia"`: experimental, one-way R-to-Julia, partial; it is not a
  general replacement for the R/TMB engine.
- The current parent Destination B ledger leaves G3–G8 unmet. This packet
  does not change any checkbox.

Sources: `docs/src/gllvmtmb-parity.md`,
`docs/dev-log/core070/bridge-coverage-matrix.md`, and
`.unlazy/destination-b/GATES.md`.

## Current evidence that informs, but does not answer, G0

| Item | Current evidence | What it does **not** establish |
|---|---|---|
| B1 `unit` | Local commit `814d8486` adds a public fixed-coordinate Gaussian unit test and a frozen-R formula receipt. | Same-data fitted parity, intervals, recovery, all grouping levels, or B1 qualification. |
| S3b / S4 | Retained private/directional tree, pedigree, and dense reference artifacts; A4/S4 acceptance record remains `paired_evidence_unavailable`. | Public R bridge admission or a paired user workflow. |
| Dense `vcv` | Existing schema records one R-ridged-once precision contract and a condition-number boundary. | A general dense-covariance consumer, valid intervals, or a second Julia inversion. |
| FRK | `gllvmTMB#1275` is the explicit parking record. | An implementation request. |

The older 2026-09-02 maintainer note records a default dense-`vcv` convention,
but the newer D-220 handover requires direct confirmation rather than inferring
that it still authorises this Destination B line.

## Five owner decisions

| G0 label | Choices | Recommended response | Exact consequence if approved |
|---|---|---|---|
| **B1 grouping** | Authorize / narrow / park | **Authorize the approved full grouping programme, but qualify no capability from the existing B1 checkpoint.** First execution slice: paired Gaussian shared-`unit` fit, then expand to `unit_obs`, `cluster`, and `cluster2` under the approved plan. | Opens only the named GLLVM.jl grouping line; it does not alter gllvmTMB engine/C++ or claim parity. |
| **R `phylo_rr` S3b** | Proceed / park | **Proceed, bridge-adapter only.** | Allows a separately leased R worktree for the adapter and its tests; no C++ work and no generic bridge admission. |
| **S4** | Authorize exact Gaussian paired-validation scope / park | **Authorize Gaussian paired public-workflow validation after its consumer is working.** | Opens S4 only after S3b consumer evidence; it does not admit non-Gaussian phylogeny or broad interval coverage. |
| **Dense `vcv`** | Confirm canonical R precision contract / park | **Confirm:** one R ridge, retain original condition number and warning, transport canonical precision/determinant/scale, no independent Julia inversion. | Makes the dense case an explicit paired-evidence target, not a blanket covariance feature. |
| **FRK** | Confirm park / unpark | **Confirm park at `gllvmTMB#1275`.** | No FRK implementation, documentation expansion, or dependency work. |

## Execution sequence after a positive G0

Maximum concurrency remains three workers plus the coordinator. Each builder
receives an isolated worktree, an Unlazy leaf ledger, and a declared file scope.

```text
G0 owner receipt
  ├─ B1 grouping engine / Gaussian public fit
  ├─ S3b phylogenetic consumer + bounded R adapter
  └─ independent fixtures / source-to-Julia mapping checks
             ↓
          S4 paired validation and interval evidence
             ↓
  non-Gaussian grouping, recovery, public workflows, independent review
```

Before any campaign estimated above 30 minutes, the relevant slice must record
a runtime estimate, a pre-run test, its expected failure modes, and a separate
compute approval. Totoro or DRAC selection is not pre-authorised by this G0
packet.

## Paste-ready owner response

```text
G0 approved for Destination B:

1. B1 grouping: AUTHORIZE full approved grouping programme; current B1 remains
   source-alignment only. Start with paired Gaussian unit, then the remaining
   three named levels.
2. R phylo_rr S3b: PROCEED as an R bridge adapter/test line only; no C++ work.
3. S4: AUTHORIZE one Gaussian paired public-workflow validation after S3b.
4. dense vcv: CONFIRM the R-ridged-once canonical precision contract; no Julia
   reinversion; retain condition-number warning.
5. FRK: CONFIRM PARK at gllvmTMB#1275.

Keep public wording: experimental partial R-to-Julia bridge, not 0.7 parity.
No push, merge, release, registry action, 0.7.1 expansion, or coverage campaign
is authorised by this response.
```

## Authorisation boundary

The owner directly approved B1, bridge-only S3b, conditional Gaussian S4, and
the stated dense-`vcv` contract on 2026-09-08; FRK remains parked. The approval
does **not** authorise R/C++ engine work, a second Julia inversion, a generic
bridge admission, non-Gaussian phylogeny, a coverage campaign, a push, merge,
release, registry action, 0.7.1 expansion, or a public parity claim. B1 source
alignment remains evidence only, not B1 qualification.
