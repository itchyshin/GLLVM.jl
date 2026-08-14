# After Task: ZINB+X Identity Arc 0 (docs-only)

**Date:** 2026-08-13  
**Lane:** `docs/zinb-x-identity-20260813`  
**Worktree:** `.worktrees/gllvmjl-zinb-x-identity-20260813`  
**Base tip:** `8abdd751` (`origin/main` = Merge #201 ZIP+X confint)  
**Decision:** `docs/dev-log/decisions/2026-08-13-zinb-x-identity.md`

## Goal

Land ACCEPTED ZINB+X Identity Arc 0 — **docs-only**. No ZINB+X engine, no
bridge `zinb` admit, no twin light Δ. Flip the stale ZIP+X confint “PR
pending” pointer to **MERGED #201**. **STOP** before any ZINB+X engine.

## Implemented

Decision note ACCEPTED with twin-asymmetry fence (gllvmTMB ZIP/ZINB still
cut @ `9518d1bf`; no `family_to_id` ZINB arm). Locked estimand: shared
site-X with **separate** `γ^z` / `γ^c`, retain `Λ_z = 0`, **shared scalar
`r`** (log-scale). Explicitly rejects copying NB2 per-trait φ. Cites Julia
no-X `fit_zinb_gllvm` map and shipped ZIP dual-`γ` reuse. Board / AGENTS /
check-log / Arc Card Actuals updated. Zero `src/` in the diff.

## Mathematical Contract

ZINB mixture (§2.2 of the two-part design) under shared site-X:

- `η^z_{ts} = β^z_t + X[t,s,:] · γ^z` (`Λ_z = 0`)
- `η^c_{ts} = β^c_t + X[t,s,:] · γ^c + (Λ_c z_s)_t`
- one shared `r` on `log r` (two-part §3; Julia no-X packing)

Not implemented in this slice — Identity lock only.

## Files Changed

- `docs/dev-log/decisions/2026-08-13-zinb-x-identity.md` — ACCEPTED lock
- `docs/dev-log/plans/2026-08-13-zinb-x-identity-arc-card.md` — card + Actuals
- `docs/dev-log/after-task/2026-08-13-zinb-x-identity.md` — this report
- `docs/dev-log/coordination-board.md` — START HERE + #201 MERGED + this lane
- `docs/dev-log/check-log.md` — Identity entry
- `AGENTS.md` — Phase-state snapshot (ZIP+X CI MERGED; this Identity)

## Tests Added

None — docs-only Identity. No new test would have failed; engine is fenced.

## Benchmark Numbers

`N/A — no hot-path change` (no `src/` edit).

## R-Parity Verdict

`Parity: N/A — change does not touch the parity surface`. Twin ZINB is cut;
this note **forbids** inventing a light Δ.

## JET / Allocs / Aqua Verdicts

- JET: N/A — no `src/` change
- Allocs: N/A — no `src/` change
- Aqua: N/A — no Project.toml / export change

## Checks Run

S0 twin-cut re-check (live `gllvmTMB` @ `9518d1bf`):

- `docs/dev-log/known-limitations.md` L146–148 still cuts ZIP/ZINB
- `R/fit-multi.R` `family_to_id` has no ZIP/ZINB arm
- `R/aghq-control.R` `"zip","zinb"` is a curvature heuristic only

Julia map @ `8abdd751`:

- `fit_zinb_gllvm` packs `[βz; βc; pack(Λc); log r]`, `Λ_z = 0`
- `zinb` ∉ `_BRIDGE_ONEPART_FAMILIES` / `_BRIDGE_X_FAMILIES`
- `fit_zip_gllvm_cov` dual-`γ` shipped (#200/#201)

Diff fence: **zero** `src/` files in this lane’s commit.

Stale-wording `rg` (worktree):

```
rg "ZINB\\+X|zinb-x|PR pending" docs/dev-log/coordination-board.md AGENTS.md
rg "shared scalar \`r\`|per-trait" docs/dev-log/decisions/2026-08-13-zinb-x-identity.md
```

Board START HERE no longer says ZIP+X confint “PR pending”. Decision
explicitly locks shared scalar `r` and rejects per-trait copy.

Full `Pkg.test()`: **not run** — docs-only; no engine claim.

## Consistency Audit

README / CLAUDE.md / `docs/src/` family pages were **not** rewritten. This
Identity does not change user-facing capability. ZIP+X Identity
(`2026-08-09-zip-x-identity.md`) left untouched. PR #199 not touched.

## GitHub Issue Maintenance

No issue action — this is a docs lock, not a capability close. Phylo #127
stays parked.

## What Did Not Go Smoothly

Lane preflight on the Dropbox checkout still shows the protected stale
fork plus PR #199; this lane used a fresh `origin/main` worktree and did
not touch #199. `.worktrees/` is not gitignored in this repo; the
worktree itself is not staged.

## Team Learning

Identity arcs that follow a twin-backed neighbour (NB2 per-trait φ) must
state the **non-copy** in the lock table, not only in rejected alts.

## Remaining Risks

- Twin ZINB may return later with a different dispersion / X grammar —
  Identity re-check is mandatory before any light Δ.
- Next engine arc could still cargo-cult per-trait `r` if it reads only
  the NB2+X note. The lock here is the fence.

## Known Limitations

This note does **not** ship `fit_zinb_gllvm_cov`, admit bridge `zinb`,
claim twin parity, or start hurdle/Tweedie+X / ADEMP / Phylo #127.

## Next Command

`none — Identity ACCEPTED; STOP. Fresh /arc-creation only for ZINB+X engine.`

## Rose Verdict

Rose verdict: **PASS** — docs-only Identity ACCEPTED; shared scalar `r`
locked; twin cut cited; ZIP dual-`γ` reuse cited; zero `src/` engine;
board #201 pointer corrected; engine / twin Δ / ADEMP fenced.
