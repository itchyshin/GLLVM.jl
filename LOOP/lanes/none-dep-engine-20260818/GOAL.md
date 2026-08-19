# GOAL — none-dep-engine-20260818 (matrix fitter)

Identity ACCEPTED on #260 (`docs/dev-log/decisions/2026-08-18-none-dep-identity.md`).
Do **not** rewrite it.

## Mission

Matrix fitter first: none × dep as K=p full-rank packed Λ.
Same estimand as latent(d=T). No formula sugar this slice.

## In

- `fit_dep_gllvm` → `fit_gllvm(Y; K = p)`
- Reuse `rr_theta_len(p, p) = p(p+1)/2` + pack_lambda
- Focused tests: free count; FD ≤ 1e-6; match latent K=p ≤ 1e-8
- check-log + after-task
- L47 stays **planned** until tests+FD; file hot → leave flip

## Out

- formula FunctionTerm / `(…|g)` / RE-grammar v2 / `dep()` sugar
- bridge.jl, aghq_grid.jl, packing.jl rewrite
- phylo_dep / animal / spatial / kernel
- invented twin Δ
- Dropbox checkout
- Identity rewrite
