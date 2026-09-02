# Maintainer decisions — true R↔Julia parity replan (2026-09-02)

Taken in one sitting (AskUserQuestion, Claude Code session on lane `codex/core070-aghq-20260830`)
so no later session re-asks them. Companion map: `../core070/true-parity-decision-map.md`.

1. **Direction of the qualification claim: one-directional.** True parity is qualified as *R workflows
   run identically through `engine = "julia"`* against the frozen gllvmTMB 0.7.0 oracle. The reverse
   gap (what Julia has that R lacks) is produced by a tool as a written list and handed to the gllvmTMB
   lane as decisions, never as owed work on this lane. (Chosen option: "One-directional".)
2. **Oracle target: stay frozen at 0.7.0** (`b4d5fee64def88bc768dda1f1f77c29b295edd86`). A re-freeze
   gate is scheduled right after the second-order contract lands, because the 0.7.1 total-variance fix
   (ψ_t → ψ_t²) only touches derived confidence intervals. (Chosen option: "Stay 0.7.0".)
3. **Second-order parity scope: standard errors + fixed-effect `vcov` block + Wald confidence-interval
   endpoints.** Fitted values, predictions, residuals, and paired recovery-to-truth are measured where
   cheap but do **not** gate the claim. Tolerances are proposed in
   `../core070/second-order-parity-contract.md` and signed separately (ticket T3-tolerances).
4. **Go on the knowable slices** (ledger recount, re-bind check of the 8 estimand-defect rows, contract
   draft, se=TRUE pre-run on Totoro ≤ 30 min, both-direction ledger tool, R-side defect list to the R
   lane, map committed); local commits only; no push while CI run 33622687447 is live.

## Relayed by the gllvmTMB lane the same day — recorded, awaiting direct confirmation

- *"Make sure both Julia and R have `unit_obs`, `unit`, `cluster` and `cluster2` — it is important."*
  → new R→Julia required row family + naming rows keyed by the four level names (ticket T12).
- *"Bring zip/zinb/zib to R."* → R gains the ZI trio natively; supersedes decision #12's "no R twin" on
  the R side only.
- *"Both ways, for user-facing capabilities; the bridge stays R→Julia."* → compatible with decision 1
  above: the claim runs one way, capabilities are tracked both ways. **Confirmed directly the same
  day as vault D-204** (Shinichi, drmTMB session: *"both ways for user-facing; keep the legacy
  rewrite; file the issues"*); no longer relayed-only.

Compute decisions of the day (plan v1): the ZI-trio ADEMP campaign runs on Totoro (Narval has no live
socket; Nibi under a full-cluster maintenance reservation until 2026-09-03 08:00).

## Overnight envelope (Shinichi, 2026-09-02 ~23:05Z, AskUserQuestion, four answers)

5. **Pushes and CI**: up to three pushes overnight; shard the CI suite into parallel jobs and
   drop coverage on routine runs (full matrix and coverage stay on `workflow_dispatch`).
6. **Phylo Q1–Q4**: the recorded defaults are accepted — opt-in `correlation=true` (bridge forces
   it); dense `vcv=` admitted with a condition-number warning; kernel split to its own slice;
   non-ultrametric trees deferred behind `GJL-GATE-PHYLO-NONULTRAMETRIC`. S1–S2 may proceed.
7. **Ledger authority**: re-bind rows on passing paired receipts; flip the `mi()` status row to
   implemented on a test receipt; every flip listed in the morning report.
8. **Arc scope**: second-order receipts on all paired cells; T5 paired re-runs; T4 realistic-size
   pre-run; ZI-trio + scoreboard docs; *"consider using DRAC cleverly"* → Nibi array queued to
   start when its maintenance lifts (08:00 EDT), Totoro for pre-runs and the suite.
