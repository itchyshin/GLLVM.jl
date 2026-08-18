# Ultra-plan (frozen at G0) — arc 2 only

**Cite, do not rewrite** the approved seven-arc plan:

`/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-aghq-stage1b-20260817/docs/dev-log/plans/2026-08-18-seven-arcs-ultraplan.md`

G0 answers (binding): **2 → 3 → 4**; **5 waits**; **6 and 7 wait**. This
file is the arc-2 extract. It is not a new plan.

## This lane

A4(3) **affordability** half (plan S2 / arc 2).

Binding helper contract (do not re-derive Hopper):

```julia
_aghq_kd_bound(d::Integer, k::Integer) -> Nothing
```

Argument order matches `aghq_grid(d, k)`. Throw `ArgumentError`
(`"AGHQ Stage 1a: …"`) iff **`k > 1` and `d > 5`**. Return `nothing`
when affordable. Error text names tensor cost `k^d` and `d ≤ 5`. Never
say treewidth / min-fill / `spHess` / `.aghq_gate`. Do not compute huge
`k^d` as Int. Do **not** add `_aghq_d_bound` or `aghq_gate`.

Call site only from `aghq_stage1a_loglik_site`, in this order:

1. existing `k ≥ 1` check
2. `_aghq_stage1a_reject_extra(...)` **unchanged**
3. `d = size(Λ, 2)`
4. `_aghq_kd_bound(d, k)`
5. `aghq_grid(d, k)`

`k == 1`, any `d`: pass — still evaluate the Laplace template. `k>1`,
`d≤5`: pass. `k>1`, `d>5`: throw. Declared extras (e.g. `phylo=true`)
throw first.

## Collision

`src/families/aghq_grid.jl` is **not** on #255. Helper + call site may
land from `origin/main` `@ 3d5acba0`.

**OPEN GATE: wait #255 MERGED** before editing `test/test_aghq_gate.jl`
or `docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md`.

Pending tests (notes only until the gate opens): bound(6,3) and (6,2)
throw; site k=3 d=6 throws; phylo=true still wins; bound(5,3),(1,3),(6,1),(20,1)
nothing; k=1 K=6 still ≈ Laplace; k=3 K=2 adapt golden still passes;
k=3 d=5 does not throw. Delete the three `!isdefined` absence tests.
Optional: keep `!isdefined(:aghq_gate)` in a renamed not-a-TMB-port testset.

## Fences

Arc 3–7 OUT. No TMB port, no stub `aghq=`, no ledger promote, no merge
from this worktree. Never honesty worktree. Never Dropbox checkout.
