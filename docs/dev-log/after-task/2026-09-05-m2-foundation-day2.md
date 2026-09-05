# After-task — M2 Foundation day-2 (integrator slice)

**Date:** 2026-09-05  
**Branch:** `cursor/m2-foundation-day2-20260905` @ `b451ce8d` (stacked on day-1)  
**Lane:** Cursor integrator (worktree `GLLVM.jl-gllvm-twin-20260904`)  
**Lease:** `docs/dev-log/after-task/, docs/dev-log/check-log.md, .cursor/` (4h)

## Scope (integrator-owned)

| Item | Deliverable | Status |
|---|---|---|
| **A** | CI watch on draft PR #294 — report green/red; mark ready if green (**no merge**) | **PARTIAL** — Julia + Documenter green; advisory R red (see below); #294 **ready-for-review**, **not merged** |
| **B** | Worktree hygiene — discard local smoke leftovers | **DONE** |
| **C** | Stitch sibling Poisson commit; push day-2 branch; open stacked draft PR #295 | **DONE** |
| **D** | Totoro T4 queue script (`tools/t4_totoro_gaussian_prerun.sh`; dry-run only) | **DONE** — queued via script; **no launch** (needs Shinichi compute-go) |
| — | This after-task + check-log entry | **DONE** (this report) |

## Out of scope (sibling agents)

| Item | Owner | Status |
|---|---|---|
| Poisson each-own-optimum 2SO smoke (gate-tier A5) | sibling | **DONE** @ `2a029749` |
| CI fix if #294 advisory red | sibling | **WAITING** — Shinichi call on non-gating vs triage |
| Totoro T4 launch | sibling | **BLOCKED** — script only; `GLLVM_TOTORO_LAUNCH=1` not set |

## Evidence

### Poisson 2SO each-own-optimum smoke (A5)

- Driver: `tools/core070_second_order/smoke_poisson_eoo.jl`
- Receipt: `docs/dev-log/core070/poisson-2so-eoo-smoke-receipt-2026-09-05.json`
- Note: `docs/dev-log/core070/poisson-2so-eoo-smoke-2026-09-05.md`
- **PASS** — SE rel 5.81e-6; vcov Fro rel 1.09e-5; CI abs 5.27e-6; ~26.5 s local

### PR #294 CI (final — run [33979515590](https://github.com/itchyshin/GLLVM.jl/actions/runs/33979515590))

| Check | Result |
|---|---|
| Julia 1 + 1.10 (8 shards) | **PASS** |
| Documenter | **PASS** |
| Frozen R 0.7.0 family smoke (advisory; rebuilt oracle) | **FAIL** — 277 pass / **9 fail** (continue-on-error) |
| `mergeStateStatus` | **UNSTABLE** (advisory job only) |
| PR state | **ready-for-review** (draft lifted); **OPEN**, **not merged** |

Nine fail brief: [`advisory-r070-smoke-fail-brief-2026-09-05.md`](../core070/advisory-r070-smoke-fail-brief-2026-09-05.md) — NB2 (1), truncated NB2 (1), Student-t estimated-ν cluster (7).

### Totoro T4 pre-run (dry-run queue)

- Script: `tools/t4_totoro_gaussian_prerun.sh` (default prints rsync + ssh; exit 0)
- Authority: `docs/dev-log/core070/t4-totoro-estimate-2026-09-05.md`
- **Queued only** — no `GLLVM_TOTORO_LAUNCH=1`; no compute-go in this chat

## Worktree hygiene

Discarded (not committed):

- `docs/dev-log/core070/d220-paired-gaussian-cell-receipt-2026-09-05.json` (re-run timings / wrong git_head)
- `tools/core070_second_order/common.jl` (local `_PARITY_TWIN_RLIB` `.libPaths` tweak)
- Untracked smoke dirs: `data/`, `logs/`, `out/`, `tools/core070_second_order/out/`, recovery checkpoints

Worktree clean on `cursor/m2-foundation-day2-20260905`.

## Branch strategy

- **#294 unmerged** → day-2 stacks on `cursor/m2-foundation-day1-20260905` via draft PR [#295](https://github.com/itchyshin/GLLVM.jl/pull/295)
- Merge order: #294 first (Shinichi), then #295

## Claim boundary

- **NOT** true-parity or programme §7 completion
- **NOT** Totoro T4 launch (no compute-go in this chat)
- M2 Foundation smoke evidence only (Poisson each-own-optimum tier)

## Waiting on Shinichi

| Gate | Question |
|---|---|
| **#294 merge** | Accept advisory R smoke as **non-gating** (277/9, continue-on-error) and merge #294? Or triage NB2 / truncated-NB2 / Student-t first? |
| Totoro compute-go | Required before T4 pre-run cell launch (D-139 estimate ready; script queued) |

## Review lenses

| Lens | Verdict |
|---|---|
| Hopper | Poisson fixture matches batch-1 / parity harness — OK |
| Fisher | Tolerances cite signed contract §4; cond scale not triggered — OK |
| Rose | Claim boundary explicit; stacked PR strategy honest while #294 open — OK for draft |

**Integrator verdict:** M2 Foundation day-2 **PARTIAL** — B/C/D done; Poisson smoke stitched; #294 Julia+Documenter green; advisory R 277/9 blocks UNSTABLE until Shinichi call; Totoro queued dry-run only.
