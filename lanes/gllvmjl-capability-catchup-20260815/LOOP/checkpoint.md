GOAL: binding plan `docs/dev-log/plans/2026-08-15-truncated-nbinom2-identity-engine.md` (G0 LOCKED · Ada defaults).
STATE: Identity+engine+focused GREEN locally; await #205 merge then rebase/PR.
BINDING CONTRACT: `docs/dev-log/plans/2026-08-15-truncated-nbinom2-identity-engine.md`
  Ada: Arc1 shared scalar `r` (Julia `r` ≡ twin `φ`); twin per-trait documented; Arc1b OWED.
ARCS DONE (verified):
- S1 Identity ACCEPTED `2026-08-15-truncated-nbinom2-identity.md`
- S2 Engine `truncated_nbinom2.jl` + wire
- S3 focused **11/11 Pass**; max_abs_FD=1.12e-7
- S4 ledger flip `truncated_nbinom2` → implemented
- S5 after-task + check-log + board + Melissa plan-actual
ARC IN PROGRESS: S0 #205 merge-gate (Documenter PASS; Julia CI IN_PROGRESS @ `b2b99463`)
NEXT: merge #205 on green → rebase this branch onto origin/main → push PR → merge-on-green → MC julia_surface PROPOSE
OPEN GATES: #205 Julia CI; post-merge rebase; optional full Pkg.test before/with PR
TRUTH LIVES IN:
- Plan / after-task / plan-actual under docs/dev-log/
- Branch `cursor/truncated-nbinom2-20260815` @ this WT tip
RESUME: Binding plan path above. Sole #205 merger if still OPEN. Do not spawn competing /goal.
Rose: ≠ invent ZIP/ZINB Δ ≠ Phylo #127 ≠ ADEMP ≠ silent rtol. Do NOT write Dropbox protected fork.
