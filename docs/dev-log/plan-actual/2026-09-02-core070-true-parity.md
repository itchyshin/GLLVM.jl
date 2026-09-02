# Plan vs Actual — Core 0.7.0 owed-steps + true-parity replan

Plan file: `~/.claude/plans/typed-churning-wombat.md` (v2 true-parity; v1 owed-steps summarised inline).
Session: Claude Fable 5.1, lane `codex/core070-aghq-20260830`, worktree `GLLVM.jl-core070-aghq-20260830`.
Date: 2026-09-02. Reconciled: 2026-09-02 12:34Z (Melissa, K10).

## Slice table

| Slice | Planned model/effort | Actual | Artifact planned | Artifact actual | Gate | Tag |
|---|---|---|---|---|---|---|
| v1 S0–S10 (owed steps, summarised) | mixed, Ada-run + 1 Haiku child | CI polled (Monitor), PR states read, ZI deployed+launched on Totoro via 1 Haiku child, phylo Qs written inline | `ci-verdict…`, PR states, ZI receipt, phylo-questions doc | CI verdict placeholder; PR states got; ZI deploy receipt done, full run in flight; phylo doc done | leaf-ci/leaf-report UNMET (pending); leaf-zi UNMET (ZI-G3 checks "launched OR PAUSED w/ pre-run nums" — launched, so substance met, checkbox unticked) | pending / adaptive |
| K0 recon | Ada + 3 Haiku, explicit model | 3 Haiku Explore children as planned | scratchpad/recon-{ledger,evidence,decisions}.md | done, consumed into sweep receipt | n/a (K0 pre-budget) | adaptive |
| K1+K4 | Haiku·low, 1 child reused via SendMessage | 1 Haiku child, reused for K4 as planned | ledger-recount + counts.py; parity-defect-rebind | both written; recount reproduces handover 505/285/220/0 exactly | leaf-recount 2/2 MET; leaf-rebind 2/2 MET | adaptive |
| K6 | Haiku·low | Haiku as planned | r-side-defects doc + summary to gllvmtmb-54 | 34 leads, cloglog item removed as ours | leaf-rdefects 2/2 MET | adaptive |
| K2 contract | Sonnet·high (Fisher+Noether lens) | Sonnet, Rose-edited before dispatch (Hessian convention frozen, CT-G1 read manually) | second-order-parity-contract.md | written; tolerances flagged unsigned (T3) | leaf-contract 3/3 MET (CT-G2 failed once, author fixed wording, not gate) | adaptive |
| K3 pre-run | Sonnet·medium, Totoro, ≤30 min D-139 est. | Sonnet; pre-run sampled only p=5 cells; full run overran est. by 1–3h, not killed, re-reported | second-order-prerun doc | 4/5 families agree 1e-6..1e-5; NB2 produced no Julia SE (SingularException at boundary optimum) — recorded as finding | leaf-prerun 2/2 MET | drift (D-139 estimate) / adaptive (overrun handling) |
| K5 tool | Sonnet·medium | Sonnet as planned | tools/parity_ledger.py + first run doc | FORWARD=77 REVERSE=82 at oracle; FORWARD=85 REVERSE=82 at 0.7.1 main (8 untracked); self-test OK | leaf-tool 2/2 MET (CHECK flag corrected `--julia`→`--root` before any run existed to measure) | adaptive |
| K7 map | Fable, inline | Fable, inline, as planned | true-parity-decision-map.md + AskUserQuestion | map committed; 4 sections; maintainer answered T1/T2/T3-scope/T7 | leaf-map 2/2 MET | adaptive (matches plan) |
| K8 Rose review | Sonnet·medium, before K2/K3/K5 | Sonnet, ran before K2/K3/K5 dispatch as planned; made 2 edits (Hessian freeze, CT-G1 grep→manual) | critique appended to map | edits adopted; sweep-receipt non-vacuity checked | n/a (folded into leaf-contract) | adaptive |
| K9 MECHANICAL-VERIFY | Haiku·low, fresh, after K1–K6 | **not yet run** | gate-check --reverify all leaves | not dispatched this session | leaf-close CL-G1/CL-G2 UNMET (unchecked, pending K9/close) | pending |
| K10 RECONCILE | Sonnet·low (me) | Sonnet, running before K9 completed | this file | this file | n/a | unclear (see deviation below) |
| IN FLIGHT (CI, ZI) | Monitor/bg | CI still pending Julia-job verdict; ZI at ~140–240/240 chunks last checked, overrun | ci-verdict doc, ZI findings doc | both **_PLACEHOLDER** in after-task draft | leaf-ci/leaf-zi UNMET | pending |

## Material deviations

1. **Axis: safety gates / sequencing.** K10 (this reconcile) is running while K9 (MECHANICAL-VERIFY) has not
   been dispatched, though the plan's dependency line states `K10←K9`. `leaf-close` (CL-G1/CL-G2) is
   correctly unchecked, so the ledger itself is honest about the gap — but the *order* in the plan was
   K9 then K10, and K9 was skipped in favour of running K10 directly. **Tag: drift. Owner: Ada** (scope/routing —
   whether K10 may run ahead of K9 given K9 is "mechanical re-verify of already-met leaves" needs a recorded
   call, not a silent skip).
