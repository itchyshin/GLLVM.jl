# Destination B — Done-when hard verification (Rose)

**Date:** 2026-09-14  
**Auditor:** Rose (claim vs evidence)  
**Branch:** `cursor/honest-070-destb` @ **`4765d041`** (PR [#336](https://github.com/itchyshin/GLLVM.jl/pull/336) OPEN)  
**`origin/main`:** `23fd0496`  
**Constraints honoured:** no merge, no Totoro, no S4 probe, no version bump.

## Live commands (this session)

| Check | Command | One-line proof |
|---|---|---|
| Tip | `git rev-parse --short HEAD` | `4765d041` = `gh pr view 336` `headRefOid` prefix |
| Version fence | `rg '^version = ' Project.toml` | `version = "0.3.0"` |
| DestB scope | `node tools/destination_b_scope_check.mjs` | exit **0**; trailing `SCOPE_HISTORY_AND_NEGATIVE_CONTROLS_PASS` |
| Scope on `main` | checkout `origin/main` + same node command | same **PASS** (32-row identity tool green on both tips) |
| 2026-09-14 receipts on `main` | `git cat-file -e origin/main:docs/dev-log/after-task/2026-09-14-destb-api-boundary.md` | **missing** (bundle lives on #336 only) |
| Arc 0 matrix on `main` | `git show origin/main:docs/design/capability-status.md \| rg phylo_dep` | still **`planned`** — G2 Rose promotion **not** on `main` |
| PR CI | `gh pr checks 336` | Documenter + deploy **pass** (docs-only diff; no Julia 8-shard on this PR) |

## Done-when table (items 1–3 only)

| # | Requirement | Evidence | Verdict |
|---|-------------|----------|---------|
| **1** | Destination B **admitted scope** has honest evidence/disposition | `tools/destination_b_scope_check.mjs` PASS @ branch tip; static **API-BOUNDARY** [`2026-09-14-destb-api-boundary.md`](2026-09-14-destb-api-boundary.md); B1/S3b/S4 dispositions in [`2026-09-14-destb-final-review-panel.md`](2026-09-14-destb-final-review-panel.md) Rose §1 (incl. “must NOT claim 32/32 closed”); `main` retains #318-era G1/G2 (`2026-09-13-destination-b-g1-static-audit.md`, `2026-09-13-destination-b-g2-b1-s3b.md`) | **PASS** on **#336 branch receipts** · **not** replicated on `origin/main` until merge |
| **2** | LOOP **covariance grid** closed or waived with Rose | [`LOOP/arcs.md`](../../LOOP/arcs.md) rows **#9–#15** = `done`; Rose G2 audit **PASS** in [`2026-09-14-destb-g2-capability-promotion.md`](2026-09-14-destb-g2-capability-promotion.md); panel §4 **FINAL-REVIEW** affirms Arc 0 grid **as documented on this branch** (§271) — engine merges #324–#334 already on `main`; **documented Rose promotion** only on #336 | **PASS** (grid + Rose fence on branch) |
| **3** | Joint version **proposal** exists; **`Project.toml` still 0.3.0** | [`2026-09-14-destb-g11-joint-version-proposal-stub.md`](2026-09-14-destb-g11-joint-version-proposal-stub.md) present; live `Project.toml` `0.3.0`; no version commit in `git log -5 -- Project.toml` on branch | **PASS** |

**Done-when score (1–3):** **3 PASS**, **0 FAIL**.

## Not Done-when (written programme gates — OWED follow-ons)

No decision file elevates **#323 live smoke** or **#336 merge** to Done-when **1–3** blockers. They **do** block **parent `/goal` complete** and honest **main** landing:

| Item | Status | Authority |
|------|--------|-----------|
| **#336 merge** | OPEN draft; docs/LOOP + `capability-status.md` G2 block off `main` | [`LOOP/GOAL.md`](../../LOOP/GOAL.md) STOP fence; [`2026-09-14-destb-goal-completion-audit.md`](2026-09-14-destb-goal-completion-audit.md) §Goal-complete |
| **#323** advisory Frozen R smoke | Handoff only; issue open; **no Totoro** this slice | G7 receipt; G11 stub §#323 **HELD**; ultra-plan G7 = Codex after D-139 |
| **S4 public-formula probe** | Recorder on origin; **probe not run** | G0 Q2 second yes **not** given; [`LOOP/GOAL.md`](../../LOOP/GOAL.md) unchecked S4 probe |
| Formal G11 → `docs/dev-log/decisions/…` | Optional promote from stub | GOAL unchecked line 51 |

## Rose verdict

**Done-when (1–3): PASS** on branch tip `4765d041` with live scope-check corroboration.

**UpdateGoal / programme complete: NO** — receipts not on `main`; #323 und dispositioned; S4 probe held.

**Corrections already tracked:** T15 summary arithmetic + G10 banner artifact (panel PASS-WITH-CORRECTIONS); do not cite panel §3 item 5 “G11 does not exist” — **superseded** by G11 stub on same branch.

**Do not merge #336** in this slice (maintainer act only).
