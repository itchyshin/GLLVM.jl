GOAL: see GOAL.md. Binding plan: `docs/dev-log/plans/2026-08-15-parallel-family-catchup-3to5.md` (G0 LOCKED · Ada 4-set).
STATE: Wave1 Identity docs ACCEPTED + PRs opened; waiting CI green before W1-admit merge. #205 still OPEN — base remains catch-up tip lineage.
ARCS DONE (verified):
- W0 scaffold: plan + LOOP @ programme `66dc3e90` · PR #206
- W1-lognormal-Id: decision ACCEPTED @ `06a3b5a1` · PR #207
- W1-zibx-Id: decision ACCEPTED @ `0625316a` · PR #208
- W1-censored-Id: decision ACCEPTED @ `6ab338f8` · PR #209
ARC IN PROGRESS:
- W1-admit: wait CI green on #206–#209 then merge (docs-only; merge-on-full-CI-green)
NEXT: on CI green → merge Identity PRs → open Wave2 engine WTs (lognormal / ZIB+X / censored) from post-admit tip (or catch-up tip if #205 still open) → engines|| on ownership matrix
OPEN GATES: Wave1 PR CI before admit; do not merge engines until Identity PRs merged; never touch truncated_nbinom2
TRUTH LIVES IN:
- Plan: `docs/dev-log/plans/2026-08-15-parallel-family-catchup-3to5.md`
- LOOP: `lanes/gllvmjl-parallel-family-catchup-20260815/LOOP/`
- Programme: https://github.com/itchyshin/GLLVM.jl/pull/206 @ `66dc3e90`
- Identities: #207 `06a3b5a1` · #208 `0625316a` · #209 `6ab338f8`
- #205 observe-only: https://github.com/itchyshin/GLLVM.jl/pull/205
- nbinom2 OWNED: `.worktrees/gllvmjl-truncated-nbinom2-20260815` — DO NOT TOUCH
RESUME: You are parallel-family-catchup conductor. READ FIRST: LOOP/GOAL.md → checkpoint.md → ultra-plan.md. CONTINUE FROM: W1-admit (merge #206–#209 on CI green) then Wave2 engines|| for lognormal + ZIB+X + censored_poisson only. Never touch truncated_nbinom2 / Dropbox fork. Compute=local tiny+FD; Julia-forward OK; ≠ invent ZIP/ZINB Δ; ≠ ADEMP. Fan-out≤6. Stage by name; push/PR on green; merge on full CI green.
