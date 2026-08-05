# Handover — NB1+X Arc 1+2 → local (2026-08-05)

**From:** Cursor cloud agent (GLLVM9)  
**To:** Shinichi / local Cursor Agent  
**Theme:** R–Julia parity — NB1+X combined Arc 1+2  
**Skip brain:** cloud has no shinichi-brain MCP; local `/ask-brain` as usual.

## Verdict

**Engine LOCAL DONE; closeout half-landed; live RCall OWED.**  
Not merge-ready until docs commit + push + (optional) live Δ.

## Branch / tips

| Item | Value |
|---|---|
| Branch | `cursor/nb1-x-engine-arc12-fffd` |
| Engine tip (local cloud, may be unpushed) | `a83391fa` — `feat(nb1): fit_nb1_gllvm_grouped_cov + bridge/formula X route` |
| PR | [#186](https://github.com/itchyshin/GLLVM.jl/pull/186) (draft; title still plans-era until updated) |
| Identity base | `main` @ `210de76d` (#185 MERGED) |
| Decision | `docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md` |

## G0 locks (already answered)

1. OH default on R-facing path → **yes** (`hessian=:observed` on `fit_nb1_gllvm_grouped_cov`)  
2. Continue plan branch → **yes** (`cursor/nb1-x-engine-arc12-fffd`)

## Done (evidence)

- `fit_nb1_gllvm_grouped_cov` / `NB1GroupedCovFit` + OH weight in `grouped_dispersion.jl`
- Bridge `nb1`+X, `@formula`, confint adapter, shared-φ `fit_gllvm_cov(NB1)` opt-in
- `test/test_nb1_x_identity.jl` → **7/7**
- `test/test_bridge_x.jl` → **208/208**
- Light cell scaffold: `test/parity/test_x_covariate_parity.jl` seed=48; helper `:nb1` → `nbinom1()`

## Still OWED / dirty on cloud tip

1. **Uncommitted docs** (were present on cloud worktree at handoff):  
   `AGENTS.md`, `docs/dev-log/coordination-board.md`, `check-log.md`,  
   `docs/dev-log/after-task/2026-08-05-nb1-x-engine-arc12.md`,  
   `docs/src/gllvmtmb-parity.md`, `docs/design/capability-status.md`, Arc Card Actuals  
2. **Push** `a83391fa` (+ docs commit) to origin; refresh PR #186 title/body  
3. **Live RCall** `GLLVM_PARITY_TESTS=1` NB1+X cell — **OWED** (no R in cloud). Paste Δ @ rtol 1e-6; no widen  
4. Full `Pkg.test()` / CI after push  

## Local START HERE

```sh
git fetch origin
git checkout cursor/nb1-x-engine-arc12-fffd
# if cloud pushed: git pull
# if not: recover commit from cloud agent branch or re-apply from this handover

# verify
julia --project=. -e 'using Test; include("test/test_nb1_x_identity.jl")'
julia --project=. -e 'using Test; include("test/test_bridge_x.jl")'

# live oracle (local R + gllvmTMB)
GLLVM_PARITY_TESTS=1 julia --project=. test/parity/test_x_covariate_parity.jl
# or focused include of the NB1+X @testset
```

Then: commit any remaining docs → push → update #186 → merge when ready.  
**STOP** inventing next family — fresh `/arc-creation` only.

## Rose fence

OK: NB1+X engine + Julia identity + scaffolded light cell.  
Not OK: live Δ (OWED); full family parity; ADEMP; Phylo Model A.

## Brain / cloud note

Do **not** spend time wiring shinichi-brain into cloud for this lane — local agents only.
