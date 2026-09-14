# Destination B — honest-0.7 goal completion audit (Done-when)

**Date:** 2026-09-14  
**Auditor:** Ada (Cursor)  
**Lane tip:** `cursor/honest-070-destb` @ `45363995`  
**Draft PR:** [#336](https://github.com/itchyshin/GLLVM.jl/pull/336) (OPEN)  
**Frozen oracle:** gllvmTMB `b4d5fee64def88bc768dda1f1f77c29b295edd86`  
**Probe / Totoro:** **not run** in this audit slice (per G0 envelope).

## Live verification (this session)

| Check | Command / source | Result |
|---|---|---|
| Branch tip | `git rev-parse --short HEAD` on `cursor/honest-070-destb` | `45363995` — matches PR #336 head |
| `Project.toml` version | `rg '^version = ' Project.toml` | `0.3.0` — unchanged |
| DestB scope tool | `node tools/destination_b_scope_check.mjs` | exit 0; `SCOPE_HISTORY_AND_NEGATIVE_CONTROLS_PASS` |
| PR #336 CI | `gh pr checks 336` (2026-09-14) | **Documenter** + **documenter/deploy** SUCCESS ([run 34869801594](https://github.com/itchyshin/GLLVM.jl/actions/runs/34869801594)); **no Julia 8-shard matrix** on this docs-only diff |
| Branch vs `main` | `git diff origin/main...HEAD --stat` | 18 files, **docs/LOOP only** — zero `src/` / `test/` |
| G11 stub | file read | [`2026-09-14-destb-g11-joint-version-proposal-stub.md`](2026-09-14-destb-g11-joint-version-proposal-stub.md) — proposal only; explicitly keeps `0.3.0` |
| FINAL-REVIEW panel | file read | [`2026-09-14-destb-final-review-panel.md`](2026-09-14-destb-final-review-panel.md) — Rose+Fisher **PASS-WITH-CORRECTIONS**; lists #323 / S4 probe as open |
| #323 handoff | file read | [`2026-09-14-destb-g7-frozen-r-smoke-handoff.md`](2026-09-14-destb-g7-frozen-r-smoke-handoff.md) — Codex/Totoro scoped; **no live smoke** |
| S4 recorder | `git ls-remote origin refs/heads/codex/destination-b-s4-phylo-dep-formula-20260910` (gllvmTMB) | tip `97214679c…`; draft **#1283** OPEN; **probe not run** |
| LOOP vs reality | `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md` | Grid #9–#15 **done** with Rose fences; GOAL checklist matches branch receipts; formal G11 decision doc still optional |

## Done-when requirement table

| Requirement | Evidence path | Verdict |
|---|---|---|
| **(1) Destination B admitted scope has honest evidence/disposition** | G1 [`2026-09-14-destb-api-boundary.md`](2026-09-14-destb-api-boundary.md); G2 [`2026-09-14-destb-g2-capability-promotion.md`](2026-09-14-destb-g2-capability-promotion.md); G4–G6 T13–T15 receipts; G10 prep + [`2026-09-14-destb-final-review-panel.md`](2026-09-14-destb-final-review-panel.md); live `destination_b_scope_check.mjs` PASS @ branch tip | **PASS** (evidence on branch) · **HELD** until #336 merged **or** maintainer accepts draft receipts without merge |
| **(2) LOOP grid closed or waived with Rose** | `LOOP/arcs.md` rows #9–#15 **done**; G2 promotion in `docs/design/capability-status.md` (Arc 0 qualifiers; `spatial_dep` stays `planned` fail-loud); panel §1 Arc 0 discipline | **PASS** |
| **(3) Joint version *proposal* exists without `Project.toml` bump** | [`2026-09-14-destb-g11-joint-version-proposal-stub.md`](2026-09-14-destb-g11-joint-version-proposal-stub.md); live `Project.toml` `0.3.0` | **PASS** |
| **HEADLINE #323 advisory Frozen R smoke (full programme objective)** | G7 handoff only; issue **#323** open; Totoro **not run**; G11 stub + panel list as blocker | **HELD** — needs **Codex execute + receipt** **or** maintainer **waive** to keep-advisory-non-gating |
| **S4 public-formula probe (GOAL gate, not Done-when #1–3)** | G9 push receipt; gllvmTMB **#1283**; G0 Q2 second yes **not given** | **HELD** |
| **Cursor `/goal` complete (parent UpdateGoal)** | This audit + `LOOP/checkpoint.md` | **HELD** — see §Goal-complete rule below |

### Done-when score (items 1–3 only)

| | Count |
|---|---:|
| **PASS** | **3** |
| **HELD** (within Done-when #1 merge acceptance) | **1** sub-gate (#336 land) |
| **FAIL** | **0** |

Interpretation: the three **explicit Done-when bullets** are satisfied **on draft PR #336** with live scope-check corroboration. Programme **goal complete** for the parent still **fails** because #323 is not dispositioned and receipt branch is not on `main`.

## Goal-complete rule (parent `UpdateGoal`)

**UpdateGoal complete: NO**

Allow **YES** only when **all** of:

1. Done-when **(1)–(3)** PASS **and** receipts on `origin/main` (or maintainer explicitly waives merge),
2. **#323** either **executed** (Totoro receipt) **or** **waived in writing** to remain advisory non-gating,
3. `Project.toml` remains **`0.3.0`** (until a separate version act).

S4 probe remains **out of scope** for Done-when 1–3 but stays **open** in `LOOP/GOAL.md` until second G0 yes.

## Shinichi one-liner choices (paste-ready)

1. **#336 merge:** `Merge draft PR #336 (docs receipts only) when Documenter-green is enough for you — Julia matrix did not re-run on this diff.`
2. **D-139 / #323:** `Authorise Codex Totoro Track A from g7 handoff after you paste D-139 ack — or waive #323 as permanently advisory non-gating.`
3. **#323 waive (alternate):** `Waive live #323 smoke; keep Frozen R job advisory non-gating indefinitely (document in decisions/).`
4. **S4 probe:** `Do not run S4 probe until I give second explicit yes after reviewing gllvmTMB #1283 / 97214679c.`

## Rose note

Panel memo already **PASS-WITH-CORRECTIONS** with hygiene applied on branch (`215318e5`). This audit does **not** promote capabilities or version semantics; it only maps Done-when vs open gates.

## Follow-up (not in this slice)

- Merge #336 (maintainer),
- Codex #323 campaign (D-139),
- Optional G11 stub → formal `docs/dev-log/decisions/…`,
- S4 probe (second G0 yes),
- Parent `UpdateGoal` complete only after §Goal-complete rule satisfied.
