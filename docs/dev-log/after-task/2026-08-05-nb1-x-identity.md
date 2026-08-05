# After-Task Report: NB1+X dispersion identity (Arc 0)

**Date:** 2026-08-05  
**Branch:** `cursor/nb1-x-identity-arc0-fffd` (PR #185) from `origin/main` @
`13d97b13`  
**Lead:** Ada (Cursor `/goal`) · G0: Q1=per-trait+X if twin confirms · Q2=short
no-X · Q3=A move START HERE on execute  
**Scope:** docs-only identity lock — **no `src/`**, no NB1+X RCall, no ADEMP

## Goal (one sentence)

Lock the public/twin default for NB1 under shared site-X as **per-trait φ +
shared γ**, twin to live gllvmTMB `nbinom1` / `log_phi_nbinom1`, before any
NB1+X engine or light-parity work.

## What changed

| Path | Role |
|---|---|
| `docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md` | ACCEPTED decision |
| `docs/dev-log/plans/scratch/nb1-x-twin-recon.md` | S0 twin recon |
| `docs/dev-log/plans/scratch/nb1-x-julia-recon.md` | S1 Julia recon |
| `docs/dev-log/plans/2026-08-05-nb1-x-identity-*.md` | Arc Card + Ultra Plan |
| `docs/dev-log/coordination-board.md` | START HERE → NB1+X identity |
| `docs/dev-log/check-log.md` | Evidence + Rose fence entry |
| `docs/dev-log/plan-actual/2026-08-05-nb1-x-identity.md` | Melissa light reconcile |
| `docs/dev-log/after-task/2026-08-05-nb1-x-identity.md` | This report |
| `AGENTS.md` | Phase-state snapshot only |

## Tests

Docs-only — no new tests. Mechanical verify:

- Decision cites twin file:line + Julia bridge/NB1 routes
- `git diff --name-only` shows **no `src/`** / **no `test/`**
- Fence strings: full family parity / ADEMP / Phylo Model A /
  engine-before-acceptance / Gamma Option B / Tweedie/ZIP

## R-parity / twin

Oracle = live twin surface @ `5bf18ab3`, not a new cell. Confirmed fid-15
`nbinom1` per-trait `log_phi_nbinom1` + shared `X_fix*b_fix`. Julia gap =
**missing site-X kernel** on bridge (ArgumentError today).

## JET / Allocs / Aqua

N/A (no code).

## Rose audit verdict

**PASS WITH NOTES.** Claim surface is a design lock only. Notes:

1. Status ACCEPTED under G0; docs PR #185 still open until merge.
2. Engine / light RCall remain fenced until Arc 1 / Arc 2.
3. No-X already per-trait via bridge — no Option-B-style flip.
4. `/ask-brain` unavailable in cloud; twin cites from raw GitHub fetch.
5. Scale: Julia/twin NB1 φ is linear-variance (not NB2 1/r).

**Rose verdict: PASS WITH NOTES** — identity doc + fence OK; no engine claim.

## Remaining risks

- Someone starts `fit_nb1_*_cov` before reading the Rose fence.
- Confusing NB1 φ with NB2 `r` / public φ=1/r.
- Cloud twin fetch SHA drift if gllvmTMB main moves before Arc 1.

## Next command

```text
# Merge #185 when ready (docs-only self-merge OK):
# gh pr merge 185 --merge

# Next capability (fresh chat — only after decision stays ACCEPTED on main):
# /arc-creation — NB1+X engine Arc 1 (fit_nb1_gllvm_grouped_cov)
```
