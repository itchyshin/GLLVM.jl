# GOAL — gamma-x-grouped-cov-20260803 (IMMUTABLE — re-read at the top of EVERY arc)

## Mission

Engine Arc 1 implementing the LOCKED Gamma+X identity
(`docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`): export
`fit_gamma_gllvm_grouped_cov` + `GammaGroupedCovFit` (per-group/per-trait shape α
+ shared site-X γ), route bridge X and `@formula`+X for gamma through that path,
keep `fit_gllvm_cov(...; family=Gamma())` as shared-α + X opt-in, ship Julia-only
identity tests (G=1+fisher ≈ shared cov; constant-αvec marginal), docs cascade
+ check-log + after-task + Rose fence.

## Headline

Close the twin gap under X for Gamma the same way #175 closed it for NB2/Beta —
without claiming light RCall parity.

## Invariants

- One write lane: `.worktrees/gllvmjl-gamma-x-grouped-cov-20260803` on
  `fix/gamma-x-grouped-cov-20260803` from `origin/main`.
- Full #175 mirror for Gamma only; FD LBFGS (no analytic-grad redesign).
- FENCES: light RCall Gamma+X Arc 2; no-X Option B flip; Ordinal+X; X_lv;
  ADEMP/coverage; Phylo Model A; “full family parity”; Dropbox checkout writes;
  `git add -A`; push without ask; merging or conflict-resolving #177.
- No silent rtol widen. Verify = printed identity/test tallies.
- Compute = laptop (Totoro only if smoke needs it; no DRAC).
- STOP at Arc 1 — Arc 2 is a separate `/goal`.

## Authoritative WHAT

→ `LOOP/ultra-plan.md` (frozen copy of approved ultra-plan).

## Definition of done

1. `fit_gamma_gllvm_grouped_cov` + `GammaGroupedCovFit` exported with docstring.
2. Bridge X + `@formula`+X route `gamma` through grouped_cov; shared cov remains opt-in.
3. Identity tests green (G=1+fisher ≈ `fit_gllvm_cov`; constant αvec); bridge_x oracles updated.
4. Docs cascade + surgical check-log/board (fence #177 hunks).
5. After-task + Rose OK for engine claim only (not RCall / full parity).
6. Commits staged by path; **no push** unless maintainer asks.
