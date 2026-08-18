# Ultra-plan — gllvmjl-parity-beyond (FROZEN at G0 2026-08-18)

**Status:** G0 APPROVED. Binding detail for the running `/goal`.
**Lane:** `cursor/lane-parity-beyond-20260818`
**Worktree:** `~/local-scratch/lanes/GLLVM.jl-parity-beyond-20260818`
**Base:** `origin/main` **`3d5acba0`**
**Do not mutate this file mid-run.** GOAL.md wins on what must never be lost.

This is the approved programme (Shinichi **approve!** 2026-08-18), not the
overnight A4(3) plan and not the Stage-1b AGHQ ultra-plan that previously
lived at this path on `origin/main`.

---

## Arc order (derived; status lives in `arcs.md`)

1. **P1 Identity** — multinomial / categorical, docs only. Twin fid 16.
   Ledger stays `missing`. STOP before `src/`.
2. **P1 engine** — after Identity is on a pushed branch (sibling push/PR).
   Not in the same arc as Identity.
3. **P2 owed bridges** — `truncated_nbinom2` Arc1b (fid 11, per-trait
   `log_phi_truncnb2`); `lognormal` bridge + light RCall Δ (fid 3).
   `truncated_poisson` fid 10 is **not** restamped OWED.
4. **P3 Tweedie T2–T5** — T6 already paid (#236/#238). `fit_gllvm` admit STOP.
5. **E** — AGHQ 2 → 3 → 4 **after** affordability `/goal` STOPs. A4(5) waits.
   Do not touch `src/families/aghq_grid.jl` while #255 is open.
6. **C** — covariance grammar, cheapest first = `none × dep()`. File-disjoint.
7. **X** — coverage certificate. Totoro/DRAC only if Shinichi sizes+asks.

## Affordability lock (do not abort)

In-flight A4(3) affordability `/goal`:
`~/local-scratch/lanes/GLLVM.jl-aghq-a43-afford-20260818`
branch `cursor/lane-aghq-a43-afford-20260818` — **OPEN GATE #255** —
owns `test/test_aghq_gate.jl`. Helper already on `src/families/aghq_grid.jl`.

This programme **must not** touch those files, the honesty worktree
`GLLVM.jl-a43-honesty-20260818`, overnight `LOOP/GOAL.md`, or the Dropbox
checkout.

## Twin pins

- Multinomial Identity: twin `origin/main` **`af1218d8`**; Julia **`3d5acba0`**.
- Decision: `docs/dev-log/decisions/2026-08-18-multinomial-identity.md`.
- Do not alias `categorical()`. No invented Δ.

## Full mission fence

See `LOOP/GOAL.md` (immutable). That file is the complete In / Out /
Invariant / Definition of done. This file is the frozen plan pointer and
arc order.
