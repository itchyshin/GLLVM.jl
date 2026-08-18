# Arcs — aghq-a43-afford-20260818 (arc 2 only)

Cite, do not rewrite:
`/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-aghq-stage1b-20260817/docs/dev-log/plans/2026-08-18-seven-arcs-ultraplan.md`

G0 (approved): **2 → 3 → 4**; **5 waits**; **6 and 7 wait**. This lane
runs **arc 2 only**. Do not start 3–7.

Helper contract (Grok scout, binding): one unexported
`_aghq_kd_bound(d::Integer, k::Integer) -> Nothing`. Throw `ArgumentError`
(`"AGHQ Stage 1a: …"`) iff **`k > 1` and `d > 5`**. Do **not** add
`_aghq_d_bound` or `aghq_gate`. Call only from `aghq_stage1a_loglik_site`
after `_aghq_stage1a_reject_extra` (unchanged).

| # | arc | status | gate? |
|---|-----|--------|-------|
| 2a | LOOP kit on this worktree (GOAL / arcs / checkpoint / ultra-plan) | done | — |
| 2b | `_aghq_kd_bound` + call site on `src/families/aghq_grid.jl` | done | — |
| 2c | Fail-loud tests + delete `#253` `!isdefined` absence tests in `test/test_aghq_gate.jl` | done | #255 MERGED @ `81866b1a` |
| 2d | Decision addendum: affordability closed by `_aghq_kd_bound`; eligibility still declared-kwargs | done | #255 MERGED @ `81866b1a` |
| 2e | check-log + after-task; named-path commits; STOP at sibling push/PR | done (this closeout) | OPEN GATE = sibling push onto #256; do not merge |
| 3 | Gate wiring (`false` vs omitted kwargs) | OUT | — |
| 4 | A4(4) site-evaluator / fitter | OUT | — |
| 5 | A4(5) print/AIC/`used` / public `aghq=` | OUT | waits |
| 6 | `none × dep()` Identity | OUT | waits |
| 7 | CV Identity | OUT | waits |

#255 MERGED @ `81866b1a`. Absence tests deleted. Do not invent
`aghq_gate`. No public `aghq=`. Ledger AGHQ stays `missing`.

This worktree’s `LOOP/` is not the overnight / honesty kit.
