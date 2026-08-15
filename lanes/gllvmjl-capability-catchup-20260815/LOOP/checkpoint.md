GOAL: see GOAL.md.   STATE: PROGRAMME STOP — Arc0–Rung4+Close verified; full `Pkg.test()` GREEN.
ARCS DONE (verified):
- Arc0: #204 MERGED @ 2914cc18; board START HERE catch-up → STOP pointer
- Rung1: bare implemented zip/zinb/zib; 0 non-bare Status (token parse)
- Rung2: student+com_poisson implemented; REML OWED note
- Rung3: Identity ACCEPTED docs/dev-log/decisions/2026-08-15-truncated-poisson-identity.md
- Rung4: TruncatedPoisson engine; test_truncated_poisson.jl 10/10 Pass; ledger flip
- Close: after-task + check-log + Melissa plan-actual + Rose fence in after-task
- Full suite: `julia --project=. -e 'using Pkg; Pkg.test()'` @ tip `d5ae8b62` → **5559 Pass / 1 Broken / 5560 Total** (55m58.3s); Testing GLLVM tests passed; 0 Fail; no rtol widen
ARC IN PROGRESS: none
NEXT: human gate — ask Shinichi before push/PR (suite green; do not push until instructed)
OPEN GATES (need human): push/PR without ask; public MC overwrite of R MSPL
TRUTH LIVES IN:
- Worktree `.worktrees/gllvmjl-capability-catchup-20260815` branch `cursor/capability-catchup-20260815` @ `d5ae8b62` (suite tip)
- after-task `docs/dev-log/after-task/2026-08-15-gllvm-jl-capability-catchup.md`
- plan-actual `docs/dev-log/plan-actual/2026-08-15-gllvm-jl-capability-catchup.md`
- Full suite log: `/tmp/gllvmjl-capability-catchup-pkgtest-20260815.log`
RESUME: You are gllvmjl-capability-catchup-20260815. PROGRAMME DONE for G0 scope; full Pkg.test GREEN.
READ FIRST: LOOP/GOAL.md → checkpoint.md → after-task 2026-08-15-gllvm-jl-capability-catchup.md.
If continuing: ask Shinichi before push/PR. Optional next lane: truncated_nbinom2 or REML test.
Do NOT redo Arc0–Rung4. Do NOT invent ZIP/ZINB twin Δ. Do NOT write Dropbox protected fork.
