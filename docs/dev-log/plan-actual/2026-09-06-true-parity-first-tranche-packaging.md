# First-tranche packaging receipt — 2026-09-06

Lane: `cursor/ultra-plan-true-parity-remainder-20260906` (PR [#308](https://github.com/itchyshin/GLLVM.jl/pull/308))
Worktree: `~/local-scratch/lanes/GLLVM.jl-ultra-plan-true-parity-remainder-20260906`
Plan: `docs/dev-log/plans/2026-09-06-ultra-plan-true-parity-remainder.md`
Recorded: 2026-09-06, while the authorised merge queue was still finishing.

This is the P1 packaging note. It records what G0 authorised and what has been
pushed. It does not merge PRs, promote capability rows, or claim true parity.

## Destination

**B**, not “0.7.1 parity.”

The signed destination remains `v0.true-parity`: retained paired evidence for
the owner-approved 42-row gate tier, against frozen gllvmTMB 0.7.0. That is
not a claim that every capability-ledger row is covered. A later gllvmTMB
0.7.1 DESCRIPTION bump does not change the oracle. Class-1 catch-up stays
deferred.

## G0 lock

PR [#308](https://github.com/itchyshin/GLLVM.jl/pull/308) @ `4a8def47`
(`4a8def473ab1286366646a24b8f8376a9b199795`).

Shinichi answered **ALL YES** to Q1–9 on 2026-09-06. Status is G0 approved;
execution of this first tranche is authorised.

1. Push A+D = YES
2. Merge #301 → #297 → #304 then #306 = YES
3. First build after A = YES (P3 next bounded M2/M3 scope; not M2-R2)
4. M2-R2 stays stopped = YES
5. NB2 A11 keep `partial` = YES
6. D = bridge-evidence only = YES
7. Local smokes only = YES
8. Class-1 deferred / frozen 0.7.0 = YES
9. Launch via `/goal` after this packaging lands = YES

## A and D — pushed

| Slice | Repo | PR | SHA | Subject |
|---|---|---|---|---|
| A — M2 S1/S2 remainder | GLLVM.jl | [#309](https://github.com/itchyshin/GLLVM.jl/pull/309) | `c422374c` | docs: record M2 remainder S1/S2 EOO receipts without a true-parity claim |
| D — Julia kernel bridge | GLLVM.jl | [#307](https://github.com/itchyshin/GLLVM.jl/pull/307) | `75d0a37c` | docs: record kernel-bridge Rose claim audit |
| D — paired R bridge | gllvmTMB | [#1274](https://github.com/itchyshin/gllvmTMB/pull/1274) | `c717a5720` | docs: record kernel-bridge Rose claim audit |

A is local EOO / `se=TRUE` schema evidence for Binomial, Beta, and NB2. It is
not M5 completion. D is packaging and bridge evidence only.

## Merge queue progress

Authorised order remains **#301 → #297 → #304 then #306**. This sitting does
not merge any of them.

| PR | Role | State at this receipt |
|---|---|---|
| [#301](https://github.com/itchyshin/GLLVM.jl/pull/301) | θ-map harness `log_phi` length | **MERGED** 2026-09-06T17:28:32Z (`8602293f`) |
| [#297](https://github.com/itchyshin/GLLVM.jl/pull/297) | T4 P6 Totoro grid | Conflict resolved; `MERGEABLE`; CI pending. Resume the queue after green. |
| [#304](https://github.com/itchyshin/GLLVM.jl/pull/304) | Choose R / Julia / bridge page | Queued behind #297 |
| [#306](https://github.com/itchyshin/GLLVM.jl/pull/306) | Destination G0 plan | Queued after #304 |

## Fences that still hold

- **NB2 A11 stays `partial`.** Do not promote it to covered from A’s smoke receipts.
- **D is bridge-evidence only.** No capability promotion beyond the current
  receipts; no R-engine edit from this lane.
- **No public parity claim.** Packaging is not `v0.true-parity` completion and
  not “0.7.1 parity.”
- **M2-R2 stays stopped** until a new G0.
- **Compute stays local smokes** until a separate D-139 estimate and G0.
- **0.7.1 Class-1 stays deferred.** The frozen oracle is gllvmTMB 0.7.0.

## What this receipt does not do

It does not merge #297, #304, #306, #307, #308, #309, or gllvmTMB #1274. It
does not start M2-R2, P4 implementation, Totoro/DRAC, or a public claim. The
next sitting may launch the approved first tranche via `/goal` after this
note is on the #308 branch.

## Pointers

- Plan and G0 lock: `docs/dev-log/plans/2026-09-06-ultra-plan-true-parity-remainder.md`
- Programme canon: #291
- Destination decision: #306
- M2 baton: #303
- Unlazy tranche ledger: `.unlazy/true-parity-remainder-20260906/`
