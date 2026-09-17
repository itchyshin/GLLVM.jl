# True-parity paste packet (post-#402 paste-gated scaffolds)

<!-- slop-ok: paste-packet field labels (**STATE:** / Tip / Twin) match prior owed packets -->

STATE: **IN PROGRESS**. Do **not** mark the programme or `/goal` complete.

**Rehydrate:** `git fetch origin main && git rev-parse origin/main`  
Tip (2026-09-17): **`e590eb9ec`** ([#418](https://github.com/itchyshin/GLLVM.jl/pull/418) paste-ready status); paste DRAFT harnesses rebased on tip — **[#399](https://github.com/itchyshin/GLLVM.jl/pull/399)** @ `0736950a4` (Delta A), **[#411](https://github.com/itchyshin/GLLVM.jl/pull/411)** @ `627007faa` (Stage 1), **[#409](https://github.com/itchyshin/GLLVM.jl/pull/409)** @ `fd39c476c` (S4), **[#410](https://github.com/itchyshin/GLLVM.jl/pull/410)** @ `68b78cb4f` (Totoro): **MERGEABLE + Julia green; still DRAFT until paste** (Frozen R advisory may fail).

**Twin:** gllvmTMB `origin/main` @ `02b46cfc8`; frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86`; **`Project.toml` stays `0.3.0`**.

**Board:** [`2026-09-14-true-parity-pending-board.md`](../2026-09-14-true-parity-pending-board.md)  
**Supersedes:** [`2026-09-16-post-399-paste-packet.md`](2026-09-16-post-399-paste-packet.md) (four paste strings unchanged).

---

## Adversarial scorecard (2026-09-17 @ `e590eb9ec` + #402 MERGED / DRAFT harnesses tip-aligned)

| Named item | Verdict | Evidence |
|------------|---------|----------|
| Ledger gap | **DONE** (inventory) | [`after-task/2026-09-15-true-parity-ledger-gap-inventory.md`](../after-task/2026-09-15-true-parity-ledger-gap-inventory.md) |
| §2 A (delta dispersion) | **PASTE-GATED** | DRAFT **[#399](https://github.com/itchyshin/GLLVM.jl/pull/399)**; paste `accept delta dispersion A` |
| #402 runbooks (Stage1/S4/Totoro) | **DONE** | MERGED @ `08ca9e487` |
| D3 Stage 1 | **PASTE-GATED** | DRAFT **[#411](https://github.com/itchyshin/GLLVM.jl/pull/411)** + [`plans/2026-09-16-d3-loading-profile-stage1-paste-gated-scaffold.md`](../plans/2026-09-16-d3-loading-profile-stage1-paste-gated-scaffold.md); paste `G0 Stage 1` |
| S4 public-formula probe | **PASTE-GATED** | DRAFT **[#409](https://github.com/itchyshin/GLLVM.jl/pull/409)** + S4 checklist; paste `S4 probe yes` |
| Totoro #323 Track A | **PASTE-GATED** | DRAFT **[#410](https://github.com/itchyshin/GLLVM.jl/pull/410)** + Totoro runbook; paste `ack Totoro D-139 #323 Track A` |
| #357 bridge logLik | **DONE** | MERGED on `main` @ `5ee6dc596` |
| #363 / #314 | **SKIP** | CONFLICTING DRAFT |
| Ungated CI | **#401** node24 | **DONE** @ `c33745302` |

**Ungated implementable engine slice:** **none**. All four paste rows are DRAFT harnesses (**#399**, **#411**, **#409**, **#410**). Paste still required before merge or execution.

---

## Paste → unlocks → first action (Shinichi only)

| Paste (exact) | DRAFT / runbook | After paste |
|---------------|-----------------|-------------|
| `accept delta dispersion A` | DRAFT **[#399](https://github.com/itchyshin/GLLVM.jl/pull/399)** | ready+merge when green; ACCEPTED block + engine closeout + D1 remeasure |
| `G0 Stage 1` | DRAFT **[#411](https://github.com/itchyshin/GLLVM.jl/pull/411)** + **#402** runbook | Merge harness when green; implement bounded slice (`src/` export + fitter pin + confirmatory tests); no ledger bind without fixture evidence |
| `S4 probe yes` | DRAFT **[#409](https://github.com/itchyshin/GLLVM.jl/pull/409)** | Merge harness when green; run probe vs #1283 `97214679c`; no R `src/` edits |
| `ack Totoro D-139 #323 Track A` | DRAFT **[#410](https://github.com/itchyshin/GLLVM.jl/pull/410)** | Merge harness when green; Codex Track A on Totoro per launch pack |

---

## Quick refresh

```bash
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main && git rev-parse origin/main
gh pr view 399 409 410 411 --json isDraft,url
gh pr checks 401
```

Expected `origin/main`: **`e590eb9ec`**. DRAFT heads above after `gh pr update-branch --rebase` onto tip. Goal **not** complete.
