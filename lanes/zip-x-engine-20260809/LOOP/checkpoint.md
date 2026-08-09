GOAL: see GOAL.md.   STATE: G0+SCAFFOLD landed; gated on #197+#198 MERGED — no engine src/.
ARCS DONE (verified): G0 (Shinichi approved plan + Q1–Q3 2026-08-09); SCAFFOLD (ultra-plan + Arc Card + LOOP kit written under worktree; local docs branch `docs/zip-x-engine-ultraplan-20260809` @ tip of Identity `90e8abae`).
ARC IN PROGRESS: GATE — wait merges (do not steal/merge; other lane may own CI→merge).
NEXT: after both MERGED → S0 (fresh worktree off `origin/main` `feat/zip-x-engine-YYYYMMDD`; twin ZIP re-cite; then S1 call-site map). Do **not** start S2 until S0/S1 land.
OPEN GATES (need human / external): **#197 + #198 MERGED on origin/main** (as of scaffold: #197 OPEN, Julia CI IN_PROGRESS / UNSTABLE; #198 OPEN MERGEABLE on #197 tip, Documenter SUCCESS).
TRUTH LIVES IN:
- plan `docs/dev-log/plans/2026-08-09-zip-x-engine-arc0-ultra-plan.md`
- Arc Card `docs/dev-log/plans/2026-08-09-zip-x-engine-arc0-arc-card.md`
- Identity `docs/dev-log/decisions/2026-08-09-zip-x-identity.md` (ACCEPTED)
- LOOP `lanes/zip-x-engine-20260809/LOOP/`
- scaffold branch `docs/zip-x-engine-ultraplan-20260809` @ `5a92aaa0` on wt `.worktrees/gllvmjl-post-bb-x-capacity-handover-20260809` (local only; not pushed)
- PRs: https://github.com/itchyshin/GLLVM.jl/pull/197 · https://github.com/itchyshin/GLLVM.jl/pull/198

RESUME: paste the block below into a **fresh Cursor chat** after `#197` and `#198` show `MERGED`.

```
/goal ZIP+X engine Arc 0 — RESUME after merge gate

You are zip-x-engine-20260809 — running the approved ZIP+X engine Arc 0.
This is a RESUME (G0+SCAFFOLD already done).

READ FIRST, IN ORDER:
- lanes/zip-x-engine-20260809/LOOP/GOAL.md
- lanes/zip-x-engine-20260809/LOOP/checkpoint.md
- lanes/zip-x-engine-20260809/LOOP/ultra-plan.md
- docs/dev-log/decisions/2026-08-09-zip-x-identity.md
- AGENTS.md

PRECONDITION: gh pr view 197 / 198 both state=MERGED on origin/main.
If not both MERGED: STOP; overwrite checkpoint; do not edit src/.

WORKSPACE: fresh git worktree from origin/main
  `.worktrees/gllvmjl-zip-x-engine-YYYYMMDD` on `feat/zip-x-engine-YYYYMMDD`
  (NOT Dropbox checkout; NOT docs/zip-x-identity tip; NOT ultraplan docs tip).
  Copy/reattach LOOP from lane if needed; do NOT recreate the plan.

RUN goal skill (Cursor arc-loop adapter): re-read GOAL each arc; verify by
LOG not exit code; conductor lean; pause at OPEN GATE; overwrite checkpoint
each arc; fresh chat at batch barriers.

CONTINUE FROM: S0 → S1 → S2… (see LOOP/arcs.md).
Pause at: Rose claim gate (S7); any dual-γ FD failure before bridge admit.
LOCKED: Q1 Rung2 confint not DoD; Q2 admit one-part+X zip; Q3 plan files done.
FENCES: ≠ twin light RCall Δ ≠ ZINB/hurdle/Tweedie+X ≠ ADEMP ≠ Phylo #127
≠ Dropbox writes ≠ git add -A ≠ push without ask ≠ silent rtol widen
≠ claim twin parity.

OUTCOME: fit_zip_gllvm_cov / ZIPCovFit + identity/FD≤1e-6 + bridge/@formula
(one-part + X) + docs/Rose; STOP.
```
