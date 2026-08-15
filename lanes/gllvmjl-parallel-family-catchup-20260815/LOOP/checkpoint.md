GOAL: see GOAL.md. Binding plan: `docs/dev-log/plans/2026-08-15-parallel-family-catchup-3to5.md` (G0 LOCKED · Ada 4-set).
STATE: Programme scaffolded; Wave1 Identity || launched on 3 WTs from catch-up tip `b2b99463` (#205 OPEN — not post-merge main).
ARCS DONE (verified):
- W0 scaffold: plan + LOOP + worktrees (programme + lognormal/zib-x/censored Identity) @ `b2b99463`
ARC IN PROGRESS:
- W1-lognormal-Id · WT `.worktrees/gllvmjl-lognormal-identity-20260815` · branch `cursor/lognormal-identity-20260815`
- W1-zibx-Id · WT `.worktrees/gllvmjl-zib-x-identity-20260815` · branch `cursor/zib-x-identity-20260815`
- W1-censored-Id · WT `.worktrees/gllvmjl-censored-poisson-identity-20260815` · branch `cursor/censored-poisson-identity-20260815`
NEXT: land 3 Identity decision docs → stage-by-name commit → push/PR → wait CI green → W1-admit
OPEN GATES: Wave1 PR CI before admit; do not start Wave2 engines until Identities ACCEPTED
TRUTH LIVES IN:
- Plan: `docs/dev-log/plans/2026-08-15-parallel-family-catchup-3to5.md`
- LOOP: `lanes/gllvmjl-parallel-family-catchup-20260815/LOOP/`
- Programme WT `.worktrees/gllvmjl-parallel-family-catchup-20260815` @ branch `cursor/parallel-family-catchup-20260815`
- #205 observe-only: https://github.com/itchyshin/GLLVM.jl/pull/205
- nbinom2 OWNED: `.worktrees/gllvmjl-truncated-nbinom2-20260815` — DO NOT TOUCH
RESUME: You are parallel-family-catchup conductor. READ FIRST: LOOP/GOAL.md → checkpoint.md → ultra-plan.md → plan path above. CONTINUE FROM: Wave1 Identity || (3 WTs). Pause at Wave1 CI admit. Never touch truncated_nbinom2 / Dropbox fork. Compute=local tiny+FD; Julia-forward OK; ≠ invent ZIP/ZINB Δ; ≠ ADEMP. Fan-out≤6. Stage by name; push/PR when wave green; merge on full CI green.