2. **Axis: safety gates (D-139 compute estimate).** K3's Totoro pre-run sampled only the cheapest cell class
   (p=5) before estimating the full 240-chunk ZI run's wall time; the full run overran the ≤30–60 min estimate
   by 1–3 h (p=25 cells ~110s/fit vs 1.6s at p=5). The run was not killed (reversible, inside the ≤150-core
   envelope) and was re-reported per D-139's own "overrun stops and re-reports" clause. **Tag: drift** (the
   estimate itself, sampled from the cheapest not the most expensive cell) **— adaptive** (the recorded
   response to the overrun, which followed the rule). **Owner: domain reviewer (Gauss/compute-routing)**.
3. **Axis: evidence/verification.** K3's NB2 cell produced no Julia SEs (`confint` hit `SingularException` on
   a 19×19 finite-difference Hessian at a degenerate huge-dispersion optimum) while R's `sdreport()` returned
   finite SEs except two boundary `log_phi` entries. Recorded as a numbered finding with a hypothesis, not
   patched or hidden. **Tag: adaptive. Owner: domain reviewer (Fisher/Gauss)**.
4. **Axis: safety gates.** `leaf-tool` CT-flag (actually TL-G1's CHECK) was edited from a guessed `--julia`
   flag to the tool's actual `--root` flag — but only after the tool existed and its real CLI was known; no
   run was scored against the wrong flag first. **Tag: adaptive. Owner: Rose (closeout/claims)** — gate
   text should match the tool's real interface before a leaf is written, but no green was manufactured.
5. **Axis: safety gates.** `leaf-contract` CT-G1 (Fisher-retained families sentence) was reviewed by Rose as
   a manual read, matching the plan's own CT-G2 spec ("G2 (manual, Rose reads it)"); the plan had listed one
   quantity-tolerance gate (G1) and one manual family-sentence gate (G2), while the actual ledger has three
   gates (CT-G1 manual family sentence, CT-G2 automated grep for tolerances, CT-G3 manual Fisher tolerance
   argument) — a 2-gate plan became a 3-gate ledger with the manual/automated split re-assigned. **Tag:
   adaptive** (the extra CT-G3 gate strengthens rather than weakens the check; no gate was demoted from
   automated to manual after a run). **Owner: Rose**.
6. **Axis: model routing / decision authority.** Rebind verdicts were corrected from RE-BINDABLE (scout's
   first pass, based on Julia-only test evidence) to LIKELY-FIXED / LIKELY-FIXED-UNVERIFIED by Ada, on the
   stated ground that a paired cross-engine receipt is required to re-bind a row and Julia-only tests are not
   that receipt. **Tag: adaptive. Owner: Ada** (this is exactly Ada's scope-authority role, exercised and
   recorded in the file itself).
7. **Axis: public claims / scope.** Three owner requirements (grouping-level names, ZI-trio-to-R, capability
   direction) arrived RELAYED via the gllvmTMB lane rather than directly from the maintainer, and all three
   are recorded "to be confirmed by the maintainer directly" rather than acted on. **Tag: adaptive** (correctly
   quarantined as unconfirmed, not silently adopted) — **note: three items relayed, not two as flagged for
   review; recount this before closing the ticket. Owner: Ada**.
8. **Axis: safety gates / execution flow.** Plan mode was toggled off then back on mid-execution, delaying
   the v1 ZI full-run launch (an approved write action) until the toggle completed. **Tag: unclear** — no
   record of who toggled it or why; the delay is real but the cause is not attributable from the artifacts
   read. **Owner: Ada** (to confirm intent, or flag as environmental noise).
9. **Axis: model routing (fan-out budget).** Fisher-retained-family staleness (issue 3 in the after-task
   ledger) surfaced as a side-effect of writing the contract, not from a dedicated audit slice — the plan
   did not allocate a check for `docs/src/gllvmtmb-parity.md` drift. **Tag: adaptive** (Rose's "check every
   neighbour" principle caught it; correctly logged as an open issue, not fixed inline, respecting the
   MUST-STOP on src/docs edits outside scope). **Owner: Rose**.

## Pending at reconcile time

- **CI verdict** (`33622687447` Julia-job conclusions) — `CI_VERDICT_PLACEHOLDER` in the after-task draft;
  `leaf-ci` both gates unchecked.
- **ZI campaign end** — overrun, last read ~140–240/240 chunks; `ZI_END_PLACEHOLDER` in the after-task draft;
  findings write-up explicitly DEFERRED until the run ends; `leaf-zi` ZI-G3 unchecked though the full run
  did launch (receipt exists) — the checkbox lags the substance.
- **K9 MECHANICAL-VERIFY** — not yet dispatched this session (see deviation 1); `leaf-close` both gates
  correctly unchecked as a result.

## Recurring-class candidates (for PLAN-DRIFT-LEDGER)

The clearest repeat-risk pattern here is **pre-run sampling the cheapest cell, not the most expensive one**,
before stating a D-139 wall-time estimate — the same shape as a prior compute-routing lesson (estimate from
the wrong end of the cost distribution, then discover the true cost only after committing to the full run).
A second, softer pattern: **a plan's own sequencing (K9 before K10) getting reordered under context pressure**
without a recorded decision — worth a generic checklist line ("closeout reconciliation runs after, not
instead of, mechanical re-verify") rather than a one-off fix here.
