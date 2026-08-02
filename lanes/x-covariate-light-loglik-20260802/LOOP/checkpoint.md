GOAL: see GOAL.md.   STATE: COMPLETE (local; push gated).
ARCS DONE (verified):
- S0 worktree @ 4d19c503; twin 910ebd54; R lib /tmp/R-gllvmtmb-x-parity-20260802
- S1 fit_gllvmtmb_parity_loglik_x + parity_site_design
- S2 test_x_covariate_parity.jl (3 cells) + runparity include
- S3 full parity LOG: X 18/18; Δ ≤ 4e-9; rtol 1e-6 held
- S4–S7 after-task, check-log, board, plan-actual, Rose fence
ARC IN PROGRESS: none
NEXT: push/PR only when maintainer asks
OPEN GATES (need human): push/PR
TRUTH LIVES IN: branch parity/x-covariate-light-loglik-20260802; log
docs/dev-log/x-covariate-parity-full-20260802.log; after-task
docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md
RESUME: Read LOOP/GOAL.md → checkpoint (COMPLETE). Do not reopen X cells unless
failing; next work is push/PR or a fenced follow-on lane.
