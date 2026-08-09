# GOAL — zip-x-engine-20260809 (IMMUTABLE — re-read at the top of EVERY arc)

Read this first, every cycle. Auto-compact eats messages, not this file.
Unsure after a compaction? Re-read THIS, then checkpoint.md, then continue.

## Mission

Ship the Julia-forward ZIP+X engine under the ACCEPTED Identity
(`docs/dev-log/decisions/2026-08-09-zip-x-identity.md`): export
`fit_zip_gllvm_cov` + `ZIPCovFit` packing
`[βz; γ^z; βc; γ^c; pack(Λc)]` with `Λ_z = 0`, wire dual offsets
`Oz=_build_offset(X,γz)` / `Oc=_build_offset(X,γc)` into the ZIP Laplace
marginal, land Julia identity + packed FD ≤ 1e-6, admit bridge/`@formula`
for **both** no-X `zip` and ZIP+X, cascade docs/board/check-log/after-task,
Rose fence (no twin Δ), then STOP.

## Headline

Close the Identity→engine gap for ZIP+X without inventing twin parity —
dual-γ packing is the novel load-bearing piece.

## Invariants

- **G0 approved 2026-08-09** (Q1–Q3 locked): Rung 2 confint not in DoD;
  bridge admits one-part + X; Arc Card + ultra-plan persisted.
- **OPEN GATE first:** do not start engine `src/` until `#197` and `#198`
  are both **MERGED** on `origin/main`. Another lane owns merges — do not
  steal/merge unless already green+merged.
- One write lane after gate clears: fresh `.worktrees/…` off `origin/main`
  on `feat/zip-x-engine-YYYYMMDD` — **NOT** Dropbox checkout; **NOT**
  Identity tip `docs/zip-x-identity-20260809`.
- FENCES: ≠ twin light RCall Δ ≠ ZINB/hurdle/Tweedie+X ≠ ADEMP/coverage ≠
  Phylo #127 ≠ free `Λ_z` as default ≠ shared single-γ forced equal ≠
  Dropbox writes ≠ `git add -A` ≠ push without ask ≠ silent rtol widen ≠
  claim twin parity / full family parity.
- No silent rtol widen. Verify = printed identity/FD tallies + Rose fence
  strings, not exit code alone.
- Compute = laptop (no Totoro/DRAC for this arc).
- Optional Rung 2 (ZIP+X confint) only if under-run; never inflate DoD.

## Authoritative WHAT

→ `lanes/zip-x-engine-20260809/LOOP/ultra-plan.md`  
(source: `docs/dev-log/plans/2026-08-09-zip-x-engine-arc0-ultra-plan.md`;
Arc Card: `docs/dev-log/plans/2026-08-09-zip-x-engine-arc0-arc-card.md`)

## Definition of done

1. `fit_zip_gllvm_cov` + `ZIPCovFit` exported with docstring; packing matches
   Identity (`Λ_z = 0`; separate `γ^z`/`γ^c`).
2. `test/test_zip_x_identity.jl` green: zero-X ≈ `fit_zip_gllvm`; packed
   FD ≤ 1e-6 (printed tallies).
3. Bridge/`@formula` admit no-X `zip` → `fit_zip_gllvm` and X →
   `ZIPCovFit`; capabilities golden.
4. Docs cascade + check-log + board START HERE + after-task.
5. Rose OK for **Julia ZIP+X engine claim only** (explicitly not twin Δ /
   ADEMP / full parity).
6. Melissa plan-actual + Actuals filled; STOP.
7. Commits staged by path; **no push** unless maintainer asks.
