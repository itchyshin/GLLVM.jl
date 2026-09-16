# S4 public-formula probe — Julia-side checklist (paste-gated DRAFT)

**DRAFT:** do **not** run the probe, do **not** merge engine changes, do **not** edit gllvmTMB `src/` until maintainer paste **`S4 probe yes`**.

**Goal gate:** [`LOOP/GOAL.md`](../../LOOP/GOAL.md) QS4 (second explicit yes only).

**Twin recorder (read-only reference):** gllvmTMB draft [PR #1283](https://github.com/itchyshin/gllvmTMB/pull/1283), commit **`97214679c`** on `origin/codex/destination-b-s4-phylo-dep-formula-20260910` ([G9 push receipt](../after-task/2026-09-14-destb-g9-s4-recorder-push.md)).

This checklist is **Julia-side prep only**. No probe execution from cloud / Cursor without the paste.

---

## Paste unlock

| Paste (exact) | Agent may |
|---------------|-----------|
| `S4 probe yes` | Execute isolated S4 Julia probe vs recorder artifacts; file receipt under `docs/dev-log/after-task/`; update DestB / GOAL checkboxes. |

---

## Pre-flight (before any probe run)

- [ ] Confirm recorder ref fetchable: `git ls-remote origin codex/destination-b-s4-phylo-dep-formula-20260910` → tip `97214679c…`
- [ ] Read gllvmTMB #1283 scope (formula / fixture contract only; **no** TMB edits from GLLVM.jl lane)
- [ ] Frozen oracle pin unchanged: `b4d5fee64def88bc768dda1f1f77c29b295edd86`
- [ ] Identify Julia entry script (DestB isolated runner; do not invent a second driver without Hopper review)
- [ ] D-50: probe on **local Mac-light** or **Totoro** with maintainer compute ack if wall clock >30 min (separate from #323 Track A ack)

---

## Julia-side execution checklist (after paste)

1. Check out GLLVM.jl at programme tip; `Pkg.instantiate()`; single Julia process.
2. Materialize or load S4 fixture bundle aligned with recorder commit (wide/long public formula path for **`phylo_dep()`** cell per DestB scope).
3. Run isolated probe; capture **pass/fail table** + log paths (no GitHub Actions artifacts).
4. Classify each failure: Julia surface gap vs recorder drift vs R-oracle defect (do not widen `@test` rtol).
5. Write after-task: scope boundary (probe receipt ≠ Arc 0 promotion ≠ capability row `covered`).
6. Update pending board + paste packet only via docs PR (no silent GOAL complete).

---

## Fences

- **No** gllvmTMB engine surgery from this repo.
- **No** S4 probe without **`S4 probe yes`** (this document does not substitute for the paste).
- **No** claim that S4 closure implies honest-0.7 FINAL-REVIEW complete.

---

## Related DRAFTs

| Paste | Scaffold |
|-------|----------|
| `G0 Stage 1` | [`2026-09-16-d3-loading-profile-stage1-paste-gated-scaffold.md`](2026-09-16-d3-loading-profile-stage1-paste-gated-scaffold.md) |
| `ack Totoro D-139 #323 Track A` | [`2026-09-16-totoro-323-track-a-runbook-paste-gated.md`](2026-09-16-totoro-323-track-a-runbook-paste-gated.md) |
