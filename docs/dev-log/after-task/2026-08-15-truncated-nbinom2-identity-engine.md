# After-task: truncated_nbinom2 Identity→Engine

**Date:** 2026-08-15  
**Lane:** `cursor/truncated-nbinom2-20260815`  
**WT:** `.worktrees/gllvmjl-truncated-nbinom2-20260815`  
**Binding plan:** `docs/dev-log/plans/2026-08-15-truncated-nbinom2-identity-engine.md` (G0 LOCKED · Ada defaults)  
**Depends on:** PR #205 tip (`b2b99463` Documenter-fixed) carrying `truncated_poisson`

## Goal

Land twin-aligned zero-truncated NB2 (fid 11) Identity→Engine with Arc1 **shared
scalar `r`** (Julia `r` ≡ twin `φ`); twin per-trait documented; Arc1b OWED.

## Done

| Slice | Evidence |
|---|---|
| S1 Identity | ACCEPTED `docs/dev-log/decisions/2026-08-15-truncated-nbinom2-identity.md` |
| S2 Engine | `src/families/truncated_nbinom2.jl` — `TruncatedNegBin2{T}`, score/weight/logpdf, `fit_truncated_nbinom2_gllvm` over `[β; Λ; log r]` |
| S3 Tests | `test/test_truncated_nbinom2.jl` **13/13 Pass** (post-Sol `a`-factor fix) |
| S4 Ledger | `truncated_nbinom2` → `implemented` (bare token); Notes = shared-`r` / twin per-trait |
| Wire | `src/GLLVM.jl` include/export; `fit_gllvm` dispatch; `test/runtests.jl` include |

## Verification

- Focused (post-Sol fix): **13 Pass / 0 Fail** (~6.7s) — Λ=0 exact, score/weight with `a=r/(r+μ)` + density-derivative check, y=0 reject, smoke fit + `fit_gllvm`, packed NLL FD ≤ 1e-6
- Sol BLOCK cell (μ=2.5, y=3, r=4): bare `(y−μ_tr)=0.08144` ≠ `dℓ/dη`; fixed `score=a·(y−μ_tr)=0.05011869` vs central FD `dℓ/dη=0.05011869` (abs diff 4.1e-10)
- Weight: `W = a² · Var(Y|Y>0)`
- No rtol/atol widen

## Sol ceiling BLOCK

- **2026-08-15 HARD BLOCK:** score/weight omitted `a = r/(r+μ)` (wrong HurdleNB-positive copy).
- **CLEAR:** kernel fixed; Identity + tests updated to density-derivative truth; focused 13/13 green.

## Rose fence

- Claim = Julia Laplace engine + Identity twin cite (fid 11); light RCall **optional / not run**
- Arc1 = shared scalar `r`; twin default per-trait `log_phi_truncnb2` = **documented / Arc1b OWED**
- ≠ invent ZIP/ZINB twin Δ ≠ Phylo #127 ≠ ADEMP ≠ silent rtol
- Public capability = Status `implemented` with honest Notes (not twin-default per-trait parity)

## Next

1. Merge #205 on full Julia CI green (sole merger if still OPEN) — record merge SHA  
2. Rebase this branch onto post-#205 `origin/main` → push PR → merge-on-green  
3. MC `claim_guard.julia_surface` PROPOSE only (do not clobber R MSPL) — next_safe = Arc1b / REML OWED / truncated confint  
4. Optional Arc1b: light RCall Δ or per-trait φ if twin cell needs it
